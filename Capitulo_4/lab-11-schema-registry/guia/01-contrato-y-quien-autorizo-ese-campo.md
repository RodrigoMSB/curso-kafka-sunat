# Lab 11 · Schema Registry

## ¿Quién autorizó ese campo nuevo?

> **Este es el laboratorio donde Kafka deja de confiar en la buena voluntad.**
> Hasta ahora, todo lo que escribiste en un tópico entró. Kafka no miró adentro
> ni una sola vez. Hoy vas a poner en el camino la única pieza del ecosistema
> cuyo trabajo es **decir que no**.

**Duración.** Si lo repites tú solo, la corrida completa de los 4 pasos tomó
**7 segundos medidos** de punta a punta, en 12 comandos, y **cero segundos de
espera**: aquí no hay ninguna ronda del broker que aguardar. En clase toma 20
minutos, porque el laboratorio entero es explicación.
**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`),
con sus 3 brokers y el Schema Registry respondiendo en el puerto 8081.

---

## 1 · EL PROBLEMA

Un martes, un desarrollador del equipo de fulfillment agrega un campo al
pedido. Necesita guardar el medio de pago, y agregar un campo es la cosa más
inocente que se le puede hacer a un registro. Lo prueba en su máquina, funciona,
lo sube. El productor no falla. El tópico sigue recibiendo. Los tableros siguen
dibujando. Nadie se entera de nada, porque no hay nada de qué enterarse.

El jueves, el equipo de analytics corre el reproceso del mes para el cierre. Y
el proceso se cae. No en el primer mensaje: se cae **en el mensaje cuarenta mil
y algo**, que es donde el histórico viejo se junta con lo que se escribió desde
el martes.

Nadie rompió nada a propósito. El del martes agregó un campo. El de analytics no
tocó una línea de código. Y el cierre no salió.

**El problema es que entre esos dos equipos no había nada.** Un tópico de Kafka
acepta lo que le pongas: para el broker son bytes, y no los mira. El acuerdo
sobre qué significan esos bytes existía —los dos equipos lo tenían clarísimo—
pero existía en la cabeza de la gente, en un correo de hace ocho meses, y en el
código de cada uno por separado. **Un acuerdo que no está en ninguna parte
ejecutable no es un contrato: es una costumbre.** Y las costumbres se rompen sin
que salte nada.

Y hay una segunda mitad, que es la que hace esto caro de verdad: **el error no
aparece cuando alguien lo comete.** Aparece cuando alguien lee. En una base de
datos, un `INSERT` que viola el esquema falla ahí mismo, delante del que lo
escribió, con su nombre en el log. En Kafka el que escribe se va a su casa
tranquilo y el que se cae es otro, dos días después, sin ninguna pista de qué
cambió ni quién lo cambió.

Ese *«¿y esto desde cuándo viene así?»* es lo que vas a cerrar hoy.

---

## 2 · LA METÁFORA

Durante todo el curso Kafka es **un restaurante**. Vale la pena repasar el
reparto antes de seguir, porque hoy se suman dos piezas.

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| Las libretas de respaldo que copian cada comanda | Las **réplicas** |
| El pincho donde se van clavando las comandas del turno | El **segmento** |

Las piezas nuevas de hoy:

| En el restaurante | En Kafka |
|---|---|
| **El formato de la comanda**: qué casillas trae y cuáles son obligatorias | El **schema** |
| **El talonario oficial del local**: el único lugar donde está definido cómo es una comanda válida, y quién decide si se puede cambiar | El **Schema Registry** |

Hasta ahora, en este curso, el salón y la cocina se entendían porque sí. Nadie
había escrito nunca en qué casillas va cada cosa. Funcionaba porque el local es
chico y todos se conocen.

Ahora imagina que alguien del salón manda a imprimir un talonario nuevo. Le
agrega una casilla —**«número de tarjeta»**— y la deja **obligatoria**: una
comanda sin esa casilla llena no es una comanda válida. Los mozos empiezan a
usar el talonario nuevo esa misma tarde. Nadie avisó a la cocina, porque para el
salón no cambió nada: la comanda tiene una casilla más, y punto.

Y entonces la cocina, que viene con retraso, sigue sacando comandas del pincho
del turno anterior. Comandas escritas con el talonario **viejo**. Y el cocinero
—que ya aprendió el formato nuevo— llega a la casilla «número de tarjeta» y
**no está**. No está en blanco: no existe. Y nadie le dijo nunca qué hacer
cuando no está.

La cocina se detiene. Y no se detuvo por culpa de la comanda que tiene en la
mano, que está perfecta: se detuvo por culpa de un talonario que se cambió sin
preguntar.

De ahí sale la única regla que necesitas para entender todo lo demás:

> 🍽 **El talonario no se cambia sin preguntarle a la cocina si va a poder
> seguir leyendo lo que ya está escrito.**

Eso es exactamente lo que hace Schema Registry. Y, para lo que hoy nos importa,
es **lo único** que hace.

---

## 3 · CÓMO LO RESUELVE

La traducción técnica son tres piezas, y ninguna sirve sin las otras dos.

> 📄 **Schema**
> La declaración de qué campos tiene un mensaje, de qué tipo es cada uno, y
> cuáles pueden faltar. En este laboratorio está escrito en **Avro**, que es un
> archivo `.avsc` con formato JSON. Es el formato de la comanda.

> 🗄 **Schema Registry**
> Un servicio aparte del clúster —aquí, el contenedor `schema-registry`, que
> responde en `http://localhost:8081`— donde viven todos los schemas. No es
> parte del broker: es una pieza más del ecosistema Confluent, con su propia
> API REST. Es el talonario oficial.

