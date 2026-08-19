#!/bin/bash
# ============================================================
# check-listeners.sh · ficha didáctica sobre listeners y advertised.listeners
# ============================================================
# Familia LEE. Saca del archivo generado las dos líneas que deciden quién
# puede hablarle a este broker. La lección del lab 04: listeners son las
# puertas que abre; advertised.listeners es la dirección que le DICTA al
# cliente para todo lo que viene después del bootstrap. No son lo mismo y
# confundirlas es el fallo clásico de Kafka.
#
# La ficha se dibuja solo en una terminal. Al tuberiar salen las dos líneas.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

flag_desc() {
    case "$1" in
        listeners) echo "las dos líneas que deciden por dónde se entra a este broker" ;;
        /etc/kafka/*.properties) echo "el archivo que la imagen genera al arrancar. Es el que el broker lee" ;;
        *)         flag_desc_comun "$1" ;;
    esac
}

# El valor de una de las dos líneas, sin el nombre de la propiedad.
valor_de() {
    printf '%s\n' "$2" | grep "^$1=" | cut -d= -f2- | head -1
}

# Los nombres de listener declarados, separados por espacio.
nombres_de() {
    printf '%s\n' "$1" | tr ',' '\n' | sed 's/:.*//' | tr '\n' ' '
}

ficha_encabezado() {
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Leer del archivo generado de ${BROKER} las dos líneas que definen por dónde escucha y qué dirección le publica a cada cliente"

    ficha_medio 'COMANDO REAL'
    ficha_comando "docker exec ${BROKER} bash -c \\"
    ficha_comando "    'grep listeners /etc/kafka/kafka.properties'"

    ficha_medio 'DESGLOSE'
    ficha_flag 'grep' 'listeners' 'listeners'
    ficha_flag 'archivo' '/etc/kafka/kafka.properties' '/etc/kafka/*.properties'

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'listeners' 'las puertas que el broker ABRE. Una por cada público'
    ficha_campo 'advertised.listeners' 'la dirección que el broker le DICTA al cliente después del bootstrap. Es su tarjeta de presentación'
    ficha_campo '0.0.0.0' 'escucho por todas las interfaces. Sirve para abrir, nunca para publicar'
    ficha_campo 'PLAINTEXT / EXTERNAL / CONTROLLER' 'los nombres que les pusiste tú. Kafka no los interpreta, solo los aparea'

    ficha_cerrar
    ficha_nota 'Una tarjeta no es correcta en absoluto: es correcta PARA un público.'
    echo ''
}

diagnostico() {
    local salida="$1"
    local lst adv n_lst n_adv

    lst=$(valor_de 'listeners' "$salida")
    adv=$(valor_de 'advertised.listeners' "$salida")
    n_lst=$(nombres_de "$lst")
    n_adv=$(nombres_de "$adv")

    ficha_abrir 'DIAGNÓSTICO'

    if [ -z "$lst" ]; then
        ficha_warn 'No encontré la línea listeners en el archivo generado.'
        ficha_cerrar
        return 0
    fi

    ficha_texto "Este broker abre estas puertas: ${n_lst}"
    ficha_texto "Y publica direcciones para: ${n_adv}"
    ficha_vacia

    case "$lst" in
        *0.0.0.0*)
            ficha_texto 'Fíjate en el 0.0.0.0 del lado de listeners: significa "escucho por todas las interfaces". Para ABRIR está bien.'
            ;;
    esac
    case "$adv" in
        *0.0.0.0*)
            ficha_warn 'Hay un 0.0.0.0 en advertised.listeners. Eso es un error: al cliente no se le puede dictar "todas las interfaces", necesita una dirección concreta.'
            ;;
        *)
            ficha_texto 'Y fíjate que en advertised.listeners NO hay ningún 0.0.0.0: ahí van direcciones concretas, porque el cliente tiene que poder resolverlas.'
            ;;
    esac

    ficha_vacia
    case "$adv" in
        *localhost*)
            ficha_texto 'El EXTERNAL publica localhost. Eso es correcto para tu máquina, donde "localhost" es donde están los puertos publicados por Docker.'
            ficha_texto 'Y es inservible para un contenedor de la red, porque para él "localhost" es él mismo. Ese es el fallo clásico, y lo vas a ver en vivo.'
            ;;
    esac
    ficha_causa '  La red del clúster' 'kafka-cli/show-network.sh'
    ficha_cerrar
}

main() {
    ficha_init_color
    resolve_kafka_broker

    local salida='' rc=0
    salida=$(docker exec "$BROKER" bash -c 'grep listeners /etc/kafka/kafka.properties' 2>&1) || rc=$?

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_encabezado

    if [ "$rc" -ne 0 ] || [ -z "$salida" ]; then
        ficha_cruda_envuelta 'El grep no devolvió nada. Esto respondió:' \
            "$(ficha_linea_error "$salida")"
        echo ''
        exit "$rc"
    fi

    ficha_cruda_envuelta 'Esto dice el archivo' "$salida"
    echo ''
    diagnostico "$salida"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
