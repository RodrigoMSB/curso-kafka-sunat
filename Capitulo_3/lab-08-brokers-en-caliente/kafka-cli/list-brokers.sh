#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
# ── Ficha didáctica ──────────────────────────────────────────
# Este wrapper corre DOS comandos distintos, así que la ficha muestra los dos.
# Solo con TTY.
flag_desc() {
    case "$1" in
        describe) echo "solo consulta, no toca nada" ;;
        --status) echo "el resumen del quórum, quién manda y desde cuándo" ;;
        *)        flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Ver qué brokers responden hoy en el clúster y cómo está el quórum que los coordina. Son dos preguntas distintas y por eso van dos comandos.'
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-broker-api-versions --bootstrap-server $BOOTSTRAP | grep ..."
    ficha_comando "kafka-metadata-quorum --bootstrap-server $BOOTSTRAP describe --status"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag 'describe'           ''           'describe'
    ficha_flag '--status'           ''           ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Arriba, un host:puerto por broker que contestó. Esa lista sale filtrada con grep de una salida mucho más larga, porque api-versions imprime además todas las APIs que soporta cada uno.'
    ficha_campo 'LeaderId'      'qué nodo manda el quórum ahora mismo'
    ficha_campo 'HighWatermark' 'hasta dónde está confirmada la metadata por la mayoría'
    ficha_campo 'MaxFollowerLag' 'cuánto le falta al nodo más atrasado. Debe ser bajo'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, los dos comandos están en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Brokers registrados en el clúster]${NC}"
docker exec "$BROKER" kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP" 2>/dev/null \
    | grep -oE '^[a-z0-9.-]+:[0-9]+' | sort -u
echo ""
echo -e "${CYAN}[Metadata del clúster]${NC}"
docker exec "$BROKER" kafka-metadata-quorum --bootstrap-server "$BOOTSTRAP" describe --status 2>/dev/null || true
