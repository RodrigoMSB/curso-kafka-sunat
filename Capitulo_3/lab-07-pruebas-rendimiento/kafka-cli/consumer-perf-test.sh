#!/bin/bash
# Wrapper de kafka-consumer-perf-test para medir throughput de consumo.
# Permite comparar el rendimiento de lectura entre configuraciones.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES> [opciones]

Opciones (todas opcionales):
  --fetch-size BYTES         Tamaño máximo por fetch (default: 1048576 = 1 MB)

Ejemplos:
  # Baseline
  $0 novatech.tuning.bench 100000

  # Fetch grande
  $0 novatech.tuning.bench 100000 --fetch-size 5242880
EOF
    exit 1
fi

TOPIC="$1"
NUM_RECORDS="$2"
shift 2

FETCH_SIZE=1048576

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fetch-size) FETCH_SIZE="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)       echo "de qué tópico se lee la carga" ;;
        --messages)    echo "cuántos mensajes leer antes de parar y dar el resultado" ;;
        --fetch-size)  echo "cuántos bytes pide por viaje al broker. Menos viajes, más memoria" ;;
        *)             flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Medir a qué velocidad se leen ${NUM_RECORDS} mensajes de ${TOPIC}, que es la otra mitad del rendimiento y la que casi nadie mide"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-consumer-perf-test --topic $TOPIC \\"
    ficha_comando "    --messages $NUM_RECORDS --bootstrap-server $BOOTSTRAP \\"
    ficha_comando "    --fetch-size $FETCH_SIZE"
    ficha_medio 'DESGLOSE'
    ficha_flag '--topic'            "$TOPIC"       ''
    ficha_flag '--messages'         "$NUM_RECORDS" ''
    ficha_flag '--bootstrap-server' "$BOOTSTRAP"   ''
    ficha_flag '--fetch-size'       "$FETCH_SIZE"  ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una fila de valores separados por coma, con su encabezado arriba. Se lee emparejando cada valor con su nombre.'
    ficha_campo 'nMsg.sec'          'mensajes por segundo, el número que se compara'
    ficha_campo 'MB.sec'            'lo mismo en bytes'
    ficha_campo 'rebalance.time.ms' 'lo que tardó en entrar al grupo antes de leer nada. Suele ser la mayor parte del total en pruebas cortas'
    ficha_campo 'fetch.time.ms'     'lo que tardó leyendo de verdad, ya sin el rebalanceo'
    ficha_cerrar
    ficha_nota_warn 'Kafka 8.x avisa que --messages está deprecado. Su reemplazo es --num-records,'
    ficha_nota 'que es como ya se llama el flag equivalente en el perf-test del productor.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-consumer-perf-test está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Consumer Perf Test] ${TOPIC}${NC}"
echo "  Mensajes:        ${NUM_RECORDS}"
echo "  Fetch size:      ${FETCH_SIZE} bytes"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-consumer-perf-test \
    --topic "$TOPIC" \
    --messages "$NUM_RECORDS" \
    --bootstrap-server "$BOOTSTRAP" \
    --fetch-size "$FETCH_SIZE"
