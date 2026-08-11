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

# ── Ficha didáctica ──────────────────────────────────────────
# Este archivo es CANÓNICO: vive en tools/ficha/wrappers/ y se replica por
# hash a los labs 11 y 12, que lo tienen idéntico byte a byte. Cualquier
# cambio se hace en el canónico y se replica, nunca en una copia.
# Solo con TTY.
flag_desc() {
    case "$1" in
        --topic)             echo "a qué tópico se escribe" ;;
        schema.registry.url) echo "dónde queda registrado el schema, y de dónde lo tomará quien lea" ;;
        value.schema)        echo "el tipo Avro del valor, campo por campo. Es el contrato que se registra" ;;
        *)                   flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Publicar el pedido ${ID} en formato Avro, declarando su schema en el mismo comando para que el Registry lo guarde y le asigne un número"
    ficha_medio 'COMANDO REAL'
    ficha_comando 'echo "$MENSAJE" | kafka-avro-console-producer \'
    ficha_comando '    --bootstrap-server kafka-broker-1:29092 --topic novatech.lab10.pedidos \'
    ficha_comando '    --property schema.registry.url=http://schema-registry:8081 \'
    ficha_comando '    --property value.schema=<record Pedido con sus 6 campos>'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:29092'  ''
    ficha_flag '--topic'            'novatech.lab10.pedidos' ''
    ficha_flag '--property' 'schema.registry.url=...' 'schema.registry.url'
    ficha_flag '--property' 'value.schema=record Pedido' 'value.schema'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El productor no imprime nada cuando le va bien.'
    ficha_texto 'El schema se registra la primera vez y queda con un número. Los mensajes siguientes viajan con ese número, no con el schema entero, y por eso Avro pesa tan poco. Si mandas un schema incompatible con el ya registrado, el Registry rechaza la escritura, y eso es justamente lo que este lab enseña.'
    ficha_cerrar
    ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. Al producir el reemplazo es'
    ficha_nota '--reader-property, y al consumir --formatter-property.'
    ficha_nota 'Corre dentro del contenedor schema-registry, no del broker, porque las'
    ficha_nota 'herramientas de Avro vienen en esa imagen.'
    echo ''
fi

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
