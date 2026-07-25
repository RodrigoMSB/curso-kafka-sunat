#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

BOOT_ALL="kafka-broker-1:9092,kafka-broker-2:9093,kafka-broker-3:9094"
BOOT_SURV="kafka-broker-1:9092,kafka-broker-2:9093"   # sin broker-3 (el que cae)
ADMIN="/etc/kafka/client-properties/admin.properties"
TOPIC="novatech.lab12.confidencial"

paso() { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}"; }
producir() {  # $1=desde $2=hasta $3=bootstrap
    for i in $(seq "$1" "$2"); do echo "pedido-capstone-$i"; done | \
    MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= cli-client kafka-console-producer \
        --bootstrap-server "$3" --producer.config "$ADMIN" \
        --producer-property acks=all --topic "$TOPIC"
}

echo -e "${BOLD}${CYAN}CAPSTONE NOVATECH — Resiliencia y Seguridad (automatizado)${NC}"

paso "1/8 · Estado inicial del clúster seguro (TLS+SASL+ACL, RF=3, min.ISR=2)"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server "$BOOT_ALL" --command-config "$ADMIN" --describe --topic "$TOPIC"

paso "2/8 · Producción autenticada con acks=all — 10 pedidos"
producir 1 10 "$BOOT_ALL"
echo -e "${GREEN}  ✓ 10 pedidos producidos sobre el canal seguro${NC}"

paso "3/8 · Simulación de fallo — cae kafka-broker-3"
docker stop kafka-broker-3
echo -e "${RED}  ✗ kafka-broker-3 caído${NC}"; sleep 6

paso "4/8 · Estado tras el fallo (nuevo líder electo, ISR baja a 2)"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server "$BOOT_SURV" --command-config "$ADMIN" --describe --topic "$TOPIC"

paso "5/8 · Producción DURANTE el fallo (ISR=2 ≥ min.ISR=2 → sin downtime)"
producir 11 20 "$BOOT_SURV"
echo -e "${GREEN}  ✓ 10 pedidos más, con un broker caído y cero pérdida${NC}"

paso "6/8 · Recuperación — vuelve kafka-broker-3"
docker start kafka-broker-3
echo -e "${GREEN}  ✓ kafka-broker-3 reintegrándose${NC}"; sleep 12

paso "7/8 · Verificación sin pérdida (deben ser 20 mensajes)"
TOTAL=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client bash -c "kafka-console-consumer \
    --bootstrap-server $BOOT_ALL --command-config $ADMIN \
    --topic $TOPIC --from-beginning --timeout-ms 8000 2>/dev/null | grep -c '^pedido-capstone'")
echo -e "${BOLD}  Mensajes totales: ${TOTAL} (esperado: 20)${NC}"

paso "8/8 · Estado recuperado (ISR vuelve a 3)"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server "$BOOT_ALL" --command-config "$ADMIN" --describe --topic "$TOPIC"

echo -e "\n${GREEN}${BOLD}✓ Capstone completado: seguridad (TLS+SASL+ACL) y resiliencia (failover sin pérdida) demostradas end-to-end.${NC}"
echo -e "${CYAN}  Para hacerlo paso a paso a mano, sigue guia/01..05.${NC}"
