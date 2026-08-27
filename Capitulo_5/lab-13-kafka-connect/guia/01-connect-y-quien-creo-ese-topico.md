# Lab 13 · Kafka Connect

## ¿Quién creó ese tópico?

> **Este es el laboratorio donde Kafka deja de ser algo a lo que hay que
> escribirle.** Hasta ahora, cada mensaje que entró a un tópico lo pusiste tú,
> con un comando. Hoy no vas a escribir en Kafka ni una sola vez, y el tópico se
> va a llenar igual.

**Duración.** Si lo repites tú solo, la corrida completa de los 4 pasos tomó
**19 segundos medidos** de punta a punta, en 7 comandos — y **10 de esos 19
fueron esperar sin hacer nada**, por un motivo que el Paso 2 explica y que el
Paso 4 vuelve a mostrar. La ejecución pura son **9 segundos**. En clase toma 20
minutos, porque casi todo el tiempo es explicación.
**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`),
con sus 3 brokers, PostgreSQL y Kafka Connect respondiendo en el puerto 8083.

---

## 1 · EL PROBLEMA

El sistema que le importa a SUNAT no es Kafka. Es la base de datos que ya
estaba. La que lleva veinte años funcionando, la que tiene los datos de verdad,
la que nadie va a reemplazar este año ni el que viene.

Y el encargo siempre llega igual: *«necesitamos que lo que entra ahí también
llegue a Kafka»*.

La respuesta obvia es escribir un programa. Un proceso que se conecte a la base,
consulte cada tanto qué hay de nuevo, y publique lo que encuentre. Suena a un
par de días de trabajo. Y lo es —**la primera versión**—.

Lo que no suena a un par de días es todo lo demás, que aparece después:

- ¿Cómo sabe qué filas ya publicó, si el proceso se reinicia?
- ¿Y si se cae a la mitad de una tanda? ¿Republica todo, o se salta lo que
  faltaba?
- ¿Y si la base no responde? ¿Reintenta, se rinde, avisa?
- ¿Y si hay que correr dos copias para que aguante el volumen? ¿Cómo se reparten
  el trabajo sin duplicar?
- ¿Quién lo monitorea? ¿Dónde están sus métricas?

**Ese programa deja de ser un script y se convierte en un sistema.** Y cuando
mañana el encargo se repita con otra base de datos, o con un archivo, o con una
API, hay que volver a escribirlo entero.

Y hay una segunda mitad del problema, que es la que más caro sale: ese programa
**hay que mantenerlo**. Tiene dueño, tiene despliegue, tiene versiones, y tiene
un día en que la persona que lo escribió ya no trabaja ahí.

Hoy vas a hacer ese trabajo completo sin escribir una línea de código.

---

## 2 · LA METÁFORA

Durante todo el curso Kafka es **un restaurante**. Vale la pena repasar el
reparto antes de seguir, porque hoy se suma una pieza nueva y viene de afuera.

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| El pincho donde se van clavando las comandas del turno | El **segmento** |
| El formato acordado de la comanda | El **schema** |

Y ahora la pieza de hoy, que no es del restaurante: **es del local que había
antes.**

| En el restaurante | En Kafka |
|---|---|
| **El libro de reservas de la entrada**, escrito a mano, que existe desde antes que las comandas y que nadie va a jubilar | La **base de datos** que ya estaba |
| **La instrucción escrita**: «mira ese libro cada cinco segundos y copia lo que sea nuevo» | El **conector** |
| **El ayudante** que efectivamente lo hace, línea por línea | La **task** |
| **El dedo** con que marca hasta qué línea ya copió | El **offset del conector** |

Lo que importa del ayudante, y es el corazón de este laboratorio:

**El ayudante no piensa.** No decide qué copiar, no interpreta, no corrige. Mira
el libro, ve que hay líneas más abajo de donde tiene el dedo, y las copia a
comandas. Después mueve el dedo. Y vuelve a mirar a los cinco segundos.

Nadie escribió un programa para el ayudante. Alguien le escribió **una
instrucción en un papel**: qué libro, cada cuánto, y cómo saber cuál es nueva.

De ahí sale la única regla que necesitas para entender todo lo demás:

> 🍽 **Al ayudante no se le programa. Se le escribe la instrucción y se le
> entrega.**

🔴 **Y aquí está lo que hay que ver venir**, porque es la limitación que el Paso
4 te va a dejar servida: **el dedo solo avanza.** Si alguien vuelve atrás y
corrige una línea que el ayudante ya copió, el ayudante **nunca se entera**: su
dedo ya pasó por ahí. Y si alguien arranca una hoja, tampoco.

---

## 3 · CÓMO LO RESUELVE

La traducción técnica son cuatro piezas.

> 🔌 **Kafka Connect**
> Un servicio aparte del clúster —aquí, el contenedor `kafka-connect`, que
> responde en `http://localhost:8083`— cuyo único trabajo es mover datos entre
> Kafka y sistemas externos. No es parte del broker: es otra pieza del
> ecosistema, con su propia API REST.

