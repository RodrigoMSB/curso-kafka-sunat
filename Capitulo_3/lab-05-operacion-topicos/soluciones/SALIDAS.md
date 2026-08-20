# Lab 05 · SALIDAS — la corrida real

> **Esto no es un ejemplo escrito a mano.** Es la transcripción literal de una
> corrida completa de los 8 pasos de la guía, comando por comando, contra el
> clúster de tres brokers del laboratorio. Los tiempos `[t=NNNs]` son segundos
> desde el inicio del recorrido.
>
> **Para qué sirve:** para contrastar. Si a ti te salió algo distinto, aquí
> puedes ver si la diferencia importa o no.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total** | **256 s** |
| De eso, esperando la ronda del broker (Paso 6) | **212 s** |
| Todo lo demás (7 pasos, 11 comandos) | **44 s** |

🔴 **Los 212 segundos de espera son el número que más varía.** El broker revisa
la retención cada 5 minutos (`log.retention.check.interval.ms=300000`) y tú
llegas en un punto cualquiera de esa ronda: puede tocarte casi nada o casi los
300. En otra corrida medida fueron **106 s**. No es un fallo, es el mecanismo.

## Lo que va a ser distinto en tu máquina

| Valor | Por qué cambia |
|---|---|
| `TopicId` | Se genera al crear el tópico. Siempre distinto |
| `Leader:` y el orden de `Replicas:` | Kafka reparte los líderes al crear. Lo que **no** cambia es que `Isr` tenga los mismos tres números que `Replicas` |
| El `[t=NNNs]` en que el offset cambia | La ronda del broker. Ver arriba |
| `:0:105` o `:0:100` al final | Si la ronda llega antes de que venzan los 5 de la segunda ráfaga, quedan 5 vivos en vez de 0. Las dos salidas demuestran lo mismo |
| El **orden** de las claves `NVT-` del Paso 7 | Cada clave cae en la partición que le toca por su *hash*, y el consumidor lee partición por partición. En esta corrida salieron en orden; en otra salieron `3,4,5,6,1,2` |

## Lo que **no** debería cambiar

- `retention.ms=604800000` y `segment.ms=604800000` en `novatech.fleet.gps` — son los valores de fábrica.
- `Configs:` con tres valores en `novatech.lab05.efimero` tras crearlo.
- `:0:100` y `:0:0` justo después de escribir los 100 mensajes.
- **Dos** archivos `.log` en disco tras la segunda ráfaga.
- Que el offset más antiguo deje de ser 0 sin que nadie ejecute un borrado.
- Que las claves del Paso 7 lleguen como `NVT-N` y **no** como `null`.
- Que el `Configs` del Paso 8 pase de `retention.ms=60000` a `retention.ms=3600000` sin reiniciar nada.

---

## Transcripción

```

===== [t=000s] PASO 1 · describe-topic.sh novatech.fleet.gps =====
Topic: novatech.fleet.gps	TopicId: i_Kc6cToTbGyJGMSZQpolw	PartitionCount: 6	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: novatech.fleet.gps	Partition: 0	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 1	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 2	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 3	Leader: 2	Replicas: 2,1,3	Isr: 2,1,3	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 4	Leader: 1	Replicas: 1,3,2	Isr: 1,3,2	Elr: 	LastKnownElr: 
	Topic: novatech.fleet.gps	Partition: 5	Leader: 3	Replicas: 3,2,1	Isr: 3,2,1	Elr: 	LastKnownElr: 
All configs for topic novatech.fleet.gps are:

===== [t=003s] PASO 2 · los tres plazos =====
  cleanup.policy=delete sensitive=false synonyms={DEFAULT_CONFIG:log.cleanup.policy=delete}
  retention.ms=604800000 sensitive=false synonyms={}
  segment.ms=604800000 sensitive=false synonyms={}

===== [t=006s] PASO 3 · crear el efimero =====
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic novatech.lab05.efimero.
  ✓ Tópico novatech.lab05.efimero creado
Topic: novatech.lab05.efimero	TopicId: aLJ5h-SFTV-cqyeLB3k_aA	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000

===== [t=010s] PASO 4 · 100 mensajes y los dos extremos =====
  ✓ 100 mensajes publicados en 1s (~100 msg/seg)
novatech.lab05.efimero:0:100
novatech.lab05.efimero:0:0

===== [t=014s] PASO 5 · cerrar el espiche =====
  ✓ 5 mensajes publicados en 1s (~5 msg/seg)
00000000000000000000.index
00000000000000000000.log
00000000000000000000.timeindex
00000000000000000100.index
00000000000000000100.log
00000000000000000100.snapshot
00000000000000000100.timeindex
leader-epoch-checkpoint
partition.metadata

===== [t=030s] PASO 6 · esperar la ronda =====
[t=048s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=065s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=083s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=100s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=118s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=136s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=154s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=172s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=189s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=207s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=224s] earliest=novatech.lab05.efimero:0:0  latest=novatech.lab05.efimero:0:105
[t=242s] earliest=novatech.lab05.efimero:0:105  latest=novatech.lab05.efimero:0:105
>>> BORRO
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

===== [t=242s] PASO 7 · la condicion previa de la compactacion =====
  ✓ 6 mensajes publicados en 2s (~3 msg/seg)
NVT-1|evento_1_payload
NVT-2|evento_2_payload
NVT-3|evento_3_payload
NVT-4|evento_4_payload
NVT-5|evento_5_payload
NVT-6|evento_6_payload
Processed a total of 6 messages

===== [t=249s] PASO 8 · --alter en caliente =====
Topic: novatech.lab05.efimero	TopicId: aLJ5h-SFTV-cqyeLB3k_aA	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
Completed updating config for topic novatech.lab05.efimero.
  ✓ Configs aplicadas
Topic: novatech.lab05.efimero	TopicId: aLJ5h-SFTV-cqyeLB3k_aA	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=3600000,segment.ms=10000

===== [t=256s] FIN =====
DURACION TOTAL DE EJECUCION: 256 segundos
```