> 🏷 **Subject**
> El nombre bajo el que se guarda la historia de un schema. Por convención es
> `<tópico>-value` para el schema del valor y `<tópico>-key` para el de la
> clave. El tuyo va a ser `novatech.lab10.pedidos-value`. Un subject **no tiene
> un schema: tiene una lista de versiones**, y esa lista solo crece.

Y ahora la pieza que decide todo, que es una regla de una línea:

> ⚖️ **Compatibilidad BACKWARD**
> El modo con el que viene configurado este clúster. Dice: **un lector que ya
> tiene el schema nuevo tiene que poder leer los datos escritos con el schema
> viejo.** Ese es el cocinero de la metáfora: aprendió el talonario nuevo y
> sigue sacando comandas viejas del pincho.

La palabra «backward» confunde a todo el mundo la primera vez, así que vale la
pena fijar quién es quién:

| Quién | Qué tiene | Qué se le exige |
|---|---|---|
| **El lector** (consumidor) | El schema **nuevo** | Que **no se caiga** |
| **El dato** | Escrito con el schema **viejo** | Nada. Ya está escrito, no se puede cambiar |

🔴 **Y aquí está la consecuencia que no está escrita en ninguna definición de
una línea:** bajo BACKWARD, **agregar un campo obligatorio es un cambio
incompatible.** No porque agregar campos esté mal, sino porque el lector nuevo,
al toparse con un dato viejo, va a buscar ese campo y no lo va a encontrar, y
**nadie le dijo qué poner en su lugar.**

De ahí sale la única cosa que hay que recordar sobre cómo se agregan campos en
Kafka:

> 📦 **Valor por defecto** (*default*)
> Lo que el lector debe asumir cuando el campo no viene en el dato. Un campo con
> default se puede agregar sin romper a nadie: el lector nuevo lee un dato
> viejo, no encuentra el campo, y usa el default. **Un campo sin default no
> tiene salida.**

El campo que el desarrollador del martes agregó —`tarjeta_credito`, obligatorio,
sin default— es exactamente el caso que no tiene salida. Y es el que vas a
intentar registrar en el Paso 2.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **El contrato de datos no es un documento: es una compuerta, y se demuestra
> con lo que rechaza.**

Tres partes, y las tres se ven en pantalla:

- **es una compuerta** — hay un momento exacto, y una respuesta exacta, en que
  el cambio no entra;
- **rechaza** — y no rechaza en silencio: dice **qué campo**, **por qué**, y
  **contra qué versión** lo comparó;
- **no hay puerta trasera** — al que escribe con `curl` y al que escribe con un
  productor de Kafka les pasa exactamente lo mismo.

---

## 5 · LOS PASOS

### Paso 1 · Escribir el contrato

**Se explica.**

Hoy el tópico `novatech.lab10.pedidos` ya existe y está vacío, y **no tiene
ningún contrato asociado**. Eso es lo normal: un tópico de Kafka nunca lo tiene
hasta que alguien lo pone.

> 📋 **Tópico**
> El nombre bajo el que se agrupan mensajes del mismo tipo. No es una tabla ni
> una cola: es un registro que solo crece por el final. Es el tipo de comanda.

> 🖥 **Broker**
> Cada uno de los servidores Kafka del clúster. Este laboratorio levanta tres:
> `kafka-broker-1`, `kafka-broker-2` y `kafka-broker-3`. Es el mozo. 🔴 **El
> Schema Registry no es uno de ellos**: es un cuarto contenedor, aparte, y el
> broker ni se entera de que existe.

