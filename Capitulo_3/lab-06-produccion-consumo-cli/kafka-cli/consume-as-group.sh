#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.fleet.events"
GROUP=""
SHOW_KEYS=""

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --group)
            GROUP="$2"
            shift 2
            ;;
        --with-keys)
            SHOW_KEYS="--property print.key=true --property key.separator=:"
            shift
            ;;
        --help|-h)
            echo "Uso: $0 --group <NOMBRE_GRUPO> [--with-keys]"
            echo ""
            echo "Consume como miembro del grupo especificado."
            echo "Las particiones se reparten entre miembros del mismo grupo."
            echo ""
            echo "Ejemplos:"
            echo "  $0 --group dashboard"
            echo "  $0 --group alertas --with-keys"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}[ERROR] Argumento desconocido: $1${NC}"
            exit 1
            ;;
    esac
done

if [ -z "$GROUP" ]; then
    echo -e "${YELLOW}[ERROR] El parámetro --group es obligatorio. Usa --help.${NC}"
    exit 1
fi

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)         echo "de qué tópico se lee" ;;
        --group)         echo "el grupo al que te unes. Kafka reparte las particiones entre sus miembros y a cada mensaje lo lee uno solo" ;;
        print.key)       echo "imprime también la clave de cada mensaje, no solo el valor" ;;
        key.separator)   echo "con qué carácter se separan clave y valor en pantalla" ;;
        *)               flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Leer ${TOPIC} como miembro del grupo ${GROUP}, y dejar que Kafka reparta las particiones entre los miembros del grupo"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-console-consumer --bootstrap-server $BOOTSTRAP \\"
    if [ -n "$SHOW_KEYS" ]; then
        ficha_comando "    --topic $TOPIC --group $GROUP \\"
        ficha_comando '    --property print.key=true --property key.separator=:'
    else
        ficha_comando "    --topic $TOPIC --group $GROUP"
    fi
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--topic'            "$TOPIC"     ''
    ficha_flag '--group'            "$GROUP"     ''
    if [ -n "$SHOW_KEYS" ]; then
        ficha_flag '--property' 'print.key=true'   'print.key'
        ficha_flag '--property' 'key.separator=:'  'key.separator'
    fi
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un mensaje por línea, a medida que llegan, y solo los de las particiones que te tocaron. Si otro miembro del grupo está vivo, él ve las otras, y esa es la diferencia con consumir sin grupo.'
    ficha_cerrar
    if [ -n "$SHOW_KEYS" ]; then
        ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. El reemplazo NO es el mismo'
        ficha_nota 'en los dos lados: --formatter-property al consumir, --reader-property al producir.'
    fi
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-console-consumer está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Consume Group] tópico=${TOPIC} grupo=${GROUP}${NC}"
echo -e "${YELLOW}  Presiona Ctrl+C para detener${NC}"
echo "────────────────────────────────────────────────────────"

# shellcheck disable=SC2086
docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    --group "$GROUP" \
    $SHOW_KEYS
