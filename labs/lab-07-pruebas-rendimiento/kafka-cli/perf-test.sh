#!/bin/bash
# Wrapper de kafka-producer-perf-test con parámetros de tuning expuestos.
# Permite comparar throughput entre distintas configuraciones.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES> [opciones]

Opciones (todas opcionales):
  --record-size BYTES        Tamaño de cada mensaje (default: 200)
  --acks ACKS                Nivel de acks: 0, 1, all (default: all)
  --batch-size BYTES         Tamaño máximo de batch (default: 16384 = 16 KB)
  --linger-ms MS             Tiempo máximo de espera para acumular batch (default: 0)
  --compression TYPE         none, gzip, snappy, lz4, zstd (default: none)
  --throughput RATE          Mensajes/seg objetivo (-1 = sin límite, default: -1)

Ejemplos comparativos:
  # Baseline (sin tuning)
  $0 novatech.tuning.bench 50000

  # Batching agresivo
  $0 novatech.tuning.bench 50000 --batch-size 65536 --linger-ms 10

  # Compresión LZ4
  $0 novatech.tuning.bench 50000 --compression lz4

  # acks=1 (menor durabilidad, mayor throughput)
  $0 novatech.tuning.bench 50000 --acks 1

  # Combinación pro
  $0 novatech.tuning.bench 50000 --batch-size 65536 --linger-ms 10 --compression lz4 --acks 1
EOF
    exit 1
fi

TOPIC="$1"
NUM_RECORDS="$2"
shift 2

RECORD_SIZE=200
ACKS="all"
BATCH_SIZE=16384
LINGER_MS=0
COMPRESSION="none"
THROUGHPUT=-1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --record-size) RECORD_SIZE="$2"; shift 2 ;;
        --acks) ACKS="$2"; shift 2 ;;
        --batch-size) BATCH_SIZE="$2"; shift 2 ;;
        --linger-ms) LINGER_MS="$2"; shift 2 ;;
        --compression) COMPRESSION="$2"; shift 2 ;;
        --throughput) THROUGHPUT="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${CYAN}[Perf Test] ${TOPIC}${NC}"
echo "  Mensajes:        ${NUM_RECORDS}"
echo "  Tamaño:          ${RECORD_SIZE} bytes"
echo "  Acks:            ${ACKS}"
echo "  Batch size:      ${BATCH_SIZE} bytes"
echo "  Linger ms:       ${LINGER_MS}"
echo "  Compresión:      ${COMPRESSION}"
echo "  Throughput cap:  ${THROUGHPUT} msg/seg"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" \
    --num-records "$NUM_RECORDS" \
    --record-size "$RECORD_SIZE" \
    --throughput "$THROUGHPUT" \
    --producer-props \
        bootstrap.servers="$BOOTSTRAP" \
        acks="$ACKS" \
        batch.size="$BATCH_SIZE" \
        linger.ms="$LINGER_MS" \
        compression.type="$COMPRESSION"
