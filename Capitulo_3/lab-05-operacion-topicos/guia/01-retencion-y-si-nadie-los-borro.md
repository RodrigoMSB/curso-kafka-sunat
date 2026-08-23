# Lab 05 · Operación de tópicos

## ¿Y si nadie los borró?

> **Este es el laboratorio que explica por qué Kafka no es una base de datos.**
> Si hay una sola idea que te tienes que llevar de esta sesión, es esta: en Kafka
> el dato tiene fecha de vencimiento, la fecha la pusiste tú, y cuando vence
> nadie te avisa.

**Duración.** Si lo repites tú solo, una corrida completa de los 5 pasos tomó
**217 segundos medidos** de punta a punta — y **193 de esos 217 fueron esperar
sin hacer nada**, por un motivo que el Paso 5 explica. Los cuatro primeros
pasos suman 24 segundos. En clase toma 20 minutos, porque casi todo el
tiempo es explicación.
**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`).

---

## 1 · EL PROBLEMA

Un lunes por la mañana el área de fiscalización abre el tablero y la serie de
comprobantes del jueves anterior no está. No hay un `DELETE` en ningún log de
auditoría. Nadie tocó nada. El equipo de plataforma jura que el clúster estuvo
arriba todo el fin de semana, y tiene razón: estuvo arriba.

La sala se va a pasar la mañana en la pregunta obvia: **«¿quién los borró?»**.
Y esa pregunta se puede investigar durante días sin llegar a nada, porque parte
de un supuesto que nadie puso sobre la mesa: que alguien los borró.

Guarda la otra por ahora: **¿y si nadie los borró?**

Este es el error que más caro sale al empezar con Kafka: tratarlo como si fuera
una base de datos. En una base de datos, lo que insertaste está hasta que
alguien lo borre. En Kafka es al revés — **lo que escribiste se va solo, y la
única razón por la que sigue ahí es que el plazo que configuraste todavía no
venció**.

Y hay una segunda mitad del problema, la que muerde en el otro sentido: lo que
nunca declaraste que había que botar tampoco es gratis. Se queda para siempre y
te llena el disco. En un clúster de producción, un servidor con el disco lleno
es un servidor caído.

Las dos caras del mismo parámetro. Ese parámetro es lo que vas a operar hoy.

---

## 2 · LA METÁFORA

Durante todo el curso Kafka es **un restaurante**. Vale la pena repasar el
reparto antes de seguir, porque hoy se suma una pieza nueva.

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| Las libretas de respaldo que copian cada comanda | Las **réplicas** |
| Quiénes marcaron tarjeta y están al día | El **ISR** |
| El jefe de turno que decide quién atiende qué sector | El **controlador** |

La pieza nueva de hoy:

| En el restaurante | En Kafka |
|---|---|
| **El espiche**: el pincho donde el mozo va clavando las comandas del turno | El **segmento** |

Esto es lo que importa del espiche, y es el corazón de este laboratorio:

Cuando el turno termina, el mozo **no va sacando comanda por comanda del
pincho**. Baja el espiche entero al depósito, pone uno nuevo, y sigue. Y cuando
llega la orden de «limpiar lo viejo», **lo que se bota es el espiche completo,
no las comandas de a una**.

De ahí sale la única regla que necesitas para entender todo lo demás:

> 🍽 **Kafka no borra mensajes. Bota espiches enteros.**

---

## 3 · CÓMO LO RESUELVE

La traducción técnica de la metáfora son dos parámetros del tópico, y hay que
verlos juntos porque uno sin el otro no hace nada.

> 📦 **Segmento**
> El archivo físico en el disco del broker donde se van escribiendo los
> mensajes de **una partición**, uno detrás de otro. Cada partición tiene en
> todo momento **un segmento activo** (el espiche que está en uso, donde
> se escribe) y cero o más **segmentos cerrados** (los que ya se bajaron
> al depósito).

**`segment.ms`** — cada cuánto se cierra el espiche y se empieza uno nuevo.
Por defecto son 7 días.

**`retention.ms`** — cuánto tiempo se guarda un espiche **ya cerrado** antes de
botarlo. Por defecto también son 7 días.

> ⏳ **Retención**
> El plazo que Kafka respeta antes de botar datos viejos de un tópico. Se
> configura en milisegundos, con `retention.ms`. Es un plazo por tópico: dos
> tópicos del mismo clúster pueden tener plazos completamente distintos.

Y ahora la parte que no está escrita en ninguna documentación de una línea:

🔴 **El segmento activo no se bota nunca.** Esté como esté de viejo, mientras sea
el que está en uso, se queda. Solo los cerrados son candidatos.

Esa frase explica el 90 % de los «configuré retención de un minuto y no pasó
nada» que vas a escuchar en tu carrera. Si `segment.ms` es de 7 días y
`retention.ms` es de 1 minuto, **no se borra nada durante 7 días**: todos los
mensajes, viejos y nuevos, viven en el mismo espiche activo, y ese espiche no se
puede botar.

Hay un tercer parámetro, que es del broker y no del tópico, y que te va a
morder hoy en clase:

**`log.retention.check.interval.ms`** — cada cuánto el broker se molesta en
mirar si hay espiches vencidos. Por defecto son **5 minutos**. Kafka no borra en
el instante en que vence el plazo. Borra en la próxima pasada de la ronda.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Kafka borra mensajes solo, cuando se lo pediste, y no te avisa.**

Tres partes, y las tres se ven en pantalla:

- **solo** — nadie va a ejecutar un comando de borrado en este laboratorio;
- **cuando se lo pediste** — el plazo lo vas a escribir tú, con `--config`;
- **y no te avisa** — no hay un log, ni una alerta, ni una métrica que salte.
  El único rastro es que un número cambió.

---

## 5 · LOS PASOS

### Paso 1 · Fabricar el tópico que sí podemos ver morir

**Se explica.**

Necesitamos un tópico con los dos plazos cortos y con **una sola partición**.

> 🔑 **Clave** (*key*)
> Un identificador opcional que se le pega a cada mensaje al escribirlo, aparte
> de su contenido. En SUNAT sería el RUC, o el número de serie del comprobante.
> Es lo que Kafka usa para decidir en qué partición cae el mensaje. **Hoy vamos
> a escribir todo sin clave**, y eso tiene una consecuencia.

Lo de la partición única no es comodidad: es lo que hace que el experimento
funcione. Cuando los mensajes no llevan clave, el productor de consola **se pega
a una sola partición durante toda su sesión**, y en la sesión siguiente elige
otra. Con varias particiones, la primera ráfaga cae entera en una y la segunda
—la que tiene que cerrar el espiche— cae en **otra**. Resultado: el espiche que
contiene los datos nunca rota, nunca se cierra, y no se borra nada.

Esto está medido. Con 3 particiones el borrado tardó 265 segundos y dejó una
partición sin tocar. Con 1 partición tardó 128 segundos y se llevó todo lo
vencido. Con una sola partición hay un solo espiche y las dos ráfagas caen
obligatoriamente en el mismo sitio.

**Se ejecuta.**

```bash
kafka-cli/create-topic.sh novatech.lab05.efimero \
    --partitions 1 \
    --rf 3 \
    --config retention.ms=60000 \
    --config segment.ms=10000
