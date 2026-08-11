#!/bin/bash
# Aumenta el número de particiones de un tópico (NUNCA se puede disminuir).
# IMPORTANTE: aumentar particiones rompe el orden por clave para mensajes nuevos.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

if [ $# -ne 2 ]; then
    cat <<EOF
Uso: $0 <TOPICO> <NUEVO_NUMERO_DE_PARTICIONES>

ADVERTENCIA: solo se puede AUMENTAR el número de particiones, nunca disminuir.
ADVERTENCIA: aumentar particiones cambia la asignación hash(key) % num_partitions
             para mensajes futuros, rompiendo el orden por clave.

Ejemplo:
  $0 novatech.gps.realtime 12
EOF
    exit 1
fi

TOPIC="$1"
NEW_PARTITIONS="$2"

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka.
flag_desc() {
    case "$1" in
        --topic)      echo "a qué tópico se le cambian las particiones" ;;
        --alter)      echo "modifica un tópico que ya existe, en caliente y sin reiniciar nada" ;;
        --partitions) echo "el número TOTAL al que quieres llegar, no cuántas agregar. Solo se puede subir" ;;
        *)            flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Llevar ${TOPIC} a ${NEW_PARTITIONS} particiones para repartirlo entre más consumidores"
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-topics --bootstrap-server $BOOTSTRAP --alter \\"
    ficha_comando "    --topic $TOPIC --partitions $NEW_PARTITIONS"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP"      ''
    ficha_flag '--alter'            ''                ''
    ficha_flag '--topic'            "$TOPIC"          ''
    ficha_flag '--partitions'       "$NEW_PARTITIONS" ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Kafka no imprime nada cuando le va bien. Para verlo, corre después describe-topic.sh y cuenta las particiones.'
    ficha_warn 'Kafka reparte por hash de la clave entre el número de particiones, así que al cambiarlo los mensajes nuevos con la misma clave pueden caer en otra y se rompe su orden. No se deshace ni se puede bajar.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-topics está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${YELLOW}[Alter Partitions] ${TOPIC} -> ${NEW_PARTITIONS} particiones${NC}"
echo -e "${YELLOW}⚠  Esta operación NO PUEDE deshacerse.${NC}"
echo "────────────────────────────────────────────────────────"

docker exec "$BROKER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --alter \
    --topic "$TOPIC" \
    --partitions "$NEW_PARTITIONS"

echo -e "${GREEN}  ✓ Particiones actualizadas${NC}"
