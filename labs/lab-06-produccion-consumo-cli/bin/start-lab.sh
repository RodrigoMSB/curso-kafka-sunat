#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 02: Iniciar laboratorio
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
echo "║     Lab 02: Pub/Sub y Consumer Groups en acción          ║"
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

echo -e "${YELLOW}[1/5] Levantando contenedores del clúster NovaTech...${NC}"
# Cleanup defensivo:
# (1) Force-remove contenedores con nombres canónicos compartidos (cross-lab):
#     compose down -v sólo limpia los del proyecto actual; cuando el alumno
#     cambia de lab sin haber corrido stop-lab.sh del anterior, los nombres
#     colisionan ("Conflict: container name already in use").
# (2) docker compose down -v --remove-orphans del proyecto actual.
for c in kafka-broker-1 kafka-broker-2 kafka-broker-3 kafbat-ui gps-producer; do
    docker rm -f "$c" 2>/dev/null || true
done
docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true

docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo -e "${YELLOW}[2/5] Esperando a que los brokers estén operativos...${NC}"

TIMEOUT=120
ELAPSED=0
BROKERS_READY=0

while [ "$BROKERS_READY" -lt 3 ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    BROKERS_READY=0
    for BROKER in kafka-broker-1 kafka-broker-2 kafka-broker-3; do
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$BROKER" 2>/dev/null || echo "not_found")
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
    echo -e "${RED}[ERROR] Timeout: solo ${BROKERS_READY}/3 brokers están operativos después de ${TIMEOUT}s${NC}"
    echo -e "${RED}  Revisa los logs con: docker compose -f ${COMPOSE_FILE} logs${NC}"
    exit 1
fi

echo -e "${GREEN}  ✓ 3/3 brokers operativos${NC}"

echo ""
echo -e "${YELLOW}[3/5] Esperando a que Kafbat UI esté disponible...${NC}"

UI_TIMEOUT=60
UI_ELAPSED=0
while [ "$UI_ELAPSED" -lt "$UI_TIMEOUT" ]; do
    if curl -sf http://localhost:8090/actuator/health > /dev/null 2>&1; then
        break
    fi
    echo -e "${YELLOW}  Kafbat UI iniciando... (${UI_ELAPSED}s/${UI_TIMEOUT}s)${NC}"
    sleep 5
    UI_ELAPSED=$((UI_ELAPSED + 5))
done

if [ "$UI_ELAPSED" -ge "$UI_TIMEOUT" ]; then
    echo -e "${YELLOW}[ADVERTENCIA] Kafbat UI aún no responde. Puede tardar unos segundos más.${NC}"
    echo -e "${YELLOW}  Puedes verificar manualmente en: http://localhost:8090${NC}"
else
    echo -e "${GREEN}  ✓ Kafbat UI disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[4/5] Verificando productor GPS...${NC}"
sleep 5
if docker ps --filter "name=gps-producer" --filter "status=running" --format "{{.Names}}" | grep -q "gps-producer"; then
    echo -e "${GREEN}  ✓ Productor GPS activo${NC}"
else
    echo -e "${YELLOW}  [INFO] El productor GPS está iniciando...${NC}"
fi

echo ""
echo -e "${YELLOW}[5/5] Inicializando tópico de eventos para Lab 02...${NC}"
bash "$(dirname "$0")/../infra/scripts/init-events-topic.sh"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  CLÚSTER NOVATECH OPERATIVO${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Componentes:${NC}"
echo -e "    Broker 1:        localhost:9092"
echo -e "    Broker 2:        localhost:9093"
echo -e "    Broker 3:        localhost:9094"
echo -e "    Kafbat UI:       http://localhost:8090"
echo ""
echo -e "${CYAN}  Tópico del Lab 02:${NC}"
echo -e "    ${BOLD}novatech.fleet.events${NC} (6 particiones, RF=3)"
echo ""
echo -e "${CYAN}  Comandos útiles:${NC}"
echo -e "    Producir un evento:  ${BOLD}kafka-cli/produce-event.sh \"<MENSAJE>\"${NC}"
echo -e "    Consumir sin grupo:  ${BOLD}kafka-cli/consume-event.sh${NC}"
echo -e "    Consumir en grupo:   ${BOLD}kafka-cli/consume-as-group.sh --group <NOMBRE>${NC}"
echo -e "    Listar grupos:       ${BOLD}kafka-cli/list-groups.sh${NC}"
echo -e "    Detener laboratorio: ${BOLD}bin/stop-lab.sh${NC}"
echo ""
echo -e "${YELLOW}  Abre la guía: guia/01-log-inmutable.md${NC}"
echo ""
