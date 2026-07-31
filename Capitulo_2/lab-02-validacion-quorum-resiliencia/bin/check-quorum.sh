#!/bin/bash
# ============================================================
# check-quorum.sh · ficha didáctica sobre kafka-metadata-quorum
# ============================================================
# Familia LEE. Solo consulta, no toca nada. El valor está en saber
# interpretar la salida, así que la ficha explica el comando justo
# debajo del comando, deja la leyenda de los campos pegada a la salida
# y cierra con un diagnóstico armado con los datos reales del clúster.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bin/common.sh
source "$DIR_LAB/bin/common.sh"

# ── Diccionario de flags ─────────────────────────────────────
# Función con case, NO array asociativo. Bash 3.2 no los soporta.
flag_desc() {
    case "$1" in
        --bootstrap-server) echo "la puerta de entrada al clúster. En tu servidor va la IP de tu broker" ;;
        describe)           echo "solo consulta, no toca nada" ;;
        --status)           echo "el resumen del quórum, quién manda y desde cuándo" ;;
        --replication)      echo "el detalle por nodo, cuánto le falta a cada uno" ;;
        *)                  echo "" ;;
    esac
}

# ── Lectura de la salida de describe --status ────────────────
# Las líneas vienen con el formato "Campo:<espacios>valor". Se devuelve
# TODO lo que sigue al nombre del campo, no la primera palabra. El JSON
# de CurrentVoters trae espacios adentro y cortarlo por palabras lo parte.
q_valor() {
    printf '%s\n' "$2" | sed -n "s/^$1:[[:space:]]*//p" | head -1
}

# Cuenta cuántos nodos hay en una lista JSON de CurrentVoters u Observers.
# La lista vacía "[]" es un caso normal, no un error. Ahí grep devuelve 1
# y con pipefail se llevaría puesto el script.
q_contar_ids() {
    local n
    n=$(printf '%s\n' "$1" | grep -o '"id":' | wc -l | tr -d ' ') || n=0
    printf '%s' "${n:-0}"
}

# ── Lectura de la salida de describe --replication ───────────
# Las columnas se localizan por su nombre en la cabecera, porque el orden
# y la cantidad cambian entre versiones de Kafka. Un votante se considera
# vivo si el líder lo vio hace menos de 15 segundos.
# El lag máximo sale de la columna Lag, que es la que el alumno tiene
# delante. Antes se leía MaxFollowerLag de --status, que es otra consulta
# en otro momento, y el diagnóstico terminaba contradiciendo a la tabla.
# Imprime "<votantes> <vivos> <observadores> <rezagados> <lag_maximo>".
q_resumen_replicacion() {
    local ahora_ms
    ahora_ms=$(( $(date +%s) * 1000 ))
    printf '%s\n' "$1" | awk -v ahora="$ahora_ms" -v umbral=15000 '
        NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i; next }
        NF < 3 { next }
        {
            estado = (("Status" in col) ? $(col["Status"]) : "?")
            visto  = (("LastFetchTimestamp" in col) ? $(col["LastFetchTimestamp"]) + 0 : 0)
            lag    = (("Lag" in col) ? $(col["Lag"]) + 0 : 0)
            if (lag > maxlag) maxlag = lag
            if (estado == "Observer") { obs++; next }
            vot++
            if (estado == "Leader" || (ahora - visto) <= umbral) vivos++
            else rezag++
        }
        END { printf "%d %d %d %d %d", vot + 0, vivos + 0, obs + 0, rezag + 0, maxlag + 0 }
    '
}

# ── Validación · lo primero, siempre ─────────────────────────
# kafka-metadata-quorum puede fallar y ESCUPIR UN STACK TRACE POR STDOUT
# saliendo con código 0. Si eso se parsea sin verificar, las líneas del
# stack trace se cuentan como nodos y el diagnóstico afirma números que no
# existen. Un dato que no se pudo leer no se estima. Se declara que falta.
#
# Es tabla válida solo si la cabecera trae NodeId y TODAS las filas que
# siguen empiezan con un entero. Un "Exception" o un "at ..." la invalida
# entera, porque no arrancan con entero.
q_repl_es_tabla() {
    printf '%s\n' "$1" | awk '
        NR == 1 { if ($0 !~ /NodeId/) malo = 1; next }
        /^[ \t]*$/ { next }
        { if ($1 !~ /^[0-9]+$/) malo = 1; else filas++ }
        END { if (malo || filas == 0) exit 1; exit 0 }
    '
}

