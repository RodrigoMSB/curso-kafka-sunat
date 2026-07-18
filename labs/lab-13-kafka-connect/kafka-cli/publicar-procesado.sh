#!/bin/bash
# Publica un mensaje al tópico novatech.lab09.pedidos.procesados.
# El JDBC Sink connector lo detectará y escribirá en la tabla pedidos_procesados.
#
# Nota: el JSON incluye 'schema' + 'payload' porque el Sink connector necesita
# saber el tipo de cada campo para mapearlo a columnas SQL. Esto es el formato
# estándar de Kafka Connect cuando se usa JsonConverter con schemas.enable=true.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

PEDIDO_ID="${1:?Uso: $0 <pedido_id>}"
TOPIC="novatech.lab09.pedidos.procesados"

MENSAJE=$(cat <<EOF
{"schema":{"type":"struct","fields":[{"field":"id","type":"int32","optional":false},{"field":"cliente_id","type":"int32","optional":true},{"field":"producto","type":"string","optional":true},{"field":"cantidad","type":"int32","optional":true},{"field":"monto","type":"double","optional":true},{"field":"estado","type":"string","optional":true}],"optional":false},"payload":{"id":${PEDIDO_ID},"cliente_id":1001,"producto":"Pedido procesado en $(date +%H:%M:%S)","cantidad":1,"monto":99999.99,"estado":"procesado"}}
EOF
)

echo -e "${CYAN}[Publicar Procesado] -> ${TOPIC}${NC}"
echo "  Pedido ID: ${PEDIDO_ID}"
echo ""

echo "$MENSAJE" | docker exec -i "$BROKER" kafka-console-producer \
  --bootstrap-server "$BOOTSTRAP" \
  --topic "$TOPIC"

echo -e "${GREEN}  ✓ Mensaje publicado${NC}"
echo ""
echo -e "${YELLOW}En ~5 segundos verifica con:${NC}"
echo -e "  ${GREEN}kafka-cli/verificar-tabla-procesados.sh${NC}"