El contrato que vamos a firmar es el pedido tal como lo conocen hoy los tres
equipos: seis campos, todos obligatorios. Está en el repositorio, y conviene
mirarlo antes de registrarlo.

**Se ejecuta.**

```bash
cat infra/schemas/pedido.avsc
```

**Qué sale.**

```json
{
  "type": "record",
  "name": "Pedido",
  "namespace": "com.novatech.lab10",
  "fields": [
    {"name": "id", "type": "int"},
    {"name": "cliente_id", "type": "int"},
    {"name": "producto", "type": "string"},
    {"name": "cantidad", "type": "int"},
    {"name": "monto", "type": "double"},
    {"name": "estado", "type": "string"}
  ]
}
```

**Cómo se lee.** Seis campos, cada uno con su tipo. **Ninguno tiene la palabra
`default`.** Los seis son obligatorios: un mensaje al que le falte cualquiera de
ellos no es un pedido válido. Guarda eso, porque es la mitad de la explicación
del Paso 2.

Ahora se registra:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc
```

| Parte del comando | Para qué está |
|---|---|
| `schema-cli/register-schema.sh` | Envoltorio del curso. Por dentro hace un `POST` a la API REST del Registry con el archivo embebido en JSON |
| `novatech.lab10.pedidos-value` | El **subject**. El `-value` no es decorativo: dice que este contrato es para el **valor** del mensaje, no para su clave |
| `infra/schemas/pedido.avsc` | El archivo con el schema |

El comando real que corre por debajo, y que es el que vas a escribir en el
servidor de SUNAT donde no hay envoltorios:

```bash
curl -s -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data '{"schema": "<el .avsc, escapado como texto>"}' \
    http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions
```

| Parámetro | Para qué está |
|---|---|
| `-X POST` | Registrar es escribir. El `GET` sobre la misma URL solo lista las versiones |
| `-H "Content-Type: ...v1+json"` | El tipo de contenido propio del Registry. Sin esta cabecera contesta `415` |
| `--data '{"schema": ...}'` | 🔴 El schema **no viaja como JSON**: viaja como una **cadena de texto** dentro de un JSON. Por eso el envoltorio usa `python3` para escaparlo, y por eso escribir este `curl` a mano es incómodo |

**Qué sale.**

```json
{
    "id": 1,
    "version": 1,
    "guid": "f7c3dc5b-9a9f-1792-4c66-77095fdbd42d",
    "schemaType": "AVRO",
    "schema": "{\"type\":\"record\",\"name\":\"Pedido\",...}"
}
```

**Cómo se lee.** Son dos números distintos y conviene no confundirlos nunca:

| Campo | Qué dice |
|---|---|
| `version: 1` | La versión **dentro de este subject**. Es la que le importa a la gente: «el contrato de pedidos va en la v1» |
| `id: 1` | El identificador **global del Registry**, único en todo el clúster. Es el que viaja pegado a cada mensaje. Hoy coinciden porque es el primer schema del laboratorio; en un clúster con veinte tópicos no coinciden nunca |
| `schemaType: AVRO` | El Registry también acepta JSON Schema y Protobuf. Aquí es Avro |

> ⚠️ **Si los dos números no te salen en 1**, no está roto. El `id` es un
> contador global del Registry que **nunca reutiliza valores**: si ya corriste
> este laboratorio antes sin volver a levantar el clúster, tu `id` será 3, o 7.
> El único que vuelve a 1 es el `version`, y solo si el subject se borró
> **permanentemente**. La forma de tener la salida exacta de arriba es arrancar
> con `bin/start-lab.sh`, que borra los volúmenes y con ellos el tópico
> `_schemas` donde vive ese contador.

🔴 **El `id` es la pieza que hace que Avro pese tan poco.** Cada mensaje que se
escriba desde ahora no lleva el schema adentro: lleva **ese número**, en cuatro
bytes, y el que lee usa el número para pedirle el schema al Registry una sola
vez. Los nombres de los campos —`cliente_id`, `producto`, `monto`— no se repiten
en cada mensaje, como sí pasa en JSON.

El contrato está firmado. Desde este momento el tópico tiene reglas.

---

### Paso 2 · El cambio que parece inocente

**Se explica.**

Este es el paso central del laboratorio. Vamos a hacer exactamente lo que hizo
el desarrollador del martes: agregar un campo.

Antes de ejecutar nada, mira **la única diferencia** entre el contrato firmado y
el que se quiere firmar:

**Se ejecuta.**

```bash
diff infra/schemas/pedido.avsc infra/schemas/pedido-v3-incompatible.avsc
```

| Parte del comando | Para qué está |
|---|---|
| `diff` | Compara dos archivos línea por línea. No toca nada ni habla con el clúster |
| el primer archivo | El contrato **vigente**, el que ya está registrado |
| el segundo archivo | El contrato **propuesto** |

**Qué sale.**

```
11c11,12
<     {"name": "estado", "type": "string"}
---
>     {"name": "estado", "type": "string"},
>     {"name": "tarjeta_credito", "type": "string"}
```

**Cómo se lee.** El `11c11,12` dice «la línea 11 del primero cambia por las
líneas 11 y 12 del segundo». Lo de abajo del `<` es lo viejo, lo de abajo del
`>` es lo nuevo. **Y el cambio es una sola línea:** un campo llamado
`tarjeta_credito`, de tipo `string`. Sin `default`.

🔴 **Detente aquí y pregúntale a la sala qué va a pasar.** Es un campo nuevo, al
final, que no toca ninguno de los seis que ya estaban. No renombra nada, no
borra nada, no cambia ningún tipo. Para casi cualquier persona esto es el cambio
más seguro que existe.

Ahora, antes de intentar registrarlo, se lo preguntamos al Registry. Esto es
importante en la vida real: **existe una forma de preguntar sin escribir.**

```bash
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

