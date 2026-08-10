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

ficha_op "RESET DEL LAB 12" \
    'Elimina contenedores, volúmenes y redes del lab: lo devuelve a cero' \
    'la guía, tu reporte de plantillas/ y todo archivo del lab en disco' \
    "los volúmenes de novatech-lab12: pierdes tus tópicos y los mensajes de Kafka" \
    'cuando el lab quedó en un estado que no sabes desarmar'

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
