#!/bin/bash
# ============================================================
# Lab 01 - Recuperación del alumno (95)
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

echo -e "${BOLD}${YELLOW}Recuperación del Lab 01${NC}"
echo -e "Esto ${RED}reemplaza tu estado actual${NC} por uno funcional de referencia."
if [ "$AUTO" != "si" ]; then
    printf "¿Continuar? (s/N) "; read -r R
    [ "$R" = "s" ] || [ "$R" = "S" ] || { echo "Cancelado."; exit 0; }
fi

echo -e "${CYAN}[1/3] Limpiando estado actual...${NC}"
SOL="$(find soluciones -name 'docker-compose*.yml' 2>/dev/null | head -1)"
[ -n "$SOL" ] && docker compose -f "$SOL" down -v --remove-orphans >/dev/null 2>&1 || true
botar_contenedores_del_curso "95-recuperar-lab" kafka-broker || exit 1

echo -e "${CYAN}[2/3] Reconstruyendo línea base funcional...${NC}"
docker compose -f "$SOL" up -d >/dev/null 2>&1
WAITED=0
until docker exec -e KAFKA_OPTS= kafka-broker \
        kafka-broker-api-versions --bootstrap-server kafka-broker:29092 >/dev/null 2>&1 || [ "$WAITED" -ge 150 ]; do
    sleep 4; WAITED=$((WAITED+4))
done

if [ "$COMPLETO" = "si" ]; then
    echo -e "${CYAN}[extra] Aplicando pasos resueltos (--completo)...${NC}"
    echo -e "  (la solución YA es el estado final de este lab; --completo no aplica)"
fi

echo -e "${CYAN}[3/3] Verificando con el validador del lab...${NC}"
if bash bin/90-test-lab.sh; then
    echo -e "\n${GREEN}${BOLD}✓ LAB RECUPERADO — puedes continuar en la guía donde ibas${NC}"
    echo -e "${CYAN}  Tu clúster ahora es el de la solución de referencia. Si quieres reintentar la construcción manual, usa bin/reset-mi-cluster.sh y vuelve a la guía 01.${NC}"
    exit 0
else
    echo -e "\n${RED}${BOLD}✗ La recuperación no quedó sana. Pide ayuda al instructor.${NC}"
    exit 1
fi
