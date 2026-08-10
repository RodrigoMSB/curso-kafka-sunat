#!/bin/bash
# ============================================================
# Lab 11 - Validador del alumno (90)
# Verifica el estado ACTUAL: brokers + Schema Registry. Informa si
# ya registraste el schema del lab.
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }
info(){ echo -e "  ${CYAN}·${NC} $1"; }

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
SR_PORT="8081"
SUBJECT="novatech.lab10.pedidos-value"

ficha_op_verifica 'QUÉ VA A VERIFICAR' \
    'los 3 brokers están healthy' \
    'Schema Registry responde /subjects' \
    'si el subject novatech.lab10.pedidos-value ya está registrado' \

echo -e "${BOLD}Validador del Lab 11 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Schema Registry responde
if SUBJECTS=$(curl -sf "http://localhost:${SR_PORT}/subjects" 2>/dev/null); then
    ok "Schema Registry responde en :${SR_PORT}/subjects"
    # 3. ¿Ya registraste el schema? (informativo)
    if echo "$SUBJECTS" | grep -q "$SUBJECT"; then
        ok "el subject ${SUBJECT} está registrado"
    else
        info "aún no registras el schema. Prueba:"
        info "  schema-cli/register-schema.sh ${SUBJECT} infra/schemas/pedido.avsc"
        info "  o produce un Avro: kafka-cli/produce-pedido-avro.sh"
    fi
else
    bad "Schema Registry no responde en :${SR_PORT}" "revisa el contenedor: docker logs schema-registry"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