q_status_es_valido() {
    local lider
    lider=$(q_valor 'LeaderId' "$1")
    case "$lider" in
        ''|*[!0-9]*) return 1 ;;
        *)           return 0 ;;
    esac
}

# Una sola línea, la más informativa de una salida rota. El stack trace
# completo no le aporta nada al alumno. El orden de preferencia importa,
# porque Kafka manda el dato útil en un WARN y después una excepción
# genérica que no dice nada ("Failed to create new KafkaAdminClient").
q_linea_error() {
    local l
    l=$(printf '%s\n' "$1" | grep -m1 'UnknownHostException') || l=''
    if [ -z "$l" ]; then
        l=$(printf '%s\n' "$1" | grep -m1 'resolution failed') || l=''
    fi
    if [ -z "$l" ]; then
        l=$(printf '%s\n' "$1" | grep -m1 'Exception') || l=''
    fi
    if [ -z "$l" ]; then
        l=$(printf '%s\n' "$1" | sed -n '/[^[:space:]]/{p;q;}')
    fi
    printf '%s' "$l"
}

# El nombre del contenedor que Kafka no pudo resolver, si el error lo trae.
# Se cubren las dos formas que emite Kafka 4.x para lo mismo:
#   UnknownHostException: kafka-broker-1: Name or service not known
#   ... DNS resolution failed for kafka-broker-1
# Kafka pega cosas al nombre. En el primer caso, el ':' que separa el resto
# del mensaje. En otras variantes, el puerto. Se corta en el primer ':' y en
# la primera ',', que saca las dos.
#
# Lo que sale de acá va dentro de un 'docker start' que el alumno copia y
# pega, así que si no es un nombre de contenedor válido se devuelve vacío
# y el diagnóstico no ofrece el comando. Antes que un comando roto, ninguno.
q_host_error() {
    local h
    h=$(printf '%s\n' "$1" \
        | sed -n 's/.*UnknownHostException:[[:space:]]*\([^ ][^ ]*\).*/\1/p' | head -1)
    if [ -z "$h" ]; then
        h=$(printf '%s\n' "$1" \
            | sed -n 's/.*DNS resolution failed for[[:space:]]*\([^ ][^ ]*\).*/\1/p' | head -1)
    fi

    h="${h%%:*}"
    h="${h%%,*}"

    case "$h" in
        ''|*[!A-Za-z0-9._-]*) h='' ;;
    esac

    printf '%s' "$h"
}

# El nombre salió de un mensaje de error de Kafka, no de docker. Antes de
# ofrecer un 'docker start' se confirma que ese contenedor existe en esta
# máquina, porque el alumno lo va a copiar y pegar tal cual.
q_contenedor_existe() {
    docker ps -a --filter "name=^${1}$" --format '{{.Names}}' 2>/dev/null \
        | grep -q "^${1}$"
}

# ── Reformateo de la salida para que se pueda leer ───────────
# Se conserva todo lo que la ficha explica y no se altera ningún valor.
# Solo se cambia la presentación.

# CurrentVoters llega como un JSON de una sola línea que envuelve tres
# veces en pantalla. Se abre a una línea por nodo. Sin jq, que no está
# garantizado en el Git Bash de los alumnos de SUNAT.
q_voters_legible() {
    printf '%s\n' "$1" | awk '
    {
        n = split($0, partes, /}[ \t]*,[ \t]*{/)
        for (i = 1; i <= n; i++) {
            trozo = partes[i]
            id = ""; ep = ""
            if (match(trozo, /"id"[ \t]*:[ \t]*[0-9]+/)) {
                id = substr(trozo, RSTART, RLENGTH)
                sub(/.*[^0-9]/, "", id)
            }
            if (match(trozo, /"[A-Za-z]+:\/\/[^"]+"/)) {
                ep = substr(trozo, RSTART + 1, RLENGTH - 2)
            }
            if (id != "" && ep != "") printf "  id %s  ->  %s\n", id, ep
        }
    }'
}

