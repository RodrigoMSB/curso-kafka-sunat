#!/bin/bash
# Muestra streams y tables registrados en ksqlDB.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[Show Streams & Tables]${NC}"
echo "────────────────────────────────────────────────────────"

docker exec ksqldb-cli ksql http://ksqldb-server:8088 --execute "SHOW STREAMS; SHOW TABLES;"
