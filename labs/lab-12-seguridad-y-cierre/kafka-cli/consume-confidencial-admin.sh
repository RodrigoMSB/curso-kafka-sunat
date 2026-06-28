#!/bin/bash
# Consume del topic confidencial usando credenciales de admin.
# DEBE FUNCIONAR (admin es super user, sin ACL necesaria).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[Consume Confidencial] User: admin ← novatech.lab12.confidencial${NC}"
echo -e "${YELLOW}  Esperado: admin SÍ puede leer (super user, ACLs no aplican).${NC}"
echo "────────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server kafka-broker-1:9092 \
    --consumer.config /etc/kafka/client-properties/admin.properties \
    --topic novatech.lab12.confidencial \
    --from-beginning \
    --timeout-ms 5000