# Rehace el bloque de --status. Las líneas escalares pasan tal cual y las
# dos listas JSON se abren. Si el parseo no devuelve nada, la línea
# original se imprime igual. Nunca se pierde el dato.
q_status_legible() {
    local salida="$1" linea campo valor abierto
    printf '%s\n' "$salida" | while IFS= read -r linea; do
        case "$linea" in
            CurrentVoters:*|CurrentObservers:*)
                campo="${linea%%:*}"
                valor=$(printf '%s' "$linea" | sed -n "s/^${campo}:[[:space:]]*//p")
                if [ "$valor" = "[]" ]; then
                    printf '%s   ninguno\n' "$campo"
                    continue
                fi
                abierto=$(q_voters_legible "$valor")
                if [ -n "$abierto" ]; then
                    printf '%s\n' "$campo"
                    printf '%s\n' "$abierto"
                else
                    printf '%s\n' "$linea"
                fi
                ;;
            *)
                printf '%s\n' "$linea"
                ;;
        esac
    done
}

# Recorta la tabla de --replication a las cuatro columnas que la ficha
# explica. Las posiciones se leen de la cabecera por nombre, así que un
# cambio de orden en otra versión de Kafka no lo rompe.
q_repl_legible() {
    printf '%s\n' "$1" | awk '
        NR == 1 {
            for (i = 1; i <= NF; i++) col[$i] = i
            printf "%-8s %-14s %-5s %s\n", "NodeId", "LogEndOffset", "Lag", "Status"
            next
        }
        NF < 3 { next }
        {
            filas++
            printf "%-8s %-14s %-5s %s\n", \
                (("NodeId" in col) ? $(col["NodeId"]) : $1), \
                (("LogEndOffset" in col) ? $(col["LogEndOffset"]) : "?"), \
                (("Lag" in col) ? $(col["Lag"]) : "?"), \
                (("Status" in col) ? $(col["Status"]) : "?")
        }
        END { if (filas == 0) exit 3 }
    '
}

q_nodos() {
    if [ "$1" -eq 1 ]; then
        printf '1 nodo'
    else
        printf '%s nodos' "$1"
    fi
}

q_mensajes() {
    if [ "$1" -eq 1 ]; then
        printf '1 mensaje'
    else
        printf '%s mensajes' "$1"
    fi
}

# Umbral de lag que se considera normal. Un clúster con tráfico tiene
# lag chico y variable todo el tiempo, no es un problema. Por encima de
# esto sí se advierte, porque el nodo dejó de seguir el ritmo.
Q_LAG_NORMAL=10

# ── Encabezado de la ficha ───────────────────────────────────
# El orden importa. Cada bloque va pegado a lo que explica, el DESGLOSE
# debajo del comando y la leyenda de los campos justo antes de la salida.
ficha_encabezado() {
    local destino="$1"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Preguntarle al clúster quién manda el quórum y si está sano'

    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-metadata-quorum --bootstrap-server $destino \\"
    ficha_comando '    describe --status'
    ficha_comando "kafka-metadata-quorum --bootstrap-server $destino \\"
    ficha_comando '    describe --replication'

    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$destino"      ''
    ficha_flag 'describe'           '--status'      '--status'
    ficha_flag 'describe'           '--replication' '--replication'

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'LeaderId'         'quién manda ahora mismo'
    ficha_campo 'LeaderEpoch'      'cuántas veces hubo elección. Sube en cada relevo'
    ficha_campo 'HighWatermark'    'hasta dónde está confirmado por la mayoría'
    ficha_campo 'MaxFollowerLag'   'cuánto le falta al más atrasado. Debe ser bajo'
    ficha_campo 'CurrentVoters'    'los que votan'
    ficha_campo 'CurrentObservers' 'los que copian pero no votan'
    ficha_campo 'DirectoryId'      'el identificador del directorio de datos de cada nodo'

    ficha_cerrar
}

# Notas al pie. La advertencia sale solo cuando el comando de arriba no
# se puede ejecutar ahora mismo, para que el alumno no lo copie en vano.
ficha_pie() {
    local hay_broker="$1" rc="$2"

    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    if [ "$hay_broker" -eq 0 ]; then
        ficha_nota_warn 'Ese contenedor no está corriendo ahora mismo.'
    elif [ "$rc" -ne 0 ]; then
        ficha_nota_warn 'Ese comando acaba de fallar. Mirá el diagnóstico del final.'
    fi
    ficha_nota 'En tu servidor, --bootstrap-server lleva la IP real de tu broker.'
    echo ''
}

