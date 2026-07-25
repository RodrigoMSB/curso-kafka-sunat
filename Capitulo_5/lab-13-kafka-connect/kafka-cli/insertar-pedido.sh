#!/bin/bash
# Inserta un pedido nuevo en PostgreSQL.
# El JDBC Source connector detectará el cambio en ~5 segundos
# y publicará el evento al tópico novatech.lab09.pedidos.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

CLIENTE="${1:-2001}"
PRODUCTO="${2:-Producto demo $(date +%s)}"
CANTIDAD="${3:-10}"
MONTO="${4:-15000.00}"

echo -e "${CYAN}[Insertar Pedido] Insertando pedido en PostgreSQL...${NC}"
docker exec postgres psql -U novatech -d novatech_orders -c \
  "INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado) VALUES (${CLIENTE}, '${PRODUCTO}', ${CANTIDAD}, ${MONTO}, 'pendiente') RETURNING id;"

echo ""
echo -e "${YELLOW}En ~5 segundos, el Source connector lo capturará y publicará a:${NC}"
echo -e "  ${CYAN}novatech.lab09.pedidos${NC}"
echo ""
echo -e "Verifica con: ${GREEN}kafka-cli/consume-pedidos.sh${NC}"
