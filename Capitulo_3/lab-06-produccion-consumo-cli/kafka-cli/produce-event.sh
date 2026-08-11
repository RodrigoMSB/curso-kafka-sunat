#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.fleet.events"
KEY=""
VALUE=""

# Parsear argumentos: --key <key> "<value>"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --key)
            KEY="$2"
            shift 2
            ;;
        --help|-h)
            echo "Uso: $0 [--key <KEY>] \"<MENSAJE>\""
            echo ""
            echo "Ejemplos:"
            echo "  $0 \"vehicle:NVT-1001 status:MOVING\""
            echo "  $0 --key NVT-1001 \"status:STOPPED\""
            exit 0
            ;;
        *)
            VALUE="$1"
            shift
            ;;
    esac
done

if [ -z "$VALUE" ]; then
    echo -e "${YELLOW}[ERROR] Debes proporcionar un mensaje. Usa --help para más info.${NC}"
    exit 1
fi

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        parse.key)     echo "el productor parte cada línea en clave y valor. Sin esto, la línea entera es el valor y la clave va vacía" ;;
        key.separator) echo "por qué carácter la parte. Aquí, todo lo anterior al primer ':' es la clave" ;;
        *)             flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    if [ -n "$KEY" ]; then
        ficha_texto "Publicar un mensaje en ${TOPIC} con la clave ${KEY}, que es lo que decide en qué partición cae y qué mensajes quedan juntos y en orden"
    else
        ficha_texto "Publicar un mensaje en ${TOPIC} sin clave, así que Kafka lo repartirá entre las particiones sin garantizarle orden con ningún otro"
    fi
    ficha_medio 'COMANDO REAL'
    if [ -n "$KEY" ]; then
        ficha_comando "echo '${KEY}:${VALUE}' | kafka-console-producer \\"
        ficha_comando "    --bootstrap-server $BOOTSTRAP --topic $TOPIC \\"
        ficha_comando '    --property parse.key=true --property key.separator=:'
    else
        ficha_comando "echo '${VALUE}' | kafka-console-producer \\"
        ficha_comando "    --bootstrap-server $BOOTSTRAP --topic $TOPIC"
    fi
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--topic'            "$TOPIC"     ''
    if [ -n "$KEY" ]; then
        ficha_flag '--property' 'parse.key=true'  'parse.key'
        ficha_flag '--property' 'key.separator=:' 'key.separator'
    fi
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El productor no imprime nada cuando le va bien, y ese silencio es el éxito. Para comprobar que llegó, léelo con consume-event.sh --from-beginning.'
    ficha_cerrar
    if [ -n "$KEY" ]; then
        ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. El reemplazo NO es el mismo'
        ficha_nota 'en los dos lados: --reader-property al producir, --formatter-property al consumir.'
    fi
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-console-producer está en el PATH y no hace falta docker.'
    echo ''
fi

if [ -n "$KEY" ]; then
    echo -e "${CYAN}[Produce] key='${KEY}' value='${VALUE}'${NC}"
    echo "${KEY}:${VALUE}" | docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC" \
        --property "parse.key=true" \
        --property "key.separator=:"
else
    echo -e "${CYAN}[Produce] value='${VALUE}'${NC}"
    echo "${VALUE}" | docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC"
fi

echo -e "${GREEN}  ✓ Mensaje publicado en ${TOPIC}${NC}"
