#!/bin/bash
# E2E instructor · Lab 09 - Clientes Java/Spring
# Requiere JDK 21 + Maven en el host (las apps corren en el host contra localhost:9092-94).
# Si faltan, imprime N/A y sale 0 (no rompe run-all en máquinas sin Java).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 09)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-09-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 09"; exit 1; }

# Chequeo de prerequisitos: sin JDK/Maven -> N/A explícito
if ! command -v java >/dev/null 2>&1 || ! command -v mvn >/dev/null 2>&1; then
    echo -e "\033[1;33m━━━ E2E N/A · Lab 09 · falta JDK/Maven en el host (se omite) ━━━\033[0m"
    exit 0
fi

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 09 - Clientes Java/Spring"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh infra/scripts/*.sh 2>/dev/null

BOOT="kafka-broker-1:29092"
TOPIC="novatech.lab09.pedidos"

bash bin/start-lab.sh >/dev/null 2>&1
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
_pass "clúster arriba (3 brokers healthy)"

# Compilación de ambos proyectos
mvn -q -f cliente-java/pom.xml compile >/dev/null 2>&1
assert_success $? "cliente-java compila (mvn compile)"

mvn -q -f cliente-spring/pom.xml compile >/dev/null 2>&1
assert_success $? "cliente-spring compila (mvn compile)"

# Interop: ProductorApp (Java) produce 10 pedidos al tópico; se cuentan por consumo
mvn -q -f cliente-java/pom.xml exec:java \
    -Dexec.mainClass=com.novatech.kafka.ProductorApp -Dexec.args=10 >/dev/null 2>&1
GOT=$(docker exec kafka-broker-1 bash -c \
    "kafka-console-consumer --bootstrap-server $BOOT --topic $TOPIC --from-beginning --timeout-ms 10000 2>/dev/null | grep -c ." )
assert_ge "$GOT" 10 "ProductorApp produjo >=10 pedidos verificados por consumo ($GOT)"

# El 90 del alumno también debe aprobar sobre el clúster vivo
bash bin/90-test-lab.sh >/dev/null 2>&1
assert_success $? "el validador del alumno (90) aprueba sobre el lab vivo"

test_end; exit $?
