#!/bin/bash
# ============================================================
# NovaTech Logistics - Biblioteca compartida
# Funciones y variables comunes a todos los scripts del lab.
# Se importa con:
#   source "$(dirname "$0")/common.sh"           # desde bin/
#   source "$(dirname "$0")/../bin/common.sh"    # desde kafka-cli/
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

# ── Invocar docker compose sin pasarle rutas absolutas ──
# En Git Bash, `pwd` devuelve /c/KAFKA/... y ese formato NO le sirve a
# docker.exe, que es un binario de Windows: lo resuelve contra la raiz del
# disco y produce C:\c\KAFKA\..., una ruta que no existe. El sintoma medido
# en la VM de Netec, al arrancar este lab, fue:
#
#   open C:\c\KAFKA\curso-kafka-sunat\...\infra\docker-compose.yml:
#   The system cannot find the path specified.
#
# Es el mismo defecto que la SPEC-75 arreglo en los labs 08 a 14; alli se
# manifestaba en el --env-file y aqui en el -f, porque compose valida el
# --env-file primero y estos labs no le pasaban ninguno.
#
# Ojo, porque son DOS problemas opuestos y este archivo necesita los dos:
# MSYS_NO_PATHCONV=1 (arriba) protege las rutas que deben llegar intactas AL
# CONTENEDOR, como /var/lib/kafka/data. Aqui el problema es al reves -- una
# ruta del HOST que docker.exe tiene que entender -- y esa misma variable lo
# empeora, porque impide la traduccion.
#
# La solucion es no darle ninguna ruta: se entra al directorio y se usan
# nombres relativos. El `cd` es un builtin de bash, asi que la ruta absoluta
# se resuelve dentro del shell y nunca cruza a docker.exe. El subshell
# mantiene el cambio de directorio local a esta funcion.
#
# El -f se va: dentro de infra/, compose encuentra su docker-compose.yml solo.
# El -p pasa a ser explicito: hoy el nombre del proyecto sale del .env y las
# dos formas resuelven igual, pero el alcance de un `down -v` lo da el
# proyecto y eso no se deja implicito (tests/CONVENCIONES-TEST.md).
DIR_INFRA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra" && pwd)"
PROYECTO="$(grep '^COMPOSE_PROJECT_NAME=' "$DIR_INFRA/.env" 2>/dev/null | cut -d= -f2 | tr -d ' \r')"
compose() {  # <subcomando de docker compose>...
    ( cd "$DIR_INFRA" && docker compose --env-file .env -p "$PROYECTO" "$@" )
}

# ── Detectar un broker disponible ──
# Recorre los brokers del 1 al 3 y devuelve el nombre del primero
# que está corriendo. Si ninguno está vivo, retorna 1.
find_alive_broker() {
    for i in 1 2 3; do
        if docker ps --filter "name=kafka-broker-${i}" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "kafka-broker-${i}"; then
            echo "kafka-broker-${i}"
            return 0
        fi
    done
    echo ""
    return 1
}

# ── Resolver broker y bootstrap-server ──
# Fija las variables BROKER y BOOTSTRAP en el script que importa.
# Aborta con código 1 si no hay brokers corriendo.
resolve_broker() {
    BROKER=$(find_alive_broker)
    if [ -z "$BROKER" ]; then
        echo -e "${RED}[ERROR] No hay brokers disponibles. ¿Ejecutaste bin/start-lab.sh?${NC}" >&2
        exit 1
    fi
    local BROKER_NUM="${BROKER##*-}"
    # Puertos PLAINTEXT: broker-1 -> 29092, broker-2 -> 29093, broker-3 -> 29094
    BOOTSTRAP="${BROKER}:$(( 29091 + BROKER_NUM ))"
    export BROKER BOOTSTRAP
}

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

# ── Motor de ficha didáctica ──
# Se importa si está presente. El `if` es a propósito: si el lab viaja
# suelto sin ficha.sh, los wrappers viejos siguen funcionando igual.
FICHA_LIB="$(dirname "${BASH_SOURCE[0]}")/ficha.sh"
if [ -f "$FICHA_LIB" ]; then
    source "$FICHA_LIB"
fi
