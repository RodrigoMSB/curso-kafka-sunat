#!/bin/bash
# REPASO 01 · baja el cluster del repaso y borra lo que creo.
set -uo pipefail

VERDE='\033[0;32m'; AMARILLO='\033[1;33m'; NC='\033[0m'
AQUI="$(cd "$(dirname "$0")" && pwd)"
INFRA="$AQUI/../infra"
PROYECTO="repaso-01-quorum"

compose() { ( cd "$INFRA" && docker compose -p "$PROYECTO" "$@" ); }

echo -e "${AMARILLO}[repaso-01] bajando el clúster y borrando sus volumenes y su red${NC}"
echo -e "${AMARILLO}            Solo se toca el proyecto ${PROYECTO}. Nada mas.${NC}"

# -v borra los volumenes de este proyecto. --remove-orphans limpia un
# contenedor que hubiera quedado de una version anterior del compose.
compose down -v --remove-orphans

restantes=$(docker ps -a --filter "label=com.docker.compose.project=${PROYECTO}" -q | wc -l | tr -d ' ')
redes=$(docker network ls --filter "label=com.docker.compose.project=${PROYECTO}" -q | wc -l | tr -d ' ')
volumenes=$(docker volume ls --filter "label=com.docker.compose.project=${PROYECTO}" -q | wc -l | tr -d ' ')

echo
echo "  contenedores del repaso que quedan   ${restantes}"
echo "  redes del repaso que quedan          ${redes}"
echo "  volumenes del repaso que quedan      ${volumenes}"

if [ "$restantes" = "0" ] && [ "$redes" = "0" ] && [ "$volumenes" = "0" ]; then
    echo -e "${VERDE}[repaso-01] tu maquina quedo como estaba.${NC}"
else
    echo -e "${AMARILLO}[repaso-01] quedo algo sin borrar. Revisa las tres cuentas de arriba.${NC}"
    exit 1
fi
