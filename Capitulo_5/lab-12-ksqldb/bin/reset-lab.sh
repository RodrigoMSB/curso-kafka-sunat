#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 12: Reiniciar laboratorio
# Elimina todos los contenedores, volúmenes y redes
# ============================================================

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"

echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}${BOLD}║  ADVERTENCIA: Esta acción eliminará:                ║${NC}"
echo -e "${RED}${BOLD}║  - Todos los contenedores del laboratorio           ║${NC}"
echo -e "${RED}${BOLD}║  - Todos los volúmenes de datos (mensajes Kafka)    ║${NC}"
echo -e "${RED}${BOLD}║  - Las redes de Docker creadas                      ║${NC}"
echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

read -r -p "¿Estás seguro de que deseas reiniciar el laboratorio? (s/N): " CONFIRM

if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo -e "${YELLOW}[INFO] Operación cancelada.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}[NovaTech] Eliminando contenedores, volúmenes y redes...${NC}"
docker compose -f "$COMPOSE_FILE" down -v --remove-orphans

echo ""
echo -e "${GREEN}[OK] Laboratorio reiniciado completamente.${NC}"
echo -e "${YELLOW}  Para volver a iniciar: bin/start-lab.sh${NC}"
