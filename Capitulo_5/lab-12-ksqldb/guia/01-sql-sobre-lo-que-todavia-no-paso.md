# Lab 12 · ksqlDB

## ¿Se puede preguntar por algo que todavía no pasó?

> **Este es el laboratorio más corto del curso, y tiene una sola idea adentro.**
> Si te llevas esa idea, sobra todo lo demás.

**Duración.** Si lo repites tú solo, el recorrido de los 3 pasos tomó **17
segundos medidos**, en 4 comandos — y **8 de esos 17 son una espera a
propósito**, porque el Paso 3 consiste justamente en no hacer nada y mirar. En
clase toma 20 minutos.
**Antes de empezar:** el clúster arriba (`bin/start-lab.sh`), y 🔴 **los datos ya
sembrados** — el tópico `novatech.lab10.pedidos` con pedidos en formato Avro y
sus esquemas registrados. Eso **no lo hace el `start-lab.sh`**: son cuatro
comandos que tardan **66 segundos medidos** y están en *Para profundizar A*. Si
vas a dictar este lab, córrelos antes.

**Todo lo que este laboratorio le pide a ksqlDB va por `curl`**, contra su API
REST. Hay un cliente interactivo más cómodo —`ksql-cli/ksql-shell.sh`— y está en
*Para profundizar B*; el recorrido no lo usa por una razón concreta que se
explica ahí.

---

## 1 · EL PROBLEMA

El equipo de analítica de SUNAT pide algo que suena razonable: *«queremos saber
cuántos comprobantes por minuto están entrando, y cuáles superan cierto
monto»*.

Y la respuesta que reciben, hoy, es siempre la misma forma: **mañana**. Porque
el camino es que los datos se copien a algún sitio durante la noche, que un
proceso los agregue, y que a la mañana siguiente haya un informe.

Ese informe **siempre habla del pasado**. Es correcto, es útil, y llega tarde
para todo lo que importa en el momento: una carga anómala, un pico de rechazos,
un contribuyente que empezó a hacer algo raro hace veinte minutos.

**Y la alternativa que se propone siempre es peor de lo que parece:** «que
escriban una aplicación que consuma el tópico y vaya calculando». Ya viste en el
Lab 09 lo que es un consumidor: veinte líneas para conectarse, y todo lo demás
—el estado, las ventanas de tiempo, los reinicios, el paralelismo— hay que
escribirlo. Para una pregunta. Y la siguiente pregunta es otra aplicación.

Hay una segunda mitad, más incómoda: **la gente que tiene las preguntas no
escribe aplicaciones.** El analista que sabe qué hay que preguntar sabe SQL, no
Java. Cada vez que la respuesta exige un desarrollador, la pregunta se pospone o
no se hace.

---

## 2 · LA METÁFORA

Durante todo el curso Kafka es **un restaurante**. Vale la pena repasar el
reparto antes de seguir.

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| El pincho donde se van clavando las comandas del turno | El **segmento** |
| El formato acordado de la comanda | El **schema** |

La pieza de hoy no es un objeto nuevo: **es una forma distinta de preguntar.**

| En el restaurante | En Kafka |
|---|---|
| **El que baja al depósito a contar las comandas del mes** y sube con un número | Una consulta **de siempre**, sobre una base de datos |
| **El que se planta en el paso con una libreta** y va anotando cada comanda que cruza, mientras cruza | Una consulta de **ksqlDB**, con `EMIT CHANGES` |

Lo que importa de esta comparación, y es el corazón del laboratorio:

El del depósito **pregunta una vez y obtiene una respuesta.** Cuando termina de
contar, su número ya está viejo: mientras contaba entraron comandas nuevas. Si
quiere saber cómo va ahora, tiene que volver a bajar.

El del paso **pregunta una vez y no deja de obtener respuestas.** No baja a
ningún lado. Se queda ahí, y cada comanda que cruza es una respuesta más a la
misma pregunta que hizo al principio.

