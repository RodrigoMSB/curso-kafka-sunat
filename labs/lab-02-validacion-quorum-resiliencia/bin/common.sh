#!/bin/bash
# ============================================================
# NovaTech Logistics - Lab 03 - Biblioteca compartida
# ============================================================

# ── Colores ──
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Detectar un broker vivo (cualquier nombre) ──
# Busca contenedores que usen la imagen cp-kafka y estén corriendo.
# Devuelve el nombre del primero. Si no hay ninguno, retorna 1.
find_alive_kafka_container() {
    local CONTAINER
    CONTAINER=$(docker ps \
        --filter "ancestor=confluentinc/cp-kafka:8.2.0" \
        --filter "status=running" \
        --format "{{.Names}}" 2>/dev/null | head -1)
    if [ -n "$CONTAINER" ]; then
        echo "$CONTAINER"
        return 0
    fi
    echo ""
    return 1
}

# ── Resolver broker y bootstrap-server ──
# Fija las variables BROKER y BOOTSTRAP en el script que importa.
# Calcula el puerto PLAINTEXT correcto según el sufijo numérico del broker.
# Convención del lab: broker-N escucha PLAINTEXT en el puerto (29091 + N)
#   broker-1 -> 29092, broker-2 -> 29093, broker-3 -> 29094
# Aborta con código 1 si no hay brokers corriendo.
resolve_kafka_broker() {
    BROKER=$(find_alive_kafka_container)
    if [ -z "$BROKER" ]; then
        echo -e "${RED}[ERROR] No se encontró ningún contenedor Kafka corriendo.${NC}" >&2
        echo -e "${RED}  ¿Levantaste tu clúster con 'docker compose up -d' desde mi-cluster/?${NC}" >&2
        exit 1
    fi

    # Si el nombre termina en un número (ej: kafka-broker-2), calcular puerto
    if [[ "$BROKER" =~ -([0-9]+)$ ]]; then
        local BROKER_NUM="${BASH_REMATCH[1]}"
        BOOTSTRAP="${BROKER}:$(( 29091 + BROKER_NUM ))"
    else
        # Broker solitario (ej: kafka-broker sin sufijo numérico)
        BOOTSTRAP="${BROKER}:29092"
    fi

    export BROKER BOOTSTRAP
}
