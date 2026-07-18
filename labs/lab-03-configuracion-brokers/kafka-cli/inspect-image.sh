#!/bin/bash
# Explora qué hay dentro de la imagen Confluent cp-kafka.
# Útil para entender qué binarios y archivos de configuración trae.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

IMAGE="confluentinc/cp-kafka:8.2.0"

echo -e "${CYAN}${BOLD}Inspeccionando imagen ${IMAGE}${NC}"
echo "════════════════════════════════════════════════════════"

# 1. Pull (idempotente)
echo -e "${YELLOW}[1/4] Pull de la imagen (si ya está, será instantáneo)...${NC}"
docker pull -q "$IMAGE" > /dev/null
echo -e "${GREEN}  ✓ Imagen disponible${NC}"

echo ""
echo -e "${YELLOW}[2/4] Binarios CLI de Kafka (en /usr/bin/):${NC}"
docker run --rm "$IMAGE" sh -c "ls /usr/bin/kafka-* 2>/dev/null | head -20"

echo ""
echo -e "${YELLOW}[3/4] Archivos de configuración de ejemplo (en /etc/kafka/):${NC}"
docker run --rm "$IMAGE" sh -c "ls -la /etc/kafka/ 2>/dev/null | head -20"

echo ""
echo -e "${YELLOW}[4/4] Versión de Java incluida:${NC}"
docker run --rm "$IMAGE" java -version 2>&1 | head -3

echo ""
echo -e "${GREEN}${BOLD}Inspección completa. Anota tus observaciones en el reporte.${NC}"
