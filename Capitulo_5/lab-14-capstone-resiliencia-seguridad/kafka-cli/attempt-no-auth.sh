#!/bin/bash
# Intenta conectar al broker SIN credenciales SASL.
# DEBE FALLAR: el listener EXTERNAL solo acepta SASL_SSL.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

# ── Ficha didáctica ──────────────────────────────────────────
# Prueba NEGATIVA: este comando tiene que fallar, y el error es el resultado
# correcto. La ficha lo dice antes para que nadie lo lea como avería.
# Solo con TTY.
flag_desc() {
    case "$1" in
        --list) echo "pedir la lista de tópicos, que es la consulta más inocente que existe" ;;
        *)      flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Pedirle la lista de tópicos al listener seguro SIN presentar credenciales, para comprobar que nos rechaza'
    ficha_texto 'Es una prueba negativa. Si esto funcionara, la seguridad del clúster estaría rota.'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-topics --bootstrap-server kafka-broker-1:9092 --list'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' 'kafka-broker-1:9092' ''
    ficha_flag '--list'             ''                    ''
    ficha_texto 'Lo que importa aquí es el flag que NO está. Falta --command-config, así que el cliente se presenta sin usuario, sin clave y sin certificado.'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un error de timeout o de handshake SSL, y ningún tópico listado. Eso es aprobar, no fallar.'
    ficha_texto 'El broker no contesta "no autorizado" con detalle porque en el listener seguro ni siquiera llega a establecerse la conexión, y esa es justamente la diferencia con el caso de la ACL denegada.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor cli-client. El listener 9092 de este lab exige'
    ficha_nota 'SASL_SSL, a diferencia del PLAINTEXT de los labs anteriores.'
    echo ''
fi

echo -e "${RED}[Test no-auth] Intentando conectar SIN credenciales...${NC}"
echo -e "${YELLOW}  Esto DEBE fallar porque el listener EXTERNAL exige SASL_SSL.${NC}"
echo "─────────────────────────────────────────────────────"

# kafka-topics --list SIN --command-config
MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
    --bootstrap-server kafka-broker-1:9092 \
    --list \
    2>&1 | head -10 || true

echo "─────────────────────────────────────────────────────"
echo -e "${GREEN}[Resultado esperado] error de timeout o falla de SASL/SSL handshake.${NC}"
echo -e "${GREEN}Eso PRUEBA que SASL_SSL impide conexiones sin credenciales.${NC}"
