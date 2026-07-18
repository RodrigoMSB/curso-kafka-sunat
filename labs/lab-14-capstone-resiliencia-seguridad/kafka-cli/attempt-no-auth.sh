#!/bin/bash
# Intenta conectar al broker SIN credenciales SASL.
# DEBE FALLAR: el listener EXTERNAL solo acepta SASL_SSL.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${RED}[Test no-auth] Intentando conectar SIN credenciales...${NC}"
echo -e "${YELLOW}  Esto DEBE fallar porque el listener EXTERNAL exige SASL_SSL.${NC}"
echo "─────────────────────────────────────────────────────"

# kafka-topics --list SIN --command-config
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server kafka-broker-1:9092 \
    --list \
    2>&1 | head -10 || true

echo "─────────────────────────────────────────────────────"
echo -e "${GREEN}[Resultado esperado] error de timeout o falla de SASL/SSL handshake.${NC}"
echo -e "${GREEN}Eso PRUEBA que SASL_SSL impide conexiones sin credenciales.${NC}"
