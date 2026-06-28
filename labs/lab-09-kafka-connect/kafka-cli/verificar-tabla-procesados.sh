#!/bin/bash
# Consulta la tabla pedidos_procesados en PostgreSQL para ver
# los registros que el JDBC Sink connector escribió.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[Verificar Tabla] pedidos_procesados${NC}"
echo "────────────────────────────────────────────────────────"

docker exec postgres psql -U novatech -d novatech_orders -c \
  "SELECT id, cliente_id, producto, estado, procesado_en FROM pedidos_procesados ORDER BY procesado_en DESC LIMIT 10;"
