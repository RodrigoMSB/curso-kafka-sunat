#!/bin/bash
set -euo pipefail

# Lab 12 reset: detiene todo, borra volúmenes Y certificados.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"
CERTS_DIR="${LAB_DIR}/infra/certs"

echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}${BOLD}║  ADVERTENCIA: Esta acción eliminará:                ║${NC}"
echo -e "${RED}${BOLD}║  - Todos los contenedores del laboratorio           ║${NC}"
echo -e "${RED}${BOLD}║  - Todos los volúmenes de datos (mensajes Kafka)    ║${NC}"
echo -e "${RED}${BOLD}║  - Las redes de Docker creadas                      ║${NC}"
echo -e "${RED}${BOLD}║  - Los certificados TLS generados                   ║${NC}"
echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
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
