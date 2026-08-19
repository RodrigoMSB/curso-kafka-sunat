#!/bin/bash
# ============================================================
# list-config-files.sh · ficha didáctica sobre los .properties del broker
# ============================================================
# Familia LEE. Solo lista archivos, no toca nada. La lección del lab 03 es
# que en /etc/kafka hay muchos .properties y solo uno manda. Cuál es no se
# afirma: se le pregunta al proceso del broker con qué archivo arrancó.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale nada más que la
# lista, porque la guía puede hacer 'list-config-files.sh | wc -l'.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

flag_desc() {
    case "$1" in
        /etc/kafka/*.properties) echo "todos los .properties del directorio de configuración" ;;
        *)                       flag_desc_comun "$1" ;;
    esac
}

# ── Con qué archivo arrancó el proceso ───────────────────────
# Es la única respuesta que no se puede discutir: se lee de la línea de
# comandos del java que está corriendo. Si no se puede leer, se dice, no
# se adivina.
archivo_en_uso() {
    docker exec "$BROKER" bash -c \
        "ps -o args= -C java 2>/dev/null | tr ' ' '\n' | grep '\.properties\$'" 2>/dev/null | head -1
}

ficha_encabezado() {
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Listar los archivos de configuración que hay dentro de ${BROKER} y descubrir cuántos son y cuál usa el broker de verdad"

    ficha_medio 'COMANDO REAL'
    ficha_comando "docker exec ${BROKER} bash -c 'ls /etc/kafka/*.properties'"

    ficha_medio 'DESGLOSE'
    ficha_flag 'ls' '/etc/kafka/*.properties' '/etc/kafka/*.properties'

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'kafka.properties' 'el que manda. No lo escribió nadie: la imagen lo genera al arrancar, traduciendo tus variables KAFKA_* del compose'
    ficha_campo 'server.properties' 'ejemplo de fábrica que trae la distribución. El broker NO lo lee'
    ficha_campo 'broker.properties' 'otro ejemplo de fábrica, para un nodo solo broker'
    ficha_campo 'controller.properties' 'ejemplo de fábrica, para un nodo solo controlador'
    ficha_campo 'connect-*.properties' 'ejemplos de Kafka Connect. No son de este lab'

    ficha_cerrar
    ficha_nota 'Que un archivo exista no significa que el broker lo lea.'
    echo ''
}

diagnostico() {
    local salida="$1" en_uso="$2" total generados

    total=$(printf '%s\n' "$salida" | grep -c 'properties$')

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "Hay ${total} archivos .properties en /etc/kafka, y solo uno gobierna este broker."
    ficha_vacia

    if [ -n "$en_uso" ]; then
        ficha_texto "El proceso de Kafka arrancó con ${en_uso}."
        ficha_texto 'Eso no es una suposición: sale de la línea de comandos del java que'
        ficha_texto 'está corriendo ahora mismo.'
        generados=$(( total - 1 ))
        ficha_texto "Los otros ${generados} son ejemplos que trae la distribución. Puedes editarlos"
        ficha_texto 'todo lo que quieras y el broker no se va a enterar.'
    else
        ficha_warn 'No pude leer con qué archivo arrancó el proceso.'
        ficha_texto 'Verifícalo a mano dentro del contenedor con:'
        ficha_causa '  El archivo en uso' "docker exec ${BROKER} ps -o args= -C java"
    fi

    ficha_vacia
    ficha_texto 'La pregunta que sigue: si nadie escribió ese archivo, ¿de dónde salieron'
    ficha_texto 'sus valores? De las variables KAFKA_* de tu compose.'
    ficha_causa '  Compara los archivos' 'kafka-cli/compare-configs.sh'
    ficha_cerrar
}

main() {
    ficha_init_color
    resolve_kafka_broker

    local salida='' rc=0 en_uso=''
    salida=$(docker exec "$BROKER" bash -c 'ls /etc/kafka/*.properties' 2>&1) || rc=$?

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_encabezado

    if [ "$rc" -ne 0 ]; then
        ficha_cruda_envuelta 'El contenedor no devolvió la lista. Esto respondió:' \
            "$(ficha_linea_error "$salida")"
        echo ''
        exit "$rc"
    fi

    ficha_cruda 'Esto hay en /etc/kafka' "$salida"
    echo ''

    en_uso=$(archivo_en_uso || true)
    diagnostico "$salida" "$en_uso"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
