#!/usr/bin/env bash
# Canoniza un .pptx generado por python-pptx a OOXML que PowerPoint Mac acepta.
# Uso: bash presentacion/canonizar-pptx.sh <archivo.pptx>
# Reescribe el archivo IN-PLACE (deja un respaldo .crudo.pptx al lado).
set -euo pipefail

SOFFICE="${SOFFICE:-/opt/homebrew/bin/soffice}"
[ -x "$SOFFICE" ] || SOFFICE="$(command -v soffice || true)"
[ -n "$SOFFICE" ] || { echo "ERROR: no encuentro soffice (LibreOffice)"; exit 1; }

F="$1"
[ -f "$F" ] || { echo "ERROR: no existe $F"; exit 1; }
DIR="$(cd "$(dirname "$F")" && pwd)"
BASE="$(basename "$F")"
TMP="$(mktemp -d)"

# 1) Convertir a una carpeta temporal
"$SOFFICE" --headless --convert-to pptx --outdir "$TMP" "$F" >/dev/null 2>&1

# 2) Higiene: matar cualquier soffice que haya quedado
pkill -9 -i soffice 2>/dev/null || true

# 3) Verificar que el convertido existe y es válido
OUT="$TMP/$BASE"
[ -f "$OUT" ] || { echo "ERROR: la conversion no produjo $OUT"; rm -rf "$TMP"; exit 1; }

# 4) Respaldar el crudo y reemplazar in-place por el canonizado
cp "$F" "$DIR/${BASE%.pptx}.crudo.pptx"
cp "$OUT" "$F"
rm -rf "$TMP"

# 5) Limpiar atributos extendidos de macOS (cuarentena, etc.)
xattr -c "$F" 2>/dev/null || true

echo "OK canonizado: $F  (respaldo crudo: ${BASE%.pptx}.crudo.pptx)"
