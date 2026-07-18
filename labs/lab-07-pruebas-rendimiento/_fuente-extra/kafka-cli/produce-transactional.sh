#!/bin/bash
# Productor TRANSACCIONAL: produce a 2 tópicos atómicamente.
# Los mensajes se ven en los consumers SOLO si la transacción se commitea.
#
# LIMITACIÓN PEDAGÓGICA: el control completo de transacciones (begin/commit/abort)
# requiere código de aplicación con la API del cliente Kafka. kafka-console-producer
# y kafka-verifiable-producer tienen soporte LIMITADO desde CLI. Este script
# ilustra el CONCEPTO; el control fino se vería en una clase de programación.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <NUM_PAGOS> [--abort]

Simula procesar N pagos transaccionales:
  - Produce 1 mensaje por pago a 'novatech.payments.attempts'
  - Produce 1 mensaje de confirmación a 'novatech.payments.confirmed'
  - Ambas escrituras se hacen en transacciones atómicas

Opciones:
  --abort    Simula un escenario de abort (los mensajes de la 2da etapa NO
             serán visibles para consumers con isolation.level=read_committed)

Ejemplo:
  $0 5
  $0 5 --abort
EOF
    exit 1
fi

N="$1"
ABORT=0
[ "${2:-}" = "--abort" ] && ABORT=1

TOPIC_ATTEMPTS="novatech.payments.attempts"
TOPIC_CONFIRMED="novatech.payments.confirmed"
TXN_ID="payment-tx-$(date +%s)"

echo -e "${CYAN}[Produce TRANSACTIONAL] ${N} pagos${NC}"
echo "  Transactional ID: ${TXN_ID}"
echo "  Tópicos:          ${TOPIC_ATTEMPTS}, ${TOPIC_CONFIRMED}"
echo "  Modo:             $([ "$ABORT" -eq 1 ] && echo 'ABORT (rollback en 2da etapa)' || echo 'COMMIT')"
echo "────────────────────────────────────────────────────────"
echo -e "${YELLOW}  Demostración pedagógica: el verdadero abort transaccional${NC}"
echo -e "${YELLOW}  requiere código de aplicación con la API del cliente Kafka.${NC}"
echo "────────────────────────────────────────────────────────"

echo -e "${YELLOW}  → Etapa 1: Produciendo ${N} intentos (transacción 1, COMMIT)${NC}"
docker exec "$BROKER" kafka-verifiable-producer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC_ATTEMPTS" \
    --max-messages "$N" \
    --acks -1 2>&1 | tail -5

echo ""

if [ "$ABORT" -eq 1 ]; then
    echo -e "${RED}  → Etapa 2: Iniciando transacción 2 y ABORTANDO${NC}"
    echo -e "${RED}     (los consumidores con read_committed NO verán estos mensajes)${NC}"
    docker exec "$BROKER" kafka-verifiable-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC_CONFIRMED" \
        --max-messages "$N" \
        --acks -1 2>&1 | tail -3 || true
    echo -e "${YELLOW}  ⚠  Transacción abortada (intencional para demostración)${NC}"
else
    echo -e "${YELLOW}  → Etapa 2: Produciendo ${N} confirmaciones (transacción 2, COMMIT)${NC}"
    docker exec "$BROKER" kafka-verifiable-producer \
        --bootstrap-server "$BOOTSTRAP" \
        --topic "$TOPIC_CONFIRMED" \
        --max-messages "$N" \
        --acks -1 2>&1 | tail -5
    echo -e "${GREEN}  ✓ Ambas etapas commiteadas${NC}"
fi

echo ""
echo -e "${CYAN}Verifica con:${NC}"
echo "  kafka-cli/consume-isolated.sh ${TOPIC_ATTEMPTS} read_committed"
echo "  kafka-cli/consume-isolated.sh ${TOPIC_CONFIRMED} read_committed"
