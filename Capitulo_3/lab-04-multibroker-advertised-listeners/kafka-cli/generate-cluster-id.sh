#!/bin/bash
# ============================================================
# generate-cluster-id.sh · ficha didáctica sobre random-uuid
# ============================================================
# Familia CREA. Su salida ES el resultado: no hay un estado que mirar
# después, el valor que imprime es lo único que produjo. Por eso el
# último bloque no describe un estado, explica qué es ese valor y qué
# pasa si no se usa igual en todos los brokers del clúster.
#
# La ficha se dibuja solo en una terminal. Sin terminal sale el UUID
# pelado y nada más, para que CLUSTER_ID=$(generate-cluster-id.sh)
# funcione.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

IMAGEN="confluentinc/cp-kafka:8.2.0"

flag_desc() {
    case "$1" in
        random-uuid) echo "inventa una identidad nueva. No toca ningún clúster ni ningún disco" ;;
        *)           flag_desc_comun "$1" ;;
    esac
}

# El valor válido es una sola línea, sin espacios, de 22 caracteres en
# base64. Si viene otra cosa no se afirma que sea un cluster-id.
g_es_uuid() {
    case "$1" in
        ''|*[!A-Za-z0-9_-]*) return 1 ;;
        *)                   return 0 ;;
    esac
}

# ── Encabezado de la ficha ───────────────────────────────────
ficha_encabezado() {
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Pedirle a Kafka una identidad nueva para un clúster que todavía no existe'

    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-storage random-uuid'

    ficha_medio 'DESGLOSE'
    ficha_flag 'random-uuid' '' ''

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una sola línea. Ese texto es el valor completo, no un resumen ni un'
    ficha_texto 'identificador que se pueda acortar.'

    ficha_cerrar
    ficha_nota "En el lab se ejecuta con docker run --rm ${IMAGEN}"
    ficha_nota 'En su servidor, kafka-storage ya está en el PATH y no hace falta docker.'
    echo ''
}

# ── Qué es este valor ────────────────────────────────────────
# No hay estado que diagnosticar: el valor recién nace. Lo que falta es
# saber qué hacer con él, y sobre todo qué pasa si no se usa igual en
# todos los brokers del clúster.
que_es_este_valor() {
    local cid="$1"

    ficha_abrir 'QUÉ ES ESTE VALOR'
    ficha_texto "${cid} es la identidad del clúster."
    ficha_texto 'Todavía no existe ningún clúster con ella. Existe cuando se formatee el'
    ficha_texto 'almacenamiento de los brokers con este mismo valor.'

    ficha_vacia
    ficha_texto 'Todos los brokers del clúster tienen que tener exactamente esa misma cadena. Si alguno tiene otra, no forma quórum con los demás.'
    ficha_texto 'No debe confundirse con el directory.id, que identifica el directorio de datos de cada nodo y por eso sí es distinto en cada broker.'

    ficha_vacia
    ficha_warn 'Si un broker se formatea con una cadena y otro con otra, el segundo arranca y muere con InconsistentClusterIdException.'

    ficha_vacia
    ficha_causa '  Dónde va' 'CLUSTER_ID en el .env o en docker-compose.yml'
    ficha_cerrar
}

diagnostico_error() {
    local salida="$1"

    ficha_abrir 'QUÉ PASÓ'
    ficha_texto 'kafka-storage no devolvió una identidad utilizable.'
    ficha_vacia
    ficha_texto 'No es un error de tu clúster, porque acá todavía no hay ninguno. Es'
    ficha_texto 'que el contenedor de un solo uso no llegó a correr.'
    ficha_causa '  ¿Está Docker vivo?' 'docker info'
    ficha_causa '  ¿Está la imagen?'   "docker image ls ${IMAGEN}"
    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    ficha_init_color

    local cid='' rc=0
    cid=$(docker run --rm "$IMAGEN" kafka-storage random-uuid 2>/dev/null \
        | tr -d '\r\n') || rc=$?

    # Sin terminal sale el valor pelado. Es lo que hace que se pueda
    # capturar con CLUSTER_ID=$(...) sin arrastrar adornos.
    if ! ficha_activa; then
        if [ "$rc" -ne 0 ] || ! g_es_uuid "$cid"; then
            echo "[ERROR] No se pudo generar el CLUSTER_ID." >&2
            exit 1
        fi
        printf '%s\n' "$cid"
        exit 0
    fi

    ficha_encabezado

    if [ "$rc" -ne 0 ] || ! g_es_uuid "$cid"; then
        ficha_cruda 'Esto devolvió Kafka' "${cid:-(nada)}"
        echo ''
        diagnostico_error "$cid"
        exit 1
    fi

    ficha_cruda 'Esto devolvió Kafka' "$cid"
    echo ''
    que_es_este_valor "$cid"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato sin depender de Docker.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
