#!/bin/bash
# Produce un flood de pedidos Avro para tener datos en ksqlDB.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

CANTIDAD="${1:-50}"
PRODUCTOS=("Caja bananos" "Pallet reforzado" "Etiquetas RFID" "Cinta industrial" "Stretch film" "Cartón premium" "Papel kraft" "Cuerda nautica")
ESTADOS=("pendiente" "en_proceso" "enviado" "entregado")

# ── Ficha didáctica ──────────────────────────────────────────
# Este wrapper no ejecuta Kafka: llama N veces a produce-pedido-avro.sh, que
# es quien habla con el Registry. Por eso no hay flags de Kafka que desglosar:
# los suyos los explica la ficha de ese wrapper. Solo con TTY.
if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Generar ${CANTIDAD} pedidos con datos al azar y publicarlos en Avro, para que ksqlDB tenga un flujo con volumen sobre el que consultar"
    ficha_medio 'COMANDO REAL'
    ficha_comando "for i in 1..${CANTIDAD}"
    ficha_comando '    kafka-cli/produce-pedido-avro.sh <id> <cliente> <producto> <cant> <monto> <estado>'
    ficha_medio 'DESGLOSE'
    ficha_texto "El único parámetro propio es la cantidad, que hoy vale ${CANTIDAD} y por defecto es 50."
    ficha_texto 'Los productos, estados, clientes y montos salen de listas fijas y de $RANDOM, así que cada corrida genera datos distintos.'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una línea de confirmación por pedido, y al final el total. Si quieres ver el comando de Avro con todos sus flags, corre produce-pedido-avro.sh una sola vez y lee su ficha.'
    ficha_cerrar
    ficha_nota 'La salida de cada hijo se recorta a su última línea, así que aquí no se'
    ficha_nota 'repite su ficha ni su detalle.'
    echo ''
fi

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
