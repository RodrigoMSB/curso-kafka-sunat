#!/bin/bash
# Produce un mensaje al topic público usando credenciales de app1.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

MENSAJE="${1:-Hola desde app1 al topic publico - $(date +%H:%M:%S)}"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --producer.config) echo "las credenciales con las que se presenta el productor. Aquí, las de app1" ;;
        --topic)           echo "a qué tópico se escribe" ;;
        *)                 flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Escribir en el tópico público como app1. Es el mismo comando que el del confidencial, cambiando solo el tópico, y sirve para ver que la diferencia no está en el comando sino en las ACLs.'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'echo "$MENSAJE" | kafka-console-producer \'
    ficha_comando '    --bootstrap-server kafka-broker-1:9092 \'
    ficha_comando '    --producer.config /etc/kafka/client-properties/app1.properties \'
    ficha_comando '    --topic novatech.lab12.publico'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092'     ''
    ficha_flag '--producer.config'  'app1.properties'         ''
    ficha_flag '--topic'            'novatech.lab12.publico'  ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Silencio, igual que en el confidencial. Lo interesante es que este mensaje sí lo va a poder leer app2, y el otro no, con las mismas credenciales en los dos casos.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client.'
    echo ''
fi

echo -e "${CYAN}[Produce Publico] User: app1 → novatech.lab12.publico${NC}"
echo "  Mensaje: ${MENSAJE}"

echo "$MENSAJE" | MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= cli-client kafka-console-producer \
    --bootstrap-server kafka-broker-1:9092 \
    --producer.config /etc/kafka/client-properties/app1.properties \
    --topic novatech.lab12.publico

echo -e "${GREEN}  ✓ Mensaje publicado${NC}"
