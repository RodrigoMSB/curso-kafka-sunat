#!/bin/bash
# ============================================================
# Motor de ficha didáctica · piloto Lab 02
# ============================================================
# Dibuja la caja de la ficha con su marco, sus secciones y sus filas
# con ajuste de línea y color. No sabe nada de Kafka. El vocabulario
# lo pone el wrapper que lo importa.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin arrays
# asociativos (declare -A), sin mapfile, sin grep -P, sin sed -i.

FICHA_ANCHO=76

# ── ¿Se dibuja la ficha? ─────────────────────────────────────
# Solo en una terminal interactiva. Al tuberiar o redirigir sale nada más
# que lo que devolvió Kafka, sin marco, sin leyenda y sin diagnóstico.
# No es cosmética. Las guías publicadas hacen
#   kafka-cli/describe-topic.sh novatech.gps.realtime | head -3
# y con la ficha delante eso le mostraría al alumno tres líneas de marco
# en vez de sus datos. Es la misma regla de 'ls', que pinta colores en
# pantalla y no los pinta al tubo.
#
# FICHA_FORZAR=1 es la costura de test. El runner captura con $( ), que no
# es TTY, y sin esto no podría ver la ficha nunca. Sin la variable, el
# comportamiento es exactamente el de siempre.
ficha_activa() {
    if [ "${FICHA_FORZAR:-}" = "1" ]; then
        return 0
    fi
    [ -t 1 ]
}

# ── Colores ──────────────────────────────────────────────────
# Quedan VACÍOS si no hay TTY, si NO_COLOR está seteada o si TERM=dumb.
# Así la ficha redirigida a archivo no lleva un solo código ANSI.
ficha_init_color() {
    F_MARCO=''
    F_TITULO=''
    F_BIN=''
    F_FLAG=''
    F_VAL=''
    F_FLECHA=''
    F_EXPL=''
    F_WARN=''
    F_NOTA=''
    F_OFF=''

    if [ -n "${NO_COLOR:-}" ]; then return 0; fi
    if [ "${TERM:-}" = "dumb" ]; then return 0; fi
    if [ ! -t 1 ]; then return 0; fi

    F_MARCO=$(printf '\033[0;36m')
    F_TITULO=$(printf '\033[1;36m')
    F_BIN=$(printf '\033[1;32m')
    F_FLAG=$(printf '\033[1;33m')
    F_VAL=$(printf '\033[0;36m')
    F_FLECHA=$(printf '\033[0;90m')
    F_EXPL=$(printf '\033[0;37m')
    F_WARN=$(printf '\033[0;33m')
    F_NOTA=$(printf '\033[0;90m')
    F_OFF=$(printf '\033[0m')
}

