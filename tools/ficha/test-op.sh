#!/bin/bash
# ============================================================
# test-op.sh · pruebas de la familia OPERATIVA (ficha_op_*)
# ============================================================
# Corre en frío contra el canónico. Sin Docker, sin clúster, sin red.
#
#   bash tools/ficha/test-op.sh
#
# Las aserciones comparan VALORES. Una aserción que no puede distinguir
# lo correcto de lo incorrecto no es una aserción -- y por eso este
# runner incluye sus propias pruebas de que SABE DECIR QUE NO (6.d).
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -u

DIR_CANON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NO_COLOR=1; export NO_COLOR

N_TOTAL=0; N_VERDE=0
verde() { N_TOTAL=$(( N_TOTAL + 1 )); N_VERDE=$(( N_VERDE + 1 )); printf '  verde  %s\n' "$1"; }
rojo()  { N_TOTAL=$(( N_TOTAL + 1 )); printf '  ROJO   %s\n' "$1"
          printf '           esperado  %s\n' "$2"; printf '           obtenido  %s\n' "$3"; }
recortar() { printf '%s' "$1" | tr '\n' '|' | cut -c1-140; }
afirmar_igual()    { if [ "$2" = "$3" ]; then verde "$1"; else rojo "$1" "<$2>" "<$3>"; fi; }
afirmar_contiene() { case "$3" in *"$2"*) verde "$1" ;; *) rojo "$1" "que contuviera <$2>" "$(recortar "$3")" ;; esac; }
afirmar_no_contiene() { case "$3" in *"$2"*) rojo "$1" "que NO contuviera <$2>" "$(recortar "$3")" ;; *) verde "$1" ;; esac; }

# El texto sin marco ni espacios repetidos, para comparar frases que la
# caja pudo haber envuelto en dos renglones.
plano() { printf '%s' "$1" | tr -d '│┌┐└┘├┤─' | tr -s ' ' | tr '\n' ' '; }
afirmar_contiene_plano() { afirmar_contiene "$1" "$2" "$(plano "$3")"; }

# ── La ficha de muestra que se usa en casi todas las pruebas ──
muestra() {
    FICHA_FORZAR=1 ficha_op \
        'RESET DEL CLÚSTER' \
        'Borra y reconstruye tu clúster desde cero' \
        'la guía, tus reportes y los archivos de mi-cluster/' \
        'los contenedores y volúmenes del proyecto novatech-lab02' \
        'cuando tu clúster quedó en un estado que no sabés desarmar'
}

printf '\n%s\n' 'Familia operativa'

# shellcheck source=/dev/null
. "$DIR_CANON/ficha.sh"

# ── 1. Existe y es una sola familia ──────────────────────────
if command -v ficha_op >/dev/null 2>&1; then verde 'motor · ficha_op existe'
else rojo 'motor · ficha_op existe' 'una función ficha_op' 'no está definida'; fi

SAL="$(muestra)"

# ── 2. Contenido: los cuatro bloques y sus textos ────────────
afirmar_contiene       'contenido · el título va en el marco'     'RESET DEL CLÚSTER' "$SAL"
afirmar_contiene       'contenido · rótulo QUÉ HACE'              'QUÉ HACE'    "$SAL"
afirmar_contiene       'contenido · rótulo CONSERVA'              'CONSERVA'    "$SAL"
afirmar_contiene       'contenido · rótulo DESTRUYE'              'DESTRUYE'    "$SAL"
afirmar_contiene       'contenido · rótulo CUÁNDO USARLO'         'CUÁNDO'      "$SAL"
afirmar_contiene_plano 'contenido · la frase de QUÉ HACE'         'Borra y reconstruye tu clúster desde cero' "$SAL"
afirmar_contiene_plano 'contenido · lo que conserva'              'tus reportes' "$SAL"
afirmar_contiene_plano 'contenido · el proyecto compose acotado'  'novatech-lab02' "$SAL"
afirmar_contiene_plano 'contenido · cuándo usarlo'                'no sabés desarmar' "$SAL"

# ── 3. El techo duro de 10 líneas (6.b) ──────────────────────
N=$(printf '%s\n' "$SAL" | grep -c '')
if [ "$N" -le 10 ] && [ "$N" -gt 0 ]; then verde "formato · la ficha cabe en 10 líneas (son ${N})"
else rojo 'formato · la ficha cabe en 10 líneas' '<=10 y >0' "$N"; fi

# ── 4. El marco: ancho y borde derecho ───────────────────────
MAX=0
while IFS= read -r l; do
    n=$(printf '%s' "$l" | LC_ALL=C tr -d '\200-\277' | LC_ALL=C wc -c | tr -d ' ')
    [ "$n" -gt "$MAX" ] && MAX=$n
done <<EOT
$SAL
EOT
if [ "$MAX" -le 76 ]; then verde "formato · ninguna línea pasa de 76 columnas (máximo ${MAX})"
else rojo 'formato · ninguna línea pasa de 76 columnas' '<=76' "$MAX"; fi

