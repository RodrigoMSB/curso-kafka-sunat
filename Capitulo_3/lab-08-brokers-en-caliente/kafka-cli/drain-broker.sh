#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"
resolve_broker
TOPIC="${1:-novatech.lab08.pedidos}"
REMAINING="${2:-1,2,3}"   # brokers que SE QUEDAN (sin el que se drena)
# ── Ficha didáctica ──────────────────────────────────────────
# Este wrapper no ejecuta Kafka: delega en reassign-partitions.sh. Su ficha
# apunta al comando delegado, porque el alumno corre ESTE y merece saber aquí
# qué va a pasar. Solo con TTY.
flag_desc() {
    case "$1" in
        --broker-list) echo "los brokers que SE QUEDAN con las réplicas. El que falte de esta lista es el que se drena" ;;
        *)             flag_desc_comun "$1" ;;
    esac
}

if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Sacar del reparto al broker que no esté en la lista ${REMAINING}, moviendo las réplicas de ${TOPIC} a los que sí están. Es el paso previo a apagar un broker sin perder datos."
    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-cli/reassign-partitions.sh $TOPIC $REMAINING"
    ficha_comando "  que por debajo corre kafka-reassign-partitions en sus tres fases,"
    ficha_comando '  --generate, --execute y --verify'
    ficha_medio 'DESGLOSE'
    ficha_flag "  --broker-list" "$REMAINING" '--broker-list'
    ficha_texto 'El resto de los flags los pone el wrapper delegado y su propia ficha los explica.'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'La de reassign-partitions, que sale a continuación. Cuando cada partición diga "is completed", el broker excluido ya no guarda nada de este tópico y se puede detener.'
    ficha_warn 'Drenar copia datos por la red entre brokers mientras el clúster atiende. Y drena solo ESTE tópico: si el broker tiene réplicas de otros, hay que drenar cada uno.'
    ficha_cerrar
    ficha_nota 'En el lab el trabajo lo hace reassign-partitions.sh dentro del contenedor.'
    echo ''
fi

echo -e "${CYAN}[Drenar] Moviendo ${TOPIC} a brokers ${REMAINING} (excluye el resto)${NC}"
# El '| cat' no es decorativo y no se borra: sin él, el wrapper delegado
# encuentra un TTY y dibuja SU ficha completa aquí en medio, repitiendo lo que
# esta ya explicó. Con el tubo, ficha_activa da falso y solo sale su salida
# útil, byte a byte igual que antes (los colores de common.sh no dependen del
# TTY, así que no se pierde ninguno).
"$(dirname "$0")/reassign-partitions.sh" "$TOPIC" "$REMAINING" | cat
echo -e "${GREEN}✓ Particiones drenadas. El broker excluido ya puede detenerse:${NC}"
echo -e "${CYAN}  docker compose -f infra/docker-compose.yml --profile scale stop kafka-broker-4${NC}"