```

| Parámetro | Valor | Para qué está |
|---|---|---|
| `--partitions` | `1` | Un solo pedazo, un solo espiche, un solo contador que mirar |
| `--rf` | `3` | Tres copias. El mismo nivel de resguardo que el resto del clúster |
| `--config retention.ms` | `60000` | **60 segundos.** Un espiche cerrado hace más de un minuto es candidato a irse |
| `--config segment.ms` | `10000` | **10 segundos.** El espiche se cierra rapidísimo, para que haya candidatos |

**Qué sale.**

```
Created topic novatech.lab05.efimero.
```

Puede venir acompañado de un `WARNING` sobre puntos y guiones bajos en el
nombre. Es Kafka avisando que un nombre que mezcla ambos podría chocar en sus
métricas internas. El tópico se creó igual.

---

### Paso 2 · Describirlo y leer la línea `Configs`

**Se explica.**

Antes de escribirle nada, hay que saber leerlo. Empecemos por los términos que
van a aparecer en la salida.

> 🖥 **Broker**
> Cada uno de los servidores Kafka del clúster. Este laboratorio levanta tres:
> `kafka-broker-1`, `kafka-broker-2` y `kafka-broker-3`. Es el mozo.

> 📋 **Tópico**
> El nombre bajo el que se agrupan mensajes del mismo tipo. No es una tabla ni
> una cola: es un registro que solo crece por el final. Es el tipo de comanda.

> 🍰 **Partición**
> Cada uno de los pedazos en que se corta un tópico. Un tópico de 6 particiones
> son 6 registros independientes, cada uno con su propio orden interno. Son los
> sectores del salón: por eso el trabajo se puede repartir. El tuyo tiene una
> sola, a propósito.

**Se ejecuta.**

```bash
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -2
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/describe-topic.sh` | Envoltorio del curso. Por dentro llama a `kafka-topics --describe` dentro del contenedor y le agrega la ficha didáctica |
| `novatech.lab05.efimero` | Qué tópico queremos mirar |
| `\| head -2` | El listado completo trae más de treinta configuraciones. Las dos primeras líneas son el resumen del tópico y la de su única partición |

El comando real que corre por debajo, y que es el que vas a escribir en el
servidor de SUNAT donde no hay Docker:

```bash
kafka-topics --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.lab05.efimero
```

| Parámetro | Para qué está |
|---|---|
| `--bootstrap-server` | La puerta de entrada al clúster. Le preguntas a un broker cualquiera y él te contesta por todos |
| `--describe` | Solo consulta. No modifica nada |
| `--topic` | Sobre qué tópico preguntamos |

**Qué sale.**

```
Topic: novatech.lab05.efimero	TopicId: dBn0wnH_SIKGYMgNDgfgwA	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
	Topic: novatech.lab05.efimero	Partition: 0	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr:
