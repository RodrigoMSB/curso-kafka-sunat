#!/bin/bash
# Consulta la tabla pedidos_procesados en PostgreSQL para ver
# los registros que el JDBC Sink connector escribió.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

# ── Ficha didáctica ──────────────────────────────────────────
# Este wrapper no habla con Kafka: consulta PostgreSQL para comprobar lo que
# el connector Sink dejó ahí. El protagonista es psql. Solo con TTY.
flag_desc() {
    case "$1" in
        -U) echo "con qué usuario entra a PostgreSQL" ;;
        -d) echo "a qué base de datos" ;;
        -c) echo "la consulta que ejecuta, y sale" ;;
        *)  echo "" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Mirar la tabla pedidos_procesados para comprobar que el connector Sink escribió ahí lo que publicamos en Kafka, sin que nadie corriera un INSERT.'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'psql -U novatech -d novatech_orders -c \'
    ficha_comando '  "SELECT id, cliente_id, producto, estado, procesado_en'
    ficha_comando '   FROM pedidos_procesados ORDER BY procesado_en DESC LIMIT 10;"'
    ficha_medio 'DESGLOSE'
    ficha_flag '-U' 'novatech'        ''
    ficha_flag '-d' 'novatech_orders' ''
    ficha_flag '-c' 'SELECT ...'      '-c'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una tabla de psql, y al pie el número de filas. Si dice "(0 rows)", el Sink todavía no escribió, y lo normal es que tarde unos segundos.'
    ficha_texto 'La columna procesado_en la pone la base con su reloj, no el mensaje, así que sirve para ver cuánto tardó el viaje desde Kafka.'
    ficha_cerrar
    ficha_nota 'En el lab corre dentro del contenedor con docker exec postgres'
    ficha_nota 'En tu servidor, psql apunta al host de la base con -h y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Verificar Tabla] pedidos_procesados${NC}"
echo "────────────────────────────────────────────────────────"

docker exec postgres psql -U novatech -d novatech_orders -c \
  "SELECT id, cliente_id, producto, estado, procesado_en FROM pedidos_procesados ORDER BY procesado_en DESC LIMIT 10;"
