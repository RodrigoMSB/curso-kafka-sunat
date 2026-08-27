# Lab 10 · Kafbat UI y REST Proxy

## ¿Y a las tres de la mañana?

> **Este es el único laboratorio del curso que se hace mirando, no tecleando.**
> Y termina con una advertencia, porque una interfaz bonita es la forma más
> rápida de perder la costumbre de la línea de comandos — que es lo único que
> siempre va a estar.

**Duración.** Si lo repites tú solo, la corrida completa tomó **13 segundos
medidos** de punta a punta, en 11 comandos. Casi todo el tiempo de clase se va
en la pantalla del navegador, que no se cronometra en segundos.

🔴 **Un aviso sobre los números de partición de esta guía.** Los tres mensajes
que siembra el `start-lab.sh` van **sin clave**, así que el productor elige una
partición y mete los tres ahí. **Cuál elige cambia en cada arranque:** en las
corridas medidas fueron la 2 y la 0. Las salidas de abajo son de una corrida
real con la 2. **Si a ti te toca otra, no está roto** — lo único que importa es
que dos particiones queden en cero y una con todo.
**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`),
con sus 3 brokers, el REST Proxy en el 8082 y Kafbat UI en el **8090**.

---

## 1 · EL PROBLEMA

Llevas cinco laboratorios leyendo tablas de texto separadas por tabuladores. Es
lento, es incómodo, y hay algo que no has podido hacer ni una vez: **mirar el
clúster entero a la vez**.

Cuando alguien pregunta *«¿cómo va todo?»*, no hay un comando que conteste eso.
Hay que preguntar tópico por tópico, grupo por grupo, y armar el cuadro en la
cabeza. Para un clúster con cuatro tópicos se puede. Para uno con doscientos, no.

Y ahí aparece la solución obvia y la trampa que trae puesta.

**La solución obvia:** una interfaz web que lo dibuje. Existe, está en este
laboratorio, y es buenísima.

**La trampa:** que el equipo se acostumbre a que el clúster *es* lo que se ve en
esa pantalla. Y entonces llega el día en que hay un incidente a las tres de la
mañana, y alguien entra por SSH a un servidor donde no hay navegador, ni túnel,
ni la interfaz levantada — y no sabe qué escribir.

Hay una segunda mitad, más incómoda: **la interfaz es una cosa más que se puede
caer.** Es un contenedor con su propia memoria, su propia versión y su propia
forma de romperse. Un tablero caído se parece muchísimo a un clúster caído, si
no sabes distinguirlos. **El Paso 4 los distingue en vivo.**

---

## 2 · LA METÁFORA

Durante todo el curso Kafka es **un restaurante**. Vale la pena repasar el
reparto antes de seguir.

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| Las libretas de respaldo que copian cada comanda | Las **réplicas** |
| El equipo que se reparte los sectores del salón | El **grupo de consumidores** |

Las piezas de hoy:

| En el restaurante | En Kafka |
|---|---|
| **El pizarrón del salón**: el tablero donde el jefe de turno ve de un vistazo qué sectores están cubiertos y cuál se está atrasando | **Kafbat UI** |
| **La ventanilla de la calle**: por donde un repartidor de afuera deja un pedido sin entrar al local ni conocer a nadie | **REST Proxy** |

Lo que importa del pizarrón, y es el corazón de este laboratorio:

**El pizarrón no atiende mesas.** No cocina, no lleva platos, no cobra. Lo único
que hace es **decirte a qué mesa correr**. Un jefe de turno que mira el pizarrón
y entiende que la mesa 12 lleva veinte minutos esperando es un buen jefe de
turno. Uno que se queda mirando el pizarrón, no.

Y esto, que es lo que hay que ver hoy en pantalla:

> 🍽 **Si se borra el pizarrón, el restaurante sigue funcionando exactamente
> igual. Lo único que se perdió es tu forma cómoda de mirarlo.**

De ahí sale la única regla que necesitas para entender todo lo demás: **el
tablero no es el clúster. Es una vista del clúster.**

---

## 3 · CÓMO LO RESUELVE

Dos piezas, y conviene no confundirlas porque hacen cosas opuestas.

> 🖥 **Kafbat UI**
> Una aplicación web —aquí, el contenedor `kafbat-ui`, en
> **http://localhost:8090**— que se conecta al clúster como **un cliente más** y
> dibuja lo que encuentra. 🔴 **No tiene datos propios.** Todo lo que muestra se
> lo preguntó a los brokers en el momento de dibujarlo.

> 🚪 **REST Proxy**
> Un servicio —el contenedor `kafka-rest`, en **http://localhost:8082**— que
> traduce HTTP al protocolo de Kafka. Existe para el sistema que **no puede**
> tener un cliente de Kafka: un lenguaje sin biblioteca decente, un sistema
> antiguo, o un socio al otro lado de un cortafuegos que solo deja pasar HTTP.

La diferencia que hay que tener clara:

| | Kafbat UI | REST Proxy |
|---|---|---|
| Para quién es | **Para ti**, el administrador | **Para otro sistema** |
| Qué hace | Mira, sobre todo | Escribe y lee |
| Si se cae | Te quedas sin vista | Ese sistema se queda sin Kafka |

🔴 **Y la advertencia que trae REST Proxy**, porque es la pregunta que un
administrador tiene que saber contestar: **es un intermediario más**. Cada
mensaje pasa por él, así que es un punto que se satura, que se cae, y que hay
que dimensionar y vigilar. **Si el sistema puede usar un cliente nativo, debe
usar un cliente nativo.** REST Proxy es para cuando no puede.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Todo lo que viste por consola está aquí dibujado — y aun así la consola es
> lo que vas a tener a las tres de la mañana.**

Tres partes, y las tres se ven en pantalla:

- **está aquí dibujado** — vas a poner lado a lado la salida de un comando y la
  pantalla que la dibuja, y van a ser los mismos números;
- **dibujado mejor** — hay una cosa que el tablero hace de verdad mejor, y vas a
  verla;
- **y aun así** — vas a apagar el tablero y comprobar que **el clúster no se
  entera**.

---

## 5 · LOS PASOS

### Paso 1 · Qué hay que mirar, antes de mirarlo

**Se explica.**

El laboratorio arranca con el tópico ya poblado: el `start-lab.sh` le mete tres
pedidos **por HTTP** al levantarse. Vamos a saber exactamente qué hay antes de
abrir el navegador, porque si no, el tablero solo va a ser bonito.

> 📋 **Tópico**
> El nombre bajo el que se agrupan mensajes del mismo tipo. No es una tabla ni
> una cola: es un registro que solo crece por el final. Es el tipo de comanda.

> 🍰 **Partición**
> Cada uno de los pedazos en que se corta un tópico. Este tiene **tres**. Son los
> sectores del salón: por eso el trabajo se puede repartir.

> 🔢 **Offset**
> El número de orden de un mensaje dentro de su partición. Empieza en 0 y solo
> sube. El offset «más nuevo» es, en la práctica, la cuenta de mensajes de esa
> partición.

**Se ejecuta.**

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.lab10.pedidos
```