> 📝 **Conector** (*connector*)
> La declaración, en JSON, de **qué** conectar. No dice cómo: dice qué base, qué
> tabla, con qué credenciales, cada cuánto y a qué tópico. Es la instrucción del
> papel. 🔴 **Es todo lo que vas a escribir hoy, y no es código.**

> ⚙️ **Task**
> La unidad que ejecuta el trabajo. Un conector puede tener varias, y ahí está
> su paralelismo. Es el ayudante.

> 🏭 **Worker**
> El proceso donde viven las tasks. En este laboratorio hay uno; en producción
> hay varios, y si uno se cae, los demás se reparten sus tasks solos. Es el
> puesto de trabajo.

Y las dos direcciones, que se nombran desde el punto de vista de Kafka:

| Tipo | De dónde | A dónde | El de hoy |
|---|---|---|---|
| **Source** | Un sistema externo | Kafka | ✅ El del recorrido |
| **Sink** | Kafka | Un sistema externo | El de *Para profundizar C* |

Ahora los tres parámetros del conector de hoy, que son los que deciden todo:

**`mode: incrementing`** — cómo sabe qué es nuevo. Mira una columna que solo
sube, y publica las filas con valor mayor al último que vio. Es el dedo.

**`incrementing.column.name: id`** — cuál es esa columna.

**`poll.interval.ms: 5000`** — cada cuánto vuelve a mirar. **Cinco segundos.**

🔴 **De ahí salen los 10 segundos de espera que este laboratorio tiene medidos**,
y es importante decirlo antes de que pase: cuando insertes una fila y no aparezca
al instante, **no está roto**. El ayudante está en medio de sus cinco segundos.

Y de `mode: incrementing` sale la consecuencia que no está escrita en ninguna
documentación de una línea:

🔴 **Este conector solo ve los `INSERT`.** Un `UPDATE` no cambia el `id`, así que
la fila queda por debajo del dedo y nunca se vuelve a publicar. Un `DELETE` saca
una fila que el dedo ya pasó, y en Kafka no pasa nada. **Lo que estás copiando no
es la tabla: son las altas de la tabla.** Para lo otro existe Debezium, que en
vez de consultar la tabla lee el registro de transacciones de PostgreSQL — y eso
es otro laboratorio.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Un dato que entra a una base de datos aparece en Kafka sin que nadie
> escriba una línea de código.**

Tres partes, y las tres se ven en pantalla:

- **sin una línea de código** — lo único que se envía es un JSON de quince
  líneas, y ya viene escrito en el repositorio;
- **aparece** — el tópico no existe al empezar el laboratorio, y nadie va a
  ejecutar un comando para crearlo;
- **un dato que entra** — vas a escribir un `INSERT` en SQL, no en Kafka, y el
  texto que escribas va a salir dentro de un mensaje.

---

## 5 · LOS PASOS

### Paso 1 · El tópico que todavía no existe

**Se explica.**

Antes de tocar nada hay que fijar el punto de partida, porque la demostración
depende de él.

> 📋 **Tópico**
> El nombre bajo el que se agrupan mensajes del mismo tipo. No es una tabla ni
> una cola: es un registro que solo crece por el final. Es el tipo de comanda.

> 🖥 **Broker**
> Cada uno de los servidores Kafka del clúster. Este laboratorio levanta tres:
> `kafka-broker-1`, `kafka-broker-2` y `kafka-broker-3`. Es el mozo. 🔴 **Kafka
> Connect no es uno de ellos**: es un contenedor aparte.

**Se ejecuta.**

