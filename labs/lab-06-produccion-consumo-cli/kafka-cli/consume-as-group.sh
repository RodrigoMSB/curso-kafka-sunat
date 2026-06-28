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

echo -e "${CYAN}[Consume Group] tópico=${TOPIC} grupo=${GROUP}${NC}"
echo -e "${YELLOW}  Presiona Ctrl+C para detener${NC}"
echo "────────────────────────────────────────────────────────"

# shellcheck disable=SC2086
docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    --group "$GROUP" \
    $SHOW_KEYS
