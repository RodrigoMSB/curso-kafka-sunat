#!/bin/bash
# ============================================================
# Validador de ambiente para el curso de Kafka
#
# Recorre los 12 labs en orden, levanta cada uno con bin/start-lab.sh,
# captura tiempos y exit codes, limpia y pasa al siguiente.
#
# NO aborta cuando un lab falla: continúa con el resto y reporta al final.
#
# Uso típico (instructor antes de la clase, ops antes de entregar VMs):
#     scripts/diagnostico/validar-ambiente.sh
#
# Salida en pantalla + archivo de reporte + logs por lab.
# ============================================================

set -uo pipefail
# NO usamos -e: el script debe seguir cuando un lab falla.

# ─── Detección de raíz del repo ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ─── Constantes ───
SCRIPT_VERSION="1.0.0"
LAB_TIMEOUT_SECS=600

# Lista hardcoded de containers conocidos del curso (para limpieza forzada)
KNOWN_CONTAINER_PATTERN='^(kafka-broker-|kafbat-ui|cli-client|gps-producer|control-center|schema-registry|kafka-connect|ksqldb-server|ksqldb-cli|prometheus|grafana|debezium|postgres)'

# ─── Colores ───
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Variables runtime ───
SKIP_CLEANUP=0
ONLY_LAB=""
FROM_LAB=""
TO_LAB=""

# ─── Help ───
print_help() {
    cat <<'EOF'
Uso: validar-ambiente.sh [opciones]

Recorre los labs del curso, levanta cada uno con bin/start-lab.sh, captura
exit code y tiempo, limpia, y reporta al final.

Opciones:
    (sin opciones)        Valida los 12 labs en orden (lab-01 a lab-12)
    --lab N               Valida solo lab-N (ej: --lab 05)
    --from N              Valida desde lab-N hasta lab-12
    --to N                Valida desde lab-01 hasta lab-N
    --skip-cleanup        No ejecuta docker volume prune al final de cada lab
    --help                Muestra este mensaje y sale

Lab 03 siempre se marca SKIP (lab manual: el alumno construye su propio cluster).

Ejemplos:
    validar-ambiente.sh
    validar-ambiente.sh --lab 05
    validar-ambiente.sh --from 06
    validar-ambiente.sh --to 04
    validar-ambiente.sh --skip-cleanup

Tiempo estimado: ~30-50 minutos para los 12 labs.

Resultado: archivo REPORTE-FINAL.txt en
    scripts/diagnostico/logs/validacion-YYYYMMDD-HHMMSS/
junto con un log detallado por lab.

Exit code: 0 si todos los labs pasaron (o SKIP), 1 si alguno falló.
EOF
}

# ─── Parser de opciones CLI ───
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            print_help
            exit 0
            ;;
        --lab)
            if [[ -z "${2:-}" ]]; then
                echo "ERROR: --lab requiere un número (ej: --lab 05)" >&2
                exit 2
            fi
            ONLY_LAB=$(printf "%02d" "$2")
            shift 2
            ;;
        --from)
            if [[ -z "${2:-}" ]]; then
                echo "ERROR: --from requiere un número" >&2
                exit 2
            fi
            FROM_LAB=$(printf "%02d" "$2")
            shift 2
            ;;
        --to)
            if [[ -z "${2:-}" ]]; then
                echo "ERROR: --to requiere un número" >&2
                exit 2
            fi
            TO_LAB=$(printf "%02d" "$2")
            shift 2
            ;;
        --skip-cleanup)
            SKIP_CLEANUP=1
            shift
            ;;
        *)
            echo "ERROR: opción desconocida: $1" >&2
            echo "Usá --help para ver opciones disponibles." >&2
            exit 2
            ;;
    esac
done

# ─── Validaciones pre-flight ───
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] docker no está en el PATH.${NC}" >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Docker no está corriendo o el daemon no responde.${NC}" >&2
    echo -e "${RED}        Iniciá Docker Desktop y volvé a intentar.${NC}" >&2
    exit 1
fi

# Detectar comando de timeout disponible
TIMEOUT_CMD=""
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout"
fi

# ─── Preparar directorio de logs ───
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOGS_DIR="$SCRIPT_DIR/logs/validacion-$TIMESTAMP"
if ! mkdir -p "$LOGS_DIR"; then
    echo -e "${RED}[ERROR] No se pudo crear $LOGS_DIR${NC}" >&2
    exit 1
