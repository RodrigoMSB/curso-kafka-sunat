#!/bin/bash
# Detiene el clúster del alumno preservando los volúmenes.

set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

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

ficha_op 'DETENER TU CLÚSTER' \
    'Apaga los contenedores de tu clúster sin borrar nada' \
    'tus datos, tus tópicos y tu docker-compose.yml de mi-cluster/' \
    "nada: solo detiene los contenedores del proyecto novatech-lab02" \
    'cuando terminas por hoy y quieres liberarle memoria a Docker'

echo -e "${YELLOW}Deteniendo tu clúster...${NC}"
cd "${LAB_DIR}/mi-cluster"
docker compose down

echo -e "${GREEN}✓ Clúster detenido. Volúmenes preservados.${NC}"
echo -e "${GREEN}  Para reiniciar: cd mi-cluster && docker compose up -d${NC}"