```bash
kafka-cli/list-topics.sh
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/list-topics.sh` | Envoltorio del curso. Por dentro llama a `kafka-topics --list` dentro del contenedor y le agrega la ficha didáctica |

**Qué sale.**

```
_connect-configs
_connect-offsets
_connect-status
novatech.lab09.pedidos.procesados
```

**Cómo se lee.** Cuatro tópicos, y **ninguno se llama `novatech.lab09.pedidos`**.
Ese es el que va a aparecer solo. Fíjate en los otros:

| Tópico | Qué es |
|---|---|
| `_connect-configs`, `_connect-offsets`, `_connect-status` | 🔴 **Son de Connect, y son de Kafka.** Connect no tiene base de datos: guarda sus conectores, su avance y su estado en tres tópicos del propio clúster. Por eso, si el contenedor se cae y vuelve, **retoma exactamente donde iba** |
| `novatech.lab09.pedidos.procesados` | El del camino de vuelta, que hoy no recorremos. Está en *Para profundizar C* |

Y del otro lado, la tabla que sí tiene datos:

```bash
docker exec postgres psql -U novatech -d novatech_orders -c "SELECT count(*) FROM pedidos;"
```

| Parte del comando | Para qué está |
|---|---|
| `docker exec postgres` | Ejecuta dentro del contenedor de PostgreSQL |
| `psql -U novatech -d novatech_orders` | El cliente de línea de comandos de PostgreSQL, con su usuario y su base |
| `-c "SELECT ..."` | Ejecuta esa sentencia y sale. Sin `-c` abriría una sesión interactiva |

**Qué sale.**

```
 count
-------
     5
(1 row)
```

**Cómo se lee.** Cinco filas en la base, cero mensajes en Kafka. **Ese es el
antes.** Deja el número a la vista.

---

### Paso 2 · La instrucción, que es un JSON

**Se explica.**

Este es el paso donde no se escribe código. Antes de enviarlo, hay que leerlo:
es corto y cada línea decide algo.

**Se ejecuta.**

```bash
cat infra/connect/jdbc-source-pedidos.json
```

**Qué sale.**

```json
{
  "name": "novatech-source-pedidos",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
    "tasks.max": "1",
    "connection.url": "jdbc:postgresql://postgres:5432/novatech_orders",
    "connection.user": "novatech",
    "connection.password": "novatech_secret",
    "table.whitelist": "pedidos",
    "mode": "incrementing",
    "incrementing.column.name": "id",
    "topic.prefix": "novatech.lab09.",
    "poll.interval.ms": "5000",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter.schemas.enable": "false"
  }
}
```

**Cómo se lee.** Esa es la instrucción entera. Línea por línea:

| Campo | Qué decide |
|---|---|
| `connector.class` | Qué tipo de ayudante. Este sabe hablar JDBC; hay otros que saben S3, Elasticsearch, MongoDB. 🔴 **Es lo único que cambia si mañana la fuente es otra** |
| `tasks.max: 1` | Cuántos ayudantes. Uno basta para una tabla |
| `connection.url` | 🔴 Fíjate en el `postgres:5432` — es el nombre del contenedor y su puerto **interno**. Desde tu máquina PostgreSQL está en el 15432, pero Connect lo ve por la red de Docker |
| `table.whitelist: pedidos` | Qué tabla mirar. Acepta varias, separadas por coma |
| `mode: incrementing` | Cómo sabe qué es nuevo: el dedo |
| `incrementing.column.name: id` | Cuál es la columna del dedo |
| `topic.prefix` | 🔴 **Aquí está la respuesta al título de esta guía.** El tópico no se nombra: se **arma**, pegando este prefijo al nombre de la tabla. `novatech.lab09.` + `pedidos` |
| `poll.interval.ms: 5000` | Cada cuánto vuelve a mirar |
| `value.converter` | En qué formato deja el mensaje. Aquí JSON. En el Lab 11 hubiera sido Avro |

Ahora se envía:

```bash
connect-cli/create-source.sh
```

| Parte del comando | Para qué está |
|---|---|
| `connect-cli/create-source.sh` | Envoltorio del curso. Hace un `POST` del archivo a la API REST de Connect |

El comando real que corre por debajo:

