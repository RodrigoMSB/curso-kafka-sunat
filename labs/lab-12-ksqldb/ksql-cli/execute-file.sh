#!/bin/bash
# Ejecuta un archivo .sql en ksqlDB.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

ARCHIVO="${1:?Uso: $0 <archivo.sql>}"

if [ ! -f "$ARCHIVO" ]; then
    echo -e "${RED}Error: $ARCHIVO no encontrado${NC}"
    exit 1
fi

echo -e "${CYAN}[Execute KSQL File] $ARCHIVO${NC}"
echo "────────────────────────────────────────────────────────"

# Copiar archivo al contenedor y ejecutarlo
docker cp "$ARCHIVO" ksqldb-cli:/tmp/statements.sql
docker exec ksqldb-cli ksql http://ksqldb-server:8088 --file /tmp/statements.sql
