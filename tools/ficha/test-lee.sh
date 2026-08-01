#!/bin/bash
# ============================================================
# test-lee.sh · pruebas de la familia LEE
# ============================================================
# Corre en frío, contra el canónico y contra fixtures capturados de un
# clúster real. Sin Docker, sin clúster, sin red.
#
#   bash tools/ficha/test-lee.sh
#
# Las aserciones comparan VALORES, no presencia de palabras. Una aserción
# que no puede distinguir lo correcto de lo incorrecto no es una aserción.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -u

DIR_CANON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$DIR_CANON/../.." && pwd)"
DIR_FIX="$DIR_CANON/fixtures"
LAB="$RAIZ/Capitulo_3/lab-05-operacion-topicos"

NO_COLOR=1
export NO_COLOR

TMP="${TMPDIR:-/tmp}/test-lee-$$"
mkdir -p "$TMP/bin"
trap 'rm -rf "$TMP"' EXIT

N_TOTAL=0
N_VERDE=0

verde() { N_TOTAL=$(( N_TOTAL + 1 )); N_VERDE=$(( N_VERDE + 1 )); printf '  verde  %s\n' "$1"; }
rojo() {
    N_TOTAL=$(( N_TOTAL + 1 ))
    printf '  ROJO   %s\n' "$1"
    printf '           esperado  %s\n' "$2"
    printf '           obtenido  %s\n' "$3"
}
recortar() { printf '%s' "$1" | tr '\n' '|' | cut -c1-120; }

afirmar_igual() {
    if [ "$2" = "$3" ]; then verde "$1"; else rojo "$1" "<$2>" "<$3>"; fi
}
afirmar_contiene() {
    case "$3" in *"$2"*) verde "$1" ;; *) rojo "$1" "que contuviera <$2>" "$(recortar "$3")" ;; esac
}
# La caja envuelve las frases largas, así que una frase de dos renglones
# no aparece contigua en la salida cruda. Se compara sobre el texto sin
# marco y con los espacios colapsados.
plano() {
    printf '%s\n' "$1" | sed 's/^│//; s/│$//' | tr '\n' ' ' | tr -s ' '
}
afirmar_contiene_plano() {
    afirmar_contiene "$1" "$2" "$(plano "$3")"
}

afirmar_no_contiene() {
    case "$3" in *"$2"*) rojo "$1" "que NO contuviera <$2>" "$(recortar "$3")" ;; *) verde "$1" ;; esac
}

# ── Fixtures ─────────────────────────────────────────────────
# La primera línea documenta cómo se capturó. Si falta, se aborta, porque
# entonces estaríamos comiéndonos la primera línea de datos.
fx() {
    local a="$DIR_FIX/$1"
    if [ ! -f "$a" ]; then printf 'FIXTURE QUE NO EXISTE: %s\n' "$1" >&2; exit 2; fi
    case "$(sed -n '1p' "$a")" in
        '#'*) ;;
        *) printf 'FIXTURE SIN LINEA DE CAPTURA: %s\n' "$1" >&2; exit 2 ;;
    esac
    sed '1d' "$a"
}

# ── Doble de docker ──────────────────────────────────────────
cat > "$TMP/bin/docker" <<'DOBLE'
#!/bin/sh
case "$*" in
    *"kafka-topics"*"--describe"*)  [ -n "${T_DESC:-}" ] && cat "$T_DESC"; exit "${T_RC:-0}" ;;
    *"kafka-configs"*)              [ -n "${T_CFG:-}" ] && cat "$T_CFG"; exit 0 ;;
    *"--list --exclude-internal"*)  [ -n "${T_LIST:-}" ] && cat "$T_LIST"; exit 0 ;;
    *"kafka-topics"*"--list"*)      [ -n "${T_LISTI:-}" ] && cat "$T_LISTI"; exit 0 ;;
esac
case "$*" in
    ps*) printf 'kafka-broker-1\n'; exit 0 ;;
esac
exit 0
DOBLE
chmod +x "$TMP/bin/docker"

fx_a() { fx "$1" > "$TMP/$1"; printf '%s' "$TMP/$1"; }