```bash
curl -s -X POST -H "Content-Type: application/json" \
    --data @infra/connect/jdbc-source-pedidos.json \
    http://localhost:8083/connectors
```

| Parámetro | Para qué está |
|---|---|
| `-X POST` a `/connectors` | Crear un conector es una llamada REST. 🔴 **No hay archivo de configuración que editar ni servicio que reiniciar** |
| `--data @archivo` | La arroba le dice a `curl` que el cuerpo sale de ese archivo, no de la línea |

**Qué sale.** Connect devuelve la configuración completa tal como la guardó, más
un campo nuevo:

```json
{
    "name": "novatech-source-pedidos",
    "config": { ... },
    "tasks": [],
    "type": "source"
}
```

**Cómo se lee.** `"tasks": []`, vacío. **Todavía no hay ayudante.** El conector
quedó registrado, y el reparto de tasks ocurre un instante después. Por eso el
paso siguiente no es opcional:

```bash
connect-cli/status-connector.sh novatech-source-pedidos
```

> ⚠️ **Si lo corres pegado al comando anterior puede contestarte esto**, y está
> medido:
>
> ```json
> {
>     "error_code": 404,
>     "message": "No status found for connector novatech-source-pedidos"
> }
> ```
>
> **No está roto y el conector no falló.** El estado se publica un instante
> después de aceptar la instrucción. Vuelve a correr el mismo comando: en la
> corrida medida ya respondía al segundo intento. 🔴 **Es el único punto del
> laboratorio donde hay que repetir un comando, y conviene saberlo antes de que
> pase delante de la sala.**

**Qué sale.**

```json
{
    "name": "novatech-source-pedidos",
    "connector": {
        "state": "RUNNING",
        "worker_id": "kafka-connect:8083",
        "version": "10.9.0"
    },
    "tasks": [
        {
            "id": 0,
            "state": "RUNNING",
            "worker_id": "kafka-connect:8083",
            "version": "10.9.0"
        }
    ],
    "type": "source"
}
```

**Cómo se lee.** 🔴 **Hay dos `state`, y no son el mismo.** Esta distinción es
lo que más se confunde en producción:

| Cuál | Qué dice |
|---|---|
| `connector.state` | Si la **instrucción** está aceptada y vigente |
| `tasks[0].state` | Si el **ayudante** está trabajando |

**Los dos tienen que decir `RUNNING`.** Un conector `RUNNING` con su task en
`FAILED` es el caso que más caro sale: la instrucción está ahí, se ve verde por
encima, y no se está copiando nada. *(Para profundizar D lo provoca a
propósito.)*

---

### Paso 3 · El tópico que apareció solo

**Se explica.**

Nadie ejecutó un comando de creación de tópicos. Vamos a mirar.

**Se ejecuta.**

```bash
kafka-cli/list-topics.sh
```

**Qué sale.**

```
_connect-configs
_connect-offsets
_connect-status
novatech.lab09.pedidos
novatech.lab09.pedidos.procesados
```

**Cómo se lee.** Apareció `novatech.lab09.pedidos`. **Esa es la respuesta al
título de la guía:** lo creó el conector, con el nombre que salió de pegar
`topic.prefix` + el nombre de la tabla.

Y no apareció vacío:

> 🔢 **Offset**
> El número de orden de un mensaje dentro de su partición. Empieza en 0 y solo
> sube. El offset «más nuevo» de una partición es, en la práctica, la cuenta de
> mensajes que se han escrito en ella.

> 🍰 **Partición**
> Cada uno de los pedazos en que se corta un tópico. Este tópico tiene **una
> sola**, porque el conector lo creó con los valores por defecto del broker y
> nadie le pidió otra cosa.

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos --time -1
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-get-offsets` | Pregunta por los offsets de un tópico. Solo consulta |
| `--bootstrap-server` | La puerta de entrada al clúster. Le preguntas a un broker cualquiera y contesta por todos |
| `--time -1` | El offset **más nuevo**. (`-2` sería el más antiguo) |

**Qué sale.**

```
novatech.lab09.pedidos:0:5
```

**Cómo se lee.** Es `tópico:partición:offset`. Partición 0, offset 5. **Cinco
mensajes** — exactamente las cinco filas que el Paso 1 contó en la tabla. El
ayudante entró, encontró el libro con cinco líneas y el dedo en cero, y las copió
todas.

Ahora mira lo que copió:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --from-beginning --max-messages 5
```

