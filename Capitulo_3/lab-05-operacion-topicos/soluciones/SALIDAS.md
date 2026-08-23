# Lab 05 · SALIDAS — la corrida real

> **Esto no es un ejemplo escrito a mano.** Es la transcripción literal de una
> corrida completa de los 5 pasos de la guía, comando por comando, contra el
> clúster de tres brokers del laboratorio. Los tiempos `[t=NNNs]` son segundos
> desde el inicio del recorrido.
>
> **Para qué sirve:** para contrastar. Si a ti te salió algo distinto, aquí
> puedes ver si la diferencia importa o no.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total** | **217 s** |
| De eso, esperando la ronda del broker (Paso 5) | **193 s** |
| Todo lo demás (4 pasos, 9 comandos) | **24 s** |

🔴 **Los 193 segundos de espera son el número que más varía.** El broker revisa
la retención cada 5 minutos (`log.retention.check.interval.ms=300000`) y tú
llegas en un punto cualquiera de esa ronda: puede tocarte casi nada o casi los
300. En otras corridas medidas fueron **260 s**, **212 s** y **106 s**. No es un
fallo, es el mecanismo.

## Lo que va a ser distinto en tu máquina

| Valor | Por qué cambia |
|---|---|
| `TopicId` | Se genera al crear el tópico. Siempre distinto |
| `Leader:` y el orden de `Replicas:` | Kafka reparte los líderes al crear. Lo que **no** cambia es que `Isr` tenga los mismos tres números que `Replicas` |
| El `[t=NNNs]` en que el offset cambia | La ronda del broker. Ver arriba |
| `:0:105` o `:0:100` al final | Si la ronda llega antes de que venzan los 5 de la segunda ráfaga, quedan 5 vivos en vez de 0. Las dos salidas demuestran lo mismo |

## Lo que **no** debería cambiar

- `Configs:` con tres valores en `novatech.lab05.efimero` tras crearlo.
- `:0:100` y `:0:0` justo después de escribir los 100 mensajes.
- **Dos** archivos `.log` en disco tras la segunda ráfaga.
- Que el offset más antiguo deje de ser 0 sin que nadie ejecute un borrado.
- Que los espiches viejos aparezcan renombrados a `.deleted` antes de desaparecer.

---

## Transcripción

```

===== [t=000s] PASO 1 · crear el topico de la demostracion =====
WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
Created topic novatech.lab05.efimero.
  ✓ Tópico novatech.lab05.efimero creado

===== [t=001s] PASO 2 · describirlo y leer la linea Configs =====
Topic: novatech.lab05.efimero	TopicId: dBn0wnH_SIKGYMgNDgfgwA	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
	Topic: novatech.lab05.efimero	Partition: 0	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 

===== [t=004s] PASO 3 · 100 comprobantes y los dos extremos =====
  ✓ 100 mensajes publicados en 1s (~100 msg/seg)
novatech.lab05.efimero:0:100
novatech.lab05.efimero:0:0

===== [t=007s] PASO 4 · cerrar el espiche =====
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

===== [t=024s] PASO 5 · esperar la ronda del broker =====
[t=025s] novatech.lab05.efimero:0:0
[t=046s] novatech.lab05.efimero:0:0
[t=068s] novatech.lab05.efimero:0:0
[t=089s] novatech.lab05.efimero:0:0
[t=110s] novatech.lab05.efimero:0:0
[t=131s] novatech.lab05.efimero:0:0
[t=153s] novatech.lab05.efimero:0:0
[t=174s] novatech.lab05.efimero:0:0
[t=195s] novatech.lab05.efimero:0:0
[t=217s] novatech.lab05.efimero:0:105

--- y en disco ---
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

===== [t=217s] FIN =====
```

---

## Nota sobre la línea base

Esta corrida arrancó con el tópico **borrado y verificado como inexistente**.
Si repites el recorrido sin borrar `novatech.lab05.efimero`, los offsets
arrancan donde quedó la corrida anterior (`:0:105`, `:0:205`…) y la ronda del
broker puede disparar en segundos, porque ya hay un espiche vencido de antes.
**La demostración se ve, pero los números no cuadran con esta transcripción.**

```bash
kafka-cli/delete-topic.sh novatech.lab05.efimero
```

⚠️ Ese comando **pide que escribas el nombre del tópico para confirmar**. Si lo
llamas desde un script sin darle esa confirmación por la entrada estándar, no
borra nada y no falla: sigue de largo.

---

## Lo que salió del recorrido y dónde quedó

Este laboratorio tenía ocho pasos y hoy tiene cinco. Lo que salió no se perdió:
está en la sección **7 · PARA PROFUNDIZAR** de la guía, con su comando y su
salida real.

| Salió del recorrido | Dónde está |
|---|---|
| Describir `novatech.fleet.gps` y la cuenta de los 7 + 7 días | *Para profundizar G* |
| La compactación y las claves `NVT-` | *Para profundizar B* |
| El `--alter` de configuración en caliente | *Para profundizar C* |
