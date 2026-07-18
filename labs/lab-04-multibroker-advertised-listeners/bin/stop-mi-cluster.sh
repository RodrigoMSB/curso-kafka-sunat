#!/bin/bash
# Detiene el clúster del alumno preservando los volúmenes.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/mi-cluster/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${YELLOW}[INFO] No existe ${COMPOSE_FILE}.${NC}"
    echo -e "${YELLOW}  Aún no has creado tu docker-compose. Nada que detener.${NC}"
    exit 0
fi

echo -e "${YELLOW}Deteniendo tu clúster...${NC}"
cd "${LAB_DIR}/mi-cluster"
docker compose down

echo -e "${GREEN}✓ Clúster detenido. Volúmenes preservados.${NC}"
echo -e "${GREEN}  Para reiniciar: cd mi-cluster && docker compose up -d${NC}"