| Parte del comando | Para qué está |
|---|---|
| `check-compatibility.sh` | `POST` a `/compatibility/subjects/<subject>/versions/latest`. 🔴 **Es de solo consulta**: pregunta y no registra nada, pase lo que pase |
| `novatech.lab10.pedidos-value` | Contra qué subject se compara |
| `...pedido-v3-incompatible.avsc` | El schema propuesto |

**Qué sale.**

```json
{
    "is_compatible": false
}
```

**Cómo se lee.** Una sola palabra, y es la respuesta a la pregunta de la sala.
Este es el comando que un equipo pone en su *pipeline* de integración continua:
**se pregunta antes de desplegar, no después.**

Y ahora sí, se intenta registrar:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

**Qué sale.**

```json
{
    "error_code": 40901,
    "message": "Schema being registered is incompatible with an earlier schema for subject \"novatech.lab10.pedidos-value\", details: [{errorType:'READER_FIELD_MISSING_DEFAULT_VALUE', description:'The field 'tarjeta_credito' at path '/fields/6' in the new schema has no default value and is missing in the old schema', additionalInfo:'tarjeta_credito'}, {oldSchemaVersion: 1}, {oldSchema: '{\"type\":\"record\",\"name\":\"Pedido\",...}'}, {validateFields: 'false', compatibility: 'BACKWARD'}]"
}
```

**Cómo se lee.** Esa pared de texto es el laboratorio entero. Vale la pena
leerla en voz alta, porque **el Registry está explicando su propia decisión**, y
hay cuatro datos adentro:

| Lo que dice | Qué significa |
|---|---|
| `errorType: READER_FIELD_MISSING_DEFAULT_VALUE` | El nombre del motivo. Traducido: *«al que lee le falta un campo y no tiene qué poner en su lugar»*. Es el cocinero de la metáfora, exacto |
| `The field 'tarjeta_credito' ... has no default value and is missing in the old schema` | 🔴 **Nombra el campo culpable.** No dice «hay una incompatibilidad»: dice cuál, y dice las dos condiciones que la causan —no tiene default, y no está en el schema viejo— |
| `oldSchemaVersion: 1` | Contra qué versión comparó. Bajo BACKWARD compara contra **la última**, no contra todas |
| `compatibility: 'BACKWARD'` | 🔴 **Con qué regla juzgó.** El mismo cambio, bajo otro modo, tendría otro veredicto. La compuerta no es una ley universal: es una política que alguien configuró |

Y el `error_code: 40901` es el código propio del Registry, no el de HTTP. El
HTTP que devolvió es un **409 Conflict** — el comando que lo muestra está en
*Para profundizar I*.

**Lo que hay que decir en este punto**, porque es la lección y no se deduce
sola: el desarrollador del martes **no habría llegado al jueves**. Su despliegue
se cae el martes, en su propia pantalla, con el nombre del campo que lo rompió.
🔴 **Eso es todo lo que compra Schema Registry: adelantar el error al momento y
a la persona que lo puede arreglar.**

---

### Paso 3 · Y no hay puerta trasera

**Se explica.**

