#!/bin/bash
# Consume del topic confidencial usando credenciales de admin.
# DEBE FUNCIONAR (admin es super user, sin ACL necesaria).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --consumer.config) echo "las credenciales del consumidor. Aquí, las de admin" ;;
        --topic)           echo "de qué tópico se lee" ;;
        --from-beginning)  echo "desde el primer mensaje que el tópico conserva" ;;
        --timeout-ms)      echo "cuánto espera sin recibir antes de cortar. Sin esto quedaría colgado" ;;
        *)                 flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Leer el tópico confidencial como admin, que es super user del clúster y por eso pasa sin que ninguna ACL lo mire'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-console-consumer --bootstrap-server kafka-broker-1:9092 \'
    ficha_comando '    --consumer.config /etc/kafka/client-properties/admin.properties \'
    ficha_comando '    --topic novatech.lab12.confidencial --from-beginning --timeout-ms 5000'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092'         ''
    ficha_flag '--consumer.config'  'admin.properties'            ''
    ficha_flag '--topic'            'novatech.lab12.confidencial' ''
    ficha_flag '--from-beginning'   ''                            ''
    ficha_flag '--timeout-ms'       '5000'                        ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un mensaje por línea, y al final un TimeoutException que es el fin normal del --timeout-ms, no una avería.'
    ficha_texto 'Compáralo con lo que le pasa a app2 sobre este mismo tópico. El super user es una llave maestra configurada en el broker, y por eso conviene que en producción sea de pocas manos.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client.'
    echo ''
fi

echo -e "${CYAN}[Consume Confidencial] User: admin ← novatech.lab12.confidencial${NC}"
echo -e "${YELLOW}  Esperado: admin SÍ puede leer (super user, ACLs no aplican).${NC}"
echo "────────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server kafka-broker-1:9092 \
    --consumer.config /etc/kafka/client-properties/admin.properties \
    --topic novatech.lab12.confidencial \
    --from-beginning \
    --timeout-ms 5000
