#!/bin/bash
# Produce un pedido Avro al tópico novatech.lab10.pedidos.
# Usa kafka-avro-console-producer (incluido en cp-schema-registry).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

ID="${1:-1}"
CLIENTE="${2:-1001}"
PRODUCTO="${3:-Caja premium}"
CANTIDAD="${4:-10}"
MONTO="${5:-25000.00}"
ESTADO="${6:-pendiente}"

SCHEMA='{"type":"record","name":"Pedido","namespace":"com.novatech.lab10","fields":[{"name":"id","type":"int"},{"name":"cliente_id","type":"int"},{"name":"producto","type":"string"},{"name":"cantidad","type":"int"},{"name":"monto","type":"double"},{"name":"estado","type":"string"}]}'

MENSAJE=$(cat <<EOF
{"id":${ID},"cliente_id":${CLIENTE},"producto":"${PRODUCTO}","cantidad":${CANTIDAD},"monto":${MONTO},"estado":"${ESTADO}"}
EOF
)

echo -e "${CYAN}[Produce Pedido Avro] -> novatech.lab10.pedidos${NC}"
echo "  ID: ${ID} | Cliente: ${CLIENTE} | Producto: ${PRODUCTO}"

echo "$MENSAJE" | docker exec -i \
  -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
  schema-registry kafka-avro-console-producer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic novatech.lab10.pedidos \
  --property schema.registry.url=http://schema-registry:8081 \
  --property value.schema="$SCHEMA"

echo -e "${GREEN}  ✓ Pedido publicado${NC}"
