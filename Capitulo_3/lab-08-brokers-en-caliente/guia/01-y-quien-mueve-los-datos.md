# Lab 08 · Sumar un broker en caliente

## ¿Y quién mueve los datos?

> **Este es el laboratorio que enseña que agregar capacidad no es lo mismo que
> usarla.** Vas a meter un cuarto servidor a un clúster que está atendiendo, y
> el servidor va a quedarse ahí, vacío, sin hacer absolutamente nada hasta que
> alguien se lo ordene.

**Duración.** La ejecución son **33 segundos medidos** de punta a punta: 11 en
levantar el broker y 22 en mover las réplicas. En clase toma 20 minutos, porque
aquí la máquina no es el trabajo — el trabajo es entender qué pasó y qué te dejó
puesto.

**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`).

---

## 1 · EL PROBLEMA

Viene el Cyber. El equipo de NovaTech decide sumar un cuarto broker al clúster
para aguantar el pico. Levantan el servidor, lo unen al clúster, confirman que
aparece en la lista.

Y no pasa nada.

El tráfico sigue repartido entre los tres de siempre. El servidor nuevo está
encendido, sano, costando dinero, y **vacío**. Alguien pregunta cuándo empieza a
recibir carga, y la respuesta honesta es: **nunca, si nadie se lo ordena.**

El problema no es Kafka. El problema es una confusión que se paga cara:
**agregar capacidad y usar capacidad son dos operaciones distintas**, y la
segunda mueve datos por la red mientras tus clientes están conectados.

---

## 2 · LA METÁFORA

> Seguimos en el restaurante. El mozo es el broker, el tipo de comanda es el
> tópico, los sectores del salón son las particiones, el cocinero es el
> consumidor y la brigada es su grupo.

Hoy **entra un mozo nuevo a mitad de servicio**.

Ponerle el uniforme y presentarlo al equipo es una cosa. Que le toque atender
mesas es otra: alguien tiene que **reasignarle sectores del salón**, y eso
significa que un mozo que ya venía atendiendo la mesa 7 se la pasa al nuevo,
con los clientes sentados y a mitad del plato.

| En el restaurante | En Kafka |
|---|---|
| Entra el mozo nuevo y se presenta | El broker 4 arranca y se une al clúster |
| Sigue parado en la puerta | El broker 4 no tiene ninguna partición |
| Se le reparten sectores del salón | `kafka-reassign-partitions` |
| El traspaso de cada mesa, con el cliente ahí | La copia de cada réplica, con el productor escribiendo |
| El papelito con quién atendía qué antes | **El plan de vuelta** |
| «Vayan despacio, que hay clientes» | **El throttle** |

🔴 **Y las dos últimas filas son las que nadie anota**, que es exactamente de lo
que trata la segunda mitad de este laboratorio.

---

## 3 · CÓMO LO RESUELVE

`kafka-reassign-partitions` es **el comando más peligroso del curso**, y trabaja
en tres fases separadas a propósito:

| Fase | Qué hace | ¿Mueve datos? |
|---|---|---|
| `--generate` | Propone un plan y lo imprime | No |
| `--execute` | Aplica el plan. Empieza la copia | **Sí** |
| `--verify` | Pregunta cómo va, y al terminar **limpia** | No |

Están separadas porque **el plan que Kafka propone no tiene por qué gustarte**.
Entre `--generate` y `--execute` hay un hueco deliberado para que un humano lea
lo que va a pasar.

> 🔑 **Réplica**
> Una copia de una partición viviendo en un broker. `RF=3` significa tres copias
> de cada partición, en tres brokers distintos.

> 🔑 **Reasignar**
> Cambiar **en qué brokers vive** cada réplica. No cambia el número de
> particiones, no cambia el orden y no toca un solo mensaje.

Y la pieza que hace falta para leer todo lo demás:

🔴 **Reasignar es copiar gigabytes entre servidores mientras el clúster
atiende.** Compite por la misma red y los mismos discos que tus clientes. Por
eso el comando te deja **un plan de vuelta** y **un freno**, y por eso este
laboratorio trata sobre esos dos y no sobre el comando.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Se le puede agregar un servidor a un clúster que está atendiendo y moverle
> carga sin detener nada.**

Y la letra chica, que es la mitad del valor de la clase:

> ▎ **«Sin detener nada» no significa «sin que nadie lo note».** Los clientes
> reciben errores, los reintentan solos, y no se pierde un mensaje — pero la
> cola de latencia se entera.

🔴 **Aviso:** al final del recorrido vamos a mirar dos cosas que el comando te
deja y que no se ven si no las buscas: **el plan para deshacer** y **los frenos
puestos**. Saltarse la última fase deja el clúster con límites de ancho de banda
que nadie recuerda haber puesto.

---

## 5 · LOS PASOS

### Paso 1 · La foto, y el tráfico corriendo

**Se explica.**

Un clúster de tres brokers con un tópico de 6 particiones y factor de
replicación 3. Cada partición vive en tres brokers: hay **18 réplicas**
repartidas entre tres servidores.

Y para poder afirmar «sin detener nada» hace falta que **haya algo que detener**.
Antes de tocar nada, ponemos tráfico.

**Se ejecuta.** Primero la foto:

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

**Qué sale.**

```
Topic: novatech.lab08.pedidos	PartitionCount: 6	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Partition: 0	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2
	Partition: 1	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3
	Partition: 2	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1
	Partition: 3	Leader: 1	Replicas: 1,3,2	Isr: 1,3,2
	Partition: 4	Leader: 3	Replicas: 3,2,1	Isr: 3,2,1
	Partition: 5	Leader: 2	Replicas: 2,1,3	Isr: 2,1,3
