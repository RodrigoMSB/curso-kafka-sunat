#!/bin/bash
# ============================================================
# Orquestador E2E (instructor) - corre los 14 labs en serie.
# Uno a la vez, teardown entre cada uno, veredicto global + reporte con duración.
# ============================================================
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib-test.sh"
REPORT="$HERE/VALIDACION-REPORT.md"

declare -a RESULTS; GLOBAL_FAIL=0; T_GLOBAL0=$(date +%s)

{
  echo "# Reporte de validación E2E - SUNAT"
  echo ""
  echo "Generado: $(date '+%Y-%m-%d %H:%M')"
  echo ""
  echo "| Lab | Resultado | Duración (s) |"
  echo "|-----|-----------|--------------|"
} > "$REPORT"

for t in "$HERE"/lab-*.sh; do
    [ -e "$t" ] || continue
    name="$(basename "$t" .sh)"
    echo -e "\n${BOLD}${CYAN}▶ ${name}${NC}"
    t0=$(date +%s)
    if bash "$t"; then st="PASS"; else st="FAIL"; GLOBAL_FAIL=$((GLOBAL_FAIL+1)); fi
    dur=$(( $(date +%s) - t0 ))
    RESULTS+=("$name  $st  (${dur}s)")
    echo "| $name | $st | $dur |" >> "$REPORT"
    # Aviso (no matar) si quedan contenedores del ecosistema del curso
    docker ps --format '{{.Names}}' | grep -qE 'kafka-broker|novatech|kafbat|kafka-rest|cli-client|schema-registry|ksqldb|connect' \
        && echo -e "${YELLOW}  OJO: quedan contenedores tras ${name} — revisar teardown${NC}"
done

TOTAL=${#RESULTS[@]}; DUR_G=$(( $(date +%s) - T_GLOBAL0 ))
{ echo ""; echo "**Global: $((TOTAL-GLOBAL_FAIL))/${TOTAL} PASS · ${DUR_G}s totales**"; } >> "$REPORT"

echo -e "\n${BOLD}━━━ RESUMEN (${DUR_G}s) ━━━${NC}"
for r in "${RESULTS[@]}"; do echo "  $r"; done
if [ "$GLOBAL_FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}TODOS APROBADOS (${TOTAL}/${TOTAL})${NC}"; exit 0
else
    echo -e "${RED}${BOLD}${GLOBAL_FAIL} LAB(S) FALLIDO(S) — ver ${REPORT}${NC}"; exit 1
fi
