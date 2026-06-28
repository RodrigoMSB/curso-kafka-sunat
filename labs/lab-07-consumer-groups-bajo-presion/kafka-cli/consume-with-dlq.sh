#!/bin/bash
# Consume mensajes y desvía a DLQ los que matcheen un patrón.
# Implementa el patrón Dead Letter Queue de manera simplificada.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 --group GROUP --pattern PATTERN [--max N]

Consume del tópico novatech.lab07.eventos. Si un mensaje contiene PATTERN
(considerado "venenoso"), lo redirige a novatech.lab07.dlq en vez de procesarlo.
Los demás mensajes se procesan normalmente.

Opciones:
  --group GROUP        Consumer group (obligatorio)
  --pattern PATTERN    Patrón string que indica un mensaje venenoso
  --max N              Máximo de mensajes a consumir (default: 50)

Ejemplos:
  $0 --group alertas --pattern POISON
  $0 --group alertas --pattern ERROR --max 100
EOF
    exit 1
fi

GROUP=""
PATTERN=""
MAX=50

while [[ $# -gt 0 ]]; do
    case "$1" in
        --group) GROUP="$2"; shift 2 ;;
        --pattern) PATTERN="$2"; shift 2 ;;
        --max) MAX="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

if [ -z "$GROUP" ] || [ -z "$PATTERN" ]; then
    echo -e "${RED}[ERROR] --group y --pattern son obligatorios${NC}"
    exit 1
fi

TOPIC_MAIN="novatech.lab07.eventos"
TOPIC_DLQ="novatech.lab07.dlq"

echo -e "${CYAN}[Consume con DLQ] grupo=${GROUP} patrón=\"${PATTERN}\"${NC}"
echo "  Tópico principal: ${TOPIC_MAIN}"
echo "  DLQ:              ${TOPIC_DLQ}"
echo "  Max mensajes:     ${MAX}"
echo "────────────────────────────────────────────────────────"

PROCESSED=0
ROUTED_TO_DLQ=0

# Consumir y procesar
docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC_MAIN" \
    --group "$GROUP" \
    --max-messages "$MAX" \
    --timeout-ms 30000 2>/dev/null | while IFS= read -r MSG; do

    if [[ "$MSG" == *"$PATTERN"* ]]; then
        # Mensaje venenoso: enviar a DLQ
        echo -e "${RED}  [DLQ] ${MSG}${NC}"
        echo "$MSG" | docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC_DLQ" 2>/dev/null
    else
        # Mensaje sano: procesar normalmente
        echo -e "${GREEN}  [OK]  ${MSG}${NC}"
    fi
done

echo ""
echo -e "${GREEN}✓ Consumo completado.${NC}"
echo -e "${CYAN}  Verifica la DLQ con:${NC}"
echo "  docker exec kafka-broker-1 kafka-console-consumer \\"
echo "      --bootstrap-server kafka-broker-1:29092 \\"
echo "      --topic ${TOPIC_DLQ} --from-beginning --max-messages 50 --timeout-ms 5000"
