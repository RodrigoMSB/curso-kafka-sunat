#!/bin/bash
# ============================================================
# alter-broker-config.sh · ficha didáctica sobre kafka-configs --alter
# ============================================================
# Familia LEE-Y-ESCRIBE. Cambia una propiedad del broker EN CALIENTE, sin
# reiniciar y sin tocar el archivo.
#
# 🔴 ESTE WRAPPER NO PROTEGE AL ALUMNO DEL ERROR, Y ES A PROPÓSITO.
# En el lab 03 se pide num.replica.fetchers=4 sobre un valor de 1, Kafka lo
# rechaza, y ESE rechazo es la lección: el broker está vivo del otro lado y
# valida. Un wrapper que validara antes de mandar, o que suavizara el
# mensaje, borraría el momento pedagógico del lab. El comando se manda tal
# cual y el error se muestra entero.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -uo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

flag_desc() {
    case "$1" in
        brokers)          echo "preguntamos por un broker, no por un tópico" ;;
        --alter)          echo "esto SÍ cambia algo. Todo lo demás del lab 03 solo miraba" ;;
        --add-config)     echo "la propiedad y su valor nuevo, en caliente" ;;
        --delete-config)  echo "quita el valor dinámico y deja que vuelva a mandar el de abajo" ;;
        *)                flag_desc_comun "$1" ;;
    esac
}

uso() {
    echo "Uso: $0 <ID_BROKER> <PROPIEDAD> <VALOR>   cambia la propiedad en caliente" >&2
    echo "     $0 <ID_BROKER> <PROPIEDAD> --delete  quita el cambio y vuelve al valor de antes" >&2
    echo "" >&2
    echo "Ejemplos del lab 03:" >&2
    echo "  $0 1 num.replica.fetchers 4        # Kafka lo RECHAZA. Es la lección" >&2
    echo "  $0 1 num.replica.fetchers 2        # este sí lo acepta" >&2
    echo "  $0 1 num.replica.fetchers --delete # lo deja como estaba" >&2
    exit 1
}

# El valor efectivo de la propiedad AHORA, y de dónde viene. Se lee del
# broker antes de tocar nada, para poder mostrar el antes y el después.
valor_actual() {
    docker exec "$BROKER" kafka-configs \
        --bootstrap-server "$BOOTSTRAP" \
        --entity-type brokers --entity-name "$1" \
        --describe --all 2>/dev/null | grep "^  $2=" | head -1
}

ficha_encabezado() {
    local id="$1" prop="$2" valor="$3" destino="$4" borrar="$5"

    ficha_abrir 'QUÉ VAMOS A HACER'
    if [ "$borrar" = "1" ]; then
        ficha_texto "Quitarle al broker ${id} el valor dinámico de ${prop}, para que vuelva a mandar el que estaba debajo"
    else
        ficha_texto "Cambiarle al broker ${id} la propiedad ${prop} a ${valor}, en caliente y sin reiniciar nada"
    fi

    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-configs --bootstrap-server $destino \\"
    ficha_comando "    --entity-type brokers --entity-name $id \\"
    if [ "$borrar" = "1" ]; then
        ficha_comando "    --alter --delete-config $prop"
    else
        ficha_comando "    --alter --add-config ${prop}=${valor}"
    fi

    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$destino" ''
    ficha_flag '--entity-type'      'brokers'  'brokers'
    ficha_flag '--entity-name'      "$id"      ''
    ficha_flag '--alter'            ''         ''
    if [ "$borrar" = "1" ]; then
        ficha_flag '--delete-config' "$prop" '--delete-config'
    else
        ficha_flag '--add-config' "${prop}=${valor}" '--add-config'
    fi

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'Completed updating config' 'aceptado. El cambio ya rige, sin reiniciar'
    ficha_campo 'InvalidRequestException'   'rechazado. El motivo va en la segunda línea, no en la traza'

    ficha_cerrar
    ficha_nota "El cambio afecta SOLO al broker ${id}, y no toca ningún archivo."
    ficha_nota 'Kafka valida en caliente: no acepta más del doble del valor actual.'
    echo ''
}