| Parte del comando | Para qué está |
|---|---|
| `--from-beginning` | Empieza por el mensaje más viejo que el tópico conserva, no por lo que llegue de ahora en adelante |
| `--max-messages 5` | 🔴 **Sin esto el comando no termina nunca**: un consumidor se queda esperando. Con el tope, lee cinco y sale solo |

**Qué sale.**

```
{"id":1,"cliente_id":1001,"producto":"Caja de bananos premium","cantidad":50,"monto":"ExLQ","estado":"pendiente","creado_en":1787796032917}
{"id":2,"cliente_id":1002,"producto":"Pallet de cajas reforzadas","cantidad":20,"monto":"AIfNoA==","estado":"pendiente","creado_en":1787796032917}
{"id":3,"cliente_id":1003,"producto":"Etiquetas RFID x1000","cantidad":1,"monto":"RKog","estado":"pendiente","creado_en":1787796032917}
{"id":4,"cliente_id":1004,"producto":"Cinta adhesiva industrial 50m","cantidad":100,"monto":"C3Gw","estado":"pendiente","creado_en":1787796032917}
{"id":5,"cliente_id":1005,"producto":"Stretch film 500m","cantidad":30,"monto":"G3dA","estado":"pendiente","creado_en":1787796032917}
Processed a total of 5 messages
```

**Cómo se lee.** Un JSON por línea, y **sus campos son las columnas de la
tabla**. Nadie definió ese formato: lo dedujo el conector del esquema de
PostgreSQL.

🔴 **Y ahora lo que siempre pregunta la sala:** `"monto":"ExLQ"`. No está
corrupto. La columna `monto` es un `NUMERIC(10,2)` de SQL, un decimal exacto, y
**JSON no tiene decimal exacto** — solo tiene el número de coma flotante, que
redondea. Antes que entregarte un importe redondeado, el conector te entrega los
bytes originales en base64. Es incómodo, y es la respuesta correcta: en un
sistema tributario, un céntimo perdido por redondeo es un problema de verdad.
*(Se arregla con `numeric.mapping`, en Para profundizar F.)*

---

### Paso 4 · La fila nueva, y el viaje

**Se explica.**

Todo lo anterior podría explicarse como «el conector hizo una carga inicial».
Este paso es el que demuestra que el ayudante **sigue mirando**.

Vas a escribir un `INSERT` en SQL. En Kafka no vas a tocar nada.

**Se ejecuta.**

```bash
kafka-cli/insertar-pedido.sh 2001 "Pedido de la clase" 5 25000.00
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/insertar-pedido.sh` | Envoltorio del curso. 🔴 **A pesar de estar en `kafka-cli/`, no habla con Kafka**: hace un `INSERT` en PostgreSQL y nada más |
| `2001` | El `cliente_id` |
| `"Pedido de la clase"` | El producto. 🔴 **Elige un texto reconocible**: lo vas a buscar dentro de un mensaje de Kafka en un minuto |
| `5` | La cantidad |
| `25000.00` | El monto |

El comando real que corre por debajo:

```bash
psql -U novatech -d novatech_orders -c \
  "INSERT INTO pedidos (cliente_id, producto, cantidad, monto, estado)
   VALUES (2001, 'Pedido de la clase', 5, 25000.00, 'pendiente') RETURNING id;"
```

**Qué sale.**

```
 id
----
  6
(1 row)
INSERT 0 1
```

**Cómo se lee.** `RETURNING id` devolvió `6`: es el `id` de la fila nueva, y por
lo tanto la línea a la que el dedo del ayudante todavía no llegó. `INSERT 0 1`
es PostgreSQL diciendo que insertó una fila.

**Y ahora se espera.** Cuenta hasta cinco en voz alta, y pregunta:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos --time -1
```

**Qué sale.**

```
novatech.lab09.pedidos:0:6
```

**Cómo se lee.** Pasó de 5 a 6. 🔴 **Ese `6` es toda la afirmación de este
laboratorio en un solo número.** Nadie ejecutó un productor. Nadie escribió
código. Se escribió una fila en una base de datos y apareció un mensaje en
Kafka.

🕐 **Cuánto tardó, medido:** **6 segundos** desde el `INSERT`. El
`poll.interval.ms` son 5, y el segundo restante es lo que le toma consultar y
publicar. **Si tú lo corres y tarda 3, o tarda 9, es normal**: depende de en qué
punto de sus cinco segundos estaba el ayudante cuando insertaste.

Y por último, el mensaje:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --partition 0 --offset 5 --max-messages 1
```

