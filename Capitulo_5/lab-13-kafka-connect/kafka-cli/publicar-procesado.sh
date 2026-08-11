#!/bin/bash
# Publica un mensaje al tópico novatech.lab09.pedidos.procesados.
# El JDBC Sink connector lo detectará y escribirá en la tabla pedidos_procesados.
#
# Nota: el JSON incluye 'schema' + 'payload' porque el Sink connector necesita
# saber el tipo de cada campo para mapearlo a columnas SQL. Esto es el formato
# estándar de Kafka Connect cuando se usa JsonConverter con schemas.enable=true.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

PEDIDO_ID="${1:?Uso: $0 <pedido_id>}"
TOPIC="novatech.lab09.pedidos.procesados"

MENSAJE=$(cat <<EOF
{"schema":{"type":"struct","fields":[{"field":"id","type":"int32","optional":false},{"field":"cliente_id","type":"int32","optional":true},{"field":"producto","type":"string","optional":true},{"field":"cantidad","type":"int32","optional":true},{"field":"monto","type":"double","optional":true},{"field":"estado","type":"string","optional":true}],"optional":false},"payload":{"id":${PEDIDO_ID},"cliente_id":1001,"producto":"Pedido procesado en $(date +%H:%M:%S)","cantidad":1,"monto":99999.99,"estado":"procesado"}}
EOF
)

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic) echo "a qué tópico se escribe. De aquí lo lee el connector Sink para bajarlo a SQL" ;;
        *)       flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Publicar un evento en ${TOPIC} para que el connector JDBC Sink lo baje solo a la tabla pedidos_procesados. Es el camino inverso al del Source."
    ficha_medio 'COMANDO REAL'
    ficha_comando 'echo "$MENSAJE" | kafka-console-producer \'
    ficha_comando "    --bootstrap-server $BOOTSTRAP --topic $TOPIC"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--topic'            "$TOPIC"     ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'El productor no imprime nada cuando le va bien.'
    ficha_texto 'Lo que hay que mirar es el mensaje que mandamos, que lleva dos partes. En "schema" va el tipo de cada campo y en "payload" los valores. El Sink necesita el schema para saber a qué columna SQL y de qué tipo va cada dato, y por eso el JSON se ve tan largo para tan pocos valores.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-console-producer está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Publicar Procesado] -> ${TOPIC}${NC}"
echo "  Pedido ID: ${PEDIDO_ID}"
echo ""

echo "$MENSAJE" | docker exec -i "$BROKER" kafka-console-producer \
  --bootstrap-server "$BOOTSTRAP" \
  --topic "$TOPIC"

echo -e "${GREEN}  ✓ Mensaje publicado${NC}"
echo ""
echo -e "${YELLOW}En ~5 segundos verifica con:${NC}"
echo -e "  ${GREEN}kafka-cli/verificar-tabla-procesados.sh${NC}"