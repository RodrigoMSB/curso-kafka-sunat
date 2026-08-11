#!/bin/bash
# Elimina un tópico (con confirmación interactiva).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 1 ]; then
    echo "Uso: $0 <NOMBRE_TOPICO>"
    exit 1
fi

TOPIC="$1"

# ── Ficha didáctica ──────────────────────────────────────────
# Va ANTES de la confirmación, para que el alumno escriba el nombre sabiendo
# qué se lleva por delante. Solo con TTY.
flag_desc() {
    case "$1" in
        --topic)  echo "cuál se borra" ;;
        --delete) echo "borra el tópico entero, con sus particiones y todo lo que guardan" ;;
        *)        flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Borrar el tópico ${TOPIC} del clúster, con sus mensajes. No hay papelera ni deshacer."
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-topics --bootstrap-server $BOOTSTRAP --delete --topic $TOPIC"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--delete'           ''           ''
    ficha_flag '--topic'            "$TOPIC"     ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Kafka no imprime nada cuando le va bien. El borrado además es asíncrono, así que el tópico puede seguir apareciendo unos segundos en list-topics.sh antes de desaparecer.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-topics está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${RED}⚠  Vas a ELIMINAR el tópico '${TOPIC}' y TODOS sus mensajes.${NC}"
echo -n "Escribe el nombre del tópico para confirmar: "
read CONFIRM

if [ "$CONFIRM" != "$TOPIC" ]; then
    echo -e "${YELLOW}Cancelado.${NC}"
    exit 0
fi

docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --delete \
    --topic "$TOPIC"

echo -e "${GREEN}  ✓ Tópico ${TOPIC} eliminado${NC}"
