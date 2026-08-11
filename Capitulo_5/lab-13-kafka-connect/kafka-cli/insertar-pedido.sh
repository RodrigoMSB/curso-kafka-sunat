#!/bin/bash
# Inserta un pedido nuevo en PostgreSQL.
# El JDBC Source connector detectará el cambio en ~5 segundos
# y publicará el evento al tópico novatech.lab09.pedidos.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

CLIENTE="${1:-2001}"
PRODUCTO="${2:-Producto demo $(date +%s)}"
CANTIDAD="${3:-10}"
MONTO="${4:-15000.00}"

# ── Ficha didáctica ──────────────────────────────────────────
# Este wrapper no habla con Kafka: escribe en PostgreSQL y deja que el
# connector haga el resto. El protagonista es psql. Solo con TTY.
flag_desc() {
    case "$1" in
        -U) echo "con qué usuario entra a PostgreSQL" ;;
        -d) echo "a qué base de datos" ;;
        -c) echo "la sentencia SQL que ejecuta, y sale. Sin esto, psql abriría una sesión interactiva" ;;
        *)  echo "" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Insertar una fila en la tabla pedidos de PostgreSQL. Nada más. A Kafka no lo tocamos, y ahí está la gracia del lab.'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'psql -U novatech -d novatech_orders -c \'
    ficha_comando "  \"INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado)"
    ficha_comando "   VALUES (${CLIENTE}, '${PRODUCTO}', ${CANTIDAD}, ${MONTO}, 'pendiente') RETURNING id;\""
    ficha_medio 'DESGLOSE'
    ficha_flag '-U' 'novatech'        ''
    ficha_flag '-d' 'novatech_orders' ''
    ficha_flag '-c' 'INSERT ...'      '-c'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El "id" que devuelve RETURNING es el de la fila nueva, e "INSERT 0 1" quiere decir que se insertó una.'
    ficha_texto 'Lo interesante pasa después y sin que tú hagas nada, porque el connector JDBC Source consulta la tabla cada pocos segundos y publica esa fila como evento.'
    ficha_cerrar
    ficha_nota 'En el lab corre dentro del contenedor con docker exec postgres'
    ficha_nota 'En tu servidor, psql apunta al host de la base con -h y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Insertar Pedido] Insertando pedido en PostgreSQL...${NC}"
docker exec postgres psql -U novatech -d novatech_orders -c \
  "INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado) VALUES (${CLIENTE}, '${PRODUCTO}', ${CANTIDAD}, ${MONTO}, 'pendiente') RETURNING id;"

echo ""
echo -e "${YELLOW}En ~5 segundos, el Source connector lo capturará y publicará a:${NC}"
echo -e "  ${CYAN}novatech.lab09.pedidos${NC}"
echo ""
echo -e "Verifica con: ${GREEN}kafka-cli/consume-pedidos.sh${NC}"