> 🍽 **La pregunta se hace una vez y sigue contestando.**

Y de ahí sale lo que hay que ver hoy en pantalla, que es lo único que asombra de
ksqlDB: **el del paso puede plantarse antes de que exista la comanda.** Puede
hacer la pregunta cuando todavía no hay nada que contestar, y esperar.

---

## 3 · CÓMO LO RESUELVE

Tres piezas, y ninguna es complicada.

> 🗃 **ksqlDB**
> Un servicio aparte del clúster —aquí, el contenedor `ksqldb-server`, que
> responde en `http://localhost:8088`— que acepta SQL y lo traduce a
> aplicaciones de Kafka. 🔴 **No es una base de datos.** No guarda tus datos: los
> datos siguen viviendo en los tópicos. Es un traductor.

> 🌊 **STREAM**
> La declaración de que un tópico se puede leer como si fuera una tabla: qué
> columnas tiene y de qué tipo es cada una. 🔴 **Declarar un stream no copia
> nada ni mueve nada.** Es ponerle un nombre y una forma a un tópico que ya
> existe, para poder escribirle SQL encima.

Y la palabra que lo cambia todo:

> ▶️ **`EMIT CHANGES`**
> Las dos palabras que convierten un `SELECT` normal en uno que **no termina**.
> Sin ellas, ksqlDB contesta con lo que hay y se va. Con ellas, contesta con lo
> que hay **y se queda esperando lo que venga**.

La diferencia tiene nombres, y conviene tenerlos:

| | Cómo se llama | Qué hace |
|---|---|---|
| Sin `EMIT CHANGES` | **Pull query** | Pregunta, responde, termina. Como cualquier SQL |
| Con `EMIT CHANGES` | **Push query** | Pregunta una vez, responde para siempre |

Y el otro parámetro que decide qué ves, que ya conoces del Lab 09:

**`auto.offset.reset`** — por dónde empieza a leer la consulta.

| Valor | Desde dónde | Para qué sirve hoy |
|---|---|---|
| `earliest` | El principio del tópico | Ver **lo que ya pasó**. Es el Paso 2 |
| `latest` | Solo lo que llegue de ahora en adelante | Ver **lo que todavía no pasó**. Es el Paso 3 |

🔴 **Ese parámetro es la mitad de la demostración.** Con `latest`, la consulta
arranca sin nada que mostrar y **se queda esperando**. Es el que se planta en el
paso antes de que exista la comanda.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Se puede consultar con SQL un flujo de datos que todavía está llegando.**

Tres partes, y las tres se ven en pantalla:

- **con SQL** — la consulta es un `SELECT ... FROM ... ` y nada más;
- **que todavía está llegando** — la consulta va a estar corriendo **ocho
  segundos antes** de que el dato exista;
- **y sigue contestando** — el dato va a aparecer solo, sin que nadie vuelva a
  preguntar nada.

---

## 5 · LOS PASOS

### Paso 1 · Ponerle forma de tabla a un tópico

**Se explica.**

El tópico `novatech.lab10.pedidos` ya tiene pedidos escritos en Avro. Kafka
sabe que son bytes; el Schema Registry sabe qué campos tienen. **Lo que falta es
decirle a ksqlDB que los mire como filas.**

> 📋 **Tópico**
> El nombre bajo el que se agrupan mensajes del mismo tipo. No es una tabla ni
> una cola: es un registro que solo crece por el final.

**Se ejecuta.**

```bash
curl -s -X POST http://localhost:8088/ksql \
    -H "Content-Type: application/vnd.ksql.v1+json" \
    -d '{"ksql":"CREATE STREAM pedidos_stream (id INT, cliente_id INT, producto VARCHAR, cantidad INT, monto DOUBLE, estado VARCHAR) WITH (KAFKA_TOPIC='"'"'novatech.lab10.pedidos'"'"', VALUE_FORMAT='"'"'AVRO'"'"');"}' \
  | tr ',' '\n' | grep -E '"status"|"message"'
```

