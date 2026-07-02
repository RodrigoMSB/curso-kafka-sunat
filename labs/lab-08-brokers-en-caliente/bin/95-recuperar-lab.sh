#!/bin/bash
# ============================================================
# Lab 08 - Recuperación del alumno (95)
# Te lleva a un estado FUNCIONAL para seguir la clase.
# ADVERTENCIA: reemplaza tu estado actual del lab.
# Uso: bin/95-recuperar-lab.sh [--si] [--completo]
# ============================================================
set -uo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")/.." && pwd)"; cd "$LAB_DIR"
AUTO=no; COMPLETO=no
for a in "$@"; do
    [ "$a" = "--si" ] && AUTO=si
    [ "$a" = "--completo" ] && COMPLETO=si
done

echo -e "${BOLD}${YELLOW}Recuperación del Lab 08${NC}"
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
    echo -e "  (este lab no tiene pasos --completo; la línea base ya es el estado final)"
fi

echo -e "${CYAN}[3/3] Verificando con el validador del lab...${NC}"
if bash bin/90-test-lab.sh; then
    echo -e "\n${GREEN}${BOLD}✓ LAB RECUPERADO — puedes continuar en la guía donde ibas${NC}"
    echo -e "${CYAN}  El broker-4 no forma parte de la línea base: se agrega en la guía 03 con kafka-cli/add-broker.sh.${NC}"
    exit 0
else
    echo -e "\n${RED}${BOLD}✗ La recuperación no quedó sana. Pide ayuda al instructor.${NC}"
    exit 1
fi