# Corre el wrapper entero. $1 = wrapper, $2 = con ficha (1) o sin (0), resto = argumentos.
correr() {
    local wrapper="$1" con_ficha="$2"; shift 2
    local forzar=''
    [ "$con_ficha" = "1" ] && forzar=1
    SALIDA=$(cd "$LAB" && PATH="$TMP/bin:$PATH" \
        T_DESC="${T_DESC:-}" T_CFG="${T_CFG:-}" T_LIST="${T_LIST:-}" T_LISTI="${T_LISTI:-}" \
        FICHA_FORZAR="$forzar" /bin/bash "kafka-cli/$wrapper" "$@" 2>&1)
    CODIGO=$?
}

T_DESC=$(fx_a describe-topic-sano.txt)
T_DESC_ISR=$(fx_a describe-topic-isr-incompleto.txt)
T_LIST=$(fx_a list-topics-negocio.txt)
T_LISTI=$(fx_a list-topics-con-internos.txt)
T_CFG=''
export T_DESC T_CFG T_LIST T_LISTI

FICHA_SOLO_FUNCIONES=1
# shellcheck source=wrappers/describe-topic.sh
. "$LAB/bin/ficha.sh"
unset FICHA_SOLO_FUNCIONES
set +e
set +o pipefail
ficha_init_color

echo ''
echo 'La regla que da sentido a todo esto · sin terminal no hay ficha'

correr describe-topic.sh 0 novatech.fleet.gps
PRIMERA=$(printf '%s\n' "$SALIDA" | sed -n '1p' | cut -c1-5)
afirmar_igual 'sin_tty_solo_kafka · describe-topic arranca con los datos' 'Topic' "$PRIMERA"
afirmar_no_contiene 'sin_tty_solo_kafka · sin marco' '┌' "$SALIDA"
afirmar_no_contiene 'sin_tty_solo_kafka · sin diagnóstico' 'DIAGNÓSTICO' "$SALIDA"
afirmar_igual 'sin_tty_solo_kafka · cuántas líneas devuelve' '4' \
    "$(printf '%s\n' "$SALIDA" | grep -c '[^[:space:]]')"

correr list-topics.sh 0
afirmar_igual 'sin_tty_solo_kafka · list-topics devuelve solo los nombres' \
    'novatech.audit.events novatech.fleet.gps' "$(printf '%s\n' "$SALIDA" | tr '\n' ' ' | sed 's/ *$//')"

correr describe-topic.sh 1 novatech.fleet.gps
afirmar_contiene 'con_tty_hay_ficha · aparece el marco' '┌─ QUÉ VAMOS A HACER' "$SALIDA"
afirmar_contiene 'con_tty_hay_ficha · aparece el diagnóstico' '┌─ DIAGNÓSTICO' "$SALIDA"

echo ''
echo 'describe-topic · el diagnóstico dice lo que el alumno necesita'

correr describe-topic.sh 1 novatech.fleet.gps
afirmar_contiene_plano 'topico_sano · cuenta particiones y copias reales' \
    'tiene 3 particiones y guarda 3 copias' "$SALIDA"
afirmar_contiene 'topico_sano · declara el ISR completo' \
    'Las 3 particiones tienen su ISR completo' "$SALIDA"
afirmar_contiene_plano 'topico_sano · el liderazgo repartido entre los 3' \
    'repartido entre 3 brokers. El que más atiende lleva 1 de 3' "$SALIDA"
afirmar_contiene_plano 'topico_sano · tolerancia calculada con el ISR real' \
    'peor parada tiene 3, así que todavía toleras perder 1 broker' "$SALIDA"
afirmar_no_contiene 'topico_sano · sin advertencias' '⚠' "$SALIDA"

T_DESC="$T_DESC_ISR"; export T_DESC
correr describe-topic.sh 1 novatech.fleet.gps
afirmar_contiene 'isr_incompleto · nombra al broker que falta' \
    'El broker 2 está fuera del ISR de las 3 particiones' "$SALIDA"
afirmar_contiene_plano 'isr_incompleto · avisa que está al límite' \
    'peor parada tiene justo 2. Si cae un broker más' "$SALIDA"
afirmar_contiene_plano 'isr_incompleto · el liderazgo se concentró' \
    'repartido entre 2 brokers. El que más atiende lleva 2 de 3' "$SALIDA"

