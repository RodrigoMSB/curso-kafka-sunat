#!/bin/bash
# ============================================================
# Lab 05 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu laboratorio. No modifica nada.
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
DEMO_TOPIC="novatech.fleet.gps"   # lo crea el contenedor gps-producer al arrancar

ficha_op_verifica 'QUÉ VA A VERIFICAR' \
    'los 3 brokers están healthy' \
    'kafka-topics responde y cuántos tópicos hay en el clúster' \
    'el tópico demo novatech.fleet.gps existe' \
    'kafka-topics --describe devuelve las particiones de ese tópico' \

echo -e "${BOLD}Validador del Lab 05 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. kafka-topics responde (herramienta central del lab)
if [ "$VIVOS" -gt 0 ] && LIST=$(docker exec kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" --list 2>/dev/null); then
    N=$(echo "$LIST" | grep -c .)
    ok "kafka-topics responde (${N} tópicos en el clúster)"
else
    bad "kafka-topics no responde" "revisa que start-lab.sh haya terminado sin errores"
    LIST=""
fi

# 3. Tópico demo del lab presente
if echo "$LIST" | grep -q "^${DEMO_TOPIC}$"; then
    ok "el tópico demo ${DEMO_TOPIC} existe"
else
    bad "el tópico demo ${DEMO_TOPIC} no existe todavía" "espera unos segundos a que gps-producer arranque, o revisa sus logs"
fi

# 4. describe sano sobre el tópico demo
if echo "$LIST" | grep -q "^${DEMO_TOPIC}$"; then
    PARTS=$(docker exec kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" --describe --topic "$DEMO_TOPIC" 2>/dev/null | grep -cE 'Partition: [0-9]+')
    if [ "$PARTS" -ge 1 ] 2>/dev/null; then ok "kafka-topics --describe sano (${PARTS} particiones en ${DEMO_TOPIC})"
    else bad "describe no devolvió particiones" "revisa el estado del clúster"; fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