# ── Diagnóstico con el quórum respondiendo ───────────────────
diagnostico_quorum() {
    local salida_status="$1" salida_repl="$2"
    local lider epoch hw voters_json observers_json
    local n_voters n_obs resumen vot vivos obs rezag maxlag mayoria tolerancia

    lider=$(q_valor 'LeaderId' "$salida_status")
    epoch=$(q_valor 'LeaderEpoch' "$salida_status")
    hw=$(q_valor 'HighWatermark' "$salida_status")
    voters_json=$(q_valor 'CurrentVoters' "$salida_status")
    observers_json=$(q_valor 'CurrentObservers' "$salida_status")

    n_voters=$(q_contar_ids "$voters_json")
    n_obs=$(q_contar_ids "$observers_json")

    resumen=$(q_resumen_replicacion "$salida_repl")
    vot=$(echo "$resumen" | awk '{print $1}')
    vivos=$(echo "$resumen" | awk '{print $2}')
    obs=$(echo "$resumen" | awk '{print $3}')
    rezag=$(echo "$resumen" | awk '{print $4}')
    maxlag=$(echo "$resumen" | awk '{print $5}')

    if [ "$obs" -eq 0 ]; then
        obs="$n_obs"
    fi

    mayoria=$(( vot / 2 + 1 ))
    tolerancia=$(( vivos - mayoria ))

    ficha_abrir 'DIAGNÓSTICO'

    # Verificación cruzada contra un hecho independiente. La cantidad de
    # votantes de la tabla tiene que cuadrar con la lista CurrentVoters,
    # que viene de la otra consulta. Si no cuadran, no se afirma nada.
    if [ "$n_voters" -gt 0 ] && [ "$vot" -ne "$n_voters" ]; then
        ficha_texto "Manda el nodo ${lider}, epoch ${epoch}."
        ficha_vacia
        ficha_texto "El detalle por nodo trae ${vot} votantes y CurrentVoters trae ${n_voters}."
        ficha_texto 'Las dos consultas no coinciden, así que no te puedo decir si el'
        ficha_texto 'quórum está sano sin arriesgarme a mentirte.'
        ficha_vacia
        ficha_causa '  ¿Qué brokers están vivos?' 'docker ps'
        ficha_causa '  Volvé a preguntar'         'bin/check-quorum.sh'
        ficha_cerrar
        return 0
    fi

    if [ "$rezag" -eq 0 ]; then
        ficha_texto "Quórum SANO. Manda el nodo ${lider}, epoch ${epoch}."
        if [ "$maxlag" -eq 0 ]; then
            ficha_texto "${vot} votantes, todos al día. Ninguno va un solo mensaje atrás."
        elif [ "$maxlag" -le "$Q_LAG_NORMAL" ]; then
            ficha_texto "${vot} votantes al día. El más atrasado va $(q_mensajes "$maxlag") atrás,"
            ficha_texto 'normal en un clúster con tráfico.'
        else
            ficha_texto "${vot} votantes, pero el más atrasado va $(q_mensajes "$maxlag") atrás."
            ficha_warn "Más de ${Q_LAG_NORMAL} es mucho. Ese nodo no está siguiendo el ritmo."
        fi
    else
        ficha_texto "Quórum DEGRADADO. Manda el nodo ${lider}, epoch ${epoch}."
        ficha_texto "${vot} votantes configurados, pero ${rezag} no responde hace más de 15s."
        ficha_texto "El más atrasado va $(q_mensajes "$maxlag") atrás."
        ficha_texto "Quedan ${vivos} al día y hacen falta ${mayoria} para poder decidir."
    fi

    ficha_texto "Confirmado por la mayoría hasta el offset ${hw}."
    if [ "$obs" -gt 0 ]; then
        ficha_texto "${obs} observadores, copian el log de metadatos pero no votan."
    fi

    ficha_vacia

    if [ "$tolerancia" -gt 0 ]; then
        ficha_texto "Toleras perder $(q_nodos "$tolerancia") y el clúster sigue mandando."
        ficha_warn "Pierdes $(( tolerancia + 1 )) y el clúster queda sin control. Nadie elige líderes."
    elif [ "$tolerancia" -eq 0 ]; then
        ficha_texto "Estás justo en la mayoría, ${vivos} de ${vot} y hacen falta ${mayoria}."
        ficha_warn 'Pierdes 1 más y el clúster queda sin control. Nadie elige líderes.'
    else
        ficha_warn "SIN mayoría. Hay ${vivos} votantes al día y hacen falta ${mayoria}."
        ficha_warn 'El clúster no elige líderes ni acepta cambios de metadatos.'
    fi

    ficha_cerrar
}

