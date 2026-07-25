#!/bin/bash
# Detiene el clúster Y borra los volúmenes (estado completamente limpio).

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/mi-cluster/docker-compose.yml"

echo -e "${RED}⚠  Este comando ELIMINA todos los datos de tu clúster.${NC}"
echo -n "¿Estás seguro? (escribe 'si' para continuar): "
read CONFIRM

if [ "$CONFIRM" != "si" ]; then
    echo -e "${YELLOW}Cancelado.${NC}"
    exit 0
fi

if [ -f "$COMPOSE_FILE" ]; then
    cd "${LAB_DIR}/mi-cluster"
    docker compose down -v
    echo -e "${GREEN}✓ Contenedores y volúmenes eliminados.${NC}"
else
    echo -e "${YELLOW}[INFO] No hay docker-compose.yml en mi-cluster/. Nada que limpiar.${NC}"
fi
