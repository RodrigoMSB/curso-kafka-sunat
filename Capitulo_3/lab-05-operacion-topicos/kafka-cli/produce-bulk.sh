#!/bin/bash
# Produce N mensajes generados automáticamente a un tópico.
# Útil para llenar tópicos rápido y observar throughput / segmentación.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <N> [--key-pattern PATTERN]

Genera N mensajes automáticos y los publica al tópico.

Opciones:
  --key-pattern PATTERN   Si se especifica, usa PATTERN-i como clave de cada mensaje
                          (ej: NVT-1001, NVT-1002, ...)

Ejemplos:
  $0 novatech.gps.realtime 1000
  $0 novatech.vehicle.state 100 --key-pattern NVT
EOF
    exit 1
fi

TOPIC="$1"
N="$2"
shift 2

KEY_PATTERN=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --key-pattern) KEY_PATTERN="$2"; shift 2 ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)       echo "a qué tópico se escriben los mensajes" ;;
        parse.key)     echo "el productor parte cada línea en clave y valor. Sin esto, la línea entera es el valor y la clave va vacía" ;;
        key.separator) echo "por qué carácter la parte. Aquí, lo anterior al primer ':' es la clave" ;;
        *)             flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    if [ -n "$KEY_PATTERN" ]; then
        ficha_texto "Publicar ${N} mensajes en ${TOPIC} con claves ${KEY_PATTERN}-1 en adelante, para ver cómo la clave decide en qué partición cae cada uno"
    else
        ficha_texto "Publicar ${N} mensajes en ${TOPIC} sin clave, para llenarlo rápido y mirar cómo se reparte y cómo crecen sus segmentos"
    fi
    ficha_medio 'COMANDO REAL'
    if [ -n "$KEY_PATTERN" ]; then
        ficha_comando "seq 1 $N | awk '{ print \"${KEY_PATTERN}-\"\$1\":evento_\"\$1 }' | \\"
        ficha_comando "  kafka-console-producer --bootstrap-server $BOOTSTRAP --topic $TOPIC \\"
        ficha_comando '    --property parse.key=true --property key.separator=:'
    else
        ficha_comando "seq 1 $N | awk '{ print \"evento_\"\$1 }' | \\"
        ficha_comando "  kafka-console-producer --bootstrap-server $BOOTSTRAP --topic $TOPIC"
    fi
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--topic'            "$TOPIC"     ''
    if [ -n "$KEY_PATTERN" ]; then
        ficha_flag '--property' 'parse.key=true'  'parse.key'
        ficha_flag '--property' 'key.separator=:' 'key.separator'
    fi
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El productor no imprime nada por mensaje. La línea de resumen con los msg/seg la calcula este wrapper, no Kafka, y sirve para comparar entre corridas, no como medición de rendimiento. Para eso está el lab 07.'
    ficha_cerrar
    if [ -n "$KEY_PATTERN" ]; then
        ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. Del lado del productor el'
        ficha_nota 'reemplazo es --reader-property, y del lado del consumidor --formatter-property.'
    fi
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-console-producer está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Produce Bulk] ${N} mensajes -> ${TOPIC}${NC}"
if [ -n "$KEY_PATTERN" ]; then
    echo "  Patrón de clave: ${KEY_PATTERN}-N"
fi
echo "────────────────────────────────────────────────────────"

START_TIME=$(date +%s)

if [ -n "$KEY_PATTERN" ]; then
    # Generar mensajes con clave en formato KEY:VALUE
    seq 1 "$N" | awk -v p="$KEY_PATTERN" '{ print p"-"$1":evento_"$1"_payload" }' | \
        docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC" \
            --property "parse.key=true" \
            --property "key.separator=:"
else
    # Generar mensajes sin clave
    seq 1 "$N" | awk '{ print "evento_"$1"_payload" }' | \
        docker exec -i "$BROKER" kafka-console-producer \
            --bootstrap-server "$BOOTSTRAP" \
            --topic "$TOPIC"
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
[ "$ELAPSED" -eq 0 ] && ELAPSED=1
RATE=$((N / ELAPSED))

echo -e "${GREEN}  ✓ ${N} mensajes publicados en ${ELAPSED}s (~${RATE} msg/seg)${NC}"
