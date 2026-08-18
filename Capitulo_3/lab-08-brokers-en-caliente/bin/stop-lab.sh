#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

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

ficha_op "DETENER EL LAB 08" \
    'Apaga los contenedores del lab. No borra nada' \
    'el material del lab en disco, y los volúmenes mientras el lab siga detenido' \
    "nada: solo detiene los contenedores de novatech-lab08" \
    'cuando terminas por hoy y quieres liberarle memoria a Docker'

echo -e "${YELLOW}[NovaTech] Deteniendo el laboratorio...${NC}"
# --profile scale para alcanzar también a kafka-broker-4 si quedó arriba.
compose --profile scale stop

echo -e "${GREEN}✓ Laboratorio detenido.${NC}"
echo -e "${CYAN}  Los volúmenes siguen ahí mientras el lab esté detenido.${NC}"
echo -e "${YELLOW}  Ojo al reanudar: bin/start-lab.sh reconstruye el laboratorio desde cero,${NC}"
echo -e "${YELLOW}  así que los tópicos y mensajes que creaste no sobreviven. El lab vuelve${NC}"
echo -e "${YELLOW}  a sembrar los suyos. Si creaste algo propio, anótalo antes.${NC}"
echo -e "${CYAN}  Para borrar todo ahora: bin/reset-lab.sh${NC}"