```

**Cómo se lee.**

| Columna | Qué dice |
|---|---|
| `Replicas: 3,1,2` | En qué brokers vive esta partición. **El primero es el líder preferido** |
| `Leader: 3` | Quién atiende ahora las lecturas y escrituras de esta partición |
| `Isr: 3,1,2` | *In-Sync Replicas*: las copias que están al día. Si una se atrasa, sale de aquí |

🔴 **Cuenta los números y fíjate que solo aparecen el 1, el 2 y el 3.** Esa es la
foto de «antes», y es contra la que vas a comparar todo.

**Ahora el tráfico.** En **otra terminal**, y déjalo corriendo todo el
laboratorio:

```bash
kafka-cli/produce-sample.sh novatech.lab08.pedidos 300000
```

🔴 **Esto no es decorativo.** Sin un productor escribiendo, la afirmación del lab
no se puede demostrar: «no se cortó el servicio» no significa nada si no había
servicio.

---

### Paso 2 · Agregar el broker 4, y ver que no pasa nada

**Se explica.**

Se levanta un cuarto broker y se une al clúster. Fíjate en lo que **no** cambia.

**Se ejecuta.**

```bash
kafka-cli/add-broker.sh
kafka-cli/list-brokers.sh
```

**Qué sale.** Al final de `list-brokers.sh`:

```
CurrentVoters:     [{"id": 1, ...}, {"id": 2, ...}, {"id": 3, ...}]
CurrentObservers:  [{"id": 4, "directoryId": "z83V1iYQZGwmSkfysMifAw"}]
```

**Cómo se lee, y son dos cosas.**

**Una · El quórum no se tocó.** Los *voters* siguen siendo 1, 2 y 3. El broker 4
entra como **observer**: aporta capacidad de almacenamiento y de cómputo, pero
**no vota** en las decisiones del clúster.

> 🔑 **Quórum de controladores**
> El grupo de nodos que decide quién es líder de qué. Se dimensiona una vez
> —tres o cinco— y **se deja quieto**. Escalar brokers y escalar el quórum son
> decisiones distintas, y mezclarlas es una fuente clásica de problemas.

**Dos · El broker 4 está vacío.** Vuelve a mirar la foto:

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

**Ni un 4 en toda la columna `Replicas`.** Las 18 réplicas siguen exactamente
donde estaban.

🔴 **Este es el punto del laboratorio.** El servidor está encendido, sano, unido
al clúster, contando en tu factura — y no está haciendo nada. **Agregar
capacidad no mueve datos.** Alguien tiene que ordenarlo.

---

### Paso 3 · Reasignar, y mirar lo que el comando te deja

**Se explica.**

Ahora sí se reparten las réplicas entre los cuatro brokers. Mientras esto corre,
el productor del Paso 1 sigue escribiendo: eso es lo que se está demostrando.

**Se ejecuta.**

```bash
kafka-cli/reassign-partitions.sh novatech.lab08.pedidos 1,2,3,4 8000000
```

| Parte del comando | Para qué está |
|---|---|
| `novatech.lab08.pedidos` | Qué tópico se reparte |
| `1,2,3,4` | Entre qué brokers. **Los que no estén aquí quedan fuera** |
| `8000000` | El throttle: 8 MB/s de techo para la copia |

El script hace las tres fases seguidas. El comando real, que es el que vas a
escribir en el servidor de SUNAT donde no hay Docker:

```bash
kafka-reassign-partitions --bootstrap-server kafka-broker-1:29092 \
    --topics-to-move-json-file topics.json --broker-list 1,2,3,4 --generate

