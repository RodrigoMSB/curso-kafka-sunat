#!/bin/bash
# ============================================================
# replicar.sh · copia el canónico a los labs que lo usan
# ============================================================
# Los labs del curso son autocontenidos por diseño: el alumno tiene que
# poder copiarse la carpeta de un lab y que funcione sola. Eso obliga a
# duplicar el motor en cada lab. Para que las copias no diverjan, el
# origen es uno solo, vive acá, y se replica desde acá.
#
# Después de replicar, cada lab tiene todo adentro y no necesita tools/
# para nada. tools/ es infraestructura de desarrollo, no dependencia de
# ejecución.
#
#   bash tools/ficha/replicar.sh             replica
#   bash tools/ficha/replicar.sh --verificar  solo comprueba los hashes
#   bash tools/ficha/replicar.sh --listar     imprime los destinos del mapa
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -uo pipefail

DIR_CANON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$DIR_CANON/../.." && pwd)"

# ── El mapa ──────────────────────────────────────────────────
# Función con case en vez de array asociativo, que bash 3.2 no soporta.
# Cada línea es "<destino relativo a la raíz>".

# Labs que llevan el motor. Son los que tienen algún wrapper con ficha.
labs_con_motor() {
    cat <<'MAPA'
Capitulo_2/lab-01-inicializacion-kraft
Capitulo_2/lab-02-validacion-quorum-resiliencia
Capitulo_3/lab-03-configuracion-brokers
Capitulo_3/lab-04-multibroker-advertised-listeners
Capitulo_3/lab-05-operacion-topicos
Capitulo_3/lab-07-pruebas-rendimiento
Capitulo_3/lab-08-brokers-en-caliente
Capitulo_4/lab-11-schema-registry
Capitulo_5/lab-12-ksqldb
Capitulo_5/lab-13-kafka-connect
MAPA
}

# Labs que llevan describe-topic.sh.
labs_describe_topic() {
    cat <<'MAPA'
Capitulo_3/lab-05-operacion-topicos
Capitulo_3/lab-07-pruebas-rendimiento
Capitulo_3/lab-08-brokers-en-caliente
Capitulo_4/lab-11-schema-registry
Capitulo_5/lab-12-ksqldb
Capitulo_5/lab-13-kafka-connect
MAPA
}

# Labs que llevan list-topics.sh. El lab-08 no lo tiene y no se le agrega,
# porque su guía nunca lo menciona.
labs_list_topics() {
    cat <<'MAPA'
Capitulo_3/lab-05-operacion-topicos
Capitulo_3/lab-07-pruebas-rendimiento
Capitulo_4/lab-11-schema-registry
Capitulo_5/lab-12-ksqldb
Capitulo_5/lab-13-kafka-connect
MAPA
}

# Labs de las sesiones 1 a 3. Los cuatro tienen el mismo archivo.
labs_verify_storage() {
    cat <<'MAPA'
Capitulo_2/lab-01-inicializacion-kraft
Capitulo_2/lab-02-validacion-quorum-resiliencia
Capitulo_3/lab-03-configuracion-brokers
Capitulo_3/lab-04-multibroker-advertised-listeners
MAPA
}

# check-quorum.sh vive en los mismos 4 labs que verify-storage.
labs_check_quorum() {
    labs_verify_storage
}

# Los wrappers de kafka-cli/ de las sesiones 1 a 3, en los mismos 4 labs.
labs_kafka_cli_01_04() {
    labs_verify_storage
}

