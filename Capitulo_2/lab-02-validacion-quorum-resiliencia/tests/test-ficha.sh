#!/bin/bash
# ============================================================
# test-ficha.sh · pruebas del parser y del diagnóstico
# ============================================================
# Corre en frío. Sin Docker, sin clúster, sin red. Los fixtures son
# salidas de Kafka capturadas del clúster real, byte a byte, y el
# comando 'docker' se reemplaza por un doble que las sirve.
#
#   bash tests/test-ficha.sh
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -u

DIR_TESTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_LAB="$(cd "$DIR_TESTS/.." && pwd)"
DIR_FIX="$DIR_TESTS/fixtures"

# Sin color, para que las comparaciones no dependan de si hay TTY.
NO_COLOR=1
export NO_COLOR

TMP="${TMPDIR:-/tmp}/test-ficha-$$"
mkdir -p "$TMP/bin"
limpiar() { rm -rf "$TMP"; }
trap limpiar EXIT

# ── Contador ─────────────────────────────────────────────────
N_TOTAL=0
N_VERDE=0

verde() {
    N_TOTAL=$(( N_TOTAL + 1 ))
    N_VERDE=$(( N_VERDE + 1 ))
    printf '  verde  %s\n' "$1"
}

rojo() {
    N_TOTAL=$(( N_TOTAL + 1 ))
    printf '  ROJO   %s\n' "$1"
    printf '           esperado  %s\n' "$2"
    printf '           obtenido  %s\n' "$3"
}

recortar() {
    printf '%s' "$1" | tr '\n' '|' | cut -c1-120
}

afirmar_contiene() {
    case "$3" in
        *"$2"*) verde "$1" ;;
        *)      rojo "$1" "que contuviera <$2>" "$(recortar "$3")" ;;
    esac
}

afirmar_no_contiene() {
    case "$3" in
        *"$2"*) rojo "$1" "que NO contuviera <$2>" "$(recortar "$3")" ;;
        *)      verde "$1" ;;
    esac
}

afirmar_igual() {
    if [ "$2" = "$3" ]; then
        verde "$1"
    else
        rojo "$1" "<$2>" "<$3>"
    fi
}

# ── Fixtures ─────────────────────────────────────────────────
# La primera línea de cada fixture documenta cómo se capturó. El resto es
# la salida de Kafka sin tocar. Si falta esa línea se aborta, porque
# entonces estaríamos comiéndonos la primera línea de datos.
fx() {
    local archivo="$DIR_FIX/$1"
    if [ ! -f "$archivo" ]; then
        printf 'FIXTURE QUE NO EXISTE: %s\n' "$1" >&2
        exit 2
    fi
    case "$(sed -n '1p' "$archivo")" in
        '#'*) ;;
        *)
            printf 'FIXTURE SIN LINEA DE CAPTURA: %s\n' "$1" >&2
            exit 2
            ;;
    esac
    sed '1d' "$archivo"
}

# Deja el fixture ya pelado en un archivo, para que lo sirva el doble.
fx_archivo() {
    fx "$1" > "$TMP/$1"
    printf '%s' "$TMP/$1"
}

# ── Doble del comando docker ─────────────────────────────────
# Responde con fixtures según lo que le pidan. Así el wrapper entero se
# puede correr sin Docker, incluido su código de salida.
cat > "$TMP/bin/docker" <<'DOBLE'
#!/bin/sh
args="$*"
case "$args" in
    *"describe --status"*)
        [ -n "${T_STATUS:-}" ] && cat "$T_STATUS"
        exit "${T_STATUS_RC:-0}"
        ;;
    *"describe --replication"*)
        [ -n "${T_REPL:-}" ] && cat "$T_REPL"
        exit "${T_REPL_RC:-0}"
        ;;
esac
case "$args" in
    ps*)
        nombre=$(printf '%s' "$args" | sed -n 's/.*name=^\([^$]*\)\$.*/\1/p')
        if [ -n "$nombre" ]; then
            [ -n "${T_PS:-}" ] && printf '%s\n' "$T_PS" | grep "^${nombre}$"
            exit 0
        fi
        [ -n "${T_PS:-}" ] && printf '%s\n' "$T_PS"
        exit 0
        ;;
esac
exit 0
DOBLE
chmod +x "$TMP/bin/docker"

