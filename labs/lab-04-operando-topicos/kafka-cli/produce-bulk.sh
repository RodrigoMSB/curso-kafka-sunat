#!/bin/bash
# Produce N mensajes generados automáticamente a un tópico.
# Útil para llenar tópicos rápido y observar throughput / segmentación.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <N> [--key-pattern PATTERN]

Genera N mensajes automáticos y los publica al tópico.

Opciones:
  --key-pattern PATTERN   Si se especifica, usa PATTERN-i como clave de cada mensaje
                          (ej: NVT-1001, NVT-1002, ...)

Ejemplos:
  $0 novatech.gps.realtime 1000
  $0 novatech.vehicle.state 100 --key-pattern NVT
EOF
    exit 1
fi

TOPIC="$1"
N="$2"
shift 2

KEY_PATTERN=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --key-pattern) KEY_PATTERN="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${CYAN}[Produce Bulk] ${N} mensajes -> ${TOPIC}${NC}"
if [ -n "$KEY_PATTERN" ]; then
    echo "  Patrón de clave: ${KEY_PATTERN}-N"
fi
echo "────────────────────────────────────────────────────────"

START_TIME=$(date +%s)

if [ -n "$KEY_PATTERN" ]; then
    # Generar mensajes con clave en formato KEY:VALUE
    seq 1 "$N" | awk -v p="$KEY_PATTERN" '{ print p"-"$1":evento_"$1"_payload" }' | \
        docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC" \
            --property "parse.key=true" \
            --property "key.separator=:"
else
    # Generar mensajes sin clave
    seq 1 "$N" | awk '{ print "evento_"$1"_payload" }' | \
        docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC"
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
[ "$ELAPSED" -eq 0 ] && ELAPSED=1
RATE=$((N / ELAPSED))

echo -e "${GREEN}  ✓ ${N} mensajes publicados en ${ELAPSED}s (~${RATE} msg/seg)${NC}"
