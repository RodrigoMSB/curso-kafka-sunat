# Troubleshooting - Lab 11

## Síntoma 1: JMX Exporter no responde

**Síntoma**: `curl http://localhost:7071/metrics` da timeout o connection refused.

**Causa**: el JAR no se montó correctamente, o `KAFKA_OPTS` no incluye el javaagent.

**Diagnóstico**:
```bash
docker exec kafka-broker-1 ls -la /opt/jmx-exporter/
docker logs kafka-broker-1 2>&1 | grep -i javaagent
```

**Solución**:
- Verificar que `infra/jmx-exporter/jmx_prometheus_javaagent.jar` existe
- Verificar que `KAFKA_OPTS: "-javaagent:..."` está en el environment del broker
- `bin/reset-lab.sh` y volver a `bin/start-lab.sh`

---

## Síntoma 2: Prometheus muestra targets DOWN

**Síntoma**: En http://localhost:9090 > Status > Targets, los brokers están DOWN.

**Causa común**: `prometheus.yml` usa `localhost:7071` en vez de `kafka-broker-1:7071`.

**Diagnóstico**:
```bash
docker exec prometheus wget -O - http://kafka-broker-1:7071/metrics 2>&1 | head -5
```

**Solución**: el config debe usar hostnames internos (`kafka-broker-N`), NO `localhost`.

---

## Síntoma 3: Grafana sin datos

**Síntoma**: el dashboard se ve pero todos los paneles dicen "No data".

**Diagnóstico**:
1. Abrir http://localhost:3000 > Configuration > Data Sources
2. Click en "Prometheus"
3. Botón "Test" abajo

**Si el test falla**: el datasource no apunta correctamente. URL debe ser
`http://prometheus:9090` (NO `localhost`).

**Si el test pasa pero paneles vacíos**: las queries del dashboard usan
nombres de métricas distintos a los que JMX Exporter genera. Es esperado
y se cubre en la guía 02.

---

## Síntoma 4: Dashboard pre-cargado no aparece

**Síntoma**: Grafana carga pero el dashboard "Kafka Cluster Overview" no
está en la lista.

**Diagnóstico**:
```bash
docker exec grafana ls -la /var/lib/grafana/dashboards/
docker exec grafana ls -la /etc/grafana/provisioning/dashboards/
docker logs grafana 2>&1 | grep -i provisioning
```

**Solución**:
- Verificar que `infra/grafana/dashboards/kafka-overview.json` existe
- Verificar que `infra/grafana/provisioning/dashboards/default.yml` existe
- Reiniciar solo Grafana: `docker compose -f infra/docker-compose.yml restart grafana`

---

## Síntoma 5: Métrica "No data" en panel específico

**Síntoma**: un panel del dashboard dice "No data".

**Causa**: la query PromQL usa un nombre de métrica que JMX Exporter no genera.

