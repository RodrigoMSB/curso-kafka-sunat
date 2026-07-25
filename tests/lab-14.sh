#!/bin/bash
# E2E instructor · Lab 14 - Capstone (seguridad TLS+SASL+ACL + resiliencia)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-14-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 14"; exit 1; }

trap 'lab_teardown "$LAB_DIR"' EXIT

test_start "Lab 14 - Capstone (seguridad + resiliencia)"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh kafka-cli/*.sh infra/scripts/*.sh 2>/dev/null

BOOT="kafka-broker-1:9092"
TOPIC="novatech.lab12.confidencial"
APP1="/etc/kafka/client-properties/app1.properties"
APP2="/etc/kafka/client-properties/app2.properties"
ADMIN="/etc/kafka/client-properties/admin.properties"

# Producir marcas [s..e] como app1 (acks=all) al canal seguro
prod() {  # <start> <end>
    local s="$1" e="$2" i
    for i in $(seq "$s" "$e"); do echo "${MARK}-${i}"; done | \
        MSYS_NO_PATHCONV=1 docker exec -i -e KAFKA_OPTS= cli-client kafka-console-producer \
        --bootstrap-server "$BOOT" --command-config "$APP1" \
        --command-property acks=all --topic "$TOPIC" 2>/dev/null
}
# Contar MIS marcas leídas como admin (ground truth)
count_admin() {
    MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client bash -c \
        "kafka-console-consumer --bootstrap-server $BOOT --command-config $ADMIN --topic $TOPIC --from-beginning --timeout-ms 8000 2>/dev/null | grep -c '^${MARK}-'"
}
# Menor tamaño de ISR entre las particiones del tópico
isr_min() {
    MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-topics \
        --bootstrap-server "$BOOT" --command-config "$ADMIN" --describe --topic "$TOPIC" 2>/dev/null \
        | grep -oE 'Isr: [0-9,]+' | sed 's/Isr: //' | awk -F, '{print NF}' | sort -n | head -1
}

bash bin/start-lab.sh >/dev/null 2>&1
# El clúster seguro (TLS+PKI) es el más pesado; más margen para hosts cargados.
wait_for_brokers 3 240 || abort_test "clúster seguro no subió (3 brokers no healthy en 240s)"
_pass "clúster seguro arriba (TLS+SASL+ACL, 3 brokers)"

MARK="$(new_mark)"

# 1. POSITIVO: app1 produce 5, admin lee 5
prod 1 5
assert_eq 5 "$(count_admin)" "positivo: admin lee las 5 marcas producidas por app1"

# 2. NEGATIVO (la joya): app2 NO puede leer confidencial. Se lee el stderr REAL
#    del consumidor (no el stdout del script del lab, que incluye la palabra en su ayuda).
DENY=$(MSYS_NO_PATHCONV=1 docker exec -e KAFKA_OPTS= cli-client kafka-console-consumer \
    --bootstrap-server "$BOOT" --command-config "$APP2" \
    --topic "$TOPIC" --from-beginning --timeout-ms 5000 2>&1 || true)
if echo "$DENY" | grep -qiE 'TopicAuthorizationException|not authorized'; then AUTHZ="denegado"; else AUTHZ="permitido"; fi
assert_eq "denegado" "$AUTHZ" "negativo: app2 es DENEGADO al leer confidencial (ACL efectiva)"

# 3. FAILOVER sin pérdida: cae broker-3, se produce durante el fallo, se recupera, total=10
bash kafka-cli/simulate-failure.sh 3 >/dev/null 2>&1
W=0; until [ "$(isr_min 2>/dev/null || echo 3)" -le 2 ] || [ "$W" -ge 40 ]; do sleep 4; W=$((W+4)); done
ISRM=$(isr_min); [ "${ISRM:-3}" -le 2 ] && RED_OK="yes" || RED_OK="no"
assert_eq "yes" "$RED_OK" "el ISR se reduce a <=2 tras caer un broker (min ISR=${ISRM})"

prod 6 10   # producción DURANTE el fallo (ISR=2 >= min.insync=2, sin downtime)
bash kafka-cli/recover-broker.sh 3 >/dev/null 2>&1
wait_for_brokers 3 || abort_test "broker-3 no se recuperó"
assert_eq 10 "$(count_admin)" "failover sin pérdida: 10/10 marcas presentes tras recuperar"

# 4. run-capstone.sh corre entero y reporta 20
CAPOUT=$(bash bin/run-capstone.sh 2>&1); CAPRC=$?
assert_success "$CAPRC" "run-capstone.sh termina con éxito (exit 0)"
assert_contains "$CAPOUT" "totales: 20" "run-capstone reporta 20 mensajes (cero pérdida)"
wait_for_brokers 3 || abort_test "clúster no volvió a 3 brokers tras run-capstone"

# El 90 del alumno también debe aprobar sobre el lab vivo.
# Tras el restart de broker-3 por run-capstone, el listener seguro tarda unos
# segundos en atender ops de admin/ACL aunque Docker ya reporte healthy: reintento acotado.
NINETY=1; W=0
while [ "$W" -lt 40 ]; do
    if bash bin/90-test-lab.sh >/dev/null 2>&1; then NINETY=0; break; fi
    sleep 6; W=$((W+6))
done
assert_eq 0 "$NINETY" "el validador del alumno (90) aprueba sobre el lab vivo"

test_end; exit $?
