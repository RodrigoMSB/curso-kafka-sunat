#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Lab 01: Exploración del clúster
# Ejecuta comandos de diagnóstico para inspeccionar el clúster
# ============================================================

# shellcheck source=common.sh
source "$(dirname "$0")/common.sh"
resolve_broker

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo ""
}

echo -e "${CYAN}  Usando broker: ${BROKER} (${BOOTSTRAP})${NC}"

# ── Sección 1: Lista de tópicos ──
banner "1. TÓPICOS DEL CLÚSTER"
docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" --list

# ── Sección 2: Descripción del tópico principal ──
banner "2. DETALLE DEL TÓPICO novatech.fleet.gps"
docker exec "$BROKER" kafka-topics --bootstrap-server "$BOOTSTRAP" \
    --describe --topic novatech.fleet.gps

# ── Sección 3: Estado del quorum KRaft ──
banner "3. ESTADO DEL QUORUM KRAFT"
docker exec "$BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" \
    describe --status

# ── Sección 4: Grupos de consumidores ──
banner "4. GRUPOS DE CONSUMIDORES"
docker exec "$BROKER" kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
    --list 2>/dev/null || echo -e "${YELLOW}  No hay grupos de consumidores activos aún${NC}"

echo ""
GROUPS=$(docker exec "$BROKER" kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" --list 2>/dev/null || true)
if [ -n "$GROUPS" ]; then
    echo -e "${YELLOW}  Detalle de grupos:${NC}"
    docker exec "$BROKER" kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" \
        --describe --all-groups 2>/dev/null || true
fi

# ── Sección 5: Información de replicación ──
banner "5. ESTADO DE REPLICACIÓN"
docker exec "$BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" \
    describe --replication

echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Exploración completada${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""
