#!/bin/bash
# Consume del topic público usando credenciales de app2.
# DEBE FUNCIONAR (app2 tiene ACL para el público).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --consumer.config) echo "las credenciales del consumidor. Aquí, las de app2" ;;
        --topic)           echo "de qué tópico se lee" ;;
        --from-beginning)  echo "desde el primer mensaje que el tópico conserva" ;;
        --timeout-ms)      echo "cuánto espera sin recibir antes de cortar" ;;
        *)                 flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Leer el tópico público como app2, que sí tiene ACL de lectura sobre él. Es el caso positivo que da sentido al negativo de consume-confidencial-app2.sh.'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-console-consumer --bootstrap-server kafka-broker-1:9092 \'
    ficha_comando '    --consumer.config /etc/kafka/client-properties/app2.properties \'
    ficha_comando '    --topic novatech.lab12.publico --from-beginning --timeout-ms 5000'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092'    ''
    ficha_flag '--consumer.config'  'app2.properties'        ''
    ficha_flag '--topic'            'novatech.lab12.publico' ''
    ficha_flag '--from-beginning'   ''                       ''
    ficha_flag '--timeout-ms'       '5000'                   ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Los mensajes, uno por línea, y el TimeoutException final que es el fin normal del --timeout-ms.'
    ficha_texto 'Las mismas credenciales de app2 que aquí funcionan son las que sobre el confidencial dan TOPIC_AUTHORIZATION_FAILED. Lo único que cambia es el nombre del tópico, y eso es exactamente lo que decide una ACL.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client.'
    echo ''
fi

echo -e "${CYAN}[Consume Publico] User: app2 ← novatech.lab12.publico${NC}"
echo -e "${YELLOW}  Esperado: app2 SÍ puede leer (tiene ACL).${NC}"
echo "────────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server kafka-broker-1:9092 \
    --consumer.config /etc/kafka/client-properties/app2.properties \
    --topic novatech.lab12.publico \
    --from-beginning \
    --timeout-ms 5000
