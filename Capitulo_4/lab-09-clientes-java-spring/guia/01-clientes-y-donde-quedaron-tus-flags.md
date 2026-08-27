# Lab 09 · Clientes Java

## ¿Dónde quedaron tus flags?

> **Este laboratorio no es para que escribas código.** Es para que, el día que
> un desarrollador te mande un programa que «no conecta con Kafka», puedas abrir
> el archivo, encontrar las cuatro líneas que importan, y decirle cuál está mal.
> Eso es trabajo de administración, y no se puede hacer sin haber visto nunca
> un cliente por dentro.

**Duración.** Si lo repites tú solo, la corrida completa tomó **8 segundos
medidos** de punta a punta, en **tres comandos** — el del Paso 1 no se ejecuta,
está para mirarlo. La primera vez suma la descarga de Maven: **4 segundos y 16
MB en 25 archivos**, medidos en una máquina con el repositorio local vacío. En
clase toma 20 minutos, porque casi todo el tiempo es leer código en pantalla.

🔴 **La única dependencia de este laboratorio que no está en Docker es Maven.**
Compruébalo antes de la clase con `mvn -v`. Si no está, el Paso 3 no corre y el
resto del laboratorio sí.
**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`),
con sus 3 brokers y el tópico `novatech.lab09.pedidos` creado.

---

## 1 · EL PROBLEMA

Un martes te llega un correo del equipo de desarrollo: *«el servicio de
comprobantes no está publicando en Kafka. ¿Pueden revisar el clúster?»*.

Revisas el clúster. Los tres brokers están arriba. El tópico existe, con sus
particiones y sus réplicas al día. No hay nada que revisar: **el clúster está
perfecto.**

Y aquí es donde la conversación se puede ir por dos caminos muy distintos.

El primero: contestas «por aquí está todo bien» y devuelves el correo. Dos días
después el problema sigue, ahora con más gente copiada, y nadie ha mirado el
único lugar donde puede estar.

El segundo: pides el archivo. Lo abres. Son treinta líneas, y **veinticinco no
te importan**. Las que importan son cuatro, y las reconoces porque son
exactamente las mismas cosas que tú escribiste con guiones en el Lab 06.
Encuentras que el `bootstrap.servers` apunta a un puerto interno que desde la
máquina del desarrollador no existe, y contestas eso.

**La diferencia entre los dos caminos no es saber Java.** Es haber visto una vez
que el código de un cliente Kafka no tiene nada nuevo adentro: **son tus flags,
escritos de otra forma.**

Y hay una segunda mitad, la que hace que esto importe de verdad: **el broker no
puede ayudarte a distinguir.** Para él, un cliente Java y una consola son
exactamente el mismo cliente. No hay un log que diga «este mensaje vino de una
aplicación». Si el mensaje no llegó, el broker no tiene nada que contarte.

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
| El equipo que se reparte los sectores del salón | El **grupo de consumidores** |

Hoy **no se suma ninguna pieza nueva**, y eso es justamente la lección.

Hasta ahora, cuando querías meter una comanda, la escribías tú, a mano, en el
talonario. Eso era `kafka-console-producer`.

Un cliente Java es **la misma comanda escrita por una caja registradora** en vez
de por una mano. La caja tiene que saber lo mismo que sabía la mano: a qué mozo
entregarle la comanda, de qué tipo es, y si lleva número de mesa. Ni más ni
menos.

Y lo importante, que es lo que hay que ver hoy en pantalla:

> 🍽 **El mozo no sabe si la comanda la escribió una mano o una máquina, y no
> tiene forma de saberlo.** Le llega una comanda, la clava en el espiche, y
> sigue.

De ahí sale la única regla que necesitas para entender todo lo demás: **un
cliente no es una capa sobre Kafka. Es un cliente de Kafka, igual que la
consola.** Lo que cambia es quién teclea.

---

## 3 · CÓMO LO RESUELVE

Un cliente Kafka en cualquier lenguaje tiene siempre las mismas tres partes, y
conviene tener los nombres antes de ver el archivo.

> 🧾 **Properties** (las propiedades)
> Una lista de pares `clave = valor` que se le entrega al cliente antes de
> arrancarlo. **Son tus flags.** Cada `--algo` que escribiste en el Lab 06 es una
> línea de esta lista, con otro nombre.

> 🏭 **`KafkaProducer` / `KafkaConsumer`**
> El objeto que abre la conexión y habla el protocolo de Kafka. Es lo que en la
> consola era el comando entero: `kafka-console-producer`.

> ✉️ **`ProducerRecord`**
> Un mensaje: a qué tópico va, con qué clave, y con qué valor. En la consola
> esto era **una línea de texto** que tú escribías y partía el separador.

Y la pieza que hace que Kafka pueda mover cualquier cosa:

> 🔄 **Serializador** (*serializer*)
> Kafka **solo mueve bytes**. No sabe qué es un pedido, ni un número, ni una
> fecha. El serializador es la función que convierte tu objeto en bytes al
> escribir, y el deserializador la que los vuelve a convertir al leer. En la
> consola nunca lo viste porque el texto ya era bytes.

🔴 **Y la trampa que esto esconde, que es de administración y no de desarrollo:**
el serializador del que escribe y el deserializador del que lee **son dos piezas
distintas, en dos programas distintos, que nadie obliga a coincidir**. Si no
coinciden, el que se cae es el que lee. Ese es exactamente el problema que el
Lab 11 va a resolver con Schema Registry — y por eso este laboratorio va antes.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Lo que hiciste con dos comandos de consola son veinte líneas de código, y
> hace exactamente lo mismo.**

Tres partes, y las tres se ven en pantalla:

- **veinte líneas** — vas a contar los renglones que de verdad importan, y son
  cuatro propiedades;
- **exactamente lo mismo** — lo que escriba el programa Java lo vas a leer con
  el mismo `kafka-console-consumer` del Lab 06, sin adaptar nada;
- **y donde parecían distintos** —el `--from-beginning`— vas a ver que la
  diferencia no estaba donde todos creen.

---

## 5 · LOS PASOS

### Paso 1 · Los flags que ya sabes

**Se explica.**

Antes de abrir un archivo Java, hay que tener fresco con qué se lo va a
comparar. Este es el comando con el que produjiste en el Lab 06, tal cual:

```bash
echo "RUC-20100066601:comprobante_1" | \
docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --property parse.key=true --property key.separator=:
```

🔴 **No lo ejecutes: ese tópico es de otro laboratorio.** Está aquí para
mirarlo. Quédate con las cuatro decisiones que tomaste al escribirlo:

| Lo que decidiste | Con qué flag |
|---|---|
| A qué clúster hablarle | `--bootstrap-server` |
| A qué tópico escribir | `--topic` |
| Si el mensaje lleva clave | `--property parse.key=true` |
| Cómo separar la clave del valor | `--property key.separator=:` |

**Cuatro decisiones.** Guárdalas, porque son las que vas a buscar en el archivo.

---

### Paso 2 · El mismo comando, escrito en Java

**Se explica.**

> 📋 **Tópico**
> El nombre bajo el que se agrupan mensajes del mismo tipo. No es una tabla ni
> una cola: es un registro que solo crece por el final. Es el tipo de comanda.

> 🔑 **Clave** (*key*)
> Un identificador opcional que se le pega a cada mensaje. Es lo que Kafka usa
> para decidir en qué partición cae. En SUNAT sería el RUC o el número de serie
> del comprobante.

**Se ejecuta.**

```bash
cat cliente-java/src/main/java/com/novatech/kafka/ProductorApp.java
```

**Qué sale.** **53 líneas**, contadas. 🔴 **De esas 53, estas son las que
importan, y son las únicas que vamos a leer:**

```java
Properties props = new Properties();
props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP);
props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, PedidoSerializer.class.getName());
props.put(ProducerConfig.ACKS_CONFIG, "all");

