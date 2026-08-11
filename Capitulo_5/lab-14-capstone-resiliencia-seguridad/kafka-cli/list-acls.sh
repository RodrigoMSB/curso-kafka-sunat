#!/bin/bash
# Lista todas las ACLs del cluster.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --command-config) echo "el archivo con el usuario, su clave SASL y el material TLS. Sin esto el broker no te deja ni preguntar" ;;
        --list)           echo "solo consulta. Devuelve las reglas que hay, no las cambia" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Preguntar qué reglas de autorización tiene puestas el clúster, o sea quién puede hacer qué sobre cada tópico'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-acls --bootstrap-server kafka-broker-1:9092 \'
    ficha_comando '    --command-config /etc/kafka/client-properties/admin.properties \'
    ficha_comando '    --list'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092' ''
    ficha_flag '--command-config'   'admin.properties'    ''
    ficha_flag '--list'             ''                    ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un bloque por recurso, y adentro una línea por regla. Cada regla tiene cuatro partes y hay que leerlas juntas.'
    ficha_campo 'principal'      'a quién se le aplica, con el formato User:app1'
    ficha_campo 'host'           'desde qué IP. El asterisco es desde cualquiera'
    ficha_campo 'operation'      'qué puede hacer, como READ, WRITE, CREATE o DESCRIBE'
    ficha_campo 'permissionType' 'si la regla concede o niega. En Kafka lo que no está permitido está denegado, así que un tópico sin reglas no lo lee nadie salvo el super user'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client, que es el que tiene los'
    ficha_nota 'certificados y las credenciales montados.'
    echo ''
fi

echo -e "${CYAN}[List ACLs] Todas las reglas de autorización${NC}"
echo "────────────────────────────────────────────────────────"

MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-acls \
    --bootstrap-server kafka-broker-1:9092 \
    --command-config /etc/kafka/client-properties/admin.properties \
    --list
