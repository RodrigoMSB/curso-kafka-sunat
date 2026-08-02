#!/bin/bash
# ============================================================
# flags.sh · diccionario de flags compartido por los wrappers
# ============================================================
# Los flags que significan lo mismo en todo Kafka viven acá, para que
# los 87 wrappers no los expliquen cada uno a su manera. Cada wrapper
# define su propio flag_desc para lo suyo y cae acá para el resto.
#
# Función con case, NO array asociativo. Bash 3.2 no los soporta.
flag_desc_comun() {
    case "$1" in
        --bootstrap-server) echo "la puerta de entrada al clúster. En tu servidor va la IP de tu broker" ;;
        --topic)            echo "sobre qué tópico preguntamos" ;;
        --describe)         echo "solo consulta, no toca nada" ;;
        --list)             echo "solo consulta, devuelve los nombres y nada más" ;;
        --exclude-internal) echo "esconde los tópicos que Kafka usa para su propia contabilidad" ;;
        --all)              echo "trae también los valores heredados, no solo los que cambiaste" ;;
        --entity-type)      echo "sobre qué tipo de objeto preguntamos" ;;
        --entity-name)      echo "cuál de ellos" ;;
        *)                  echo "" ;;
    esac
}
