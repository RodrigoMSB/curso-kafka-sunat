# Lab 01 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

---

## Reto 1: Volumen de datos

### Comando

```bash
docker exec kafka-broker-1 kafka-log-dirs \
    --bootstrap-server kafka-broker-1:29092 \
    --describe \
    --topic-list novatech.fleet.gps
```

### Explicación

El comando `kafka-log-dirs` muestra información detallada sobre los directorios de log de Kafka, incluyendo el tamaño en bytes de cada partición en cada broker. La salida es un JSON que contiene:

- `broker`: ID del broker consultado
- `logDirs`: Array con los directorios de log
- Para cada partición: `size` (bytes), `offsetLag`, `isFuture`

Para obtener el total de bytes, el alumno debe:
1. Sumar el campo `size` de todas las particiones del tópico `novatech.fleet.gps`
2. Tener en cuenta que cada partición tiene réplicas en otros brokers, por lo que el volumen total "lógico" es el tamaño de las particiones líderes, no la suma de todas las réplicas

### Forma alternativa de calcular (más precisa)

```bash
# Ver tamaño por partición en cada broker
for BROKER in kafka-broker-1 kafka-broker-2 kafka-broker-3; do
    echo "=== $BROKER ==="
    docker exec $BROKER kafka-log-dirs \
        --bootstrap-server $BROKER:29092 \
        --describe \
        --topic-list novatech.fleet.gps
done
```

El volumen total depende del tiempo que lleve corriendo el productor. Con un mensaje cada 2 segundos y un tamaño promedio de ~150 bytes por mensaje JSON:

- 1 minuto: ~4.5 KB (30 mensajes)
- 10 minutos: ~45 KB (300 mensajes)
- 1 hora: ~270 KB (1800 mensajes)

---

## Reto 2: Distribución de datos

### Análisis

El productor GPS del laboratorio no especifica una clave de partición (`--key`), por lo que Kafka usa el **particionador sticky por defecto** (a partir de Kafka 2.4+/KIP-480).

**Comportamiento del sticky partitioner**:
- Agrupa mensajes del mismo batch en la misma partición
- Cuando el batch se completa o se envía, elige una nueva partición
- Resultado: distribución aproximadamente uniforme a lo largo del tiempo, pero con posibles diferencias en ventanas cortas

### ¿Por qué podría haber diferencias?

1. **Particionador sticky**: Al agrupar mensajes por batch, las particiones con batches más recientes pueden tener ligeramente más datos
2. **Tiempo de inicio**: Si el productor acaba de arrancar, puede que no todas las particiones hayan recibido la misma cantidad de mensajes
3. **Round-robin puro vs. sticky**: El `kafka-console-producer` envía un mensaje a la vez (sin batching real), por lo que con la versión de Kafka usada, la distribución tiende a ser bastante uniforme

### Conclusión esperada

La diferencia entre la partición con más datos y la de menos datos debería ser mínima (pocos mensajes de diferencia). Si un alumno ve diferencias grandes, puede indicar que el productor se reinició recientemente.

---

## Reto 3: Exploración visual con Kafbat UI

### Navegación paso a paso

1. Abrir **http://localhost:8090** en el navegador
2. La pantalla inicial muestra el clúster `novatech-cluster` pre-configurado vía variables de entorno (no requiere configuración manual)
3. Hacer clic en el clúster para entrar al panel principal

### Ubicación de los datos solicitados

- **Brokers**: Menú lateral > "Brokers"
  - Lista los 3 brokers con su ID, host, puerto y estado
  - Marca cuál es el "Controller" del quorum KRaft

- **Tópicos**: Menú lateral > "Topics"
  - `novatech.fleet.gps` aparece con sus 6 particiones
  - Al hacer clic, se accede a sub-secciones: Overview, Messages, Consumers, Settings

- **Throughput del tópico**:
  - Topics > `novatech.fleet.gps` > pestaña "Overview"
  - El gráfico "Messages per second" muestra ~0.5 msg/seg

- **Mensajes en vivo**:
  - Topics > `novatech.fleet.gps` > pestaña "Messages"
  - Permite filtrar por partición, offset o por contenido (CEL filtering)
  - Cada mensaje JSON GPS aparece formateado y legible

- **Consumer Groups**:
  - Menú lateral > "Consumers"
  - El grupo `lab01-explorer` aparece si el alumno ya ejecutó `consume-gps.sh`
  - Muestra lag por partición, miembros y offset actual

### Respuestas esperadas

| Dato | Valor esperado |
|------|----------------|
| Brokers visibles | 3 (broker-1, broker-2, broker-3) |
| Controlador KRaft | Varía (1, 2 o 3, el primero electo) |
| Particiones del tópico GPS | 6 |
| Throughput | ~0.5 msg/seg (1 mensaje cada 2 segundos) |
| Consumer group `lab01-explorer` | Aparece si el alumno consumió mensajes; si no, la sección está vacía |

---

*Soluciones de referencia - Lab 01*
