#!/bin/bash
# Abre el cliente CLI interactivo de ksqlDB.

source "$(dirname "$0")/../bin/common.sh"

echo -e "${CYAN}[ksqlDB CLI] Conectando a ksqldb-server:8088...${NC}"
echo -e "${YELLOW}Tip: usa 'SHOW STREAMS;' o 'SHOW TABLES;' para empezar.${NC}"
echo -e "${YELLOW}     Para salir: 'exit' o Ctrl+D${NC}"
echo ""

docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
