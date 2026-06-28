#!/bin/bash
# ============================================================
# NovaTech Logistics - Biblioteca compartida
# Funciones y variables comunes a todos los scripts del lab.
# Se importa con:
#   source "$(dirname "$0")/common.sh"           # desde bin/
#   source "$(dirname "$0")/../bin/common.sh"    # desde kafka-cli/
# ============================================================

# ── Colores ──
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Detectar un broker disponible ──
# Recorre los brokers del 1 al 3 y devuelve el nombre del primero
# que está corriendo. Si ninguno está vivo, retorna 1.
find_alive_broker() {
    for i in 1 2 3; do
        if docker ps --filter "name=kafka-broker-${i}" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "kafka-broker-${i}"; then
            echo "kafka-broker-${i}"
            return 0
        fi
    done
    echo ""
    return 1
}

# ── Resolver broker y bootstrap-server ──
# Fija las variables BROKER y BOOTSTRAP en el script que importa.
# Aborta con código 1 si no hay brokers corriendo.
resolve_broker() {
    BROKER=$(find_alive_broker)
    if [ -z "$BROKER" ]; then
        echo -e "${RED}[ERROR] No hay brokers disponibles. ¿Ejecutaste bin/start-lab.sh?${NC}" >&2
        exit 1
    fi
    local BROKER_NUM="${BROKER##*-}"
    # Puertos PLAINTEXT: broker-1 -> 29092, broker-2 -> 29093, broker-3 -> 29094
    BOOTSTRAP="${BROKER}:$(( 29091 + BROKER_NUM ))"
    export BROKER BOOTSTRAP
}
