#!/bin/bash
# Verifica que el storage de un broker está correctamente formateado.
# Uso: bin/verify-storage.sh <NOMBRE_CONTAINER>

set -euo pipefail
source "$(dirname "$0")/common.sh"

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_CONTAINER>"
    echo "Ejemplo: $0 kafka-broker-1"
    exit 1
fi

CONTAINER="$1"

if ! docker ps --filter "name=^${CONTAINER}$" --format "{{.Names}}" | grep -q "^${CONTAINER}$"; then
    echo -e "${RED}[ERROR] El contenedor '${CONTAINER}' no está corriendo.${NC}"
    exit 1
fi

echo -e "${CYAN}[Verify Storage] contenedor=${CONTAINER}${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$CONTAINER" kafka-storage info -c /etc/kafka/kafka.properties 2>&1 || \
docker exec "$CONTAINER" ls -la /var/lib/kafka/data 2>/dev/null

echo ""
echo -e "${YELLOW}Si ves un archivo 'meta.properties' con un cluster.id válido,${NC}"
echo -e "${YELLOW}el storage está correctamente formateado.${NC}"