| Parte del comando | Para qué está |
|---|---|
| `POST /ksql` | El punto de entrada para las sentencias que **definen** cosas: crear, borrar, listar. Las consultas van por otro, que verás en el Paso 2 |
| `-H "Content-Type: application/vnd.ksql.v1+json"` | El tipo de contenido propio de ksqlDB. Sin esta cabecera contesta `415` |
| `-d '{"ksql":"..."}'` | 🔴 **El SQL viaja como texto dentro de un JSON**, igual que el schema del Lab 11. Por eso las comillas simples de dentro se escriben `'"'"'`: para cerrar la comilla del shell, poner una literal, y volver a abrirla |
| `CREATE STREAM ... (columnas)` | Los seis campos del pedido, con su tipo. **Tienen que coincidir con lo que hay en el tópico** |
| `KAFKA_TOPIC=` | 🔴 **Sobre qué tópico existente.** El stream no crea un tópico: se monta sobre uno que ya está |
| `VALUE_FORMAT='AVRO'` | Cómo están escritos los mensajes. ksqlDB irá al Schema Registry a buscar el schema |
| `\| tr ',' '\n' \| grep -E ...` | La respuesta es un JSON de 447 caracteres en una sola línea, con la sentencia entera repetida dentro. Esto la parte por comas y deja **solo las dos líneas que importan**. Es un corte bruto, no un formateador de JSON |

**Qué sale.**

```
"commandStatus":{"status":"SUCCESS"
"message":"Stream created"
```

**Cómo se lee.** `SUCCESS` y `Stream created`. **Y lo importante es lo que
*no* pasó:** no se copió un solo mensaje, no se creó un tópico nuevo, no se movió
un byte. Lo único que hay ahora es una **declaración**: ksqlDB sabe que ese
tópico se puede leer como una tabla de seis columnas.

> ⚠️ **Si en vez de eso te sale esto**, el stream ya existía de una corrida
> anterior:
>
> ```
> "error_code":40001
> "message":"Cannot add stream 'PEDIDOS_STREAM': A stream with the same name already exists"
> ```
>
> No es un problema: sigue al Paso 2, el stream que necesitas ya está. Para
> empezar de cero, primero `DROP STREAM pedidos_stream;` por el mismo endpoint.
> **El mismo filtro de arriba muestra el error igual de bien que el éxito**, que
> es justo lo que se le pide a un filtro.

---

### Paso 2 · Preguntar por lo que ya pasó

**Se explica.**

Ahora el `SELECT`. Este primero es el aburrido a propósito: pregunta por lo que
ya está escrito, que es lo que haría cualquier base de datos. Sirve para
comprobar dos cosas antes del paso que importa — que el SQL funciona, y que los
datos se leen bien.

**Se ejecuta.**

```bash
curl -s -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, producto, monto FROM pedidos_stream EMIT CHANGES LIMIT 3;","properties":{"auto.offset.reset":"earliest"}}'
```

| Parte del comando | Para qué está |
|---|---|
| `POST /query-stream` | 🔴 **Otro endpoint.** Las consultas no van por `/ksql`: van por aquí, que es el que sabe devolver una respuesta que llega de a poco |
| `-H "...ksqlapi.delimited.v1"` | Pide la respuesta **delimitada por líneas**: una línea por fila, a medida que salen |
| `"sql": "SELECT id, producto, monto FROM pedidos_stream"` | SQL corriente. Tres columnas de las seis |
| `EMIT CHANGES` | Push query: no termina sola |
| `LIMIT 3` | 🔴 **Lo único que hace que termine.** Sin el `LIMIT`, este comando se queda corriendo hasta que lo cortes con Ctrl+C |
| `"properties":{"auto.offset.reset":"earliest"}` | Empieza por el principio del tópico: queremos ver lo viejo |

**Qué sale.**