# El diagnóstico RESUME. Una línea por broker que falta, no una por
# partición: con 12 particiones serían 12 líneas diciendo un solo hecho.
afirmar_igual 'diagnostico_resume · una sola línea de ISR para un solo broker' '1' \
    "$(printf '%s\n' "$SALIDA" | grep -c 'fuera del ISR')"
afirmar_igual 'diagnostico_resume · ninguna línea por partición suelta' '0' \
    "$(printf '%s\n' "$SALIDA" | grep -c 'Partición [0-9], falta')"

echo ''
echo 'Agrupación por broker · entradas adversarias, no fixtures'

# Kafka no produce esto, se construye acá para atacar al agrupador:
# dos brokers distintos faltando en particiones distintas.
agrupar() {
    printf '%s\n' "$1" | awk 'NF == 2 {
        n[$1]++
        if (lista[$1] == "") lista[$1] = $2; else lista[$1] = lista[$1] ", " $2
    }
    END { for (b in n) printf "%s|%s|%s\n", b, n[b], lista[b] }' | sort -n | tr '\n' ' '
}
afirmar_igual 'agrupa_por_broker · dos brokers en particiones distintas' \
    '2|2|0, 1 3|1|2 ' "$(agrupar '2 0
2 1
3 2')"
afirmar_igual 'agrupa_por_broker · un broker en una sola partición' \
    '4|1|7 ' "$(agrupar '4 7')"

echo ''
echo 'list-topics · el diagnóstico cuenta'

T_DESC=$(fx_a describe-topic-sano.txt); export T_DESC
correr list-topics.sh 1
afirmar_contiene 'lista_negocio · cuenta los de negocio' \
    '2 tópicos de negocio' "$SALIDA"
afirmar_contiene 'lista_negocio · ofrece el comando para ver los internos' \
    'kafka-cli/list-topics.sh --internal' "$SALIDA"

correr list-topics.sh 1 --internal
afirmar_contiene_plano 'lista_internos · separa internos de propios' \
    '3 tópicos en total, de los cuales 1 son internos' "$SALIDA"
afirmar_contiene_plano 'lista_internos · explica __consumer_offsets' \
    'anota por dónde va cada grupo de consumo' "$SALIDA"

echo ''
echo 'Formato y portabilidad'

correr describe-topic.sh 1 novatech.fleet.gps
TODO="$SALIDA"
correr list-topics.sh 1 --internal
TODO="$TODO
$SALIDA"

ANCHO=$(printf '%s\n' "$TODO" | LC_ALL=C tr -d '\200-\277' | awk 'length > m { m = length } END { print m + 0 }')
if [ "$ANCHO" -le 80 ]; then
    verde "formato · ninguna línea pasa de 80 columnas (máximo ${ANCHO})"
else
    rojo 'formato · ninguna línea pasa de 80 columnas' '80 o menos' "$ANCHO"
fi
afirmar_igual 'formato · el borde derecho siempre en la misma columna' '76 ' \
    "$(printf '%s\n' "$TODO" | grep '^[┌├└│]' | LC_ALL=C tr -d '\200-\277' | awk '{print length}' | sort -u | tr '\n' ' ')"
afirmar_igual 'formato · cero códigos ANSI sin TTY' '0' \
    "$(printf '%s\n' "$TODO" | grep -c "$(printf '\033')")"
afirmar_igual 'portabilidad · cero construcciones prohibidas' '0' \
    "$(grep -n 'jq\|declare -A\|mapfile\|grep -P' "$DIR_CANON"/ficha.sh "$DIR_CANON"/flags.sh "$DIR_CANON"/wrappers/*.sh | grep -cv ': *#')"

echo ''
echo 'Réplicas'

"$DIR_CANON/replicar.sh" --verificar > "$TMP/hash.txt" 2>&1
afirmar_igual 'replicas · ninguna copia divergió del canónico' '0' "$?"
afirmar_igual 'replicas · cuántas copias verifica' '25' \
    "$(grep -c '^  igual' "$TMP/hash.txt")"

echo ''
if [ "$N_VERDE" -eq "$N_TOTAL" ]; then
    printf '  %s pruebas, %s en verde\n\n' "$N_TOTAL" "$N_VERDE"
    exit 0
fi
printf '  %s pruebas, %s en verde, %s en ROJO\n\n' "$N_TOTAL" "$N_VERDE" "$(( N_TOTAL - N_VERDE ))"
exit 1
