#!/bin/bash
# Produce mensajes continuamente hasta Ctrl+C.
# Útil para observar fallos en vivo: si el productor se cuelga, sabes que falló algo.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <TOPICO> [--rate MS] [--key-pattern PATTERN] [--acks ACKS]

Produce 1 mensaje cada MS milisegundos hasta Ctrl+C.

Opciones:
  --rate MS              Intervalo entre mensajes (default: 1000ms = 1 msg/seg)
  --key-pattern PATTERN  Si se especifica, usa PATTERN-N como clave
  --acks ACKS            Nivel de ACKs (0, 1 o all - default: all)

Ejemplos:
  $0 novatech.lab05.resiliente
  $0 novatech.lab05.resiliente --rate 200 --key-pattern NVT
  $0 novatech.lab05.estricto --acks all
EOF
    exit 1
fi

TOPIC="$1"
shift

RATE_MS=1000
KEY_PATTERN=""
ACKS="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rate) RATE_MS="$2"; shift 2 ;;
        --key-pattern) KEY_PATTERN="$2"; shift 2 ;;
        --acks) ACKS="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

# Convertir ms a segundos para sleep
RATE_S=$(awk "BEGIN { printf \"%.3f\", $RATE_MS / 1000 }")

echo -e "${CYAN}[Produce Continuous] -> ${TOPIC}${NC}"
echo "  Rate:  ${RATE_MS}ms (1 mensaje cada ${RATE_S}s)"
echo "  Acks:  ${ACKS}"
[ -n "$KEY_PATTERN" ] && echo "  Key pattern: ${KEY_PATTERN}-N"
echo "────────────────────────────────────────────────────────"
echo -e "${YELLOW}Presiona Ctrl+C para detener${NC}"
echo ""

# Generador en background que escribe a un FIFO, productor que lee del FIFO
FIFO=$(mktemp -u)
mkfifo "$FIFO"

trap "rm -f $FIFO; kill %1 2>/dev/null || true; exit 0" INT TERM EXIT

# Productor (lee del FIFO)
if [ -n "$KEY_PATTERN" ]; then
    docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC" \
        --producer-property "acks=${ACKS}" \
        --property "parse.key=true" \
        --property "key.separator=:" \
        < "$FIFO" &
else
    docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC" \
        --producer-property "acks=${ACKS}" \
        < "$FIFO" &
fi

# Generador (escribe al FIFO)
exec 3>"$FIFO"
COUNT=0
while true; do
    COUNT=$((COUNT + 1))
    if [ -n "$KEY_PATTERN" ]; then
        # Rotar entre 5 claves para distribución
        KEY_NUM=$((COUNT % 5 + 1))
        echo "${KEY_PATTERN}-${KEY_NUM}:evento_${COUNT}_$(date +%s)" >&3
    else
        echo "evento_${COUNT}_$(date +%s)" >&3
    fi
    echo -e "${GREEN}  → enviado #${COUNT}${NC}"
    sleep "$RATE_S"
done
