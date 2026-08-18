#!/bin/bash
set -euo pipefail

# La biblioteca del lab, primero: exporta MSYS_NO_PATHCONV, sin la cual
# Git Bash convierte toda ruta absoluta en ruta de Windows antes de que
# docker la vea -- incluida la del "-f <ruta>/docker-compose.yml".
# La guardia vive en la biblioteca, nunca inline (tests/CONVENCIONES-TEST.md).
# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

# ============================================================
# NovaTech Logistics - Lab 08b: Iniciar laboratorio
#
# Levanta un servidor RHEL 9 con Kafka INSTALADO y APAGADO.
# Encenderlo es el laboratorio, no el arranque: si este script dejara el
# broker corriendo, se comeria el momento 3 de la guia.
# ============================================================

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║     ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗                 ║"
echo "║     ████╗  ██║██╔═══██╗██║   ██║██╔══██╗                ║"
echo "║     ██╔██╗ ██║██║   ██║██║   ██║███████║                ║"
echo "║     ██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║                ║"
echo "║     ██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║                ║"
echo "║     ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝                ║"
echo "║              T E C H   L O G I S T I C S                ║"
echo "║                                                          ║"
echo "║     Lab 08b: Kafka sobre RHEL 9, sin Docker adelante     ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] Docker no esta corriendo. Inicia Docker Desktop.${NC}"
    exit 1
fi

