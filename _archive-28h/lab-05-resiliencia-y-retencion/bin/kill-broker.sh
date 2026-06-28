#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 01: Simular caída de broker
# Detiene un broker específico para observar tolerancia a fallos
# ============================================================

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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

# Verificar que el broker está corriendo
if ! docker ps --filter "name=${BROKER_NAME}" --filter "status=running" --format "{{.Names}}" | grep -q "$BROKER_NAME"; then
    echo -e "${RED}[ERROR] El broker ${BROKER_NAME} no está corriendo.${NC}"
    exit 1
fi

# Determinar un broker vivo para ejecutar comandos (diferente al que vamos a tumbar)
ALIVE_BROKER=""
for i in 1 2 3; do
    if [ "$i" -ne "$BROKER_NUM" ]; then
        if docker ps --filter "name=kafka-broker-${i}" --filter "status=running" --format "{{.Names}}" | grep -q "kafka-broker-${i}"; then
            ALIVE_BROKER="kafka-broker-${i}"
            break
        fi
    fi
done

if [ -z "$ALIVE_BROKER" ]; then
    echo -e "${RED}[ERROR] No se encontró un broker alternativo disponible.${NC}"
    exit 1
fi

BOOTSTRAP="${ALIVE_BROKER}:$(( 29091 + $(echo "$ALIVE_BROKER" | grep -o '[0-9]$') ))"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║  SIMULACIÓN DE CAÍDA DE BROKER                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Estado ANTES ──
echo -e "${YELLOW}${BOLD}▶ ESTADO ANTES DE LA CAÍDA${NC}"
echo ""

echo -e "${CYAN}  Quorum KRaft:${NC}"
docker exec "$ALIVE_BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" \
    describe --status 2>/dev/null || true
echo ""

echo -e "${CYAN}  Líderes de particiones (novatech.fleet.gps):${NC}"
docker exec "$ALIVE_BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
    --describe --topic novatech.fleet.gps 2>/dev/null || true
echo ""

# ── Tumbar el broker ──
echo -e "${RED}${BOLD}✖ Deteniendo ${BROKER_NAME}...${NC}"
docker compose -f "$COMPOSE_FILE" stop "$BROKER_NAME"

echo ""
echo -e "${YELLOW}  Esperando 5 segundos para que el clúster se estabilice...${NC}"
sleep 5

# ── Estado DESPUÉS ──
echo ""
echo -e "${GREEN}${BOLD}▶ ESTADO DESPUÉS DE LA CAÍDA${NC}"
echo ""

echo -e "${CYAN}  Quorum KRaft:${NC}"
docker exec "$ALIVE_BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" \
    describe --status 2>/dev/null || true
echo ""

echo -e "${CYAN}  Líderes de particiones (novatech.fleet.gps):${NC}"
docker exec "$ALIVE_BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
    --describe --topic novatech.fleet.gps 2>/dev/null || true
echo ""

echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  El broker ${BROKER_NAME} ha sido detenido.${NC}"
echo -e "${YELLOW}  Observa los cambios en líderes, ISR y quorum.${NC}"
echo -e "${YELLOW}  Para recuperarlo: bin/revive-broker.sh ${BROKER_NUM}${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
