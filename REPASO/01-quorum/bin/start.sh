#!/bin/bash
# REPASO 01 · levanta el cluster de tres nodos del repaso del quorum.
set -uo pipefail

VERDE='\033[0;32m'; AMARILLO='\033[1;33m'; ROJO='\033[0;31m'; NC='\033[0m'
AQUI="$(cd "$(dirname "$0")" && pwd)"
INFRA="$AQUI/../infra"
PROYECTO="repaso-01-quorum"

# En Git Bash, docker.exe no entiende la ruta /c/... que devuelve pwd, asi que
# se entra al directorio y se usan nombres relativos. El cd es un builtin del
# shell, de modo que la ruta absoluta se resuelve aqui y nunca cruza a docker.
compose() { ( cd "$INFRA" && docker compose -p "$PROYECTO" "$@" ); }

echo -e "${AMARILLO}[repaso-01] levantando tres nodos KRaft (proyecto ${PROYECTO})${NC}"
compose up -d || { echo -e "${ROJO}[repaso-01] no pude levantar el clúster.${NC}" >&2; exit 1; }

echo -e "${AMARILLO}[repaso-01] esperando a que los tres respondan...${NC}"
listo=0
for i in $(seq 1 60); do
    vivos=0
    for n in 1 2 3; do
        docker exec "repaso-quorum-${n}" \
            kafka-broker-api-versions --bootstrap-server "repaso-quorum-${n}:$((29091 + n))" \
            >/dev/null 2>&1 && vivos=$((vivos + 1))
    done
    if [ "$vivos" -eq 3 ]; then listo=1; break; fi
    sleep 2
done

if [ "$listo" -ne 1 ]; then
    echo -e "${ROJO}[repaso-01] los tres nodos no llegaron a responder.${NC}" >&2
    echo -e "${ROJO}            Mira los registros con: docker logs repaso-quorum-1${NC}" >&2
    exit 1
fi

echo -e "${VERDE}[repaso-01] los tres nodos responden. El clúster está listo.${NC}"
echo
echo "  Nodos      repaso-quorum-1, repaso-quorum-2, repaso-quorum-3"
echo "  Puertos    19092, 19093, 19094  (no chocan con ningun laboratorio)"
echo
echo "  Abre la guia: REPASO/01-quorum/README.md"
