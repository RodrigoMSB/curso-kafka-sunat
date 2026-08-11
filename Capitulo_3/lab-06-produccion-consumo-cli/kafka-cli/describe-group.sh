#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_GRUPO>"
    echo "Ejemplo: $0 alertas"
    exit 1
fi

GROUP="$1"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka, porque las
# guías del curso hacen 'describe-group.sh alertas | head -3'.
flag_desc() {
    case "$1" in
        --group) echo "de qué grupo queremos el detalle" ;;
        *)       flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Ver cómo va el grupo ${GROUP}, hasta dónde leyó, cuánto le falta y quién de sus miembros atiende cada partición"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-consumer-groups --bootstrap-server $BOOTSTRAP \\"
    ficha_comando "    --describe --group $GROUP"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--describe'         ''           ''
    ficha_flag '--group'            "$GROUP"     ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'PARTITION'      'cada partición lleva su cuenta por separado'
    ficha_campo 'CURRENT-OFFSET' 'hasta dónde leyó el grupo en esa partición'
    ficha_campo 'LOG-END-OFFSET' 'hasta dónde escribió el productor'
    ficha_campo 'LAG'            'lo que falta por leer. Es la resta de los dos anteriores, y es el número que se vigila en producción'
    ficha_campo 'CONSUMER-ID'    'qué miembro atiende esa partición. Un guion es nadie'
    ficha_campo 'HOST'           'desde qué IP se conectó ese miembro'
    ficha_campo 'CLIENT-ID'      'el nombre con que la aplicación se presentó'
    ficha_cerrar
    ficha_nota 'Si nadie está conectado, Kafka avisa "has no active members" y las tres'
    ficha_nota 'últimas columnas salen en guion. El grupo y sus offsets siguen ahí.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-consumer-groups está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Describe Group] grupo=${GROUP}${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-consumer-groups \
    --bootstrap-server "$BOOTSTRAP" \
    --describe \
    --group "$GROUP"
