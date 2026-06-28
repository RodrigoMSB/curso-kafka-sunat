#!/bin/bash
# Produce un FLOOD de mensajes muy rápido para generar lag intencionalmente.
# Útil para experimentos de "consumers no dan abasto".

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <NUM_MENSAJES> [--rate MS]

Produce N mensajes lo más rápido posible al tópico novatech.lab07.eventos.

Opciones:
  --rate MS    Tiempo entre mensajes en ms (default: 0 = sin límite)

Ejemplos:
  $0 10000              # 10K mensajes lo más rápido posible
  $0 1000 --rate 50     # 1K mensajes a 20 msg/seg (1 cada 50ms)
EOF
    exit 1
fi

N="$1"
shift

RATE_MS=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rate) RATE_MS="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

TOPIC="novatech.lab07.eventos"

echo -e "${CYAN}[Produce Flood] ${N} mensajes -> ${TOPIC}${NC}"
[ "$RATE_MS" -gt 0 ] && echo "  Rate: 1 mensaje cada ${RATE_MS}ms"
echo "────────────────────────────────────────────────────────"

START=$(date +%s)

if [ "$RATE_MS" -eq 0 ]; then
    # Sin límite: máxima velocidad.
    # Usamos un timestamp del shell (no awk's systime, que es GNU-only y
    # no existe en BSD awk de macOS). Es suficiente para etiquetar el
    # batch — todos los mensajes comparten el mismo timestamp del flood.
    TS=$(date +%s)
    seq 1 "$N" | awk -v ts="$TS" '{ print "evento_"$1"_"ts }' | \
        docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC" \
            --producer-property "acks=1"
else
    # Con rate limit
    RATE_S=$(awk "BEGIN { printf \"%.3f\", $RATE_MS / 1000 }")
    for i in $(seq 1 "$N"); do
        echo "evento_${i}_$(date +%s)" | docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC" \
            --producer-property "acks=1" 2>/dev/null
        sleep "$RATE_S"
    done
fi

END=$(date +%s)
ELAPSED=$((END - START))
[ "$ELAPSED" -eq 0 ] && ELAPSED=1
THROUGHPUT=$((N / ELAPSED))

echo -e "${GREEN}  ✓ ${N} mensajes en ${ELAPSED}s (~${THROUGHPUT} msg/seg)${NC}"
