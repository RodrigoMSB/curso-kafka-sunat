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

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)             echo "a qué tópico se escribe" ;;
        schema.registry.url) echo "dónde queda registrado el schema, y de dónde lo tomará quien lea" ;;
        parse.key)           echo "parte la línea en clave y valor" ;;
        key.separator)       echo "por qué carácter la parte" ;;
        key.schema)          echo "el tipo Avro de la CLAVE. Aquí un int, el id del cliente" ;;
        value.schema)        echo "el tipo Avro del VALOR, campo por campo. Es el contrato que se registra" ;;
        *)                   flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Publicar el cliente ${ID} en Avro con su clave, que es lo que ksqlDB exige para poder crear una TABLE sobre este tópico"
    ficha_medio 'COMANDO REAL'
    ficha_comando 'echo "$MENSAJE" | kafka-avro-console-producer \'
    ficha_comando '    --bootstrap-server kafka-broker-1:29092 --topic novatech.lab10.clientes \'
    ficha_comando '    --property schema.registry.url=http://schema-registry:8081 \'
    ficha_comando '    --property parse.key=true --property key.separator=: \'
    ficha_comando '    --property key.schema=... --property value.schema=...'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:29092'   ''
    ficha_flag '--topic'            'novatech.lab10.clientes' ''
    ficha_flag '--property' 'schema.registry.url=...' 'schema.registry.url'
    ficha_flag '--property' 'parse.key=true'          'parse.key'
    ficha_flag '--property' 'key.separator=:'         'key.separator'
    ficha_flag '--property' 'key.schema={"type":"int"}' 'key.schema'
    ficha_flag '--property' 'value.schema=record Cliente' 'value.schema'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El productor no imprime nada cuando le va bien.'
    ficha_texto 'Lo que sí ocurre y no se ve es que el Registry guarda el schema la primera vez y le da un número. De ahí en adelante cada mensaje viaja con ese número y no con el schema entero.'
    ficha_cerrar
    ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. Al producir el reemplazo es'
    ficha_nota '--reader-property, y al consumir --formatter-property.'
    ficha_nota 'Corre dentro del contenedor schema-registry, no del broker.'
    echo ''
fi

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
