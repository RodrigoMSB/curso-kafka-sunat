#!/bin/bash
# ============================================================
# NovaTech Logistics - Lab 01 - Biblioteca compartida
# ============================================================

# ── Rutas absolutas en Git Bash ──
# MSYS traduce cualquier argumento que empiece con / a una ruta de Windows
# antes de que docker lo vea, y "/var/lib/kafka/data" le llega al contenedor
# como "C:/Program Files/Git/var/lib/kafka/data". El comando falla, el
# wrapper se cae a su camino alternativo y termina afirmando que el
# almacenamiento no está formateado cuando sí lo está. MSYS solo mira si la
# variable existe, no su valor. Fuera de Windows nadie la lee.
export MSYS_NO_PATHCONV=1

# ── Colores ──
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Detectar un broker vivo (cualquier nombre) ──
# Busca contenedores que usen la imagen cp-kafka y estén corriendo.
# Devuelve el nombre del primero. Si no hay ninguno, retorna 1.
find_alive_kafka_container() {
    local CONTAINER
    CONTAINER=$(docker ps \
        --filter "ancestor=confluentinc/cp-kafka:8.2.0" \
        --filter "status=running" \
        --format "{{.Names}}" 2>/dev/null | head -1)
    if [ -n "$CONTAINER" ]; then
        echo "$CONTAINER"
        return 0
    fi
    echo ""
    return 1
}

# ── Resolver broker y bootstrap-server ──
# Fija las variables BROKER y BOOTSTRAP en el script que importa.
# Calcula el puerto PLAINTEXT correcto según el sufijo numérico del broker.
# Convención del lab: broker-N escucha PLAINTEXT en el puerto (29091 + N)
#   broker-1 -> 29092, broker-2 -> 29093, broker-3 -> 29094
# Aborta con código 1 si no hay brokers corriendo.
resolve_kafka_broker() {
    BROKER=$(find_alive_kafka_container)
    if [ -z "$BROKER" ]; then
        echo -e "${RED}[ERROR] No se encontró ningún contenedor Kafka corriendo.${NC}" >&2
        echo -e "${RED}  ¿Levantaste tu clúster con 'docker compose up -d' desde mi-cluster/?${NC}" >&2
        exit 1
    fi

    # Si el nombre termina en un número (ej: kafka-broker-2), calcular puerto
    if [[ "$BROKER" =~ -([0-9]+)$ ]]; then
        local BROKER_NUM="${BASH_REMATCH[1]}"
        BOOTSTRAP="${BROKER}:$(( 29091 + BROKER_NUM ))"
    else
        # Broker solitario (ej: kafka-broker sin sufijo numérico)
        BOOTSTRAP="${BROKER}:29092"
    fi

    export BROKER BOOTSTRAP
}

# ── Motor de ficha didáctica ──
# Se importa si está presente. El `if` es a propósito: si el lab viaja
# suelto sin ficha.sh, los wrappers viejos siguen funcionando igual.
FICHA_LIB="$(dirname "${BASH_SOURCE[0]}")/ficha.sh"
if [ -f "$FICHA_LIB" ]; then
    source "$FICHA_LIB"
fi

# ── Destruccion nombrada, en pantalla, y solo de lo del curso ─
# Los composes fijan container_name (deuda declarada), asi que dos labs no
# conviven: al cambiar de lab, el nombre choca con "Conflict: container name
# already in use". Antes esto se resolvia con un `docker rm -f` a ciegas sobre
# una lista literal. En la VM del alumno daba igual; en la maquina del
# instructor esos nombres pueden ser de otro proyecto.
#
# El contrato (tests/CONVENCIONES-TEST.md):
#   - solo se remueve lo etiquetado com.docker.compose.project=novatech-lab*
#   - cada remocion se imprime, con su proyecto
#   - un nombre tomado por algo ajeno NO se toca: se dice quien lo tiene y se
#     falla con instruccion. Un conflicto con algo de afuera se resuelve a mano.
# Devuelve 1 si encontro un duenio ajeno.
# Proyecto compose de este lab. Fuente unica: aqui.
# Los labs 05-14 lo leen de infra/.env; estos cuatro no tienen
# COMPOSE_PROJECT_NAME ahi, asi que va declarado.
PROYECTO="novatech-lab01"

