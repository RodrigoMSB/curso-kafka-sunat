#!/bin/bash
# Produce un mensaje al topic confidencial usando credenciales de app1.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

MENSAJE="${1:-Pago confidencial #$(date +%s) - app1}"

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
    ficha_texto 'Escribir en el tópico confidencial como app1, que es el único usuario con permiso para hacerlo además del admin'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'echo "$MENSAJE" | kafka-console-producer \'
    ficha_comando '    --bootstrap-server kafka-broker-1:9092 \'
    ficha_comando '    --producer.config /etc/kafka/client-properties/app1.properties \'
    ficha_comando '    --topic novatech.lab12.confidencial'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092'         ''
    ficha_flag '--producer.config'  'app1.properties'             ''
    ficha_flag '--topic'            'novatech.lab12.confidencial' ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El productor no imprime nada cuando le va bien, y ese silencio ya dice dos cosas. Que el handshake SASL_SSL salió bien, y que app1 tenía la ACL de escritura sobre este tópico.'
    ficha_texto 'Si le faltara cualquiera de las dos, verías un error en vez del silencio. Para comprobar que llegó, léelo con consume-confidencial-admin.sh.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client, que tiene montado el archivo'
    ficha_nota 'app1.properties con su usuario, su clave y el truststore.'
    echo ''
fi

echo -e "${CYAN}[Produce Confidencial] User: app1 → novatech.lab12.confidencial${NC}"
echo "  Mensaje: ${MENSAJE}"

echo "$MENSAJE" | MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= cli-client kafka-console-producer \
    --bootstrap-server kafka-broker-1:9092 \
    --producer.config /etc/kafka/client-properties/app1.properties \
    --topic novatech.lab12.confidencial

echo -e "${GREEN}  ✓ Mensaje publicado${NC}"
