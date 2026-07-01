#!/bin/bash
# ============================================================
# Lab 06 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu laboratorio. No modifica nada
# (solo produce/consume unos mensajes de prueba efímeros).
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
# El tópico real del lab lo crea infra/scripts/init-events-topic.sh (hardcode);
# el TOPIC_NAME del .env no se usa para este flujo.
TOPIC="novatech.fleet.events"

echo -e "${BOLD}Validador del Lab 06 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Tópico
if [ "$VIVOS" -gt 0 ] && docker exec kafka-broker-1 kafka-topics --bootstrap-server kafka-broker-1:29092 --list 2>/dev/null | grep -q "^${TOPIC}$"; then
    ok "el tópico ${TOPIC} existe"
else
    bad "el tópico ${TOPIC} no existe (o el clúster no responde)" "revisa que start-lab.sh haya terminado sin errores"
fi

# 3. Flujo produce/consume con marca efímera (ground truth)
if [ "$VIVOS" -eq 3 ]; then
    MARK="chk-$(date +%s)-${RANDOM}"
    for i in 1 2 3; do echo "${MARK}-${i}"; done | \
        docker exec -i kafka-broker-1 kafka-console-producer \
        --bootstrap-server kafka-broker-1:29092 --command-property acks=all --topic "$TOPIC" 2>/dev/null
    GOT=$(docker exec kafka-broker-1 bash -c \
        "kafka-console-consumer --bootstrap-server kafka-broker-1:29092 --topic $TOPIC --from-beginning --timeout-ms 8000 2>/dev/null | grep -c '^${MARK}-'")
    if [ "$GOT" = "3" ]; then ok "produce/consume funciona (3/3 mensajes de prueba)"
    else bad "produce/consume: llegaron ${GOT}/3" "revisa docker logs kafka-broker-1 y la guía 01"; fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
