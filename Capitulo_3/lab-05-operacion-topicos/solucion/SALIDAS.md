# Lab 05 · SALIDAS — la corrida real

> **Esto no es un ejemplo escrito a mano.** Es la transcripción literal de una
> corrida completa de la guía, comando por comando, contra el clúster de tres
> brokers del laboratorio. Los tiempos `[t=NNNs]` son segundos desde el inicio
> del recorrido.
>
> **Para qué sirve:** para contrastar. Si a ti te salió algo distinto, aquí
> puedes ver si la diferencia importa o no. Los valores que **van a cambiar**
> en tu corrida están marcados abajo.

## Lo que va a ser distinto en tu máquina

| Valor | Por qué cambia |
|---|---|
| `TopicId` | Se genera al crear el tópico. Siempre distinto |
| `Leader:` y el orden de `Replicas:` | Kafka reparte los líderes al crear. Lo que **no** cambia es que `Isr` tenga los mismos tres números que `Replicas` |
| El segundo `[t=NNNs]` en que el offset cambia | Depende de en qué punto de su ronda de 5 minutos estaba el broker. Aquí fueron 139 s |
| `:0:105` o `:0:100` al final | Si la ronda llega antes de que venzan los 5 de la segunda ráfaga, quedan 5 vivos en vez de 0. Las dos salidas demuestran lo mismo |

## Lo que **no** debería cambiar

- `retention.ms=604800000` y `segment.ms=604800000` en `novatech.fleet.gps` — son los valores de fábrica.
- `Configs:` con tres valores en `novatech.lab05.efimero` tras crearlo.
- `:0:100` y `:0:0` justo después de escribir los 100 mensajes.
- **Dos** archivos `.log` en disco tras la segunda ráfaga.
- Que el offset más antiguo deje de ser 0 sin que nadie ejecute un borrado.

---

## Transcripción

```
Error while executing topic command : Topic 'novatech.lab05.efimero' does not exist as expected

===== [t=000s] PASO 1 - describe-topic.sh novatech.fleet.gps =====
Topic: novatech.fleet.gps	TopicId: EkAoQqD3QYuv4dPGk1cvvA	PartitionCount: 6	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: novatech.fleet.gps	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 3	Leader: 3	Replicas: 3,2,1	Isr: 3,2,1	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 4	Leader: 2	Replicas: 2,1,3	Isr: 2,1,3	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 5	Leader: 1	Replicas: 1,3,2	Isr: 1,3,2	Elr: 	LastKnownElr: 
All configs for topic novatech.fleet.gps are:

===== [t=004s] PASO 2 - los tres plazos =====
  cleanup.policy=delete sensitive=false synonyms={DEFAULT_CONFIG:log.cleanup.policy=delete}
  retention.ms=604800000 sensitive=false synonyms={}
  segment.ms=604800000 sensitive=false synonyms={}

===== [t=007s] PASO 3 - create-topic.sh novatech.lab05.efimero =====
[Create Topic] novatech.lab05.efimero
  Particiones:        1
  Replication factor: 3
  Configs personalizadas:
    retention.ms=60000
    segment.ms=10000
────────────────────────────────────────────────────────
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic novatech.lab05.efimero.
  ✓ Tópico novatech.lab05.efimero creado

===== [t=008s] PASO 3b - verificar (head -2) =====
Topic: novatech.lab05.efimero	TopicId: 9dFfPq7yRZS1Wb6XPm6E-Q	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
	Topic: novatech.lab05.efimero	Partition: 0	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 

===== [t=012s] PASO 4 - produce-bulk.sh 100 =====
[Produce Bulk] 100 mensajes -> novatech.lab05.efimero
────────────────────────────────────────────────────────
  ✓ 100 mensajes publicados en 1s (~100 msg/seg)

===== [t=013s] PASO 4b - los dos extremos =====
--- --time -1 ---
novatech.lab05.efimero:0:100
--- --time -2 ---
novatech.lab05.efimero:0:0

===== [t=016s] PASO 5 - esperar 15s y escribir 5 mas =====
[Produce Bulk] 5 mensajes -> novatech.lab05.efimero
────────────────────────────────────────────────────────
  ✓ 5 mensajes publicados en 2s (~2 msg/seg)

===== [t=033s] PASO 5b - ls de los espiches en disco =====
00000000000000000000.index
00000000000000000000.log
00000000000000000000.timeindex
00000000000000000100.index
00000000000000000100.log
00000000000000000100.snapshot
00000000000000000100.timeindex
leader-epoch-checkpoint
partition.metadata

===== [t=033s] PASO 6 - esperar la ronda del broker =====
[t=052s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=069s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=087s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=104s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=122s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=139s] earliest=novatech.lab05.efimero:0:105  latest=novatech.lab05.efimero:0:105
>>> BORRO

===== [t=139s] PASO 6b - ls despues del borrado =====
00000000000000000000.index.deleted
00000000000000000000.log.deleted
00000000000000000000.timeindex.deleted
00000000000000000100.index.deleted
00000000000000000100.log.deleted
00000000000000000100.snapshot.deleted
00000000000000000100.timeindex.deleted
00000000000000000105.log
00000000000000000105.snapshot
leader-epoch-checkpoint
partition.metadata

===== [t=139s] FIN del recorrido =====
DURACION TOTAL DE EJECUCION: 139 segundos
```

---

## El número que cierra el laboratorio

```
DURACION TOTAL DE EJECUCION: 139 segundos
```

**139 segundos de ejecución** de punta a punta, de los cuales 106 fueron
esperar a que el broker hiciera su ronda. El resto del tiempo de clase es
explicación, no comandos.
