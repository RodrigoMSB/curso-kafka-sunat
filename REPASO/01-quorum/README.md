# Repaso 01 · El quórum

Un repaso corto. No necesitas haber hecho el laboratorio 02 ni tener nada levantado.

**Dura unos cinco minutos.** Levanta su propio clúster de tres nodos, en puertos que no chocan con ningún laboratorio, y al terminar no deja nada en tu máquina.

## Qué vas a entender

El quórum es la mayoría de controladores que tienen que estar de acuerdo para que el clúster pueda decidir algo. Con tres nodos la mayoría es dos, así que el clúster aguanta perder uno.

Con dos caídos ya no hay mayoría. Y ahí aparece lo que hace este repaso memorable. El clúster sigue contestando lo que ya sabía, pero no puede aprender nada nuevo.

## Cómo levantarlo

```bash
cd REPASO/01-quorum
bash bin/start.sh
```

Levanta tres nodos KRaft y espera a que los tres respondan. La primera vez tarda más, porque Docker descarga la imagen de Kafka.

## Acto 1 · El quórum sano

```bash
docker exec repaso-quorum-1 kafka-metadata-quorum \
  --bootstrap-server repaso-quorum-1:29092 describe --status
```

`docker exec repaso-quorum-1` entra al primer nodo. `kafka-metadata-quorum` es la herramienta que reporta el estado del quórum. `--bootstrap-server` le dice a qué nodo preguntar, y `29092` es el puerto interno con que los nodos se hablan entre ellos. `describe --status` pide el resumen.

Vas a ver algo así.

```
ClusterId:              UmVwYXNvUXVvcnVtMDFBQg
LeaderId:               3
LeaderEpoch:            1
HighWatermark:          32
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   10
CurrentVoters:          [{"id": 1, "endpoints": [...]}, {"id": 2, ...}, {"id": 3, ...}]
CurrentObservers:       []
```

**Cómo se lee.** Hay tres votantes en `CurrentVoters`, y uno de ellos es el líder. El número que te salga en `LeaderId` puede ser 1, 2 o 3, porque el líder se elige y no siempre gana el mismo. `LeaderEpoch` es el contador de elecciones. Empieza en 1 y sube cada vez que hay una nueva. `HighWatermark` es cuántos registros de metadatos lleva escritos el clúster, así que en tu máquina será otro número.

## Acto 2 · Cae uno

```bash
docker stop repaso-quorum-3
```

Detiene el tercer nodo. Quedan dos de tres, que siguen siendo mayoría. Ahora pídele al clúster que decida algo nuevo.

```bash
docker exec repaso-quorum-1 kafka-topics \
  --bootstrap-server repaso-quorum-1:29092 \
  --create --topic repaso.con-dos --partitions 1 --replication-factor 2
```

`kafka-topics --create` pide crear un tópico, que es una decisión que el quórum tiene que aprobar. `--replication-factor 2` pide dos copias, que es lo máximo que puedes pedir con dos nodos vivos.

```
WARNING: Due to limitations in metric names, topics with a period ('.') or
underscore ('_') could collide. To avoid issues it is best to use either,
but not both.
Created topic repaso.con-dos.
```

Ese `WARNING` sale siempre que un nombre de tópico mezcla puntos y guiones bajos. No es un error y no impide nada.

**Cómo se lee.** El tópico se creó. Perdiste un nodo y el clúster sigue decidiendo, porque dos de tres alcanzan para la mayoría. Esto es lo que significa tolerar una caída.

## Acto 3 · Cae el segundo

```bash
docker stop repaso-quorum-2
```

Queda un solo nodo de tres. Uno no es mayoría. Ahora vienen dos comandos, y la gracia está en compararlos.

Primero, pregúntale por lo que ya sabe.

```bash
docker exec repaso-quorum-1 kafka-topics \
  --bootstrap-server repaso-quorum-1:29092 --list
```

```
repaso.con-dos
```

Responde al instante, y con código de salida 0. Todo parece normal.

Ahora pídele algo nuevo.

```bash
docker exec repaso-quorum-1 kafka-topics \
  --bootstrap-server repaso-quorum-1:29092 \
  --create --topic repaso.sin-mayoria --partitions 1 --replication-factor 1
```

Este tarda alrededor de un minuto antes de rendirse. La espera es parte de lo que estás viendo, porque Kafka reintenta hasta que se le acaba el plazo.

```
Error while executing topic command : Call(callName=createTopics, deadlineMs=...,
tries=1, nextAllowedTryMs=...) timed out at ... after 1 attempt(s)
[...] ERROR org.apache.kafka.common.errors.TimeoutException: Call(...) timed out
Caused by: org.apache.kafka.common.errors.DisconnectException: Cancelled
createTopics request with correlation id 3 due to node 1 being disconnected
```

El código de salida es 1, frente al 0 del comando anterior.

**Cómo se lee.** Y aquí está el punto de todo el repaso. El mismo clúster, en el mismo momento, contesta una cosa y falla la otra. El `--list` funciona porque lee de una copia local que el nodo ya tenía guardada. El `--create` falla porque escribir exige que la mayoría esté de acuerdo, y no hay mayoría.

**Un tablero que solo consulta te va a decir que el clúster está sano.** Está contestando. Lo que no puede es decidir.

## Cierre · El quórum se rehace solo

```bash
docker start repaso-quorum-2 repaso-quorum-3
```

Espera unos veinte segundos y vuelve a mirar el estado.

```bash
docker exec repaso-quorum-1 kafka-metadata-quorum \
  --bootstrap-server repaso-quorum-1:29092 describe --status
```

```
LeaderId:               1
LeaderEpoch:            4
```

**Cómo se lee.** Compara con el acto 1. El líder cambió y `LeaderEpoch` subió de 1 a 4. Cada número de más es una elección que ocurrió mientras los nodos iban y venían. Nadie las ordenó. El quórum se rehace solo en cuanto vuelve a haber mayoría.

## Qué quedó

Con tres controladores, la mayoría es dos, y por eso se aguanta perder uno.

Con dos caídos no hay mayoría, y el clúster deja de poder decidir aunque siga respondiendo consultas.

Por eso los controladores se despliegan en número impar, y por eso un chequeo de salud que solo lee no alcanza para saber si el clúster está bien.

## Cómo bajarlo

```bash
bash bin/stop.sh
```

Borra los tres contenedores, sus volúmenes y su red, y te muestra las tres cuentas en cero para que compruebes que tu máquina quedó como estaba.