Aquí siempre aparece la misma objeción en la sala, y es una buena objeción:
*«bueno, pero eso es porque usaste el comando del Registry. Yo escribo con un
productor de Kafka y el broker no sabe nada de contratos».*

Es cierto que el broker no sabe nada. El contrato **no lo aplica el broker**: lo
aplica la biblioteca del cliente, antes de que el mensaje salga. Y la forma de
demostrarlo es la que vale para cualquier compuerta: **hacerla decir que no, y
después hacerla decir que sí, con el mismo comando.**

Primero, cuántos mensajes hay en el tópico ahora mismo.

> 🔢 **Offset**
> El número de orden de un mensaje dentro de su partición. Empieza en 0 y solo
> sube. El offset «más nuevo» de una partición es, en la práctica, la cuenta de
> mensajes que se han escrito en ella.

**Se ejecuta.**

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1 \
  | awk -F: '{s+=$3} END {print s" mensajes"}'
```

| Parte del comando | Para qué está |
|---|---|
| `docker exec kafka-broker-1` | Ejecuta dentro del contenedor del broker 1, que es donde vive la herramienta |
| `kafka-get-offsets` | Pregunta por los offsets de un tópico. Solo consulta |
| `--time -1` | El offset **más nuevo**. (`-2` sería el más antiguo) |
| `\| awk -F: '{s+=$3} ...'` | La salida trae una línea por partición, con formato `tópico:partición:offset`. El `awk` corta por `:`, suma la tercera columna y deja un solo número. El tópico tiene 12 particiones y contarlas a ojo en clase no funciona |

**Qué sale.**

```
0 mensajes
```

Ahora el productor, con el contrato que el Registry acaba de rechazar:

```bash
echo '{"id":99,"cliente_id":1001,"producto":"Caja premium","cantidad":1,"monto":25000.00,"estado":"pendiente","tarjeta_credito":"4111-1111-1111-1111"}' \
| MSYS_NO_PATHCONV=1 docker exec -i \
    -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
    schema-registry kafka-avro-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --reader-property schema.registry.url=http://schema-registry:8081 \
    --reader-property value.schema="$(tr -d '\n ' < infra/schemas/pedido-v3-incompatible.avsc)" \
  2>&1 | grep -oE "^org[^:]*Exception"
```

Es el comando más largo del laboratorio y cada pedazo hace falta:

| Parte del comando | Para qué está |
|---|---|
| `echo '{...}' \|` | El mensaje, con los siete campos del contrato nuevo. El productor de consola lee de la entrada estándar |
| `MSYS_NO_PATHCONV=1` | 🔴 **Solo para Git Bash en Windows.** Sin esto, Git Bash ve el `/etc/cp-base-java/...` de la línea siguiente y lo traduce a una ruta de Windows antes de que Docker la vea. Fuera de Windows nadie lee esta variable |
| `docker exec -i` | El `-i` mantiene abierta la entrada estándar, que es por donde entra el `echo` |
| `-e SCHEMA_REGISTRY_LOG4J_OPTS=...` | Silencia el volcado de configuración que la imagen imprime por defecto. Sin esto la pantalla se llena con cuarenta líneas de `INFO` antes del error |
| `schema-registry kafka-avro-console-producer` | 🔴 Corre dentro del contenedor **del Registry**, no del broker: las herramientas de Avro vienen en esa imagen y no en la de Kafka |
| `--reader-property schema.registry.url=...` | A qué Registry preguntarle. Sin esto el productor no sabe traducir a Avro y falla |
| `--reader-property value.schema=...` | El contrato con el que este productor dice que va a escribir |
| `$(tr -d '\n ' < ...)` | Aplasta el `.avsc` a una sola línea, porque el flag no acepta saltos de línea |
| `2>&1 \| grep -oE "^org[^:]*Exception"` | El error viene con veinte líneas de traza de Java. Esto deja **solo el nombre de la excepción**. El motivo detallado ya lo leíste en el Paso 2: es el mismo |

**Qué sale.**

```
org.apache.kafka.common.errors.SerializationException
```

**Cómo se lee.** *Serialization*, no *Authorization* ni *Broker*: **el mensaje
nunca llegó a la red.** Se cayó al convertirlo a bytes, dentro del proceso del
productor, porque el paso de convertir a Avro incluye ir a preguntarle al
Registry y el Registry dijo que no.

Y ahora el número que cierra el argumento:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1 \
  | awk -F: '{s+=$3} END {print s" mensajes"}'
```

```
0 mensajes
```

🔴 **Sigue en cero.** No entró un mensaje a medias, ni un mensaje corrupto que
haya que limpiar después. No entró nada.

