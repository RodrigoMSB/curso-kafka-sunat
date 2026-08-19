#!/bin/bash
# ============================================================
# compare-configs.sh · ficha didáctica sobre las cuatro propiedades clave
# ============================================================
# Familia LEE. Busca las mismas cuatro propiedades en todos los .properties
# y muestra que dan respuestas distintas. La lección: no alcanza con leer un
# archivo, hay que saber cuál. Las huellas que delatan al real son la ruta
# de datos del compose y el nombre del contenedor.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale el grep pelado.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

PROPS='^(node.id|process.roles|log.dirs|listeners)'

flag_desc() {
    case "$1" in
        -E)      echo "expresión regular extendida, para pedir varias propiedades de una vez" ;;
        "$PROPS") echo "las cuatro propiedades que definen la identidad del nodo" ;;
        /etc/kafka/*.properties) echo "todos los .properties del directorio de configuración" ;;
        *)       flag_desc_comun "$1" ;;
    esac
}

# Cuántos archivos distintos aparecen en la salida del grep.
archivos_distintos() {
    printf '%s\n' "$1" | cut -d: -f1 | sort -u | grep -c 'properties$'
}

# El archivo que trae una huella nuestra. Las dos que valen: la ruta de
# datos que fijamos en el compose y el nombre del contenedor en listeners.
archivo_con_huella() {
    printf '%s\n' "$1" | grep -E '/var/lib/kafka/data|kafka-broker' | cut -d: -f1 | sort -u | head -1
}

# Los valores que da un archivo para una propiedad.
valor_de() {
    printf '%s\n' "$2" | grep "^$1:$3=" | cut -d= -f2- | head -1
}

ficha_encabezado() {
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Preguntarle a TODOS los .properties de ${BROKER} las mismas cuatro propiedades, para ver que no contestan lo mismo"

    ficha_medio 'COMANDO REAL'
    ficha_comando "docker exec ${BROKER} bash -c \\"
    ficha_comando "    'grep -E \"${PROPS}\" \\"
    ficha_comando "     /etc/kafka/*.properties'"

    ficha_medio 'DESGLOSE'
    ficha_flag 'grep -E' "\"${PROPS}\"" '-E'
    ficha_flag 'archivos' '/etc/kafka/*.properties' '/etc/kafka/*.properties'

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'node.id' 'el número de este nodo en el clúster. Sale de KAFKA_NODE_ID'
    ficha_campo 'process.roles' 'si el nodo es broker, controlador o las dos cosas'
    ficha_campo 'log.dirs' 'dónde guarda los datos. Es la huella más clara: la ruta que fijaste tú'
    ficha_campo 'listeners' 'las puertas que abre. La otra huella: lleva el nombre de tu contenedor'

    ficha_cerrar
    ficha_nota 'Cada línea viene con el archivo del que salió, delante de los dos puntos.'
    echo ''
}

diagnostico() {
    local salida="$1" cuantos real
    local rol dirs

    cuantos=$(archivos_distintos "$salida")
    real=$(archivo_con_huella "$salida")

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "Las mismas cuatro propiedades aparecen en ${cuantos} archivos distintos, con valores que se contradicen."

    if [ -n "$real" ]; then
        rol=$(valor_de "$real" "$salida" 'process.roles')
        dirs=$(valor_de "$real" "$salida" 'log.dirs')
        ficha_vacia
        ficha_texto "El real es ${real}, y se reconoce por las huellas:"
        [ -n "$dirs" ] && ficha_campo 'log.dirs' "${dirs} — esa ruta la pusiste tú en el compose, no viene de fábrica"
        ficha_campo 'listeners' 'lleva el nombre de tu contenedor, que la distribución no puede saber'
        [ -n "$rol" ] && ficha_texto "Ese archivo declara process.roles=${rol}."
    else
        ficha_warn 'Ningún archivo trae las huellas esperadas (/var/lib/kafka/data ni el nombre del contenedor).'
        ficha_texto 'Puede que este clúster no sea el del lab. Compruébalo a mano.'
    fi

    ficha_vacia
    ficha_texto 'Los demás traen /tmp/kraft-*-logs y listeners en localhost: son los ejemplos que vienen en la distribución, iguales en cualquier instalación del mundo.'
    ficha_vacia
    ficha_texto 'Y ojo con lo que este comando NO puede decirte: el archivo dice lo que se declaró, no lo que el broker está usando ahora. Eso se le pregunta al broker.'
    ficha_causa '  Config efectiva' 'kafka-cli/describe-broker-config.sh 1'
    ficha_cerrar
}

main() {
    ficha_init_color
    resolve_kafka_broker

    local salida='' rc=0
    salida=$(docker exec "$BROKER" bash -c "grep -E \"$PROPS\" /etc/kafka/*.properties" 2>&1) || rc=$?

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

    ficha_cruda 'Esto devolvieron los archivos' "$salida"
    echo ''
    diagnostico "$salida"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