sha() {
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

N_COPIAS=0
N_MAL=0

copiar() {
    local origen="$1" destino="$2"
    if [ ! -d "$(dirname "$destino")" ]; then
        printf 'FALTA EL DIRECTORIO %s\n' "$(dirname "$destino")" >&2
        N_MAL=$(( N_MAL + 1 ))
        return 1
    fi
    cp "$origen" "$destino"
    chmod +x "$destino"
    N_COPIAS=$(( N_COPIAS + 1 ))
}

# Imprime cada destino sin tocar nada. Sirve para que los tests deriven
# la cantidad de copias del mapa y no de una constante escrita a mano,
# que se pone roja cada vez que el mapa crece.
listar() {
    printf '%s\n' "${2#$RAIZ/}"
}

verificar() {
    local origen="$1" destino="$2" a b
    a=$(sha "$origen")
    b=$(sha "$destino")
    if [ -z "$b" ]; then
        printf '  FALTA    %s\n' "${destino#$RAIZ/}"
        N_MAL=$(( N_MAL + 1 ))
        return 1
    fi
    if [ "$a" != "$b" ]; then
        printf '  DIVERGE  %s\n' "${destino#$RAIZ/}"
        N_MAL=$(( N_MAL + 1 ))
        return 1
    fi
    printf '  igual    %s\n' "${destino#$RAIZ/}"
    N_COPIAS=$(( N_COPIAS + 1 ))
}

# El motor se importa desde common.sh. Es la única modificación que este
# script hace sobre un archivo que ya existía en el lab, y por eso va
# declarada acá y es idempotente.
enganchar_common() {
    local common="$1"
    if [ ! -f "$common" ]; then
        return 0
    fi
    if grep -q 'ficha.sh' "$common"; then
        return 0
    fi
    cat >> "$common" <<'ENGANCHE'

# ── Motor de ficha didáctica ──
# Se importa si está presente. El `if` es a propósito: si el lab viaja
# suelto sin ficha.sh, los wrappers viejos siguen funcionando igual.
FICHA_LIB="$(dirname "${BASH_SOURCE[0]}")/ficha.sh"
if [ -f "$FICHA_LIB" ]; then
    source "$FICHA_LIB"
fi
ENGANCHE
    printf '  enganchado  %s\n' "${common#$RAIZ/}"
}

recorrer() {
    local accion="$1" lab

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/ficha.sh" "$RAIZ/$lab/bin/ficha.sh"
        "$accion" "$DIR_CANON/flags.sh" "$RAIZ/$lab/bin/flags.sh"
        if [ "$accion" = "copiar" ]; then
            enganchar_common "$RAIZ/$lab/bin/common.sh"
        fi
    done <<EOF
$(labs_con_motor)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/describe-topic.sh" \
                  "$RAIZ/$lab/kafka-cli/describe-topic.sh"
    done <<EOF
$(labs_describe_topic)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/list-topics.sh" \
                  "$RAIZ/$lab/kafka-cli/list-topics.sh"
    done <<EOF
$(labs_list_topics)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/verify-storage.sh" \
                  "$RAIZ/$lab/bin/verify-storage.sh"
    done <<EOF
$(labs_verify_storage)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/check-quorum.sh" \
                  "$RAIZ/$lab/bin/check-quorum.sh"
    done <<EOF
$(labs_check_quorum)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/generate-cluster-id.sh" \
                  "$RAIZ/$lab/kafka-cli/generate-cluster-id.sh"
    done <<EOF
$(labs_kafka_cli_01_04)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/format-storage.sh" \
                  "$RAIZ/$lab/kafka-cli/format-storage.sh"
    done <<EOF
$(labs_kafka_cli_01_04)
EOF

    while IFS= read -r lab; do
        [ -z "$lab" ] && continue
        "$accion" "$DIR_CANON/wrappers/inspect-image.sh" \
                  "$RAIZ/$lab/kafka-cli/inspect-image.sh"
    done <<EOF
$(labs_kafka_cli_01_04)
EOF
}

case "${1:-}" in
    --listar)
        recorrer listar
        ;;
    --verificar)
        echo 'Verificando que ninguna copia haya divergido del canónico'
        recorrer verificar
        echo ''
        if [ "$N_MAL" -gt 0 ]; then
            printf '  %s copias iguales, %s CON PROBLEMAS\n\n' "$N_COPIAS" "$N_MAL"
            exit 1
        fi
        printf '  %s copias, todas idénticas al canónico\n\n' "$N_COPIAS"
        ;;
    *)
        echo 'Replicando el canónico a los labs'
        recorrer copiar
        echo ''
        printf '  %s archivos copiados\n\n' "$N_COPIAS"
        [ "$N_MAL" -gt 0 ] && exit 1
        ;;
esac
exit 0
