#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"

echo -e "${YELLOW}[Add] Levantando kafka-broker-4 (broker-only)...${NC}"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile scale up -d kafka-broker-4

echo -e "${YELLOW}Esperando a que el broker-4 esté operativo...${NC}"
for i in $(seq 1 24); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' kafka-broker-4 2>/dev/null || echo "not_found")
    if [ "$STATUS" = "healthy" ]; then
        echo -e "${GREEN}✓ broker-4 operativo y unido al clúster${NC}"
        echo -e "${CYAN}Verifica con: kafka-cli/list-brokers.sh${NC}"
        exit 0
    fi
    sleep 5
done
echo -e "${RED}[ADVERTENCIA] broker-4 no reportó healthy a tiempo. Revisa: docker logs kafka-broker-4${NC}"
