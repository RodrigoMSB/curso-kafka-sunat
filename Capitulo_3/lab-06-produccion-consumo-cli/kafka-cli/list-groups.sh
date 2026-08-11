#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker

# ── Ficha didáctica ──────────────────────────────────────────
# Solo con TTY. Al tuberiar sale nada más que lo de Kafka, porque las
# guías del curso hacen 'list-groups.sh | head -3'.
flag_desc() { flag_desc_comun "$1"; }

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Preguntarle al clúster qué grupos de consumidores existen'
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-consumer-groups --bootstrap-server $BOOTSTRAP --list"
    ficha_medio 'DESGLOSE'
    ficha_flag '--bootstrap-server' "$BOOTSTRAP" ''
    ficha_flag '--list' '' ''
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Un nombre por línea. Cada uno es un grupo que Kafka recuerda, tenga consumidores vivos o no, porque el grupo sobrevive a sus miembros y conserva por dónde iba leyendo.'
    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${BROKER}"
    ficha_nota 'En tu servidor, kafka-consumer-groups está en el PATH y no hace falta docker.'
    echo ''
fi

echo -e "${CYAN}[Consumer Groups] del clúster${NC}"
echo "────────────────────────────────────────────────────────"
docker exec "$BROKER" kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" --list