# ── Ancho visible, en caracteres y sin depender del locale ───
# Los acentos ocupan 2 bytes y las cajas Unicode 3, así que medir con
# ${#var} da bytes cuando el locale no es UTF-8 y descuadra el marco.
# Se borran los bytes de continuación UTF-8 (0x80-0xBF) y se cuentan
# los que quedan, que son exactamente uno por carácter. Todo el
# cálculo va bajo LC_ALL=C para que no dependa del entorno del alumno.
# Se resuelve dentro de bash, sin lanzar procesos. Se llama una vez por
# palabra al ajustar las líneas, y con tres procesos por llamada la ficha
# tardaba segundos en dibujarse.
ficha_ancho_visible() {
    local LC_ALL=C
    local limpio=${1//[$'\200'-$'\277']/}
    printf '%s' "${#limpio}"
}

# La versión lenta pero obvia, que sirve de patrón de comparación en los
# tests. Si las dos dejan de coincidir, la rápida está mal.
ficha_ancho_visible_lento() {
    printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | LC_ALL=C wc -c | tr -d ' '
}

ficha_espacios() {
    if [ "$1" -gt 0 ]; then
        printf "%${1}s" ''
    fi
    return 0
}

# Las llaves de ${s} son obligatorias. Bash 3.2 en macOS toma los bytes
# altos de '─' como parte del nombre de la variable si se escribe "$s─".
ficha_raya() {
    local i=0 s=''
    while [ "$i" -lt "$1" ]; do
        s="${s}─"
        i=$(( i + 1 ))
    done
    printf '%s' "$s"
}

# ── Una fila del marco ───────────────────────────────────────
# $1 = texto ya coloreado, que es el que se imprime
# $2 = mismo texto sin códigos ANSI, que es el que se mide
ficha_fila() {
    local coloreado="$1" plano="$2" n relleno
    n=$(ficha_ancho_visible "$plano")
    relleno=$(( FICHA_ANCHO - 4 - n ))
    printf '%s│%s  %s%s%s│%s\n' \
        "$F_MARCO" "$F_OFF" "$coloreado" "$(ficha_espacios "$relleno")" "$F_MARCO" "$F_OFF"
}

ficha_vacia() {
    ficha_fila '' ''
}

# ── Bordes ───────────────────────────────────────────────────
ficha_abrir() {
    local titulo="$1" n
    n=$(ficha_ancho_visible "$titulo")
    printf '%s┌─ %s%s%s %s┐%s\n' \
        "$F_MARCO" "$F_TITULO" "$titulo" "$F_MARCO" "$(ficha_raya $(( FICHA_ANCHO - 5 - n )))" "$F_OFF"
}

ficha_medio() {
    local titulo="$1" n
    n=$(ficha_ancho_visible "$titulo")
    printf '%s├─ %s%s%s %s┤%s\n' \
        "$F_MARCO" "$F_TITULO" "$titulo" "$F_MARCO" "$(ficha_raya $(( FICHA_ANCHO - 5 - n )))" "$F_OFF"
}

ficha_cerrar() {
    printf '%s└%s┘%s\n' "$F_MARCO" "$(ficha_raya $(( FICHA_ANCHO - 2 )))" "$F_OFF"
}

# ── Bloque de texto con ajuste de línea ──────────────────────
# $1 = prefijo coloreado   $2 = prefijo plano
# $3 = texto               $4 = color del texto
# $5 = sangría de las líneas de continuación
ficha_bloque() {
    local pref_c="$1" pref_p="$2" texto="$3" color="$4" sangria="$5"
    local util cuerpo palabra n cont
    util=$(( FICHA_ANCHO - 4 ))
    cont=$(ficha_espacios "$sangria")
    cuerpo=''

    set -f
    for palabra in $texto; do
        if [ -z "$cuerpo" ]; then
            n=$(ficha_ancho_visible "${pref_p}${palabra}")
        else
            n=$(ficha_ancho_visible "${pref_p}${cuerpo} ${palabra}")
        fi
        if [ "$n" -gt "$util" ] && [ -n "$cuerpo" ]; then
            ficha_fila "${pref_c}${color}${cuerpo}${F_OFF}" "${pref_p}${cuerpo}"
            pref_c="$cont"
            pref_p="$cont"
            cuerpo="$palabra"
        elif [ -z "$cuerpo" ]; then
            cuerpo="$palabra"
        else
            cuerpo="${cuerpo} ${palabra}"
        fi
    done
    set +f

    if [ -n "$cuerpo" ]; then
        ficha_fila "${pref_c}${color}${cuerpo}${F_OFF}" "${pref_p}${cuerpo}"
    fi
}

# ── Filas de uso corriente ───────────────────────────────────

# Párrafo simple.
ficha_texto() {
    ficha_bloque '' '' "$1" "$F_EXPL" 0
}

# Advertencia, con el ⚠ al frente.
ficha_warn() {
    ficha_bloque "${F_WARN}⚠ " '⚠ ' "$1" "$F_WARN" 2
}

# Campo de salida, del estilo "LeaderEpoch → cuántas veces hubo elección".
ficha_campo() {
    local campo="$1" desc="$2"
    ficha_bloque \
        "${F_FLAG}${campo}${F_OFF} ${F_FLECHA}→${F_OFF} " \
        "${campo} → " \
        "$desc" "$F_EXPL" 4
}

# Flag con su valor real, "--bootstrap-server kafka-broker-1:29092 → ...".
# $3 es la clave a buscar en flag_desc cuando el significado lo aporta
# el valor y no la etiqueta, como en "describe --status".
# Si flag_desc no conoce la clave, el flag igual aparece, con una nota.
# Nunca se cae en silencio. Una ficha que omite un flag miente por omisión.
ficha_flag() {
    local flag="$1" valor="$2" clave="${3:-}" desc
    [ -z "$clave" ] && clave="$flag"
    desc=$(flag_desc "$clave")
    [ -z "$desc" ] && desc="(ver la guía del lab)"

    if [ -n "$valor" ]; then
        ficha_bloque \
            "${F_FLAG}${flag}${F_OFF} ${F_VAL}${valor}${F_OFF} ${F_FLECHA}→${F_OFF} " \
            "${flag} ${valor} → " \
            "$desc" "$F_EXPL" 4
    else
        ficha_bloque \
            "${F_FLAG}${flag}${F_OFF} ${F_FLECHA}→${F_OFF} " \
            "${flag} → " \
            "$desc" "$F_EXPL" 4
    fi
}

# Línea de comando, con el binario en verde y los flags en amarillo.
# Respeta la sangría de las líneas de continuación. En ellas la primera
# palabra no es el binario, así que no va en verde.
ficha_comando() {
    local linea="$1" sangria resto coloreado='' plano='' palabra primera=1
    sangria="${linea%%[! ]*}"
    resto="${linea#"$sangria"}"
    [ -n "$sangria" ] && primera=0

    set -f
    for palabra in $resto; do
        case "$palabra" in
            -*)   coloreado="${coloreado}${F_FLAG}${palabra}${F_OFF} " ;;
            '\\') coloreado="${coloreado}${F_MARCO}${palabra}${F_OFF} " ;;
            *)
                if [ "$primera" = "1" ]; then
                    coloreado="${coloreado}${F_BIN}${palabra}${F_OFF} "
                else
                    coloreado="${coloreado}${F_VAL}${palabra}${F_OFF} "
                fi
                ;;
        esac
        plano="${plano}${palabra} "
        primera=0
    done
    set +f

    ficha_fila "${sangria}${coloreado% }" "${sangria}${plano% }"
}