| Parte del comando | Para qué está |
|---|---|
| `--partition 0` | Obligatorio cuando se pide un offset concreto: los offsets son por partición |
| `--offset 5` | 🔴 **El sexto mensaje es el offset 5**, porque los offsets empiezan en 0. Si insertaste más filas, súmalas |
| `--max-messages 1` | Lee uno y sale |

**Qué sale.**

```
{"id":6,"cliente_id":2001,"producto":"Pedido de la clase","cantidad":5,"monto":"JiWg","estado":"pendiente","creado_en":1787796675362}
Processed a total of 1 messages
```

*(El `creado_en` es la hora en milisegundos desde 1970 y va a ser distinto en tu
corrida. Los demás campos no.)*

**Cómo se lee.** `"producto":"Pedido de la clase"`. **Es el texto que escribiste
en el `INSERT`**, dentro de un mensaje de Kafka, sin haber tocado Kafka.

---

## 6 · QUÉ QUEDÓ

**Lo que quedó demostrado en pantalla, con su evidencia:**

| Lo que se afirmó | Cómo se vio |
|---|---|
| El tópico no existía | `list-topics` sin `novatech.lab09.pedidos`, en el Paso 1 |
| Lo creó el conector, no tú | El mismo `list-topics` después, y el `topic.prefix` del JSON |
| No se escribió una línea de código | Un JSON de 15 líneas, enviado con un `POST` |
| Las filas que ya estaban se copiaron | 5 filas en la tabla → offset `5` en el tópico |
| Y sigue copiando | Un `INSERT` → offset `6`, en **6 segundos medidos** |
| El dato es el mismo | `"producto":"Pedido de la clase"`, el texto que escribiste en SQL |

**Las cinco reglas que se llevan a SUNAT:**

1. 🔴 **Un conector no es un programa: es un JSON.** No tiene despliegue, ni
   repositorio propio, ni versiones que compilar. Se envía por REST y queda
   guardado en un tópico de Kafka.

2. 🔴 **Hay dos `state` y hay que mirar los dos.** Un conector `RUNNING` con su
   task en `FAILED` se ve verde por encima y no está copiando nada.

3. 🔴 **`mode: incrementing` copia altas, no la tabla.** Los `UPDATE` y los
   `DELETE` son invisibles. Si el caso los necesita, la respuesta es Debezium y
   hay que decirlo antes de prometer nada.

4. 🔴 **La latencia la pones tú, con `poll.interval.ms`.** Cinco segundos aquí.
   Bajarlo acerca el dato y carga la base; subirlo la alivia y aleja el dato. No
   hay valor correcto: hay una decisión.

5. 🔴 **Un `NUMERIC` de SQL no cabe en JSON.** El base64 no es un error: es el
   conector negándose a redondearte un importe. En un sistema tributario eso es
   lo que quieres.

**La pregunta que vale para la sala:** de las integraciones que tu equipo
mantiene hoy con código propio, ¿cuántas son «leer una tabla y publicar lo
nuevo», y quién las mantiene cuando esa persona no está?

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue estaba en el recorrido de clase y salió por tiempo. Cada
bloque trae su comando completo, pero **no está desarrollado**: se lee y se
ejecuta solo.

### A · Verificar Connect y ver qué sabe hacer

```bash
curl -s http://localhost:8083/
curl -s http://localhost:8083/connector-plugins | tr '{' '\n' | grep -oE '"class":"[^"]*"'
```

**Salidas reales:**

```
{"version":"8.2.0-ccs","commit":"62a39a849020cb35fe97d7dbaa83962d8bde94b5","kafka_cluster_id":""}
```

🔴 **Ojo con `kafka_cluster_id`: viene vacío.** No está roto y no es tu clúster
mal configurado; en esta versión ese campo no se llena. **Es un ejemplo de por
qué las salidas se miran y no se suponen.**

Y de los plugins, los dos que importan hoy:

