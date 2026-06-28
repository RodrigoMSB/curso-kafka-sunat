#!/bin/bash
# Genera CA + certificados de servidor para los 3 brokers Kafka.
# Usado para TLS en listener cliente (SASL_SSL://).
#
# Portabilidad: openssl corre en el host (Git Bash en Windows lo trae,
# macOS/Linux lo tienen preinstalado). keytool corre dentro de un contenedor
# eclipse-temurin:21-jdk para eliminar la dependencia de Java en el host.
#
# Compatibilidad MSYS/Git Bash en Windows:
#   - MSYS convierte automáticamente argumentos que empiezan con "/"
#     (-subj /CN=..., -keystore /certs/...) a paths Windows. Eso rompe
#     openssl y keytool.
#   - MSYS_NO_PATHCONV=1 aplicado GLOBALMENTE rompe los paths host (los
#     deja en formato /c/... en lugar de C:\...). Conclusión: usarlo
#     SOLO como prefijo de comandos puntuales que tienen -subj o args
#     /certs/...
#   - Los paths host se convierten explícitamente a formato nativo con
#     cygpath -w (que viene incluido en Git Bash) mediante to_native_path().

set -euo pipefail
source "$(dirname "$0")/common.sh"

CERTS_DIR="$(cd "$(dirname "$0")/../infra/certs" && pwd)"
PASS="${TLS_KEYSTORE_PASSWORD:-changeit}"
DAYS=3650
CN_CA="NovaTech-CA-Lab12"
KEYTOOL_IMAGE="eclipse-temurin:21-jdk"

# Directorio temporal para archivos auxiliares (ej: extensiones de openssl).
# Evitamos process substitution <(...) porque en Git Bash sobre Windows el
# /proc/PID/fd/N que genera no es accesible y openssl falla con
# "BIO_new_file: No such process".
TMPDIR_LAB12="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_LAB12"' EXIT INT TERM

# Helper portable: convierte un path POSIX a su formato nativo del sistema.
# - En Git Bash/MSYS/Cygwin: cygpath -w (`/c/foo/bar` -> `C:\foo\bar`)
# - En macOS/Linux: pasa tal cual
to_native_path() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            cygpath -w "$1"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

# Detección única para condicionar prefijos a Git Bash
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) IS_MSYS=1 ;;
    *)                    IS_MSYS=0 ;;
esac

# Wrapper: ejecuta keytool dentro de un contenedor eclipse-temurin:21-jdk
# montando $CERTS_DIR como /certs. Los paths que se pasen a keytool deben
# referirse a /certs/<archivo>, no a la ruta del host.
#
# En Git Bash, los args /certs/... serían convertidos por MSYS si no se
# protegen, así que usamos MSYS_NO_PATHCONV=1 como prefijo. El path del
# lado izquierdo de -v se convierte explícitamente con to_native_path
# para que docker reciba el formato nativo Windows.
run_keytool() {
    local host_certs
    host_certs="$(to_native_path "$CERTS_DIR")"
    if [[ "$IS_MSYS" -eq 1 ]]; then
        MSYS_NO_PATHCONV=1 docker run --rm \
            -v "$host_certs:/certs" \
            -w /certs \
            "$KEYTOOL_IMAGE" \
            keytool "$@"
    else
        docker run --rm \
            -v "$host_certs:/certs" \
            -w /certs \
            "$KEYTOOL_IMAGE" \
            keytool "$@"
    fi
}

mkdir -p "$CERTS_DIR"

# Idempotencia: si TODOS los archivos esperados existen, saltar generación.
# Si falta CUALQUIERA (ej: una corrida previa abortó a mitad por timeout,
# Ctrl+C, error de shell, etc.), limpiar y regenerar todo desde cero —
# generar parcialmente certs incompletos hace que los brokers afectados
# fallen al arrancar con NoSuchFileException sobre el .keystore.jks.
EXPECTED_FILES=(
    "ca.crt"
    "ca.key"
    "kafka.truststore.jks"
    "kafka-broker-1.keystore.jks"
    "kafka-broker-2.keystore.jks"
    "kafka-broker-3.keystore.jks"
    "cert-credentials"
)
ALL_EXIST=true
MISSING_FILES=()
for f in "${EXPECTED_FILES[@]}"; do
    if [[ ! -f "$CERTS_DIR/$f" ]]; then
        ALL_EXIST=false
        MISSING_FILES+=("$f")
    fi
done

if [[ "$ALL_EXIST" == "true" ]]; then
    echo -e "${YELLOW}Certificados completos detectados en $CERTS_DIR. Saltando generación.${NC}"
    echo -e "${YELLOW}Para regenerar: borrar el directorio infra/certs/ y volver a ejecutar.${NC}"
    exit 0
fi

