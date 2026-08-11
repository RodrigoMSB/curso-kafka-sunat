#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
NUM="${2:-5000}"
# ── Ficha didáctica ──────────────────────────────────────────
# El nombre dice "sample" pero por debajo corre kafka-producer-perf-test. La
# ficha existe justamente para que el alumno vea qué se ejecuta de verdad.
# Solo con TTY.
flag_desc() {
    case "$1" in
        --topic)           echo "a qué tópico se le manda la carga" ;;
        --num-records)     echo "cuántos mensajes manda en total" ;;
        --record-size)     echo "cuántos bytes pesa cada uno" ;;
        --throughput)      echo "tope de mensajes por segundo. Con -1 empuja todo lo que pueda" ;;
        --producer-props)  echo "las propiedades del productor" ;;
        bootstrap.servers) echo "por dónde entra al clúster. Aquí va adentro de las props, no como --bootstrap-server" ;;
        *)                 flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Llenar ${TOPIC} con ${NUM} mensajes para que haya datos que mover cuando reasignemos particiones. El nombre dice sample, pero por debajo corre la herramienta de rendimiento."
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-producer-perf-test --topic $TOPIC \\"
    ficha_comando "    --num-records $NUM --record-size 256 --throughput -1 \\"
    ficha_comando "    --producer-props bootstrap.servers=$BOOTSTRAP"
    ficha_medio 'DESGLOSE'
    ficha_flag '--topic'          "$TOPIC" ''
    ficha_flag '--num-records'    "$NUM"   ''
    ficha_flag '--record-size'    '256'    ''
    ficha_flag '--throughput'     '-1'     ''
    ficha_flag '--producer-props' ''       ''
    ficha_flag "  bootstrap.servers=$BOOTSTRAP" '' 'bootstrap.servers'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'La línea de records/sec y latencias es del perf-test, no de este wrapper. Aquí no interesa el número, interesa que el tópico quede con datos.'
    ficha_cerrar
    ficha_nota_warn 'Kafka 8.x avisa que --producer-props está deprecado. Su reemplazo es'
    ficha_nota '--command-property, distinto del --reader-property del console-producer.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-producer-perf-test está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Sample] Produciendo ${NUM} mensajes en ${TOPIC}...${NC}"
docker exec "$BROKER" kafka-producer-perf-test \
    --topic "$TOPIC" --num-records "$NUM" --record-size 256 --throughput -1 \
    --producer-props bootstrap.servers="$BOOTSTRAP"
echo -e "${GREEN}✓ Mensajes producidos${NC}"
