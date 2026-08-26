#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 06: Detener laboratorio
# Detiene los contenedores preservando los volúmenes de datos
# ============================================================

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"

ficha_op "DETENER EL LAB 06" \
    'Apaga los contenedores del lab. No borra nada' \
    'tus tópicos y mensajes en los volúmenes de Docker, y el material del lab' \
    "nada: solo detiene los contenedores de novatech-lab06" \
    'cuando terminas por hoy y quieres liberarle memoria a Docker'

echo -e "${YELLOW}[NovaTech] Deteniendo contenedores del clúster...${NC}"
compose stop

echo ""
echo -e "${GREEN}[OK] Clúster NovaTech detenido correctamente.${NC}"
echo -e "${YELLOW}  Los datos se han preservado en los volúmenes de Docker.${NC}"
echo -e "${YELLOW}  Para reanudar, ejecuta: bin/start-lab.sh${NC}"
echo -e "${YELLOW}  Para eliminar todo (incluyendo datos): bin/reset-lab.sh${NC}"
