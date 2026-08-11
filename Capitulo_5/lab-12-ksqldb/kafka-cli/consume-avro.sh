#!/bin/bash
# Consume mensajes Avro y los muestra como JSON usando kafka-avro-console-consumer.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

TOPIC="${1:?Uso: $0 <topic>}"

# ── Ficha didáctica ──────────────────────────────────────────
# Este archivo es CANÓNICO: vive en tools/ficha/wrappers/ y se replica por
# hash a los labs 11 y 12, que lo tienen idéntico byte a byte. Entró al mapa
# en la SPEC-71, cuando el arreglo del -it borró la única diferencia que
# tenía con su par -- y esa diferencia era un bug, no una decisión.
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)             echo "de qué tópico se lee" ;;
        --from-beginning)    echo "empieza por el mensaje más viejo que el tópico conserva" ;;
        schema.registry.url) echo "dónde preguntar por el schema. Sin esto el consumidor no sabe traducir los bytes y falla" ;;
        *)                   flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Leer ${TOPIC} con el consumidor de Avro, que trae de vuelta el schema desde el Registry y nos muestra JSON en vez de bytes"
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-avro-console-consumer --bootstrap-server kafka-broker-1:29092 \'
    ficha_comando "    --topic $TOPIC --from-beginning \\"
    ficha_comando '    --property schema.registry.url=http://schema-registry:8081'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:29092' ''
    ficha_flag '--topic'            "$TOPIC"               ''
    ficha_flag '--from-beginning'   ''                     ''
    ficha_flag '--property' 'schema.registry.url=http://schema-registry:8081' 'schema.registry.url'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un JSON por mensaje, aunque en el tópico no haya JSON.'
    ficha_texto 'Lo que viaja son bytes binarios con un número de schema adelante. El consumidor lee ese número, le pide al Registry el schema que le corresponde y recién entonces puede traducir. Por eso Avro ocupa menos que JSON y por eso sin Registry no se lee nada.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor schema-registry, no del broker, porque las'
    ficha_nota 'herramientas de Avro vienen en esa imagen y no en la de Kafka.'
    echo ''
fi

echo -e "${CYAN}[Consume Avro] Tópico: ${TOPIC}${NC}"
echo "  Presiona Ctrl+C para detener"
echo "────────────────────────────────────────────────────────"

docker exec -i \
  -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
  schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic "$TOPIC" \
  --from-beginning \
  --property schema.registry.url=http://schema-registry:8081
