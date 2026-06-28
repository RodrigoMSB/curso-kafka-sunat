#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 01: Recuperar broker caído
# Reinicia un broker previamente detenido
# ============================================================

# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"

# Validar argumento
if [ $# -ne 1 ] || [[ ! "$1" =~ ^[1-3]$ ]]; then
    echo -e "${RED}[ERROR] Uso: $0 <número_broker>${NC}"
    echo -e "${YELLOW}  Ejemplo: $0 2${NC}"
    echo -e "${YELLOW}  Valores válidos: 1, 2 o 3${NC}"
    exit 1
fi

BROKER_NUM=$1
BROKER_NAME="kafka-broker-${BROKER_NUM}"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║  RECUPERACIÓN DE BROKER                              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}[NovaTech] Iniciando ${BROKER_NAME}...${NC}"
docker compose -f "$COMPOSE_FILE" start "$BROKER_NAME"

# Esperar a que el broker esté healthy
echo -e "${YELLOW}  Esperando a que el broker esté operativo...${NC}"
TIMEOUT=90
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$BROKER_NAME" 2>/dev/null || echo "not_found")
    if [ "$STATUS" = "healthy" ]; then
        break
    fi
    echo -e "${YELLOW}  Estado: ${STATUS} (${ELAPSED}s/${TIMEOUT}s)${NC}"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo -e "${RED}[ERROR] El broker no se recuperó en ${TIMEOUT} segundos.${NC}"
    echo -e "${RED}  Revisa los logs: docker logs ${BROKER_NAME}${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ ${BROKER_NAME} está operativo${NC}"
echo ""

# Detectar un broker disponible (puede ser el recién revivido o cualquiera)
resolve_broker

echo -e "${CYAN}  Consultando estado vía ${BROKER} (${BOOTSTRAP})${NC}"
echo ""

echo -e "${CYAN}  Estado del quorum KRaft:${NC}"
docker exec "$BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" \
    describe --status 2>/dev/null || true
echo ""

echo -e "${CYAN}  Estado de réplicas ISR:${NC}"
docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
    --describe --topic novatech.fleet.gps 2>/dev/null || true
echo ""

echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  El broker ${BROKER_NAME} se ha recuperado exitosamente.${NC}"
echo -e "${YELLOW}  Observa cómo las réplicas ISR se actualizan.${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
