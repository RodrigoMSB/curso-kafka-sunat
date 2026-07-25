#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
TOPIC="${1:-novatech.lab12.confidencial}"
BOOT="${BOOT:-kafka-broker-1:9092,kafka-broker-2:9093,kafka-broker-3:9094}"
echo -e "${CYAN}[Describe] ${TOPIC} — líderes e ISR por partición${NC}"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server "$BOOT" \
    --command-config /etc/kafka/client-properties/admin.properties \
    --describe --topic "$TOPIC"
