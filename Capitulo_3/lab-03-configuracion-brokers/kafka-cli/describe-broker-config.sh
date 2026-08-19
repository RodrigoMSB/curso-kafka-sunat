#!/bin/bash
# ============================================================
# describe-broker-config.sh · ficha didáctica sobre kafka-configs --describe
# ============================================================
# Familia LEE. Le pregunta al broker VIVO qué configuración está usando y de
# dónde salió cada valor. La lección del lab 03 son los synonyms: la lista de
# orígenes de una propiedad, ordenada por precedencia. El primero manda.
#
# La salida completa son cientos de líneas. La ficha muestra un recorte
# elegido y el diagnóstico cuenta los orígenes sobre la salida ENTERA, no
# sobre el recorte. Un número sacado de una salida recortada miente.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

# Las propiedades que el lab mira. Se eligen porque cada una ilustra un
# origen distinto, y se declaran aquí para que el recorte sea explícito.
INTERESANTES='min.insync.replicas|log.retention.hours|num.partitions|num.replica.fetchers'

flag_desc() {
    case "$1" in
        brokers) echo "preguntamos por un broker, no por un tópico" ;;
        # Se acortan aquí, sin tocar el diccionario compartido: esta ficha
        # lleva cinco flags y con los textos largos se pasa del techo de 20.
        --bootstrap-server) echo "la entrada al clúster" ;;
        # (el valor ya es largo, así que la descripción va corta)
        --all)              echo "trae también los heredados, no solo los que cambiaste" ;;
        *)       flag_desc_comun "$1" ;;
    esac
}

# Cuántas propiedades traen un origen dado. Se cuenta sobre la salida
# completa que devolvió Kafka.
contar_origen() {
    printf '%s\n' "$2" | grep -c "$1" || true
}

ficha_encabezado() {
    local id="$1" destino="$2"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Preguntarle al broker ${id}, vivo, qué config usa y de dónde salió cada valor"

    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-configs --bootstrap-server $destino \\"
    ficha_comando "    --entity-type brokers --entity-name $id \\"
    ficha_comando '    --describe --all'

    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$destino" ''
    ficha_flag '--entity-type'      'brokers'  'brokers'
    ficha_flag '--entity-name'      "$id"      ''
    ficha_flag '--describe'         ''         ''
    ficha_flag '--all'              ''         ''

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'DEFAULT_CONFIG'       'valor de fábrica. Nadie lo tocó'
    ficha_campo 'STATIC_BROKER_CONFIG' 'vino del archivo. Cambiarlo exige reiniciar'
    ficha_campo 'DYNAMIC_BROKER_CONFIG' 'cambiado en caliente, solo para ESTE broker'
    ficha_campo 'DYNAMIC_DEFAULT_BROKER_CONFIG' 'igual, pero para TODOS los brokers'
    ficha_campo 'synonyms={...}'       'los orígenes de esa propiedad, en orden de precedencia'

    ficha_cerrar
    ficha_nota 'De la lista de synonyms manda el PRIMERO. Los de más abajo quedaron tapados.'
    echo ''
}

diagnostico() {
    local salida="$1" id="$2"
    local total n_def n_static n_dyn n_dyndef

    total=$(printf '%s\n' "$salida" | grep -c 'sensitive=' || true)
    n_def=$(contar_origen 'DEFAULT_CONFIG' "$salida")
    n_static=$(contar_origen 'STATIC_BROKER_CONFIG' "$salida")
    n_dyn=$(contar_origen 'DYNAMIC_BROKER_CONFIG' "$salida")
    n_dyndef=$(contar_origen 'DYNAMIC_DEFAULT_BROKER_CONFIG' "$salida")

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "El broker ${id} está usando ${total} propiedades. Contadas sobre la salida completa, no sobre el recorte de arriba:"
    ficha_vacia
    ficha_campo 'DEFAULT_CONFIG'        "${n_def} — de fábrica. Es la mayoría, y está bien que lo sea"
    ficha_campo 'STATIC_BROKER_CONFIG'  "${n_static} — las que declaraste tú en el compose"
    ficha_campo 'DYNAMIC_BROKER_CONFIG' "${n_dyn} — cambiadas en caliente, solo para este broker"
    ficha_campo 'DYNAMIC_DEFAULT_BROKER_CONFIG' "${n_dyndef} — cambiadas en caliente para todo el clúster"
    ficha_vacia

    if [ "$n_dyn" -eq 0 ]; then
        ficha_texto 'Todavía no hay ninguna dinámica: nadie cambió nada en caliente en este broker.'
        ficha_causa '  Cambiar una en vivo' 'kafka-cli/alter-broker-config.sh 1 num.replica.fetchers 2'
    else
        ficha_texto "Hay ${n_dyn} propiedad(es) cambiada(s) en caliente. Esas le ganan a lo que diga el archivo, y el archivo ni se enteró."
    fi

    ficha_vacia
    ficha_texto 'Lo que este comando prueba: el archivo y el broker vivo son dos cosas distintas. El archivo dice lo que se declaró; esto dice lo que se está usando.'
    ficha_cerrar
}

main() {
    local id="${1:-1}"

    ficha_init_color
    resolve_kafka_broker
    local destino="$BOOTSTRAP" salida='' rc=0 recorte=''

    salida=$(docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$destino" \
        --entity-type brokers --entity-name "$id" \
        --describe --all 2>&1) || rc=$?

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_encabezado "$id" "$destino"

    if [ "$rc" -ne 0 ]; then
        ficha_cruda_envuelta 'Kafka no devolvió la configuración. Esto respondió:' \
            "$(ficha_linea_error "$salida")"
        echo ''
        exit "$rc"
    fi

    recorte=$(printf '%s\n' "$salida" | grep -E "^  ($INTERESANTES)=" || true)
    if [ -n "$recorte" ]; then
        ficha_cruda_envuelta 'Cuatro propiedades elegidas, de las cientos que devolvió' "$recorte"
        ficha_nota_salida 'Es un recorte. El comando de arriba, a mano, las devuelve todas.'
        echo ''
    fi

    diagnostico "$salida" "$id"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
