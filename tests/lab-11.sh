#!/bin/bash
# E2E instructor · Lab 11 - Schema Registry (Avro)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"

# Proyecto propio del e2e. Sin esto el alcance de un down -v lo da el
# nombre del directorio y puede alcanzar a un despliegue ajeno.
PROY="$(proyecto_e2e 11)"
export COMPOSE_PROJECT_NAME="$PROY"

LAB_DIR=""
for d in "$HERE"/../Capitulo_*/lab-11-*; do [ -d "$d" ] && LAB_DIR="$(cd "$d" && pwd)" && break; done
[ -n "$LAB_DIR" ] || { echo "No encuentro la carpeta del lab 11"; exit 1; }

trap 'lab_teardown "$LAB_DIR" "$PROY"' EXIT

test_start "Lab 11 - Schema Registry (Avro)"

cd "$LAB_DIR"
set -a; source infra/.env; set +a
chmod +x bin/*.sh kafka-cli/*.sh schema-cli/*.sh infra/scripts/*.sh 2>/dev/null

SR_PORT="8081"
TOPIC="novatech.lab10.pedidos"
SUBJECT="novatech.lab10.pedidos-value"

levantar_lab "$LAB_DIR" || abort_test "no se pudo levantar el entorno del lab"
wait_for_brokers 3 || abort_test "clúster no subió (3 brokers no healthy en 150s)"
wait_for_container schema-registry 120 || abort_test "Schema Registry no llegó a healthy"
_pass "clúster + Schema Registry arriba"

# 1. SR responde /subjects
curl -sf "http://localhost:${SR_PORT}/subjects" >/dev/null 2>&1
assert_success $? "Schema Registry responde /subjects en :${SR_PORT}"

# 2. Producir Avro con el script del lab (auto-registra el schema) — 3 pedidos
for id in 1 2 3; do
    bash kafka-cli/produce-pedido-avro.sh "$id" 1001 "Caja premium" 10 25000.00 pendiente >/dev/null 2>&1
done
SUBJECTS=$(curl -sf "http://localhost:${SR_PORT}/subjects" 2>/dev/null || true)
assert_contains "$SUBJECTS" "$SUBJECT" "el schema ${SUBJECT} quedó registrado tras producir Avro"

# 3. Consumir Avro deserializado (consumer con timeout; consume-avro.sh es interactivo)
GOT=$(docker exec -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
    schema-registry bash -c \
    "kafka-avro-console-consumer --bootstrap-server kafka-broker-1:29092 --topic $TOPIC --from-beginning --timeout-ms 10000 --property schema.registry.url=http://schema-registry:8081 2>/dev/null | grep -c cliente_id")
assert_ge "$GOT" 1 "consumo Avro deserializado devuelve registros ($GOT)"

# El 90 del alumno también debe aprobar sobre el lab vivo
# La salida del validador del alumno NO se tira: si el 90 aprueba diciendo
# algo falso, o falla, el e2e tiene que mostrarlo. Era el ultimo vector de
# verde con material roto (SPEC-66 F1).
SALIDA_90=$(bash bin/90-test-lab.sh 2>&1); RC90=$?
printf '%s\n' "$SALIDA_90"
assert_success "$RC90" "el validador del alumno (90) aprueba sobre el lab vivo"
assert_contains "$SALIDA_90" "LAB EN BUEN ESTADO" "el 90 imprime su linea de conteo (se lee, no se asume)"

test_end; exit $?
