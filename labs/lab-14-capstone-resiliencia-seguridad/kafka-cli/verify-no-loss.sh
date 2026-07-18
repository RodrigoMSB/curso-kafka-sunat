#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
TOPIC="${1:-novatech.lab12.confidencial}"
BOOT="${BOOT:-kafka-broker-1:9092,kafka-broker-2:9093,kafka-broker-3:9094}"
echo -e "${CYAN}[Verificación sin pérdida] Contando mensajes en ${TOPIC}...${NC}"
TOTAL=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client bash -c "kafka-console-consumer \
    --bootstrap-server $BOOT \
    --command-config /etc/kafka/client-properties/admin.properties \
    --topic $TOPIC --from-beginning --timeout-ms 8000 2>/dev/null | wc -l")
echo -e "${BOLD}  Total de mensajes leídos: ${TOTAL}${NC}"