**Diagnóstico**:
1. Click en el panel → Edit
2. Mira la query (ej. `kafka_server_brokertopicmetrics_messagesinpersec`)
3. En Prometheus (http://localhost:9090), prueba:
   ```promql
   {__name__=~"kafka_server.*"}
   ```
4. Comparar lo que aparece con lo que la query espera

**Solución**: ajustar la query del dashboard. Lección típica de operación.

---

## Síntoma 6: JMX Exporter consume mucha memoria

**Síntoma**: el broker usa más RAM de lo normal.

**Causa**: el JMX Exporter genera muchas métricas si las reglas son muy
permisivas.

**Solución**: revisar `infra/jmx-exporter/kafka-broker.yml`. Reglas más
específicas (que solo capturen métricas críticas) reducen el costo.

---

## Síntoma 7: Conflicto de puertos con labs anteriores

Detener TODOS los demás labs antes:
```bash
# desde labs/<otro-lab>/
bin/stop-lab.sh
```

Puertos usados: 9092, 9093, 9094, 7071, 7072, 7073, 8090, 9090, 3000.

---

## Síntoma 8: Cambiar puerto Kafbat UI

Ver troubleshooting del Lab 01.

---

## Síntoma: brokers "unhealthy" pero responden bien internamente

### Diagnóstico

```bash
docker ps  # muestra brokers como "unhealthy"
docker exec kafka-broker-1 kafka-broker-api-versions --bootstrap-server localhost:29092
```

Si la salida del segundo comando muestra:
```
Failed to start Prometheus JMX Exporter
java.net.BindException: Address already in use
```

### Causa

Cualquier comando ejecutado en el contenedor (incluyendo healthchecks) hereda la variable `KAFKA_OPTS`. Esa variable incluye `-javaagent:.../jmx_prometheus_javaagent.jar=7071:...`. Como el broker YA usa el puerto 7071 para su propio JMX Exporter, cualquier comando subsecuente que invoque Java intenta levantar un segundo exporter en el mismo puerto y falla.

### Solución

Usar healthchecks que NO invoquen Java. Por ejemplo `nc -z` (test TCP simple) en lugar de `kafka-broker-api-versions` (que es un comando Java).

### Lección aprendida

Cuando se usa JMX Exporter como Java agent, hay que tener cuidado con TODOS los comandos que ejecuten Java en el mismo contenedor. La regla práctica: para health checks y diagnóstico, usar `nc`, `curl` o `kafkacat`, no las herramientas Java de `cp-kafka`.

### Detalle adicional sobre netcat

La imagen `confluentinc/cp-kafka:8.2.0` NO incluye `nc` (netcat) por defecto. Por eso usamos el built-in de bash `/dev/tcp/<host>/<puerto>` que es portable y no requiere binarios adicionales:

```bash
bash -c 'exec 3</dev/tcp/localhost/29092'
```

Si el comando devuelve exit code 0, el puerto está abierto y aceptando conexiones.

---

## Síntoma: scripts kafka-cli/ fallan con "Address already in use" (puerto 7071)

### Causa

Cualquier comando `docker exec` que ejecute herramientas Java de Kafka (`kafka-topics`, `kafka-producer-perf-test`, `kafka-console-consumer`, etc.) hereda la variable `KAFKA_OPTS` del contenedor del broker. Esa variable contiene `-javaagent:.../jmx_prometheus_javaagent.jar=7071:...`, y cuando el comando arranca su JVM, intenta levantar OTRO JMX Exporter en el puerto 7071 que ya está ocupado por el broker.

Síntoma típico:
```
Failed to start Prometheus JMX Exporter
java.net.BindException: Address already in use
```

### Solución

Pasar `-e KAFKA_OPTS=` al `docker exec` para sobreescribir la variable a vacío en esa ejecución:

```bash
# MAL (hereda KAFKA_OPTS y falla):
docker exec kafka-broker-1 kafka-topics --list --bootstrap-server localhost:29092

# BIEN:
docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-topics --list --bootstrap-server localhost:29092
```

### Lección

Cuando se usa JMX Exporter como Java agent, hay que ser cuidadoso con la herencia de variables de entorno en `docker exec`. Esta regla aplica a TODOS los scripts del Lab 11 que invocan herramientas Java dentro del contenedor del broker.

## Síntoma: dashboard de Grafana muestra "N/A" en todos los paneles

### Causa más común

Las queries PromQL del dashboard usan nombres de métricas que NO coinciden con las que JMX Exporter genera con el config de reglas que tenemos.

### Diagnóstico

1. Abrir Prometheus: http://localhost:9090
2. Pestaña **Query**
3. Empezar a tipear `kafka_` y ver el autocomplete: muestra TODAS las métricas Kafka disponibles
4. Comparar con las queries del dashboard (Edit panel > expression)

### Solución

Si una métrica del dashboard no existe en Prometheus, hay 3 opciones:
- **A**: Cambiar la query del panel para usar una métrica que SÍ existe
- **B**: Agregar una regla en `infra/jmx-exporter/kafka-broker.yml` que la genere
- **C**: Eliminar el panel del dashboard

En este lab, el dashboard "NovaTech Kafka — Lab 11" usa solo métricas que existen out-of-the-box. Si lo modificas y aparece "N/A", revisa qué métrica nueva agregaste.

### Lección

Los dashboards de la comunidad (como los de grafana.com) son **punto de partida, no copia-pega**. Casi siempre requieren ajustar las queries al config específico de tu JMX Exporter.

---

*Troubleshooting - Lab 11*