**Qué sale.**

```
Topic: novatech.lab10.pedidos	TopicId: QbFBzWeXTwaExIYa7BPG8A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: novatech.lab10.pedidos	Partition: 0	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr:
	Topic: novatech.lab10.pedidos	Partition: 1	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr:
	Topic: novatech.lab10.pedidos	Partition: 2	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr:
```

**Cómo se lee.** Es la misma salida del Lab 05, y hoy la vamos a usar de otra
manera: como **la respuesta correcta** contra la que vamos a comparar el
tablero. Quédate con tres cosas: **3 particiones**, **RF 3**, y las tres con sus
tres réplicas en ISR.

Y ahora dónde están los mensajes:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1
```

**Qué sale.**

```
novatech.lab10.pedidos:0:0
novatech.lab10.pedidos:1:0
novatech.lab10.pedidos:2:3
```

🔴 **Detente aquí, porque esto es más interesante de lo que parece.** Hay tres
mensajes, y **los tres están en la misma partición**. Las otras dos están
vacías.

No es un error: los tres se escribieron **sin clave**, y un productor sin clave
se pega a una partición durante su tanda. *(Si en tu corrida la partición llena
es la 0 o la 1 en vez de la 2, es normal, y de ahí en adelante todos los números
de partición de esta guía se te corren a esa. Ya está medido en las dos.)*

**La pregunta que vale, y que el tablero va a contestar de un vistazo:** en un
tópico de doscientas particiones, ¿cómo te enterarías tú de que ciento noventa
están vacías?

---

### Paso 2 · La misma verdad, dos veces

**Se explica.**

Ahora se abre el navegador. **No es un paso decorativo:** vas a comparar campo
por campo con lo que acabas de leer.

**Se ejecuta.** Abre **http://localhost:8090**.

🔴 **El puerto es el 8090, no el 8080.** Por dentro el contenedor escucha en el
8080 y el `docker-compose.yml` lo publica en el 8090, para no chocar con
cualquier otra cosa que uses. Si escribes 8080 no hay nadie.

**Qué se ve, y dónde:**

| Dónde hacer clic | Qué buscar | Con qué comando lo comprobaste |
|---|---|---|
| **Dashboard** (la pantalla de entrada) | El clúster `novatech-cluster`, en verde, con **3 brokers** | El `bin/90-test-lab.sh` |
| **Brokers** | Tres filas, 1, 2 y 3 | — |
| **Topics** → `novatech.lab10.pedidos` | **Partitions: 3**, **Replication Factor: 3** | La primera línea del `--describe` |
| Pestaña **Partitions** de ese tópico | Tres filas, con su *Leader* y sus réplicas | Las tres líneas `Partition:` del `--describe` |
| La columna de mensajes por partición | 🔴 **Dos particiones en 0 y una en 3** | El `kafka-get-offsets` |
| Pestaña **Messages** | Los tres pedidos, como JSON legible | — |

**Cómo se lee.** Los números son **los mismos**. No hay un solo dato en esa
pantalla que no hayas podido sacar de la línea de comandos.

Y aquí está la primera mitad de la afirmación, que conviene decir en voz alta:
🔴 **el tablero no sabe nada que tú no puedas averiguar.** Es un cliente de
Kafka, igual que la consola, igual que el programa Java del Lab 09. Le pregunta
a los brokers y dibuja lo que le contestan.

**Lo que sí hace mejor**, y es honesto reconocerlo: el desbalance de particiones
—dos en cero y una en tres— en la consola son tres líneas que hay que sumar a
ojo. En la pantalla es una barra que está torcida. **En un tópico de doscientas
particiones esa diferencia deja de ser cómoda y pasa a ser la única forma
práctica.**

---

### Paso 3 · Lo que el tablero suma por ti

**Se explica.**

Vamos a fabricar el problema más común de operación —un consumidor que se quedó
atrás— y a mirarlo por los dos lados.

> 👥 **Grupo de consumidores**
> Varios consumidores que comparten un nombre de grupo y se reparten las
> particiones de un tópico. Kafka guarda por dónde va **el grupo**, no cada
> consumidor.

> 📉 **Lag** (retraso)
> Cuántos mensajes hay escritos que el grupo todavía no leyó. Es la diferencia
> entre el offset final del tópico y el offset por donde va el grupo. **Es el
> número que se vigila en producción**, más que ningún otro.

**Se ejecuta.** Primero, un grupo que lee lo que hay y se va:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --group fiscalizacion --from-beginning --max-messages 3
```

