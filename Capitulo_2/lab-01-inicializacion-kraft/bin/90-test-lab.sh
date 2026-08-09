#!/bin/bash
# ============================================================
# Lab 01 - Validador del alumno (90)
# Verifica el estado ACTUAL de tu broker. No modifica nada.
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

echo -e "${BOLD}Validador del Lab 01 — tu primer broker KRaft${NC}"

# 1. Contenedor (el broker único del lab se llama kafka-broker)
if docker ps --format '{{.Names}}' | grep -q '^kafka-broker$'; then
    ok "el contenedor kafka-broker está corriendo"
else
    bad "no encuentro kafka-broker corriendo" "revisa la guía 02 (arranque) o reconstruye con soluciones/"
fi

# 2. API del broker
if MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker \
     kafka-broker-api-versions --bootstrap-server kafka-broker:29092 >/dev/null 2>&1; then
    ok "el broker responde a la API"
else
    bad "el broker no responde" "mira docker logs kafka-broker; ¿formateaste el storage con tu cluster-id? (guía 02)"
fi

# 3. Storage formateado con cluster.id
CID=$(MSYS_NO_PATHCONV=1 docker exec kafka-broker bash -c \
      "grep -h 'cluster.id' /var/lib/kafka/data/meta.properties 2>/dev/null | head -1" 2>/dev/null)
if [ -n "$CID" ]; then
    ok "storage formateado (${CID})"
else
    bad "no veo meta.properties con cluster.id" "el formateo no ocurrió o el log.dirs apunta a otra ruta (guía 02)"
fi

# 4. Quórum de 1 nodo responde
if MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= kafka-broker \
     kafka-metadata-quorum --bootstrap-server kafka-broker:29092 describe --status 2>/dev/null | grep -q 'LeaderId'; then
    ok "el quórum KRaft (1 nodo) tiene líder"
else
    bad "el quórum no reporta líder" "revisa KAFKA_PROCESS_ROLES y CONTROLLER_QUORUM_VOTERS en tu compose (guía 02)"
fi

echo ""
if [ "$BAD" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ LAB EN BUEN ESTADO (${OK} verificaciones OK)${NC}"; exit 0
else
    echo -e "${RED}${BOLD}✗ HAY ${BAD} PROBLEMA(S) — revisa las sugerencias de arriba${NC}"; exit 1
fi
