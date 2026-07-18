#!/bin/bash
# Registra un schema Avro bajo un subject.
# Uso: register-schema.sh <subject-name> <archivo.avsc>

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

SUBJECT="${1:?Uso: $0 <subject> <archivo.avsc>}"
ARCHIVO="${2:?Uso: $0 <subject> <archivo.avsc>}"

if [ ! -f "$ARCHIVO" ]; then
    echo -e "${RED}Error: $ARCHIVO no encontrado${NC}"
    exit 1
fi

# Schema Registry espera el schema embebido en JSON con escape
SCHEMA=$(python3 -c "import json,sys; print(json.dumps(open('$ARCHIVO').read()))")

PAYLOAD="{\"schema\": $SCHEMA}"

echo -e "${CYAN}[Register Schema] Subject: ${SUBJECT}${NC}"

curl -s -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data "$PAYLOAD" \
  "http://localhost:8081/subjects/${SUBJECT}/versions" | python3 -m json.tool 2>/dev/null
