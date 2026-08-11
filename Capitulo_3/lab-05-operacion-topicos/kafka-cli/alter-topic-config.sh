#!/bin/bash
# Modifica configuraciones de un tópico EN CALIENTE (sin reiniciar nada).
#
# Uso:
#   kafka-cli/alter-topic-config.sh <NOMBRE_TOPICO> --add KEY=VALUE [...]
#   kafka-cli/alter-topic-config.sh <NOMBRE_TOPICO> --delete KEY [...]

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 3 ]; then
    cat <<EOF
Uso:
  $0 <TOPICO> --add KEY=VALUE [--add KEY=VALUE ...]
  $0 <TOPICO> --delete KEY [--delete KEY ...]

Ejemplos:
  $0 novatech.gps.realtime --add retention.ms=7200000
  $0 novatech.gps.realtime --add compression.type=zstd --add segment.ms=3600000
  $0 novatech.gps.realtime --delete retention.ms
EOF
    exit 1
fi

TOPIC="$1"
shift

ADD_CONFIGS=()
DELETE_CONFIGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --add)    ADD_CONFIGS+=("$2"); shift 2 ;;
        --delete) DELETE_CONFIGS+=("$2"); shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --alter)         echo "modifica la configuración en caliente, sin reiniciar el broker ni mover datos" ;;
        --add-config)    echo "las propiedades que se fijan en este tópico, separadas por coma. Pisan lo que diga el broker" ;;
        --delete-config) echo "las propiedades que se quitan del tópico, que vuelve a heredar el valor del broker" ;;
        *)               flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    # Las dos listas se arman por separado y NUNCA dentro de una asignación
    # condicional: bajo 'set -e', un $( ) que devuelve 1 mata el script, y con
    # solo --delete la primera lista está vacía.
    FICHA_ADD=''
    FICHA_DEL=''
    if [ ${#ADD_CONFIGS[@]} -gt 0 ];    then FICHA_ADD=$(IFS=','; echo "${ADD_CONFIGS[*]}"); fi
    if [ ${#DELETE_CONFIGS[@]} -gt 0 ]; then FICHA_DEL=$(IFS=','; echo "${DELETE_CONFIGS[*]}"); fi
    ficha_abrir 'QUÉ VAMOS A HACER'
    if [ -n "$FICHA_ADD" ]; then
        ficha_texto "Fijarle a ${TOPIC} la configuración ${FICHA_ADD} sin reiniciar nada y sin tocar los mensajes que ya tiene"
    fi
    if [ -n "$FICHA_DEL" ]; then
        ficha_texto "Quitarle a ${TOPIC} la configuración ${FICHA_DEL}, con lo que vuelve a heredar el valor que tenga el broker"
    fi
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-configs --bootstrap-server $BOOTSTRAP --alter \\"
    ficha_comando "    --entity-type topics --entity-name $TOPIC \\"
    [ -n "$FICHA_ADD" ] && ficha_comando "    --add-config $FICHA_ADD"
    [ -n "$FICHA_DEL" ] && ficha_comando "    --delete-config $FICHA_DEL"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--entity-type'      'topics'     ''
    ficha_flag '--entity-name'      "$TOPIC"     ''
    ficha_flag '--alter'            ''           ''
    [ -n "$FICHA_ADD" ] && ficha_flag '--add-config'    "$FICHA_ADD" ''
    [ -n "$FICHA_DEL" ] && ficha_flag '--delete-config' "$FICHA_DEL" ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una línea, "Completed updating config for topic <nombre>". Para ver el valor que quedó y de dónde lo hereda, corre describe-topic.sh, que muestra las configuraciones efectivas.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-configs está en el PATH y no hace falta docker.'
    echo ''
fi

if [ ${#ADD_CONFIGS[@]} -gt 0 ]; then
    JOINED=$(IFS=','; echo "${ADD_CONFIGS[*]}")
    echo -e "${CYAN}[Alter Topic Config] ${TOPIC} - AGREGAR/MODIFICAR${NC}"
    echo "  ${JOINED}"
    docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics \
        --entity-name "$TOPIC" \
        --alter \
        --add-config "$JOINED"
    echo -e "${GREEN}  ✓ Configs aplicadas${NC}"
fi

if [ ${#DELETE_CONFIGS[@]} -gt 0 ]; then
    JOINED=$(IFS=','; echo "${DELETE_CONFIGS[*]}")
    echo -e "${CYAN}[Alter Topic Config] ${TOPIC} - ELIMINAR${NC}"
    echo "  ${JOINED}"
    docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics \
        --entity-name "$TOPIC" \
        --alter \
        --delete-config "$JOINED"
    echo -e "${GREEN}  ✓ Configs eliminadas (vuelven a heredar el valor default)${NC}"
fi