```
"class":"io.confluent.connect.jdbc.JdbcSinkConnector"
"class":"io.confluent.connect.jdbc.JdbcSourceConnector"
```

**Lo que hay que mirar:** son **5** plugins en total en esta imagen. En Confluent
Hub hay cientos: S3, Elasticsearch, MongoDB, Salesforce. Instalar uno es dejar su
`.jar` en la carpeta de plugins y reiniciar el worker.

### B · El dedo del ayudante

La forma corta y correcta de preguntarle a Connect por dónde va:

```bash
curl -s http://localhost:8083/connectors/novatech-source-pedidos/offsets
```

**Salida real**, tomada con 16 filas en la tabla:

```json
{"offsets":[{"partition":{"protocol":"1","table":"public.pedidos"},"offset":{"incrementing":16}}]}
```

**Lo que hay que mirar:** `{"incrementing":16}`, y `max(id)` en la tabla también
es 16. **Ese es el dedo.** Si tumbas Connect y lo levantas, retoma en el 17 —
por eso no republica lo que ya publicó, y por eso no necesita archivos locales.

**Y dónde vive el dedo**, que es lo que hace a Connect tolerante a fallos: en un
tópico de Kafka.

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 --topic _connect-offsets --time -1 \
  | awk -F: '$3>0'
```

```
_connect-offsets:20:2
```

**Lo que hay que mirar:** de las 25 particiones del tópico solo una tiene datos
—los registros de un conector van todos a la misma, por su clave— y tiene **2**
registros.

🔴 **Y aquí está la trampa de este bloque, que la guía vieja tenía mal.** Es
tentador leerlo así:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic _connect-offsets --from-beginning \
    --max-messages 1 --formatter-property print.key=true
```

```
["novatech-source-pedidos",{"protocol":"1","table":"public.pedidos"}]	{"incrementing":9}
```

**Nueve, no dieciséis.** El `--from-beginning` con `--max-messages 1` trae el
registro **más viejo que sobrevive**, no el vigente. Los dos registros dicen
cosas distintas y solo el último manda:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic _connect-offsets --partition 20 --offset 0 \
    --max-messages 2 --formatter-property print.key=true
```

```
["novatech-source-pedidos",{"protocol":"1","table":"public.pedidos"}]	{"incrementing":9}
["novatech-source-pedidos",{"protocol":"1","table":"public.pedidos"}]	{"incrementing":16}
```

**La lección, que vale más que el comando:** un tópico de estado se lee por el
**final**, no por el principio. Está compactado, así que con el tiempo Kafka
deja solo el último por clave — pero mientras no compacte, los viejos siguen
ahí y contestan otra cosa. **Contrasta siempre contra la fuente**: aquí,
`max(id)` de la tabla.

🔴 **Y por qué `--max-messages` con el número exacto:** si pides más mensajes de
los que hay, el consumidor **se queda esperando** y no vuelve. La guía vieja
pedía 5 sobre un tópico que en ese momento tenía 1. Medido: el comando no
termina.

### C · El camino de vuelta: el Sink

Es la otra mitad de Connect y no cabe en los 20 minutos: de Kafka a la base de
datos. El laboratorio lo trae entero y funciona.

```bash
kafka-cli/verificar-tabla-procesados.sh     # vacía: (0 rows)
connect-cli/create-sink.sh
connect-cli/status-connector.sh novatech-sink-procesados
kafka-cli/publicar-procesado.sh 6
kafka-cli/verificar-tabla-procesados.sh
```

**Salida real de la última línea, medida a los 2 segundos de publicar:**

```
 id | cliente_id |           producto           |  estado
----+------------+------------------------------+-----------
  6 |       1001 | Pedido procesado en 22:06:05 | procesado