**Y ahora la mitad que hace que esto sea una demostración y no un susto.** El
mismo comando, con lo único distinto siendo el archivo del contrato:

```bash
echo '{"id":1,"cliente_id":1001,"producto":"Caja premium","cantidad":10,"monto":25000.00,"estado":"pendiente"}' \
| MSYS_NO_PATHCONV=1 docker exec -i \
    -e SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j2.configurationFile=/etc/cp-base-java/log4j2.yaml" \
    schema-registry kafka-avro-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --reader-property schema.registry.url=http://schema-registry:8081 \
    --reader-property value.schema="$(tr -d '\n ' < infra/schemas/pedido.avsc)" \
  2>&1 | grep -oE "^org[^:]*Exception"
```

**Qué sale.**

```

```

**Nada.** Ni una línea. El `grep` no encontró ninguna excepción que mostrar,
porque no hubo ninguna. Y el tópico:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1 \
  | awk -F: '{s+=$3} END {print s" mensajes"}'
```

```
1 mensajes
```

**Cómo se lee.** Mismo productor, mismo broker, mismo tópico, mismo mensaje de
seis campos. Lo único que cambió es **con qué contrato dijo que escribía**. Uno
pasó y el otro no.

🔴 **Esa es la prueba de que la compuerta es una compuerta.** Una que rechaza
todo no sirve de nada; hay que verla dejar pasar.

---

### Paso 4 · El cambio que sí pasa

**Se explica.**

Si el laboratorio terminara en el Paso 3, la sala se llevaría una conclusión
falsa y peligrosa: *«con Schema Registry no se pueden agregar campos»*. Se
pueden. Hay exactamente una condición.

Mira la otra propuesta que trae el laboratorio, contra el mismo contrato
vigente:

**Se ejecuta.**

```bash
diff infra/schemas/pedido.avsc infra/schemas/pedido-v2-compatible.avsc
```

**Qué sale.**

```
11c11,12
<     {"name": "estado", "type": "string"}
---
>     {"name": "estado", "type": "string"},
>     {"name": "prioridad", "type": ["null", "string"], "default": null}
```

**Cómo se lee.** Otra vez **una sola línea**: un campo nuevo, al final. La misma
forma de cambio que el Paso 2. Y dos diferencias que lo cambian todo:

| Lo que trae | Qué significa |
|---|---|
| `"type": ["null", "string"]` | Un tipo **unión**: este campo puede ser un texto **o** puede ser nulo. En Avro, un campo que admite nulo se declara así, con una lista |
| `"default": null` | 🔴 **La pieza que faltaba en el Paso 2.** Le dice al lector nuevo qué asumir cuando el dato viejo no trae este campo: nulo |

Pregúntale otra vez al Registry:

```bash
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v2-compatible.avsc
```

**Qué sale.**

```json
{
    "is_compatible": true
}
```

Y se registra:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido-v2-compatible.avsc
```

**Qué sale.**

```json
{
    "id": 2,
    "version": 2,
    "guid": "8039c9ea-b34f-edeb-4674-e9dd977a4b01",
    "schemaType": "AVRO",
    "schema": "{\"type\":\"record\",\"name\":\"Pedido\",...,{\"name\":\"prioridad\",\"type\":[\"null\",\"string\"],\"default\":null}]}"
}
```

**Cómo se lee.** `version: 2`. El subject ahora tiene dos versiones, y la vieja
**no se borró**:

```bash
curl -s http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions
```

```
[1,2]
```

🔴 **Las dos siguen ahí, y tienen que seguir.** El mensaje que escribiste en el
Paso 3 lleva pegado el `id: 1`. Si la v1 desapareciera, ese mensaje quedaría
ilegible para siempre. **El Registry no es un archivo de configuración que se
sobrescribe: es un registro histórico, y por eso vive en un tópico de Kafka**
(`_schemas`, que puedes ver en *Para profundizar F*) y no en un archivo.

---

## 6 · QUÉ QUEDÓ

**Lo que quedó demostrado en pantalla, con su evidencia:**

| Lo que se afirmó | Cómo se vio |
|---|---|
| El contrato existe y tiene versión | `version: 1` al registrarlo, `[1,2]` al final |
| Un cambio que rompe al que lee no entra | `is_compatible: false` y `error_code: 40901` |
| Y el Registry dice **por qué** | `READER_FIELD_MISSING_DEFAULT_VALUE`, con el nombre del campo |
| No hay puerta trasera para el productor | `SerializationException`, y el tópico en `0 mensajes` |
| Pero la compuerta sí deja pasar | El mismo comando con el otro contrato: sin error, `1 mensajes` |
| El cambio correcto entra sin drama | `is_compatible: true` → `version: 2` |

