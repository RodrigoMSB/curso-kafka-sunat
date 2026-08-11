#!/bin/bash
# Consume mensajes del tópico novatech.lab09.pedidos
# (creado automáticamente por el JDBC Source connector).

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

TOPIC="novatech.lab09.pedidos"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)          echo "de qué tópico se lee. Este no lo creaste tú, lo creó el connector" ;;
        --from-beginning) echo "empieza por el mensaje más viejo, para ver también lo que el connector publicó antes de que llegaras" ;;
        print.key)        echo "en false, no muestra la clave" ;;
        print.value)      echo "en true, muestra el cuerpo del mensaje" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Leer ${TOPIC}, que es donde el connector JDBC Source va dejando cada fila nueva de la tabla de PostgreSQL convertida en un evento"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-console-consumer --bootstrap-server $BOOTSTRAP \\"
    ficha_comando "    --topic $TOPIC --from-beginning \\"
    ficha_comando '    --property print.key=false --property print.value=true'
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--topic'            "$TOPIC"     ''
    ficha_flag '--from-beginning'   ''           ''
    ficha_flag '--property' 'print.key=false'   'print.key'
    ficha_flag '--property' 'print.value=true'  'print.value'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un JSON por línea, uno por fila de la tabla. Sus campos son las columnas.'
    ficha_texto 'Si un importe aparece como texto raro tipo "ExLQ", no está corrupto. Es una columna NUMERIC de SQL, que el connector manda como bytes en base64 porque JSON no tiene decimal exacto.'
    ficha_cerrar
    ficha_nota_warn 'Kafka 8.x avisa que --property está deprecado. Al consumir, el reemplazo es'
    ficha_nota '--formatter-property; al producir es --reader-property.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-console-consumer está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Consume Pedidos] Tópico: ${TOPIC}${NC}"
echo "  Presiona Ctrl+C para detener"
echo "────────────────────────────────────────────────────────"

# -i, no -it. Con -t docker exige un TTY en la ENTRADA y el comando muere con
# "the input device is not a TTY" en cuanto alguien lo tuberea, lo redirige a un
# archivo o lo captura con $( ) -- que es justo lo que hacen las guías y los e2e.
# El lab 11 ya usaba -i para el mismo comando; esto los deja iguales.
docker exec -i "$BROKER" kafka-console-consumer \
  --bootstrap-server "$BOOTSTRAP" \
  --topic "$TOPIC" \
  --from-beginning \
  --property print.key=false \
  --property print.value=true
