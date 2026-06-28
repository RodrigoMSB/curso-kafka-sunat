#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 12: Iniciar laboratorio (con seguridad)
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
echo "║     Lab 12: Seguridad y evaluación final                 ║"
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
    echo -e "${YELLOW}[ADVERTENCIA] Docker tiene ${DOCKER_MEM_GB} GB. Se recomiendan 6 GB.${NC}"
fi

echo -e "${YELLOW}[1/6] Generando certificados TLS (si no existen)...${NC}"
bash "$(dirname "$0")/generate-certs.sh"

echo ""
echo -e "${YELLOW}[2/6] Levantando contenedores del clúster NovaTech Lab 12...${NC}"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

echo ""
echo -e "${YELLOW}[3/6] Esperando a que los 3 brokers estén operativos...${NC}"

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
    echo -e "${RED}  Revisa logs: docker logs kafka-broker-1${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ 3/3 brokers operativos${NC}"

echo ""
echo -e "${YELLOW}[4/6] Esperando a que Kafbat UI esté disponible...${NC}"
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
echo -e "${YELLOW}[5/6] Inicializando tópicos del Lab 12...${NC}"
bash "$(dirname "$0")/../infra/scripts/init-lab12-topics.sh"

echo ""
echo -e "${YELLOW}[6/6] Inicializando ACLs del Lab 12...${NC}"
bash "$(dirname "$0")/../infra/scripts/init-lab12-acls.sh"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  CLÚSTER NOVATECH LAB 12 OPERATIVO (con seguridad)${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Componentes:${NC}"
echo -e "    Broker 1 SASL_SSL:  localhost:9092"
echo -e "    Broker 2 SASL_SSL:  localhost:9093"
echo -e "    Broker 3 SASL_SSL:  localhost:9094"
echo -e "    Kafbat UI:          http://localhost:8090"
echo ""
echo -e "${CYAN}  Tópicos del Lab 12:${NC}"
echo -e "    ${BOLD}novatech.lab12.publico${NC}       - 3 part, RF=3 (autenticados con ACL)"
echo -e "    ${BOLD}novatech.lab12.confidencial${NC}  - 3 part, RF=3 (solo admin + app1)"
echo ""
echo -e "${CYAN}  Usuarios:${NC}"
echo -e "    ${BOLD}admin${NC}       → super user, todo permitido"
echo -e "    ${BOLD}app1${NC}        → producer+consumer publico Y confidencial"
echo -e "    ${BOLD}app2${NC}        → SOLO consumer del público"
echo ""
echo -e "${CYAN}  Próximos pasos:${NC}"
echo -e "    1. Producir como app1:                ${BOLD}kafka-cli/produce-confidencial.sh${NC}"
echo -e "    2. Intentar consumir confidencial app2 (DEBE FALLAR): ${BOLD}kafka-cli/consume-confidencial-app2.sh${NC}"
echo -e "    3. Listar ACLs:                       ${BOLD}kafka-cli/list-acls.sh${NC}"
echo -e "    4. Intentar conectar SIN auth:        ${BOLD}kafka-cli/attempt-no-auth.sh${NC}"
echo ""
echo -e "${YELLOW}  Abre la guía: guia/01-tls-y-certificados.md${NC}"
echo ""
