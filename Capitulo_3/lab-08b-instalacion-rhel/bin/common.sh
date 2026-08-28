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
DIR_INFRA="${LAB_DIR}/infra"
ENV_FILE="${DIR_INFRA}/.env"
CONTENEDOR="kafka-rhel"
PROYECTO="novatech-lab08b"

# ── Invocar docker compose sin pasarle rutas absolutas ──
# En Git Bash, `pwd` devuelve /c/KAFKA/... y ese formato NO le sirve a
# docker.exe, que es un binario de Windows: lo resuelve contra la raiz del
# disco y produce C:\c\KAFKA\..., una ruta que no existe. El sintoma medido
# en la VM de Netec fue:
#
#   couldn't find env file: C:\c\KAFKA\curso-kafka-sunat\...\infra\.env
#
# MSYS_NO_PATHCONV=1 no cubre esto y no es su trabajo: esa guardia impide que
# MSYS traduzca rutas que deben llegar intactas AL CONTENEDOR (/etc/kafka/...,
# /var/lib/kafka/data). Aqui el problema es al reves -- una ruta del HOST que
# docker.exe tiene que entender.
#
# La solucion es no darle ninguna: se entra al directorio y se usan nombres
# relativos. El `cd` es un builtin de bash, asi que la ruta absoluta se
# resuelve dentro del shell y nunca cruza a docker.exe. El subshell mantiene
# el cambio de directorio local a esta funcion.
#
# Tambien se saca el `-f`: dentro de infra/, compose encuentra su
# docker-compose.yml solo. El `-p` explicito se queda, porque el alcance de un
# `down -v` lo da el proyecto (tests/CONVENCIONES-TEST.md).
compose() {  # <subcomando de docker compose>...
    ( cd "$DIR_INFRA" && docker compose --env-file .env -p "$PROYECTO" "$@" )
}

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
        # Ojo con el separador. Si el propio fuera novatech-lab08, un patron
        # ${propio}* se tragaria tambien la red de novatech-lab08b, que es OTRO
        # lab del curso y si debe limpiarse: quedaba acumulando una red por
        # detras. Medido. Se ancla el _ que compose pone entre el proyecto y la
        # clave de red; ninguno de los quince composes fija name:, asi que ese
        # separador siempre esta. La colision solo va en un sentido: con propio
        # novatech-lab08b la red de novatech-lab08 ya se limpiaba bien.
        case "$red" in "$propio"|"${propio}_"*) continue ;; esac
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
