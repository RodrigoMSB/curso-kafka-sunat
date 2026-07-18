#!/bin/bash
# Describe una transacción específica.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 1 ]; then
    cat <<EOF
Uso: $0 <TRANSACTIONAL_ID>

Para listar todas: kafka-cli/list-transactions.sh
EOF
    exit 1
fi

TXN_ID="$1"

echo -e "${CYAN}[Describe Transaction] ${TXN_ID}${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-transactions \
    --bootstrap-server "$BOOTSTRAP" \
    describe \
    --transactional-id "$TXN_ID"
