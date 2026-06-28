#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 11: Iniciar laboratorio
# ============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"

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
echo "║     Lab 11: Prometheus + Grafana                         ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] Docker no está corriendo.${NC}"
    exit 1
fi

DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
DOCKER_MEM_GB=$((DOCKER_MEM / 1073741824))
if [ "$DOCKER_MEM_GB" -lt 5 ]; then
    echo -e "${YELLOW}[ADVERTENCIA] Docker tiene ${DOCKER_MEM_GB} GB de RAM. Se recomiendan al menos 6 GB.${NC}"
fi

echo -e "${YELLOW}[1/6] Levantando contenedores del clúster NovaTech Lab 11...${NC}"
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

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

echo ""
echo -e "${YELLOW}[2/6] Esperando a que los 3 brokers estén operativos...${NC}"

TIMEOUT=180; ELAPSED=0; BROKERS_READY=0
while [ "$BROKERS_READY" -lt 3 ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    BROKERS_READY=0
    for B in kafka-broker-1 kafka-broker-2 kafka-broker-3; do
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$B" 2>/dev/null || echo "not_found")
        [ "$STATUS" = "healthy" ] && BROKERS_READY=$((BROKERS_READY + 1))
    done
    if [ "$BROKERS_READY" -lt 3 ]; then
        echo -e "${YELLOW}  ${BROKERS_READY}/3 brokers listos... (${ELAPSED}s/${TIMEOUT}s)${NC}"
        sleep 5; ELAPSED=$((ELAPSED + 5))
    fi
done

if [ "$BROKERS_READY" -lt 3 ]; then
    echo -e "${RED}[ERROR] Solo ${BROKERS_READY}/3 brokers operativos.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ 3/3 brokers operativos${NC}"

echo ""
echo -e "${YELLOW}[3/6] Esperando a que Kafbat UI esté disponible...${NC}"
UI_TIMEOUT=60; UI_ELAPSED=0
while [ "$UI_ELAPSED" -lt "$UI_TIMEOUT" ]; do
    if curl -sf http://localhost:8090/actuator/health > /dev/null 2>&1; then break; fi
    echo -e "${YELLOW}  Kafbat UI iniciando... (${UI_ELAPSED}s/${UI_TIMEOUT}s)${NC}"
    sleep 5; UI_ELAPSED=$((UI_ELAPSED + 5))
done
if [ "$UI_ELAPSED" -ge "$UI_TIMEOUT" ]; then
    echo -e "${YELLOW}  [INFO] Kafbat UI tarda. Verificable en http://localhost:8090${NC}"
else
    echo -e "${GREEN}  ✓ Kafbat UI disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[4/6] Esperando a Prometheus...${NC}"
PROM_TIMEOUT=60; PROM_ELAPSED=0
while [ "$PROM_ELAPSED" -lt "$PROM_TIMEOUT" ]; do
    if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then break; fi
    echo -e "${YELLOW}  Prometheus iniciando... (${PROM_ELAPSED}s/${PROM_TIMEOUT}s)${NC}"
    sleep 5; PROM_ELAPSED=$((PROM_ELAPSED + 5))
done
if [ "$PROM_ELAPSED" -ge "$PROM_TIMEOUT" ]; then
    echo -e "${YELLOW}  [INFO] Prometheus tarda. Verificable en http://localhost:9090${NC}"
else
    echo -e "${GREEN}  ✓ Prometheus disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[5/6] Esperando a Grafana...${NC}"
GRAF_TIMEOUT=60; GRAF_ELAPSED=0
while [ "$GRAF_ELAPSED" -lt "$GRAF_TIMEOUT" ]; do
    if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then break; fi
    echo -e "${YELLOW}  Grafana iniciando... (${GRAF_ELAPSED}s/${GRAF_TIMEOUT}s)${NC}"
    sleep 5; GRAF_ELAPSED=$((GRAF_ELAPSED + 5))
done
if [ "$GRAF_ELAPSED" -ge "$GRAF_TIMEOUT" ]; then
    echo -e "${YELLOW}  [INFO] Grafana tarda. Verificable en http://localhost:3000${NC}"
else
    echo -e "${GREEN}  ✓ Grafana disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[6/6] Inicializando tópicos del Lab 11...${NC}"
bash "$(dirname "$0")/../infra/scripts/init-lab11-topics.sh"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  CLÚSTER NOVATECH LAB 11 OPERATIVO${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Componentes:${NC}"
echo -e "    Broker 1:           localhost:9092"
echo -e "    Broker 2:           localhost:9093"
echo -e "    Broker 3:           localhost:9094"
echo -e "    Kafbat UI:          http://localhost:8090"
echo -e "    Prometheus:         http://localhost:9090   ← métricas crudas + PromQL"
echo -e "    ${BOLD}Grafana:            http://localhost:3000${NC}   ← LA ESTRELLA (admin/admin)"
echo ""
echo -e "${CYAN}  Tópicos del Lab 11:${NC}"
echo -e "    ${BOLD}novatech.lab11.eventos${NC}    - 12 particiones, para generar carga"
echo ""
echo -e "${CYAN}  Próximos pasos:${NC}"
echo -e "    1. Generar carga:     ${BOLD}kafka-cli/produce-flood.sh 600 200${NC}"
echo -e "    2. Abrir Grafana:     http://localhost:3000 (anónimo o admin/admin)"
echo -e "    3. Tour del dashboard: Kafka Cluster Overview (pre-cargado)"
echo -e "    4. Tumbar broker:     ${BOLD}kafka-cli/trigger-broker-down.sh 2${NC}"
echo ""
echo -e "${YELLOW}  Abre la guía: guia/01-arquitectura-monitoreo.md${NC}"
echo ""