```

**Cómo se lee.** La primera línea es el resumen del tópico:

| Campo | Qué dice |
|---|---|
| `PartitionCount: 1` | El tópico tiene un solo pedazo, porque lo pediste así. Es el número que limita cuántos consumidores pueden trabajar en paralelo — lo vas a ver en el Lab 06 |
| `ReplicationFactor: 3` | De ese pedazo hay 3 copias, en 3 brokers distintos. Aguantas perder uno |
| `Configs: ...` | 🔴 **Esta es la parte que importa hoy.** Trae **tres** valores: los dos plazos que acabas de poner y uno que ya venía del broker |

Y aquí está la trampa clásica de esta línea: **`Configs` no lista la
configuración del tópico. Lista solo lo que está cambiado respecto del valor
por defecto.** Tu tópico tiene más de treinta configuraciones; aparecen tres
porque hay tres cosas cambiadas. En un tópico que nadie tocó esta línea se lee
casi vacía y se entiende como «este tópico no tiene configuración». Lo que dice
en realidad es «este tópico no tiene ningún valor distinto del de fábrica»:
los otros treinta y pico están ahí, con su valor por defecto, decidiendo cosas.

Uno de los que **no** aparece es `cleanup.policy`, y es el que decide qué pasa
cuando un espiche vence. Está en su valor de fábrica, `delete`: el espiche
cerrado se bota entero. Es lo que vas a ver en los pasos siguientes.

> 🧹 **La otra política, en una frase**
> `cleanup.policy` acepta también `compact`, que no mira el reloj: mira la
> **clave** de cada mensaje y guarda **solo el último valor de cada clave**,
> para siempre. Sirve para estados («¿cómo está ahora?») en vez de eventos
> («¿cuándo pasó?»). No se ejecuta en clase porque el compactador corre en
> segundo plano y tarda bastante más que este laboratorio. El comando está en
> *Para profundizar B*.

La segunda línea es la de la partición, y trae dos términos más:

> 📚 **Réplica**
> Cada una de las copias de una partición. `Replicas: 2,3,1` significa que esta
> partición vive en los brokers 2, 3 y 1. Son las libretas de respaldo.

> ✅ **ISR** (*In-Sync Replicas*)
> Cuáles de esas copias están **al día** en este momento. Si `Isr` tiene los
> mismos tres números que `Replicas`, ninguna se quedó atrás. Son los que
> marcaron tarjeta.

| Campo | Qué dice |
|---|---|
| `Partition: 0` | El número de este pedazo. Solo hay uno, así que solo está el 0 |
| `Leader: 2` | Qué broker atiende las lecturas y escrituras de este pedazo. Los otros dos solo copian. **A ti te va a salir otro número**: Kafka reparte los líderes al crear |
| `Replicas: 2,3,1` | En qué brokers está |
| `Isr: 2,3,1` | Cuáles están al día. Los tres |
| `Elr` / `LastKnownElr` | Campos nuevos de Kafka 4.x, para escenarios de pérdida más severos que los de este lab. En este laboratorio salen **siempre vacíos** |

---

### Paso 3 · Escribir 100 comprobantes y contarlos

**Se explica.**

Para contar mensajes en Kafka no se usa un `SELECT COUNT(*)`. Se usan los dos
extremos del registro.

> 🔢 **Offset**
> El número de orden de un mensaje **dentro de su partición**. Empieza en 0 y
> nunca se reutiliza. Es el número de comanda, y es correlativo: si el
> comprobante 0 se botó, el siguiente sigue siendo el 1. Los números no se
> corren hacia atrás.

Los dos extremos que importan:

- **`--time -1`** te da el **offset más nuevo**: dónde va a caer el próximo
  mensaje que se escriba. Es la marca de «hasta aquí escribimos».
- **`--time -2`** te da el **offset más antiguo que todavía existe**. Es la
  marca de «desde aquí se puede leer».

Y de ahí sale la cuenta que vas a usar toda la clase:

> ▎ **mensajes vivos = `--time -1` − `--time -2`**

Cuando Kafka bota un espiche, el offset más nuevo **no se mueve** (nadie
escribió nada). El que se mueve es el más antiguo, que salta hacia adelante.
Ese salto es el borrado. **Es el único rastro que vas a tener.**

**Se ejecuta.**

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 100
```