# ── Diagnóstico cuando --status anduvo pero --replication no ─
# Se afirma solo lo que salió de la consulta que sí funcionó, se declara
# lo que no se pudo leer y se explica por qué. Ni un número de la salida
# rota entra acá. Antes que una cifra inventada, va un "no lo sé".
diagnostico_parcial() {
    local salida_status="$1" salida_repl="$2"
    local lider epoch hw voters_json n_voters mayoria host err

    lider=$(q_valor 'LeaderId' "$salida_status")
    epoch=$(q_valor 'LeaderEpoch' "$salida_status")
    hw=$(q_valor 'HighWatermark' "$salida_status")
    voters_json=$(q_valor 'CurrentVoters' "$salida_status")
    n_voters=$(q_contar_ids "$voters_json")
    err=$(q_linea_error "$salida_repl")
    host=$(q_host_error "$salida_repl")

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "Manda el nodo ${lider}, epoch ${epoch}. Confirmado hasta el offset ${hw}."
    if [ "$n_voters" -gt 0 ]; then
        mayoria=$(( n_voters / 2 + 1 ))
        ficha_texto "El quórum tiene ${n_voters} votantes configurados y hacen falta ${mayoria}"
        ficha_texto 'para poder decidir.'
    fi
    ficha_vacia

    case "$err" in
        *UnknownHostException*|*'resolution failed'*)
            if [ -n "$host" ]; then
                ficha_texto 'No pude leer el detalle por nodo. Kafka no consiguió resolver'
                ficha_texto "el nombre ${host}, que es justo lo que pasa cuando ese"
                ficha_texto 'contenedor no está corriendo.'
            else
                ficha_texto 'No pude leer el detalle por nodo. Kafka no consiguió resolver'
                ficha_texto 'el nombre de uno de los brokers, así que hay uno apagado.'
            fi
            ;;
        *)
            ficha_texto 'No pude leer el detalle por nodo. Kafka no devolvió una tabla,'
            ficha_texto 'devolvió el error que está acá arriba.'
            ;;
    esac
    ficha_texto 'Sin ese detalle no puedo decirte cuántos votantes están al día.'

    ficha_vacia
    if [ -n "$host" ] && q_contenedor_existe "$host"; then
        ficha_causa '  ¿Qué brokers están vivos?' 'docker ps'
        ficha_causa '  Levantar el que falta'     "docker start ${host}"
    else
        # Sin un nombre limpio no se ofrece un 'docker start' a medias.
        ficha_causa '  ¿Qué brokers están vivos?' 'docker ps -a'
    fi

    ficha_cerrar
}

# ── Diagnóstico cuando el comando falla ──────────────────────
# El error es el momento de mayor valor pedagógico del lab. Se traduce
# y se entrega con los comandos para investigarlo. Nunca se lo traga.
diagnostico_error() {
    local salida="$1" destino="$2"

    ficha_abrir 'DIAGNÓSTICO'

    case "$salida" in
        *TimeoutException*)
            ficha_texto "TimeoutException al contactar ${destino}"
            ficha_vacia
            ficha_texto 'El broker no respondió. Tres causas, en orden de probabilidad.'
            ficha_causa '  1. El broker está caído'     'docker ps'
            ficha_causa '  2. La dirección no resuelve' 'revisa advertised.listeners'
            ficha_causa '  3. El puerto está tomado'    "lsof -i :${destino##*:}"
            ;;
        *ConnectException*)
            ficha_texto "ConnectException contra ${destino}"
            ficha_vacia
            ficha_texto 'Nadie escucha en esa dirección. El proceso Kafka no está'
            ficha_texto 'arriba, o quedó escuchando en otro puerto.'
            ficha_causa '  1. ¿Está corriendo?'     'docker ps'
            ficha_causa '  2. ¿Qué puerto publica?' "docker port ${BROKER}"
            ficha_causa '  3. ¿Qué dice el log?'    "docker logs ${BROKER} --tail 50"
            ;;
        *)
            ficha_texto 'El comando falló y el error no es uno de los conocidos.'
            ficha_texto 'Lo que devolvió Kafka está acá arriba, sin tocar.'
            ficha_vacia
            ficha_texto 'Revisa la guía del lab.'
            ;;
    esac

    ficha_cerrar
}

