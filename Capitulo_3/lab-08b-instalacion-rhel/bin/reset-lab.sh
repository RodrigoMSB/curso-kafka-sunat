#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 08b: Reiniciar laboratorio desde cero
# ============================================================

echo -e "${YELLOW}[NovaTech] Reiniciando el lab 08b desde cero...${NC}"
echo -e "${CYAN}  QUE HACE:    borra el contenedor y el volumen de datos del lab 08b.${NC}"
echo -e "${CYAN}  CONSERVA:    la guia, tus notas y todo archivo del lab en disco.${NC}"
echo -e "${CYAN}  DESTRUYE:    el broker formateado y sus topicos. Solo de ${PROYECTO}.${NC}"
echo -e "${CYAN}  CUANDO:      para volver a empezar el lab con el servidor recien instalado.${NC}"
echo ""

# El alcance del `down -v` lo da el PROYECTO, no el archivo: por eso el -p
# explicito (tests/CONVENCIONES-TEST.md). Sin el, el proyecto sale del nombre
# del directorio y puede alcanzar volumenes que no son de este lab.
compose down -v --remove-orphans

echo ""
echo -e "${GREEN}✓ Lab 08b reiniciado. La imagen se conserva: el proximo arranque no${NC}"
echo -e "${GREEN}  vuelve a descargar los paquetes.${NC}"
echo -e "${CYAN}  Para levantarlo: bin/start-lab.sh${NC}"
