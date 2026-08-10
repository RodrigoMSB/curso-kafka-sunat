#!/bin/bash
# ============================================================
# Lab 07 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu laboratorio. Corre un perf corto
# (1000 registros) sobre el tópico de bench para confirmar métricas.
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

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
BOOT="kafka-broker-1:29092"
BENCH="novatech.tuning.bench"   # lo crea start-lab (init-lab06-topics.sh)

ficha_op_verifica 'QUÉ VA A VERIFICAR' \
    'los 3 brokers están healthy' \
    'el tópico de bench novatech.tuning.bench existe' \
    'producer-perf-test devuelve throughput, corriendo 1000 registros de prueba que quedan escritos en el bench' \

echo -e "${BOLD}Validador del Lab 07 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Tópico de bench
if [ "$VIVOS" -gt 0 ] && docker exec kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" --list 2>/dev/null | grep -q "^${BENCH}$"; then
    ok "el tópico de bench ${BENCH} existe"
else
    bad "el tópico ${BENCH} no existe" "ejecuta bin/start-lab.sh (crea el tópico de rendimiento)"
fi

# 3. Perf corto: 1000 registros → debe reportar records/sec
if [ "$VIVOS" -eq 3 ]; then
    OUT=$(docker exec kafka-broker-1 kafka-producer-perf-test \
        --topic "$BENCH" --num-records 1000 --record-size 200 --throughput -1 \
        --producer-props bootstrap.servers="$BOOT" acks=all 2>&1)
    if echo "$OUT" | grep -q 'records/sec'; then ok "producer-perf-test devuelve throughput (records/sec)"
    else bad "el perf no devolvió métricas" "revisa docker logs kafka-broker-1 y la guía de rendimiento"; fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
