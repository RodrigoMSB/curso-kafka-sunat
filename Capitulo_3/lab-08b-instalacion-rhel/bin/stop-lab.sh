#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 08b: Detener laboratorio
# Apaga el servidor conservando el volumen de datos.
# ============================================================

echo -e "${YELLOW}[NovaTech] Deteniendo el servidor RHEL (se conserva el volumen)...${NC}"
echo -e "${CYAN}  QUE HACE:    apaga el contenedor del lab 08b. No borra nada.${NC}"
echo -e "${CYAN}  CONSERVA:    el volumen con los datos del broker y todo el material.${NC}"
echo -e "${CYAN}  DESTRUYE:    nada. Solo detiene ${CONTENEDOR}.${NC}"
echo -e "${CYAN}  CUANDO:      cuando terminas por hoy y quieres liberarle memoria a Docker.${NC}"
echo ""

compose stop

echo -e "${GREEN}✓ Laboratorio detenido.${NC}"
echo -e "${CYAN}  Para reanudar: bin/start-lab.sh${NC}"
echo -e "${CYAN}  Para borrar todo (incluidos los datos): bin/reset-lab.sh${NC}"