| Parámetro | Para qué está |
|---|---|
| `novatech.lab05.efimero` | A qué tópico se escribe |
| `100` | Cuántos mensajes generar. El envoltorio los fabrica solo, con contenido de relleno |

Y ahora los dos extremos:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -1

docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

| Parte del comando | Para qué está |
|---|---|
| `docker exec` | Ejecuta el comando **dentro** de un contenedor que ya está corriendo. En el servidor de SUNAT esta parte no existe: el comando se llama solo |
| `kafka-broker-1` | En cuál de los tres contenedores. Cualquiera sirve |
| `kafka-get-offsets` | La herramienta que pregunta por los extremos del registro. No lee mensajes, solo cuenta |
| `--bootstrap-server kafka-broker-1:29092` | Puerto **interno** del broker: estamos hablándole desde dentro de la red de Docker. Desde tu máquina sería `localhost:9092` |
| `--time -1` / `--time -2` | Cuál de los dos extremos queremos |

**Qué sale.**

```
novatech.lab05.efimero:0:100
novatech.lab05.efimero:0:0
```

**Cómo se lee.** El formato es `tópico:partición:offset`.

| Línea | Traducción |
|---|---|
| `novatech.lab05.efimero:0:100` | Partición 0, offset más nuevo = 100. Se escribieron 100 mensajes, numerados del 0 al 99 |
| `novatech.lab05.efimero:0:0` | Partición 0, offset más antiguo = 0. **No se ha botado nada todavía** |

**Mensajes vivos: 100 − 0 = 100.** Anota ese par de números. Todo el
laboratorio se juega en que el segundo deje de ser 0.

---

### Paso 4 · Cerrar el espiche

**Se explica.**

Aquí está el paso que casi todo el mundo se salta, y por saltárselo concluye
que la retención «no funciona».

`segment.ms=10000` **no** significa que un temporizador cierre el espiche a los
10 segundos. Significa que **la próxima vez que llegue un mensaje**, si el
espiche tiene más de 10 segundos de vida, se cierra y se abre uno nuevo.

Kafka no rota espiches en un tópico donde no está pasando nada. Y no lo hace por
una razón sensata: cerrar un espiche cuesta trabajo en disco, y no tiene sentido
gastarlo en un tópico que nadie está usando.

