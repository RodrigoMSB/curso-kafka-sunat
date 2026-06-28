#!/bin/bash
# Produce un set de 5 clientes seed con IDs específicos para que el alumno
# pueda probar JOINs con pedidos cuyo cliente_id coincida.

set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

DIR="$(dirname "$0")"

echo -e "${CYAN}[Produce Clientes Seed] Generando 5 clientes...${NC}"

"$DIR/produce-cliente-avro.sh" 1001 "NovaCorp" "VIP" "Santiago"
"$DIR/produce-cliente-avro.sh" 1010 "LogisticaSur" "VIP" "Concepción"
"$DIR/produce-cliente-avro.sh" 1017 "AndesExport" "ESTANDAR" "Valparaíso"
"$DIR/produce-cliente-avro.sh" 1055 "PacificoCargo" "VIP" "Antofagasta"
"$DIR/produce-cliente-avro.sh" 1098 "PatagoniaTrade" "NUEVO" "Punta Arenas"

echo -e "${GREEN}  ✓ 5 clientes seed publicados${NC}"
echo -e "${YELLOW}Estos IDs (1001, 1010, 1017, 1055, 1098) se usarán para los JOINs.${NC}"
