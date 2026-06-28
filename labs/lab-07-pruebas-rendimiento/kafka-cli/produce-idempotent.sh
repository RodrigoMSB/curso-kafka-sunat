#!/bin/bash
# Productor IDEMPOTENTE: enable.idempotence=true.
# Kafka deduplica reintentos automáticamente usando producer ID + sequence number.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES>

Productor CON idempotencia. Garantiza al-menos-una entrega SIN duplicados a nivel de productor.
Configuración:
  - enable.idempotence=true
  - acks=all (forzado, requerido por idempotencia)
  - retries=Integer.MAX_VALUE (forzado)
  - max.in.flight.requests.per.connection<=5 (forzado)

Ejemplo:
  $0 novatech.payments.attempts 100
EOF
    exit 1
fi

TOPIC="$1"
N="$2"

echo -e "${CYAN}[Produce IDEMPOTENT] ${N} mensajes -> ${TOPIC}${NC}"
echo "  enable.idempotence=true"
echo "  acks=all (auto)"
echo "  Deduplicación por Producer ID + Sequence Number"
echo "────────────────────────────────────────────────────────"

seq 1 "$N" | awk '{ print "PAY-IDEMP-"$1":monto_"$1 }' | \
    docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC" \
        --property "parse.key=true" \
        --property "key.separator=:" \
        --producer-property "enable.idempotence=true" \
        --producer-property "acks=all" \
        --producer-property "request.timeout.ms=100" \
        --producer-property "delivery.timeout.ms=10000"

echo -e "${GREEN}  ✓ Producción idempotente completada${NC}"
echo -e "${YELLOW}  Aunque haya reintentos, el broker descarta duplicados.${NC}"
