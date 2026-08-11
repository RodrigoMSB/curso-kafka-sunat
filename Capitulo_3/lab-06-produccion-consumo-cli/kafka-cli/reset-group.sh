#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.fleet.events"

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_GRUPO>"
    echo ""
    echo "Resetea los offsets del grupo al inicio (offset 0 en todas las particiones)."
    echo "El grupo NO debe tener consumidores activos al ejecutar este comando."
    exit 1
fi

GROUP="$1"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --reset-offsets) echo "mueve la marca de lectura del grupo. No borra ni un mensaje del tópico" ;;
        --group)         echo "a qué grupo se le mueve la marca" ;;
        --topic)         echo "sobre qué tópico se mueve, con todas sus particiones" ;;
        --to-earliest)   echo "adónde se mueve, al primer mensaje que el tópico todavía conserva" ;;
        --execute)       echo "lo aplica de verdad. Con --dry-run en su lugar, Kafka solo muestra lo que haría" ;;
        *)               flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Mandar al grupo ${GROUP} a releer el tópico desde el principio, poniendo su marca de lectura en cero"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-consumer-groups --bootstrap-server $BOOTSTRAP \\"
    ficha_comando "    --reset-offsets --group $GROUP --topic $TOPIC \\"
    ficha_comando '    --to-earliest --execute'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--reset-offsets'    ''           ''
    ficha_flag '--group'            "$GROUP"     ''
    ficha_flag '--topic'            "$TOPIC"     ''
    ficha_flag '--to-earliest'      ''           ''
    ficha_flag '--execute'          ''           ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'PARTITION'  'una fila por partición, porque el reset va sobre todas'
    ficha_campo 'NEW-OFFSET' 'la marca que queda. Con --to-earliest es 0'
    ficha_texto 'Los mensajes no se tocan. Lo único que cambia es por dónde va el grupo, así que al reconectarse volverá a leerlos todos.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-consumer-groups está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${YELLOW}[Reset Group] grupo=${GROUP} -> --to-earliest${NC}"
echo -e "${YELLOW}  Asegúrate de que no haya consumidores activos en este grupo.${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --reset-offsets \
    --group "$GROUP" \
    --topic "$TOPIC" \
    --to-earliest \
    --execute
