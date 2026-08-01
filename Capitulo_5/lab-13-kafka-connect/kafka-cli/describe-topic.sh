#!/bin/bash
# ============================================================
# describe-topic.sh · ficha didáctica sobre kafka-topics --describe
# ============================================================
# Familia LEE. Solo consulta, no toca nada. Kafka devuelve los hechos y
# no dice si están bien, así que el diagnóstico pone el veredicto que
# falta, con los datos que devolvió y nada más.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale nada más que
# lo de Kafka, porque las guías del curso hacen 'describe-topic.sh X | head -3'.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

# El lab-02 expone resolve_kafka_broker y los demás resolve_broker. El
# canónico usa la que encuentre, para no tener que tocar los common.sh.
resolver_broker() {
    if command -v resolve_broker >/dev/null 2>&1; then
        resolve_broker
    elif command -v resolve_kafka_broker >/dev/null 2>&1; then
        resolve_kafka_broker
    else
        echo "[ERROR] Este lab no expone resolve_broker ni resolve_kafka_broker." >&2
        exit 1
    fi
}

flag_desc() {
    case "$1" in
        --describe) echo "solo consulta, no toca nada" ;;
        *)          flag_desc_comun "$1" ;;
    esac
}

# ── Lectura de la salida de kafka-topics --describe ──────────
# La primera línea trae el resumen del tópico y las siguientes una por
# partición, con el formato "Campo: valor" separado por tabuladores.
t_resumen() {
    printf '%s\n' "$2" | awk -v c="$1:" '{
        for (i = 1; i <= NF; i++) if ($i == c) { print $(i + 1); exit }
    }'
}

# Es salida válida solo si aparece la línea de resumen con PartitionCount
# y ReplicationFactor. Sin eso no hay tópico que describir y se declara
# ilegible, nunca se estima.
t_es_descripcion() {
    printf '%s\n' "$1" | awk '
        /PartitionCount:/ && /ReplicationFactor:/ { ok = 1 }
        END { if (ok) exit 0; exit 1 }
    '
}

# Una fila por partición, con los campos ya separados.
# Imprime "<particion> <lider> <replicas> <isr>".
t_particiones() {
    printf '%s\n' "$1" | awk '
        /Partition:/ {
            part = ""; lider = ""; rep = ""; isr = ""
            for (i = 1; i <= NF; i++) {
                if ($i == "Partition:") part = $(i + 1)
                if ($i == "Leader:")    lider = $(i + 1)
                if ($i == "Replicas:")  rep = $(i + 1)
                if ($i == "Isr:")       isr = $(i + 1)
            }
            if (part != "" && rep != "") printf "%s %s %s %s\n", part, lider, rep, isr
        }
    '
}

# Cuántos elementos tiene una lista separada por comas.
t_contar() {
    printf '%s\n' "$1" | awk -F, '{ n = 0; for (i = 1; i <= NF; i++) if ($i != "") n++; print n }'
}

# Los ids que están en $1 pero no en $2, separados por coma.
t_faltantes() {
    printf '%s\n%s\n' "$1" "$2" | awk -F, '
        NR == 1 { for (i = 1; i <= NF; i++) if ($i != "") todos[i] = $i; n = NF; next }
        NR == 2 { for (i = 1; i <= NF; i++) if ($i != "") hay[$i] = 1 }
        END {
            sep = ""
            for (i = 1; i <= n; i++) {
                if (todos[i] != "" && !(todos[i] in hay)) { printf "%s%s", sep, todos[i]; sep = "," }
            }
        }
    '
}

# Rehace la salida de Kafka para que se pueda leer. Los valores no se
# tocan. La línea de resumen viene con cinco campos pegados por
# tabuladores y las de partición con ocho, y todo eso envuelto en 80
# columnas queda ilegible.
t_legible() {
    printf '%s\n' "$1" | awk '
        /PartitionCount:/ {
            for (i = 1; i <= NF; i++) {
                if ($i == "Topic:")             top = $(i + 1)
                if ($i == "PartitionCount:")    np = $(i + 1)
                if ($i == "ReplicationFactor:") rf = $(i + 1)
                if ($i == "Configs:")           { cfg = ""; for (j = i + 1; j <= NF; j++) cfg = cfg (cfg == "" ? "" : " ") $j }
            }
            printf "Topic %s\n", top
            printf "PartitionCount %s     ReplicationFactor %s\n", np, rf
            if (cfg != "") printf "Configs %s\n", cfg
            printf "\n"
            printf "%-11s %-8s %-11s %s\n", "Partition", "Leader", "Replicas", "Isr"
            next
        }
        /Partition:/ {
            part = ""; lider = ""; rep = ""; isr = ""
            for (i = 1; i <= NF; i++) {
                if ($i == "Partition:") part = $(i + 1)
                if ($i == "Leader:")    lider = $(i + 1)
                if ($i == "Replicas:")  rep = $(i + 1)
                if ($i == "Isr:")       isr = $(i + 1)
            }
            printf "%-11s %-8s %-11s %s\n", part, lider, rep, isr
        }
    '
}