# ── Reanudar o instalar de cero ──────────────────────────────
# Este lab NO puede recrear el contenedor a ciegas. El trabajo del alumno
# vive DENTRO del contenedor: el /etc/kafka/server.properties que edita en
# el momento 2 esta en la capa del contenedor, no en un volumen. Un
# `down` lo borra y lo devuelve al archivo de fabrica, dejando ademas el
# volumen formateado apuntando a ninguna parte -- el servicio ya no
# arranca y el alumno no entiende por que.
#
# Se probo: tras stop-lab.sh + start-lab.sh con `down`, server.properties
# volvia a log.dirs=/tmp/kraft-combined-logs y confluent-kafka quedaba en
# `failed`. Por eso start-lab reanuda si el servidor ya existe, y solo
# construye cuando no hay nada. Para volver a cero esta reset-lab.sh, que
# lo dice en su nombre.
MODO="instalar"
DUENIO_ACTUAL=""
if docker ps -a --filter "name=^${CONTENEDOR}$" --format '{{.Names}}' 2>/dev/null | grep -q "$CONTENEDOR"; then
    DUENIO_ACTUAL="$(docker inspect "$CONTENEDOR" \
        --format "{{index .Config.Labels \"com.docker.compose.project\"}}" 2>/dev/null || true)"
    [ "$DUENIO_ACTUAL" = "$PROYECTO" ] && MODO="reanudar"
fi

if [ "$MODO" = "reanudar" ]; then
    echo -e "${YELLOW}[1/3] El servidor ya existe: se reanuda tal como lo dejaste.${NC}"
    echo -e "${CYAN}      Tu ${RUTA_CONF} y tus datos siguen como estaban.${NC}"
    echo -e "${CYAN}      Para volver al servidor recien instalado: bin/reset-lab.sh${NC}"
    echo ""
    echo -e "${YELLOW}[2/3] Encendiendo el servidor...${NC}"
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" -p "$PROYECTO" start
else
    echo -e "${YELLOW}[1/3] Preparando el terreno...${NC}"
    # Solo llega aqui si NO hay un contenedor nuestro. Si el nombre lo tiene
    # algo ajeno, esta funcion lo dice y aborta sin tocarlo.
    botar_contenedores_del_curso "start-lab" "$CONTENEDOR" || exit 1
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" -p "$PROYECTO" \
        down --remove-orphans >/dev/null 2>&1 || true

    echo ""
    echo -e "${YELLOW}[2/3] Construyendo el servidor RHEL 9 e instalando Kafka con yum...${NC}"
    echo -e "${CYAN}      La primera vez descarga unos 255 MB y tarda algunos minutos.${NC}"
    echo -e "${CYAN}      Las siguientes reutiliza la imagen y es inmediato.${NC}"
    echo ""
    # El `up` nunca se silencia: si falla, el error tiene que verse
    # (tests/CONVENCIONES-TEST.md).
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" -p "$PROYECTO" up -d --build
fi

echo ""
echo -e "${YELLOW}[3/3] Esperando a que systemd termine de arrancar...${NC}"
if ! esperar_systemd 30; then
    echo -e "${RED}[ERROR] systemd no llego a estado operativo dentro del contenedor.${NC}" >&2
    echo -e "${RED}  Estado que reporta ahora:${NC}" >&2
    docker exec "$CONTENEDOR" systemctl is-system-running >&2 2>&1 || true
    echo -e "${RED}  Revisa los logs con:${NC}" >&2
    echo -e "${RED}    docker logs ${CONTENEDOR}${NC}" >&2
    echo "" >&2
    echo -e "${YELLOW}  Si esto ocurre en la VM del alumno y no en tu maquina, no lo${NC}" >&2
    echo -e "${YELLOW}  fuerces con --privileged: avisa antes de cambiar el compose.${NC}" >&2
    exit 1
fi
echo -e "${GREEN}  ✓ systemd operativo: $(docker exec "$CONTENEDOR" systemctl is-system-running 2>&1)${NC}"

# Se lee del sistema, no se afirma de memoria.
VERSION_RHEL="$(en_rhel 'cat /etc/redhat-release' 2>/dev/null || echo '?')"
VERSION_PKG="$(en_rhel 'rpm -q confluent-kafka' 2>/dev/null || echo '?')"
CUANTOS_BIN="$(en_rhel 'ls /usr/bin/kafka-* | wc -l' 2>/dev/null | tr -d ' ' || echo '?')"

# El estado del servicio se lee, no se supone: tras un `reanudar` el broker
# puede estar encendido o no, y afirmar "apagado" seria mentirle al alumno.
ESTADO_SERVICIO="$(docker exec "$CONTENEDOR" systemctl is-active confluent-kafka 2>/dev/null || true)"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
if [ "$MODO" = "reanudar" ]; then
    echo -e "${GREEN}${BOLD}  SERVIDOR RHEL 9 REANUDADO${NC}"
else
    echo -e "${GREEN}${BOLD}  SERVIDOR RHEL 9 OPERATIVO - KAFKA RECIEN INSTALADO${NC}"
fi
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}  Sistema:${NC}    ${VERSION_RHEL}"
echo -e "${CYAN}  Paquete:${NC}    ${VERSION_PKG}"
echo -e "${CYAN}  Comandos:${NC}   ${CUANTOS_BIN} binarios kafka-* en /usr/bin"
echo -e "${CYAN}  Servicio:${NC}   confluent-kafka esta ${BOLD}${ESTADO_SERVICIO:-desconocido}${NC}"
echo ""
if [ "$ESTADO_SERVICIO" = "active" ]; then
    echo -e "${CYAN}  El broker esta encendido y respondiendo.${NC}"
else
    echo -e "${CYAN}  El broker todavia NO esta encendido, y eso es a proposito:${NC}"
    echo -e "${CYAN}  formatear el almacenamiento y arrancar el servicio es el lab.${NC}"
fi
echo ""
echo -e "${CYAN}  Entra al servidor:${NC}"
echo -e "    ${BOLD}docker exec -it ${CONTENEDOR} bash${NC}"
echo ""
echo -e "${CYAN}  Ese es el unico 'docker' de todo el laboratorio. De ahi en${NC}"
echo -e "${CYAN}  adelante los comandos son los mismos de los labs 01 y 02.${NC}"
echo ""
echo -e "${CYAN}  Donde estoy:${NC}         ${BOLD}bin/90-test-lab.sh${NC}"
echo -e "${CYAN}  Detener:${NC}             ${BOLD}bin/stop-lab.sh${NC}"
echo -e "${CYAN}  Borrar y empezar de cero:${NC} ${BOLD}bin/reset-lab.sh${NC}"
echo ""
echo -e "${YELLOW}  Abre la guia: guia/01-kafka-sin-docker.md${NC}"
echo ""