# ── Diagnóstico cuando no hay ni contenedor ──────────────────
diagnostico_sin_contenedor() {
    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto 'No hay ningún contenedor de Kafka corriendo en esta máquina.'
    ficha_vacia
    ficha_texto 'No es un error del comando. Todavía no hay a quién preguntarle.'
    ficha_causa '  1. ¿Levantaste el clúster?' 'docker compose up -d'
    ficha_causa '  2. ¿Desde qué directorio?'  'mi-cluster/'
    ficha_causa '  3. ¿Qué quedó vivo?'        'docker ps -a'
    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    ficha_init_color

    local destino rc=0 hay_broker=0
    local salida_status='' salida_repl=''

    BROKER=$(find_alive_kafka_container) || true
    if [ -n "${BROKER:-}" ]; then
        hay_broker=1
        resolve_kafka_broker
        destino="$BOOTSTRAP"
    else
        # Sin clúster no hay valor real que mostrar. Se usa el del lab y
        # el pie de la ficha avisa que ese contenedor no está corriendo.
        BROKER='kafka-broker-1'
        destino='kafka-broker-1:29092'
    fi

    # Los comandos corren ANTES de imprimir nada. Es la única forma de
    # saber si lo que se va a mostrar se puede ejecutar ahora mismo.
    if [ "$hay_broker" -eq 1 ]; then
        salida_status=$(docker exec "$BROKER" kafka-metadata-quorum \
            --bootstrap-server "$destino" describe --status 2>&1) || rc=$?
        if [ "$rc" -eq 0 ]; then
            salida_repl=$(docker exec "$BROKER" kafka-metadata-quorum \
                --bootstrap-server "$destino" describe --replication 2>&1) || rc=$?
        fi
    fi

    # Se valida ANTES de mostrar y antes de diagnosticar. kafka-metadata-quorum
    # puede escupir un stack trace por stdout y salir con código 0, así que el
    # código de salida no alcanza para saber si la salida sirve.
    local repl_ok=0 status_ok=0
    if [ "$hay_broker" -eq 1 ] && q_status_es_valido "$salida_status"; then
        status_ok=1
    fi
    if [ "$status_ok" -eq 1 ] && [ -n "$salida_repl" ] && q_repl_es_tabla "$salida_repl"; then
        repl_ok=1
    fi

    ficha_encabezado "$destino"
    if [ "$rc" -eq 0 ] && [ "$hay_broker" -eq 1 ] && [ "$repl_ok" -eq 0 ]; then
        # El comando salió bien pero la respuesta no sirve. El alumno tiene
        # que saberlo acá arriba, no solo al final.
        ficha_pie "$hay_broker" 1
    else
        ficha_pie "$hay_broker" "$rc"
    fi

    if [ "$hay_broker" -eq 0 ]; then
        diagnostico_sin_contenedor
        exit 1
    fi

    if [ "$status_ok" -eq 1 ]; then
        ficha_cruda 'Esto devolvió Kafka con describe --status' \
            "$(q_status_legible "$salida_status")"
    else
        ficha_cruda 'Kafka no devolvió el estado del quórum. Esto respondió:' \
            "$(q_linea_error "$salida_status")"
    fi
    echo ''

    if [ -n "$salida_repl" ]; then
        if [ "$repl_ok" -eq 1 ]; then
            ficha_cruda 'Esto devolvió Kafka con describe --replication' \
                "$(q_repl_legible "$salida_repl")"
            ficha_nota_salida 'Se omiten DirectoryId y las marcas de tiempo. Para verlo todo,'
            ficha_nota_salida 'corre el comando de arriba a mano.'
        else
            # No se maquilla en columnas lo que no es una tabla.
            ficha_cruda 'Kafka no devolvió una tabla. Esto respondió:' \
                "$(q_linea_error "$salida_repl")"
        fi
        echo ''
    fi

    if [ "$status_ok" -eq 0 ]; then
        diagnostico_error "$salida_status" "$destino"
        if [ "$rc" -eq 0 ]; then rc=1; fi
        exit "$rc"
    fi

    if [ "$repl_ok" -eq 0 ]; then
        diagnostico_parcial "$salida_status" "$salida_repl"
        if [ "$rc" -eq 0 ]; then rc=1; fi
        exit "$rc"
    fi

    diagnostico_quorum "$salida_status" "$salida_repl"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato de la ficha sin depender de un clúster vivo.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
