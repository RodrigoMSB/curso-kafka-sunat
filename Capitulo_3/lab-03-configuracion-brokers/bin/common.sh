#!/bin/bash
# ============================================================
# NovaTech Logistics - Lab 03 - Biblioteca compartida
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
botar_contenedores_del_curso() {  # <etiqueta> <contenedor>...
    local quien="$1"; shift
    local c existe duenio ajeno=0
    for c in "$@"; do
        existe=$(docker ps -a --filter "name=^${c}$" --format "{{.Names}}" 2>/dev/null | head -1)
        [ -z "$existe" ] && continue
        duenio=$(docker inspect "$c" --format "{{index .Config.Labels \"com.docker.compose.project\"}}" 2>/dev/null || true)
        case "$duenio" in
            novatech-lab*)
                echo -e "${YELLOW}[${quien}] botando ${c} (proyecto ${duenio})${NC}"
                docker rm -f "$c" >/dev/null 2>&1 || true
                ;;
            *)
                echo -e "${RED}[${quien}] el nombre '${c}' lo tiene un contenedor que NO es del curso.${NC}" >&2
                echo -e "${RED}          proyecto compose: ${duenio:-<sin etiqueta>}${NC}" >&2
                echo -e "${RED}          No se toca nada ajeno. Resolvelo a mano y volve a ejecutar:${NC}" >&2
                echo -e "${RED}            docker rm -f ${c}    # solo si ese contenedor es descartable${NC}" >&2
                ajeno=1
                ;;
        esac
    done
    return "$ajeno"
}