Consecuencia directa: **si escribes 100 mensajes y te vas a esperar, no se borra
nada nunca.** Los 100 quedan en el espiche activo, el espiche activo no se bota,
y puedes esperar hasta mañana. Necesitas escribir algo más, después de que pasen
los 10 segundos, para que el espiche viejo se cierre.

**Se ejecuta.** Espera unos quince segundos y escribe unos pocos mensajes más:

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 5
```

Ahora mira los archivos que el broker tiene en disco para esa partición:

```bash
MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 \
    ls /var/lib/kafka/data/novatech.lab05.efimero-0
```

| Parte del comando | Para qué está |
|---|---|
| `MSYS_NO_PATHCONV=1` | 🔴 **Obligatorio en Git Bash.** Sin esto, Git Bash convierte `/var/lib/...` en una ruta de Windows antes de que Docker la vea, y el comando falla con un error que no tiene nada que ver. En macOS y Linux la variable se ignora |
| `ls /var/lib/kafka/data/...` | El directorio donde el broker guarda los espiches de esa partición |
| `novatech.lab05.efimero-0` | El nombre del directorio es `<tópico>-<partición>`. El `-0` es la partición 0 |

**Qué sale.**

```
00000000000000000000.index
00000000000000000000.log
00000000000000000000.timeindex
00000000000000000100.index
00000000000000000100.log
00000000000000000100.snapshot
00000000000000000100.timeindex
leader-epoch-checkpoint
partition.metadata
```

**Cómo se lee.**

| Archivo | Qué es |
|---|---|
| `00000000000000000000.log` | El primer espiche. Su nombre es el offset del primer mensaje que contiene: el 0. **Ya está cerrado** |
| `00000000000000000100.log` | El espiche nuevo, el activo. Arranca en el offset 100 |
| `.index` / `.timeindex` | Índices para no tener que recorrer el `.log` entero al buscar |

> **Si `produce-bulk.sh` se queda colgado sin decir nada**, casi siempre es que
> el tópico no existe — te saltaste el Paso 1, o hiciste `bin/reset-lab.sh` en
> el medio. El clúster tiene la creación automática **desactivada** a propósito,
> y el productor reintenta en silencio en vez de fallar. Ctrl+C, crea el tópico,
> y repite.

🔴 **Si solo ves un `.log`, el espiche no rotó.** Espera diez segundos más y
vuelve a escribir 5 mensajes. Sin dos archivos `.log` aquí, el resto del
laboratorio no va a mostrar nada, porque no hay ningún espiche cerrado que
botar.

Ese primer `.log`, el que arranca en 0, es el que tiene los 100 comprobantes.
Está cerrado, y tiene el reloj corriendo.

Ojo con el contador: con estos 5 mensajes extra, `--time -1` ya no es 100 sino
**105**. Los 5 nuevos están en el espiche activo, que es el que no se puede
botar.

---

### Paso 5 · Esperar, y contar de nuevo

**Se explica.**

Ya están puestas las tres condiciones:

1. el espiche `0` está **cerrado**;
2. sus mensajes tienen más de `retention.ms` = 60 segundos de antigüedad;
3. la política es `cleanup.policy=delete`.

Falta la cuarta, que no depende de ti: **que pase la ronda del broker**. El
`log.retention.check.interval.ms` por defecto son 5 minutos, así que el borrado
va a ocurrir en algún momento dentro de los próximos 5 minutos y no hay forma
de apurarlo desde el tópico.

Esto no es un defecto del laboratorio. Es exactamente el comportamiento del
clúster de producción, y es la mitad de la afirmación que estamos demostrando:
**no te avisa, y ni siquiera está mirando todo el tiempo.**

**Se ejecuta.** Vuelve a preguntar por el offset más antiguo, cada tanto, hasta
que se mueva:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

**Qué sale.** Primero, varias veces, lo mismo de antes:

```
novatech.lab05.efimero:0:0
```

Y en algún momento, sin que nadie haya ejecutado nada:

```
novatech.lab05.efimero:0:105
```

**Cómo se lee.** El offset más antiguo disponible pasó de **0** a **105**.

| Antes | Después |
|---|---|
| `--time -1` → 105 | `--time -1` → 105 (no se movió: nadie escribió) |
| `--time -2` → 0 | `--time -2` → **105** |
| vivos: 105 − 0 = **105** | vivos: 105 − 105 = **0** |

**No quedó ninguno.** Los 100 comprobantes de la primera ráfaga y los 5 de la
segunda, todos. Para cuando llegó la ronda del broker, los 5 de la segunda
ráfaga también habían pasado los 60 segundos, así que también estaban vencidos.

> **Si a ti te salió `novatech.lab05.efimero:0:100` en vez de `:0:105`, está
> igual de bien** — significa que la ronda llegó antes y los 5 últimos todavía
> no habían vencido. Te quedan 5 vivos en lugar de 0. Lo que se demuestra es lo
> mismo: **se fue todo lo que había pasado el plazo, y nadie ejecutó nada.**

Nadie los borró. No hay una alerta, no hay una entrada en un log de auditoría,
no hay una métrica que saltara. **El único rastro es que un número que valía 0
dejó de valer 0.**

Y si quieres verlo en el disco:

```bash
MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 \
    ls /var/lib/kafka/data/novatech.lab05.efimero-0