kafka-reassign-partitions --bootstrap-server kafka-broker-1:29092 \
    --reassignment-json-file plan.json --execute --throttle 8000000

kafka-reassign-partitions --bootstrap-server kafka-broker-1:29092 \
    --reassignment-json-file plan.json --verify
```

**Qué sale del `--execute`**, y hay que mirarlo entero:

```
Current partition replica assignment

{"version":1,"partitions":[{"topic":"novatech.lab08.pedidos","partition":0,"replicas":[3,1,2],...}]}

Save this to use as the --reassignment-json-file option during rollback
Warning: You must run --verify periodically, until the reassignment completes, to ensure the throttle is removed.
The inter-broker throttle limit was set to 8000000 B/s
Successfully started partition reassignments for novatech.lab08.pedidos-0,...
```

**Cómo se lee, y son cuatro lecturas.**

#### Lectura uno · el broker 4 ya tiene carga

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

```
	Partition: 0	Leader: 3	Replicas: 3,4,1	Isr: 1,3,4
	Partition: 1	Leader: 4	Replicas: 4,1,2	Isr: 1,2,4
	Partition: 2	Leader: 1	Replicas: 1,2,3	Isr: 2,3,1
	Partition: 3	Leader: 3	Replicas: 2,3,4	Isr: 2,3,4
	Partition: 4	Leader: 1	Replicas: 1,4,2	Isr: 1,2,4
	Partition: 5	Leader: 2	Replicas: 4,2,3	Isr: 2,3,4
```

Ahora el 4 aparece en cuatro de las seis particiones, y en la 1 **es el líder**:
está atendiendo tráfico, no solo guardando copias.

#### Lectura dos · 🔴 el plan de vuelta, que se va con el scroll

Vuelve a la primera línea de la salida del `--execute`:

```
Current partition replica assignment
{"version":1,"partitions":[... "partition":0,"replicas":[3,1,2] ...]}

