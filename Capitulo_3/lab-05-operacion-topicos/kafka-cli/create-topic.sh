#!/bin/bash
# Crea un tópico con configuración personalizable.
#
# Uso:
#   kafka-cli/create-topic.sh <NOMBRE> [--partitions N] [--rf N] [--config K=V ...]
#
# Ejemplos:
#   kafka-cli/create-topic.sh novatech.test
#   kafka-cli/create-topic.sh novatech.gps.realtime --partitions 12 --rf 3 --config retention.ms=3600000 --config compression.type=lz4

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -lt 1 ]; then
    cat <<EOF
Uso: $0 <NOMBRE_TOPICO> [opciones]

Opciones:
  --partitions N         Número de particiones (default: 6)
  --rf N                 Replication factor (default: 3)
  --config KEY=VALUE     Config personalizada (puede repetirse)
  --if-not-exists        No fallar si el tópico ya existe

Ejemplos:
  $0 novatech.test
  $0 novatech.gps.realtime --partitions 12 --rf 3 \\
     --config retention.ms=3600000 --config compression.type=lz4
EOF
    exit 1
fi

TOPIC="$1"
shift

PARTITIONS=6
RF=3
IF_NOT_EXISTS=""
CONFIGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --partitions) PARTITIONS="$2"; shift 2 ;;
        --rf)         RF="$2"; shift 2 ;;
        --config)     CONFIGS+=("--config" "$2"); shift 2 ;;
        --if-not-exists) IF_NOT_EXISTS="--if-not-exists"; shift ;;
        *) echo -e "${RED}[ERROR] Argumento desconocido: $1${NC}"; exit 1 ;;
    esac
done

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)              echo "cómo se va a llamar el tópico nuevo" ;;
        --create)             echo "crea el tópico. Si ya existe, falla, salvo que le pongas --if-not-exists" ;;
        --partitions)         echo "en cuántos pedazos se parte. Es lo que permite repartir el trabajo entre consumidores, y solo se puede subir después" ;;
        --replication-factor) echo "cuántas copias de cada pedazo se guardan en brokers distintos. Con 3, aguantas perder uno" ;;
        --if-not-exists)      echo "no falla si el tópico ya estaba. Útil en scripts que se corren dos veces" ;;
        --config)             echo "una configuración propia del tópico, que pisa la del broker" ;;
        *)                    flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Crear el tópico ${TOPIC} con ${PARTITIONS} particiones y ${RF} copias de cada una, que es la decisión más difícil de cambiar después"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-topics --bootstrap-server $BOOTSTRAP --create \\"
    ficha_comando "    --topic $TOPIC --partitions $PARTITIONS --replication-factor $RF"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server'   "$BOOTSTRAP"  ''
    ficha_flag '--create'             ''            ''
    ficha_flag '--topic'              "$TOPIC"      ''
    ficha_flag '--partitions'         "$PARTITIONS" ''
    ficha_flag '--replication-factor' "$RF"         ''
    [ -n "$IF_NOT_EXISTS" ] && ficha_flag '--if-not-exists' '' ''
    if [ ${#CONFIGS[@]} -gt 0 ]; then
        for ((i=0; i<${#CONFIGS[@]}; i+=2)); do
            ficha_flag '--config' "${CONFIGS[i+1]}" '--config'
        done
    fi
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una línea, "Created topic <nombre>", y nada más. Si además ves un WARNING sobre puntos y guiones bajos, es Kafka avisando que un nombre que mezcla ambos puede chocar en sus métricas. El tópico se crea igual.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-topics está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Create Topic] ${TOPIC}${NC}"
echo "  Particiones:        ${PARTITIONS}"
echo "  Replication factor: ${RF}"
if [ ${#CONFIGS[@]} -gt 0 ]; then
    echo "  Configs personalizadas:"
    for ((i=0; i<${#CONFIGS[@]}; i+=2)); do
        echo "    ${CONFIGS[i+1]}"
    done
fi
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --create \
    --topic "$TOPIC" \
    --partitions "$PARTITIONS" \
    --replication-factor "$RF" \
    $IF_NOT_EXISTS \
    ${CONFIGS[@]+"${CONFIGS[@]}"}

echo -e "${GREEN}  ✓ Tópico ${TOPIC} creado${NC}"
