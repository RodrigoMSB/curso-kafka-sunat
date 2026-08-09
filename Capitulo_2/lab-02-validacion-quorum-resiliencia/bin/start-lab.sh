#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 02: levantar la solucion de referencia
# ============================================================
# Este lab es de CONSTRUCCION PROPIA: el alumno arma su compose en
# mi-cluster/ siguiendo la guia, y ese es el trabajo del lab. Este script
# no lo reemplaza ni lo adelanta: levanta la solucion de referencia, y
# existe para dos consumidores que no son el alumno --
#   scripts/diagnostico/validar-ambiente.sh  (validacion del curso)
#   bin/95-recuperar-lab.sh                  (rescate en clase)
#
# Lo que destruye, lo nombra en pantalla, y solo destruye lo del curso:
# un contenedor ajeno que ocupe el nombre NO se toca (CONVENCIONES).

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROYECTO="novatech-lab02"
COMPOSE_FILE="${LAB_DIR}/soluciones/docker-compose-3-brokers.SOLUCION.yml"
CONTENEDORES="kafka-broker-1 kafka-broker-2 kafka-broker-3"

# ── 1. Bajar otros labs del curso que esten arriba ──────────
# Comparten container_name (deuda declarada), asi que dos labs a la vez
# no pueden convivir. Se baja por PROYECTO, nunca por patron de nombre.
OTROS=$(docker ps --format '{{.Label "com.docker.compose.project"}}' 2>/dev/null \
        | sort -u | grep '^novatech-lab' | grep -v "^${PROYECTO}$" || true)
for p in $OTROS; do
    echo -e "${YELLOW}[start-lab] bajando el proyecto ${p} (otro lab del curso esta arriba)${NC}"
    docker compose -p "$p" down -v --remove-orphans >/dev/null 2>&1 || true
done

# ── 2. Conflictos de nombre, por etiqueta y en pantalla ─────
for c in $CONTENEDORES; do
    EXISTE=$(docker ps -a --filter "name=^${c}$" --format '{{.Names}}' 2>/dev/null | head -1)
    [ -z "$EXISTE" ] && continue
    DUENIO=$(docker inspect "$c" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null || true)
    case "$DUENIO" in
        novatech-lab*)
            echo -e "${YELLOW}[start-lab] botando ${c} (proyecto ${DUENIO})${NC}"
            docker rm -f "$c" >/dev/null 2>&1 || true
            ;;
        *)
            echo -e "${RED}[start-lab] el nombre '${c}' lo tiene un contenedor que NO es del curso.${NC}" >&2
            echo -e "${RED}            proyecto compose: ${DUENIO:-<sin etiqueta>}${NC}" >&2
            echo -e "${RED}            No se toca nada ajeno. Resolvelo a mano y volve a ejecutar:${NC}" >&2
            echo -e "${RED}              docker rm -f ${c}    # solo si ese contenedor es descartable${NC}" >&2
            exit 1
            ;;
    esac
done

# ── 3. Levantar la solucion de referencia ───────────────────
echo -e "${YELLOW}[start-lab] levantando ${PROYECTO} desde soluciones/docker-compose-3-brokers.SOLUCION.yml${NC}"
docker compose -f "$COMPOSE_FILE" -p "$PROYECTO" up -d

# Espera acotada a que el primer broker responda: sin esto, el validador
# mide el exit del 'up' y no que el lab este realmente en pie.
PRIMERO="${CONTENEDORES%% *}"
W=0
until docker exec -e KAFKA_OPTS= "$PRIMERO" \
        kafka-broker-api-versions --bootstrap-server "${PRIMERO}:29092" >/dev/null 2>&1 \
      || [ "$W" -ge 150 ]; do
    sleep 5; W=$((W+5))
done
if [ "$W" -ge 150 ]; then
    echo -e "${RED}[start-lab] ${PRIMERO} no respondio a la API en 150s.${NC}" >&2
    echo -e "${RED}            Revisa: docker logs ${PRIMERO}${NC}" >&2
    exit 1
fi

echo -e "${GREEN}[start-lab] ${PROYECTO} arriba (${PRIMERO} responde tras ${W}s)${NC}"
echo -e "${CYAN}  Esta es la solucion de referencia. Tu trabajo del lab va en mi-cluster/.${NC}"
