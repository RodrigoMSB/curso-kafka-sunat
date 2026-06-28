#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Generador de datos GPS
# Simula datos de telemetría de la flota de vehículos
# Coordenadas: Santiago de Chile (zona Maipú)
#
# Arquitectura: un solo proceso kafka-console-producer (una JVM)
# alimentado por un pipe desde el loop generador. Esto evita
# arrancar una JVM por cada mensaje (que es caro en memoria y
# tiempo).
# ============================================================

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-broker-1:29092}"
TOPIC_NAME="${TOPIC_NAME:-novatech.fleet.gps}"

# ── Paso 1: Inicializar tópicos ──
echo -e "${YELLOW}[NovaTech GPS] Inicializando tópicos...${NC}"
bash /scripts/init-topics.sh

echo -e "${GREEN}[NovaTech GPS] Iniciando generación de datos GPS...${NC}"
echo -e "${CYAN}  Bootstrap: ${BOOTSTRAP_SERVER}${NC}"
echo -e "${CYAN}  Tópico:    ${TOPIC_NAME}${NC}"
echo -e "${CYAN}  Vehículos: NVT-1001 a NVT-1005${NC}"
echo ""

# Función que genera mensajes JSON en bucle y los escribe a stdout.
# Los logs informativos van a stderr para no contaminar el pipe
# que alimenta al productor.
generate_messages() {
    # Vehículos de la flota NovaTech
    local VEHICLES=("NVT-1001" "NVT-1002" "NVT-1003" "NVT-1004" "NVT-1005")
    local STATUSES=("MOVING" "MOVING" "MOVING" "STOPPED" "IDLE")

    # Posiciones base (Santiago de Chile - zona Maipú)
    local BASE_LATS=(-33.4500 -33.4520 -33.4480 -33.4600 -33.4450)
    local BASE_LONS=(-70.6500 -70.6520 -70.6480 -70.6600 -70.6450)

    local MSG_COUNT=0

    while true; do
        # Ciclar entre los 5 vehículos
        local INDEX=$((MSG_COUNT % 5))
        local VEHICLE_ID="${VEHICLES[$INDEX]}"

        # Generar variación aleatoria en la posición
        local LAT_VARIATION
        local LON_VARIATION
        LAT_VARIATION=$(awk "BEGIN {srand(); printf \"%.4f\", (rand() - 0.5) * 0.01}")
        LON_VARIATION=$(awk "BEGIN {srand(); printf \"%.4f\", (rand() - 0.5) * 0.01}")

        local LATITUDE
        local LONGITUDE
        LATITUDE=$(awk "BEGIN {printf \"%.4f\", ${BASE_LATS[$INDEX]} + $LAT_VARIATION}")
        LONGITUDE=$(awk "BEGIN {printf \"%.4f\", ${BASE_LONS[$INDEX]} + $LON_VARIATION}")

        # Velocidad según estado
        local STATUS="${STATUSES[$INDEX]}"
        local SPEED
        case "$STATUS" in
            "MOVING")
                SPEED=$((RANDOM % 80 + 30))
                if [ $((RANDOM % 10)) -eq 0 ]; then
                    STATUSES[$INDEX]="STOPPED"
                fi
                ;;
            "STOPPED")
                SPEED=0
                if [ $((RANDOM % 5)) -eq 0 ]; then
                    STATUSES[$INDEX]="MOVING"
                fi
                ;;
            "IDLE")
                SPEED=$((RANDOM % 5))
                if [ $((RANDOM % 7)) -eq 0 ]; then
                    STATUSES[$INDEX]="MOVING"
                fi
                ;;
        esac

        # Timestamp ISO 8601
        local TIMESTAMP
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        # Construir mensaje JSON
        local MESSAGE="{\"vehicleId\":\"${VEHICLE_ID}\",\"latitude\":${LATITUDE},\"longitude\":${LONGITUDE},\"speed\":${SPEED},\"status\":\"${STATUS}\",\"timestamp\":\"${TIMESTAMP}\"}"

        # Emitir el mensaje al pipe (stdout)
        echo "$MESSAGE"

        MSG_COUNT=$((MSG_COUNT + 1))

        # Log informativo a stderr (no contamina el pipe del productor)
        echo -e "${GREEN}[${TIMESTAMP}]${NC} ${CYAN}#${MSG_COUNT}${NC} -> ${VEHICLE_ID} | lat:${LATITUDE} lon:${LONGITUDE} | ${SPEED}km/h | ${STATUS}" >&2

        # Esperar 2 segundos entre mensajes
        sleep 2
    done
}

# Un solo proceso kafka-console-producer consume el pipe.
# Una sola JVM para toda la vida del contenedor.
generate_messages | kafka-console-producer \
    --bootstrap-server "$BOOTSTRAP_SERVER" \
    --topic "$TOPIC_NAME"
