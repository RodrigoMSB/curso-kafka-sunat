#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"

# ── Ficha operativa ──────────────────────────────────────────
# Este wrapper no ejecuta ningún comando de Kafka: levanta un contenedor con
# docker compose. No hay flags de Kafka que desglosar ni salida de Kafka que
# leer, así que le corresponde la familia operativa y no la de lección.
ficha_op 'AGREGAR UN BROKER AL CLÚSTER' \
    'Levanta kafka-broker-4 con el perfil scale de compose y espera a que quede healthy y unido al quórum' \
    'los 3 brokers que ya estaban y todos sus datos. Ninguna partición se mueve sola al entrar el nuevo' \
    'nada. Solo suma un contenedor al proyecto novatech-lab08' \
    'cuando quieres ampliar el clúster. El broker entra vacío, y repartirle carga es el paso siguiente con reassign-partitions.sh'

echo -e "${YELLOW}[Add] Levantando kafka-broker-4 (broker-only)...${NC}"
compose --profile scale up -d kafka-broker-4

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
