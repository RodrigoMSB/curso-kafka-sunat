#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# Lab 14 reset: detiene todo, borra volúmenes Y certificados.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"
CERTS_DIR="${LAB_DIR}/infra/certs"

ficha_op "RESET DEL LAB 14" \
    'Elimina contenedores, volúmenes y redes del lab: lo devuelve a cero' \
    'la guía, tu reporte de plantillas/ y todo archivo del lab en disco' \
    "los volúmenes de novatech-lab14 con tus mensajes, y los certificados TLS de infra/certs, que start-lab vuelve a generar" \
    'cuando el lab quedó en un estado que no sabes desarmar'

echo ""

read -r -p "¿Estás seguro de que deseas reiniciar el laboratorio? (s/N): " CONFIRM

if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo -e "${YELLOW}[INFO] Operación cancelada.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}[NovaTech] Eliminando contenedores, volúmenes y redes...${NC}"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down -v --remove-orphans

echo ""
echo -e "${YELLOW}[NovaTech] Limpiando certificados TLS en ${CERTS_DIR}...${NC}"
find "$CERTS_DIR" -mindepth 1 ! -name '.gitkeep' -delete 2>/dev/null || true

echo ""
echo -e "${GREEN}[OK] Laboratorio reiniciado completamente.${NC}"
echo -e "${YELLOW}  Para volver a iniciar: bin/start-lab.sh${NC}"
echo -e "${YELLOW}  (regenerará los certificados automáticamente)${NC}"