| Parte del comando | Para qué está |
|---|---|
| `--group fiscalizacion` | 🔴 **Sin grupo no hay lag que medir.** Kafka solo guarda el avance de un grupo con nombre |
| `--max-messages 3` | Lee los tres que hay y sale |

Ahora llegan cinco pedidos más **por la ventanilla de la calle** — y de paso
esto es todo el REST Proxy que este laboratorio necesita:

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.kafka.json.v2+json" \
    --data '{"records":[{"value":{"pedido":2001}},{"value":{"pedido":2002}},{"value":{"pedido":2003}},{"value":{"pedido":2004}},{"value":{"pedido":2005}}]}' \
    http://localhost:8082/topics/novatech.lab10.pedidos
```

| Parte del comando | Para qué está |
|---|---|
| `-X POST` a `/topics/<tópico>` | Producir por HTTP es **un POST y ya**. No hay sesión ni estado |
| `-H "Content-Type: application/vnd.kafka.json.v2+json"` | 🔴 El tipo de contenido propio del REST Proxy. Le dice **dos cosas a la vez**: que hablas su versión 2 y que los valores van en JSON. Con `Content-Type: application/json` a secas contesta `415` |
| `--data '{"records":[...]}'` | Los mensajes. **Un POST puede llevar varios**, y por eso van dentro de una lista |

**Qué sale.**

```
{"offsets":[{"partition":2,"offset":3,"error_code":null,"error":null},{"partition":2,"offset":4,"error_code":null,"error":null},{"partition":2,"offset":5,"error_code":null,"error":null},{"partition":2,"offset":6,"error_code":null,"error":null},{"partition":2,"offset":7,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":null}
HTTP 200
```

**Cómo se lee.** Una entrada por mensaje, cada una con **la partición y el
offset donde quedó**. Es exactamente lo que el broker le contestó al programa
Java del Lab 09 — el mismo dato, por HTTP. Y el `error` en `null` de cada una es
lo que hay que mirar en producción: **un POST puede devolver `200` y traer
errores adentro**, si alguno de los mensajes de la tanda falló.

Ahora, el retraso, por la consola:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group fiscalizacion
```

**Qué sale.**

```
Consumer group 'fiscalizacion' has no active members.

GROUP           TOPIC                  PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
fiscalizacion   novatech.lab10.pedidos 0          0               0               0               -               -               -
fiscalizacion   novatech.lab10.pedidos 1          0               0               0               -               -               -
fiscalizacion   novatech.lab10.pedidos 2          3               8               5               -               -               -
```

**Cómo se lee.**

| Columna | Qué dice |
|---|---|
| `has no active members` | Nadie está consumiendo ahora mismo. El grupo existe porque dejó su marca, pero está parado |
| `CURRENT-OFFSET 3` | Por dónde va el grupo en la partición 2 |
| `LOG-END-OFFSET 8` | Hasta dónde llegó el tópico |
| `LAG 5` | 🔴 **Los cinco que entraron por HTTP y nadie leyó** |

**Y ahora la misma verdad en el tablero.** En Kafbat: **Consumers** →
`fiscalizacion`.

| Lo que muestra el tablero | Lo que dijo la consola |
|---|---|
| El grupo en estado **EMPTY** | `has no active members` |
| Un solo número grande: **Consumer Lag 5** | 🔴 **La consola no lo da sumado.** Da tres filas y el 5 hay que encontrarlo entre ceros |
| El detalle por partición, con *Current* y *End* | Las tres filas de la tabla |

**Cómo se lee.** Aquí está la segunda mitad de la afirmación, y es la parte
honesta: **el tablero sí hace algo mejor.** No sabe nada distinto —los números
son los mismos— pero **te los suma y te los pone en la cara.** Con tres
particiones da igual. Con doscientas, es la diferencia entre ver el problema y
no verlo.

---

### Paso 4 · Y ahora se cae el tablero

**Se explica.**

Este es el paso que cierra el laboratorio, y es la razón de que exista. Vamos a
apagar la interfaz **a propósito** y a ver qué se rompe.

🔴 **Predice antes de ejecutar:** con Kafbat apagado, ¿el clúster sigue
funcionando? ¿Y el REST Proxy? ¿Y el grupo `fiscalizacion` pierde su avance?

**Se ejecuta.**

```bash
docker stop kafbat-ui
```

**Qué sale.** Una sola línea: `kafbat-ui`. Docker imprime el nombre de lo que
apagó, y nada más. **No hay confirmación ni advertencia.**

| Parte del comando | Para qué está |
|---|---|
| `docker stop` | Apaga el contenedor de forma ordenada. **No borra nada**: los datos de Kafbat viven en el clúster, no en él |
| `kafbat-ui` | El nombre del contenedor de la interfaz. Es uno de los cinco de este laboratorio |

Recarga **http://localhost:8090** en el navegador: no responde. Y por si queda
duda de que está caído y no lento:

```bash
curl -sS --max-time 5 http://localhost:8090/
```

**Qué sale.**

```
curl: (7) Failed to connect to localhost port 8090 after 0 ms: Couldn't connect to server
```

**Cómo se lee.** *Failed to connect*, no *404* ni *500*. **No hay nadie
escuchando en ese puerto.** El `(7)` es el código de `curl` para «no pude
conectar».

Y ahora las tres preguntas de la predicción, contestadas con comandos:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1
```

```
novatech.lab10.pedidos:0:0
novatech.lab10.pedidos:1:0
novatech.lab10.pedidos:2:8
```

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group fiscalizacion
```

```
fiscalizacion   novatech.lab10.pedidos 2          3               8               5               -               -               -
```

```bash
curl -s -o /dev/null -w "REST Proxy: HTTP %{http_code}\n" http://localhost:8082/topics
```

```
REST Proxy: HTTP 200
```

**Cómo se lee.** 🔴 **No se movió nada.** Los ocho mensajes siguen ahí, el lag
sigue siendo 5, y la ventanilla de la calle sigue atendiendo. **El clúster no se
enteró de que el tablero se cayó**, porque el tablero nunca fue parte del
clúster: era un cliente que preguntaba y dibujaba.

Y para volver:

```bash
docker start kafbat-ui
```

Imprime otra vez `kafbat-ui`, y ya está. **Medido: vuelve a responder en 4
segundos.** Recarga el navegador y está todo
igual — porque **no había nada que recuperar.**

---

## 6 · QUÉ QUEDÓ

**Lo que quedó demostrado en pantalla, con su evidencia:**

| Lo que se afirmó | Cómo se vio |
|---|---|
| El tablero dibuja lo que la consola dice | `PartitionCount: 3`, `RF 3` e ISR, los mismos en las dos vistas |
| Y no sabe nada más | Cada campo del Paso 2 tiene su comando al lado |
| Pero suma mejor | `Consumer Lag 5` de un vistazo, contra tres filas con un 5 entre ceros |
| Producir por HTTP es un POST | `HTTP 200` con la partición y el offset de cada mensaje |
| El tablero no es el clúster | Apagado: los 8 mensajes, el lag 5 y el REST Proxy, intactos |

**Las cinco reglas que se llevan a SUNAT:**

1. 🔴 **El tablero es un cliente, no el clúster.** Todo lo que muestra se lo
   preguntó a los brokers. Si muestra algo raro, la primera pregunta es si el
   raro es el clúster o es el tablero.

2. 🔴 **Un tablero caído no es un clúster caído**, y confundirlos cuesta una
   madrugada. La forma de distinguirlos es un `kafka-get-offsets` desde
   cualquier broker.

3. 🔴 **Lo que se mira en el tablero se arregla en la consola.** Mirar y actuar
   son dos cosas, y a las tres de la mañana solo vas a tener la segunda.

4. 🔴 **REST Proxy es para el sistema que no puede tener un cliente nativo.** Si
   puede, debe. Cada mensaje que pasa por el proxy pasa por un intermediario más
   que hay que dimensionar, vigilar y mantener arriba.

5. 🔴 **El `lag` de un grupo es el número que se vigila**, y es el único de este
   laboratorio que hay que poner en una alerta. Los demás se miran cuando ya hay
   un problema; este avisa antes.

**La pregunta que vale para la sala:** si mañana a las tres de la mañana te
llaman por Kafka y solo tienes un SSH a un servidor sin navegador, ¿qué tres
comandos escribes primero?

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue estaba en el recorrido de clase y salió por tiempo. Cada
bloque trae su comando completo, pero **no está desarrollado**.

### A · REST Proxy, endpoint por endpoint

El recorrido usó un solo `POST`. La API tiene más:

```bash
curl -s http://localhost:8082/topics
curl -s http://localhost:8082/topics/novatech.lab10.pedidos
```

**Salida real del primero:**

```
["novatech.lab10.pedidos"]
```

**Lo que hay que mirar:** el segundo devuelve las particiones, los líderes y las
réplicas — **los mismos datos del `--describe` del Paso 1**, por HTTP. Tres
formas de preguntar lo mismo: la consola, el tablero y el proxy.

Y los envoltorios del curso, que son `curl` por dentro y no dependen de nada
instalado:

```bash
rest-cli/rest-list-topics.sh
rest-cli/rest-produce.sh novatech.lab10.pedidos '{"pedido":3001,"cliente":"Courier-Y"}'
```

### B · Consumir por HTTP, que es lo que de verdad cuesta

Producir por HTTP era un POST. **Consumir es un ciclo de vida de cuatro pasos**,
y esa asimetría es el bloque más instructivo del recorrido viejo:

```
crear instancia → suscribir → poll (×2) → borrar instancia
```

```bash
rest-cli/rest-consume.sh novatech.lab10.pedidos
```

**Lo que hay que mirar:** el script imprime los cinco pasos con su respuesta.
Fíjate en dos cosas:

- **El primer `poll` viene vacío.** No es un fallo: la primera llamada es la que
  activa la suscripción, y recién la segunda trae datos.
- **Hay que borrar la instancia al terminar.** Si no, queda ocupando su
  asignación de particiones en el servidor hasta que expire.

🔴 **Y ahí está el porqué de toda la asimetría:** producir no necesita memoria
—el mensaje se va y listo— pero **consumir sí, porque Kafka tiene que recordar
por dónde vas.** HTTP no tiene memoria entre llamadas, así que el proxy la
guarda por ti, y por eso hay que crear y borrar algo.

**La pregunta que vale:** ¿qué pasa con las instancias de consumer que un
sistema mal escrito crea y nunca borra?

### C · El desafío del socio que solo hace `curl`

Diséñale a un socio externo una secuencia de tres o cuatro `curl` que liste los
tópicos, produzca dos pedidos, cree un consumer, lea, y limpie la instancia.
Documéntala en el reporte. **Es el ejercicio que convierte este laboratorio en
algo que puedes entregarle a alguien.**

### D · Interoperabilidad: HTTP y nativo sobre el mismo tópico

```bash
rest-cli/rest-produce.sh novatech.lab10.pedidos '{"pedido":9999,"origen":"http"}'
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --from-beginning --max-messages 10
```

**Lo que hay que mirar:** el cliente nativo lee el mensaje que entró por HTTP,
sin saber ni poder saber por dónde entró. **Es la misma lección del Lab 09**: el
broker no distingue clientes.

### E · La API del propio tablero

Kafbat tiene su propia API REST, y es la que usa su pantalla:

```bash
curl -s http://localhost:8090/api/clusters
```

**Salida real:**

```
[{"name":"novatech-cluster","status":"ONLINE","brokerCount":3,"onlinePartitionCount":3,"topicCount":1,...,"version":"4.2-IV1","controller":"KRAFT"}]
```

**Lo que hay que mirar:** `"controller":"KRAFT"` y `"version":"4.2-IV1"` — los
mismos datos del Lab 01. 🔴 **Y una idea que vale para producción:** si quieres
vigilar el clúster desde un tablero propio o un monitor, **no hace falta que una
persona mire esta pantalla**: se le puede preguntar a esta API.

### F · El reporte del lab

`plantillas/reporte-entregable.md` recorre las actividades del recorrido viejo
con sus preguntas. Las respuestas de referencia están en
`soluciones/reporte-resuelto.md`.

---

## Cierre

El clúster queda arriba para el Lab 11. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Siguiente:** Lab 11 — *¿quién autorizó ese campo nuevo?*
