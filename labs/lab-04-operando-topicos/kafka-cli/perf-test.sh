#!/bin/bash
# Wrapper de kafka-producer-perf-test para medir throughput real del broker.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES> [TAMAÑO_BYTES] [--acks <0|1|all>]

Genera carga sintética y mide throughput real.
TAMAÑO_BYTES default: 200 bytes (similar a un evento JSON GPS)
--acks default: all (durabilidad máxima)

Ejemplos:
  $0 novatech.gps.realtime 10000
  $0 novatech.audit.events 5000 500
  $0 novatech.gps.realtime 10000 200 --acks 1
  $0 novatech.gps.realtime 10000 200 --acks 0
EOF
    exit 1
fi

TOPIC="$1"
NUM_RECORDS="$2"
shift 2

# Tercer arg posicional opcional: TAMAÑO_BYTES (si NO empieza con --)
RECORD_SIZE=200
if [[ $# -gt 0 && "$1" != --* ]]; then
    RECORD_SIZE="$1"
    shift
fi

# Flags opcionales
ACKS="all"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --acks)
            ACKS="$2"; shift 2 ;;
        *)
            echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}" >&2
            exit 1 ;;
    esac
done

echo -e "${CYAN}[Perf Test] ${TOPIC}${NC}"
echo "  Mensajes:  ${NUM_RECORDS}"
echo "  Tamaño:    ${RECORD_SIZE} bytes"
echo "  Acks:      ${ACKS}"
echo "  Throughput target: -1 (sin límite)"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" \
    --num-records "$NUM_RECORDS" \
    --record-size "$RECORD_SIZE" \
    --throughput -1 \
    --producer-props bootstrap.servers="$BOOTSTRAP" acks="$ACKS"
