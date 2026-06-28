#!/bin/bash
set -euo pipefail

# ============================================================
# NovaTech Logistics - Inicialización de tópicos
# Crea los tópicos necesarios para el laboratorio
# ============================================================

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

BOOTSTRAP_SERVER="${BOOTSTRAP_SERVER:-kafka-broker-1:29092}"
TOPIC_NAME="${TOPIC_NAME:-novatech.fleet.gps}"
PARTITIONS="${PARTITIONS:-6}"
REPLICATION_FACTOR="${REPLICATION_FACTOR:-3}"

echo -e "${YELLOW}[NovaTech] Esperando a que el clúster Kafka esté disponible...${NC}"

MAX_RETRIES=30
RETRY_COUNT=0
while ! kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP_SERVER" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo -e "${RED}[ERROR] Timeout esperando al clúster Kafka después de $MAX_RETRIES intentos${NC}"
        exit 1
    fi
    echo -e "${YELLOW}  Intento $RETRY_COUNT/$MAX_RETRIES - Reintentando en 5 segundos...${NC}"
    sleep 5
done

echo -e "${GREEN}[OK] Clúster Kafka disponible${NC}"

# Verificar si el tópico ya existe
if kafka-topics --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -q "^${TOPIC_NAME}$"; then
    echo -e "${YELLOW}[INFO] El tópico '${TOPIC_NAME}' ya existe. No se requiere creación.${NC}"
else
    echo -e "${YELLOW}[NovaTech] Creando tópico '${TOPIC_NAME}'...${NC}"
    kafka-topics --bootstrap-server "$BOOTSTRAP_SERVER" \
        --create \
        --topic "$TOPIC_NAME" \
        --partitions "$PARTITIONS" \
        --replication-factor "$REPLICATION_FACTOR"
    echo -e "${GREEN}[OK] Tópico '${TOPIC_NAME}' creado exitosamente${NC}"
fi

# Verificar la creación
echo -e "${YELLOW}[NovaTech] Verificando configuración del tópico...${NC}"
echo "────────────────────────────────────────────────"
kafka-topics --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$TOPIC_NAME"
echo "────────────────────────────────────────────────"
echo -e "${GREEN}[OK] Tópico verificado correctamente${NC}"
