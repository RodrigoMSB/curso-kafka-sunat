#!/bin/bash
# Produce un cliente Avro al tópico novatech.lab10.clientes.
# CRÍTICO: produce CON KEY (el id del cliente como int Avro), porque
# ksqlDB exige key para crear TABLEs sobre el tópico.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

ID="${1:-1001}"
NOMBRE="${2:-NovaCorp}"
TIPO="${3:-VIP}"
CIUDAD="${4:-Santiago}"

KEY_SCHEMA='{"type":"int"}'
VALUE_SCHEMA='{"type":"record","name":"Cliente","namespace":"com.novatech.lab10","fields":[{"name":"id","type":"int"},{"name":"nombre","type":"string"},{"name":"tipo","type":"string"},{"name":"ciudad","type":"string"}]}'

MENSAJE="${ID}:{\"id\":${ID},\"nombre\":\"${NOMBRE}\",\"tipo\":\"${TIPO}\",\"ciudad\":\"${CIUDAD}\"}"

echo -e "${CYAN}[Produce Cliente Avro] -> novatech.lab10.clientes${NC}"
echo "  ID: ${ID} | Nombre: ${NOMBRE} | Tipo: ${TIPO} | Ciudad: ${CIUDAD}"

# Producir con key Avro int + value Avro
echo "$MENSAJE" | docker exec -i \
  -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
  schema-registry kafka-avro-console-producer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic novatech.lab10.clientes \
  --property schema.registry.url=http://schema-registry:8081 \
  --property parse.key=true \
  --property key.separator=: \
  --property key.schema="$KEY_SCHEMA" \
  --property value.schema="$VALUE_SCHEMA"

echo -e "${GREEN}  ✓ Cliente publicado${NC}"
