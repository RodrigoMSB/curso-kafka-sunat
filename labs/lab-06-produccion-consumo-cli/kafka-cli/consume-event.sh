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

echo -e "${CYAN}[Consume] tópico=${TOPIC} (sin grupo, modo broadcast)${NC}"
echo -e "${YELLOW}  Presiona Ctrl+C para detener${NC}"
echo "────────────────────────────────────────────────────────"

# shellcheck disable=SC2086
docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    $FROM_BEGINNING \
    $SHOW_KEYS
