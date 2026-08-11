#!/bin/bash
# Intenta consumir el topic confidencial usando credenciales de app2.
# DEBE FALLAR (app2 NO tiene ACL para confidencial).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

# ── Ficha didáctica ──────────────────────────────────────────
# Prueba NEGATIVA: este comando tiene que fallar, y el error es el resultado
# correcto. Solo con TTY.
flag_desc() {
    case "$1" in
        --consumer.config) echo "las credenciales con las que se presenta el consumidor. Aquí, las de app2" ;;
        --from-beginning)  echo "empezaría por el mensaje más viejo, si le dejaran leer" ;;
        --timeout-ms)      echo "cuánto espera sin recibir nada antes de rendirse. Sin esto quedaría colgado" ;;
        *)                 flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Intentar leer el tópico confidencial como app2, que sí tiene credenciales válidas pero NO tiene permiso sobre ese tópico'
    ficha_texto 'Es una prueba negativa. El rechazo es el resultado que se busca.'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-console-consumer --bootstrap-server kafka-broker-1:9092 \'
    ficha_comando '    --consumer.config /etc/kafka/client-properties/app2.properties \'
    ficha_comando '    --topic novatech.lab12.confidencial --from-beginning --timeout-ms 5000'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092'         ''
    ficha_flag '--consumer.config'  'app2.properties'             ''
    ficha_flag '--topic'            'novatech.lab12.confidencial' ''
    ficha_flag '--from-beginning'   ''                            ''
    ficha_flag '--timeout-ms'       '5000'                        ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Busca TOPIC_AUTHORIZATION_FAILED y la línea "Topic authorization failed". Eso es la ACL funcionando.'
    ficha_texto 'Fíjate en la diferencia con attempt-no-auth.sh: allí la conexión ni se establece porque falta la credencial; aquí app2 entra al clúster sin problema y es la autorización la que la frena en el tópico. Autenticar y autorizar son dos cosas distintas.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client, que tiene montadas las'
    ficha_nota 'credenciales de admin, app1 y app2.'
    echo ''
fi

echo -e "${RED}[Test denial] app2 intenta consumir topic confidencial...${NC}"
echo -e "${YELLOW}  Esto DEBE fallar con 'TopicAuthorizationException' o similar.${NC}"
echo "─────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server kafka-broker-1:9092 \
    --consumer.config /etc/kafka/client-properties/app2.properties \
    --topic novatech.lab12.confidencial \
    --from-beginning \
    --timeout-ms 5000 \
    2>&1 | head -20

echo "─────────────────────────────────────────────────────"
echo -e "${GREEN}[Resultado esperado] error tipo 'Not authorized' / 'TopicAuthorizationException'.${NC}"
echo -e "${GREEN}Eso PRUEBA que las ACLs funcionan: app2 NO puede leer confidencial.${NC}"
