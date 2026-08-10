#!/bin/bash
# ============================================================
# Lab 14 - Validador del alumno (90)
# Verifica el estado ACTUAL: clúster seguro + admin + ACLs + PKI.
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

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
set -a; source infra/.env 2>/dev/null; set +a
BOOT="kafka-broker-1:9092"
ADMIN="/etc/kafka/client-properties/admin.properties"
TOPIC="novatech.lab12.confidencial"

ficha_op_verifica 'QUÉ VA A VERIFICAR' \
    'los 3 brokers están healthy' \
    'el listener seguro SASL_SSL responde al admin y ve el confidencial' \
    'las ACLs están cargadas (kafka-acls --list devuelve reglas)' \
    'el material PKI está en infra/certs (ca.crt + keystores)' \

echo -e "${BOLD}Validador del Lab 14 — estado actual${NC}"

# 1. Brokers
VIVOS=0
for i in 1 2 3; do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "kafka-broker-$i" 2>/dev/null)" = "healthy" ] && VIVOS=$((VIVOS+1))
done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 brokers están healthy"
else bad "solo ${VIVOS}/3 brokers healthy" "ejecuta bin/start-lab.sh y espera a que termine"; fi

# 2. Listener seguro + admin: listar el tópico confidencial vía SASL_SSL
if [ "$VIVOS" -gt 0 ] && docker exec -e KAFKA_OPTS= cli-client kafka-topics \
        --bootstrap-server "$BOOT" --command-config "$ADMIN" --list 2>/dev/null | grep -q "^${TOPIC}$"; then
    ok "el listener seguro responde a admin (SASL_SSL) y ve ${TOPIC}"
else
    bad "no pude hablar con el listener seguro como admin" "revisa cli-client y las credenciales admin.properties"
fi

# 3. ACLs presentes
if docker exec -e KAFKA_OPTS= cli-client kafka-acls \
        --bootstrap-server "$BOOT" --command-config "$ADMIN" --list 2>/dev/null | grep -q 'User:'; then
    ok "las ACLs están cargadas (list-acls devuelve reglas)"
else
    bad "no veo ACLs cargadas" "ejecuta bin/start-lab.sh (inicializa las ACLs del lab)"
fi

# 4. PKI presente localmente (sin validar contenido)
if [ -f infra/certs/ca.crt ] && ls infra/certs/*.keystore.jks >/dev/null 2>&1; then
    ok "material PKI presente (ca.crt + keystores)"
else
    bad "no encuentro el material PKI en infra/certs/" "ejecuta bin/start-lab.sh (genera certificados)"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
