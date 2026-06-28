#!/bin/bash
# Produce un flood de pedidos Avro para tener datos en ksqlDB.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

CANTIDAD="${1:-50}"
PRODUCTOS=("Caja bananos" "Pallet reforzado" "Etiquetas RFID" "Cinta industrial" "Stretch film" "Cartón premium" "Papel kraft" "Cuerda nautica")
ESTADOS=("pendiente" "en_proceso" "enviado" "entregado")

echo -e "${CYAN}[Flood Pedidos Avro] Generando ${CANTIDAD} pedidos...${NC}"

for i in $(seq 1 "$CANTIDAD"); do
    CLIENTE=$((1000 + RANDOM % 100))
    PRODUCTO_IDX=$((RANDOM % ${#PRODUCTOS[@]}))
    ESTADO_IDX=$((RANDOM % ${#ESTADOS[@]}))
    CANTIDAD_PED=$((1 + RANDOM % 100))
    MONTO=$(awk -v r="$RANDOM" 'BEGIN{printf "%.2f", 1000 + (r % 200000)}')

    "$(dirname "$0")/produce-pedido-avro.sh" \
        "$i" "$CLIENTE" "${PRODUCTOS[$PRODUCTO_IDX]}" \
        "$CANTIDAD_PED" "$MONTO" "${ESTADOS[$ESTADO_IDX]}" 2>&1 | tail -1
done

echo -e "${GREEN}  ✓ ${CANTIDAD} pedidos generados${NC}"
