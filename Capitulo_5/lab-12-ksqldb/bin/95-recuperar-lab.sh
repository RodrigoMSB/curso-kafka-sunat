#!/bin/bash
# ============================================================
# Lab 12 - Recuperación del alumno (95)
# Te lleva a un estado FUNCIONAL para seguir la clase.
# ADVERTENCIA: reemplaza tu estado actual del lab.
# Uso: bin/95-recuperar-lab.sh [--si] [--completo]
# ============================================================
set -uo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
AUTO=no; COMPLETO=no
for a in "$@"; do
    [ "$a" = "--si" ] && AUTO=si
    [ "$a" = "--completo" ] && COMPLETO=si
done

echo -e "${BOLD}${YELLOW}Recuperación del Lab 12${NC}"
echo -e "Esto ${RED}reemplaza tu estado actual${NC} por uno funcional de referencia."
if [ "$AUTO" != "si" ]; then
    printf "¿Continuar? (s/N) "; read -r R
    [ "$R" = "s" ] || [ "$R" = "S" ] || { echo "Cancelado."; exit 0; }
fi

echo -e "${CYAN}[1/3] Limpiando estado actual...${NC}"
echo "s" | bash bin/reset-lab.sh >/dev/null 2>&1 || \
    docker compose -f infra/docker-compose.yml --env-file infra/.env down -v --remove-orphans >/dev/null 2>&1 || true

echo -e "${CYAN}[2/3] Reconstruyendo línea base funcional...${NC}"
bash bin/start-lab.sh >/dev/null 2>&1

if [ "$COMPLETO" = "si" ]; then
    echo -e "${CYAN}[extra] Aplicando pasos resueltos (--completo)...${NC}"
    W=0; until curl -sf --max-time 5 http://localhost:8088/info >/dev/null 2>&1 || [ "$W" -ge 150 ]; do sleep 5; W=$((W+5)); done
    for id in 1 2 3; do bash kafka-cli/produce-pedido-avro.sh "$id" 1001 "Caja premium" 10 25000.00 pendiente >/dev/null 2>&1; done
    docker exec ksqldb-cli ksql http://ksqldb-server:8088 --execute \
      "CREATE STREAM pedidos_stream (id INT, cliente_id INT, producto VARCHAR, cantidad INT, monto DOUBLE, estado VARCHAR) WITH (KAFKA_TOPIC='novatech.lab10.pedidos', VALUE_FORMAT='AVRO');" >/dev/null 2>&1
    echo -e "  ${GREEN}stream PEDIDOS_STREAM creado y datos Avro sembrados${NC}"
fi

echo -e "${CYAN}[3/3] Verificando con el validador del lab...${NC}"
if bash bin/90-test-lab.sh; then
    echo -e "\n${GREEN}${BOLD}✓ LAB RECUPERADO — puedes continuar en la guía donde ibas${NC}"

    exit 0
else
    echo -e "\n${RED}${BOLD}✗ La recuperación no quedó sana. Pide ayuda al instructor.${NC}"
    exit 1
fi
