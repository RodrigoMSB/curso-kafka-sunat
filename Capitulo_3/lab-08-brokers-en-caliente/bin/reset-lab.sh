#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 08: Reiniciar laboratorio
# Elimina todos los contenedores, volúmenes y redes del lab.
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"

echo -e "${YELLOW}[NovaTech] Eliminando contenedores, volúmenes y redes del laboratorio...${NC}"
# --profile scale para alcanzar también a kafka-broker-4.
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile scale down -v --remove-orphans 2>/dev/null || true

# Cleanup defensivo de contenedores por nombre canónico (cross-lab).
botar_contenedores_del_curso "reset-lab" kafka-broker-1 kafka-broker-2 kafka-broker-3 kafka-broker-4 kafbat-ui || exit 1

echo -e "${GREEN}✓ Laboratorio reiniciado. Todo limpio.${NC}"
echo -e "${CYAN}  Para empezar de nuevo: bin/start-lab.sh${NC}"
