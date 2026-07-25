#!/bin/bash
# Aumenta el número de particiones de un tópico (NUNCA se puede disminuir).
# IMPORTANTE: aumentar particiones rompe el orden por clave para mensajes nuevos.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUEVO_NUMERO_DE_PARTICIONES>

ADVERTENCIA: solo se puede AUMENTAR el número de particiones, nunca disminuir.
ADVERTENCIA: aumentar particiones cambia la asignación hash(key) % num_partitions
             para mensajes futuros, rompiendo el orden por clave.

Ejemplo:
  $0 novatech.gps.realtime 12
EOF
    exit 1
fi

TOPIC="$1"
NEW_PARTITIONS="$2"

echo -e "${YELLOW}[Alter Partitions] ${TOPIC} -> ${NEW_PARTITIONS} particiones${NC}"
echo -e "${YELLOW}⚠  Esta operación NO PUEDE deshacerse.${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --alter \
    --topic "$TOPIC" \
    --partitions "$NEW_PARTITIONS"

echo -e "${GREEN}  ✓ Particiones actualizadas${NC}"
