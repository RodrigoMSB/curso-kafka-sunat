#!/bin/bash
# Verifica si un schema es compatible con la última versión registrada.
# Uso: check-compatibility.sh <subject> <archivo.avsc>

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

SUBJECT="${1:?Uso: $0 <subject> <archivo.avsc>}"
ARCHIVO="${2:?Uso: $0 <subject> <archivo.avsc>}"

if [ ! -f "$ARCHIVO" ]; then
    echo -e "${RED}Error: $ARCHIVO no encontrado${NC}"
    exit 1
fi

SCHEMA=$(python3 -c "import json,sys; print(json.dumps(open('$ARCHIVO').read()))")
PAYLOAD="{\"schema\": $SCHEMA}"

echo -e "${CYAN}[Check Compatibility] Subject: ${SUBJECT}${NC}"

curl -s -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "$PAYLOAD" \
  "http://localhost:8081/compatibility/subjects/${SUBJECT}/versions/latest" | python3 -m json.tool 2>/dev/null