**Las cinco reglas que se llevan a SUNAT:**

1. 🔴 **Un tópico sin subject registrado no tiene contrato.** No importa cuánta
   documentación exista: si no está en el Registry, no lo aplica nadie.

2. 🔴 **Todo campo que se agregue lleva `default`.** Es la única diferencia
   entre el schema del Paso 2 y el del Paso 4, y es la diferencia entre un
   despliegue que sale y uno que no.

3. 🔴 **`check-compatibility` va en el *pipeline*, no en la consola.** Preguntar
   antes de desplegar cuesta un segundo; descubrirlo el jueves cuesta el cierre
   del mes.

4. 🔴 **El modo de compatibilidad es una decisión, no un valor de fábrica.**
   El propio mensaje de error dice `compatibility: 'BACKWARD'`. Alguien lo
   eligió. En SUNAT, ese alguien tiene que tener nombre.

5. 🔴 **Las versiones viejas no se borran.** Cada mensaje escrito lleva el `id`
   de su schema. Borrar una versión es dejar ilegibles los datos que la usaron.

**La pregunta que vale para la sala:** de los tópicos que tu equipo tiene hoy en
producción, ¿cuántos tienen subject registrado, y quién decidió su modo de
compatibilidad?

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue estaba en el recorrido de clase y salió por tiempo. Cada
bloque trae su comando completo, pero **no está desarrollado**: se lee y se
ejecuta solo.

### A · El subject antes de que exista

Este era el primer paso del recorrido viejo. Cámbialo de orden: córrelo
**antes** del Paso 1 y verás la lista vacía.

```bash
schema-cli/list-subjects.sh
```

```
[]
```

**Lo que hay que mirar:** un clúster recién levantado no trae ni un contrato.
Todo lo que hay en el Registry lo puso alguien.

### B · Producir y consumir Avro de verdad

El Paso 3 escribió un mensaje con un comando crudo, para poder romperlo a
propósito. El envoltorio del curso hace lo mismo, más corto:

```bash
kafka-cli/produce-pedido-avro.sh 7 1001 "Caja premium" 10 25000.00 pendiente
kafka-cli/consume-avro.sh novatech.lab10.pedidos
```

*(Ctrl+C para salir del consumidor.)*

**Lo que hay que mirar:** el consumidor imprime **JSON**, pero en el tópico no
hay JSON: hay bytes binarios con el `id` del schema adelante. Quien traduce es
el consumidor, que va al Registry con ese número y baja el contrato. Salida real
de las dos primeras líneas:

```
{"id":1,"cliente_id":1001,"producto":"Caja premium","cantidad":10,"monto":25000.0,"estado":"pendiente"}
{"id":7,"cliente_id":1001,"producto":"Caja premium","cantidad":10,"monto":25000.0,"estado":"pendiente"}
```

**La pregunta que vale:** ¿qué pasa si apagas el contenedor `schema-registry` y
vuelves a consumir?

### C · La carga masiva y el segundo contrato

```bash
kafka-cli/produce-flood-pedidos.sh 50
kafka-cli/produce-clientes-seed.sh
schema-cli/list-subjects.sh
```

**Lo que hay que mirar:** después de los clientes, la lista de subjects trae
**tres**, no dos:

```
["novatech.lab10.clientes-key","novatech.lab10.clientes-value","novatech.lab10.pedidos-value"]
```

Apareció un `-key`. El seed de clientes escribe con clave, y la clave tiene su
propio contrato, independiente del valor. Es la convención `TopicNameStrategy`
funcionando en las dos mitades del mensaje.

### D · Los otros tres modos de compatibilidad

El Paso 2 juzgó bajo `BACKWARD` porque así viene el clúster. Hay cuatro modos, y
el veredicto del mismo cambio depende de cuál esté puesto:

| Modo | Qué exige | Cuándo se usa |
|---|---|---|
| `BACKWARD` | El lector **nuevo** lee datos **viejos** | El de fábrica. Primero se actualizan los consumidores |
| `FORWARD` | El lector **viejo** lee datos **nuevos** | Cuando hay consumidores que no puedes actualizar: un mainframe, un sistema de un tercero |
| `FULL` | Las dos cosas a la vez | Máxima seguridad, mínima libertad para cambiar |
| `NONE` | Nada. Entra cualquier cosa | Solo desarrollo local. 🔴 En producción es lo mismo que no tener Registry |