fi
REPORT_FILE="$LOGS_DIR/REPORTE-FINAL.txt"

# ─── Detectar labs disponibles (bash 3.2 compatible: no usar mapfile) ───
ALL_LABS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && ALL_LABS+=("$line")
done < <(find "$REPO_ROOT/labs" -maxdepth 1 -type d -name "lab-*" 2>/dev/null | sort)

if [[ ${#ALL_LABS[@]} -eq 0 ]]; then
    echo -e "${RED}[ERROR] No se encontraron labs en $REPO_ROOT/labs/${NC}" >&2
    exit 1
fi

# ─── Filtrar según opciones CLI ───
SELECTED_LABS=()
for lab_path in "${ALL_LABS[@]}"; do
    lab_name=$(basename "$lab_path")
    # Extraer el número (lab-NN-...)
    lab_num=$(echo "$lab_name" | sed -E 's/^lab-([0-9]+)-.*/\1/')

    if [[ -n "$ONLY_LAB" ]]; then
        [[ "$lab_num" != "$ONLY_LAB" ]] && continue
    fi
    if [[ -n "$FROM_LAB" ]]; then
        [[ "$lab_num" < "$FROM_LAB" ]] && continue
    fi
    if [[ -n "$TO_LAB" ]]; then
        [[ "$lab_num" > "$TO_LAB" ]] && continue
    fi

    SELECTED_LABS+=("$lab_path")
done

if [[ ${#SELECTED_LABS[@]} -eq 0 ]]; then
    echo -e "${RED}[ERROR] Ningún lab seleccionado con los filtros aplicados.${NC}" >&2
    exit 1
fi

# ─── Banner inicial ───
echo -e "${CYAN}${BOLD}"
cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║         VALIDACIÓN DE AMBIENTE - CURSO KAFKA                    ║
║         Script v$SCRIPT_VERSION                                            ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo "Fecha:        $(date '+%Y-%m-%d %H:%M:%S')"
echo "Repo:         $REPO_ROOT"
echo "Logs:         $LOGS_DIR"
echo "Labs a probar: ${#SELECTED_LABS[@]}"
[[ -z "$TIMEOUT_CMD" ]] && echo -e "${YELLOW}Aviso: 'timeout' no disponible — los labs pueden colgar indefinidamente${NC}"
echo ""

# ─── Helper: cleanup containers conocidos ───
cleanup_known_containers() {
    local containers
    containers=$(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -E "$KNOWN_CONTAINER_PATTERN" || true)
    if [[ -n "$containers" ]]; then
        # shellcheck disable=SC2086
        echo "$containers" | xargs docker rm -f >/dev/null 2>&1 || true
    fi
}

# ─── Helper: ejecuta un comando con timeout si está disponible ───
run_with_timeout() {
    local secs="$1"
    shift
    if [[ -n "$TIMEOUT_CMD" ]]; then
        "$TIMEOUT_CMD" "$secs" "$@"
    else
        "$@"
    fi
}

# ─── Arrays para reporte ───
declare -a REPORT_LINES
# Contadores inicializados explícitamente para compatibilidad con set -u
# (en bash 3.2, `declare -a` sin asignación no inicializa el array vacío,
# y ${#ARRAY[@]} truena cuando se procesa solo 1 lab que no toca esa rama).
OK_LABS=0
FAIL_LABS=0
SKIP_LABS=0

# ─── Iterar labs ───
TOTAL=${#SELECTED_LABS[@]}
INDEX=0
for lab_path in "${SELECTED_LABS[@]}"; do
    INDEX=$((INDEX + 1))
    lab_name=$(basename "$lab_path")
    lab_num=$(echo "$lab_name" | sed -E 's/^lab-([0-9]+)-.*/\1/')
    log_file="$LOGS_DIR/${lab_name}.log"

    printf "${CYAN}[%d/%d]${NC} Probando ${BOLD}%s${NC}... " "$INDEX" "$TOTAL" "$lab_name"

    # Lab 03: SKIP (manual)
    if [[ "$lab_num" == "03" ]]; then
        echo -e "${YELLOW}⏭️  SKIP (lab manual)${NC}"
        SKIP_LABS=$((SKIP_LABS + 1))
        REPORT_LINES+=("[$lab_num] $lab_name $(printf '%*s' $((40 - ${#lab_name})) '') SKIP (lab manual)")
        continue
    fi

    # Verificar bin/start-lab.sh
    start_script="$lab_path/bin/start-lab.sh"
    if [[ ! -x "$start_script" ]]; then
        if [[ -f "$start_script" ]]; then
            chmod +x "$start_script" 2>/dev/null || true
        fi
    fi
    if [[ ! -f "$start_script" ]]; then
        echo -e "${RED}❌ FAIL (no existe bin/start-lab.sh)${NC}"
        FAIL_LABS=$((FAIL_LABS + 1))
        REPORT_LINES+=("[$lab_num] $lab_name $(printf '%*s' $((40 - ${#lab_name})) '') FAIL  (no existe bin/start-lab.sh)")
        continue
    fi

    # Pre-cleanup: matar containers de labs anteriores
    cleanup_known_containers

    # Ejecutar start-lab.sh
    start_ts=$(date +%s)
    cd "$lab_path"
    set +o pipefail
    run_with_timeout "$LAB_TIMEOUT_SECS" bash bin/start-lab.sh > "$log_file" 2>&1
    rc=$?
    set -o pipefail
    cd "$REPO_ROOT"
    end_ts=$(date +%s)
    elapsed=$((end_ts - start_ts))

    # Clasificar resultado
    if [[ $rc -eq 0 ]]; then
        echo -e "⏱️  ${elapsed}s ${GREEN}✅ OK${NC}"
        OK_LABS=$((OK_LABS + 1))
        REPORT_LINES+=("[$lab_num] $lab_name $(printf '%*s' $((40 - ${#lab_name})) '') OK    ${elapsed}s")
    elif [[ $rc -eq 124 ]]; then
        echo -e "⏱️  ${elapsed}s ${RED}❌ TIMEOUT (>${LAB_TIMEOUT_SECS}s)${NC}"
        FAIL_LABS=$((FAIL_LABS + 1))
        REPORT_LINES+=("[$lab_num] $lab_name $(printf '%*s' $((40 - ${#lab_name})) '') TIMEOUT (rc=124, log: ${lab_name}.log)")
    else
        echo -e "⏱️  ${elapsed}s ${RED}❌ FAIL (rc=$rc)${NC}"
        FAIL_LABS=$((FAIL_LABS + 1))
        REPORT_LINES+=("[$lab_num] $lab_name $(printf '%*s' $((40 - ${#lab_name})) '') FAIL  (rc=$rc, log: ${lab_name}.log)")
    fi

    # Stop-lab + cleanup forzado
    stop_script="$lab_path/bin/stop-lab.sh"
    if [[ -f "$stop_script" ]]; then
        bash "$stop_script" >> "$log_file" 2>&1 || true
    fi
    cleanup_known_containers

    # docker volume prune (a menos que --skip-cleanup)
    if [[ $SKIP_CLEANUP -eq 0 ]]; then
        docker volume prune -f >/dev/null 2>&1 || true
    fi

    # Pausa entre labs
    sleep 5
done

# ─── Generar REPORTE-FINAL.txt ───
{
    echo "==========================================="
    echo "  VALIDACIÓN DE AMBIENTE - CURSO KAFKA"
    echo "==========================================="
    echo ""
    echo "Fecha:           $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Sistema:         $(uname -a)"
    echo "Docker:          $(docker --version 2>/dev/null || echo '?')"
    docker_mem_bytes=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    docker_mem_gb=$((docker_mem_bytes / 1073741824))
    echo "Docker memoria:  ${docker_mem_gb} GB asignados"
    echo "Repo:            $REPO_ROOT"
    echo "Logs:            $LOGS_DIR"
    echo ""
    echo "RESULTADOS:"
    echo ""
    for line in "${REPORT_LINES[@]}"; do
        echo "  $line"
    done
    echo ""
    echo "RESUMEN:"
    echo "  - OK:    $OK_LABS"
    echo "  - FAIL:  $FAIL_LABS"
    echo "  - SKIP:  $SKIP_LABS"
    echo "  - TOTAL: ${#SELECTED_LABS[@]} labs probados"
    echo ""
    echo "Logs detallados: $LOGS_DIR/"
} > "$REPORT_FILE"

# ─── Mostrar reporte en pantalla ───
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
cat "$REPORT_FILE"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Reporte completo: ${BOLD}$REPORT_FILE${NC}"
echo ""

# ─── Exit code ───
if [[ $FAIL_LABS -gt 0 ]]; then
    exit 1
fi
exit 0