try (Producer<String, Pedido> producer = new KafkaProducer<>(props)) {
    ProducerRecord<String, Pedido> record =
            new ProducerRecord<>(TOPIC, pedido.pedidoId(), pedido);
    producer.send(record, (metadata, exception) -> { ... });
    producer.flush();
}
```

**Cómo se lee.** Ahora la tabla que es el laboratorio entero. **Cada flag que
escribiste en el Paso 1 está aquí, con otro nombre:**

| Lo que escribiste en el Lab 06 | Dónde está en el Java |
|---|---|
| `--bootstrap-server kafka-broker-1:29092` | `props.put(BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP)` |
| `--topic novatech.validacion` | El **primer argumento** de `new ProducerRecord<>(TOPIC, ...)` |
| `--property parse.key=true` | El **segundo argumento**: `new ProducerRecord<>(TOPIC, pedido.pedidoId(), pedido)` |
| `--property key.separator=:` | 🔴 **No existe, y no puede existir.** En la consola clave y valor viajaban pegados en una línea de texto y había que partirla. En Java **son dos parámetros distintos**, así que no hay nada que separar |
| *(no tenía flag)* | `props.put(ACKS_CONFIG, "all")` — el `acks` del Lab 07, aquí explícito |
| *(no tenía flag)* | Los dos `SERIALIZER_CLASS_CONFIG`. En la consola nunca aparecieron porque **lo que escribías ya era texto**; aquí hay que decir cómo se convierte un `Pedido` en bytes |

🔴 **Ese es el archivo entero.** Lo demás son el `for`, el `System.out.printf` y
los `import`. **Si mañana te llega un programa que no conecta, estas cinco
líneas son las que abres**, y la primera de la lista es la que falla nueve de
cada diez veces.

**La pregunta que vale para la sala:** el `BOOTSTRAP` de este archivo dice
`localhost:9092,localhost:9093,localhost:9094`. ¿Por qué **no** dice
`kafka-broker-1:29092`, que es lo que usa la consola?

*(Porque la consola corre **dentro** de la red de Docker y este programa corre
**fuera**, en tu máquina. Es exactamente la clase de error que vas a
diagnosticar.)*

---

### Paso 3 · Correrlo

**Se explica.**

No hay nada que escribir: el proyecto ya está. Solo se compila y se ejecuta.

**Se ejecuta.**

```bash
cd cliente-java
mvn -q compile exec:java \
    -Dexec.mainClass="com.novatech.kafka.ProductorApp" \
    -Dexec.args="5"
