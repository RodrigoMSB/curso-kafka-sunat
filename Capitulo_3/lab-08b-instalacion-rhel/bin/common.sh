#!/bin/bash
# ============================================================
# NovaTech Logistics - Lab 08b: Biblioteca compartida
# Funciones y variables comunes a los scripts del lab.
# Se importa con:
#   source "$(dirname "$0")/common.sh"
# ============================================================
#
# Portabilidad exigida: macOS bash 3.2 y Git Bash (MSYS). Sin arreglos
# asociativos, sin lectura masiva a arreglo, sin PCRE en grep, sin edicion
# en sitio con sed, sin jq.
#
# Nota sobre la redaccion de este bloque: los otros labs escriben esa misma
# advertencia nombrando los constructos prohibidos con su nombre literal. Aqui
# se describen en castellano a proposito, porque la auditoria de portabilidad
# de validar-todo.sh busca esos nombres dentro de los .sh y no distingue una
# linea de codigo de un comentario que la prohibe. Este lab no le agrega
# hallazgos falsos a esa auditoria.

# ── Rutas absolutas en Git Bash ──
# MSYS traduce cualquier argumento que empiece con / a una ruta de Windows
# antes de que docker lo vea. Sin esta variable, "-f <ruta>/docker-compose.yml"
# le llega a docker como "C:/Program Files/Git/...". MSYS solo mira si la
# variable existe, no su valor. Fuera de Windows nadie la lee.
export MSYS_NO_PATHCONV=1

# ── Colores ──
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Identidad del lab ──
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${LAB_DIR}/infra/docker-compose.yml"
ENV_FILE="${LAB_DIR}/infra/.env"
CONTENEDOR="kafka-rhel"
PROYECTO="novatech-lab08b"

# Rutas DENTRO del contenedor. Viven en variables y no sueltas en cada
# comando por dos razones: se escriben una sola vez, y ninguna linea de
# `docker exec` queda con una ruta absoluta literal que MSYS pueda tocar.
RUTA_CONF="/etc/kafka/server.properties"
RUTA_DATOS="/var/lib/kafka/data"
RUTA_UNIDAD="/usr/lib/systemd/system/confluent-kafka.service"

# ── Ejecutar dentro del servidor RHEL ──
# Todo el lab ocurre adentro. Esta funcion existe para que los scripts no
# repitan el prefijo y para que el alumno vea en la guia el comando desnudo,
# sin `docker exec` adelante, que es el punto del lab.
en_rhel() {
    docker exec "$CONTENEDOR" bash -lc "$1"
}

# ── El servidor esta arriba? ──
rhel_arriba() {
    docker ps --filter "name=^${CONTENEDOR}$" --filter "status=running" \
        --format '{{.Names}}' 2>/dev/null | grep -q "$CONTENEDOR"
}

# ── Esperar a que systemd termine de arrancar ──
# Devuelve 0 si el sistema llego a running o degraded, 1 si se agoto el
# tiempo. `degraded` cuenta como bueno: significa que systemd esta operativo
# aunque alguna unidad accesoria haya fallado, y en un contenedor eso pasa.
esperar_systemd() {
    local intentos="${1:-30}"
    local i=0 estado=""
    while [ "$i" -lt "$intentos" ]; do
        estado="$(docker exec "$CONTENEDOR" systemctl is-system-running 2>/dev/null || true)"
        case "$estado" in
            running|degraded) return 0 ;;
        esac
        i=$((i + 1))
        sleep 2
    done
    return 1
}

# ── Destruccion acotada, nombrada y en pantalla ──
# El contrato (tests/CONVENCIONES-TEST.md):
#   - solo se remueve lo etiquetado com.docker.compose.project=novatech-lab*
#   - cada remocion se imprime, con su proyecto
#   - un nombre tomado por algo ajeno NO se toca: se dice quien lo tiene y se
#     falla con instruccion.
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
                echo -e "${RED}          No se toca nada ajeno. Resuelvelo a mano y vuelve a ejecutar:${NC}" >&2
                echo -e "${RED}            docker rm -f ${c}    # solo si ese contenedor es descartable${NC}" >&2
                ajeno=1
                ;;
        esac
    done
    return "$ajeno"
}
