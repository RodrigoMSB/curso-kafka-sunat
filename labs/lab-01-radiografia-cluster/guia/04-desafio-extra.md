# Parte 4: Desafío extra (opcional)

## Objetivo

Poner a prueba tu capacidad de investigación usando los comandos CLI de Kafka para obtener información avanzada sobre el clúster.

## Contexto

Tu jefe quedó impresionado con tu reporte y quiere que profundices un poco más. Te pide tres análisis adicionales.

---

## Reto 1: Volumen de datos

**Misión**: Determinar cuántos bytes totales se han escrito en el tópico `novatech.fleet.gps`.

### Pista (haz clic para revelar)

<details>
<summary>Pista 1</summary>

Investiga el comando `kafka-log-dirs`. Este comando permite ver el tamaño de los logs por partición.

</details>

<details>
<summary>Pista 2</summary>

Ejecuta dentro del contenedor:

```bash
docker exec kafka-broker-1 kafka-log-dirs \
    --bootstrap-server kafka-broker-1:29092 \
    --describe \
    --topic-list novatech.fleet.gps
```

</details>

### Tu respuesta

| Dato | Valor |
|------|-------|
| Bytes totales (sumando todas las particiones y réplicas) | |
| Comando utilizado | |

---

## Reto 2: Distribución de datos

**Misión**: Identificar cuál partición tiene más datos y formular una hipótesis de por qué.

### Pista (haz clic para revelar)

<details>
<summary>Pista 1</summary>

Usa la salida del comando `kafka-log-dirs` del reto anterior y compara el tamaño (`size`) de cada partición.

</details>

<details>
<summary>Pista 2</summary>

Piensa en cómo el productor distribuye los mensajes entre las particiones. El productor de NovaTech NO usa una clave de partición. Desde Kafka 2.4 el partitioner por defecto es **StickyPartitioner** (no round-robin): el cliente se "pega" a una partición hasta llenar el batch (`batch.size`) o hasta que vence `linger.ms`. Como nuestro productor envía 1 evento cada 2 segundos (rate muy bajo), no llena batches y se queda mucho tiempo en la misma partición. Resultado: vas a ver una partición con casi todos los datos y las demás vacías.

</details>

### Tu respuesta

| Dato | Valor |
|------|-------|
| Partición con más datos | |
| Tamaño de esa partición | |
| Partición con menos datos | |
| Tamaño de esa partición | |
| ¿Por qué hay diferencia (o no la hay)? | |

---

## Reto 3: Exploración visual con Kafbat UI

**Misión**: Acceder a la interfaz web del clúster y observar visualmente lo que ya viste por CLI. Confirmar que la UI muestra los mismos datos que `kafka-cli/describe-topics.sh`.

1. Abre tu navegador en: **http://localhost:8090**
2. En la página inicial verás el clúster `novatech-cluster` ya configurado
3. Haz clic en él para entrar y navega por las distintas secciones

### Tu respuesta

| Dato | Valor |
|------|-------|
| ¿Cuántos brokers muestra la sección "Brokers"? | |
| ¿Qué broker aparece marcado como controlador del KRaft? | |
| ¿Cuántas particiones muestra el tópico `novatech.fleet.gps`? | |
| ¿Cuál es el throughput aproximado en mensajes/segundo (visible en "Topics > novatech.fleet.gps")? | |
| ¿Aparece el consumer group `lab01-explorer` (si ya ejecutaste `consume-gps.sh`)? | |
| Toma un screenshot de la vista de mensajes del tópico GPS y adjúntalo a tu reporte | |

> **Pista**: La vista de mensajes (Topics > novatech.fleet.gps > Messages) muestra los mensajes JSON GPS llegando en vivo. Es el mismo dato que produces por `consume-gps.sh`, solo que en una interfaz visual.

---

## Entrega

Documenta tus respuestas en el archivo `plantillas/reporte-entregable.md` en la sección de desafío extra.
