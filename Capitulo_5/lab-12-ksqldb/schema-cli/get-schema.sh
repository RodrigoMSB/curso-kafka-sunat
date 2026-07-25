#!/bin/bash
# Obtiene la última versión del schema de un subject.
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

SUBJECT="${1:?Uso: $0 <subject>}"

echo -e "${CYAN}[Get Schema] Subject: ${SUBJECT}${NC}"
curl -s "http://localhost:8081/subjects/${SUBJECT}/versions/latest" | python3 -m json.tool 2>/dev/null
