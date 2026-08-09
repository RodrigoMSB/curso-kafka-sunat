#!/bin/bash
# ============================================================
# Lab 02 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu clúster de 3 nodos. No modifica nada
# (solo produce/consume unas marcas efímeras).
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

ficha_op_verifica 'QUÉ VA A VERIFICAR' \
    'los 3 contenedores kafka-broker-{1,2,3} están corriendo' \
    'el broker responde a la API' \
    'el quórum KRaft tiene líder y sus 3 voters' \
    'produce y consume funcionan con RF=3' \

echo -e "${BOLD}Validador del Lab 02 — clúster de 3 nodos con quórum${NC}"

# 1. Los 3 contenedores
VIVOS=0
for i in 1 2 3; do docker ps --format '{{.Names}}' | grep -q "^kafka-broker-$i$" && VIVOS=$((VIVOS+1)); done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 contenedores kafka-broker-{1,2,3} están corriendo"
else bad "solo ${VIVOS}/3 contenedores corriendo" "levanta tu clúster de 3 (guía 01) o usa soluciones/"; fi

# 2. API responde en broker-1
API_OK=0
if [ "$VIVOS" -gt 0 ] && docker exec -e KAFKA_OPTS= kafka-broker-1 \
     kafka-broker-api-versions --bootstrap-server "$BOOT" >/dev/null 2>&1; then
    ok "el broker responde a la API"; API_OK=1
else bad "el broker no responde" "espera a que arranquen o revisa docker logs kafka-broker-1"; fi

# 3. Quórum con líder y 3 voters
if [ "$API_OK" -eq 1 ]; then
    ST=$(docker exec -e KAFKA_OPTS= kafka-broker-1 \
         kafka-metadata-quorum --bootstrap-server "$BOOT" describe --status 2>/dev/null)
    REP=$(docker exec -e KAFKA_OPTS= kafka-broker-1 \
         kafka-metadata-quorum --bootstrap-server "$BOOT" describe --replication 2>/dev/null)
    VOTERS=$(echo "$REP" | grep -cE '^[0-9]+[[:space:]]')
    if echo "$ST" | grep -q 'LeaderId' && [ "${VOTERS:-0}" -ge 3 ]; then
        ok "quórum KRaft con líder y ${VOTERS} voters"
    else
        bad "el quórum no reporta líder + 3 voters (voters=${VOTERS:-0})" "revisa CONTROLLER_QUORUM_VOTERS en los 3 nodos (guía 01)"
    fi
fi

# 4. Produce/consume efímero (RF=3)
if [ "$VIVOS" -eq 3 ] && [ "$API_OK" -eq 1 ]; then
    MARK="chk-$(date +%s)-${RANDOM}"
    docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics \
        --bootstrap-server "$BOOT" --create --topic "$MARK" --partitions 3 --replication-factor 3 >/dev/null 2>&1
    for i in 1 2 3; do echo "${MARK}-${i}"; done | \
        docker exec -i -e KAFKA_OPTS= kafka-broker-1 kafka-console-producer \
        --bootstrap-server "$BOOT" --command-property acks=all --topic "$MARK" >/dev/null 2>&1
    GOT=$(docker exec -e KAFKA_OPTS= kafka-broker-1 bash -c \
        "kafka-console-consumer --bootstrap-server $BOOT --topic $MARK --from-beginning --timeout-ms 8000 2>/dev/null | grep -c '^${MARK}-'")
    if [ "$GOT" = "3" ]; then ok "produce/consume funciona (3/3 marcas, RF=3)"
    else bad "produce/consume: llegaron ${GOT}/3" "revisa la salud del clúster (guía 02)"; fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
