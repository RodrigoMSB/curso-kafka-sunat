#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
BROKER_LIST="${2:-1,2,3,4}"
THROTTLE="${3:-}"          # bytes/s. Vacio = sin throttle.

ROLLBACK_FILE="/tmp/lab08-rollback-${TOPIC}.json"

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
        --throttle)                 echo "techo de bytes/s para la copia. Si lo pones, Kafka deja limites puestos que SOLO quita el --verify final" ;;
        --verify)                   echo "pregunta cómo va. Solo cuando TODAS las particiones terminaron quita los throttles" ;;
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
    ficha_comando "kafka-reassign-partitions ... --reassignment-json-file plan.json --execute${THROTTLE:+ --throttle $THROTTLE}"
    ficha_comando "kafka-reassign-partitions ... --reassignment-json-file plan.json --verify"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server'         "$BOOTSTRAP"    ''
    ficha_flag '--topics-to-move-json-file' 'topics.json'   ''
    ficha_flag '--broker-list'              "$BROKER_LIST"  ''
    ficha_flag '--generate'                 ''              ''
    ficha_flag '--reassignment-json-file'   'plan.json'     ''
    ficha_flag '--execute'                  ''              ''
    [ -n "$THROTTLE" ] && ficha_flag '--throttle'           "$THROTTLE"     ''
    ficha_flag '--verify'                   ''              ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Del --execute, lo primero que sale es "Current partition replica assignment". Ese bloque es el PLAN DE VUELTA, y es lo unico que permite deshacer esto. Kafka lo dice: "Save this to use as the --reassignment-json-file option during rollback".'
    ficha_texto "Este script te lo guarda solo en ${ROLLBACK_FILE}. A mano, se copia y se pega antes de que la consola lo tape."
    ficha_texto '"is completed" en cada particion, y "Clearing throttles" al final, quieren decir que termino y que el cluster quedo destrabado.'
    ficha_warn 'Esto MUEVE DATOS por la red entre brokers mientras el cluster atiende. En produccion se hace fuera de hora punta y con --throttle, o la copia se come el ancho de banda de los clientes.'
    [ -n "$THROTTLE" ] && ficha_warn "Con --throttle, Kafka deja limites de replicacion puestos en los brokers y en el topico. Los quita el --verify, pero SOLO cuando todas las particiones terminaron. Un --verify corrido antes de tiempo los deja puestos."
    ficha_cerrar
    ficha_nota 'No cambia el número de particiones ni toca los mensajes. Solo cambia en qué brokers vive cada réplica.'
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-reassign-partitions está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Reasignación] ${TOPIC} → brokers ${BROKER_LIST}${THROTTLE:+ (throttle ${THROTTLE} B/s)}${NC}"

echo "{\"topics\":[{\"topic\":\"${TOPIC}\"}],\"version\":1}" > /tmp/lab08-topics-to-move.json
# El ORIGEN de un docker cp es una ruta del host, y docker.exe no entiende el
# /c/... que devuelve Git Bash: hay que darsela en formato nativo. De esto no
# se sale entrando al directorio como hace compose(), asi que va to_native_path
# (bin/common.sh). El DESTINO es ruta del contenedor y no se toca; de ese lado
# protege MSYS_NO_PATHCONV.
docker cp "$(to_native_path /tmp/lab08-topics-to-move.json)" "${BROKER}:/tmp/topics-to-move.json"

echo -e "${YELLOW}[1/3] Generando plan...${NC}"
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --topics-to-move-json-file /tmp/topics-to-move.json --broker-list "$BROKER_LIST" --generate \
    > /tmp/lab08-reassign-output.txt
sed -n '/Proposed partition reassignment configuration/,$p' /tmp/lab08-reassign-output.txt \
    | tail -n +2 | head -n 1 > /tmp/lab08-reassignment.json
docker cp "$(to_native_path /tmp/lab08-reassignment.json)" "${BROKER}:/tmp/reassignment.json"
echo -e "${YELLOW}Plan propuesto:${NC}"; cat /tmp/lab08-reassignment.json; echo ""

# El plan de vuelta sale del --generate, en el bloque "Current partition
# replica assignment". Se guarda ANTES de ejecutar: despues de que la consola
# scrollee, recuperarlo es imposible.
sed -n '/Current partition replica assignment/,$p' /tmp/lab08-reassign-output.txt \
    | tail -n +2 | grep -m1 '^{' > "$ROLLBACK_FILE"
echo -e "${GREEN}Plan de VUELTA guardado en ${ROLLBACK_FILE}${NC}"
echo -e "${CYAN}  Para deshacer: kafka-reassign-partitions ... --reassignment-json-file <ese archivo> --execute${NC}"
echo ""

echo -e "${YELLOW}[2/3] Ejecutando...${NC}"
docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
    --reassignment-json-file /tmp/reassignment.json --execute ${THROTTLE:+--throttle "$THROTTLE"}

# Un solo --verify no alcanza: mientras quede una particion "in progress",
# Kafka NO quita los throttles y devuelve 0 igual. Hay que insistir hasta que
# todas terminen, o el cluster se queda con los limites puestos.
#
# Y "no dice in progress" NO es lo mismo que "termino": Kafka tiene un tercer
# estado, "replica set is X rather than Y", que aparece cuando la reasignacion
# ya no esta activa pero el conjunto de replicas no quedo en el objetivo. Si el
# bucle solo mira "in progress", da por buena una particion que no convergio.
# Se exige la condicion positiva: TODAS "is completed".
echo -e "${YELLOW}[3/3] Verificando hasta que termine...${NC}"
NUM_PART=$(grep -o '"partition"' /tmp/lab08-reassignment.json | wc -l | tr -d ' ')
COMPLETO=0
for intento in $(seq 1 60); do
    SALIDA=$(docker exec "$BROKER" kafka-reassign-partitions --bootstrap-server "$BOOTSTRAP" \
        --reassignment-json-file /tmp/reassignment.json --verify 2>&1) || true
    OK=$(echo "$SALIDA" | grep -c "is completed" || true)
    if [ "$OK" -ge "$NUM_PART" ]; then
        COMPLETO=1
        printf "\r%-70s\r" " "
        echo "$SALIDA"
        break
    fi
    PEND=$((NUM_PART - OK))
    printf "\r  copiando... %s de %s partición(es) pendiente(s) (intento %s/60)" "$PEND" "$NUM_PART" "$intento"
    sleep 3
done

if [ "$COMPLETO" -eq 1 ]; then
    echo -e "${GREEN}✓ Reasignación completa${NC}"
    if [ -n "$THROTTLE" ]; then
        echo -e "${CYAN}  Los throttles los quitó el --verify final (mira 'Clearing ... throttles' arriba).${NC}"
    fi
else
    printf "\r%-70s\r" " "
    echo "$SALIDA"
    echo -e "${RED}✗ La reasignación NO convergió tras 60 intentos (3 min).${NC}"
    if echo "$SALIDA" | grep -q "rather than"; then
        echo -e "${RED}  Alguna partición quedó con un conjunto de réplicas distinto al del plan${NC}"
        echo -e "${RED}  ('rather than' arriba). No es un 'in progress': es que no convergió.${NC}"
    fi
    echo -e "${RED}  El clúster puede haber quedado con throttles puestos. Corre a mano:${NC}"
    echo -e "${RED}  docker exec ${BROKER} kafka-reassign-partitions --bootstrap-server ${BOOTSTRAP} \\${NC}"
    echo -e "${RED}      --reassignment-json-file /tmp/reassignment.json --verify${NC}"
    exit 1
fi
