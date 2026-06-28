#!/bin/bash
# Produce un mensaje al topic confidencial usando credenciales de app1.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

MENSAJE="${1:-Pago confidencial #$(date +%s) - app1}"

echo -e "${CYAN}[Produce Confidencial] User: app1 → novatech.lab12.confidencial${NC}"
echo "  Mensaje: ${MENSAJE}"

echo "$MENSAJE" | MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= cli-client kafka-console-producer \
    --bootstrap-server kafka-broker-1:9092 \
    --producer.config /etc/kafka/client-properties/app1.properties \
    --topic novatech.lab12.confidencial

echo -e "${GREEN}  ✓ Mensaje publicado${NC}"