```

```
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
```

**Cómo se lee.** Los espiches viejos siguen ahí, pero **renombrados a
`.deleted`**. Kafka borra en dos tiempos: primero renombra —y desde ese
instante el archivo ya no existe para ningún consumidor— y un minuto después
lo borra de verdad del disco. Ese minuto es `file.delete.delay.ms=60000`.

Si esperas un minuto más y repites el `ls`, los `.deleted` desaparecen y queda
solo `00000000000000000105.log`: un espiche nuevo, vacío, esperando el próximo
mensaje.

> **Si tras cinco minutos el número sigue en 0**, casi siempre es el Paso 4: no
> hay un segundo `.log`. Vuelve a escribir 5 mensajes y espera la siguiente
> ronda. `docs/troubleshooting.md` no cubre este caso — el diagnóstico está
> aquí.

---

## 6 · QUÉ QUEDÓ

### Lo que se demostró

> ▎ **Kafka borra mensajes solo, cuando se lo pediste, y no te avisa.**

| La afirmación decía | Y en pantalla se vio |
|---|---|
| **solo** | Nadie ejecutó un comando de borrado en todo el laboratorio |
| **cuando se lo pediste** | El plazo lo escribiste tú, en el Paso 1: `retention.ms=60000` |
| **y no te avisa** | Ni log, ni alerta, ni métrica. Solo `--time -2` dejó de valer 0 |

### Las cinco reglas, para llevarse a SUNAT

**1 · `retention.ms` sin `segment.ms` no hace nada.**
El plazo se cuenta desde que el espiche se **cierra**, no desde que el mensaje
se escribió. Lo viste en el Paso 4: los 100 comprobantes no se movieron hasta
que escribiste otros 5. Con los valores de fábrica (7 días y 7 días), un dato
puede vivir hasta 14 días en un tópico que en el papel dice 7 — la cuenta, sobre
un tópico real, está en *Para profundizar G*.

**2 · El segmento activo es intocable.**
Un tópico sin escrituras nuevas no borra nada, por vencido que esté. Si tienes
un tópico que dejó de recibir tráfico, sus últimos mensajes se quedan ahí para
siempre.

**3 · El borrado no es un evento observable.**
No hay alerta. Si alguien tiene que enterarse de que un dato venció, ese aviso
lo construyes tú, fuera de Kafka. La única señal es que el offset más antiguo
saltó.

**4 · La retención es una decisión de negocio, no de infraestructura.**
«¿Cuántos días hay que poder reprocesar un comprobante?» no la contesta el
equipo de plataforma. La contesta quien responde por el proceso. El equipo de
plataforma solo la escribe en `--config`.

**5 · Un tópico sin retención declarada también es una decisión.**
Es la decisión de quedarse con los 7 días de fábrica. Casi nunca es la que
alguien quiso tomar.

### La cuenta que se usa para todo

> **mensajes vivos = `kafka-get-offsets --time -1` − `kafka-get-offsets --time -2`**

Es la misma cuenta que vas a usar en el Lab 06 y en el Lab 07.

> 👥 **Grupo de consumo**
> El conjunto de consumidores que se reparten entre sí las particiones de un
> tópico, de modo que cada mensaje lo lee **uno solo** del grupo. Kafka le
> anota a cada grupo por dónde va. Es el tema del Lab 06; aquí solo hace falta
> saber que existe, porque «hasta dónde leyó un grupo» se mide con esta misma
> resta de offsets — y se le llama ***lag***.

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue está fuera del recorrido de hoy **por tiempo, no por
dificultad**. Tres de estos bloques —**B** (compactación), **C** (cambio en
caliente) y **G** (los 7 + 7 días)— estaban en el recorrido de clase hasta esta
versión y salieron para que el laboratorio quepa en 20 minutos de dictado. 🔴
**El que más rinde es C**: es la operación que de verdad vas a hacer todas las
semanas.

**Los comandos de esta sección se ejecutaron uno por uno contra este mismo
clúster antes de publicarlos**, así que corren tal cual están escritos; el
análisis queda para ti.

Salvo `novatech.fleet.gps`, que el clúster trae creado, los tópicos que estas
actividades usan **no existen todavía**: el recorrido de hoy solo creó
`novatech.lab05.efimero`. Cada bloque que lo necesita incluye su creación.

### A · Cuatro tópicos, cuatro personalidades

Cada perfil de dato pide una configuración distinta.

```bash
# Telemetría de alta frecuencia: 1 hora de retención, compresión rápida
kafka-cli/create-topic.sh novatech.gps.realtime --partitions 12 --rf 3 \
    --config retention.ms=3600000 --config compression.type=lz4 \
    --config segment.ms=600000

