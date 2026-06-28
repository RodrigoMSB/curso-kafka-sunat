#!/bin/bash
# Wrapper: muestra el estado del quorum KRaft.
# Detecta automáticamente un broker vivo y el puerto PLAINTEXT correspondiente.

set -euo pipefail
source "$(dirname "$0")/common.sh"
resolve_kafka_broker

echo -e "${CYAN}[Check Quorum KRaft]${NC} (vía ${BROKER} en ${BOOTSTRAP})"
echo "────────────────────────────────────────────────────────"

echo -e "${YELLOW}── Estado del quorum ──${NC}"
docker exec "$BROKER" kafka-metadata-quorum \
    --bootstrap-server "$BOOTSTRAP" \
    describe --status

echo ""
echo -e "${YELLOW}── Réplicas del quorum ──${NC}"
docker exec "$BROKER" kafka-metadata-quorum \
    --bootstrap-server "$BOOTSTRAP" \
    describe --replication