```

| Parte del comando | Para qué está |
|---|---|
| `mvn` | Maven, la herramienta de construcción de Java. 🔴 **Si no la tienes instalada, este paso no corre** — es la única dependencia externa del laboratorio |
| `-q` | Modo silencioso. Sin esto Maven imprime treinta líneas de su propio proceso antes de llegar a lo tuyo |
| `compile` | Convierte el `.java` en `.class`. **La primera vez descarga las bibliotecas**: 16 MB y 25 archivos, medidos |
| `exec:java` | Ejecuta una clase del proyecto |
| `-Dexec.mainClass=...` | Cuál de las clases. El proyecto tiene un productor y un consumidor |
| `-Dexec.args="5"` | Los argumentos del programa. Aquí, cuántos pedidos enviar |

**Qué sale.**

```
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
Enviado a novatech.lab09.pedidos [particion 2, offset 0]
Enviado a novatech.lab09.pedidos [particion 2, offset 1]
Enviado a novatech.lab09.pedidos [particion 1, offset 0]
Enviado a novatech.lab09.pedidos [particion 1, offset 1]
Enviado a novatech.lab09.pedidos [particion 1, offset 2]
Total de pedidos enviados: 5
```

**Cómo se lee.**

⚠️ **Las tres primeras líneas son ruido y salen siempre.** SLF4J es la
biblioteca de registro de Java diciendo que no encontró con qué escribir logs, y
se conforma con no escribir ninguno. **No es un error del laboratorio** y no
afecta a nada. Está aquí escrito para que no te distraiga en clase.

Lo que importa son las cinco líneas del medio:

| Lo que dice | Qué significa |
|---|---|
| `Enviado a novatech.lab09.pedidos` | El tópico al que fue. El mismo tipo de nombre que vienes usando desde el Lab 05 |
| `[particion 2, offset 0]` | 🔴 **Kafka le contestó al programa.** No es el programa adivinando: es el broker confirmando dónde quedó el mensaje. Eso solo pasa porque el `acks=all` de la línea 5 lo obligó a esperar la confirmación |
| Dos en la partición 2 y tres en la 1 | El reparto por **clave**. Cada pedido lleva un UUID como clave, y su hash decide la partición. 🔴 **A ti te van a salir otros números y está bien**: en dos corridas medidas salió `2,2,2,2,0` y `2,2,1,1,1`. Lo que no cambia es que el broker le dijo al programa dónde quedó cada uno |

---

### Paso 4 · Y leerlo con la consola del Lab 06

**Se explica.**

Este es el paso que cierra la afirmación. Si un cliente Java fuera «otra cosa»,
haría falta un consumidor Java para leerlo. Vamos a usar **exactamente el mismo
comando de consola** del Lab 06, sin adaptar nada.

> 🔢 **Offset**
> El número de orden de un mensaje dentro de su partición. Empieza en 0 y solo
> sube.

**Se ejecuta.**

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --from-beginning --max-messages 5 \
    --formatter-property print.key=true
```

