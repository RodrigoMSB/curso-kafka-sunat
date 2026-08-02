#!/bin/bash
# ============================================================
# test-sesiones-1-3.sh · pruebas de los wrappers de los labs 01 a 04
# ============================================================
# Corre en frío, contra el canónico y contra fixtures capturados de un
# clúster o de la imagen real. Sin Docker, sin clúster, sin red.
#
#   bash tools/ficha/test-sesiones-1-3.sh
#
# Las aserciones comparan VALORES, no presencia de palabras, y el texto
# se aplana antes de comparar porque la caja envuelve las frases largas.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -u

DIR_CANON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$DIR_CANON/../.." && pwd)"
DIR_FIX="$DIR_CANON/fixtures"
LAB="$RAIZ/Capitulo_2/lab-01-inicializacion-kraft"

NO_COLOR=1
export NO_COLOR

TMP="${TMPDIR:-/tmp}/test-s13-$$"
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
plano() { printf '%s\n' "$1" | sed 's/^│//; s/│$//' | tr '\n' ' ' | tr -s ' '; }

afirmar_igual() { if [ "$2" = "$3" ]; then verde "$1"; else rojo "$1" "<$2>" "<$3>"; fi; }
afirmar_contiene() {
    case "$3" in *"$2"*) verde "$1" ;; *) rojo "$1" "que contuviera <$2>" "$(recortar "$3")" ;; esac
}
afirmar_contiene_plano() { afirmar_contiene "$1" "$2" "$(plano "$3")"; }
afirmar_no_contiene() {
    case "$3" in *"$2"*) rojo "$1" "que NO contuviera <$2>" "$(recortar "$3")" ;; *) verde "$1" ;; esac
}

fx() {
    local a="$DIR_FIX/$1"
    if [ ! -f "$a" ]; then printf 'FIXTURE QUE NO EXISTE: %s\n' "$1" >&2; exit 2; fi
    case "$(sed -n '1p' "$a")" in
        '#'*) ;;
        *) printf 'FIXTURE SIN LINEA DE CAPTURA: %s\n' "$1" >&2; exit 2 ;;
    esac
    sed '1d' "$a"
}
fx_a() { fx "$1" > "$TMP/$1"; printf '%s' "$TMP/$1"; }

# ── Doble de docker ──────────────────────────────────────────
cat > "$TMP/bin/docker" <<'DOBLE'
#!/bin/sh
case "$*" in
    *"kafka-storage info"*)   [ -n "${T_INFO:-}" ] && cat "$T_INFO"; exit "${T_INFO_RC:-0}" ;;
    *"ls -la /var/lib/kafka"*) [ -n "${T_LS:-}" ] && cat "$T_LS"; exit 0 ;;
    *"kafka-storage format"*)
        # Foto de lo que el wrapper ya habia impreso en el instante exacto
        # en que se ejecuta el comando que escribe. Es la unica forma de
        # probar que el aviso llego ANTES, y no solo que quedo mas arriba.
        [ -n "${T_SNAP_SRC:-}" ] && [ -f "$T_SNAP_SRC" ] && cp "$T_SNAP_SRC" "${T_SNAP_DST:-/dev/null}"
        [ -n "${T_FMT:-}" ] && cat "$T_FMT"
        exit "${T_FMT_RC:-0}" ;;
    *"random-uuid"*)          printf '%s\n' "${T_UUID:-MkU3OEVBNTcwNTJENDM2Qk}"; exit "${T_UUID_RC:-0}" ;;
    *"ls /usr/bin/kafka-"*)   [ -n "${T_BIN:-}" ] && cat "$T_BIN"; exit 0 ;;
    *"ls -la /etc/kafka"*)    [ -n "${T_ETC:-}" ] && cat "$T_ETC"; exit 0 ;;
    *"java -version"*)        [ -n "${T_JAVA:-}" ] && cat "$T_JAVA"; exit 0 ;;
    pull*)                    exit "${T_PULL_RC:-0}" ;;
esac
case "$*" in
    ps*) printf '%s\n' "${T_PS:-kafka-broker-1}" ;;
