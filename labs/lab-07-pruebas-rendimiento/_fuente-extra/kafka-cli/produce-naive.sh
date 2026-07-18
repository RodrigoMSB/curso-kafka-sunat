#!/bin/bash
# Productor "naive": SIN idempotencia, con request-timeout muy corto.
# Esta combinación facilita la aparición de duplicados al provocar reintentos.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES>

Productor SIN idempotencia. Configurado para mostrar el problema de duplicados:
  - enable.idempotence=false
  - retries=5
  - request.timeout.ms=100 (muy corto a propósito)
  - delivery.timeout.ms=2000

Bajo carga o con red ligeramente congestionada, los reintentos generan duplicados.

Ejemplo:
  $0 novatech.payments.attempts 100
EOF
    exit 1
fi

TOPIC="$1"
N="$2"

echo -e "${YELLOW}[Produce NAIVE] ${N} mensajes -> ${TOPIC}${NC}"
echo "  enable.idempotence=false"
echo "  retries=5"
echo "  request.timeout.ms=100 (corto, para forzar reintentos)"
echo "────────────────────────────────────────────────────────"

# Generar mensajes con clave única (PAY-N) y enviarlos
seq 1 "$N" | awk '{ print "PAY-"$1":monto_"$1 }' | \
    docker exec -i "$BROKER" kafka-console-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC" \
        --property "parse.key=true" \
        --property "key.separator=:" \
        --producer-property "enable.idempotence=false" \
        --producer-property "acks=all" \
        --producer-property "retries=5" \
        --producer-property "request.timeout.ms=100" \
        --producer-property "delivery.timeout.ms=2000" 2>&1 || true

echo -e "${GREEN}  ✓ Producción naive completada${NC}"
echo -e "${YELLOW}  Verifica con un consumer cuántos mensajes terminaron en el tópico.${NC}"
echo -e "${YELLOW}  Si hay reintentos exitosos sin idempotencia, verás MÁS de ${N} mensajes.${NC}"
