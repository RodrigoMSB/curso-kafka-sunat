# Lab 08 · SALIDAS — la corrida real

> **Esto no es un ejemplo escrito a mano.** Es la transcripción de la corrida del
> recorrido contra el clúster del laboratorio, el 23-ago-2026.
>
> **Para qué sirve:** para contrastar. Aquí los números **sí** se parecen a los
> tuyos —esto no es un lab de mediciones—, salvo los tiempos y las latencias.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total del recorrido** | **33 s** |
| De eso, levantar el broker 4 | **11 s** |
| De eso, la reasignación | **22 s** |
| Datos en el tópico antes de empezar | ~150 MB (150 000 × 1 000 B) |
| Throttle usado | 8 MB/s |
| Mensajes producidos durante la operación | 300 000 |

🔴 **El reloj lo mandan el volumen y el throttle juntos.** Tres corridas medidas
en la misma máquina:

| Datos | Throttle | Duró |
|---|---|---|
| ~1 MB (lo que deja `start-lab.sh`) | sin throttle | **3 s** — no se ve nada |
| ~150 MB | 8 MB/s | **22 s** — se puede narrar |
| ~400 MB | 3 MB/s | **136 s** — se come el bloque |

Si quieres ver la copia, produce volumen primero. Si no quieres que la clase se
duerma, no te pases.

---

## Paso 1 · La foto inicial

```
Topic: novatech.lab08.pedidos	TopicId: KEFMMq8aRoWQ7vZ95H90gg	PartitionCount: 6	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: novatech.lab08.pedidos	Partition: 0	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2
	Topic: novatech.lab08.pedidos	Partition: 1	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3
	Topic: novatech.lab08.pedidos	Partition: 2	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1
	Topic: novatech.lab08.pedidos	Partition: 3	Leader: 1	Replicas: 1,3,2	Isr: 1,3,2
	Topic: novatech.lab08.pedidos	Partition: 4	Leader: 3	Replicas: 3,2,1	Isr: 3,2,1
	Topic: novatech.lab08.pedidos	Partition: 5	Leader: 2	Replicas: 2,1,3	Isr: 2,1,3
```

**18 réplicas entre tres brokers. Ni un 4.**

---

## Paso 2 · El broker 4 entra, y entra vacío

```
[Add] Levantando kafka-broker-4 (broker-only)...
 Container kafka-broker-4  Started
Esperando a que el broker-4 esté operativo...
✓ broker-4 operativo y unido al clúster
```

**11 segundos.** Y `list-brokers.sh`:

```
kafka-broker-3:29094
kafka-broker-4:29095

[Metadata del clúster]
LeaderId:               2
LeaderEpoch:            1
HighWatermark:          134
CurrentVoters:          [{"id": 1, ...}, {"id": 2, ...}, {"id": 3, ...}]
CurrentObservers:       [{"id": 4, "directoryId": "n5ahoDBeCm7dL3mbbqM0UQ"}]
```

🔴 **`CurrentVoters` sigue siendo 1, 2, 3. El broker 4 es `CurrentObservers`.**
El quórum no se tocó.

Y el `describe-topic` después de agregarlo: **idéntico al del Paso 1**. Cero
réplicas en el broker 4.

```
grep -c "Replicas:.*4" -> 0
```

---

## Paso 3 · La reasignación

### Lo que imprimió el `--execute`

```
Current partition replica assignment

{"version":1,"partitions":[{"topic":"novatech.lab08.pedidos","partition":0,"replicas":[3,1,2],"log_dirs":["/var/lib/kafka/data","/var/lib/kafka/data","/var/lib/kafka/data"]},{"topic":"novatech.lab08.pedidos","partition":1,"replicas":[1,2,3],...},...]}

Save this to use as the --reassignment-json-file option during rollback
Warning: You must run --verify periodically, until the reassignment completes, to ensure the throttle is removed.
The inter-broker throttle limit was set to 8000000 B/s
Successfully started partition reassignments for novatech.lab08.pedidos-0,novatech.lab08.pedidos-1,novatech.lab08.pedidos-2,novatech.lab08.pedidos-3,novatech.lab08.pedidos-4,novatech.lab08.pedidos-5
```