Save this to use as the --reassignment-json-file option during rollback
```

**Eso es la foto de cómo estaba todo antes**, en el formato exacto que el propio
comando acepta. Kafka te está diciendo, con todas las letras, que lo guardes.

🔴 **Es lo único que te permite deshacer esta operación.** Si el plan te deja el
clúster peor —y pasa: un plan automático no sabe de tus racks, de tus discos ni
de qué partición es la caliente—, la vuelta atrás es aplicar ese JSON con
`--execute`. Si no lo guardaste, tienes que reconstruirlo a mano partición por
partición desde una foto que ya no existe.

En este lab el script te lo guarda solo:

```
Plan de VUELTA guardado en /tmp/lab08-rollback-novatech.lab08.pedidos.json
```

**En tu servidor no hay quien te lo guarde.** Se copia y se pega en un archivo
**antes** de que la consola lo tape, y en una operación de verdad se manda por
correo al equipo antes de tocar nada.

#### Lectura tres · 🔴 los frenos que quedan puestos

La otra línea que casi nadie lee:

```
Warning: You must run --verify periodically, until the reassignment completes, to ensure the throttle is removed.
The inter-broker throttle limit was set to 8000000 B/s
```

El `--throttle` le pone un techo a la copia para que no se coma el ancho de banda
de tus clientes. **Es lo correcto.** Pero ese techo no es un parámetro del
comando: son **configuraciones dinámicas que Kafka escribe en el clúster** y que
se quedan ahí.

Míralas mientras la copia corre:

```bash
kafka-cli/describe-broker-config.sh 1 | grep throttled
```

```
leader.replication.throttled.rate=8000000
follower.replication.throttled.rate=8000000
```

Y en el tópico:

```
leader.replication.throttled.replicas=0:1,0:3,0:4,1:1,...
follower.replication.throttled.replicas=0:2,1:3,3:1,4:2
```

**Quién las quita: el `--verify`.** Y solo cuando **todas** las particiones
terminaron:

```
Clearing broker-level throttles on brokers 1,2,3,4
Clearing topic-level throttles on topic novatech.lab08.pedidos
```

🔴 **Y aquí está la trampa, que está medida.** Si corres `--verify` cuando
todavía queda una partición copiando, la salida dice `still in progress`,
**no limpia nada**, y devuelve código de salida 0 igual. Un script que corre
`--verify` una sola vez y se da por satisfecho **deja el clúster con los frenos
puestos**, indefinidamente. Meses después alguien investiga por qué la
replicación va lenta y encuentra un `throttled.rate` que nadie recuerda.

> 🔴 **La regla:** `--verify` se corre **en bucle hasta que ninguna partición
> diga `in progress`.** Y después se comprueba que los throttles se fueron:
>
> ```bash
> kafka-cli/describe-broker-config.sh 1 | grep throttled
> ```
>
> Si no devuelve nada, quedó limpio.

⚠ **Un detalle que engaña:** si corres el `--execute` **sin** `--throttle`, Kafka
no pone ningún freno — pero el `--verify` imprime `Clearing ... throttles` de
todos modos. Ese mensaje **no** es prueba de que hubiera throttles. De ahí sale
la creencia de que Kafka los pone solo. No los pone: los pones tú.

#### Lectura cuatro · «sin detener nada» no es «sin que nadie lo note»

Mira el log del productor que dejaste corriendo. Vas a encontrar esto:

```
WARN [Producer clientId=perf-producer-client] Got error produce response ... on
topic-partition novatech.lab08.pedidos-1, retrying (2147483646 attempts left).
Error: NOT_LEADER_OR_FOLLOWER
```

**Hubo errores.** Cuando el liderazgo de una partición se mueve de un broker a
otro, el productor le sigue escribiendo al viejo durante unos milisegundos, y
recibe `NOT_LEADER_OR_FOLLOWER`.

Y sin embargo, el resumen final:

```
300000 records sent, 2999.610051 records/sec (1.43 MB/sec), 36.77 ms avg latency,
4025.00 ms max latency, 6 ms 50th, 10 ms 95th, 1235 ms 99th, 3927 ms 99.9th.
```

**300 000 de 300 000. Cero pérdidas. Cero errores fatales.**

| Métrica | Valor |
|---|---|
| Errores `NOT_LEADER_OR_FOLLOWER` | 1 (2 líneas `WARN`) |
| Errores fatales | **0** |
| Mensajes perdidos | **0** |
| Latencia media | 36,77 ms |
| Latencia p50 | 6 ms |
| Latencia p95 | 10 ms |
| **Latencia p99** | **1 235 ms** |
| **Latencia p99.9** | **3 927 ms** |
| **Latencia máxima** | **4 025 ms** |

🔴 **Así se lee esto.** El error es **retriable**, y el cliente lo reintenta solo:
por eso no se pierde nada y por eso se puede decir «sin downtime». Pero mira el
salto entre el p95 y el p99: **de 10 ms a 1 235 ms**. Uno de cada cien mensajes
tardó más de un segundo, uno de cada mil tardó casi cuatro, y el peor tardó más
de cuatro segundos.

> Es exactamente la lección del Lab 07, aplicada a una operación en vez de a un
> benchmark: **el promedio dice que no pasó nada y el percentil dice que sí.**
> Si tu tablero solo muestra promedios, esta operación se ve perfecta.

**Lo que esto te dice para SUNAT:** una reasignación es transparente para la
*aplicación* si los clientes tienen reintentos configurados. No es transparente
para un acuerdo de nivel de servicio escrito en percentiles. Por eso se hace
fuera de hora punta y con `--throttle`.

### ⚠ Errores probables en este paso

| Síntoma | Causa | Qué hacer |
|---|---|---|
| La reasignación termina instantáneamente | El tópico tiene muy pocos datos | Es lo esperado con el tópico recién creado. Produce volumen primero (Paso 1) o no vas a ver nada |
| `--verify` dice `still in progress` y no limpia | La copia no terminó | **Correcto.** Vuelve a correrlo hasta que todas digan `completed` |
| El productor muestra `NOT_LEADER_OR_FOLLOWER` | El liderazgo se movió | **Es lo esperado.** Mira que sean `WARN` y no `ERROR`, y que el total enviado cuadre |
| El broker 4 no aparece en `Replicas` | No corriste la reasignación, o no lo incluiste en `--broker-list` | Agregar el broker no mueve datos. Hay que reasignar |
| Se acabó la RAM de Docker | Cuatro brokers piden 8 GB | Cierra otros labs. `bin/stop-lab.sh` de lo que no uses |

---

## 6 · QUÉ QUEDÓ

### Lo que se demostró

> ▎ **Se le puede agregar un servidor a un clúster que está atendiendo y moverle
> carga sin detener nada.**

| La afirmación decía | Y en pantalla se vio |
|---|---|
| **se le puede agregar un servidor** | El broker 4 entró en 11 s, y el quórum siguió siendo 1,2,3 |
| **que está atendiendo** | Un productor escribió 300 000 mensajes durante toda la operación |
| **y moverle carga** | El broker 4 pasó de 0 réplicas a estar en 4 de 6 particiones, y a ser líder de una |
| **sin detener nada** | 0 mensajes perdidos, 0 errores fatales, 33 s de punta a punta |
| **pero no sin que nadie lo note** | p99 de 1 235 ms contra un p95 de 10 ms |

### Las cuatro reglas, para llevarse a SUNAT

**1 · Agregar capacidad y usar capacidad son dos operaciones.**
Un broker nuevo entra vacío y se queda vacío. Si nadie reasigna, pagaste un
servidor para nada. Y al revés: si alguien reasigna sin avisar, se está moviendo
tráfico de producción por la red.

**2 · El plan de vuelta se guarda antes de ejecutar.**
Lo imprime el `--execute` y se lo lleva el scroll. Es lo único que permite
deshacer. En una operación de verdad se guarda en un archivo y se manda al
equipo **antes** de tocar nada.

**3 · `--verify` se corre en bucle, hasta que ninguna partición diga
`in progress`.**
Es la fase que limpia. Saltársela —o correrla una sola vez, antes de tiempo—
deja el clúster con límites de replicación puestos que nadie va a recordar. Y
comprueba después que se fueron.

**4 · «Sin downtime» se afirma con percentiles, no con promedios.**
No se perdió un mensaje. Y el p99 pasó de milisegundos a más de un segundo. Las
dos cosas son verdad, y la segunda es la que el usuario nota.

### La lectura que se usa para todo

> **Toda operación en caliente deja dos rastros: una forma de deshacerla y algo
> encendido que hay que apagar. Si no sabes cuáles son, no terminaste la
> operación.**

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue está fuera del recorrido de hoy **por tiempo, no por
dificultad**. **Los comandos de esta sección se ejecutaron uno por uno contra
este mismo clúster antes de publicarlos**, así que corren tal cual están
escritos.

### A · Deshacer de verdad: aplicar el plan de vuelta

Es el ejercicio que convierte la Lectura dos en un músculo. El plan que el script
guardó es aplicable tal cual:

```bash
docker cp /tmp/lab08-rollback-novatech.lab08.pedidos.json kafka-broker-1:/tmp/rollback.json
docker exec kafka-broker-1 kafka-reassign-partitions \
    --bootstrap-server kafka-broker-1:29092 \
    --reassignment-json-file /tmp/rollback.json --execute
