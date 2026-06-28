#!/bin/bash
set -euo pipefail

# CRÍTICO: usar -e KAFKA_OPTS= en docker exec para no heredar el JAAS
# del broker (que es para servidor, no para cliente CLI).

echo "[init-lab12-topics] Creando tópicos del Lab 12..."

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server kafka-broker-1:9092 \
    --command-config /etc/kafka/client-properties/admin.properties \
    --create \
    --topic novatech.lab12.publico \
    --partitions 3 \
    --replication-factor 3 \
    --if-not-exists

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server kafka-broker-1:9092 \
    --command-config /etc/kafka/client-properties/admin.properties \
    --create \
    --topic novatech.lab12.confidencial \
    --partitions 3 \
    --replication-factor 3 \
    --if-not-exists

echo "✓ Tópicos del Lab 12 creados (publico + confidencial)"
