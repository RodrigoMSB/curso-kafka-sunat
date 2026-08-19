#!/bin/bash
# ============================================================
# show-network.sh · ficha didáctica sobre la red del clúster
# ============================================================
# Familia LEE. Averigua en qué red de Docker vive el clúster. Docker Compose
# le antepone el nombre del proyecto, así que la red NO tiene nombre fijo y
# hay que preguntársela al contenedor. Sin ese dato no se puede lanzar un
# cliente "desde adentro", que es lo que hace falta para ver el fallo clásico
# de advertised.listeners.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale solo el nombre de
# la red, para que la guía pueda hacer RED=$(kafka-cli/show-network.sh).
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

FORMATO='{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}'
FORMATO_IP='{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{$v.IPAddress}}{{end}}'

flag_desc() {
    case "$1" in
        --format)         echo "le pide a docker solo el dato que queremos, en vez de un JSON entero" ;;
        "docker inspect")  echo "abre la ficha técnica del contenedor, que Docker mantiene por dentro" ;;
        *)        flag_desc_comun "$1" ;;
    esac
}

ficha_encabezado() {
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Preguntarle a ${BROKER} en qué red de Docker vive, porque el nombre no es fijo: Compose le antepone el del proyecto"

    ficha_medio 'COMANDO REAL'
    ficha_comando "docker inspect ${BROKER} \\"
    ficha_comando "    --format '$FORMATO'"

    ficha_medio 'DESGLOSE'
    ficha_flag 'docker inspect' "$BROKER" 'docker inspect'
    ficha_flag '--format' '{{range ...}}{{$k}}{{end}}' '--format'

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'nombre de la red' 'el prefijo es el nombre del proyecto compose, y el resto el que le pusiste en el yml'
    ficha_campo 'IPAddress' 'la dirección del broker DENTRO de esa red. Los de afuera no la alcanzan'

    ficha_cerrar
    ficha_nota 'Dentro de esa red los contenedores se llaman por su nombre; desde tu máquina, no.'
    echo ''
}

diagnostico() {
    local red="$1" detalle="$2" cuantos

    cuantos=$(docker ps --filter "network=$red" --format '{{.Names}}' 2>/dev/null | grep -c . || true)

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "El clúster vive en la red ${red}, y ahora mismo hay ${cuantos} contenedores conectados a ella."
    ficha_vacia
    ficha_texto 'Para qué sirve saberlo: para lanzar un cliente DENTRO de esa red y comprobar qué dirección le sirve y cuál no.'
    ficha_texto 'Un cliente de la red resuelve kafka-broker-1 por su nombre. Tu máquina no: para ella ese nombre no existe, y por eso el EXTERNAL publica localhost.'
    ficha_vacia
    ficha_texto 'Ese es el experimento que sigue: el mismo broker, dos puertos, un cliente adentro. Uno de los dos falla.'
    ficha_causa '  Probar desde adentro' 'kafka-cli/test-connection.sh kafka-broker-1 9092'
    ficha_cerrar
}

main() {
    ficha_init_color
    resolve_kafka_broker

    local red='' detalle='' rc=0
    red=$(docker inspect "$BROKER" --format "$FORMATO" 2>&1) || rc=$?

    # Sin terminal sale SOLO el nombre, sin adornos: la guía lo captura con
    # RED=$(...) y cualquier línea de más lo rompería.
    if ! ficha_activa; then
        printf '%s\n' "$red"
        exit "$rc"
    fi

    ficha_encabezado

    if [ "$rc" -ne 0 ] || [ -z "$red" ]; then
        ficha_cruda_envuelta 'Docker no devolvió la red. Esto respondió:' \
            "$(ficha_linea_error "$red")"
        echo ''
        exit "$rc"
    fi

    detalle=$(docker inspect "$BROKER" --format "$FORMATO_IP" 2>/dev/null || true)
    ficha_cruda 'Esto respondió Docker' "$detalle"
    echo ''
    diagnostico "$red" "$detalle"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