t_particion_es() {
    if [ "$1" -eq 1 ]; then
        printf '1 partición'
    else
        printf '%s particiones' "$1"
    fi
}

t_broker_es() {
    if [ "$1" -eq 1 ]; then
        printf '1 broker'
    else
        printf '%s brokers' "$1"
    fi
}

# ── Encabezado de la ficha ───────────────────────────────────
ficha_encabezado() {
    local destino="$1" topico="$2"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Preguntarle a Kafka cómo está armado el tópico ${topico} y si"
    ficha_texto 'sus réplicas están completas'

    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-topics --bootstrap-server $destino \\"
    ficha_comando "    --describe --topic $topico"

    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$destino" ''
    ficha_flag '--describe'         ''         ''
    ficha_flag '--topic'            "$topico"  ''

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'PartitionCount'    'en cuántos pedazos está partido el tópico'
    ficha_campo 'ReplicationFactor' 'cuántas copias de cada pedazo hay repartidas'
    ficha_campo 'Leader'            'qué broker atiende esa partición. Los demás lo copian'
    ficha_campo 'Replicas'          'los brokers que deberían tener copia'
    ficha_campo 'Isr'               'los que la tienen al día de verdad. Si es más corto que Replicas, falta alguien'
    ficha_campo 'Elr'               'las réplicas que quedaron elegibles tras una caída. Vacío es lo normal'

    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, --bootstrap-server lleva la IP real de tu broker.'
    echo ''
}

