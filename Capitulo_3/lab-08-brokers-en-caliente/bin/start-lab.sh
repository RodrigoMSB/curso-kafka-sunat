#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 08: Iniciar laboratorio
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
echo "║     Lab 08: Brokers en caliente                          ║"
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

ficha_op "INICIAR EL LAB 08" \
    'Deja el lab en su estado inicial y levanta el clúster desde cero' \
    'la guía, tu reporte de plantillas/ y todo archivo del lab en disco' \
    "contenedores y volúmenes de novatech-lab08, y contenedores de otros labs novatech-lab*" \
    'al empezar el lab, o para volver a un arranque limpio'

echo -e "${YELLOW}[1/5] Levantando contenedores del clúster NovaTech (3 brokers + Kafbat)...${NC}"
# Cleanup defensivo:
# (1) Force-remove contenedores con nombres canónicos compartidos (cross-lab):
#     compose down -v sólo limpia los del proyecto actual; cuando el alumno
#     cambia de lab sin haber corrido stop-lab.sh del anterior, los nombres
#     colisionan ("Conflict: container name already in use").
# (2) docker compose down -v --remove-orphans del proyecto actual (con profile
#     scale para alcanzar también a kafka-broker-4 si quedó arriba).
botar_contenedores_del_curso "start-lab" kafka-broker-1 kafka-broker-2 kafka-broker-3 kafka-broker-4 kafbat-ui || exit 1
compose --profile scale down -v --remove-orphans 2>/dev/null || true

# Arranca SOLO 3 brokers + kafbat (broker-4 va por profile, no aquí).
compose up -d

echo ""
echo -e "${YELLOW}[2/5] Esperando a que los 3 brokers estén operativos...${NC}"

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
    echo -e "${YELLOW}[ADVERTENCIA] Kafbat UI aún no responde. Puedes verificar en: http://localhost:8090${NC}"
else
    echo -e "${GREEN}  ✓ Kafbat UI disponible${NC}"
fi

echo ""
echo -e "${YELLOW}[4/5] Inicializando tópico de trabajo...${NC}"
# Carga las variables del .env (TOPIC_NAME, PARTITIONS, REPLICATION_FACTOR)
set -a; source "$ENV_FILE"; set +a
docker exec \
    -e TOPIC_NAME="${TOPIC_NAME}" \
    -e PARTITIONS="${PARTITIONS}" \
    -e REPLICATION_FACTOR="${REPLICATION_FACTOR}" \
    -i kafka-broker-1 bash -s < "${LAB_DIR}/infra/scripts/init-topics.sh"

echo ""
echo -e "${YELLOW}[5/5] Produciendo datos de muestra (5000 mensajes)...${NC}"
bash "${LAB_DIR}/kafka-cli/produce-sample.sh" novatech.lab08.pedidos 5000

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  CLÚSTER NOVATECH LAB 08 OPERATIVO${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Componentes:${NC}"
echo -e "    Broker 1:        localhost:9092"
echo -e "    Broker 2:        localhost:9093"
echo -e "    Broker 3:        localhost:9094"
echo -e "    Kafbat UI:       http://localhost:8090"
echo ""
echo -e "${CYAN}  Tópico de trabajo:${NC}"
echo -e "    ${BOLD}novatech.lab08.pedidos${NC}   - 6 particiones, RF 3"
echo ""
echo -e "${CYAN}  Próximos pasos:${NC}"
echo -e "    Agregar broker 4:    ${BOLD}kafka-cli/add-broker.sh${NC}"
echo -e "    Ver brokers:         ${BOLD}kafka-cli/list-brokers.sh${NC}"
echo -e "    Reasignar:           ${BOLD}kafka-cli/reassign-partitions.sh${NC}"
echo -e "    Detener laboratorio: ${BOLD}bin/stop-lab.sh${NC}"
echo ""
echo ""
echo -e "${CYAN}  El recorrido de hoy:${NC}"
echo -e "    1. Foto del clúster de 3 brokers  -> quién tiene cada partición"
echo -e "    2. Agregar el broker 4            -> entra al clúster, y entra VACÍO"
echo -e "    3. Reasignar hacia los 4          -> con un productor corriendo"
echo ""
echo -e "${YELLOW}  Abre la guía: guia/01-y-quien-mueve-los-datos.md${NC}"
echo -e "${YELLOW}  Los huecos que vas rellenando: practica/PASOS.md${NC}"
echo ""