# Si llegamos acá, falta al menos un archivo. Limpiar y regenerar todo.
if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Certificados incompletos detectados — falta(n): ${MISSING_FILES[*]}${NC}"
    echo -e "${YELLOW}Limpiando residuos y regenerando todo desde cero...${NC}"
    # Borrar artefactos del run anterior (no afecta a .gitkeep ni a archivos
    # que el usuario haya colocado deliberadamente con otra extensión).
    rm -f "$CERTS_DIR"/*.crt "$CERTS_DIR"/*.key "$CERTS_DIR"/*.jks \
          "$CERTS_DIR"/*.csr "$CERTS_DIR"/*.srl \
          "$CERTS_DIR/cert-credentials"
fi

# Pre-pull explícito de la imagen con feedback claro al usuario.
# Sin docker pull -q: si la red es lenta, el alumno necesita ver el progreso
# y NO debe haber timeouts que aborten la descarga.
echo -e "${CYAN}[generate-certs] Generando PKI para el Lab 12...${NC}"
echo "  [0/5] Verificando imagen $KEYTOOL_IMAGE..."
if docker image inspect "$KEYTOOL_IMAGE" > /dev/null 2>&1; then
    echo -e "${GREEN}    ✓ Imagen ya disponible localmente${NC}"
else
    echo -e "${YELLOW}    Descargando imagen (~440 MB, puede tardar 1-2 min en redes lentas)...${NC}"
    docker pull "$KEYTOOL_IMAGE"
    echo -e "${GREEN}    ✓ Imagen descargada${NC}"
fi

# 1. Crear CA root (openssl en host)
# - Paths convertidos a formato nativo (necesario en Windows)
# - MSYS_NO_PATHCONV=1 sólo en este comando, para proteger el -subj /CN=...
echo "  [1/5] Creando CA root..."
CA_KEY="$(to_native_path "$CERTS_DIR/ca.key")"
CA_CRT="$(to_native_path "$CERTS_DIR/ca.crt")"
if [[ "$IS_MSYS" -eq 1 ]]; then
    MSYS_NO_PATHCONV=1 openssl req -new -x509 \
        -keyout "$CA_KEY" -out "$CA_CRT" \
        -days $DAYS -passout pass:$PASS \
        -subj "/CN=$CN_CA/OU=Lab12/O=NovaTech/L=Santiago/C=CL"
else
    openssl req -new -x509 \
        -keyout "$CA_KEY" -out "$CA_CRT" \
        -days $DAYS -passout pass:$PASS \
        -subj "/CN=$CN_CA/OU=Lab12/O=NovaTech/L=Santiago/C=CL"
fi

# 2. Truststore: contiene la CA root, lo usan tanto brokers como clients
echo "  [2/5] Creando truststore..."
run_keytool -keystore /certs/kafka.truststore.jks -alias CARoot \
    -import -file /certs/ca.crt \
    -storepass $PASS -keypass $PASS -noprompt

# 3. Keystore por broker, firmado por la CA
for i in 1 2 3; do
    BROKER="kafka-broker-$i"
    echo "  [3/5] Generando keystore para $BROKER..."

    # 3a. Generar keypair (keytool en container)
    run_keytool -keystore /certs/$BROKER.keystore.jks -alias $BROKER \
        -genkey -keyalg RSA -storepass $PASS -keypass $PASS -validity $DAYS \
        -dname "CN=$BROKER, OU=Lab12, O=NovaTech, L=Santiago, C=CL" \
        -ext "SAN=DNS:$BROKER,DNS:localhost"

    # 3b. Crear CSR (keytool en container)
    run_keytool -keystore /certs/$BROKER.keystore.jks -alias $BROKER \
        -certreq -file /certs/$BROKER.csr -storepass $PASS

    # 3c. Firmar con la CA (openssl en host).
    # Escribimos las extensiones en un archivo temporal real (no usar
    # process substitution <(...): rompe en Git Bash sobre Windows porque
    # /proc/PID/fd/N no resuelve y openssl falla con "BIO_new_file: No
    # such process"). El archivo temporal se limpia al exit del script
    # vía el trap declarado al inicio.
    HOST_CA_CRT="$(to_native_path "$CERTS_DIR/ca.crt")"
    HOST_CA_KEY="$(to_native_path "$CERTS_DIR/ca.key")"
    HOST_CSR="$(to_native_path "$CERTS_DIR/$BROKER.csr")"
    HOST_CRT="$(to_native_path "$CERTS_DIR/$BROKER.crt")"
    EXT_FILE="$TMPDIR_LAB12/ext-$BROKER.cnf"
    echo "subjectAltName=DNS:$BROKER,DNS:localhost" > "$EXT_FILE"
    HOST_EXT="$(to_native_path "$EXT_FILE")"
    openssl x509 -req -CA "$HOST_CA_CRT" -CAkey "$HOST_CA_KEY" \
        -in "$HOST_CSR" -out "$HOST_CRT" \
        -days $DAYS -CAcreateserial -passin pass:$PASS \
        -extfile "$HOST_EXT"

    # 3d. Importar CA al keystore (keytool en container)
    run_keytool -keystore /certs/$BROKER.keystore.jks -alias CARoot \
        -import -file /certs/ca.crt \
        -storepass $PASS -keypass $PASS -noprompt

    # 3e. Importar cert firmado al keystore (keytool en container)
    run_keytool -keystore /certs/$BROKER.keystore.jks -alias $BROKER \
        -import -file /certs/$BROKER.crt \
        -storepass $PASS -keypass $PASS -noprompt
done

# 4. Crear archivo con la password (para que docker compose lo monte)
echo "  [4/5] Generando archivo credentials..."
echo "$PASS" > "$CERTS_DIR/cert-credentials"

# 5. Permisos restrictivos.
# `|| true` defensivo: chmod puede no aplicar a algunos archivos en sistemas
# con permisos limitados (Windows), pero los archivos siguen siendo válidos.
echo "  [5/5] Aplicando permisos..."
chmod 600 "$CERTS_DIR"/*.key "$CERTS_DIR"/*.jks "$CERTS_DIR/cert-credentials" || true

echo -e "${GREEN}✓ Certificados generados en $CERTS_DIR${NC}"
echo -e "${GREEN}  Truststore: kafka.truststore.jks (lo usan TODOS)${NC}"
echo -e "${GREEN}  Keystores:  kafka-broker-{1,2,3}.keystore.jks (uno por broker)${NC}"