# Corre el wrapper completo contra los fixtures dados.
# $1 = status, $2 = replication, $3 = contenedores visibles
# Deja la salida en SALIDA y el código en CODIGO.
correr_wrapper() {
    local f_status="$1" f_repl="$2" contenedores="$3"
    local ruta_status='' ruta_repl='' ahora=''
    [ -n "$f_status" ] && ruta_status=$(fx_archivo "$f_status")
    [ -n "$f_repl" ] && ruta_repl=$(fx_archivo "$f_repl")

    # El reloj se fija al instante en que se capturó el fixture. Sin esto, un
    # fixture sano da DEGRADADO apenas pasan 15 segundos de haberlo tomado, y
    # la prueba se pudriría sola con el tiempo.
    if [ -n "$ruta_repl" ]; then
        ahora=$(awk '
            NR == 1 { for (i = 1; i <= NF; i++) c[$i] = i; next }
            ("LastFetchTimestamp" in c) {
                t = $(c["LastFetchTimestamp"]) + 0
                if (t > m) m = t
            }
            END { if (m > 0) print m }' "$ruta_repl")
    fi

    SALIDA=$(PATH="$TMP/bin:$PATH" \
        T_STATUS="$ruta_status" T_REPL="$ruta_repl" T_PS="$contenedores" \
        Q_AHORA_MS="$ahora" \
        /bin/bash "$DIR_LAB/bin/check-quorum.sh" 2>&1)
    CODIGO=$?
}

BROKERS='kafka-broker-1
kafka-broker-2
kafka-broker-3'

# Las funciones de parseo se importan sin ejecutar el wrapper.
# La variable NO se exporta: si la heredaran los hijos, el wrapper que corre
# correr_wrapper tampoco ejecutaría su main y todo saldría vacío.
FICHA_SOLO_FUNCIONES=1
# shellcheck source=../bin/check-quorum.sh
. "$DIR_LAB/bin/check-quorum.sh"
unset FICHA_SOLO_FUNCIONES

# El wrapper trae 'set -euo pipefail' y al importarlo queda encendido acá.
# En un runner de tests eso es veneno: la primera aserción que falle corta
# la corrida y no se ve el resto.
set +e
set +o pipefail

ficha_init_color

echo ''
echo 'Regresiones de los bugs que este piloto ya sufrió'

# ── no_inventa_votantes ──────────────────────────────────────
# El stack trace de Kafka se contaba como filas de la tabla y el
# diagnóstico afirmaba 13 votantes y una mayoría de 7.
if q_repl_es_tabla "$(fx replication-stacktrace.txt)"; then
    rojo 'no_inventa_votantes · el validador rechaza el stack trace' \
        'que q_repl_es_tabla lo rechazara' 'lo tomó por tabla'
else
    verde 'no_inventa_votantes · el validador rechaza el stack trace'
fi

correr_wrapper status-sano.txt replication-stacktrace.txt "$BROKERS"
afirmar_no_contiene 'no_inventa_votantes · no afirma un quórum' 'Quórum ' "$SALIDA"
afirmar_contiene 'no_inventa_votantes · declara lo que no pudo leer' \
    'no puedo decirte cuántos votantes están al día' "$SALIDA"

# ── nombre_broker_sin_dos_puntos ─────────────────────────────
# La ficha ofrecía 'docker start kafka-broker-1:', que no funciona.
HOST_WARN=$(q_host_error "$(fx error-dns-warn.txt)")
afirmar_igual 'nombre_broker_sin_dos_puntos · formato WARN de Kafka 4.x' \
    'kafka-broker-3' "$HOST_WARN"
afirmar_no_contiene 'nombre_broker_sin_dos_puntos · sin dos puntos pegados' \
    ':' "$HOST_WARN"

# ── json_con_espacios ────────────────────────────────────────
# El JSON real trae espacios y el parser se quedaba con "[{"id":".
VOTERS=$(q_valor 'CurrentVoters' "$(fx status-sano.txt)")
afirmar_contiene 'json_con_espacios · el valor llega entero' \
    'kafka-broker-3:39094' "$VOTERS"
afirmar_igual 'json_con_espacios · cuenta los 3 votantes' \
    '3' "$(q_contar_ids "$VOTERS")"

# ── lag_coincide_con_tabla ───────────────────────────────────
# El diagnóstico leía MaxFollowerLag de otra consulta y se contradecía
# con la tabla que el alumno tenía delante.
LAG_TABLA=$(fx replication-degradado.txt \
    | awk 'NR == 1 { for (i = 1; i <= NF; i++) c[$i] = i; next }
           { l = $(c["Lag"]) + 0; if (l > m) m = l }
           END { print m + 0 }')
correr_wrapper status-degradado.txt replication-degradado.txt "$BROKERS"
afirmar_contiene 'lag_coincide_con_tabla · el diagnóstico usa la columna Lag' \
    "va ${LAG_TABLA} mensajes atrás" "$SALIDA"

# ── sin_nombre_usable_no_ofrece_comando ──────────────────────
# Entradas adversarias, NO fixtures: son errores que Kafka no produce,
# escritos acá a propósito para atacar al extractor.
for BASURA in \
    'java.net.UnknownHostException: ???' \
    'org.apache.kafka.common.KafkaException: Failed to create new KafkaAdminClient' \
    'DNS resolution failed for   '
do
    afirmar_igual "sin_nombre_usable_no_ofrece_comando · <$(printf '%.32s' "$BASURA")>" \
        '' "$(q_host_error "$BASURA")"
done

echo ''
echo 'Los cuatro escenarios y sus códigos de salida'

correr_wrapper status-sano.txt replication-sano.txt "$BROKERS"
afirmar_contiene 'escenario sano · diagnóstico' 'Quórum SANO' "$SALIDA"
afirmar_igual 'escenario sano · código de salida' '0' "$CODIGO"
TODAS="$SALIDA"

correr_wrapper status-degradado.txt replication-degradado.txt "$BROKERS"
afirmar_contiene 'escenario degradado · diagnóstico' 'Quórum DEGRADADO' "$SALIDA"
afirmar_igual 'escenario degradado · código de salida, degradar es lo que el lab pide' \
    '0' "$CODIGO"
TODAS="$TODAS
$SALIDA"

correr_wrapper status-sano.txt replication-stacktrace.txt "$BROKERS"
afirmar_contiene 'escenario replication ilegible · diagnóstico' \
    'No pude leer el detalle por nodo' "$SALIDA"
afirmar_igual 'escenario replication ilegible · código de salida' '1' "$CODIGO"
TODAS="$TODAS
$SALIDA"

correr_wrapper '' '' "$(fx sin-brokers.txt)"
afirmar_contiene 'escenario sin brokers · diagnóstico' \
    'No hay ningún contenedor de Kafka corriendo' "$SALIDA"
afirmar_igual 'escenario sin brokers · código de salida' '1' "$CODIGO"
TODAS="$TODAS
$SALIDA"

echo ''
echo 'Formato'

ANCHO=$(printf '%s\n' "$TODAS" | LC_ALL=C tr -d '\200-\277' \
    | awk 'length > m { m = length } END { print m + 0 }')
if [ "$ANCHO" -le 80 ]; then
    verde "formato · ninguna línea pasa de 80 columnas (máximo ${ANCHO})"
else
    rojo 'formato · ninguna línea pasa de 80 columnas' '80 o menos' "$ANCHO"
fi

COLUMNAS=$(printf '%s\n' "$TODAS" | grep '^[┌├└│]' | LC_ALL=C tr -d '\200-\277' \
    | awk '{ print length }' | sort -u | tr '\n' ' ')
afirmar_igual 'formato · el borde derecho de la ficha siempre en la misma columna' \
    '76 ' "$COLUMNAS"

N_ANSI=$(printf '%s\n' "$TODAS" | grep -c "$(printf '\033')") || N_ANSI=0
afirmar_igual 'formato · cero códigos ANSI sin TTY' '0' "$N_ANSI"

DOSPUNTOS=$(grep -n ': ' "$DIR_LAB/bin/ficha.sh" "$DIR_LAB/bin/check-quorum.sh" \
    | grep -v 'col\[' | grep -v 'UnknownHostException' | wc -l | tr -d ' ')
afirmar_igual 'formato · cero dos puntos en prosa' '0' "$DOSPUNTOS"

# La medición rápida de ancho se hace dentro de bash. Se compara contra la
# lenta y obvia sobre cada línea real que produce el wrapper, con acentos,
# cajas Unicode y flechas incluidas.
DISCREPAN=0
while IFS= read -r LINEA; do
    if [ "$(ficha_ancho_visible "$LINEA")" != "$(ficha_ancho_visible_lento "$LINEA")" ]; then
        DISCREPAN=$(( DISCREPAN + 1 ))
    fi
done <<EOF
$(printf '%s\n' "$TODAS" | sort -u)
EOF
afirmar_igual 'formato · la medición rápida de ancho coincide con la lenta' \
    '0' "$DISCREPAN"

echo ''
echo 'Fixtures'

FALTA_CAPTURA=0
for ARCHIVO in "$DIR_FIX"/*.txt; do
    case "$(sed -n '1p' "$ARCHIVO")" in
        '#'*) ;;
        *) FALTA_CAPTURA=$(( FALTA_CAPTURA + 1 )) ;;
    esac
done
afirmar_igual 'fixtures · todos documentan cómo se capturaron' '0' "$FALTA_CAPTURA"

echo ''
if [ "$N_VERDE" -eq "$N_TOTAL" ]; then
    printf '  %s pruebas, %s en verde\n\n' "$N_TOTAL" "$N_VERDE"
    exit 0
fi
printf '  %s pruebas, %s en verde, %s en ROJO\n\n' \
    "$N_TOTAL" "$N_VERDE" "$(( N_TOTAL - N_VERDE ))"
exit 1