esac
exit 0
DOBLE
chmod +x "$TMP/bin/docker"

# $1 = wrapper (ruta relativa al lab), $2 = 1 con ficha, resto = argumentos
correr() {
    local wrapper="$1" con_ficha="$2"; shift 2
    local forzar=''
    [ "$con_ficha" = "1" ] && forzar=1
    SALIDA=$(cd "$LAB" && PATH="$TMP/bin:$PATH" FICHA_FORZAR="$forzar" \
        T_INFO="${T_INFO:-}" T_INFO_RC="${T_INFO_RC:-0}" T_LS="${T_LS:-}" \
        T_FMT="${T_FMT:-}" T_FMT_RC="${T_FMT_RC:-0}" T_UUID="${T_UUID:-}" \
        T_BIN="${T_BIN:-}" T_ETC="${T_ETC:-}" T_JAVA="${T_JAVA:-}" T_PS="${T_PS:-}" \
        /bin/bash "$wrapper" "$@" 2>&1)
    CODIGO=$?
}

T_INFO=$(fx_a verify-storage-ok.txt)
T_LS=$(fx_a verify-storage-fallback.txt)
T_BIN=$(fx_a inspect-image-binarios.txt)
T_ETC=$(fx_a inspect-image-etc.txt)
T_JAVA=$(fx_a inspect-image-java.txt)
T_PS='kafka-broker-1'
export T_INFO T_LS T_BIN T_ETC T_JAVA T_PS

FICHA_SOLO_FUNCIONES=1
. "$LAB/bin/ficha.sh"
unset FICHA_SOLO_FUNCIONES
set +e
set +o pipefail
ficha_init_color

TODO=''

echo ''
echo 'verify-storage · lee la identidad y la explica'

correr bin/verify-storage.sh 1 kafka-broker-1
TODO="$SALIDA"
afirmar_contiene_plano 'verify_lee_el_cluster_id · el valor real del fixture' \
    'La identidad del clúster es RmVXdHVyZXNGaXh0dXJlczEK.' "$SALIDA"
afirmar_contiene_plano 'verify_lee_el_node_id · el nodo real' \
    'Este broker es el nodo 1 del clúster.' "$SALIDA"
afirmar_contiene_plano 'verify_lee_el_directorio · la ruta real' \
    'Guarda sus datos en /var/lib/kafka/data.' "$SALIDA"
afirmar_contiene_plano 'verify_no_deja_tarea · el directory.id no se copia' \
    'y por eso es distinto en cada broker. No debe copiarse entre nodos.' "$SALIDA"
afirmar_no_contiene 'verify_no_deja_tarea · sin el "si ves un meta.properties" viejo' \
    'Si ves un archivo' "$SALIDA"

# El fallback muestra el comando que corrió DE VERDAD, no el primero.
T_INFO_RC=1; export T_INFO_RC
correr bin/verify-storage.sh 1 kafka-broker-1
TODO="$TODO
$SALIDA"
afirmar_contiene 'verify_fallback · muestra el comando que corrió' \
    'docker exec kafka-broker-1 ls -la /var/lib/kafka/data' "$SALIDA"
afirmar_no_contiene 'verify_fallback · ya no muestra el que falló' \
    'kafka-storage info -c' "$SALIDA"
afirmar_contiene_plano 'verify_fallback · no afirma la identidad que no pudo leer' \
    'Lo que no puedo decirte desde acá es con qué cluster.id quedó.' "$SALIDA"
T_INFO_RC=0; export T_INFO_RC

echo ''
echo 'generate-cluster-id · su salida es el resultado'

correr kafka-cli/generate-cluster-id.sh 0
afirmar_igual 'generate_sin_tty · el UUID pelado, capturable' \
    'MkU3OEVBNTcwNTJENDM2Qk' "$SALIDA"
afirmar_igual 'generate_sin_tty · una sola línea' '1' \
    "$(printf '%s\n' "$SALIDA" | grep -c '[^[:space:]]')"

