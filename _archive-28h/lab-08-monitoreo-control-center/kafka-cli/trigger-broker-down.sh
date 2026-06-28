#!/bin/bash
# Tumba un broker para disparar alertas en Control Center.
# CC Legacy detecta automáticamente la pérdida del broker y dispara
# triggers de "Under Replicated Partitions" si están configurados.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

if [ $# -ne 1 ]; then
    cat <<EOF
Uso: $0 <NUM_BROKER>

Tumba el broker indicado para disparar alertas.
NUM_BROKER: 1, 2 o 3

Ejemplo:
  $0 2

Para revivirlo:
  docker compose -f infra/docker-compose.yml --env-file infra/.env up -d kafka-broker-2
EOF
    exit 1
fi

BROKER_NUM="$1"
echo -e "${YELLOW}[Trigger Broker Down] Tumbando kafka-broker-${BROKER_NUM}...${NC}"
docker stop "kafka-broker-${BROKER_NUM}"
echo -e "${GREEN}  ✓ Broker ${BROKER_NUM} detenido${NC}"
echo ""
echo -e "${CYAN}En 30-60 segundos verás:${NC}"
echo "  → Control Center > Cluster Overview: el broker desaparece"
echo "  → Control Center > Alerts: el trigger configurado se dispara"
echo "  → Control Center > Topics: réplicas Out-Of-Sync en los tópicos"