# Auditoría y cumplimiento: 90 días, compresión densa
kafka-cli/create-topic.sh novatech.audit.events --partitions 6 --rf 3 \
    --config retention.ms=7776000000 --config compression.type=gzip \
    --config min.insync.replicas=2

# Estado actual por vehículo: compactación en vez de retención
kafka-cli/create-topic.sh novatech.vehicle.state --partitions 6 --rf 3 \
    --config cleanup.policy=compact --config min.cleanable.dirty.ratio=0.1

# Alertas críticas: máxima durabilidad, retención ilimitada
kafka-cli/create-topic.sh novatech.alerts.critical --partitions 3 --rf 3 \
    --config min.insync.replicas=3 --config retention.ms=-1 \
    --config unclean.leader.election.enable=false
```

**La pregunta que vale:** `min.insync.replicas=3` sobre `--rf 3` significa que
si **un solo** broker se cae, el tópico deja de aceptar escrituras. ¿En qué caso
eso es lo que quieres?

### B · Compactación de verdad

*(En clase queda mencionada en una frase: existe una política que guarda solo
el último valor de cada clave. Esto es verla.)*

Sobre `novatech.vehicle.state`, escribe cinco mensajes con la misma clave y
mira qué sobrevive:

```bash
kafka-cli/produce-bulk.sh novatech.vehicle.state 100 --key-pattern NVT
```

**La trampa:** la compactación es asíncrona y `min.cleanable.dirty.ratio`
decide cuándo vale la pena hacerla. Inmediatamente después de escribir, están
todos. Ver el resultado toma bastante más que los 60 segundos de hoy.

### C · Cambiar la configuración en caliente

Una regulación cambia y hay que pasar la auditoría de 90 días a un año, sin
reiniciar nada:

```bash
kafka-cli/alter-topic-config.sh novatech.audit.events --add retention.ms=31536000000
kafka-cli/describe-topic.sh novatech.audit.events | grep -E "^  retention.ms="
```

**Lo que hay que mirar:** el campo `synonyms` al final de la línea. Las salidas
reales, antes y después:

```
antes     retention.ms=7776000000  ... synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=7776000000}
después   retention.ms=31536000000 ... synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=31536000000}
```

Fíjate en lo que **no** pasó: `DYNAMIC_TOPIC_CONFIG` ya estaba ahí **antes** del
cambio. No lo puso el `--alter` — lo puso el `--config` con que se creó el
tópico. Todo valor que escribas tú, al crear o al modificar, queda marcado así.

El que nunca tuvo valor propio es `novatech.fleet.gps` —el de *Para profundizar G*—, con
`synonyms={}`. Ese `{}` significa «aquí no escribió nadie; esto es lo que manda
el broker».

Y para volver ahí:

```bash
kafka-cli/alter-topic-config.sh novatech.audit.events --delete retention.ms
kafka-cli/describe-topic.sh novatech.audit.events | grep -E "^  retention.ms="
```

```
  retention.ms=604800000 sensitive=false synonyms={}
