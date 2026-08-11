#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
TOPIC="${1:-novatech.lab12.confidencial}"
BOOT="${BOOT:-kafka-broker-1:9092,kafka-broker-2:9093,kafka-broker-3:9094}"
# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --command-config) echo "las credenciales de admin, que puede leer todo" ;;
        --topic)          echo "qué tópico se cuenta" ;;
        --from-beginning) echo "desde el primer mensaje. Sin esto contaría solo lo que llegue de ahora en adelante, o sea nada" ;;
        --timeout-ms)     echo "cuánto espera sin recibir antes de cortar y dar el total" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Contar cuántos mensajes hay en ${TOPIC} leyéndolos todos, para comprobar con un número que la caída del broker no se llevó ninguno"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-console-consumer --bootstrap-server $BOOT \\"
    ficha_comando '    --command-config /etc/kafka/client-properties/admin.properties \'
    ficha_comando "    --topic $TOPIC --from-beginning --timeout-ms 8000 | wc -l"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOT"            ''
    ficha_flag '--command-config'   'admin.properties' ''
    ficha_flag '--topic'            "$TOPIC"           ''
    ficha_flag '--from-beginning'   ''                 ''
    ficha_flag '--timeout-ms'       '8000'             ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un solo número, el total de mensajes leídos. La cuenta la hace wc -l sobre las líneas, no Kafka.'
    ficha_texto 'El sentido está en compararlo con lo que produjiste antes de tirar el broker. Igual quiere decir cero pérdida. El TimeoutException que el comando escupe al final es el fin normal del --timeout-ms y por eso se descarta.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client, con los tres brokers en el'
    ficha_nota 'bootstrap para que el conteo funcione aunque uno esté caído.'
    echo ''
fi

echo -e "${CYAN}[Verificación sin pérdida] Contando mensajes en ${TOPIC}...${NC}"
TOTAL=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client bash -c "kafka-console-consumer \
    --bootstrap-server $BOOT \
    --command-config /etc/kafka/client-properties/admin.properties \
    --topic $TOPIC --from-beginning --timeout-ms 8000 2>/dev/null | wc -l")
echo -e "${BOLD}  Total de mensajes leídos: ${TOTAL}${NC}"