| Parte del comando | Para qué está |
|---|---|
| `--from-beginning` | Empieza por el mensaje más viejo que el tópico conserva |
| `--max-messages 5` | 🔴 **Sin esto el comando no termina nunca.** Lee cinco y sale solo |
| `--formatter-property print.key=true` | Imprime la clave además del valor. Es el reemplazo moderno de `--property`, que en Kafka 8 avisa que está en desuso |

**Qué sale.**

```
9a6cbc8d-7205-4ae8-aae6-f1d663280178	{"pedidoId":"9a6cbc8d-7205-4ae8-aae6-f1d663280178","cliente":"cliente-1","producto":"producto-1","cantidad":1,"monto":100.0}
dc130f27-ac10-4fb5-89c2-b1865ea164e7	{"pedidoId":"dc130f27-ac10-4fb5-89c2-b1865ea164e7","cliente":"cliente-3","producto":"producto-3","cantidad":3,"monto":300.0}
acf665d0-0076-426f-b73b-5ae56cf9e4fe	{"pedidoId":"acf665d0-0076-426f-b73b-5ae56cf9e4fe","cliente":"cliente-2","producto":"producto-2","cantidad":2,"monto":200.0}
1cb6c046-00be-464e-9b4f-ecf7023ceef8	{"pedidoId":"1cb6c046-00be-464e-9b4f-ecf7023ceef8","cliente":"cliente-4","producto":"producto-4","cantidad":4,"monto":400.0}
76fdb928-d3f4-4eec-bdaf-66ee549a1721	{"pedidoId":"76fdb928-d3f4-4eec-bdaf-66ee549a1721","cliente":"cliente-5","producto":"producto-0","cantidad":5,"monto":500.0}
Processed a total of 5 messages
```

*(Los UUID son distintos en cada corrida: los genera el programa. Los `cliente-N`
y los montos no.)*

**Cómo se lee.** 🔴 **Eso es todo. No hubo que adaptar nada.**

| Lo que se ve | Qué demuestra |
|---|---|
| A la izquierda del tabulador, el UUID | Es la **clave** que puso el `new ProducerRecord<>(TOPIC, pedido.pedidoId(), pedido)`. La consola la lee sin saber quién la escribió |
| A la derecha, el JSON | Es lo que produjo el `PedidoSerializer`. Para Kafka son bytes; que se vean como JSON legible es una decisión del programa, no de Kafka |
| El comando es el del Lab 06 | **No existe un `kafka-console-consumer --java`.** No hace falta, y ahí está la afirmación |

