#!/bin/bash
# ============================================================
# Lab 03 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu clúster de 3 nodos y su configuración.
# No modifica nada.
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }
BOOT="kafka-broker-1:29092"

echo -e "${BOLD}Validador del Lab 03 — configuración de brokers${NC}"

# 1. Los 3 contenedores + API
VIVOS=0
for i in 1 2 3; do docker ps --format '{{.Names}}' | grep -q "^kafka-broker-$i$" && VIVOS=$((VIVOS+1)); done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 contenedores kafka-broker-{1,2,3} están corriendo"
else bad "solo ${VIVOS}/3 contenedores corriendo" "levanta tu clúster de 3 (Lab 02) o usa soluciones/"; fi

API_OK=0
if [ "$VIVOS" -gt 0 ] && MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 \
     kafka-broker-api-versions --bootstrap-server "$BOOT" >/dev/null 2>&1; then
    ok "el broker responde a la API"; API_OK=1
else bad "el broker no responde" "espera a que arranquen o revisa docker logs kafka-broker-1"; fi

# 2. El properties generado existe
if [ "$API_OK" -eq 1 ] && MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 bash -c \
     'grep -l process.roles /etc/kafka/*.properties' >/dev/null 2>&1; then
    ok "el server.properties generado existe (contiene process.roles)"
else
    bad "no encuentro el properties con process.roles" "el contenedor no terminó de arrancar; espera o revisa logs"
fi

# 3. Configuración efectiva legible, con orígenes STATIC
if [ "$API_OK" -eq 1 ]; then
    CFG=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-configs \
        --bootstrap-server "$BOOT" --describe --entity-type brokers --entity-name 1 --all 2>/dev/null)
    if echo "$CFG" | grep -q 'STATIC_BROKER_CONFIG'; then
        ok "kafka-configs muestra orígenes (hay STATIC_BROKER_CONFIG)"
    else
        bad "no veo configs STATIC" "tu compose declara KAFKA_* → deben aparecer como STATIC (guía 02)"
    fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