DESCUADRE=0
while IFS= read -r l; do
    case "$l" in *'│') : ;; *'┐'|*'┤'|*'┘') : ;; *) DESCUADRE=$(( DESCUADRE + 1 )) ;; esac
done <<EOT
$SAL
EOT
afirmar_igual 'formato · el borde derecho siempre en la misma columna' '0' "$DESCUADRE"

# ── 5. TTY: sin FICHA_FORZAR y sin terminal, no sale nada ────
SIN_TTY="$( ficha_op 'T' 'a' 'b' 'c' 'd' )"
afirmar_igual 'tty · sin TTY la ficha no imprime ni un byte' '' "$SIN_TTY"
ANSI=$(printf '%s' "$SIN_TTY" | grep -c "$(printf '\033')" || true)
afirmar_igual 'tty · cero códigos ANSI sin TTY' '0' "$ANSI"

# ── 6. Reutiliza la fontanería, no la duplica ────────────────
afirmar_igual 'motor · la puerta TTY sigue siendo ficha_activa (una sola)' '1' \
              "$(grep -c 'ficha_activa' "$DIR_CANON/ficha.sh" | head -1 >/dev/null; grep -c '^ficha_activa()' "$DIR_CANON/ficha.sh")"
afirmar_igual 'motor · la familia op no define su propio [ -t 1 ]' '0' \
              "$(sed -n '/^# ── Familia operativa/,$p' "$DIR_CANON/ficha.sh" | grep -c '\-t 1')"

# ── 7. Portabilidad (6.e) ────────────────────────────────────
# Mismo criterio que test-lee.sh:237 -- se excluyen las lineas de comentario.
# La linea que DECLARA la regla ("sin declare -A, sin mapfile...") no es una
# violacion de la regla; contarla es el bug de auto-deteccion del preflight.
afirmar_igual 'portabilidad · cero construcciones prohibidas en el motor' '0' \
              "$(grep -n 'jq\|declare -A\|mapfile\|grep -P' "$DIR_CANON/ficha.sh" | grep -cv ': *#')"

# ── 8. EL ARNÉS SABE DECIR QUE NO (6.d) ──────────────────────
# Se le da a la ficha el contenido INVERTIDO -- lo que conserva puesto
# donde va lo que destruye -- y se comprueba que las aserciones de arriba
# habrían fallado. Si estas tres dan verde, las de arriba valen.
printf '\n%s\n' 'El arnés sabe decir que NO (sabotaje 6.d)'

INV="$(FICHA_FORZAR=1 ficha_op 'RESET' 'x' \
        'los contenedores y volúmenes del proyecto novatech-lab02' \
        'la guía y tus reportes' 'y')"
# En la ficha invertida, "novatech-lab02" cae en CONSERVA. La prueba mira
# la línea del rótulo DESTRUYE y exige que el proyecto esté ahí.
LINEA_DESTRUYE_OK="$(printf '%s\n' "$SAL" | grep 'DESTRUYE')"
LINEA_DESTRUYE_INV="$(printf '%s\n' "$INV" | grep 'DESTRUYE')"
afirmar_contiene     'sabotaje · con el contenido correcto, el proyecto está en DESTRUYE' \
                     'novatech-lab02' "$LINEA_DESTRUYE_OK"
afirmar_no_contiene  'sabotaje · invertido, el proyecto YA NO está en DESTRUYE' \
                     'novatech-lab02' "$LINEA_DESTRUYE_INV"

# Y una prueba de que el techo de 10 líneas puede fallar: una ficha con
# textos larguísimos se pasa, y el test lo detecta.
LARGA="$(FICHA_FORZAR=1 ficha_op 'T' \
    'una frase deliberadamente larguisima que obliga al motor a envolverla en varios renglones seguidos para empujar el alto de la ficha muy por encima del techo que la SPEC fija como duro' \
    'otra frase igual de larga para el bloque de lo que se conserva y que tambien tiene que envolverse en mas de un renglon porque si no el sabotaje no muerde y la prueba no vale nada' \
    'y una tercera frase kilometrica en el bloque de lo que se destruye para terminar de pasar el techo de diez lineas sin ninguna duda posible sobre el resultado' \
    'y el cuando usarlo tambien largo por si hiciera falta empujar un poco mas el alto total de la caja dibujada')"
NL=$(printf '%s\n' "$LARGA" | grep -c '')
if [ "$NL" -gt 10 ]; then verde "sabotaje · el techo de 10 líneas es detectable (la ficha larga da ${NL})"
else rojo 'sabotaje · el techo de 10 líneas es detectable' '>10 con textos largos' "$NL"; fi

printf '\n  %s pruebas, %s en verde\n\n' "$N_TOTAL" "$N_VERDE"
[ "$N_TOTAL" = "$N_VERDE" ]
