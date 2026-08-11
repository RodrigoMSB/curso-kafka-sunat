#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.fleet.events"
FROM_BEGINNING=""
SHOW_KEYS=""

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from-beginning)
            FROM_BEGINNING="--from-beginning"
            shift
            ;;
        --with-keys)
            SHOW_KEYS="--property print.key=true --property key.separator=:"
            shift
            ;;
        --help|-h)
            echo "Uso: $0 [--from-beginning] [--with-keys]"
            echo ""
            echo "Sin grupo: cada ejecución consume independientemente."
            echo "Por defecto consume solo mensajes nuevos (no históricos)."
            echo ""
            echo "Opciones:"
            echo "  --from-beginning  Lee también mensajes históricos"
            echo "  --with-keys       Muestra la clave de cada mensaje"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}[ERROR] Argumento desconocido: $1${NC}"
            exit 1
            ;;
    esac
done

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --from-beginning) echo "empieza por el mensaje más viejo que el tópico conserva. Sin él, solo verás lo que llegue de ahora en adelante" ;;
        print.key)        echo "imprime también la clave de cada mensaje, no solo el valor" ;;
        key.separator)    echo "con qué carácter se separan clave y valor en pantalla" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Leer ${TOPIC} sin pertenecer a ningún grupo, así que Kafka no lleva cuenta de por dónde vamos ni reparte nada, y vemos todas las particiones"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-console-consumer --bootstrap-server $BOOTSTRAP \\"
    ficha_comando "    --topic $TOPIC ${FROM_BEGINNING} ${SHOW_KEYS}"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--topic'            "$TOPIC"     ''
    if [ -n "$FROM_BEGINNING" ]; then
        ficha_flag '--from-beginning' '' ''
    fi
    if [ -n "$SHOW_KEYS" ]; then
        ficha_flag '--property' 'print.key=true'   'print.key'
        ficha_flag '--property' 'key.separator=:'  'key.separator'
    fi
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un mensaje por línea, a medida que llegan. Al no haber grupo no se guarda nada, así que si cortas con Ctrl+C y vuelves a entrar, arrancas otra vez desde el final y no desde donde ibas.'
    ficha_cerrar
    if [ -n "$SHOW_KEYS" ]; then
        ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. El reemplazo NO es el mismo'
        ficha_nota 'en los dos lados: --formatter-property al consumir, --reader-property al producir.'
    fi
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-console-consumer está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Consume] tópico=${TOPIC} (sin grupo, modo broadcast)${NC}"
echo -e "${YELLOW}  Presiona Ctrl+C para detener${NC}"
echo "────────────────────────────────────────────────────────"

# shellcheck disable=SC2086
docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    $FROM_BEGINNING \
    $SHOW_KEYS
