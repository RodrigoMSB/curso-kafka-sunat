#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 09: Reiniciar laboratorio
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
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down -v --remove-orphans 2>/dev/null || true

# Cleanup defensivo de contenedores por nombre canónico (cross-lab).
for c in kafka-broker-1 kafka-broker-2 kafka-broker-3 kafbat-ui; do
    docker rm -f "$c" 2>/dev/null || true
done

echo -e "${GREEN}✓ Laboratorio reiniciado. Todo limpio.${NC}"
echo -e "${CYAN}  Para empezar de nuevo: bin/start-lab.sh${NC}"