```

Los 90 días desaparecieron y el tópico volvió a los 7 días de fábrica, con el
`synonyms` otra vez vacío. **Ese es el camino que hay que saber reconocer:** un
`--delete` no pone el valor en cero, lo devuelve al del broker — que casi nunca
es el que querías.

Y lo que hay que decir el día que en SUNAT alguien pida «guardemos más»:
🔴 **subir la retención hoy no rescata lo que ya se fue.** Los comprobantes que
el Paso 5 vio desaparecer no vuelven con un `--alter`. El cambio solo mueve el
plazo de los que todavía están vivos, y aplica desde la próxima ronda del
broker — la misma ronda del Paso 5.

Lo mismo funciona sobre el tópico del recorrido, si todavía lo tienes:

```bash
kafka-cli/alter-topic-config.sh novatech.lab05.efimero --add retention.ms=3600000
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -1
```

### D · Particiones: el camino de ida

```bash
kafka-cli/alter-topic-partitions.sh novatech.gps.realtime 18   # funciona
kafka-cli/alter-topic-partitions.sh novatech.gps.realtime 6    # falla
```

**Por qué falla:** la partición de un mensaje se decide con el *hash* de su
clave sobre el número de particiones. Si bajaras de 18 a 6, las claves que hoy
caen en la partición 14 pasarían a caer en otra, y sus mensajes viejos se
quedarían donde están. El orden por clave —lo único que Kafka garantiza— se
rompería en silencio. Kafka prefiere fallar.

### E · Inspección visual

Kafbat UI, en **http://localhost:8090** → *Topics*. Compara lo que la interfaz
muestra con lo que devolvió la línea de comandos. La pestaña *Settings* de cada
tópico es el equivalente visual de `describe-topic.sh`.

### F · El reporte del lab

`plantillas/reporte-entregable.md` recorre las actividades de esta sección con
sus preguntas. Las respuestas de referencia están en
`soluciones/reporte-resuelto.md`.

### G · Los 7 + 7 días de un tópico recién salido de fábrica

Este bloque estaba en el recorrido de clase y salió por tiempo. Es la versión
aritmética de lo que la doble tanda del Paso 4 ya te mostró en vivo.

El clúster trae creado `novatech.fleet.gps`, con 6 particiones y **ningún plazo
propio**. Mira los tres valores que deciden su borrado:

```bash
kafka-cli/describe-topic.sh novatech.fleet.gps | grep -E "^  (retention.ms|segment.ms|cleanup.policy)="
```

```
  cleanup.policy=delete sensitive=false synonyms={DEFAULT_CONFIG:log.cleanup.policy=delete}
  retention.ms=604800000 sensitive=false synonyms={}
  segment.ms=604800000 sensitive=false synonyms={}
```

**Lo que hay que mirar:** los dos números son el mismo, 604 800 000 ms ÷ 1000 ÷
60 ÷ 60 ÷ 24 = **7 días**. El espiche se cierra cada 7 días, y el plazo de 7
días **empieza a contar cuando el espiche se cierra**. Un mensaje puede vivir
hasta **14 días** en un tópico que en el papel dice «7 días de retención».
Nadie mintió: el plazo no se cuenta desde donde uno cree.

Y el `^  ` con dos espacios del `grep` no es decorativo: ancla al inicio de
línea. Sin él, `retention.ms` también matchea dentro de `local.retention.ms`.

**La pregunta que vale:** ¿cuántos de los tópicos que tu equipo tiene hoy en
producción están en este estado, y quién decidió que 7 días era el número?

---

## Cierre

El clúster queda arriba para el Lab 06. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Siguiente:** Lab 06 — *si el trabajo se reparte entre varios, ¿quién decide
cuánto le toca a cada uno?*
