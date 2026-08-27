#!/bin/bash
# Genera los PDF de las guias de alumno y los deja en el docs/ de cada lab.
#
#   docs/guias-alumno/generar-pdf.sh            # todas
#   docs/guias-alumno/generar-pdf.sh 05 06      # solo esas
#
# El HTML vive aqui, en docs/guias-alumno/, porque las catorce guias comparten
# un unico estilo-alumno.css. El PDF se copia a la carpeta del lab, que es
# donde el alumno lo busca.
#
# El encargo original pedia wkhtmltopdf. Ese proyecto esta archivado desde 2023
# y ya no tiene formula ni cask en Homebrew, asi que la impresion la hace Chrome
# headless por CDP (render-pdf.mjs), con los mismos margenes y el mismo pie.
set -uo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"

# lab | carpeta del lab | texto del pie izquierdo
LABS=(
"01|Capitulo_2/lab-01-inicializacion-kraft|Lab 01 · Encender Kafka desde cero"
"02|Capitulo_2/lab-02-validacion-quorum-resiliencia|Lab 02 · Quórum y resiliencia"
"03|Capitulo_3/lab-03-configuracion-brokers|Lab 03 · Configuración de brokers"
"04|Capitulo_3/lab-04-multibroker-advertised-listeners|Lab 04 · Advertised listeners"
"05|Capitulo_3/lab-05-operacion-topicos|Lab 05 · Operación de tópicos"
"06|Capitulo_3/lab-06-produccion-consumo-cli|Lab 06 · Producción y consumo por CLI"
"07|Capitulo_3/lab-07-pruebas-rendimiento|Lab 07 · Pruebas de rendimiento"
"08|Capitulo_3/lab-08-brokers-en-caliente|Lab 08 · Brokers en caliente"
"08b|Capitulo_3/lab-08b-instalacion-rhel|Lab 08b · Instalación en RHEL"
)

PEDIDOS=("$@")
quiere() {
    [ ${#PEDIDOS[@]} -eq 0 ] && return 0
    local p
    for p in "${PEDIDOS[@]}"; do [ "$p" = "$1" ] && return 0; done
    return 1
}

hechos=0
saltados=0
fallos=0

for fila in "${LABS[@]}"; do
    IFS='|' read -r num carpeta pie <<< "$fila"
    quiere "$num" || continue

    html="$AQUI/lab${num}.html"
    if [ ! -f "$html" ]; then
        echo "  -- lab ${num}: sin HTML todavia, se salta"
        saltados=$((saltados + 1))
        continue
    fi

    destino="$RAIZ/$carpeta/docs"
    mkdir -p "$destino"
    if node "$AQUI/render-pdf.mjs" "$html" "$destino/lab${num}.pdf" "$pie"; then
        paginas=$(pdfinfo "$destino/lab${num}.pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
        peso=$(du -h "$destino/lab${num}.pdf" | cut -f1)
        echo "  OK lab ${num}: ${paginas:-?} paginas, ${peso} -> $carpeta/docs/lab${num}.pdf"
        hechos=$((hechos + 1))
    else
        echo "  FALLO lab ${num}"
        fallos=$((fallos + 1))
    fi
done

echo "----------------------------------------"
echo "generados: $hechos · saltados: $saltados · fallos: $fallos"
[ "$fallos" -eq 0 ]