correr kafka-cli/generate-cluster-id.sh 1
TODO="$TODO
$SALIDA"
afirmar_contiene_plano 'generate_explica · la misma cadena en los tres' \
    'Los tres brokers tienen que tener exactamente esa misma cadena.' "$SALIDA"
afirmar_contiene_plano 'generate_explica · la consecuencia con nombre' \
    'arranca y muere con InconsistentClusterIdException.' "$SALIDA"
afirmar_contiene_plano 'generate_explica · lo distingue del directory.id' \
    'No la confundas con el directory.id' "$SALIDA"

echo ''
echo 'format-storage · el aviso va antes de escribir'

T_FMT=$(fx_a format-storage-primera.txt); export T_FMT
correr kafka-cli/format-storage.sh 1 kafka-broker-1 MkU3OEVBNTcwNTJENDM2Qk
TODO="$TODO
$SALIDA"
afirmar_contiene 'format_avisa_antes · el bloque de aviso existe' \
    'ESTO ESCRIBE EN EL DISCO' "$SALIDA"

# Que el aviso quede más arriba en el texto no prueba nada: se puede
# imprimir todo junto después de haber escrito en el disco. Lo que hay que
# probar es que ya estaba en pantalla en el instante en que el comando
# corrió. El doble de docker saca la foto justo ahí.
rm -f "$TMP/snap.txt"
T_SNAP_SRC="$TMP/fmt-vivo.txt" T_SNAP_DST="$TMP/snap.txt" \
    PATH="$TMP/bin:$PATH" FICHA_FORZAR=1 \
    T_FMT="$T_FMT" T_FMT_RC="${T_FMT_RC:-0}" T_PS="$T_PS" \
    /bin/bash -c 'cd "$1" && exec /bin/bash kafka-cli/format-storage.sh kafka-broker-1 MkU3OEVBNTcwNTJENDM2Qk' \
    _ "$LAB" > "$TMP/fmt-vivo.txt" 2>&1
if [ -f "$TMP/snap.txt" ] && grep -q 'ESTO ESCRIBE EN EL DISCO' "$TMP/snap.txt"; then
    verde 'format_avisa_antes · el aviso ya estaba en pantalla cuando el comando corrió'
else
    rojo 'format_avisa_antes · el aviso ya estaba en pantalla cuando el comando corrió' \
        'el bloque de aviso, ya impreso' \
        "$(head -c 90 "$TMP/snap.txt" 2>/dev/null || echo '(no se imprimió nada antes)')"
fi

afirmar_contiene_plano 'format_resultado_corto · nombra broker e identidad' \
    'kafka-broker-1 quedó grabado con la identidad MkU3OEVBNTcwNTJENDM2Qk.' "$SALIDA"
afirmar_contiene 'format_encadena · manda a verify-storage' \
    'bin/verify-storage.sh kafka-broker-1' "$SALIDA"
afirmar_no_contiene 'format_recorta_ruido · sin la línea Bootstrap metadata' \
    'BootstrapMetadata(records=' "$SALIDA"
afirmar_contiene 'format_recorta_ruido · avisa que la sacó' \
    'Se omite la línea Bootstrap metadata' "$SALIDA"

# El RESULTADO es corto: se corre doce veces en tres sesiones.
N_RES=$(printf '%s\n' "$SALIDA" | sed -n '/┌─ RESULTADO/,/└─/p' | grep -c '^│')
if [ "$N_RES" -le 4 ]; then
    verde "format_resultado_corto · ${N_RES} líneas de RESULTADO"
else
    rojo 'format_resultado_corto · el RESULTADO no cansa' '4 líneas o menos' "$N_RES"
fi

T_FMT=$(fx_a format-storage-ya-estaba.txt); export T_FMT
correr kafka-cli/format-storage.sh 1 kafka-broker-1 MkU3OEVBNTcwNTJENDM2Qk
afirmar_contiene_plano 'format_ya_estaba · no dice que grabó algo' \
    'kafka-broker-1 ya estaba formateado. No se tocó nada.' "$SALIDA"