# Causa probable más el comando para verificarla, en dos columnas.
# No usa ficha_bloque porque el ajuste de línea colapsa la alineación.
ficha_causa() {
    local texto="$1" cmd="$2" n relleno esp total
    n=$(ficha_ancho_visible "$texto")
    relleno=$(( 36 - n ))
    [ "$relleno" -lt 1 ] && relleno=1
    esp=$(ficha_espacios "$relleno")

    # Si el comando no entra en la misma fila, baja a la siguiente en vez
    # de desbordar el marco. Un comando cortado no se puede copiar.
    total=$(ficha_ancho_visible "${texto}${esp}${cmd}")
    if [ "$total" -gt $(( FICHA_ANCHO - 4 )) ]; then
        ficha_fila "${F_EXPL}${texto}${F_OFF}" "$texto"
        ficha_fila "    ${F_BIN}${cmd}${F_OFF}" "    ${cmd}"
        return 0
    fi

    ficha_fila "${F_EXPL}${texto}${F_OFF}${esp}${F_BIN}${cmd}${F_OFF}" "${texto}${esp}${cmd}"
}

# ── Fuera del marco ──────────────────────────────────────────

# Una sola línea, la más informativa de una salida rota. El stack trace
# completo no le aporta nada al alumno. El orden de preferencia importa,
# porque Kafka manda el dato útil en un WARN y después una excepción
# genérica que no dice nada.
ficha_linea_error() {
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

# Nota al pie.
ficha_nota() {
    printf '%s  %s%s\n' "$F_NOTA" "$1" "$F_OFF"
}

# Nota al pie de advertencia, para marcar lo que no se puede ejecutar.
ficha_nota_warn() {
    printf '%s  ⚠ %s%s\n' "$F_WARN" "$1" "$F_OFF"
}

# Salida de una herramienta, rotulada e indentada para que no se confunda
# con la ficha. Los VALORES no se tocan nunca. Lo único que se hace acá es
# envolver las líneas largas, para que ninguna quede partida por el
# terminal. Envolver conserva el texto entero.
#
# CUÁNDO SE ENVUELVE Y CUÁNDO NO. Es la distinción que decide cuál de las
# dos funciones usar.
#
#   ficha_cruda           la salida es TABULAR. Se deja tal cual. Envolver
#                         una tabla la destruye. El nombre de archivo cae al
#                         renglón de abajo y deja de alinearse con su tamaño
#                         y su fecha. Ejemplo, un ls -la o la tabla de
#                         particiones.
#
#   ficha_cruda_envuelta  la línea NO tiene columnas que romper. Pares
#                         clave=valor, mensajes de error, prosa. Ahí no hay
#                         nada que se desalinee y sin envolver se sale de la
#                         pantalla. Ejemplo, el "Found metadata" de
#                         kafka-storage info, que son 114 columnas.
#
# El ancho de 76 rige para la CAJA, que es lo que dibujamos nosotros.
ficha_cruda() {
    local rotulo="$1" texto="$2" l
    # Rótulo vacío significa que el bloque ya viene anunciado por otra cosa,
    # como el [N/4] de los wrappers de varios pasos. Ahí no se imprime una
    # línea en blanco de adorno.
    if [ -n "$rotulo" ]; then
        printf '%s  %s%s\n' "$F_NOTA" "$rotulo" "$F_OFF"
    fi
    printf '%s\n' "$texto" | while IFS= read -r l; do
        if [ -z "$l" ]; then
            echo ''
        else
            printf '    %s\n' "$l"
        fi
    done
}

# Variante para un texto de una sola línea larguísima, como el mensaje de
# una excepción de Java. Ahí no hay columnas que romper y sin envolver se
# sale de la pantalla. NO se usa para salidas tabulares.
ficha_cruda_envuelta() {
    local rotulo="$1" texto="$2" l
    if [ -n "$rotulo" ]; then
        printf '%s  %s%s\n' "$F_NOTA" "$rotulo" "$F_OFF"
    fi
    printf '%s\n' "$texto" | ficha_envolver "$(( FICHA_ANCHO - 4 ))" | while IFS= read -r l; do
        if [ -z "$l" ]; then
            echo ''
        else
            printf '    %s\n' "$l"
        fi
    done
}

# Envuelve por espacios a lo ancho pedido, con sangría de 2 en las líneas
# de continuación. Si una palabra sola no entra, la corta. Nunca descarta
# texto. Trabaja en bytes, que es correcto porque la salida de las
# herramientas de Kafka es ASCII.
ficha_envolver() {
    awk -v ancho="$1" '
    {
        resto = $0
        pref = ""
        while (1) {
            disp = ancho - length(pref)
            if (length(resto) <= disp) { print pref resto; break }
            corte = 0
            for (i = disp; i > int(disp / 2); i--) {
                if (substr(resto, i, 1) == " ") { corte = i; break }
            }
            if (corte == 0) corte = disp
            trozo = substr(resto, 1, corte)
            sub(/ +$/, "", trozo)
            print pref trozo
            resto = substr(resto, corte + 1)
            sub(/^ +/, "", resto)
            pref = "  "
        }
    }'
}

# Nota gris al pie de una salida reformateada, alineada con ella.
ficha_nota_salida() {
    printf '%s    %s%s\n' "$F_NOTA" "$1" "$F_OFF"
}

# ── Diccionario de flags compartido ──────────────────────────
# Viaja siempre junto al motor, así que se importa desde acá y el
# replicador no tiene que cablearlo en cada common.sh.
FICHA_FLAGS="$(dirname "${BASH_SOURCE[0]}")/flags.sh"
if [ -f "$FICHA_FLAGS" ]; then
    source "$FICHA_FLAGS"
fi

# ── Familia operativa ────────────────────────────────────────
# La ficha de LECCIÓN explica un comando para que el alumno lo entienda:
# se lee en modo estudio y puede permitirse quince líneas. La OPERATIVA
# es otra cosa. La corre alguien que está por destruir algo, o que ya
# rompió el lab y está apurado, y su trabajo es que esa persona sepa qué
# conserva y qué pierde ANTES de apretar enter -- no enseñarle nada.
#
# De ahí el techo de 10 líneas: no es estética, es que una pantalla de
# advertencia larga no se lee. Cuatro bloques fijos y se acabó.
#
# No es un segundo motor: usa la misma fontanería (ficha_activa,
# ficha_abrir/medio/cerrar, ficha_bloque) que la familia de lección. Dos
# implementaciones del ancho visible serían el mismo pecado que las
# guardias inline que la SPEC-66 vino a sacar.
#
#   ficha_op <titulo> <que_hace> <conserva> <destruye> <cuando>
#
# El bloque DESTRUYE nombra el proyecto compose al que se limita, que es
# el contrato heredado del F5: nada se destruye fuera del propio proyecto.
ficha_op() {
    ficha_activa || return 0
    ficha_init_color

    local titulo="$1" hace="$2" conserva="$3" destruye="$4" cuando="$5"

    ficha_abrir "$titulo"
    ficha_bloque "${F_FLAG}QUÉ HACE${F_OFF}  ${F_FLECHA}→${F_OFF} " 'QUÉ HACE  → ' \
                 "$hace" "$F_EXPL" 4
    ficha_bloque "${F_BIN}CONSERVA${F_OFF}  ${F_FLECHA}→${F_OFF} " 'CONSERVA  → ' \
                 "$conserva" "$F_EXPL" 4
    ficha_bloque "${F_WARN}DESTRUYE${F_OFF}  ${F_FLECHA}→${F_OFF} " 'DESTRUYE  → ' \
                 "$destruye" "$F_WARN" 4
    ficha_bloque "${F_NOTA}CUÁNDO${F_OFF}    ${F_FLECHA}→${F_OFF} " 'CUÁNDO    → ' \
                 "$cuando" "$F_NOTA" 4
    ficha_cerrar
}

# Encabezado del validador (90-test-lab.sh). Mismo techo, mismo marco,
# pero su contenido es la lista de lo que ese lab verifica -- que es
# distinta en cada uno. Se pasa una línea por chequeo.
#
#   ficha_op_verifica <titulo> <chequeo>...
ficha_op_verifica() {
    ficha_activa || return 0
    ficha_init_color

    local titulo="$1"; shift
    local c

    ficha_abrir "$titulo"
    for c in "$@"; do
        ficha_bloque "${F_FLECHA}·${F_OFF} " '· ' "$c" "$F_EXPL" 2
    done
    ficha_cerrar
}
