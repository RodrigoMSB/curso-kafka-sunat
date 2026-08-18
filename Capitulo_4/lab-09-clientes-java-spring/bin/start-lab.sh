#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluido el "-f <ruta>/docker-compose.yml" de mas abajo.
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 09: Iniciar laboratorio
# ============================================================

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Directorio base del laboratorio
LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"

# Banner
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║     ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗                 ║"
echo "║     ████╗  ██║██╔═══██╗██║   ██║██╔══██╗                ║"
echo "║     ██╔██╗ ██║██║   ██║██║   ██║███████║                ║"
echo "║     ██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║                ║"
echo "║     ██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║                ║"
echo "║     ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝                ║"
echo "║              T E C H   L O G I S T I C S                ║"
echo "║                                                          ║"
echo "║     Lab 09: Clientes Java y Spring                       ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar que Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] Docker no está corriendo. Por favor, inicia Docker Desktop.${NC}"
    exit 1
fi

# Verificar memoria disponible de Docker (mínimo 6 GB)
DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
DOCKER_MEM_GB=$((DOCKER_MEM / 1073741824))
if [ "$DOCKER_MEM_GB" -lt 5 ]; then
    echo -e "${YELLOW}[ADVERTENCIA] Docker tiene ${DOCKER_MEM_GB} GB de RAM asignados.${NC}"
    echo -e "${YELLOW}  Se recomiendan al menos 6 GB para este laboratorio.${NC}"
fi

# Carga las variables del .env (puertos, tópico)
set -a; source "$ENV_FILE"; set +a

ficha_op "INICIAR EL LAB 09" \
    'Deja el lab en su estado inicial y levanta el clúster desde cero' \
    'la guía, tu reporte de plantillas/ y todo archivo del lab en disco' \
    "contenedores y volúmenes de novatech-lab09, y contenedores de otros labs novatech-lab*" \
    'al empezar el lab, o para volver a un arranque limpio'

echo -e "${YELLOW}[1/4] Levantando contenedores (3 brokers + Kafbat)...${NC}"
# Cleanup defensivo de contenedores por nombre canónico (cross-lab).
botar_contenedores_del_curso "start-lab" kafka-broker-1 kafka-broker-2 kafka-broker-3 kafbat-ui || exit 1
compose down -v --remove-orphans 2>/dev/null || true

compose up -d

echo ""
echo -e "${YELLOW}[2/4] Esperando a que los 3 brokers estén operativos...${NC}"
TIMEOUT=120
ELAPSED=0
BROKERS_READY=0
while [ "$BROKERS_READY" -lt 3 ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    BROKERS_READY=0
    for B in kafka-broker-1 kafka-broker-2 kafka-broker-3; do
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$B" 2>/dev/null || echo "not_found")
        if [ "$STATUS" = "healthy" ]; then
            BROKERS_READY=$((BROKERS_READY + 1))
        fi
    done
    if [ "$BROKERS_READY" -lt 3 ]; then
        echo -e "${YELLOW}  ${BROKERS_READY}/3 brokers listos... (${ELAPSED}s/${TIMEOUT}s)${NC}"
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    fi
done
if [ "$BROKERS_READY" -lt 3 ]; then
    echo -e "${RED}[ERROR] Timeout: solo ${BROKERS_READY}/3 brokers operativos después de ${TIMEOUT}s${NC}"
    echo -e "${RED}  Revisa los logs con: cd infra && docker compose logs${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ 3/3 brokers operativos${NC}"

echo ""
echo -e "${YELLOW}[3/4] Esperando a que Kafbat UI esté disponible...${NC}"
UI_TIMEOUT=60
UI_ELAPSED=0
while [ "$UI_ELAPSED" -lt "$UI_TIMEOUT" ]; do
    if curl -sf http://localhost:${KAFBAT_UI_PORT}/actuator/health > /dev/null 2>&1; then
        break
    fi
    echo -e "${YELLOW}  Kafbat UI iniciando... (${UI_ELAPSED}s/${UI_TIMEOUT}s)${NC}"
    sleep 5
    UI_ELAPSED=$((UI_ELAPSED + 5))
done
if [ "$UI_ELAPSED" -ge "$UI_TIMEOUT" ]; then
    echo -e "${YELLOW}[ADVERTENCIA] Kafbat UI aún no responde. Verifica en: http://localhost:${KAFBAT_UI_PORT}${NC}"
else
    echo -e "${GREEN}  ✓ Kafbat UI disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[4/4] Inicializando tópico de trabajo...${NC}"
docker exec \
    -e TOPIC_NAME="${TOPIC_NAME}" \
    -e PARTITIONS="${PARTITIONS}" \
    -e REPLICATION_FACTOR="${REPLICATION_FACTOR}" \
    -i kafka-broker-1 bash -s < "${LAB_DIR}/infra/scripts/init-topics.sh"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  CLÚSTER NOVATECH LAB 09 OPERATIVO${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Componentes:${NC}"
echo -e "    Broker 1:        localhost:9092"
echo -e "    Broker 2:        localhost:9093"
echo -e "    Broker 3:        localhost:9094"
echo -e "    Kafbat UI:       http://localhost:${KAFBAT_UI_PORT}"
echo ""
echo -e "${CYAN}  Tópico de trabajo:${NC}"
echo -e "    ${BOLD}${TOPIC_NAME}${NC}   - ${PARTITIONS} particiones, RF ${REPLICATION_FACTOR}"
echo ""
echo -e "${CYAN}  Los clientes están en ${BOLD}cliente-java/${NC}${CYAN} y ${BOLD}cliente-spring/${NC}${CYAN} (se compilan con Maven en esta VM).${NC}"
echo -e "${YELLOW}  Próximos pasos: abre guia/01-cliente-kafka-clients.md${NC}"
echo ""
