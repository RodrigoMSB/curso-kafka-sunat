#!/bin/bash
# Produce un set de 5 clientes seed con IDs específicos para que el alumno
# pueda probar JOINs con pedidos cuyo cliente_id coincida.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

DIR="$(dirname "$0")"

# ── Ficha didáctica ──────────────────────────────────────────
# Este archivo es CANÓNICO: vive en tools/ficha/wrappers/ y se replica por
# hash a los labs 11 y 12, que lo tienen idéntico byte a byte.
#
# No ejecuta Kafka: llama cinco veces a produce-cliente-avro.sh, así que no
# tiene flags propios que desglosar. Solo con TTY.
if ficha_activa; then
    ficha_init_color
    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto 'Publicar cinco clientes con ids fijos, para que después haya con qué cruzar los pedidos por su cliente_id'
    ficha_medio 'COMANDO REAL'
    ficha_comando 'kafka-cli/produce-cliente-avro.sh 1001 NovaCorp VIP Santiago'
    ficha_comando '  ... y lo mismo para 1010, 1017, 1055 y 1098'
    ficha_medio 'DESGLOSE'
    ficha_texto 'No recibe ningún parámetro. Los cinco clientes y sus ids están fijos a propósito, porque son los que las guías usan para los joins.'
    ficha_texto 'Los flags de Avro los pone produce-cliente-avro.sh y su propia ficha los explica uno por uno.'
    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_texto 'Una confirmación por cliente y, al final, los cinco ids que quedaron publicados. Si alguno falla, el script se detiene ahí y no publica los siguientes.'
    ficha_cerrar
    ficha_nota 'Corre dentro del contenedor schema-registry, no del broker.'
    echo ''
fi

echo -e "${CYAN}[Produce Clientes Seed] Generando 5 clientes...${NC}"

# El '| cat' no es decorativo y no se borra: sin él, cada hijo encuentra un TTY
# y dibuja SU ficha completa, cinco veces seguidas, tapando la de este wrapper.
# Con el tubo, ficha_activa da falso en el hijo y solo sale su salida útil,
# byte a byte igual que antes -- los colores de common.sh no dependen del TTY.
"$DIR/produce-cliente-avro.sh" 1001 "NovaCorp" "VIP" "Santiago"        | cat
"$DIR/produce-cliente-avro.sh" 1010 "LogisticaSur" "VIP" "Concepción"  | cat
"$DIR/produce-cliente-avro.sh" 1017 "AndesExport" "ESTANDAR" "Valparaíso" | cat
"$DIR/produce-cliente-avro.sh" 1055 "PacificoCargo" "VIP" "Antofagasta" | cat
"$DIR/produce-cliente-avro.sh" 1098 "PatagoniaTrade" "NUEVO" "Punta Arenas" | cat

echo -e "${GREEN}  ✓ 5 clientes seed publicados${NC}"
echo -e "${YELLOW}Estos IDs (1001, 1010, 1017, 1055, 1098) se usarán para los JOINs.${NC}"
