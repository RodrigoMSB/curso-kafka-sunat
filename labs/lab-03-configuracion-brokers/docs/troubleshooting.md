# Troubleshooting - Lab 03 (SUNAT)

## Problemas comunes y soluciones

### 1. No aparece ningún `.properties` dentro del contenedor

```bash
docker exec kafka-broker-1 bash -c 'ls /etc/kafka/*.properties'
```

Si el comando falla o el archivo no existe, el broker **no llegó a arrancar**: la imagen
genera el properties al inicio. Revisa los logs:

```bash
docker logs kafka-broker-1 | tail -30
```

Causa típica: una variable `KAFKA_*` mal escrita o un storage sin formatear. Reconstruye
el clúster con `soluciones/` del **Lab 02**.

---

### 2. `kafka-configs` no responde / se queda colgado

```bash
docker exec kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 --describe --entity-type brokers --entity-name 1 --all
```

Si no responde, el clúster está caído o el bootstrap interno es incorrecto. Verifica que
los 3 brokers estén arriba (`docker ps`) y que el puerto interno sea `29092`. Si el clúster
no está sano, reconstrúyelo con `soluciones/` del **Lab 02** antes de seguir.

---

*Troubleshooting - Lab 03*
