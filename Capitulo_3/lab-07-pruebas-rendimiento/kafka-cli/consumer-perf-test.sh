#!/bin/bash
# Wrapper de kafka-consumer-perf-test para medir throughput de consumo.
# Permite comparar el rendimiento de lectura entre configuraciones.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES> [opciones]

Opciones (todas opcionales):
  --fetch-size BYTES         Tamaño máximo por fetch (default: 1048576 = 1 MB)

Ejemplos:
  # Baseline
  $0 novatech.tuning.bench 100000

  # Fetch grande
  $0 novatech.tuning.bench 100000 --fetch-size 5242880
EOF
    exit 1
fi

TOPIC="$1"
NUM_RECORDS="$2"
shift 2

FETCH_SIZE=1048576

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fetch-size) FETCH_SIZE="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${CYAN}[Consumer Perf Test] ${TOPIC}${NC}"
echo "  Mensajes:        ${NUM_RECORDS}"
echo "  Fetch size:      ${FETCH_SIZE} bytes"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-perf-test \
    --topic "$TOPIC" \
    --messages "$NUM_RECORDS" \
    --bootstrap-server "$BOOTSTRAP" \
    --fetch-size "$FETCH_SIZE"
