#!/bin/bash
# Crea un tópico con configuración personalizable.
#
# Uso:
#   kafka-cli/create-topic.sh <NOMBRE> [--partitions N] [--rf N] [--config K=V ...]
#
# Ejemplos:
#   kafka-cli/create-topic.sh novatech.test
#   kafka-cli/create-topic.sh novatech.gps.realtime --partitions 12 --rf 3 --config retention.ms=3600000 --config compression.type=lz4

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <NOMBRE_TOPICO> [opciones]

Opciones:
  --partitions N         Número de particiones (default: 6)
  --rf N                 Replication factor (default: 3)
  --config KEY=VALUE     Config personalizada (puede repetirse)
  --if-not-exists        No fallar si el tópico ya existe

Ejemplos:
  $0 novatech.test
  $0 novatech.gps.realtime --partitions 12 --rf 3 \\
     --config retention.ms=3600000 --config compression.type=lz4
EOF
    exit 1
fi

TOPIC="$1"
shift

PARTITIONS=6
RF=3
IF_NOT_EXISTS=""
CONFIGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --partitions) PARTITIONS="$2"; shift 2 ;;
        --rf)         RF="$2"; shift 2 ;;
        --config)     CONFIGS+=("--config" "$2"); shift 2 ;;
        --if-not-exists) IF_NOT_EXISTS="--if-not-exists"; shift ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${CYAN}[Create Topic] ${TOPIC}${NC}"
echo "  Particiones:        ${PARTITIONS}"
echo "  Replication factor: ${RF}"
if [ ${#CONFIGS[@]} -gt 0 ]; then
    echo "  Configs personalizadas:"
    for ((i=0; i<${#CONFIGS[@]}; i+=2)); do
        echo "    ${CONFIGS[i+1]}"
    done
fi
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --create \
    --topic "$TOPIC" \
    --partitions "$PARTITIONS" \
    --replication-factor "$RF" \
    $IF_NOT_EXISTS \
    ${CONFIGS[@]+"${CONFIGS[@]}"}

echo -e "${GREEN}  ✓ Tópico ${TOPIC} creado${NC}"
