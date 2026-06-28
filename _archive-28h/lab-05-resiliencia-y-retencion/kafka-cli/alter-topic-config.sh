#!/bin/bash
# Modifica configuraciones de un tópico EN CALIENTE (sin reiniciar nada).
#
# Uso:
#   kafka-cli/alter-topic-config.sh <NOMBRE_TOPICO> --add KEY=VALUE [...]
#   kafka-cli/alter-topic-config.sh <NOMBRE_TOPICO> --delete KEY [...]

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 3 ]; then
    cat <<EOF
Uso:
  $0 <TOPICO> --add KEY=VALUE [--add KEY=VALUE ...]
  $0 <TOPICO> --delete KEY [--delete KEY ...]

Ejemplos:
  $0 novatech.gps.realtime --add retention.ms=7200000
  $0 novatech.gps.realtime --add compression.type=zstd --add segment.ms=3600000
  $0 novatech.gps.realtime --delete retention.ms
EOF
    exit 1
fi

TOPIC="$1"
shift

ADD_CONFIGS=()
DELETE_CONFIGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --add)    ADD_CONFIGS+=("$2"); shift 2 ;;
        --delete) DELETE_CONFIGS+=("$2"); shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

if [ ${#ADD_CONFIGS[@]} -gt 0 ]; then
    JOINED=$(IFS=','; echo "${ADD_CONFIGS[*]}")
    echo -e "${CYAN}[Alter Topic Config] ${TOPIC} - AGREGAR/MODIFICAR${NC}"
    echo "  ${JOINED}"
    docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics \
        --entity-name "$TOPIC" \
        --alter \
        --add-config "$JOINED"
    echo -e "${GREEN}  ✓ Configs aplicadas${NC}"
fi

if [ ${#DELETE_CONFIGS[@]} -gt 0 ]; then
    JOINED=$(IFS=','; echo "${DELETE_CONFIGS[*]}")
    echo -e "${CYAN}[Alter Topic Config] ${TOPIC} - ELIMINAR${NC}"
    echo "  ${JOINED}"
    docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics \
        --entity-name "$TOPIC" \
        --alter \
        --delete-config "$JOINED"
    echo -e "${GREEN}  ✓ Configs eliminadas (vuelven a heredar el valor default)${NC}"
fi
