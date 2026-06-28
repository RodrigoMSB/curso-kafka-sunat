#!/bin/bash
# Consume del topic público usando credenciales de app2.
# DEBE FUNCIONAR (app2 tiene ACL para el público).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[Consume Publico] User: app2 ← novatech.lab12.publico${NC}"
echo -e "${YELLOW}  Esperado: app2 SÍ puede leer (tiene ACL).${NC}"
echo "────────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server kafka-broker-1:9092 \
    --consumer.config /etc/kafka/client-properties/app2.properties \
    --topic novatech.lab12.publico \
    --from-beginning \
    --timeout-ms 5000
