#!/usr/bin/env bash
# ============================================================================
#  validar-todo.sh — Botón único de validación del curso SUNAT
#  Objetivo: mismo botón en macOS (tu entorno) y Git-Bash (la VM del alumno).
#  Portable bash 3.2, sin GNU-ismos. Corre igual en ambas plataformas.
#
#  Hace tres cosas, en orden:
#    1) PREFLIGHT   → detecta la plataforma y audita anti-patrones que rompen
#                     en Windows/Git-Bash (aunque lo corras desde tu Mac).
#    2) RUN-ALL     → ejecuta el harness e2e de los 14 labs (tests/run-all.sh).
#    3) VEREDICTO   → resumen cruzado: portabilidad + resultado funcional.
#
#  Uso:
#    bash validar-todo.sh                     # preflight + run-all completo
#    bash validar-todo.sh --solo-preflight    # solo la auditoría de portabilidad (rápido)
#    bash validar-todo.sh --lab 08            # preflight + un solo lab (tests/lab-08.sh)
# ============================================================================
set -uo pipefail

# ---- Colores (con fallback si la terminal no los soporta) ----
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

WARN=0; FATAL=0
warn()  { WARN=$((WARN+1));  printf "  ${YELLOW}!${NC}  %s\n" "$1"; }
fatal() { FATAL=$((FATAL+1)); printf "  ${RED}x${NC}  %s\n" "$1"; }
ok()    {                    printf "  ${GREEN}+${NC}  %s\n" "$1"; }

# ---- Parseo de argumentos ----
SOLO_PREFLIGHT=no; UN_LAB=""
while [ $# -gt 0 ]; do
  case "$1" in
    --solo-preflight) SOLO_PREFLIGHT=yes; shift ;;
    --lab) UN_LAB="${2:-}"; shift 2 ;;
    *) echo "Argumento desconocido: $1"; exit 2 ;;
  esac
done

# ============================================================================
#  1) PREFLIGHT — plataforma + auditoría de portabilidad
# ============================================================================
echo -e "\n${BOLD}${CYAN}=== 1/3 . PREFLIGHT (plataforma + portabilidad) ===${NC}"

PLATFORM="desconocida"
UNAME="$(uname -s 2>/dev/null || echo unknown)"
case "$UNAME" in
  Darwin)              PLATFORM="macOS (Docker Desktop)" ;;
  Linux)
    if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
      PLATFORM="Windows/WSL2 (Linux dentro de Windows)"
    else
      PLATFORM="Linux nativo"
    fi ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="Windows/Git-Bash (MSYS)" ;;
esac
ok "Plataforma detectada: ${BOLD}${PLATFORM}${NC}"
echo -e "     ${CYAN}bash ${BASH_VERSION:-?} . uname=${UNAME}${NC}"

for tool in docker bash grep sed awk; do
  if command -v "$tool" >/dev/null 2>&1; then ok "'$tool' disponible"
  else fatal "falta '$tool' en el PATH"; fi
done
if command -v "docker" >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then ok "'docker compose' (v2) disponible"
  else fatal "'docker compose' v2 no responde (Docker Desktop arriba?)"; fi
fi

echo -e "\n  ${BOLD}Auditoria de portabilidad de los scripts:${NC}"
SCAN_DIRS="labs tests"
# --include='*.sh': la auditoria de portabilidad mira SOLO ejecutables. La
# documentacion (p.ej. tests/CONVENCIONES-TEST.md, que cita los GNU-ismos
# prohibidos) no es codigo y se auto-detectaba como violacion.
scan() { grep -rn --include='*.sh' "$1" $SCAN_DIRS 2>/dev/null | grep -vE '_fuente-extra|/\.git/'; }

H=$(scan 'sed -i ' | grep -vE "sed -i ''|sed -i\.bak" || true)
[ -z "$H" ] && ok "sin 'sed -i' sin sufijo (rompe en BSD sed de macOS)" || { fatal "sed -i sin sufijo:"; echo "$H" | sed 's/^/       /'; }

H=$(scan 'base64 -d\|base64 --decode' || true)
[ -z "$H" ] && ok "sin 'base64 -d' (difiere GNU vs BSD; usar 'openssl base64 -d -A')" || { fatal "base64 -d:"; echo "$H" | sed 's/^/       /'; }

H=$(scan 'declare -A\|mapfile\|readarray\|,,}\|\^\^}' || true)
[ -z "$H" ] && ok "sin features de bash 4+ (macOS trae bash 3.2)" || { fatal "bash 4+:"; echo "$H" | sed 's/^/       /'; }

H=$(scan 'grep -P\|grep -oP' || true)
[ -z "$H" ] && ok "sin 'grep -P' (PCRE ausente en BSD grep)" || { warn "grep -P (revisar en macOS):"; echo "$H" | sed 's/^/       /'; }

H=$(scan 'readlink -f\|date -d ' || true)
[ -z "$H" ] && ok "sin 'readlink -f' / 'date -d' (GNU-ismos)" || { warn "GNU-ismos date/readlink:"; echo "$H" | sed 's/^/       /'; }

H=$(grep -rln '^#! */bin/sh' $SCAN_DIRS 2>/dev/null | grep -vE '_fuente-extra' || true)
[ -z "$H" ] && ok "todos los scripts usan shebang bash (no sh)" || { warn "shebangs /bin/sh:"; echo "$H" | sed 's/^/       /'; }

