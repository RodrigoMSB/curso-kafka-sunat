#!/bin/bash
# ============================================================
# inspect-image.sh · ficha didáctica sobre la imagen de Kafka
# ============================================================
# Familia INFRA. No consulta un clúster, abre la imagen. Es el único de
# esta tanda donde Docker es la lección y no la fontanería, así que acá
# el comando protagonista es el docker run y NO hay nota al pie que lo
# mande al fondo.
#
# Corre cuatro comandos, no uno. Una ficha por comando serían cuatro
# cajas seguidas y nadie lee eso: va una sola al principio que anuncia
# los cuatro pasos, y cada paso conserva su rótulo [N/4].
#
# La ficha se dibuja solo en una terminal. Sin terminal salen los cuatro
# pasos pelados, como los devolvió Docker.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

IMAGEN="confluentinc/cp-kafka:8.2.0"

flag_desc() {
    case "$1" in
        run)   echo "levanta un contenedor nuevo a partir de la imagen" ;;
        --rm)  echo "lo borra apenas termina. Es de usar y tirar, no deja rastro" ;;
        -q)    echo "sin la barra de progreso, solo el resultado" ;;
        pull)  echo "descarga la imagen si no está. Si ya está, no hace nada" ;;
        sh)    echo "abre una shell adentro del contenedor para correr el listado" ;;
        *)     flag_desc_comun "$1" ;;
    esac
}

# ── Encabezado · una sola ficha para los cuatro pasos ────────
ficha_encabezado() {
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Abrir la imagen ${IMAGEN} y ver qué trae adentro, sin levantar ningún clúster"

    ficha_medio 'LOS CUATRO PASOS'
    ficha_campo '[1/4]' 'descargar la imagen, si aún no está'
    ficha_campo '[2/4]' 'qué binarios de Kafka trae'
    ficha_campo '[3/4]' 'qué archivos de configuración de ejemplo trae'
    ficha_campo '[4/4]' 'con qué Java corre'

    ficha_medio 'COMANDO REAL'
    ficha_comando "docker pull -q ${IMAGEN}"
    ficha_comando "docker run --rm ${IMAGEN} \\"
    ficha_comando '    sh -c "ls /usr/bin/kafka-*"'
    ficha_comando "docker run --rm ${IMAGEN} \\"
    ficha_comando '    sh -c "ls -la /etc/kafka/"'
    ficha_comando "docker run --rm ${IMAGEN} java -version"

    ficha_medio 'DESGLOSE'
    ficha_flag 'pull'  ''  ''
    ficha_flag 'run'   ''  ''
    ficha_flag '--rm'  ''  ''
    ficha_flag 'sh'    '-c' 'sh'

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo '/usr/bin/kafka-*' 'un ejecutable por herramienta. Son los que vas a usar todo el curso'
    ficha_campo '/etc/kafka/'      'los archivos de ejemplo. El lab no los usa, arma el suyo'
    ficha_campo 'openjdk version'  'Kafka corre sobre la JVM, y esa versión viaja dentro de la imagen'

    ficha_cerrar
    echo ''
}

# Cada paso abre con una regla corta y su numero, para que se lea como
# parte de la ficha y no como una linea suelta al lado de las cajas.
paso() {
    printf '%s  ── [%s/4] %s %s%s\n' \
        "$F_MARCO" "$1" "$2" "$(ficha_raya $(( FICHA_ANCHO - 12 - $(ficha_ancho_visible "$2") )))" "$F_OFF"
}

# ── Qué acaba de ver ────────────────────────────────────────
# Cierra hacia adelante: para qué le sirve esto en los 13 labs que
# vienen, y qué cambia cuando el mismo Kafka no viene en una imagen.
que_acabas_de_ver() {
    local n_bin="$1" java="$2"

    ficha_abrir 'QUÉ ACABA DE VER'
    if [ "$n_bin" -gt 0 ]; then
        ficha_texto "Los ${n_bin} binarios de arriba son los primeros de una lista más larga, recortada para que entre en pantalla. Son los que se usan en los 13 laboratorios que siguen. kafka-topics, kafka-console-producer y kafka-configs son los tres que más se escriben."
    fi
    if [ -n "$java" ]; then
        ficha_texto "Kafka corre sobre ${java}, y esa JVM viaja dentro de la imagen. Por eso no hizo falta instalar Java en su máquina."
    fi

    ficha_vacia
    ficha_texto 'En el curso llegan dentro de una imagen porque es lo que hace el laboratorio reproducible. En SUNAT no habrá imagen. Kafka llega por paquete o por tarball y esos mismos binarios quedan en el PATH del servidor, así que se invocan sin docker adelante.'
    ficha_texto 'Lo que cambia es cómo llegan. Los comandos son los mismos.'

    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    ficha_init_color

    local con_ficha=0
    if ficha_activa; then
        con_ficha=1
        ficha_encabezado
    fi

    local rc=0 binarios='' etc='' java='' n_bin=0 ver_java=''

    [ "$con_ficha" -eq 1 ] && paso 1 'descargando la imagen si hace falta'
    docker pull -q "$IMAGEN" > /dev/null 2>&1 || rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "[ERROR] No se pudo bajar la imagen ${IMAGEN}." >&2
        echo "  ¿Está Docker corriendo? Probá con 'docker info'." >&2
        exit 1
    fi

    binarios=$(docker run --rm "$IMAGEN" sh -c "ls /usr/bin/kafka-* 2>/dev/null | head -20" 2>&1) || true
    etc=$(docker run --rm "$IMAGEN" sh -c "ls -la /etc/kafka/ 2>/dev/null | head -20" 2>&1) || true
    java=$(docker run --rm "$IMAGEN" java -version 2>&1 | head -3) || true

    if [ "$con_ficha" -eq 0 ]; then
        printf '%s\n%s\n%s\n' "$binarios" "$etc" "$java"
        exit 0
    fi

    paso 2 'binarios de Kafka en /usr/bin/'
    ficha_cruda '' "$binarios"
    echo ''
    paso 3 'archivos de configuración de ejemplo en /etc/kafka/'
    ficha_cruda '' "$etc"
    echo ''
    paso 4 'versión de Java'
    ficha_cruda '' "$java"
    echo ''

    n_bin=$(printf '%s\n' "$binarios" | grep -c '^/usr/bin/kafka-') || n_bin=0
    ver_java=$(printf '%s\n' "$java" | sed -n 's/.*version "\([^"]*\)".*/Java \1/p' | head -1)
    que_acabas_de_ver "$n_bin" "$ver_java"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato sin depender de Docker.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