# ── Diagnóstico ──────────────────────────────────────────────
# Todo sale de la salida que Kafka devolvió. Nada se estima.
diagnostico_topico() {
    local salida="$1" topico="$2"
    local nparts rf minisr filas
    local total=0 incompletas=0 sin_lider=0 rf_real isr_minimo=
    local pares='' agrupado
    local linea part lider rep isr n_rep n_isr faltan
    local lideres='' tolerancia mayoria

    nparts=$(t_resumen 'PartitionCount' "$salida")
    rf=$(t_resumen 'ReplicationFactor' "$salida")
    filas=$(t_particiones "$salida")

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "El tópico ${topico} tiene $(t_particion_es "$nparts") y guarda ${rf} copias de cada una."

    # Recorrido de las particiones. Se cuenta lo que se lee, no se supone.
    while IFS=' ' read -r part lider rep isr; do
        [ -z "$part" ] && continue
        total=$(( total + 1 ))
        n_rep=$(t_contar "$rep")
        n_isr=$(t_contar "$isr")
        if [ "$lider" = "none" ] || [ -z "$lider" ]; then
            sin_lider=$(( sin_lider + 1 ))
        else
            lideres="${lideres}${lider}
"
        fi
        if [ -z "$isr_minimo" ] || [ "$n_isr" -lt "$isr_minimo" ]; then
            isr_minimo="$n_isr"
        fi
        if [ "$n_isr" -lt "$n_rep" ]; then
            incompletas=$(( incompletas + 1 ))
            faltan=$(t_faltantes "$rep" "$isr")
            # Se acumula "broker particion" para agrupar despues. El
            # diagnostico resume: una linea por broker que falta, no una
            # por particion. Con 12 particiones serian 12 lineas diciendo
            # un solo hecho, y para listar ya esta la salida cruda de arriba.
            pares="${pares}$(printf '%s\n' "$faltan" | tr ',' '\n' | sed "s/\$/ ${part}/")
"
        fi
    done <<EOF
$filas
EOF

    if [ "$total" -eq 0 ]; then
        ficha_texto 'Kafka no devolvió ninguna partición, así que no puedo decirte más.'
        ficha_cerrar
        return 0
    fi

    if [ "$incompletas" -eq 0 ] && [ "$sin_lider" -eq 0 ]; then
        ficha_texto "Las ${total} particiones tienen su ISR completo. Nadie falta."
    fi

    if [ -n "$pares" ]; then
        agrupado=$(printf '%s\n' "$pares" | awk 'NF == 2 {
            n[$1]++
            if (lista[$1] == "") lista[$1] = $2; else lista[$1] = lista[$1] ", " $2
        }
        END { for (b in n) printf "%s|%s|%s\n", b, n[b], lista[b] }' | sort -n)
        local br cuantas cuales
        while IFS='|' read -r br cuantas cuales; do
            [ -z "$br" ] && continue
            if [ "$cuantas" -eq "$total" ]; then
                ficha_warn "El broker ${br} está fuera del ISR de las ${total} particiones."
            elif [ "$cuantas" -le 6 ]; then
                ficha_warn "El broker ${br} está fuera del ISR de $(t_particion_es "$cuantas") de ${total}, la ${cuales}."
            else
                ficha_warn "El broker ${br} está fuera del ISR de ${cuantas} de las ${total} particiones."
            fi
        done <<AGRUPADO
$agrupado
AGRUPADO
    fi
    if [ "$sin_lider" -gt 0 ]; then
        ficha_warn "$(t_particion_es "$sin_lider") sin líder. Eso no se lee ni se escribe."
    fi

    # Reparto del liderazgo, contado sobre los líderes reales.
    if [ -n "$lideres" ]; then
        local distintos maximo
        distintos=$(printf '%s' "$lideres" | sort -u | grep -c '[0-9]')
        maximo=$(printf '%s' "$lideres" | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
        if [ "$distintos" -gt 1 ]; then
            ficha_texto "El liderazgo está repartido entre ${distintos} brokers. El que más atiende lleva ${maximo} de ${total} particiones."
        else
            ficha_warn "Las ${total} particiones las atiende un solo broker. Si se cae, se cae todo."
        fi
    fi

    ficha_vacia

    # Cuántos brokers aguanta perder, según el factor de replicación real
    # y el min.insync.replicas que tenga puesto el tópico.
    minisr=$(printf '%s\n' "$salida" | sed -n 's/.*min\.insync\.replicas=\([0-9][0-9]*\).*/\1/p' | head -1)
    rf_real="$rf"
    if [ -n "$minisr" ]; then
        ficha_texto "Este tópico guarda ${rf_real} copias y necesita ${minisr} al día para aceptar escrituras."
        tolerancia=$(( isr_minimo - minisr ))
        if [ "$tolerancia" -gt 0 ]; then
            ficha_texto "Hoy la partición peor parada tiene ${isr_minimo}, así que todavía toleras perder $(t_broker_es "$tolerancia") más."
        elif [ "$tolerancia" -eq 0 ]; then
            ficha_warn "Hoy la peor parada tiene justo ${isr_minimo}. Si cae un broker más, este tópico deja de aceptar escrituras."
        else
            ficha_warn "Hoy la peor parada tiene ${isr_minimo} y hacen falta ${minisr}. Este tópico ya no acepta escrituras."
        fi
    else
        mayoria=$(( rf_real / 2 + 1 ))
        ficha_texto "Con ${rf_real} copias, este tópico tolera perder $(t_broker_es "$(( rf_real - mayoria ))")"
        ficha_texto 'sin perder datos.'
    fi

    ficha_cerrar
}

diagnostico_ilegible() {
    local salida="$1" topico="$2"
    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "Kafka no devolvió la descripción de ${topico}. Esto respondió:"
    ficha_vacia
    ficha_texto 'Puede que el tópico no exista todavía, o que el nombre tenga una'
    ficha_texto 'letra de más.'
    ficha_causa '  ¿Qué tópicos hay?' 'kafka-cli/list-topics.sh'
    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    if [ $# -lt 1 ]; then
        echo "Uso: $0 <NOMBRE_TOPICO>" >&2
        exit 1
    fi
    local topico="$1"

    ficha_init_color
    resolver_broker
    local destino="$BOOTSTRAP" rc=0 salida='' configs=''

    salida=$(docker exec "$BROKER" kafka-topics \
        --bootstrap-server "$destino" \
        --describe --topic "$topico" 2>&1) || rc=$?

    configs=$(docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$destino" \
        --entity-type topics --entity-name "$topico" \
        --describe --all 2>/dev/null | head -50) || configs=''

    # Sin terminal se emite solo lo de Kafka, tal cual, para no romper las
    # tuberías de las guías.
    if ! ficha_activa; then
        printf '%s\n' "$salida"
        if [ -n "$configs" ]; then
            printf '%s\n' "$configs"
        fi
        exit "$rc"
    fi

    ficha_encabezado "$destino" "$topico"

    if [ "$rc" -ne 0 ] || ! t_es_descripcion "$salida"; then
        ficha_cruda 'Kafka no devolvió una descripción. Esto respondió:' \
            "$(ficha_linea_error "$salida")"
        echo ''
        diagnostico_ilegible "$salida" "$topico"
        if [ "$rc" -eq 0 ]; then rc=1; fi
        exit "$rc"
    fi

    ficha_cruda 'Esto devolvió Kafka' "$(t_legible "$salida")"
    ficha_nota_salida 'Se omiten TopicId, Elr y LastKnownElr. Para verlo todo, corre el'
    ficha_nota_salida 'comando de arriba a mano.'
    echo ''
    if [ -n "$configs" ]; then
        ficha_cruda 'Y estas son las configuraciones efectivas del tópico' "$configs"
        echo ''
    fi

    diagnostico_topico "$salida" "$topico"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato sin depender de un clúster vivo.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
