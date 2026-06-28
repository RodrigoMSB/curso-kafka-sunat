#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 10: Iniciar laboratorio
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
echo "║     Lab 10: Schema Registry + ksqlDB                     ║"
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

echo -e "${YELLOW}[1/7] Levantando contenedores del clúster NovaTech Lab 10...${NC}"
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
echo -e "${YELLOW}[2/7] Esperando a que los 3 brokers estén operativos...${NC}"

TIMEOUT=180
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
    echo -e "${RED}[ERROR] Solo ${BROKERS_READY}/3 brokers operativos.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ 3/3 brokers operativos${NC}"

echo ""
echo -e "${YELLOW}[3/7] Esperando a que Kafbat UI esté disponible...${NC}"
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
echo -e "${YELLOW}[4/7] Esperando a Schema Registry (puede tardar 30-60s)...${NC}"
SR_TIMEOUT=90; SR_ELAPSED=0
while [ "$SR_ELAPSED" -lt "$SR_TIMEOUT" ]; do
    if curl -sf http://localhost:8081/subjects > /dev/null 2>&1; then break; fi
    echo -e "${YELLOW}  Schema Registry iniciando... (${SR_ELAPSED}s/${SR_TIMEOUT}s)${NC}"
    sleep 10; SR_ELAPSED=$((SR_ELAPSED + 10))
done
if [ "$SR_ELAPSED" -ge "$SR_TIMEOUT" ]; then
    echo -e "${YELLOW}  [ADVERTENCIA] Schema Registry no responde. Verificable en http://localhost:8081${NC}"
else
    echo -e "${GREEN}  ✓ Schema Registry disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[5/7] Esperando a ksqlDB Server (puede tardar 60-90s)...${NC}"
KSQL_TIMEOUT=180; KSQL_ELAPSED=0
while [ "$KSQL_ELAPSED" -lt "$KSQL_TIMEOUT" ]; do
    if curl -sf http://localhost:8088/info > /dev/null 2>&1; then break; fi
    echo -e "${YELLOW}  ksqlDB iniciando... (${KSQL_ELAPSED}s/${KSQL_TIMEOUT}s)${NC}"
    sleep 10; KSQL_ELAPSED=$((KSQL_ELAPSED + 10))
done
if [ "$KSQL_ELAPSED" -ge "$KSQL_TIMEOUT" ]; then
    echo -e "${YELLOW}  [ADVERTENCIA] ksqlDB no responde. Verificable en http://localhost:8088${NC}"
else
    echo -e "${GREEN}  ✓ ksqlDB Server disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[6/7] Verificando ksqlDB CLI disponible...${NC}"
sleep 3
if docker ps --filter "name=ksqldb-cli" --filter "status=running" --format "{{.Names}}" | grep -q "ksqldb-cli"; then
    echo -e "${GREEN}  ✓ ksqlDB CLI listo${NC}"
else
    echo -e "${YELLOW}  [INFO] ksqlDB CLI todavía iniciando${NC}"
fi

echo ""
echo -e "${YELLOW}[7/7] Inicializando tópicos del Lab 10...${NC}"
bash "$(dirname "$0")/../infra/scripts/init-lab10-topics.sh"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  CLÚSTER NOVATECH LAB 10 OPERATIVO${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Componentes:${NC}"
echo -e "    Broker 1:           localhost:9092"
echo -e "    Broker 2:           localhost:9093"
echo -e "    Broker 3:           localhost:9094"
echo -e "    Kafbat UI:          http://localhost:8090"
echo -e "    Schema Registry:    http://localhost:8081    ← API REST"
echo -e "    ksqlDB Server:      http://localhost:8088    ← API REST"
echo -e "    ksqlDB CLI:         ${BOLD}ksql-cli/ksql-shell.sh${NC}"
echo ""
echo -e "${CYAN}  Tópicos del Lab 10:${NC}"
echo -e "    ${BOLD}novatech.lab10.pedidos${NC}    - 12 particiones, datos Avro"
echo -e "    ${BOLD}novatech.lab10.clientes${NC}   - 3 particiones, datos Avro"
echo ""
echo -e "${CYAN}  Próximos pasos:${NC}"
echo -e "    1. Registrar schema:        ${BOLD}schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc${NC}"
echo -e "    2. Generar pedidos:         ${BOLD}kafka-cli/produce-flood-pedidos.sh 30${NC}"
echo -e "    3. Generar clientes seed:   ${BOLD}kafka-cli/produce-clientes-seed.sh${NC}"
echo -e "    4. Abrir ksqlDB:            ${BOLD}ksql-cli/ksql-shell.sh${NC}"
echo ""
echo -e "${CYAN}  Dentro de ksqlDB, primero ejecuta:${NC}"
echo -e "    ${BOLD}SET 'auto.offset.reset'='earliest';${NC}"
echo ""
echo -e "${YELLOW}  Abre la guía: guia/01-schema-registry.md${NC}"
echo ""
