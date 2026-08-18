#!/bin/bash
# ============================================================
# NovaTech Logistics - Lab 08b: Validador del alumno
#
# Mira el estado ACTUAL de tu laboratorio y te dice donde estas.
# No destruye nada, no crea topicos, no reinicia servicios: solo lee.
#
# Autocontenido a proposito (aserciones aqui adentro, sin depender de
# tests/): si te llevas la carpeta de este lab suelta, el validador va
# dentro (tests/CONVENCIONES-TEST.md).
# ============================================================
#
# Portabilidad exigida: macOS bash 3.2 y Git Bash (MSYS). Sin arreglos
# asociativos, sin lectura masiva a arreglo, sin PCRE en grep, sin edicion
# en sitio con sed, sin jq.

# shellcheck source=/dev/null
source "$(dirname "$0")/common.sh"

OK=0
FALLA=0
PENDIENTE=0

pasa()      { OK=$((OK + 1));        echo -e "  ${GREEN}✓${NC} $1"; }
falla()     { FALLA=$((FALLA + 1));  echo -e "  ${RED}✗${NC} $1"; [ -n "${2:-}" ] && echo -e "    ${CYAN}→ $2${NC}"; }
pendiente() { PENDIENTE=$((PENDIENTE + 1)); echo -e "  ${YELLOW}○${NC} $1"; [ -n "${2:-}" ] && echo -e "    ${CYAN}→ $2${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}=== Lab 08b · donde estoy ===${NC}"
echo ""

# ── El servidor ──────────────────────────────────────────────
echo -e "${BOLD}El servidor RHEL${NC}"

if ! rhel_arriba; then
    falla "el contenedor ${CONTENEDOR} no esta corriendo" \
          "levantalo con: bin/start-lab.sh"
    echo ""
    echo -e "${RED}Sin el servidor arriba no puedo revisar nada mas.${NC}"
    echo ""
    exit 1
fi
pasa "el contenedor ${CONTENEDOR} esta corriendo"

ESTADO_SYSTEMD="$(docker exec "$CONTENEDOR" systemctl is-system-running 2>/dev/null || true)"
case "$ESTADO_SYSTEMD" in
    running|degraded) pasa "systemd operativo (estado: ${ESTADO_SYSTEMD})" ;;
    *)                falla "systemd no esta operativo (estado: ${ESTADO_SYSTEMD:-sin respuesta})" \
                            "reinicia con: bin/reset-lab.sh && bin/start-lab.sh" ;;
esac

RELEASE="$(en_rhel 'cat /etc/redhat-release' 2>/dev/null || true)"
case "$RELEASE" in
    *"Red Hat Enterprise Linux release 9"*) pasa "el sistema es RHEL 9: ${RELEASE}" ;;
    *)                                      falla "no reconozco el sistema: ${RELEASE:-sin respuesta}" ;;
esac

# ── El paquete ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}El paquete instalado con yum${NC}"

PKG="$(en_rhel 'rpm -q confluent-kafka' 2>/dev/null || true)"
case "$PKG" in
    confluent-kafka-*) pasa "paquete instalado: ${PKG}" ;;
    *)                 falla "confluent-kafka no esta instalado (${PKG:-sin respuesta})" \
                             "reconstruye con: bin/reset-lab.sh && bin/start-lab.sh" ;;
esac

# La version esperada sale del .env del lab, no escrita a mano aqui: si el
# lab cambia de version, este chequeo la sigue sola.
VERSION_ESPERADA="$(grep '^KAFKA_VERSION=' "$ENV_FILE" | cut -d= -f2 | tr -d ' \r')"
if [ -z "$VERSION_ESPERADA" ]; then
    falla "no pude leer KAFKA_VERSION de infra/.env" "revisa que el archivo exista"
else
    case "$PKG" in
        "confluent-kafka-${VERSION_ESPERADA}-"*)
            pasa "la version calza con la del curso (${VERSION_ESPERADA})" ;;
        *)
            falla "la version instalada no es la del curso (esperaba ${VERSION_ESPERADA})" \
                  "sin el pin, las salidas dejan de calzar con las del lab 01" ;;
    esac
fi

# Los comandos que el paquete promete contra los que estan en el PATH. El
# numero esperado se deriva del propio RPM, no se escribe a mano: si el
# paquete cambia, el chequeo sigue siendo valido.
# No se cuentan archivos: se comprueba que CADA comando que el paquete declara
# este realmente ahi y sea ejecutable. Contar con `ls /usr/bin/kafka-*` no
# sirve -- un binario renombrado a kafka-topics.roto sigue entrando en ese
# glob y el conteo da 40 igual. Se probo: con esa version, esconder
# kafka-topics dejaba el chequeo en verde.
BIN_DECLARADOS="$(en_rhel "rpm -ql confluent-kafka | grep -c '^/usr/bin/kafka-'" 2>/dev/null | tr -d ' \r' || true)"
BIN_FALTANTES="$(en_rhel "rpm -ql confluent-kafka | grep '^/usr/bin/kafka-' | while read -r f; do [ -x \"\$f\" ] || echo \"\$f\"; done | grep -c ." 2>/dev/null | tr -d ' \r' || true)"
if [ -z "$BIN_DECLARADOS" ] || [ "$BIN_DECLARADOS" = "0" ]; then
    falla "el RPM no declara comandos kafka-* (leido: '${BIN_DECLARADOS:-vacio}')" \
          "si esto sale vacio, el chequeo de abajo no probaria nada"
