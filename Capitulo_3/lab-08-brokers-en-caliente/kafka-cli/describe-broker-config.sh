#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
ENTITY="${1:-1}"   # id de broker, o "default"
# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --entity-type)    echo "sobre qué tipo de objeto preguntamos. Aquí, brokers" ;;
        --entity-name)    echo "de qué broker, por su id" ;;
        --entity-default) echo "en vez de un broker concreto, el valor que rige para todos" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    if [ "$ENTITY" = "default" ]; then
        ficha_texto 'Preguntar qué configuración dinámica rige para todos los brokers del clúster'
    else
        ficha_texto "Preguntar qué configuración dinámica tiene puesta el broker ${ENTITY}, o sea la que se cambió en caliente y no viene del archivo"
    fi
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-configs --bootstrap-server $BOOTSTRAP --describe \\"
    if [ "$ENTITY" = "default" ]; then
        ficha_comando '    --entity-type brokers --entity-default'
    else
        ficha_comando "    --entity-type brokers --entity-name $ENTITY"
    fi
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--describe'         ''           ''
    ficha_flag '--entity-type'      'brokers'    ''
    if [ "$ENTITY" = "default" ]; then
        ficha_flag '--entity-default' ''         ''
    else
        ficha_flag '--entity-name'    "$ENTITY"  ''
    fi
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Solo salen las configuraciones DINÁMICAS. Si no cambiaste ninguna, la lista queda vacía y eso es lo normal.'
    ficha_campo 'sensitive' 'si Kafka esconde el valor por ser un secreto'
    ficha_campo 'synonyms'  'de dónde puede venir el valor y en qué orden manda. DYNAMIC_BROKER_CONFIG le gana a DEFAULT_CONFIG, y ahí se ve qué pisó a qué'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-configs está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Config broker ${ENTITY}]${NC}"
if [ "$ENTITY" = "default" ]; then
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --describe --entity-type brokers --entity-default
else
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --describe --entity-type brokers --entity-name "$ENTITY"
fi
