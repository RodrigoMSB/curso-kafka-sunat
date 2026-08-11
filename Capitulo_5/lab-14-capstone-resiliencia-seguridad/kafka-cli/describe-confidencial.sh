#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
TOPIC="${1:-novatech.lab12.confidencial}"
BOOT="${BOOT:-kafka-broker-1:9092,kafka-broker-2:9093,kafka-broker-3:9094}"
# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --command-config) echo "las credenciales de admin. Sobre un listener SASL_SSL, sin esto no hay consulta que valga" ;;
        --topic)          echo "qué tópico describimos" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Ver cómo está ${TOPIC} por dentro, qué broker lidera cada partición y cuántas réplicas están al día, que es lo que hay que mirar al caer un nodo"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-topics --bootstrap-server $BOOT \\"
    ficha_comando '    --command-config /etc/kafka/client-properties/admin.properties \'
    ficha_comando "    --describe --topic $TOPIC"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOT"            ''
    ficha_flag '--command-config'   'admin.properties' ''
    ficha_flag '--describe'         ''                 ''
    ficha_flag '--topic'            "$TOPIC"           ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'Leader'   'qué broker atiende esa partición ahora. Cambia solo cuando el anterior se cae'
    ficha_campo 'Replicas' 'los brokers que deberían tener copia'
    ficha_campo 'Isr'      'los que la tienen al día. Con min.insync.replicas=2, si esta lista baja de 2 el tópico deja de aceptar escrituras'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client. Los tres brokers van en el'
    ficha_nota 'bootstrap para que la consulta siga funcionando si uno está caído.'
    echo ''
fi

echo -e "${CYAN}[Describe] ${TOPIC} — líderes e ISR por partición${NC}"
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server "$BOOT" \
    --command-config /etc/kafka/client-properties/admin.properties \
    --describe --topic "$TOPIC"
