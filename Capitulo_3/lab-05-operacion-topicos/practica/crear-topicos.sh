#!/bin/bash
# ============================================================
# Lab 05 · practica/crear-topicos.sh
# ============================================================
# Este es el archivo que TÚ construyes.
#
# En un servidor real, los tópicos no se crean escribiendo comandos a mano en
# una terminal: se crean con un script como este, que queda versionado y dice
# por escrito qué política tiene cada tópico. Eso es lo que estás armando.
#
# Hay tres huecos marcados con ___ . Rellénalos con los valores que la guía
# justifica en el Paso 3, y el script corre. Mientras quede un ___ , el script
# se niega a ejecutar y te dice en qué línea está el hueco.
#
# Uso:
#   bash practica/crear-topicos.sh
#
# La versión resuelta está en solucion/crear-topicos.sh . Mírala después de
# intentarlo, no antes.
# ============================================================

set -uo pipefail

DIR_LAB="$(cd "$(dirname "$0")/.." && pwd)"

# ── HUECO 1 ──────────────────────────────────────────────────
# ¿En cuántas particiones se corta el tópico de la demostración?
# Pista: la guía explica por qué un número distinto vuelve ilegible el
# experimento. No es una preferencia, es una condición.
PARTICIONES=___

# ── HUECO 2 ──────────────────────────────────────────────────
# ¿Cuánto tiempo se guarda un segmento cerrado, en MILISEGUNDOS,
# antes de que Kafka lo bote?  La guía pide 60 segundos.
RETENTION_MS=___

# ── HUECO 3 ──────────────────────────────────────────────────
# ¿Cada cuánto se cierra el segmento activo, en MILISEGUNDOS?
# Tiene que ser bastante MENOR que RETENTION_MS: si no, no alcanza a
# haber ningún segmento cerrado que botar. La guía pide 10 segundos.
SEGMENT_MS=___

# ── Lo que no se toca ────────────────────────────────────────
TOPICO="novatech.lab05.efimero"
REPLICAS=3

# ============================================================
# Guardia: este script se niega a correr con huecos sin rellenar.
# Un script que corre a medias y crea un tópico con la configuración
# equivocada es peor que uno que no corre.
# ============================================================
HUECOS=$(grep -n '^[A-Z_]*=___$' "$0" || true)
if [ -n "$HUECOS" ]; then
    echo ""
    echo "  Todavía hay huecos sin rellenar. No voy a crear nada."
    echo ""
    echo "$HUECOS" | sed 's/^/    línea /'
    echo ""
    echo "  Abre este archivo, reemplaza cada ___ por su valor, y vuelve a"
    echo "  ejecutar. La guía justifica los tres en el Paso 3."
    echo ""
    exit 1
fi

# ============================================================
# Creación
# ============================================================
echo "  Creando ${TOPICO}"
echo "    particiones:   ${PARTICIONES}"
echo "    réplicas:      ${REPLICAS}"
echo "    retention.ms:  ${RETENTION_MS}"
echo "    segment.ms:    ${SEGMENT_MS}"
echo ""

"${DIR_LAB}/kafka-cli/create-topic.sh" "$TOPICO" \
    --partitions "$PARTICIONES" \
    --rf "$REPLICAS" \
    --config "retention.ms=${RETENTION_MS}" \
    --config "segment.ms=${SEGMENT_MS}"