```
{"queryId":"transient_PEDIDOS_STREAM_6677080222679532892","columnNames":["ID","PRODUCTO","MONTO"],"columnTypes":["INTEGER","STRING","DOUBLE"]}
[1,"Pallet reforzado",15207.0]
[3,"Cuerda nautica",28141.0]
[5,"Caja bananos",18458.0]
```

**Cómo se lee.**

| Línea | Qué dice |
|---|---|
| La primera | La **cabecera**: el identificador de la consulta y, sobre todo, **los nombres y tipos de las columnas**. Fíjate en que están en mayúsculas: ksqlDB convierte los nombres, y eso es normal |
| Las tres siguientes | Una fila cada una, como lista JSON, en el orden de las columnas de la cabecera |

🔴 **Y ahora lo más importante de este paso, que hay que medir para creerlo.**
Corre el mismo comando cinco veces seguidas, sin tocar nada entremedio, y mira
solo los `id`. Esto es lo que salió, medido:

```
corrida 1:  25   5   7
corrida 2:   9   7   5
corrida 3:   3   5  12
corrida 4:   5  19  28
corrida 5:   5  19  28
```

**El mismo `SELECT`, sobre datos que no cambiaron, devuelve filas distintas cada
vez.** En una base de datos eso sería un fallo grave. Aquí es el comportamiento
correcto, y la razón es la que ya conoces desde el Lab 05:

> 🍰 **Partición**
> Cada uno de los pedazos en que se corta un tópico. Este tiene **12**. El orden
> de los mensajes está garantizado **dentro de cada partición**, y en ninguna
> parte entre ellas.

ksqlDB lee las 12 particiones a la vez, y el `LIMIT 3` se queda con **las tres
primeras que lleguen**, que dependen de cuál contestó antes. 🔴 **Un flujo no
tiene un orden global, así que no hay `SELECT` que pueda dártelo.** Cualquier
informe que dependa del orden entre particiones está mal planteado, y este es el
momento de decirlo antes de que alguien lo escriba.

*(Los productos y montos también van a ser otros: los 30 pedidos se generaron
con valores al azar.)*

---

### Paso 3 · Preguntar por lo que todavía no pasó

**Se explica.**

Este es el laboratorio. Todo lo anterior era preparación.

Vamos a lanzar la **misma consulta**, cambiando una sola cosa: `earliest` por
`latest`. Con eso la consulta ignora los 30 pedidos que ya están y **se queda
esperando lo que venga**.

🔴 **Predice antes de ejecutar:** con `latest` y el tópico quieto, ¿qué va a
imprimir la consulta? ¿Va a dar error, va a terminar, o se va a quedar ahí?

Necesitas **dos terminales**. En la **terminal A**:

**Se ejecuta.**

```bash
curl -s -N -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, producto, monto FROM pedidos_stream EMIT CHANGES LIMIT 1;","properties":{"auto.offset.reset":"latest"}}'
```

| Parte del comando | Para qué está |
|---|---|
| `-N` | 🔴 **Sin memoria intermedia.** Le dice a `curl` que imprima cada línea en cuanto llegue, en vez de juntarlas. **Sin esto no verías nada hasta el final**, y el laboratorio entero se pierde |
| `"auto.offset.reset":"latest"` | 🔴 **El cambio.** Solo lo que llegue de ahora en adelante |
| `LIMIT 1` | Con un solo mensaje ya está demostrado. Sin el `LIMIT`, Ctrl+C |

**Qué sale, al instante:**

```
{"queryId":"transient_PEDIDOS_STREAM_2522520910684089146","columnNames":["ID","PRODUCTO","MONTO"],"columnTypes":["INTEGER","STRING","DOUBLE"]}
```

**Y después, nada.** La cabecera y el cursor parpadeando.

**Cómo se lee.** 🔴 **Esa nada es el resultado.** La consulta no falló, no
terminó y no está colgada: **está esperando.** Ya sabe qué columnas va a
devolver —lo dice la cabecera— pero todavía no hay ninguna fila que devolver,
porque el dato no existe.

