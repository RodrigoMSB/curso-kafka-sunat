#!/bin/bash
# Wrapper de kafka-producer-perf-test con parámetros de tuning expuestos.
# Permite comparar throughput entre distintas configuraciones.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUM_MENSAJES> [opciones]

Opciones (todas opcionales):
  --record-size BYTES        Tamaño de cada mensaje (default: 200)
  --acks ACKS                Nivel de acks: 0, 1, all (default: all)
  --batch-size BYTES         Tamaño máximo de batch (default: 16384 = 16 KB)
  --linger-ms MS             Tiempo máximo de espera para acumular batch (default: 0)
  --compression TYPE         none, gzip, snappy, lz4, zstd (default: none)
  --throughput RATE          Mensajes/seg objetivo (-1 = sin límite, default: -1)

Ejemplos comparativos:
  # Baseline (sin tuning)
  $0 novatech.tuning.bench 50000

  # Batching agresivo
  $0 novatech.tuning.bench 50000 --batch-size 65536 --linger-ms 10

  # Compresión LZ4
  $0 novatech.tuning.bench 50000 --compression lz4

  # acks=1 (menor durabilidad, mayor throughput)
  $0 novatech.tuning.bench 50000 --acks 1

  # Combinación pro
  $0 novatech.tuning.bench 50000 --batch-size 65536 --linger-ms 10 --compression lz4 --acks 1
EOF
    exit 1
fi

TOPIC="$1"
NUM_RECORDS="$2"
shift 2

RECORD_SIZE=200
ACKS="all"
BATCH_SIZE=16384
LINGER_MS=0
COMPRESSION="none"
THROUGHPUT=-1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --record-size) RECORD_SIZE="$2"; shift 2 ;;
        --acks) ACKS="$2"; shift 2 ;;
        --batch-size) BATCH_SIZE="$2"; shift 2 ;;
        --linger-ms) LINGER_MS="$2"; shift 2 ;;
        --compression) COMPRESSION="$2"; shift 2 ;;
        --throughput) THROUGHPUT="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)          echo "a qué tópico se le manda la carga" ;;
        --num-records)    echo "cuántos mensajes manda en total" ;;
        --record-size)    echo "cuántos bytes pesa cada mensaje" ;;
        --throughput)     echo "tope de mensajes por segundo. Con -1 empuja todo lo que pueda" ;;
        --producer-props) echo "las propiedades del productor, que es donde vive el tuning" ;;
        bootstrap.servers) echo "por dónde entra al clúster. Aquí va adentro de las props" ;;
        acks)             echo "cuántas copias confirman antes de dar el mensaje por escrito" ;;
        batch.size)       echo "cuántos bytes junta antes de mandar un lote" ;;
        linger.ms)        echo "cuánto espera para llenar ese lote" ;;
        compression.type) echo "si comprime y con qué. Menos red, más CPU" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Medir cuántos mensajes por segundo aguanta el clúster escribiendo ${NUM_RECORDS} de ${RECORD_SIZE} bytes con esta combinación de tuning"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-producer-perf-test --topic $TOPIC \\"
    ficha_comando "    --num-records $NUM_RECORDS --record-size $RECORD_SIZE --throughput $THROUGHPUT \\"
    ficha_comando "    --producer-props bootstrap.servers=$BOOTSTRAP acks=$ACKS \\"
    ficha_comando "      batch.size=$BATCH_SIZE linger.ms=$LINGER_MS compression.type=$COMPRESSION"
    ficha_medio 'DESGLOSE'
    ficha_flag '--topic'          "$TOPIC"       ''
    ficha_flag '--num-records'    "$NUM_RECORDS" ''
    ficha_flag '--record-size'    "$RECORD_SIZE" ''
    ficha_flag '--throughput'     "$THROUGHPUT"  ''
    ficha_flag '--producer-props' ''             ''
    ficha_flag "  bootstrap.servers=$BOOTSTRAP" '' 'bootstrap.servers'
    ficha_flag "  acks=$ACKS"                   '' 'acks'
    ficha_flag "  batch.size=$BATCH_SIZE"       '' 'batch.size'
    ficha_flag "  linger.ms=$LINGER_MS"         '' 'linger.ms'
    ficha_flag "  compression.type=$COMPRESSION" '' 'compression.type'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'records/sec' 'el número que se compara entre corridas'
    ficha_campo 'MB/sec'      'lo mismo en bytes, que es lo que ve la red'
    ficha_campo 'avg latency' 'cuánto tarda en confirmarse un mensaje promedio'
    ficha_campo '99th'        'los peores casos. Suben antes que el promedio cuando algo se satura'
    ficha_cerrar
    ficha_nota_warn 'Kafka 8.x avisa que --producer-props está deprecado. Su reemplazo es'
    ficha_nota '--command-property, distinto del --reader-property del console-producer.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-producer-perf-test está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Perf Test] ${TOPIC}${NC}"
echo "  Mensajes:        ${NUM_RECORDS}"
echo "  Tamaño:          ${RECORD_SIZE} bytes"
echo "  Acks:            ${ACKS}"
echo "  Batch size:      ${BATCH_SIZE} bytes"
echo "  Linger ms:       ${LINGER_MS}"
echo "  Compresión:      ${COMPRESSION}"
echo "  Throughput cap:  ${THROUGHPUT} msg/seg"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" \
    --num-records "$NUM_RECORDS" \
    --record-size "$RECORD_SIZE" \
    --throughput "$THROUGHPUT" \
    --producer-props \
        bootstrap.servers="$BOOTSTRAP" \
        acks="$ACKS" \
        batch.size="$BATCH_SIZE" \
        linger.ms="$LINGER_MS" \
        compression.type="$COMPRESSION"