**🔴 Y ahora el matiz que muerde, y que está medido.** Alguien va a decir: *«pero
la consola tiene `--from-beginning` y el Java tiene `auto.offset.reset=earliest`.
No son lo mismo.»*

Sí lo son. Lo que engaña es otra cosa. Estas son las cuatro corridas:

| Qué se corrió | 1ª vez | 2ª vez |
|---|---|---|
| Consola **sin** `--group`, con `--from-beginning` | 8 mensajes | **8 mensajes** |
| Consola **con** `--group`, con `--from-beginning` | 8 mensajes | **0 mensajes** |
| Consumidor Java (siempre lleva grupo) | 8 mensajes | **0 mensajes** |

*(La corrida que devuelve 0 termina con un `ERROR ... TimeoutException` antes
del `Processed a total of 0 messages`. **No es un fallo:** es el `--timeout-ms`
cumpliéndose porque no llegó nada. La línea que importa es la última.)*

**Cómo se lee.** El consumidor de consola, cuando no le das `--group`, **se
inventa un grupo nuevo en cada arranque**. Como ese grupo nunca leyó nada, no
tiene offsets guardados, y `earliest` lo manda al principio. Por eso *parece*
que `--from-beginning` «siempre lee todo».

En cuanto le pones un grupo de verdad —que es lo que hace cualquier programa—
**se comporta igual que el Java: la segunda vez no trae nada.**

🔴 **Esto no es trivia.** Es la causa número uno de «el consumidor dejó de leer»
en producción: el grupo ya tenía offsets guardados y nadie los miró. Y se
diagnostica con el `--describe --group` del Lab 06.

---

## 6 · QUÉ QUEDÓ

**Lo que quedó demostrado en pantalla, con su evidencia:**

| Lo que se afirmó | Cómo se vio |
|---|---|
| Los flags son las propiedades | La tabla del Paso 2, línea por línea |
| Son cinco líneas, no un framework | El bloque del `Properties` y el `ProducerRecord` |
| El broker le contesta al programa | `[particion 2, offset 0]`, que lo devolvió Kafka |
| La consola lee lo que Java escribió | El mismo comando del Lab 06, sin adaptar |
| Y donde parecían distintos, no lo eran | Las cuatro corridas: sin grupo 8 y 8; con grupo 8 y 0 |

**Las cinco reglas que se llevan a SUNAT:**

1. 🔴 **Un cliente Kafka no es una capa sobre Kafka: es Kafka.** El broker no
   distingue una consola de una aplicación, y no hay log que te lo diga.

2. 🔴 **Cuando un programa «no conecta», el primer archivo que se abre es el de
   las propiedades**, y la primera línea que se mira es `bootstrap.servers`.
   Nueve de cada diez veces está ahí.

3. 🔴 **`bootstrap.servers` depende de desde dónde corre el programa.** Un
   nombre de contenedor no se resuelve fuera de la red de Docker, y una
   dirección `localhost` no sirve dentro de ella.

4. 🔴 **El serializador y el deserializador son dos piezas que nadie obliga a
   coincidir.** El que se cae es el que lee, dos días después. Eso es lo que el
   Lab 11 viene a cerrar.

5. 🔴 **Un consumidor con grupo no vuelve a leer lo que ya leyó**, por más
   `earliest` que tenga. Si un consumidor «dejó de recibir», mira sus offsets
   antes que el clúster.

**La pregunta que vale para la sala:** de los incidentes de Kafka que tu equipo
atendió el último año, ¿cuántos terminaron siendo del clúster, y cuántos de la
configuración de un cliente?

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue estaba en el recorrido de clase y salió por tiempo. **Este
laboratorio es de desarrollo y la audiencia es de administración**, así que se
recortó a reconocer el código, no a escribirlo. Cada bloque trae su comando
completo, pero **no está desarrollado**.

### A · El consumidor Java, y el grupo

El Paso 4 leyó con la consola a propósito. El proyecto también trae su
consumidor:

```bash
cd cliente-java
mvn -q compile exec:java \
    -Dexec.mainClass="com.novatech.kafka.ConsumidorApp" \
    -Dexec.args="grupo-java-nativo"
```

*(Ctrl+C para salir; no termina solo.)* **Salida real de las primeras líneas:**

```
Consumidor en grupo 'grupo-java-nativo' escuchando novatech.lab09.pedidos (Ctrl+C para salir)...
[particion 2 offset 0] cliente-2 -> producto-2 x2 ($200.00)
[particion 0 offset 0] cliente-1 -> producto-1 x1 ($100.00)
```

**Lo que hay que mirar:** sus propiedades son cinco y son las mismas de siempre,
más `GROUP_ID_CONFIG` —que es el `--group` del Lab 06— y `AUTO_OFFSET_RESET`.
**Córrelo dos veces con el mismo grupo** y verás el 8 y el 0 de la tabla del
Paso 4.

### B · La serialización, de verdad

```bash
cat cliente-java/src/main/java/com/novatech/kafka/PedidoSerializer.java
cat cliente-java/src/main/java/com/novatech/kafka/PedidoDeserializer.java
cat cliente-java/src/main/java/com/novatech/kafka/Pedido.java
```

**Lo que hay que mirar:** el serializador es, en esencia, `objeto → byte[]`, y
el deserializador `byte[] → objeto`. **Son dos archivos separados que nadie
obliga a coincidir.** Si el productor agrega un campo y el consumidor no se
entera, el que revienta es el consumidor.

**La pregunta que vale:** ¿qué pasaría si el productor mandara `monto` como
texto y el consumidor lo esperara como número? *(Y compárala con lo que el Lab
11 hace con esa misma pregunta.)*

### C · Spring for Apache Kafka

La misma cosa, con el código escondido detrás de anotaciones:

```bash
cd cliente-spring
mvn spring-boot:run
```

Y en otra terminal, produciendo por HTTP:

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"pedidoId":"p-1001","cliente":"ACME","producto":"caja","cantidad":3,"monto":1500.0}' \
  http://localhost:8081/api/pedidos
```

**Lo que hay que mirar:** `KafkaTemplate` hace lo que hacía el `KafkaProducer` a
mano, y `@KafkaListener` reemplaza el bucle de `poll()`. Las propiedades no
desaparecieron: se mudaron a `src/main/resources/application.yml` y a la clase
`KafkaConfig`. 🔴 **Ese es el punto para un administrador: cuando el programa es
Spring, las propiedades están en un `.yml`, no en el `.java`.** Es el archivo
que hay que pedir.

### D · Consumer groups y rebalanceo, con clientes de verdad

Tres terminales en `cliente-java/`, las tres con el **mismo** grupo:

```bash
mvn -q compile exec:java -Dexec.mainClass="com.novatech.kafka.ConsumidorApp" -Dexec.args="grupo-escalado"
```

Y en una cuarta, produciendo:

```bash
mvn -q compile exec:java -Dexec.mainClass="com.novatech.kafka.ProductorApp" -Dexec.args="30"
```

**Lo que hay que mirar:** el tópico tiene 3 particiones, así que las tres
instancias reciben una cada una. Mata una con Ctrl+C y vuelve a producir: sus
particiones se reparten entre las dos que quedan. **Es exactamente el
rebalanceo del Lab 06, pero con procesos en vez de terminales.**

**La pregunta que vale:** ¿qué pasa si levantas una **cuarta** instancia sobre 3
particiones?

### E · El desafío de interoperabilidad

Produce con `cliente-java` y consume con la app de Spring corriendo. Documenta
si el consumidor de Spring recibió lo que produjo la API nativa, y qué dice eso
sobre el formato del mensaje en el tópico.

### F · El reporte del lab

`plantillas/reporte-entregable.md` recorre las actividades del recorrido viejo
con sus preguntas. Las respuestas de referencia están en
`soluciones/reporte-resuelto.md`.

---

## Cierre

El clúster queda arriba para el Lab 10. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Siguiente:** Lab 10 — *¿y a las tres de la mañana?*