botar_contenedores_del_curso() {  # <etiqueta> <proyecto_propio>
    # Encuentra por ETIQUETA de proyecto compose, no por lista de nombres.
    #
    # Por que (SPEC-80): una lista cableada solo cubre los contenedores que
    # ESE lab conoce, y se le escapan los que dejo cualquier otro. Eso rompia
    # cinco cadenas de labs encadenados -- 01->05, 07->08, 08->05, 11->12 y
    # 12->14 --. La etiqueta las cierra todas de una vez.
    #
    # Solo toca contenedores cuyo proyecto empieza por 'novatech-lab' y que NO
    # sean el del lab que esta arrancando: lo propio lo maneja el 'compose
    # down' del propio script. Nada ajeno al curso se toca ni se nombra.
    # Los volumenes NO se tocan: se botan contenedores y nada mas.
    local quien="$1" propio="$2"
    local id duenio nombre n=0 lista
    local red redes r=0

    if [ -z "$propio" ]; then
        echo -e "${RED}[${quien}] no recibi el proyecto propio.${NC}" >&2
        echo -e "${RED}          Sin el no puedo excluirme a mi mismo, asi que no toco nada.${NC}" >&2
        return 1
    fi

    # El --filter de docker compara por igualdad exacta, asi que solo puede
    # pedir "que tenga la etiqueta". El prefijo se comprueba abajo, en el case.
    lista=$(docker ps -a --filter "label=com.docker.compose.project" \
            --format "{{.ID}} {{.Label \"com.docker.compose.project\"}} {{.Names}}" 2>/dev/null)

    # while + here-doc, y no 'for x in $(...)': bajo zsh el for NO divide
    # palabras y barreria un solo elemento. Sin tuberia, ademas, para que el
    # contador sobreviva (bash 3.2 no tiene lastpipe).
    while read -r id duenio nombre; do
        [ -z "$id" ] && continue
        case "$duenio" in
            novatech-lab*) ;;
            *) continue ;;
        esac
        [ "$duenio" = "$propio" ] && continue
        echo -e "${YELLOW}[${quien}] botando ${nombre} (proyecto ${duenio})${NC}"
        docker rm -f "$id" >/dev/null 2>&1 || true
        n=$((n+1))
    done <<EOF
$lista
EOF

    if [ "$n" -gt 0 ]; then
        echo -e "${YELLOW}[${quien}] ${n} contenedor(es) de otros labs del curso eliminados.${NC}"
        echo -e "${YELLOW}          Sus volumenes NO se tocaron.${NC}"
    fi

    # Y las redes que quedaron sin nadie conectado. Botar solo contenedores
    # las deja acumularse: diez labs encadenados agotan los pools de
    # direcciones de Docker y el siguiente ya no puede crear la suya, con un
    # "all predefined address pools have been fully subnetted" que no dice
    # nada del lab. Solo se tocan las VACIAS, asi que nunca se desconecta
    # nada de nadie, y los volumenes siguen sin tocarse.
    #
    # Ojo: 'docker network ls --filter name=' compara por SUBCADENA, no por
    # prefijo -- medido: con name=novatech-lab devuelve tambien una red
    # llamada spec80-novatech-lab99-red, que no es del curso. Por eso el
    # prefijo se ancla aqui abajo, en el case, igual que con los contenedores.
    redes=$(docker network ls --format "{{.Name}}" 2>/dev/null)
    while read -r red; do
        [ -z "$red" ] && continue
        case "$red" in novatech-lab*) ;; *) continue ;; esac
        case "$red" in ${propio}*) continue ;; esac
        [ "$(docker network inspect "$red" --format '{{len .Containers}}' 2>/dev/null)" = "0" ] || continue
        if docker network rm "$red" >/dev/null 2>&1; then
            echo -e "${YELLOW}[${quien}] red huerfana ${red} eliminada${NC}"
            r=$((r+1))
        fi
    done <<EOF
$redes
EOF

    [ "$r" -gt 0 ] && echo -e "${YELLOW}[${quien}] ${r} red(es) vacia(s) de otros labs eliminadas.${NC}"
    return 0
}