(1 row)
```

**Lo que hay que mirar:** publicaste en un tópico y apareció una fila en SQL, otra
vez sin código. Y dos detalles del JSON del Sink que vale la pena leer en
`infra/connect/jdbc-sink-procesados.json`:

| Campo | Qué decide |
|---|---|
| `insert.mode: upsert` con `pk.fields: id` | Si publicas dos veces el mismo `id`, **actualiza en vez de duplicar**. Es lo que hace que el flujo sea repetible sin ensuciar la tabla |
| `auto.create: false` | Connect **no** crea la tabla. Podría, pero con tipos genéricos. Aquí la creó el `init-novatech.sql` con los tipos correctos |

**La pregunta que vale:** si el Sink se queda atrasado, ¿dónde esperan los
mensajes, y qué pasa cuando se pone al día?

### D · Romper el Sink a propósito, y ver los dos `state`

Publica un mensaje sin el envoltorio `schema`/`payload` que el Sink exige:

```bash
echo '{"cliente_id":99,"producto":"sin id","cantidad":1,"monto":1.0,"estado":"x"}' \
| docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos.procesados
connect-cli/status-connector.sh novatech-sink-procesados
```

**Salida real, un segundo después:**

```
"connector": { "state": "RUNNING", ... }
"tasks": [ { "state": "FAILED", "trace": "org.apache.kafka.connect.errors.ConnectException: Tolerance exceeded in error handler ..." } ]
```

🔴 **Este es el hallazgo del bloque, y contradice lo que uno espera:** el
**conector sigue en `RUNNING`**. El que murió es el **task**. Un tablero que solo
mire `connector.state` te dice que todo está bien mientras no se copia nada.

La causa raíz, más abajo en el mismo `trace`:

```
Caused by: org.apache.kafka.connect.errors.DataException: JsonConverter with
schemas.enable requires "schema" and "payload" fields and may not contain
additional fields.
```

**Y lo que no funciona**, también medido:

```bash
curl -s -X POST "http://localhost:8083/connectors/novatech-sink-procesados/restart?includeTasks=true&onlyFailed=true"
```

Devuelve `HTTP 202` y el task **vuelve a `FAILED`**. Es correcto que así sea: el
mensaje malo sigue en el mismo offset y lo vuelve a leer. 🔴 **Un `restart` no
arregla un dato malo.** Las salidas de verdad son configurar
`errors.tolerance: all` con una cola de mensajes muertos, o `bin/reset-lab.sh`.

### E · La inserción masiva

```bash
for i in 1 2 3 4 5 6 7 8 9 10; do
    kafka-cli/insertar-pedido.sh $((3000+i)) "Pedido masivo $i" $i $((10000*i))
done
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 --topic novatech.lab09.pedidos --time -1
```

**Salida real, medida:** los diez `INSERT` tomaron **1 segundo**, y los 16
mensajes estaban en el tópico **6 segundos después del último**:

```
novatech.lab09.pedidos:0:16
```

**Lo que hay que mirar:** seis segundos para diez filas es lo mismo que tardó
**una sola** fila en el Paso 4. Las diez viajaron en la misma pasada. No es una
fila por pasada: es todo lo que haya bajo el dedo.

**La pregunta que vale:** ¿qué le pasa a este conector el día que alguien haga
una carga de dos millones de filas de una vez?

### F · El importe en base64

```bash
connect-cli/delete-connector.sh novatech-source-pedidos
```

Agrega `"numeric.mapping": "best_fit"` al JSON del conector y vuelve a crearlo.

**Salida real con el cambio aplicado**, contra las mismas dos filas del Paso 3:

```
{"id":1,"cliente_id":1001,"producto":"Caja de bananos premium","cantidad":50,"monto":12500.0,...}
{"id":2,"cliente_id":1002,"producto":"Pallet de cajas reforzadas","cantidad":20,"monto":89000.0,...}
```

`"ExLQ"` pasó a ser `12500.0`. **Lee la advertencia antes de usarlo en
producción:** `best_fit` elige el tipo que quepa, y para un decimal grande eso
significa un `double` — es decir, redondeo. El base64 era feo y era exacto.

### G · Inspección visual

Kafbat UI, en **http://localhost:8090** → pestaña *Kafka Connect*. Compara lo que
la interfaz muestra con lo que devolvió `status-connector.sh`. 🔴 **Fíjate en si
la interfaz distingue los dos `state`**, que es el punto de *Para profundizar D*.

### H · El reporte del lab

`plantillas/reporte-entregable.md` recorre las actividades del recorrido viejo
con sus preguntas. Las respuestas de referencia están en
`soluciones/reporte-resuelto.md` y en `soluciones/respuestas-desafio.md`.

---

## Cierre

El clúster queda arriba para el Lab 14. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Siguiente:** Lab 14 — *la seguridad no se demuestra con lo que permite.*
