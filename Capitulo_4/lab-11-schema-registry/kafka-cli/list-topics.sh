#!/bin/bash
# ============================================================
# list-topics.sh · ficha didáctica sobre kafka-topics --list
# ============================================================
# Familia LEE. Solo consulta, no toca nada. Por defecto esconde los
# tópicos internos, que son la contabilidad propia de Kafka. Con
# --internal se ven todos.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale nada más que
# lo de Kafka, porque las guías del curso hacen 'list-topics.sh | grep X'.
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
        --list) echo "solo consulta, devuelve los nombres y nada más" ;;
        *)      flag_desc_comun "$1" ;;
    esac
}

# ── Lectura de la salida ─────────────────────────────────────
# Un nombre por línea. Los internos de Kafka empiezan con dos guiones
# bajos, y los de ksqlDB y Connect tienen sus propios prefijos.
l_contar() {
    printf '%s\n' "$1" | grep -c '[^[:space:]]' || true
}

l_internos() {
    printf '%s\n' "$1" | grep -c '^__' || true
}

# ── Encabezado de la ficha ───────────────────────────────────
ficha_encabezado() {
    local destino="$1" ver_internos="$2"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Pedirle a Kafka la lista de los tópicos que tiene ahora mismo'

    ficha_medio 'COMANDO REAL'
    if [ "$ver_internos" -eq 1 ]; then
        ficha_comando "kafka-topics --bootstrap-server $destino --list"
    else
        ficha_comando "kafka-topics --bootstrap-server $destino \\"
        ficha_comando '    --list --exclude-internal'
    fi

    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$destino" ''
    ficha_flag '--list'             ''         ''
    if [ "$ver_internos" -eq 0 ]; then
        ficha_flag '--exclude-internal' '' ''
    fi

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'un nombre por línea' 'cada uno es un tópico del clúster'
    ficha_campo '__consumer_offsets'  'interno. Kafka anota ahí por dónde va cada grupo de consumo'
    ficha_campo '__transaction_state' 'interno. El estado de las transacciones en curso'

    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, --bootstrap-server lleva la IP real de tu broker.'
    echo ''
}

# ── Diagnóstico ──────────────────────────────────────────────
diagnostico_lista() {
    local salida="$1" ver_internos="$2"
    local total internos negocio

    total=$(l_contar "$salida")
    internos=$(l_internos "$salida")
    negocio=$(( total - internos ))

    ficha_abrir 'DIAGNÓSTICO'

    if [ "$total" -eq 0 ]; then
        ficha_texto 'El clúster no tiene ningún tópico todavía.'
        ficha_texto 'No es un error. Un clúster recién levantado arranca vacío.'
        ficha_cerrar
        return 0
    fi

    if [ "$ver_internos" -eq 1 ]; then
        ficha_texto "${total} tópicos en total, de los cuales ${internos} son internos de Kafka"
        ficha_texto "y ${negocio} son tuyos."
    else
        ficha_texto "${negocio} tópicos de negocio. Los internos están escondidos."
    fi

    ficha_vacia
    ficha_texto 'Los internos empiezan con dos guiones bajos y son la contabilidad'
    ficha_texto 'propia de Kafka. El más importante es __consumer_offsets, donde'
    ficha_texto 'anota por dónde va cada grupo de consumo. Si lo borras, todos los'
    ficha_texto 'consumidores pierden su lugar.'

    if [ "$ver_internos" -eq 0 ]; then
        ficha_vacia
        ficha_causa '  Para verlos' 'kafka-cli/list-topics.sh --internal'
    fi

    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    local ver_internos=0
    if [ "${1:-}" = "--internal" ]; then
        ver_internos=1
    fi

    ficha_init_color
    resolver_broker
    local destino="$BOOTSTRAP" rc=0 salida=''

    if [ "$ver_internos" -eq 1 ]; then
        salida=$(docker exec "$BROKER" kafka-topics \
            --bootstrap-server "$destino" --list 2>&1) || rc=$?
    else
        salida=$(docker exec "$BROKER" kafka-topics \
            --bootstrap-server "$destino" --list --exclude-internal 2>&1) || rc=$?
    fi

    # Sin terminal se emite solo lo de Kafka, tal cual, para no romper las
    # tuberías de las guías.
    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_encabezado "$destino" "$ver_internos"

    if [ "$rc" -ne 0 ]; then
        ficha_cruda 'Kafka no devolvió la lista. Esto respondió:' \
            "$(ficha_linea_error "$salida")"
        echo ''
        ficha_abrir 'DIAGNÓSTICO'
        ficha_texto 'No pude leer la lista de tópicos, así que no te puedo decir'
        ficha_texto 'cuántos hay.'
        ficha_causa '  ¿Qué brokers están vivos?' 'docker ps'
        ficha_cerrar
        exit "$rc"
    fi

    ficha_cruda 'Esto devolvió Kafka' "$salida"
    echo ''
    diagnostico_lista "$salida" "$ver_internos"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato sin depender de un clúster vivo.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
