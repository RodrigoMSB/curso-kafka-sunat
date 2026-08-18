#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
BROKER_LIST="${2:-1,2,3,4}"

# ── Ficha didáctica ──────────────────────────────────────────
# El comando más peligroso del curso. La ficha va antes de la primera fase.
# Solo con TTY.
flag_desc() {
    case "$1" in
        --topics-to-move-json-file) echo "el archivo que dice qué tópicos entran al plan" ;;
        --broker-list)              echo "los brokers entre los que se reparten las réplicas. Los que NO estén aquí quedan fuera" ;;
        --generate)                 echo "solo propone un plan y lo imprime. No mueve nada todavía" ;;
        --reassignment-json-file)   echo "el plan que se va a aplicar" ;;
        --execute)                  echo "lanza el movimiento de verdad. A partir de aquí se copian datos entre brokers" ;;
        --verify)                   echo "pregunta cómo va, y al terminar QUITA los throttles que Kafka puso durante la copia" ;;
        *)                          flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Repartir las réplicas de ${TOPIC} entre los brokers ${BROKER_LIST}, copiando datos de un broker a otro con el clúster en marcha"
    ficha_medio 'COMANDO REAL · TRES FASES'
    ficha_comando "kafka-reassign-partitions --bootstrap-server $BOOTSTRAP \\"
    ficha_comando "    --topics-to-move-json-file topics.json --broker-list $BROKER_LIST --generate"
    ficha_comando "kafka-reassign-partitions ... --reassignment-json-file plan.json --execute"
    ficha_comando "kafka-reassign-partitions ... --reassignment-json-file plan.json --verify"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server'         "$BOOTSTRAP"    ''
    ficha_flag '--topics-to-move-json-file' 'topics.json'   ''
    ficha_flag '--broker-list'              "$BROKER_LIST"  ''
    ficha_flag '--generate'                 ''              ''
    ficha_flag '--reassignment-json-file'   'plan.json'     ''
    ficha_flag '--execute'                  ''              ''
    ficha_flag '--verify'                   ''              ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Del --execute, guarda el bloque "Current partition replica assignment". Es el plan de vuelta, y es lo único que te permite deshacer esto.'
    ficha_texto '"is completed" en cada partición y "Clearing throttles" al final quieren decir que terminó y que el clúster quedó destrabado.'
    ficha_warn 'Esto MUEVE DATOS por la red entre brokers mientras el clúster atiende. En producción se hace fuera de hora punta y con throttle puesto a mano, o la copia se come el ancho de banda de los clientes.'
    ficha_cerrar
    ficha_nota 'No cambia el número de particiones ni toca los mensajes. Solo cambia en qué brokers vive cada réplica.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-reassign-partitions está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Reasignación] ${TOPIC} → brokers ${BROKER_LIST}${NC}"

echo "{\"topics\":[{\"topic\":\"${TOPIC}\"}],\"version\":1}" > /tmp/lab08-topics-to-move.json
# El ORIGEN de un docker cp es una ruta del host, y docker.exe no entiende el
# /c/... que devuelve Git Bash: hay que darsela en formato nativo. De esto no
# se sale entrando al directorio como hace compose(), asi que va to_native_path
# (bin/common.sh). El DESTINO es ruta del contenedor y no se toca; de ese lado
# protege MSYS_NO_PATHCONV.
docker cp "$(to_native_path /tmp/lab08-topics-to-move.json)" "${BROKER}:/tmp/topics-to-move.json"

echo -e "${YELLOW}Generando plan...${NC}"
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --topics-to-move-json-file /tmp/topics-to-move.json --broker-list "$BROKER_LIST" --generate \
    > /tmp/lab08-reassign-output.txt
sed -n '/Proposed partition reassignment configuration/,$p' /tmp/lab08-reassign-output.txt \
    | tail -n +2 | head -n 1 > /tmp/lab08-reassignment.json
docker cp "$(to_native_path /tmp/lab08-reassignment.json)" "${BROKER}:/tmp/reassignment.json"
echo -e "${YELLOW}Plan propuesto:${NC}"; cat /tmp/lab08-reassignment.json; echo ""

echo -e "${YELLOW}Ejecutando...${NC}"
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --reassignment-json-file /tmp/reassignment.json --execute

echo -e "${YELLOW}Verificando (espera unos segundos)...${NC}"; sleep 5
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --reassignment-json-file /tmp/reassignment.json --verify || true
echo -e "${GREEN}✓ Reasignación lanzada${NC}"
