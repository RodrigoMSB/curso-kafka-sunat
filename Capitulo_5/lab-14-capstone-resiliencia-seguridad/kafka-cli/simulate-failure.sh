#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
BROKER_NUM="${1:-3}"
# ── Ficha operativa ──────────────────────────────────────────
# No ejecuta ningún comando de Kafka: hace 'docker stop'. No hay flags que
# desglosar ni salida de Kafka que leer, así que le toca la familia operativa.
ficha_op "SIMULAR LA CAÍDA DEL BROKER ${BROKER_NUM}" \
    "Detiene el contenedor kafka-broker-${BROKER_NUM} para que veas al clúster reaccionar a la pérdida de un nodo" \
    "los datos del broker caído, que siguen en su volumen, y los otros brokers atendiendo con las réplicas que ya tenían" \
    "la disponibilidad de ese nodo mientras esté abajo. El ISR baja, y con min.insync.replicas=2 el tópico queda justo en el límite" \
    "es parte del ejercicio y se revierte cuando quieras con kafka-cli/recover-broker.sh ${BROKER_NUM}. No rompiste el lab"

echo -e "${YELLOW}[Failover] Deteniendo kafka-broker-${BROKER_NUM} (simulación de fallo de nodo)...${NC}"
docker stop "kafka-broker-${BROKER_NUM}"
echo -e "${RED}  ✗ kafka-broker-${BROKER_NUM} caído.${NC}"
echo -e "${CYAN}  Observa el nuevo liderazgo:  kafka-cli/describe-confidencial.sh${NC}"
echo -e "${CYAN}  Recupéralo cuando quieras:    kafka-cli/recover-broker.sh ${BROKER_NUM}${NC}"
