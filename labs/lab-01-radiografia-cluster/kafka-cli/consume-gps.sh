#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - CLI: Consumir mensajes GPS
# Uso: consume-gps.sh [--history] [--max N]
# ============================================================

# shellcheck source=../bin/common.sh
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

FROM_BEGINNING=""
MAX_MESSAGES=10

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --history)
            FROM_BEGINNING="--from-beginning"
            shift
            ;;
        --max)
            if [[ -n "${2:-}" ]]; then
                MAX_MESSAGES="$2"
                shift 2
            else
                echo -e "${YELLOW}[ERROR] --max requiere un número como argumento${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${YELLOW}Uso: $0 [--history] [--max N]${NC}"
            echo -e "  --history  Consume desde el inicio del tópico"
            echo -e "  --max N    Número máximo de mensajes (defecto: 10)"
            exit 1
            ;;
    esac
done

if [ -n "$FROM_BEGINNING" ]; then
    echo -e "${CYAN}[NovaTech CLI] Consumiendo mensajes GPS (histórico, máx: ${MAX_MESSAGES})${NC}"
else
    echo -e "${CYAN}[NovaTech CLI] Consumiendo mensajes GPS en vivo (máx: ${MAX_MESSAGES})${NC}"
fi
echo -e "${CYAN}  (vía ${BROKER})${NC}"
echo -e "${YELLOW}  Presiona Ctrl+C para detener${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic novatech.fleet.gps \
    --group lab01-explorer \
    --max-messages "$MAX_MESSAGES" \
    $FROM_BEGINNING

echo ""
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}[OK] ${MAX_MESSAGES} mensajes consumidos${NC}"
