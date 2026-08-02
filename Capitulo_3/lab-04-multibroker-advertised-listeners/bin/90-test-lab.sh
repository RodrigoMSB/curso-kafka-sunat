#!/bin/bash
# ============================================================
# Lab 04 - Validador del alumno (90)
# Verifica el estado ACTUAL: clúster de 3 nodos, API interna y el
# listener EXTERNAL alcanzable desde fuera de la red Docker (el host).
# No modifica nada (solo produce/consume unas marcas efímeras).
# Uso: bin/90-test-lab.sh
# ============================================================
set -uo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
OK=0; BAD=0
ok()  { OK=$((OK+1));  echo -e "  ${GREEN}✓${NC} $1"; }
bad() { BAD=$((BAD+1)); echo -e "  ${RED}✗${NC} $1"; echo -e "    ${YELLOW}→ $2${NC}"; }
BOOT="kafka-broker-1:29092"
# El puerto que el lab publica al host. Por defecto el de siempre, que es
# el que ve el alumno. Los e2e del instructor exportan otro para no chocar
# con un cluster ya levantado, y este validador tiene que seguirlo.
EXT_PORT="${BROKER1_EXTERNAL_PORT:-9092}"

echo -e "${BOLD}Validador del Lab 04 — listeners y advertised.listeners${NC}"

# 1. Los 3 contenedores + API interna
VIVOS=0
for i in 1 2 3; do docker ps --format '{{.Names}}' | grep -q "^kafka-broker-$i$" && VIVOS=$((VIVOS+1)); done
if [ "$VIVOS" -eq 3 ]; then ok "los 3 contenedores kafka-broker-{1,2,3} están corriendo"
else bad "solo ${VIVOS}/3 contenedores corriendo" "levanta tu clúster de 3 (Lab 02) o usa soluciones/"; fi

API_OK=0
if [ "$VIVOS" -gt 0 ] && MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 \
     kafka-broker-api-versions --bootstrap-server "$BOOT" >/dev/null 2>&1; then
    ok "el broker responde a la API interna"; API_OK=1
else bad "el broker no responde por el listener interno" "espera a que arranquen o revisa docker logs kafka-broker-1"; fi

# 2. EXTERNAL alcanzable desde fuera de la red (el host es el cliente externo).
#    advertised EXTERNAL = localhost:9092 → se prueba con conexión TCP desde el host.
if (exec 3<>/dev/tcp/localhost/${EXT_PORT}) 2>/dev/null; then
    exec 3>&- 3<&- 2>/dev/null || true
    ok "el listener EXTERNAL responde en localhost:${EXT_PORT} (desde el host)"
else
    bad "no alcanzo el EXTERNAL en localhost:${EXT_PORT}" "tu advertised.listeners EXTERNAL publica una dirección inalcanzable — guía 02, Actividad 2"
fi

# 3. Produce/consume efímero por el listener interno
if [ "$VIVOS" -eq 3 ] && [ "$API_OK" -eq 1 ]; then
    MARK="chk-$(date +%s)-${RANDOM}"
    MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics \
        --bootstrap-server "$BOOT" --create --topic "$MARK" --partitions 3 --replication-factor 3 >/dev/null 2>&1
    for i in 1 2 3; do echo "${MARK}-${i}"; done | \
        MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= kafka-broker-1 kafka-console-producer \
        --bootstrap-server "$BOOT" --command-property acks=all --topic "$MARK" >/dev/null 2>&1
    GOT=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker-1 bash -c \
        "kafka-console-consumer --bootstrap-server $BOOT --topic $MARK --from-beginning --timeout-ms 8000 2>/dev/null | grep -c '^${MARK}-'")
    if [ "$GOT" = "3" ]; then ok "produce/consume interno funciona (3/3 marcas)"
    else bad "produce/consume: llegaron ${GOT}/3" "revisa la salud del clúster"; fi
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
