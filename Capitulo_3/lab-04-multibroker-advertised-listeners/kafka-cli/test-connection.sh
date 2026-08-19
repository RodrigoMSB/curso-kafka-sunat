#!/bin/bash
# ============================================================
# test-connection.sh · ficha didáctica sobre el fallo clásico de listeners
# ============================================================
# Familia LEE. Lanza un cliente DENTRO de la red del clúster y lo hace
# bootstrapear contra el host y puerto que le pases. La lección del lab 04:
# con el puerto EXTERNO (9092) el bootstrap conecta y el cliente muere igual,
# porque el metadata le devuelve localhost; con el INTERNO (29092) funciona.
#
# El fallo NO se evita ni se suaviza: es el experimento. El wrapper no
# valida el puerto ni te desvía al que funciona.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale lo del cliente.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -uo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

IMAGEN='confluentinc/cp-kafka:8.2.0'

flag_desc() {
    case "$1" in
        --network) echo "el cliente arranca DENTRO de la red del clúster, no en tu máquina" ;;
        --rm)      echo "el contenedor del cliente se borra solo al terminar" ;;
        *)         flag_desc_comun "$1" ;;
    esac
}

uso() {
    echo "Uso: $0 <HOST> <PUERTO>" >&2
    echo "" >&2
    echo "Los dos experimentos del lab 04:" >&2
    echo "  $0 kafka-broker-1 9092    # puerto EXTERNO desde adentro: falla" >&2
    echo "  $0 kafka-broker-1 29092   # puerto INTERNO desde adentro: funciona" >&2
    exit 1
}

ficha_encabezado() {
    local host="$1" puerto="$2" red="$3"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Lanzar un cliente DENTRO de la red del clúster y hacerlo entrar por ${host}:${puerto}, para ver si esa dirección le sirve"

    ficha_medio 'COMANDO REAL'
    ficha_comando "docker run --rm --network $red \\"
    ficha_comando "    $IMAGEN \\"
    ficha_comando "    kafka-broker-api-versions --bootstrap-server ${host}:${puerto}"

    ficha_medio 'DESGLOSE'
    ficha_flag '--rm'               ''                  '--rm'
    ficha_flag '--network'          "$red"              '--network'
    ficha_flag '--bootstrap-server' "${host}:${puerto}" ''

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'una lista de APIs' 'funcionó. Conectó, pidió el metadata y alcanzó lo que le dictaron'
    ficha_campo 'DisconnectException' 'el bootstrap conectó y el cliente murió después'
    ficha_campo 'Connection to node N' 'a qué dirección intentó ir DESPUÉS del bootstrap. Ahí está la prueba'

    ficha_cerrar
    ficha_nota 'El bootstrap y lo que viene después son dos conexiones distintas.'
    echo ''
}

diagnostico() {
    local host="$1" puerto="$2" salida="$3"
    local funciono=0 menciona_localhost=0

    printf '%s\n' "$salida" | grep -q 'usable:' && funciono=1
    printf '%s\n' "$salida" | grep -q 'localhost' && menciona_localhost=1

    ficha_abrir 'DIAGNÓSTICO'

    if [ "$funciono" -eq 1 ]; then
        ficha_texto "Funcionó. El cliente entró por ${host}:${puerto}, pidió el metadata, y las direcciones que le dictaron sí las pudo alcanzar."
        ficha_vacia
        ficha_texto 'Fíjate en los nombres que aparecen en la salida: son nombres de contenedor. Dentro de la red se resuelven; desde tu máquina no.'
        ficha_texto 'Ese es el listener interno haciendo su trabajo: publica una dirección escrita para el público que está adentro.'
    else
        ficha_warn "El cliente NO pudo trabajar contra ${host}:${puerto}, y eso es exactamente lo que el lab quiere que veas."
        ficha_vacia
        ficha_texto "Lee con cuidado lo que pasó: la conexión inicial a ${host}:${puerto} SÍ funcionó, porque ese puerto está abierto en el contenedor."
        if [ "$menciona_localhost" -eq 1 ]; then
            ficha_texto 'Pero mira a dónde intentó ir después: a localhost. Eso salió del advertised.listeners del EXTERNAL, que está escrito para tu máquina.'
            ficha_texto 'Y para este cliente, que corre en otro contenedor, "localhost" es él mismo. Ahí no hay ningún Kafka.'
        else
            ficha_texto 'Y después falló contra la dirección que le dictó el metadata.'
        fi
        ficha_vacia
        ficha_texto 'La lección: que el bootstrap responda NO significa que el clúster esté bien configurado. Son dos conexiones, y la segunda usa la tarjeta que le dieron.'
        ficha_causa '  El que sí le sirve' "kafka-cli/test-connection.sh ${host} 29092"
    fi

    ficha_cerrar
}

main() {
    [ $# -lt 2 ] && uso
    local host="$1" puerto="$2"

    ficha_init_color
    resolve_kafka_broker

    local red='' salida='' rc=0
    red=$(docker inspect "$BROKER" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null)
    if [ -z "$red" ]; then
        echo "[ERROR] No pude averiguar la red del clúster." >&2
        exit 1
    fi

    salida=$(docker run --rm --network "$red" "$IMAGEN" \
        kafka-broker-api-versions --bootstrap-server "${host}:${puerto}" 2>&1) || rc=$?

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_encabezado "$host" "$puerto" "$red"

    # La salida va entera, con sus WARN y todo. En el caso que falla, esos
    # WARN SON la evidencia: dicen a qué dirección intentó ir el cliente.
    ficha_cruda_envuelta 'Esto respondió el cliente' "$salida"
    echo ''
    diagnostico "$host" "$puerto" "$salida"
    exit "$rc"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