diagnostico_ok() {
    local id="$1" prop="$2" antes="$3" despues="$4" borrar="$5"

    # El antes y el después van FUERA de la caja. ficha_cruda imprime sin
    # marco, y llamarla entre ficha_abrir y ficha_cerrar parte la caja en dos.
    if [ -n "$antes" ]; then
        ficha_cruda_envuelta 'Antes' "$antes"
        echo ''
    fi
    if [ -n "$despues" ]; then
        ficha_cruda_envuelta 'Ahora' "$despues"
        echo ''
    fi

    ficha_abrir 'DIAGNÓSTICO'
    if [ "$borrar" = "1" ]; then
        ficha_texto "Listo: ${prop} ya no tiene valor dinámico en el broker ${id}."
    else
        ficha_texto "Aceptado. El broker ${id} ya está usando el valor nuevo, sin haberse reiniciado."
    fi
    ficha_vacia
    if [ "$borrar" = "1" ]; then
        ficha_texto 'Mira los synonyms: quedó uno solo. El DYNAMIC desapareció y el valor de fábrica volvió a mandar.'
    else
        ficha_texto 'Mira los synonyms: ahora hay dos orígenes. El DEFAULT de fábrica sigue ahí abajo y el DYNAMIC le gana encima.'
    fi
    ficha_texto "Y el archivo /etc/kafka/kafka.properties no se enteró de nada: sigue sin mencionar ${prop}. Compruébalo con:"
    ficha_causa '  El archivo' "kafka-cli/compare-configs.sh"
    ficha_cerrar
}

diagnostico_rechazo() {
    local id="$1" prop="$2" valor="$3" antes="$4" motivo="$5"

    # Fuera de la caja, por lo mismo que en diagnostico_ok.
    if [ -n "$motivo" ]; then
        ficha_cruda_envuelta 'El motivo, que es la única línea que importa de toda esa pared' "$motivo"
        echo ''
    fi
    if [ -n "$antes" ]; then
        ficha_cruda_envuelta 'El valor que tiene ahora' "$antes"
        echo ''
    fi

    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "Kafka RECHAZÓ el cambio, y eso no es un tropiezo tuyo: es la lección del lab."
    ficha_vacia
    ficha_texto 'Los cambios dinámicos tienen su propia validación. Un archivo en disco acepta cualquier disparate y recién te enteras al reiniciar; un broker vivo te contesta en el momento.'
    ficha_texto "Para esta propiedad el límite es el doble del valor actual. Prueba con un valor que lo respete."
    ficha_causa '  Dentro del límite' "kafka-cli/alter-broker-config.sh ${id} ${prop} <el doble>"
    ficha_cerrar
}

main() {
    [ $# -lt 3 ] && uso
    local id="$1" prop="$2" valor="$3" borrar=0
    [ "$valor" = "--delete" ] && borrar=1

    ficha_init_color
    resolve_kafka_broker
    local destino="$BOOTSTRAP" antes='' despues='' salida='' rc=0 motivo=''

    antes=$(valor_actual "$id" "$prop" || true)

    if [ "$borrar" = "1" ]; then
        salida=$(docker exec -e KAFKA_OPTS= "$BROKER" kafka-configs \
            --bootstrap-server "$destino" \
            --entity-type brokers --entity-name "$id" \
            --alter --delete-config "$prop" 2>&1) || rc=$?
    else
        salida=$(docker exec -e KAFKA_OPTS= "$BROKER" kafka-configs \
            --bootstrap-server "$destino" \
            --entity-type brokers --entity-name "$id" \
            --alter --add-config "${prop}=${valor}" 2>&1) || rc=$?
    fi

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_encabezado "$id" "$prop" "$valor" "$destino" "$borrar"

    if [ "$rc" -ne 0 ]; then
        # El error se muestra ENTERO, sin recortar ni suavizar. La segunda
        # línea trae el motivo y se destaca aparte, pero la pared va igual.
        ficha_cruda_envuelta 'Esto respondió Kafka, entero' "$salida"
        echo ''
        motivo=$(printf '%s\n' "$salida" | sed -n 's/.*ConfigException: //p' | head -1)
        diagnostico_rechazo "$id" "$prop" "$valor" "$antes" "$motivo"
        exit "$rc"
    fi

    ficha_cruda 'Esto respondió Kafka' "$salida"
    echo ''
    despues=$(valor_actual "$id" "$prop" || true)
    diagnostico_ok "$id" "$prop" "$antes" "$despues" "$borrar"
}

if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