Ver el modo, y cambiarlo. 🔴 **Ojo con la primera respuesta, que sorprende:**

```bash
curl -s http://localhost:8081/config/novatech.lab10.pedidos-value
```

```
{"error_code":40408,"message":"Subject 'novatech.lab10.pedidos-value' does not have subject-level compatibility configured"}
```

**Lo que hay que mirar:** el subject **no tiene modo propio**. El `BACKWARD` con
que te rechazó el Paso 2 no estaba puesto en el subject: estaba puesto en el
clúster entero, un nivel más arriba.

```bash
curl -s http://localhost:8081/config
```

```
{"compatibilityLevel":"BACKWARD"}
```

Ahora sí, ponle al subject un modo propio, que gana sobre el global:

```bash
curl -s -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data '{"compatibility":"FORWARD"}' \
    http://localhost:8081/config/novatech.lab10.pedidos-value
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

**Qué sale, medido:**

```
{"compatibility":"FORWARD"}
{
    "is_compatible": true
}
```

🔴 **El mismo archivo que el Paso 2 rechazó, ahora pasa.** No cambió el schema:
cambió quién lo juzga. Bajo `FORWARD` el lector es el **viejo**, y un lector
viejo simplemente ignora el campo que no conoce.

Y para volver:

```bash
curl -s -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data '{"compatibility":"BACKWARD"}' \
    http://localhost:8081/config/novatech.lab10.pedidos-value
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

```
{"compatibility":"BACKWARD"}
{
    "is_compatible": false
}
```

🔴 **Restáuralo siempre**, o el resto del laboratorio deja de comportarse como
está escrito. Fíjate en lo que **no** vuelve al estado inicial: el subject ahora
tiene modo propio `BACKWARD`, aunque coincida con el global. La única forma de
volver de verdad al estado de fábrica es `bin/start-lab.sh`.

**La pregunta que vale:** si el modo global manda salvo que el subject tenga uno
propio, ¿quién en SUNAT puede cambiar el global, y cuántos subjects se enterarían?

### E · `auto.register.schemas`, la puerta que sí está abierta

En el volcado de configuración del productor Avro aparece esta línea:

```
auto.register.schemas = true
```

**Lo que hay que mirar:** es el valor de fábrica, y significa que **el primer
productor que escriba en un tópico sin subject define el contrato de todos los
demás**, sin que nadie lo revise. La compuerta del Paso 2 solo existe **desde la
v1 en adelante**; para la v1 no hay compuerta que valga.

**La pregunta que vale:** en SUNAT, ¿quién debería tener permiso de escribir la
v1 de un contrato, y cómo se apaga esto? *(Pista: `auto.register.schemas=false`
en el productor, y registrar por `pipeline`.)*

### F · El tópico donde vive el Registry

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 --describe --topic _schemas
```

**Lo que hay que mirar:** el Schema Registry no tiene base de datos. Guarda todo
en un tópico de Kafka llamado `_schemas`, con una sola partición y compactado.
Si levantas otro Registry contra el mismo clúster, ve exactamente los mismos
contratos, porque los dos leen del mismo tópico.

### G · Inspección visual

Kafbat UI, en **http://localhost:8090** → pestaña *Schema Registry*. Compara lo
que la interfaz muestra con lo que devolvió `get-schema.sh`. La vista de
versiones es el equivalente visual de la lista `[1,2]` del Paso 4.

```bash
schema-cli/get-schema.sh novatech.lab10.pedidos-value
```

### H · El reporte del lab

`plantillas/reporte-entregable.md` recorre las actividades del recorrido viejo
con sus preguntas. Las respuestas de referencia están en
`soluciones/reporte-resuelto.md`.

### I · El código HTTP del rechazo

El envoltorio muestra el cuerpo de la respuesta, no su código. Para ver el
código:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\": $(python3 -c "import json;print(json.dumps(open('infra/schemas/pedido-v3-incompatible.avsc').read()))")}" \
    http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions
```

```
HTTP 409
```

**Lo que hay que mirar:** `409 Conflict`, no `400 Bad Request`. El schema no
está mal escrito —es Avro perfectamente válido—: **está en conflicto con algo
que ya existe.** El `40901` del cuerpo es el subcódigo propio del Registry
dentro de ese 409.

---

## Cierre

El clúster queda arriba para el Lab 12, que consulta con SQL estos mismos datos
Avro. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Siguiente:** Lab 12 — *¿se puede hacer un `SELECT` sobre algo que todavía está
llegando?*
