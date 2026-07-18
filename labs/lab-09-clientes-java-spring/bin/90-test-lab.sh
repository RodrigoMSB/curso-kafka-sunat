#!/bin/bash
# ============================================================
# Lab 09 - Validador del alumno (90)
# Verifica el estado ACTUAL: clúster + tópico. NO compila por ti;
# te dice cómo compilar y señala si ya tienes target/ construido.
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }
info(){ echo -e "  ${CYAN}·${NC} $1"; }

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
BOOT="kafka-broker-1:29092"
TOPIC="novatech.lab09.pedidos"

echo -e "${BOLD}Validador del Lab 09 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Tópico del lab
if [ "$VIVOS" -gt 0 ] && docker exec kafka-broker-1 kafka-topics --bootstrap-server "$BOOT" --list 2>/dev/null | grep -q "^${TOPIC}$"; then
    ok "el tópico ${TOPIC} existe"
else
    bad "el tópico ${TOPIC} no existe" "ejecuta bin/start-lab.sh (crea el tópico del lab)"
fi

# 3. Señal de avance de compilación (informativo, no bloquea)
if [ -d cliente-java/target/classes ]; then
    ok "cliente-java ya compilado (target/ presente)"
else
    info "aún no compilas cliente-java. Compílalo con:"
    info "  mvn -q -f cliente-java/pom.xml compile"
fi
if [ -d cliente-spring/target/classes ]; then
    ok "cliente-spring ya compilado (target/ presente)"
else
    info "aún no compilas cliente-spring. Compílalo con:"
    info "  mvn -q -f cliente-spring/pom.xml compile"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
