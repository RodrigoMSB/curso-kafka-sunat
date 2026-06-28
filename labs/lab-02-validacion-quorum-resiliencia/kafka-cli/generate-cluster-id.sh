#!/bin/bash
# Genera un CLUSTER_ID único usando kafka-storage random-uuid.
# Útil para inicializar un nuevo clúster KRaft.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

IMAGE="confluentinc/cp-kafka:8.2.0"

echo -e "${CYAN}Generando CLUSTER_ID...${NC}"

CLUSTER_ID=$(docker run --rm "$IMAGE" kafka-storage random-uuid 2>/dev/null | tr -d '\r\n')

if [ -z "$CLUSTER_ID" ]; then
    echo -e "${YELLOW}[ERROR] No se pudo generar el CLUSTER_ID.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ CLUSTER_ID generado:${NC}"
echo ""
echo "    ${CLUSTER_ID}"
echo ""
echo -e "${YELLOW}Cópialo a tu .env o docker-compose.yml como CLUSTER_ID.${NC}"
echo -e "${YELLOW}IMPORTANTE: el MISMO valor debe usarse en TODOS los brokers del clúster.${NC}"