🔴 **Las dos líneas que importan están ahí y son fáciles de perder:** `Save this
to use as the --reassignment-json-file option during rollback` y el `Warning:`
sobre el `--verify`.

### El `--verify` en bucle

```
  copiando... 5 de 6 partición(es) pendiente(s) (intento 1/60)
  copiando... 4 de 6 partición(es) pendiente(s) (intento 3/60)
  copiando... 3 de 6 partición(es) pendiente(s) (intento 5/60)
  copiando... 1 de 6 partición(es) pendiente(s) (intento 7/60)

Status of partition reassignment:
Reassignment of partition novatech.lab08.pedidos-0 is completed.
Reassignment of partition novatech.lab08.pedidos-1 is completed.
Reassignment of partition novatech.lab08.pedidos-2 is completed.
Reassignment of partition novatech.lab08.pedidos-3 is completed.
Reassignment of partition novatech.lab08.pedidos-4 is completed.
Reassignment of partition novatech.lab08.pedidos-5 is completed.

Clearing broker-level throttles on brokers 1,2,3,4
Clearing topic-level throttles on topic novatech.lab08.pedidos
```

### La distribución resultante

```
	Partition: 0	Leader: 3	Replicas: 3,4,1	Isr: 1,3,4
	Partition: 1	Leader: 1	Replicas: 4,1,2	Isr: 1,2,4
	Partition: 2	Leader: 2	Replicas: 1,2,3	Isr: 2,3,1
	Partition: 3	Leader: 2	Replicas: 2,3,4	Isr: 2,3,4
	Partition: 4	Leader: 3	Replicas: 1,3,2	Isr: 1,2,3
	Partition: 5	Leader: 2	Replicas: 3,2,4	Isr: 2,3,4
```

El broker 4 está en **4 de las 6** particiones. (En otra corrida de la misma
máquina quedó además como **líder** de la partición 1: qué particiones toca y de
cuáles queda líder cambia en cada corrida, porque el plan lo calcula Kafka.)

---

## Los throttles, medidos

### Durante la copia

En el **tópico**:

```
Dynamic configs for topic novatech.lab08.pedidos are:
  follower.replication.throttled.replicas=0:2,1:3,3:1,4:2
  leader.replication.throttled.replicas=0:1,0:3,0:4,1:1,1:2,1:4,2:1,2:2,2:3,3:2,3:3,3:4,4:1,4:3,4:4,5:1,5:2,5:3
```

En **cada uno de los 4 brokers**:

```
broker 1: follower.replication.throttled.rate=8000000  leader.replication.throttled.rate=8000000
broker 2: follower.replication.throttled.rate=8000000  leader.replication.throttled.rate=8000000
broker 3: follower.replication.throttled.rate=8000000  leader.replication.throttled.rate=8000000
broker 4: follower.replication.throttled.rate=8000000  leader.replication.throttled.rate=8000000
```

### 🔴 El `--verify` prematuro no limpia

Corrido cuando todavía quedaban particiones copiando:

```
Status of partition reassignment:
Reassignment of partition novatech.lab08.pedidos-0 is still in progress.
Reassignment of partition novatech.lab08.pedidos-1 is still in progress.
Reassignment of partition novatech.lab08.pedidos-2 is completed.
Reassignment of partition novatech.lab08.pedidos-3 is still in progress.
Reassignment of partition novatech.lab08.pedidos-4 is still in progress.
Reassignment of partition novatech.lab08.pedidos-5 is completed.
```

**No aparece ninguna línea `Clearing`.** Y al mirar el broker justo después:

```
leader.replication.throttled.rate=3000000     <-- siguen puestos
```

Y el comando **devolvió código de salida 0**. Nada avisa.

### Después del `--verify` final

```
broker 1: limpio
broker 2: limpio
broker 3: limpio
broker 4: limpio
tópico:   0 configuraciones con "throttled"
```

### ⚠ El mensaje que engaña

Una reasignación corrida **sin** `--throttle` no pone ningún límite — se
comprobó consultando los brokers y el tópico justo después del `--execute`, y no
había nada. Y sin embargo, el `--verify` imprimió igual:

```
Clearing broker-level throttles on brokers 1,2,3,4
Clearing topic-level throttles on topic novatech.lab08.pedidos
```