docker exec kafka-broker-1 kafka-reassign-partitions \
    --bootstrap-server kafka-broker-1:29092 \
    --reassignment-json-file /tmp/rollback.json --verify
```

**Verificado:** las 6 particiones vuelven exactamente a la asignación previa,
réplica por réplica y en el mismo orden. La salida está en `soluciones/SALIDAS.md`.

🔴 **Y una advertencia que vale la sección entera:** deshacer **no es gratis**.
Es otra reasignación completa, con su propia copia de datos, su propio impacto y
su propio plan de vuelta. «Puedo revertirlo» no significa «puedo revertirlo sin
consecuencias».

### B · Ver los throttles con las manos

Mientras una reasignación con `--throttle` está corriendo:

```bash
kafka-cli/describe-broker-config.sh 1 | grep throttled
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

Y el experimento que cierra la duda: corre una reasignación con `--throttle`,
haz **un solo** `--verify` inmediatamente, y vuelve a mirar. Medido:

```
throttles despues del verify prematuro:
  leader.replication.throttled.rate=8000000     <-- siguen puestos
```

Para limpiarlos a mano, si te quedaste con ellos:

```bash
docker exec kafka-broker-1 kafka-configs --bootstrap-server kafka-broker-1:29092 \
    --alter --entity-type brokers --entity-name 1 \
    --delete-config leader.replication.throttled.rate,follower.replication.throttled.rate
```