**Déjala ahí.** En la corrida medida estuvo **ocho segundos** sin imprimir nada.

Ahora, en la **terminal B**, se produce un pedido:

```bash
kafka-cli/produce-pedido-avro.sh 777 1001 "Pedido en vivo" 1 99999.99 pendiente
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/produce-pedido-avro.sh` | Envoltorio del curso. Escribe **un** pedido en Avro en el tópico. 🔴 **No sabe nada de ksqlDB** ni de que hay una consulta esperando |
| `777` … `pendiente` | Los seis campos del pedido. **Elige un texto reconocible** para el producto: lo vas a ver aparecer en la otra terminal |

**Vuelve a mirar la terminal A.**

**Qué sale.** Esta es la corrida medida, con la hora de cada línea:

```
[14:11:48] {"queryId":"transient_PEDIDOS_STREAM_2522520910684089146","columnNames":["ID","PRODUCTO","MONTO"],...}
[14:11:56] --- ocho segundos sin nada. Aquí se produjo el pedido en la terminal B
[14:11:57] [777,"Pedido en vivo",99999.99]
```

**Cómo se lee.** Y aquí está el laboratorio entero, en tres marcas de tiempo:

| Hora | Qué pasó |
|---|---|
| `14:11:48` | **La pregunta se hizo.** En este momento el dato no existía en ninguna parte |
| `14:11:56` | Ocho segundos después, la consulta seguía viva y sin nada que decir |
| `14:11:57` | **Un segundo después de que el dato naciera, la consulta lo contestó** |

🔴 **Nadie volvió a preguntar.** El `SELECT` se escribió una sola vez, ocho
segundos antes de que existiera la fila que lo contestó. Eso es lo que ninguna
base de datos puede hacer, y es la única razón por la que ksqlDB existe.

---

## 6 · QUÉ QUEDÓ

**Lo que quedó demostrado en pantalla, con su evidencia:**

| Lo que se afirmó | Cómo se vio |
|---|---|
| Un tópico se puede mirar como una tabla | `Stream created`, sin copiar un byte |
| Y consultarse con SQL corriente | `SELECT id, producto, monto FROM pedidos_stream` |
| Un flujo no tiene orden global | El mismo `SELECT` cinco veces: `25 5 7`, `9 7 5`, `3 5 12`, `5 19 28`, `5 19 28` |
| La pregunta puede ir antes que el dato | La cabecera a las `14:11:48`, con el tópico quieto |
| Y se contesta sola | `[777,"Pedido en vivo",...]` a las `14:11:57` |

**Las cinco reglas que se llevan a SUNAT:**

1. 🔴 **ksqlDB no es una base de datos.** No guarda tus datos: los tópicos
   siguen siendo los dueños. Si borras un stream, no pierdes nada.

2. 🔴 **`EMIT CHANGES` es la diferencia entre preguntar y quedarse
   preguntando.** Sin esas dos palabras es SQL normal; con ellas la consulta no
   termina nunca por sí sola.

3. 🔴 **`auto.offset.reset` decide qué ves, y es el error más frecuente.** Una
   consulta que «no devuelve nada» casi siempre está en `latest` sobre un tópico
   quieto. **No está rota: está esperando.**

4. 🔴 **Un flujo no tiene orden global.** Con más de una partición, las filas
   llegan en el orden en que se leen, no en el que se escribieron. Cualquier
   informe que dependa del orden entre particiones está mal planteado.

5. 🔴 **El SQL no elimina el trabajo, lo mueve.** Una consulta que corre para
   siempre es una aplicación que corre para siempre: consume memoria, se cae, y
   hay que vigilarla. **Lo que ksqlDB ahorra es escribirla, no operarla.**

**La pregunta que vale para la sala:** de los informes que tu área entrega hoy
al día siguiente, ¿cuáles cambiarían de valor si la respuesta llegara en el
momento, y cuáles no cambiarían nada?

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue estaba en el recorrido de clase y salió por tiempo. Cada
bloque trae su comando completo, pero **no está desarrollado**.

