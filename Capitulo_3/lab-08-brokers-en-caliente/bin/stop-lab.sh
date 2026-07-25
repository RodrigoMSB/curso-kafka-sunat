#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 08: Detener laboratorio
# Detiene los contenedores preservando los volúmenes de datos.
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"

echo -e "${YELLOW}[NovaTech] Deteniendo el laboratorio (se conservan los volúmenes)...${NC}"
# --profile scale para alcanzar también a kafka-broker-4 si quedó arriba.
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile scale stop

echo -e "${GREEN}✓ Laboratorio detenido.${NC}"
echo -e "${CYAN}  Para reanudar: bin/start-lab.sh${NC}"
echo -e "${CYAN}  Para borrar todo (incluidos datos): bin/reset-lab.sh${NC}"
