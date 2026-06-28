#!/bin/bash
# Monitorea el ISR de un tópico, mostrando cambios en tiempo real.
# Útil para ver cómo se reduce el ISR cuando un broker cae.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <TOPICO> [INTERVALO_SEG]

Monitorea el ISR del tópico cada N segundos (default: 2s).
Presiona Ctrl+C para detener.

Ejemplos:
  $0 novatech.lab05.resiliente
  $0 novatech.lab05.resiliente 1
EOF
    exit 1
fi

TOPIC="$1"
INTERVAL="${2:-2}"

echo -e "${CYAN}[Watch ISR] ${TOPIC} (cada ${INTERVAL}s)${NC}"
echo -e "${YELLOW}Presiona Ctrl+C para detener${NC}"
echo "════════════════════════════════════════════════════════"

trap "echo ''; echo -e '${YELLOW}Monitor detenido.${NC}'; exit 0" INT

while true; do
    # Re-resolver broker en cada iteración (puede haber cambiado)
    if ! BROKER=$(find_alive_broker); then
        echo -e "${RED}[ERROR] No hay brokers vivos.${NC}"
        sleep "$INTERVAL"
        continue
    fi
    BROKER_NUM="${BROKER##*-}"
    BOOTSTRAP="${BROKER}:$(( 29091 + BROKER_NUM ))"

    echo -e "${CYAN}─── $(date '+%H:%M:%S') ─── (vía ${BROKER}) ───${NC}"
    docker exec "$BROKER" kafka-topics \
        --bootstrap-server "$BOOTSTRAP" \
        --describe \
        --topic "$TOPIC" 2>/dev/null | grep -E "Topic:|Partition:" | head -10

    sleep "$INTERVAL"
done
