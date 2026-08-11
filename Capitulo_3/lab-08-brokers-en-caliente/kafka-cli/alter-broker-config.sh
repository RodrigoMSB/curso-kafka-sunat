#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
if [ $# -lt 2 ]; then
    echo "Uso: $0 <broker-id|default> <clave=valor>"
    echo "Ejemplo: $0 1 log.cleaner.threads=2"
    echo "Ejemplo (cluster-wide): $0 default log.retention.ms=3600000"
    exit 1
fi
ENTITY="$1"; CONFIG="$2"
# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --alter)          echo "aplica el cambio en caliente. El broker no se reinicia y nadie pierde conexión" ;;
        --entity-type)    echo "sobre qué tipo de objeto. Aquí, brokers" ;;
        --entity-name)    echo "a qué broker, por su id" ;;
        --entity-default) echo "en vez de a uno, a todos los brokers a la vez" ;;
        --add-config)     echo "la propiedad que se fija, en formato clave=valor" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    if [ "$ENTITY" = "default" ]; then
        ficha_texto "Fijar ${CONFIG} en TODOS los brokers a la vez, sin reiniciar ninguno"
    else
        ficha_texto "Fijar ${CONFIG} solo en el broker ${ENTITY}, sin reiniciarlo y sin cortar a nadie"
    fi
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-configs --bootstrap-server $BOOTSTRAP --alter \\"
    if [ "$ENTITY" = "default" ]; then
        ficha_comando "    --entity-type brokers --entity-default --add-config $CONFIG"
    else
        ficha_comando "    --entity-type brokers --entity-name $ENTITY --add-config $CONFIG"
    fi
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--alter'            ''           ''
    ficha_flag '--entity-type'      'brokers'    ''
    if [ "$ENTITY" = "default" ]; then
        ficha_flag '--entity-default' ''        ''
    else
        ficha_flag '--entity-name'    "$ENTITY" ''
    fi
    ficha_flag '--add-config'       "$CONFIG"    ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una línea, "Completed updating config for broker N". Para ver el valor que quedó y a quién le ganó, corre describe-broker-config.sh y mira sus synonyms.'
    ficha_texto 'No todas las propiedades del broker se pueden cambiar así. Las que no, Kafka las rechaza y hay que tocar el archivo y reiniciar.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-configs está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${YELLOW}[Alter] broker=${ENTITY} ${CONFIG}${NC}"
if [ "$ENTITY" = "default" ]; then
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --alter --entity-type brokers --entity-default --add-config "$CONFIG"
else
    docker exec "$BROKER" kafka-configs --bootstrap-server "$BOOTSTRAP" \
        --alter --entity-type brokers --entity-name "$ENTITY" --add-config "$CONFIG"
fi
echo -e "${GREEN}✓ Configuración aplicada en caliente (sin reinicio)${NC}"