### C · Drenar el broker y sacarlo

Pasó el pico y hay que devolver el servidor. **Apagarlo en seco pierde las
réplicas que tiene**: primero se mueven a los que se quedan.

```bash
kafka-cli/drain-broker.sh novatech.lab08.pedidos 1,2,3
kafka-cli/describe-topic.sh novatech.lab08.pedidos     # ni un 4
docker compose -f infra/docker-compose.yml --profile scale stop kafka-broker-4
kafka-cli/list-brokers.sh
```

**Lo que hay que mirar:** el clúster sigue operativo con 3 brokers y **el quórum
no se enteró**, porque el 4 nunca fue *voter*. Es la contraparte del Paso 2.

### D · Configuración dinámica de brokers

Cambiar parámetros del broker sin reiniciar: qué es *read-only*, qué es dinámico
por-broker y qué es dinámico *cluster-wide*, cómo se lee el `describe` y cómo se
interpretan los `synonyms`.

```bash
kafka-cli/describe-broker-config.sh 1
kafka-cli/alter-broker-config.sh 1 num.replica.fetchers=2
```

🔴 **Esto ya lo dictó el Lab 03 entero** —el drift entre el archivo y lo
efectivo, la validación del doble, los `synonyms`—. Aquí queda como referencia y
como el ejercicio del desafío, no como material nuevo.

### E · El ciclo completo, con tráfico

La prueba de fuego, y el entregable del lab. Con un productor corriendo en
segundo plano:

1. Agrega el broker 4.
2. Reasigna a los 4 brokers, **con `--throttle`**.
3. Guarda el plan de vuelta en un archivo con nombre y fecha.
4. Cambia `num.replica.fetchers=2` en caliente en el broker 4.
5. Drena el broker 4 y apágalo.
6. **Comprueba que no quedó ningún `throttled` en ningún broker.**

Documenta: ¿hubo pérdida de mensajes? ¿cuál fue el paso más lento? ¿cuánto se
movió el p99.9 del productor? ¿el clúster quedó limpio?

### F · El reporte del lab

Está en `plantillas/reporte-entregable.md`.

---

## Cierre

Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Lo que te llevas:** la próxima vez que alguien diga «agregamos un servidor al
clúster», la primera pregunta ya no es «¿está arriba?». Es **«¿le movieron
carga, guardaron el plan de vuelta, y comprobaron que no quedó nada
encendido?»**.

**Siguiente:** Lab 08b — instalación sobre RHEL.