# --- CRLF: el gremlin #1 de Git-Bash (un .sh con CRLF NO arranca) ---
CRLF=$(grep -rlU $'\r' $SCAN_DIRS 2>/dev/null | grep -E '\.sh$' | grep -vE '_fuente-extra' || true)
if [ -z "$CRLF" ]; then
  ok "sin finales de linea CRLF en los .sh (arrancan en Git-Bash)"
else
  fatal "scripts con CRLF - NO arrancaran en Git-Bash (Windows):"
  echo "$CRLF" | sed 's/^/       /'
  echo -e "       ${CYAN}arreglalo con: git config core.autocrlf input  (y re-checkout)${NC}"
fi

# --- MSYS_NO_PATHCONV: en Git-Bash las rutas Unix en 'docker exec' se
#     traducen a rutas Windows y rompen. docker exec con ruta absoluta
#     debe llevar su guardia MSYS_NO_PATHCONV=1.
EXEC_ABS=$(grep -rn 'docker exec' $SCAN_DIRS 2>/dev/null | grep -vE '_fuente-extra' \
           | grep -E "docker exec .*['\" ]/(etc|var|opt|mnt|usr)/" || true)
EXEC_UNGUARDED=$(echo "$EXEC_ABS" | grep -v 'MSYS_NO_PATHCONV' | grep -v '^$' || true)
if [ -z "$EXEC_UNGUARDED" ]; then
  ok "todo 'docker exec' con ruta absoluta lleva su guardia MSYS_NO_PATHCONV=1"
else
  warn "docker exec con ruta absoluta SIN MSYS_NO_PATHCONV=1 (podria romper en Git-Bash):"
  echo "$EXEC_UNGUARDED" | sed 's/^/       /'
fi

# --- /dev/tcp: la sonda TCP del Lab 04. Feature de bash (no del SO),
#     y Git-Bash trae bash -> funciona en ambas plataformas.
# El fallo de la redireccion lo reporta el shell (no el comando), asi que el
# 2>/dev/null va sobre el bloque completo para no ensuciar la salida.
{ echo >/dev/tcp/127.0.0.1/1; } 2>/dev/null || true
ok "la sonda TCP '/dev/tcp' es soportada por bash (Mac y Git-Bash)"

echo ""
case "$PLATFORM" in
  *Git-Bash*)
    ok "Estas en Git-Bash: el entorno real de los alumnos. Este es el escenario de clase."
    warn "Docker Desktop debe estar corriendo; 'host.docker.internal' resuelve nativo aqui." ;;
  *macOS*)
    ok "En macOS: 'host.docker.internal' resuelve nativo (Docker Desktop)."
    echo -e "     ${CYAN}Desde Mac se valida la logica y se auditan los patrones que romperian en Git-Bash.${NC}"
    echo -e "     ${CYAN}Para certeza total del entorno del alumno, corre este MISMO boton en la VM Windows.${NC}" ;;
  *WSL2*)
    ok "En WSL2 el entorno es Linux. Ojo: los alumnos usan Git-Bash, no WSL2." ;;
esac

if [ "$FATAL" -gt 0 ]; then
  echo -e "\n${RED}${BOLD}PREFLIGHT FALLIDO . ${FATAL} bloqueante(s) . ${WARN} aviso(s)${NC}"
  echo -e "${YELLOW}Corrige los bloqueantes antes de correr el run-all.${NC}"
  exit 1
fi
echo -e "\n${GREEN}${BOLD}PREFLIGHT OK${NC}  (${WARN} aviso(s) no bloqueante(s))"

if [ "$SOLO_PREFLIGHT" = "yes" ]; then
  echo -e "${CYAN}(--solo-preflight: no se corre el harness)${NC}"
  exit 0
fi

# ============================================================================
#  2) RUN-ALL — el harness funcional real (no se reinventa; se invoca)
# ============================================================================
echo -e "\n${BOLD}${CYAN}=== 2/3 . VALIDACION FUNCIONAL (Docker real) ===${NC}"

RUN_RC=0
if [ -n "$UN_LAB" ]; then
  TARGET="tests/lab-${UN_LAB}.sh"
  if [ -f "$TARGET" ]; then
    echo -e "${CYAN}Corriendo solo ${TARGET}...${NC}"
    bash "$TARGET"; RUN_RC=$?
  else
    fatal "No existe $TARGET (numero de lab correcto? revisa 'ls tests/')"; RUN_RC=1
  fi
else
  if [ -f "tests/run-all.sh" ]; then
    bash tests/run-all.sh; RUN_RC=$?
  else
    fatal "No encuentro tests/run-all.sh en la raiz. Estas en la raiz del repo? (debe verse 'labs/' y 'tests/')"
    RUN_RC=1
  fi
fi

# ============================================================================
#  3) VEREDICTO CRUZADO
# ============================================================================
echo -e "\n${BOLD}${CYAN}=== 3/3 . VEREDICTO ===${NC}"
echo -e "  Plataforma:    ${BOLD}${PLATFORM}${NC}"
echo -e "  Portabilidad:  ${GREEN}OK${NC} (${WARN} aviso(s))"
if [ "$RUN_RC" -eq 0 ]; then
  echo -e "  Funcional:     ${GREEN}${BOLD}APROBADO${NC}"
  echo -e "\n${GREEN}${BOLD}TODO VERDE - el curso corre y es portable.${NC}"
  exit 0
else
  echo -e "  Funcional:     ${RED}${BOLD}FALLIDO${NC} (ver detalle arriba / tests/VALIDACION-REPORT.md)"
  echo -e "\n${RED}${BOLD}Hay fallos funcionales - revisa el detalle.${NC}"
  exit 1
fi
