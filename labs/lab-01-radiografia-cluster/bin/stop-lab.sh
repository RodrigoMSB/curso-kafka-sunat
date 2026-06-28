#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 01: Detener laboratorio
# Detiene los contenedores preservando los volúmenes de datos
# ============================================================

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"

echo -e "${YELLOW}[NovaTech] Deteniendo contenedores del clúster...${NC}"
docker compose -f "$COMPOSE_FILE" stop

echo ""
echo -e "${GREEN}[OK] Clúster NovaTech detenido correctamente.${NC}"
echo -e "${YELLOW}  Los datos se han preservado en los volúmenes de Docker.${NC}"
echo -e "${YELLOW}  Para reanudar, ejecuta: bin/start-lab.sh${NC}"
echo -e "${YELLOW}  Para eliminar todo (incluyendo datos): bin/reset-lab.sh${NC}"