### A · La preparación de los datos

🔴 **Esto no lo hace el `start-lab.sh`**, y sin ello el Paso 1 no tiene nada
sobre lo que montarse. Son cuatro comandos y **66 segundos medidos**:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc
schema-cli/register-schema.sh novatech.lab10.clientes-value infra/schemas/cliente.avsc
kafka-cli/produce-flood-pedidos.sh 30
kafka-cli/produce-clientes-seed.sh
```

**Lo que hay que mirar:** los dos primeros son el Lab 11 exacto —registrar un
contrato— y los dos últimos escriben 30 pedidos y 5 clientes en Avro. **La
mayoría de los 66 segundos se van en los 30 pedidos**, porque cada uno arranca
una JVM dentro del contenedor.

⚠️ Los envoltorios de `schema-cli/` usan `python3`, que Git Bash para Windows no
trae. Si falla, el equivalente en `curl` está en la guía del Lab 11.

### B · El cliente interactivo, y por qué el recorrido no lo usa

ksqlDB trae un cliente de línea de comandos con prompt propio:

```bash
ksql-cli/ksql-shell.sh
```

Y dentro, sin `curl` ni JSON de por medio:

```sql
SET 'auto.offset.reset'='earliest';
SHOW STREAMS;
SELECT id, producto, monto FROM pedidos_stream EMIT CHANGES;
```

*(Ctrl+C corta la consulta y devuelve el prompt; `exit` sale.)*

**Es más cómodo que el `curl` del recorrido, y para explorar es lo que hay que
usar.** El recorrido no lo usa por una razón honesta: **su salida es una tabla
cuyo ancho depende del ancho de tu terminal**, así que no se puede prometer
línea por línea en una guía. Lo que ves en tu pantalla no es lo que vería otro.
El `curl` devuelve siempre lo mismo, y por eso es el que lleva las salidas
medidas.

**La pregunta que vale:** si el prompt es más cómodo, ¿por qué existe la API
REST? *(Pista: ¿quién hace las consultas cuando no hay una persona delante?)*

### C · STREAM contra TABLE, y la trampa que trae

Un `STREAM` son **eventos**: todo lo que pasó, y nada se pisa. Una `TABLE` es
**estado**: el último valor de cada clave. Declara los dos **sobre el mismo
tópico de clientes**, que es lo que hace visible la diferencia:

```bash
curl -s -X POST http://localhost:8088/ksql \
    -H "Content-Type: application/vnd.ksql.v1+json" \
    -d '{"ksql":"CREATE TABLE clientes_table (id INT PRIMARY KEY, nombre VARCHAR, tipo VARCHAR, ciudad VARCHAR) WITH (KAFKA_TOPIC='"'"'novatech.lab10.clientes'"'"', VALUE_FORMAT='"'"'AVRO'"'"', KEY_FORMAT='"'"'AVRO'"'"');"}' \
  | tr ',' '\n' | grep -E '"status"|"message"'
```

Y produce **dos veces el mismo cliente**, con nombres distintos:

```bash
kafka-cli/produce-cliente-avro.sh 1001 "Acme S.A." VIP Santiago
kafka-cli/produce-cliente-avro.sh 1001 "Acme S.A. - actualizado" VIP Santiago
```

🔴 **Aquí está la trampa, y cuesta un rato descubrirla.** Lo intuitivo es
consultar la tabla y esperar una sola fila. Lo que pasa de verdad, **medido**:

```bash
curl -s -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, nombre FROM clientes_table WHERE id = 1001 EMIT CHANGES LIMIT 3;","properties":{"auto.offset.reset":"earliest"}}'
```

```
[1001,"NovaCorp"]
[1001,"Acme S.A."]
[1001,"Acme S.A. - actualizado"]
```

**Tres filas, no una.** La tabla emitió **cada cambio**, igual que un stream.

Y si intentas la consulta sin `EMIT CHANGES`, que sería lo natural para pedir
«el valor actual», te contesta esto:

```
"message":"The `CLIENTES_TABLE` table isn't queryable. To derive a queryable
table, you can do 'CREATE TABLE QUERYABLE_CLIENTES_TABLE AS SELECT * FROM
CLIENTES_TABLE'."
```

**La lección, que no es la que uno esperaba:** 🔴 **la diferencia que importa no
es `STREAM` contra `TABLE`. Es push contra pull.** Un push query sobre una tabla
te da la historia de sus cambios; el estado actual solo lo da un **pull query
sobre una tabla materializada**, y eso hay que crearlo aparte:

```bash
curl -s -X POST http://localhost:8088/ksql \
    -H "Content-Type: application/vnd.ksql.v1+json" \
    -d '{"ksql":"CREATE TABLE clientes_actual AS SELECT * FROM clientes_table;"}' \
  | tr ',' '\n' | grep -E '"message"'

