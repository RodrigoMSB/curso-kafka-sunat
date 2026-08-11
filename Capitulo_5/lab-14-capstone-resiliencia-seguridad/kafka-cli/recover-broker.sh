#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
BROKER_NUM="${1:-3}"
# ── Ficha operativa ──────────────────────────────────────────
# No ejecuta ningún comando de Kafka: hace 'docker start'. Sin flags que
# desglosar, le toca la familia operativa igual que a simulate-failure.
ficha_op "RECUPERAR EL BROKER ${BROKER_NUM}" \
    "Arranca de vuelta el contenedor kafka-broker-${BROKER_NUM} y lo devuelve al quórum" \
    "todo. El broker vuelve con sus datos y se pone al día copiando lo que se escribió mientras no estaba" \
    "nada. Es la operación inversa de simulate-failure.sh" \
    "después de haber visto el failover. El ISR tarda unos segundos en volver a 3, y hasta entonces el tópico sigue al límite"

echo -e "${YELLOW}[Recuperación] Levantando kafka-broker-${BROKER_NUM}...${NC}"
docker start "kafka-broker-${BROKER_NUM}"
echo -e "${GREEN}  ✓ kafka-broker-${BROKER_NUM} de vuelta. El ISR debería volver a 3 en unos segundos.${NC}"
