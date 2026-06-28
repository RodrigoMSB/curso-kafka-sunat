#!/bin/bash
# Consume mensajes usando una estrategia de asignación de particiones específica.
# Permite comparar Range vs RoundRobin vs Sticky vs CooperativeSticky.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 --group <NOMBRE> [--strategy STRATEGY]

Opciones:
  --group NOMBRE         Nombre del consumer group (obligatorio)
  --strategy STRATEGY    Estrategia de asignación:
                           - range            (default de Kafka histórica)
                           - roundrobin       (distribución estricta)
                           - sticky           (minimiza re-asignación)
                           - cooperative      (default moderno, rebalanceo incremental)
                         (default: cooperative)

Ejemplos:
  $0 --group dashboard --strategy cooperative
  $0 --group alertas --strategy roundrobin
EOF
    exit 1
fi

GROUP=""
STRATEGY="cooperative"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --group) GROUP="$2"; shift 2 ;;
        --strategy) STRATEGY="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

if [ -z "$GROUP" ]; then
    echo -e "${RED}[ERROR] --group es obligatorio${NC}"
    exit 1
fi

# Mapear nombre amigable al fully-qualified class name
case "$STRATEGY" in
    range)
        STRATEGY_CLASS="org.apache.kafka.clients.consumer.RangeAssignor"
        ;;
    roundrobin)
        STRATEGY_CLASS="org.apache.kafka.clients.consumer.RoundRobinAssignor"
        ;;
    sticky)
        STRATEGY_CLASS="org.apache.kafka.clients.consumer.StickyAssignor"
        ;;
    cooperative)
        STRATEGY_CLASS="org.apache.kafka.clients.consumer.CooperativeStickyAssignor"
        ;;
    *)
        echo -e "${RED}[ERROR] Estrategia desconocida: ${STRATEGY}${NC}"
        echo "Válidas: range, roundrobin, sticky, cooperative"
        exit 1
        ;;
esac

TOPIC="novatech.lab07.eventos"

echo -e "${CYAN}[Consume con Estrategia] grupo=${GROUP} estrategia=${STRATEGY}${NC}"
echo "  Tópico:        ${TOPIC}"
echo "  Clase:         ${STRATEGY_CLASS}"
echo "────────────────────────────────────────────────────────"
echo -e "${YELLOW}  Presiona Ctrl+C para detener este consumer${NC}"
echo ""

docker exec -i "$BROKER" kafka-console-consumer \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$TOPIC" \
    --group "$GROUP" \
    --consumer-property "partition.assignment.strategy=${STRATEGY_CLASS}"