curl -s -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, nombre FROM clientes_actual WHERE id = 1001;"}'
```

**Salida real** — sin `EMIT CHANGES`, y ahora sí una sola fila:

```
[1001,"Acme S.A. - actualizado"]
```

⚠️ Si te contesta `Materialized data for key ... is not available yet`, la tabla
derivada todavía se está llenando. Espera unos segundos y repite.

**Y el contraste completo, sobre el mismo tópico y los mismos bytes:**

| Cómo se pregunta | Qué devuelve para la clave 1001 |
|---|---|
| `STREAM` + `EMIT CHANGES` | Los tres eventos, en orden |
| `TABLE` + `EMIT CHANGES` | Los tres, también: es push |
| `TABLE` materializada, **sin** `EMIT CHANGES` | **Solo el último** |

🔴 **Y el detalle que rompe todo esto si se olvida:** el `KEY_FORMAT='AVRO'` de
la tabla. La clave del cliente se escribió con schema Avro, y sin declararlo la
tabla no puede agrupar por clave. Es la razón de que exista el subject
`novatech.lab10.clientes-key` que viste en el Lab 11.

### D · Filtrar, que es lo que la sala va a pedir

```bash
curl -s -N -X POST http://localhost:8088/query-stream \
    -H "Content-Type: application/vnd.ksqlapi.delimited.v1" \
    -d '{"sql":"SELECT id, producto, monto FROM pedidos_stream WHERE monto > 50000 EMIT CHANGES LIMIT 3;","properties":{"auto.offset.reset":"earliest"}}'
```

**Lo que hay que mirar:** el `WHERE` se aplica **a medida que pasa cada
mensaje**, no sobre un conjunto ya guardado. Es el del paso, mirando cada
comanda y anotando solo las que cumplen.

### E · Agregar y unir

Las dos cosas que convierten esto en algo útil de verdad, y que están escritas
como referencia en `infra/ksqldb/statements.sql`:

```sql
CREATE TABLE pedidos_por_cliente AS
  SELECT cliente_id, COUNT(*) AS total, SUM(monto) AS suma
  FROM pedidos_stream GROUP BY cliente_id EMIT CHANGES;
```

**Lo que hay que mirar:** una agregación sobre un flujo **produce una tabla**,
porque el conteo por cliente es estado, no eventos. Y para el `JOIN` con
`clientes_table` hace falta que el stream esté **re-particionado por
`cliente_id`** y con el mismo número de particiones que la tabla — es el
`pedidos_rekey` del archivo. ksqlDB lo exige y falla si no se cumple.

### F · El reporte y el desafío

`plantillas/reporte-entregable.md` recorre las actividades del recorrido viejo.
Las respuestas de referencia están en `soluciones/reporte-resuelto.md` y
`soluciones/respuestas-desafio.md`, y el desafío completo en la guía archivada
`_fuente-extra/guia/02-desafio-streaming-sql-original.md`.

---

## Cierre

El clúster queda arriba para el Lab 14. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Siguiente:** Lab 14 — *la seguridad no se demuestra con lo que permite.*
