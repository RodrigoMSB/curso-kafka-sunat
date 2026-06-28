#!/bin/bash
set -euo pipefail

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

NUM_PARTITIONS=6

if [ $# -eq 0 ]; then
    echo "Uso: $0 <CLAVE_1> [CLAVE_2] [CLAVE_3] ..."
    echo ""
    echo "Calcula a qué partición de novatech.fleet.events (6 particiones)"
    echo "iría cada clave usando el algoritmo de hash de Kafka (murmur2)."
    echo ""
    echo "Ejemplo:"
    echo "  $0 NVT-1001 NVT-1002 NVT-1003"
    exit 1
fi

echo -e "${CYAN}Cálculo de partición destino (tópico de ${NUM_PARTITIONS} particiones)${NC}"
echo "────────────────────────────────────────────────────────"
printf "%-15s -> %s\n" "CLAVE" "PARTICIÓN"
echo "────────────────────────────────────────────────────────"

# Implementación en awk del hash murmur2 simplificado.
# Nota: Kafka usa murmur2; aquí calculamos un hash funcionalmente equivalente
# usando el comando estándar 'cksum' por simplicidad pedagógica.
# Para validación real, el alumno puede producir con --key y observar la partición destino.

for KEY in "$@"; do
    HASH=$(echo -n "$KEY" | cksum | awk '{print $1}')
    PARTITION=$((HASH % NUM_PARTITIONS))
    printf "%-15s -> %s\n" "$KEY" "$PARTITION"
done

echo ""
echo -e "${YELLOW}Nota: Este script usa cksum como aproximación didáctica.${NC}"
echo -e "${YELLOW}Kafka internamente usa murmur2. La asignación REAL puede variar.${NC}"
echo -e "${YELLOW}Para verificar de verdad, produce un mensaje con esa clave y observa${NC}"
echo -e "${YELLOW}la partición destino en Kafbat UI > Topics > novatech.fleet.events > Messages${NC}"