🔴 **Ese mensaje sale siempre, haya o no throttles.** De ahí sale la creencia de
que Kafka los pone automáticamente durante la copia. **No los pone: los pones tú
con `--throttle`.** Para saber si hay throttles no se lee ese mensaje — se
consulta la configuración.

---

## Lo que sintieron los clientes

El productor corrió durante todo el `add-broker` y toda la reasignación.

```
300000 records sent, 2999.610051 records/sec (1.43 MB/sec), 36.77 ms avg latency,
4025.00 ms max latency, 6 ms 50th, 10 ms 95th, 1235 ms 99th, 3927 ms 99.9th.
```

| | |
|---|---|
| Pedidos / enviados | 300 000 / **300 000** |
| Líneas `WARN` | 2 |
| Líneas `ERROR` | **0** |
| Líneas `FATAL` | **0** |
| Tipos de error distintos | 1 × `NOT_LEADER_OR_FOLLOWER` |

⚠ **Cuántos `NOT_LEADER_OR_FOLLOWER` salen depende de cuántos liderazgos se
muevan**, y eso cambia en cada corrida. En otra corrida de la misma máquina
salieron 5. Que salgan **cero** también es posible y no invalida nada.

Una de las líneas, entera:

```
[2026-08-23 18:39:56,090] WARN [Producer clientId=perf-producer-client] Got error
produce response with correlation id 2778 on topic-partition
novatech.lab08.pedidos-1, retrying (2147483646 attempts left).
Error: NOT_LEADER_OR_FOLLOWER (org.apache.kafka.clients.producer.internals.Sender)
```

**`retrying (2147483646 attempts left)`** — el cliente lo resuelve solo. Por eso
no se perdió un mensaje.

### Y la cola, que es lo que no se ve

```
p50         6 ms   ▏
p95        10 ms   ▏
media   36,77 ms   ▎
p99     1 235 ms   ████████████
p99.9   3 927 ms   ███████████████████████████████████████
máx     4 025 ms   ████████████████████████████████████████
```

🔴 **Entre el p95 y el p99 hay un salto de 10 ms a 1 235 ms.** El 95 % de los
mensajes no se enteró de nada. Uno de cada cien tardó más de un segundo, y el
peor tardó más de cuatro. Un tablero de promedios —o incluso de p95— habría
mostrado esta operación como si no hubiera pasado nada.

---

## PARA PROFUNDIZAR · el rollback aplicado

Se aplicó el plan de vuelta que el script guardó, sobre un clúster que ya había
sido drenado a los brokers 1,2,3.

> ⚠ **Esta prueba es una corrida aparte**, con otra asignación de partida que la
> del recorrido de arriba. Lo que hay que mirar no son los números sino que la
> columna izquierda y la derecha **coincidan**.

```
Successfully started moving log directory to /var/lib/kafka/data for replica novatech.lab08.pedidos-4 with broker 4
Successfully started moving log directory to /var/lib/kafka/data for replica novatech.lab08.pedidos-5 with broker 4
```

**Comparación réplica por réplica**, lo que decía el plan contra lo que quedó:

| Partición | El plan de vuelta decía | Quedó |
|---|---|---|
| 0 | `[3, 4, 1]` | `[3,4,1]` |
| 1 | `[4, 1, 2]` | `[4,1,2]` |
| 2 | `[1, 2, 3]` | `[1,2,3]` |
| 3 | `[2, 3, 4]` | `[2,3,4]` |
| 4 | `[1, 4, 2]` | `[1,4,2]` |
| 5 | `[4, 2, 3]` | `[4,2,3]` |

**Las seis, exactas.** El plan de vuelta no es una aproximación: restituye la
asignación anterior réplica por réplica y en el mismo orden.

🔴 **Pero costó otra reasignación completa**, con su copia de datos y su propio
impacto. Poder deshacer no es deshacer gratis.

---

## Lo que salió del recorrido y dónde quedó

| Salió del recorrido | Dónde está |
|---|---|
| Aplicar el plan de vuelta | *Para profundizar A* |
| Ver y limpiar throttles a mano | *Para profundizar B* |
| Drenar el broker 4 y apagarlo | *Para profundizar C* |
| La configuración dinámica de brokers | *Para profundizar D* — **ya dictada entera en el Lab 03** |
| El ciclo completo con tráfico | *Para profundizar E* |
