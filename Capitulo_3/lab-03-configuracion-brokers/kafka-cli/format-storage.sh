#!/bin/bash
# Formatea el storage de un broker dentro de su contenedor.
# Necesario UNA VEZ antes del primer arranque del broker en KRaft.
#
# Uso: kafka-cli/format-storage.sh <NOMBRE_CONTAINER> <CLUSTER_ID>

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ $# -ne 2 ]; then
    echo "Uso: $0 <NOMBRE_CONTAINER> <CLUSTER_ID>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 kafka-broker-1 abc123-fake-cluster-id-xyz"
    exit 1
fi

CONTAINER="$1"
CLUSTER_ID="$2"

if ! docker ps --filter "name=^${CONTAINER}$" --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
    echo -e "${RED}[ERROR] El contenedor '${CONTAINER}' no está corriendo.${NC}"
    echo -e "${YELLOW}  Pista: levanta tu clúster primero con 'docker compose up -d'.${NC}"
    exit 1
fi

echo -e "${CYAN}[Format Storage] contenedor=${CONTAINER} cluster_id=${CLUSTER_ID}${NC}"
echo "────────────────────────────────────────────────────────"

# El comando de formato puede ya haberse ejecutado: usamos --ignore-formatted para idempotencia.
docker exec "$CONTAINER" kafka-storage format \
    --cluster-id "$CLUSTER_ID" \
    --config /etc/kafka/kafka.properties \
    --ignore-formatted

echo -e "${GREEN}✓ Storage formateado en ${CONTAINER}${NC}"