elif [ "$BIN_FALTANTES" = "0" ]; then
    pasa "los ${BIN_DECLARADOS} comandos kafka-* del paquete estan y son ejecutables"
else
    falla "faltan ${BIN_FALTANTES} de los ${BIN_DECLARADOS} comandos kafka-* que declara el paquete" \
          "reconstruye con: bin/reset-lab.sh && bin/start-lab.sh"
fi

# ── La configuracion ─────────────────────────────────────────
echo ""
echo -e "${BOLD}La configuracion${NC}"

if en_rhel "test -f ${RUTA_CONF}" 2>/dev/null; then
    pasa "existe ${RUTA_CONF}, y es un archivo de verdad que puedes editar con vi"
else
    falla "no existe ${RUTA_CONF}" "reconstruye con: bin/reset-lab.sh && bin/start-lab.sh"
fi

LOG_DIRS="$(en_rhel "grep '^log.dirs=' ${RUTA_CONF} | cut -d= -f2" 2>/dev/null | tr -d ' \r' || true)"
if [ "$LOG_DIRS" = "$RUTA_DATOS" ]; then
    pasa "log.dirs apunta a ${RUTA_DATOS}, que es el volumen persistente"
else
    pendiente "log.dirs todavia apunta a ${LOG_DIRS:-<sin valor>}" \
              "en el momento 2 lo cambias a ${RUTA_DATOS}; asi los datos sobreviven al reinicio"
fi

if en_rhel "test -f ${RUTA_UNIDAD}" 2>/dev/null; then
    pasa "existe la unidad de systemd ${RUTA_UNIDAD}"
else
    falla "no existe la unidad ${RUTA_UNIDAD}"
fi

# ── El arranque ──────────────────────────────────────────────
echo ""
echo -e "${BOLD}El arranque${NC}"

if en_rhel "test -f ${RUTA_DATOS}/meta.properties" 2>/dev/null; then
    pasa "el almacenamiento esta formateado (hay meta.properties)"
else
    pendiente "el almacenamiento todavia no esta formateado" \
              "es el momento 3: kafka-storage format --cluster-id <id> --config ${RUTA_CONF}"
fi

ACTIVO="$(docker exec "$CONTENEDOR" systemctl is-active confluent-kafka 2>/dev/null || true)"
if [ "$ACTIVO" = "active" ]; then
    pasa "el servicio confluent-kafka esta activo"

    if en_rhel 'kafka-broker-api-versions --bootstrap-server localhost:9092 >/dev/null 2>&1'; then
        pasa "el broker responde en localhost:9092, sin docker exec de por medio"
        CUANTOS_TOPICOS="$(en_rhel 'kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | grep -c .' 2>/dev/null | tr -d ' \r' || echo 0)"
        echo -e "    ${CYAN}topicos visibles ahora mismo: ${CUANTOS_TOPICOS}${NC}"
    else
        falla "el servicio esta activo pero el broker no responde todavia" \
              "espera unos segundos y vuelve a correr este validador, o mira: journalctl -u confluent-kafka -n 50"
    fi
else
    # El consejo cambia segun donde estas. Si el almacenamiento ya esta
    # formateado no estas empezando: estas reanudando, y lo que falta es
    # otra cosa. La unidad viene `disabled`, asi que tras apagar el servidor
    # el broker no vuelve solo -- que es exactamente lo que pasa en un
    # servidor de verdad, y vale la pena decirlo.
    if en_rhel "test -f ${RUTA_DATOS}/meta.properties" 2>/dev/null; then
        HABILITADO="$(docker exec "$CONTENEDOR" systemctl is-enabled confluent-kafka 2>/dev/null || true)"
        pendiente "el servicio confluent-kafka no esta activo (estado: ${ACTIVO:-desconocido})" \
                  "tu servidor ya esta formateado; solo enciendelo: systemctl start confluent-kafka"
        echo -e "    ${CYAN}la unidad esta '${HABILITADO:-desconocido}': con 'systemctl enable confluent-kafka'${NC}"
        echo -e "    ${CYAN}arrancaria sola al encender el servidor, como en produccion${NC}"
    else
        pendiente "el servicio confluent-kafka no esta activo (estado: ${ACTIVO:-desconocido})" \
                  "es el momento 3: systemctl start confluent-kafka"
    fi
fi

# ── Resumen ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}=== Resumen ===${NC}"
echo -e "  ${GREEN}${OK} bien${NC} · ${YELLOW}${PENDIENTE} por hacer${NC} · ${RED}${FALLA} con problema${NC}"
echo ""

if [ "$FALLA" -gt 0 ]; then
    echo -e "${RED}Hay algo roto. Revisa las lineas con ✗ de arriba.${NC}"
    echo ""
    exit 1
fi

if [ "$PENDIENTE" -gt 0 ]; then
    echo -e "${YELLOW}El servidor esta sano y te faltan pasos del laboratorio.${NC}"
    echo -e "${CYAN}Las lineas con ○ te dicen cual sigue.${NC}"
    echo ""
    exit 0
fi

echo -e "${GREEN}${BOLD}Laboratorio completo: Kafka instalado con yum, corriendo como${NC}"
echo -e "${GREEN}${BOLD}servicio y respondiendo. Lo mismo de siempre, sin el envase.${NC}"
echo ""