T_FMT=$(fx_a format-storage-id-distinto.txt); T_FMT_RC=1; export T_FMT T_FMT_RC
correr kafka-cli/format-storage.sh 1 kafka-broker-1 OtRoClUsTeRJZERpZmVyZW
afirmar_contiene_plano 'format_id_distinto · lee la identidad que YA estaba' \
    'Ya tenía grabada la identidad MkU3OEVBNTcwNTJENDM2Qk, que no es la indicada.' "$SALIDA"
afirmar_igual 'format_id_distinto · sale con el código de Kafka' '1' "$CODIGO"
T_FMT_RC=0; export T_FMT_RC

echo ''
echo 'inspect-image · una sola ficha para cuatro pasos'

correr kafka-cli/inspect-image.sh 1
TODO="$TODO
$SALIDA"
afirmar_igual 'inspect_una_sola_ficha · una sola caja de apertura' '1' \
    "$(printf '%s\n' "$SALIDA" | grep -c '^┌─ QUÉ VAMOS A HACER')"
afirmar_igual 'inspect_cuatro_pasos · los cuatro rótulos [N/4]' '4' \
    "$(printf '%s\n' "$SALIDA" | grep -c '^  \[[0-9]/4\]')"
afirmar_igual 'inspect_sin_nota_docker · sin nota al pie de docker exec' '0' \
    "$(printf '%s\n' "$SALIDA" | grep -c 'En el lab corre dentro del contenedor')"
afirmar_contiene_plano 'inspect_cierra_adelante · cuenta los binarios reales' \
    'Los 20 binarios de arriba son los primeros de una lista más larga' "$SALIDA"
afirmar_contiene_plano 'inspect_cierra_adelante · lee la versión real de Java' \
    'Kafka corre sobre Java 21.0.10' "$SALIDA"
afirmar_contiene_plano 'inspect_cierra_adelante · el puente a SUNAT' \
    'Kafka llega por paquete o por tarball y esos mismos binarios quedan en el PATH' "$SALIDA"

echo ''
echo 'Formato y réplicas'

# El techo de 76 rige la CAJA, que es lo que dibujamos. La salida que
# emite una herramienta va tal cual: envolverla destruiria sus columnas.
ANCHO=$(printf '%s\n' "$TODO" | grep '^[┌├└│]' | LC_ALL=C tr -d '\200-\277' | awk 'length > m { m = length } END { print m + 0 }')
if [ "$ANCHO" -le 76 ]; then
    verde "formato · ninguna línea pasa de 76 columnas (máximo ${ANCHO})"
else
    rojo 'formato · ninguna línea pasa de 76 columnas' '76 o menos' "$ANCHO"
fi
afirmar_igual 'formato · el borde derecho siempre en la misma columna' '76 ' \
    "$(printf '%s\n' "$TODO" | grep '^[┌├└│]' | LC_ALL=C tr -d '\200-\277' | awk '{print length}' | sort -u | tr '\n' ' ')"
afirmar_igual 'formato · cero códigos ANSI sin TTY' '0' \
    "$(printf '%s\n' "$TODO" | grep -c "$(printf '\033')")"

# La cantidad esperada sale del mapa, no de una constante.
"$DIR_CANON/replicar.sh" --verificar > "$TMP/hash.txt" 2>&1
afirmar_igual 'replicas · ninguna copia divergió' '0' "$?"
ESPERADAS=$("$DIR_CANON/replicar.sh" --listar | grep -c '[^[:space:]]')
afirmar_igual 'replicas · verifica todos los destinos del mapa' "$ESPERADAS" \
    "$(grep -c '^  igual' "$TMP/hash.txt")"

echo ''
if [ "$N_VERDE" -eq "$N_TOTAL" ]; then
    printf '  %s pruebas, %s en verde\n\n' "$N_TOTAL" "$N_VERDE"
    exit 0
fi
printf '  %s pruebas, %s en verde, %s en ROJO\n\n' "$N_TOTAL" "$N_VERDE" "$(( N_TOTAL - N_VERDE ))"
exit 1
