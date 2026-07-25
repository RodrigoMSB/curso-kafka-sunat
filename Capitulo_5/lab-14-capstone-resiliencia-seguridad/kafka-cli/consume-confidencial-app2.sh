#!/bin/bash
# Intenta consumir el topic confidencial usando credenciales de app2.
# DEBE FALLAR (app2 NO tiene ACL para confidencial).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${RED}[Test denial] app2 intenta consumir topic confidencial...${NC}"
echo -e "${YELLOW}  Esto DEBE fallar con 'TopicAuthorizationException' o similar.${NC}"
echo "─────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server kafka-broker-1:9092 \
    --consumer.config /etc/kafka/client-properties/app2.properties \
    --topic novatech.lab12.confidencial \
    --from-beginning \
    --timeout-ms 5000 \
    2>&1 | head -20

echo "─────────────────────────────────────────────────────"
echo -e "${GREEN}[Resultado esperado] error tipo 'Not authorized' / 'TopicAuthorizationException'.${NC}"
echo -e "${GREEN}Eso PRUEBA que las ACLs funcionan: app2 NO puede leer confidencial.${NC}"
