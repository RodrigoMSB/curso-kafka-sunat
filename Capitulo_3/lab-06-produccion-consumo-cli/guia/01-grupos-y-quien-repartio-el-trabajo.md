# Lab 06 · Producción y consumo por CLI

## ¿Y quién repartió el trabajo?

> **Este es el laboratorio del concepto que más cuesta de Kafka.** No es nada de
> lo que viste hasta ahora: es que **dos procesos que leen exactamente lo mismo
> a veces se reparten el trabajo y a veces lo duplican** — y lo que decide cuál
> de las dos cosas pasa es **una sola palabra** del comando.

**Duración.** La ejecución de los cuatro pasos son **96 segundos medidos** de
punta a punta, y unos 70 de esos 96 son esperar a que Kafka rehaga el reparto.
En clase toma 20 minutos, porque casi todo el tiempo es explicación.

**Antes de empezar:** el clúster arriba (`bin/start-lab.sh`), y **cuatro
terminales** abiertas en la carpeta del lab. Vas a necesitarlas.

> **Esto no repite la demostración de apertura.** Producir un mensaje, leerlo,
> volver a leerlo y ver que sigue ahí ya lo viste al inicio de la clase. Aquí
> arrancamos donde eso termina.

---

## 1 · EL PROBLEMA

El proceso que valida comprobantes recibidos empieza a quedarse corto. Llegan
más rápido de lo que se validan, la cola crece, y a las seis de la tarde hay
cuatro horas de atraso.

La solución que propone cualquiera es obvia: **levantemos un segundo proceso.**

Y ahí aparece la pregunta que nadie sabe contestar en la reunión:

> **Si levanto un segundo validador, ¿se reparten los comprobantes, o los dos
> validan los mismos?**

Las dos respuestas son plausibles y las consecuencias son opuestas:

- Si **se reparten**, el atraso se corta a la mitad y el problema está resuelto.
- Si **los dos leen todo**, cada comprobante se valida dos veces. En un proceso
  tributario eso no es «un poco más lento»: es un comprobante contabilizado dos
  veces, y el atraso además sigue igual.

Lo peor es que **por fuera se ven idénticos**. Dos procesos, la misma fuente de
datos, el mismo comando. Nada en la pantalla te dice cuál de los dos mundos
estás habitando — hasta que alguien revisa las cifras a fin de mes.

Y hay una tercera pregunta, la que va a decidir cuánto hardware se compra: **si
dos validadores cortan el atraso a la mitad, ¿ocho lo cortan a la octava
parte?**

---

## 2 · LA METÁFORA

Seguimos en **el restaurante**. El reparto que ya conoces:

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| El espiche donde se clavan las comandas del turno | El **segmento** |
| Las libretas de respaldo que copian cada comanda | Las **réplicas** |
| Quiénes marcaron tarjeta y están al día | El **ISR** |

Hasta hoy miramos siempre el lado del mozo: quién anota, dónde se guarda,
cuánto dura. **Hoy cruzamos a la cocina.**

| En el restaurante | En Kafka |
|---|---|
| **El cocinero** que va sacando comandas del espiche para prepararlas | El **consumidor** |
| **La brigada**: los cocineros que trabajan la misma carta y se reparten las comandas entre ellos | El **grupo de consumo** |

Y con eso, el problema del capítulo 1 se dice en una frase de restaurante:

> Si entra un segundo cocinero, **¿se reparte las comandas con el primero, o
> prepara todos los platos otra vez?**

La respuesta del restaurante es de sentido común, y es exactamente la de Kafka:
**depende de si los pusiste en la misma brigada.** Dos cocineros de la misma
brigada se reparten el espiche. Dos brigadas distintas —la cocina y el equipo de
auditoría que revisa cada comanda— **preparan cada una todas las comandas**,
porque están haciendo cosas distintas con ellas.

> 🍽 **La palabra que lo decide es `--group`.**

---

## 3 · CÓMO LO RESUELVE

> 👥 **Grupo de consumo** (*consumer group*)
> El conjunto de consumidores que Kafka trata como **un solo trabajo repartido
> entre varios**. Se declara con `--group <nombre>`. Kafka le asigna a cada
> miembro un puñado de particiones, y **cada mensaje lo lee exactamente un
> miembro del grupo**.

> 🧑‍🍳 **Consumidor**
> Un proceso que lee de un tópico. Puede estar en un grupo o no. Es el cocinero.

La mecánica completa cabe en tres reglas:

**1 · Kafka no reparte mensajes. Reparte particiones.**
El grupo no va mensaje por mensaje decidiendo a quién le toca. Le asigna a cada
miembro **particiones enteras**, y ese miembro se lleva todo lo que caiga ahí.
Es el jefe de turno diciendo «tú atiendes los sectores 1 y 2, tú el 3».

**2 · De ahí sale el techo, y es aritmética.**
Si Kafka reparte particiones, **nadie puede recibir media partición**. Un tópico
de 3 particiones admite como mucho **3 miembros con trabajo**. El cuarto entra
al grupo, aparece en los listados, consume memoria… y no recibe nada.

🔴 **Ese es el concepto que más cuesta del paradigma, y el que hoy hay que
llevarse:** el paralelismo de un tópico lo fijaste **el día que elegiste el
número de particiones**, y ese número —lo viste en el Lab 05— solo se puede
subir, nunca bajar.

**3 · Grupos distintos no se conocen entre sí.**
Cada grupo lleva su propia cuenta de por dónde va. Que el grupo de validación
haya leído un comprobante **no le quita nada** al grupo de reportes.

> 🔢 **Offset**
> El número de orden de un mensaje dentro de su partición. Kafka anota, **por
> grupo**, hasta qué offset leyó cada uno. Por eso dos grupos pueden ir por
> partes distintas del mismo tópico sin estorbarse.

---

## 4 · LA AFIRMACIÓN

> ▎ **Dos consumidores del mismo grupo se reparten el trabajo; dos grupos
> distintos leen todo cada uno.**

Y su consecuencia, que es la que cuesta plata:

> ▎ **Más consumidores que particiones no acelera nada. El sobrante mira.**

La afirmación se demuestra entera en los cuatro pasos de hoy. **La consecuencia
no**: verla en pantalla toma seis minutos y cuatro terminales, y está en
*Para profundizar B*, con su comando y su salida real.

---

## 5 · LOS PASOS

### Un aviso sobre los comandos de este lab

Los comandos de hoy **no usan los envoltorios de `kafka-cli/`**. El motivo es
concreto: `consume-as-group.sh` tiene el tópico fijo por dentro
(`novatech.fleet.events`, de 6 particiones) y no acepta `--topic`, y hoy
necesitamos uno de **3 particiones** para que el techo de *Para profundizar B*
se vea con cuatro terminales en vez de siete.

Así que van los comandos de Kafka **crudos**, con todo desglosado aquí mismo. No
es una pérdida: es exactamente lo que vas a escribir en el servidor de SUNAT.

🔴 **Y una diferencia importante con el Lab 05: los consumidores de hoy no
terminan solos.** Se quedan corriendo, esperando mensajes, hasta que tú los
cortes con **`Ctrl+C`**. Eso no es un error ni rompe nada — es lo que hace un
consumidor de verdad. Cortarlo con `Ctrl+C` es la forma correcta de sacarlo, y
es lo que se usa en *Para profundizar A* para que Kafka rehaga el reparto
delante de ti.

---

### Paso 1 · El tópico de tres sectores

**Se explica.**

> 🍰 **Partición**
> Cada uno de los pedazos en que se corta un tópico. Son los sectores del
> salón: existen para que el trabajo se pueda repartir.

Necesitamos un tópico con **3 particiones**. Tres es el número más chico que
permite ver un reparto desigual entre dos miembros (2 y 1) — y también el más
chico que deja ver, con una cuarta terminal, a un miembro sin nada que hacer.
Eso último está en *Para profundizar B*.

**Se ejecuta.**

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --create --topic novatech.validacion \
    --partitions 3 --replication-factor 3
```

| Parte del comando | Para qué está |
|---|---|
| `docker exec` | Ejecuta el comando **dentro** de un contenedor que ya corre. En el servidor de SUNAT esta parte no existe |
| `kafka-broker-1` | En cuál de los tres contenedores. Cualquiera sirve |
| `--bootstrap-server kafka-broker-1:29092` | Puerto **interno**: le hablamos desde dentro de la red de Docker. Desde tu máquina sería `localhost:9092` |
| `--create --topic` | Crear, y con qué nombre |
| `--partitions 3` | 🔴 El número del laboratorio. Es el techo de paralelismo que vamos a chocar |
| `--replication-factor 3` | Tres copias de cada partición, como el resto del clúster |

**Qué sale.**

```
Created topic novatech.validacion.
```

Verifícalo:

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.validacion
```

```
Topic: novatech.validacion	TopicId: yTP9_1oNQrmXOPD3bAtT8A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
```

**Cómo se lee.** `PartitionCount: 3`. Ese número es el protagonista de todo lo
que sigue. Anótalo.

---

### Paso 2 · Un cocinero solo

**Se explica.**

Lanzamos **un** consumidor dentro del grupo `validacion` y miramos qué le tocó.
Con un solo miembro, la respuesta no tiene misterio, pero fija la línea base.

**Se ejecuta.** En la **terminal A**:

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group validacion \
    --consumer-property client.id=cons-A \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

| Parámetro | Para qué está |
|---|---|
| `docker exec -it` | La `-i` mantiene la entrada abierta y la `-t` le da una terminal. **Juntas son las que hacen que `Ctrl+C` funcione** y que las líneas aparezcan a medida que llegan |
| `--topic novatech.validacion` | De qué tópico se lee |
| `--group validacion` | 🔴 **La palabra del laboratorio.** Te unes a ese grupo, y Kafka te asigna particiones en vez de darte todo |
| `--consumer-property client.id=cons-A` | Le pone nombre a este consumidor. Sin esto Kafka le inventa uno como `console-consumer-40f2d1ba…` y los listados se vuelven ilegibles |
| `--property print.partition=true` | Imprime **de qué partición** vino cada mensaje. Sin esto no se ve el reparto |
| `--property print.key=true` | Imprime también la clave |
| `--property key.separator='\|'` | Con qué carácter se separan clave y valor en pantalla |

**Qué sale.** Nada todavía: se queda esperando. **Eso es correcto — déjalo
corriendo.** Un `Warning` sobre `--property` deprecado también es normal; el
parámetro funciona.

Ahora, en la **terminal D** (la de trabajo), pregunta cómo quedó el grupo:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

| Parámetro | Para qué está |
|---|---|
| `kafka-consumer-groups` | La herramienta que responde por los grupos: quién está, qué le tocó, cuánto le falta |
| `--describe --group` | Detalle de ese grupo. Solo consulta |

**Qué sale.**

```
GROUP       TOPIC                PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG  CONSUMER-ID                                  HOST          CLIENT-ID
validacion  novatech.validacion  0          0               0               0    cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d  /172.26.0.4   cons-A
validacion  novatech.validacion  1          0               0               0    cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d  /172.26.0.4   cons-A
validacion  novatech.validacion  2          0               0               0    cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d  /172.26.0.4   cons-A
```

**Cómo se lee.** Una línea por partición, y en las tres el mismo `CLIENT-ID`:
**`cons-A` se quedó con las tres**. Es el único cocinero, así que atiende el
salón entero.

> 📉 **Lag**
> Cuántos mensajes escritos todavía **no** leyó un grupo. Es la resta
> `LOG-END-OFFSET − CURRENT-OFFSET`, la misma cuenta de los extremos del Lab 05.
> `LAG` creciendo es la señal de que el consumo va más lento que la producción —
> el atraso de las cuatro horas del capítulo 1, medido.

| Columna | Qué dice |
|---|---|
| `PARTITION` | Cada partición lleva su cuenta por separado |
| `CURRENT-OFFSET` | Hasta dónde leyó **el grupo** en esa partición |
| `LOG-END-OFFSET` | Hasta dónde escribió el productor |
| `LAG` | Lo que falta por leer, la resta de los dos anteriores. **Es el número que se vigila en producción** |
| `CONSUMER-ID` | Qué miembro atiende esa partición |
| `CLIENT-ID` | El nombre que le pusimos con `client.id`. Por eso se lee `cons-A` |

---

### Paso 3 · Entra el segundo cocinero

**Se explica.**

Este es el paso que contesta la pregunta de la reunión. Sumamos un segundo
consumidor **al mismo grupo**, escribimos seis comprobantes, y contamos cuántos
recibió cada uno.

**Se ejecuta.** En la **terminal B**, el mismo comando de antes cambiando solo
el `client.id`:

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group validacion \
    --consumer-property client.id=cons-B \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

🔴 **`--group validacion` es idéntico. Ahí está todo el experimento.**

Espera unos 20 segundos —Kafka tiene que rehacer el reparto— y en la **terminal
D** vuelve a preguntar:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

**Qué sale.**

```
GROUP       TOPIC                PARTITION  ...  CLIENT-ID
validacion  novatech.validacion  0          ...  cons-A
validacion  novatech.validacion  1          ...  cons-A
validacion  novatech.validacion  2          ...  cons-B
```

**Cómo se lee.** Las tres particiones siguen repartidas, pero ahora entre dos
nombres: **`cons-A` se quedó con la 0 y la 1, `cons-B` con la 2.** Nadie las
comparte.

> **A ti te puede tocar al revés** —`cons-B` con dos y `cons-A` con una—, y da
> igual. Lo que **no** puede pasar es que una partición aparezca dos veces.

Ahora los seis comprobantes. En la **terminal D**:

```bash
for i in 1 2 3 4 5 6; do
  echo "RUC-2010006660${i}:comprobante_${i}" | \
  docker exec -i kafka-broker-1 kafka-console-producer \
      --bootstrap-server kafka-broker-1:29092 \
      --topic novatech.validacion \
      --property parse.key=true --property key.separator=:
done
```

| Parte del comando | Para qué está |
|---|---|
| `for i in 1 2 3 4 5 6` | Seis comprobantes, uno por vuelta |
| `RUC-...${i}:comprobante_${i}` | Clave y valor separados por `:` |
| `docker exec -i` | Aquí **sin `-t`**: no queremos terminal, queremos meterle texto por la entrada |
| `--property parse.key=true` | 🔴 Que parta cada línea en clave y valor. **Sin esto la clave viaja dentro del valor** y todos los mensajes caen en la misma partición |
| `--property key.separator=:` | Por qué carácter la parte |

**Qué sale.** El productor no imprime nada por mensaje: su silencio es el éxito.
Lo interesante pasa en las terminales A y B.

**Cómo se lee.** Esto salió en una corrida real:

```
terminal A (cons-A)                              terminal B (cons-B)
Partition:1|RUC-20100066601|comprobante_1        Partition:2|RUC-20100066604|comprobante_4
Partition:0|RUC-20100066602|comprobante_2        Partition:2|RUC-20100066606|comprobante_6
Partition:1|RUC-20100066603|comprobante_3
Partition:0|RUC-20100066605|comprobante_5
```

**Cuatro y dos. Suman seis. Y ni uno solo aparece en las dos terminales.**

Esa es la primera mitad de la afirmación, y ya contesta la reunión del capítulo
1: **dos validadores del mismo grupo se reparten el trabajo, no lo duplican.**

🔴 **Ojo con el «cuatro y dos»: el reparto es de particiones, no de mensajes.**
`cons-A` tenía dos particiones y `cons-B` una, así que era esperable que a A le
tocara más. Y dentro de eso, en qué partición cae cada comprobante lo decide el
*hash* de su clave, que no reparte parejo con seis mensajes.

**Con seis mensajes, un reparto 6–0 es perfectamente posible.** No sería un
fallo: significaría que las seis claves cayeron en particiones del mismo
miembro. Lo que demuestra el laboratorio **no es que el reparto sea parejo**,
sino que **cada mensaje lo recibe uno solo**. La suma es 6 y los duplicados son
0: eso es lo que hay que mirar.

---

### Paso 4 · Otra brigada entra a la cocina

**Se explica.**

Falta la segunda mitad de la afirmación. Hasta aquí todos los consumidores
estaban en **el mismo grupo**. ¿Qué pasa con uno que declara un grupo distinto?

En SUNAT es el caso real: el equipo de **reportes** necesita leer **todos** los
comprobantes para su analítica, y no puede quitarle trabajo al de validación.

**Se ejecuta.** Los consumidores `cons-A` y `cons-B` **siguen corriendo**: no
los cortes. Usa la tercera terminal, la que todavía está libre:

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group reportes \
    --from-beginning \
    --consumer-property client.id=cons-Z \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

| Parámetro | Para qué está |
|---|---|
| `--group reportes` | 🔴 **Un nombre distinto. Eso es todo lo que cambia** |
| `--from-beginning` | Desde el principio del tópico, no solo lo que llegue de ahora en más. Un grupo nuevo no tiene posición guardada, así que hay que decirle desde dónde arrancar |

**Qué sale.**

```
Partition:2|RUC-20100066604|comprobante_4
Partition:2|RUC-20100066606|comprobante_6
Partition:0|RUC-20100066602|comprobante_2
Partition:0|RUC-20100066605|comprobante_5
Partition:1|RUC-20100066601|comprobante_1
Partition:1|RUC-20100066603|comprobante_3
```

**Cómo se lee.** **Los seis.** Todos los comprobantes del laboratorio, en una
sola terminal — incluidos los que el grupo `validacion` ya había leído y dado
por procesados. `cons-Z` está solo en su brigada, así que se lleva las tres
particiones y todo lo que hay dentro.

(**A ti el orden de las particiones te va a salir distinto.** Lo que no cambia
es que estén los seis y que salgan agrupados.)

(Salen agrupados por partición, no en orden de escritura: el consumidor recorre
una partición y después otra. **Kafka garantiza el orden dentro de cada
partición, nunca entre particiones.**)

Y lo que cierra el laboratorio, desde la terminal de trabajo:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

```
GROUP       TOPIC                PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG  ...  CLIENT-ID
validacion  novatech.validacion  0          2               2               0    ...  cons-A
validacion  novatech.validacion  1          2               2               0    ...  cons-A
validacion  novatech.validacion  2          2               2               0    ...  cons-B
```

**El grupo `validacion` no se movió ni un offset.** Que `reportes` haya leído
los seis mensajes **no le quitó nada**: sigue con `CURRENT-OFFSET` igual a
`LOG-END-OFFSET` en las tres particiones, y `LAG` en 0. **Cada brigada lleva su
propia cuenta.**

---

## 6 · QUÉ QUEDÓ

### Lo que se demostró

> ▎ **Dos consumidores del mismo grupo se reparten el trabajo; dos grupos
> distintos leen todo cada uno.**

| La afirmación decía | Y en pantalla se vio |
|---|---|
| **mismo grupo se reparten** | Paso 3: 4 mensajes en una terminal, 2 en la otra. Suman 6, **cero repetidos** |
| **grupos distintos leen todo** | Paso 4: `reportes` recibió **los 6**, y `validacion` no perdió nada |
| **y el sobrante mira** | 🔴 **Esto no se demostró en el recorrido de hoy.** Está en *Para profundizar B*, con la salida real: cuatro miembros y `#PARTITIONS` = 1, 1, 1 y **0** |

### Las cuatro reglas, para llevarse a SUNAT

**1 · `--group` es la palabra más importante del comando.**
Con el mismo nombre, los procesos colaboran. Con nombres distintos, duplican.
Y por fuera se ven idénticos: **el nombre del grupo es un dato de arquitectura
escondido en una línea de configuración.**

**2 · El paralelismo lo fijaste al crear el tópico.**
Kafka reparte particiones, no mensajes. Más consumidores que particiones es
plata gastada en procesos que miran. Y las particiones solo suben, nunca bajan.
*(Se ve en pantalla en* Para profundizar B*.)*

**3 · El rebalanceo es automático, y también es un costo.**
Nadie tiene que reasignar nada cuando un proceso se cae. Pero durante el
rebalanceo el grupo **para**: si tus procesos se reinician seguido, estás
pagando pausas que no ves. *(Se ve en pantalla en* Para profundizar A*.)*

**4 · `LAG` es el número que se vigila.**
Es la única señal temprana de que el consumo va más lento que la producción.
Cuando alguien pregunte «¿vamos atrasados?», es esto lo que se mira.

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue está fuera del recorrido de hoy **por tiempo, no por
dificultad**. Los dos primeros bloques —el rebalanceo y el techo— estaban en el
recorrido de clase hasta esta versión y salieron para que el laboratorio quepa
en 20 minutos de dictado. 🔴 **El techo (B) es el concepto que más cuesta del
paradigma: si vas a hacer uno solo de esta sección, haz ese.**

### A · El rebalanceo · se va un cocinero a mitad de turno

**Se explica.**

En producción los procesos se caen, se reinician y se despliegan. La pregunta
que importa es: **cuando uno se va, ¿sus particiones quedan huérfanas?**

> ♻️ **Rebalanceo**
> El reparto que Kafka rehace cada vez que un miembro entra o sale del grupo.
> Nadie lo dispara a mano: pasa solo.

**Se ejecuta.** En la **terminal B**, presiona **`Ctrl+C`**.

Eso es todo. El consumidor avisa que se va y termina. Espera unos 20 segundos y
pregunta desde la **terminal D**:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

**Qué sale.**

```
GROUP       TOPIC                PARTITION  ...  CLIENT-ID
validacion  novatech.validacion  0          ...  cons-A
validacion  novatech.validacion  1          ...  cons-A
validacion  novatech.validacion  2          ...  cons-A
```

**Cómo se lee.** `cons-B` ya no está, y **la partición 2 pasó a `cons-A`**.
Nadie ejecutó un comando de reasignación: Kafka rehízo el reparto solo, y el
trabajo del que se fue lo tomó el que quedó.

Compruébalo con tres comprobantes más, desde la **terminal D**:

```bash
for i in 7 8 9; do
  echo "RUC-2010006660${i}:comprobante_${i}" | \
  docker exec -i kafka-broker-1 kafka-console-producer \
      --bootstrap-server kafka-broker-1:29092 \
      --topic novatech.validacion \
      --property parse.key=true --property key.separator=:
done
```

En la terminal A aparecen **los tres**, incluidos los que antes habrían sido de
`cons-B`:

```
Partition:0|RUC-20100066607|comprobante_7
Partition:1|RUC-20100066608|comprobante_8
Partition:0|RUC-20100066609|comprobante_9
```

`cons-A` pasó de 4 mensajes a 7. **Ninguno se perdió.**

---

### B · El techo · cuatro cocineros, tres sectores

🔴 **Este es el paso que hay que entender. Si algo se te olvida del lab, que no
sea esto.**

**Se explica.**

Volvemos a la pregunta que decide el presupuesto: si dos validadores cortaron el
atraso a la mitad, **¿ocho lo cortan a la octava parte?**

Kafka reparte **particiones**, no mensajes. Y hay tres.

**Se ejecuta.** Levanta consumidores en las **terminales B y C**, y uno más
—`cons-D`— en una cuarta. Los cuatro con `--group validacion`, cambiando solo
el `client.id`:

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group validacion \
    --consumer-property client.id=cons-D \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

Espera el rebalanceo (~30 s) y pide **la lista de miembros**, que es una vista
distinta de la de antes:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion --members
```

| Parámetro | Para qué está |
|---|---|
| `--members` | En vez de una línea por partición, **una línea por miembro**, con cuántas particiones tiene cada uno. Es la vista que hace visible al que no tiene ninguna |

**Qué sale.**

```
GROUP       CONSUMER-ID                                  HOST          CLIENT-ID  #PARTITIONS
validacion  cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d  /172.26.0.4   cons-A     1
validacion  cons-B-fa50017e-0d15-4d17-b609-a02bb91c44d7  /172.26.0.4   cons-B     1
validacion  cons-D-eb9b8358-75cb-49c1-9027-d06cf5e0113a  /172.26.0.4   cons-D     0
validacion  cons-C-f22ef424-fa6b-4b4b-aec0-92d6723ca1bb  /172.26.0.4   cons-C     1
```

**Cómo se lee.** Cuatro miembros. La columna `#PARTITIONS` dice `1`, `1`, `1`
y **`0`**.

**`cons-D` está en el grupo, está vivo, está conectado — y no va a recibir un
solo mensaje.** Su terminal se va a quedar en blanco para siempre. No está
roto: no hay una cuarta partición que darle.

> **A ti el ocioso puede ser otro** (`cons-B`, `cons-C`, el que sea). Lo que no
> cambia es que **haya exactamente uno con `0`**.

Y ahora la respuesta a la pregunta del presupuesto:

> ▎ **Con 3 particiones, el cuarto validador no acelera nada. Ni el quinto, ni
> el octavo.** Pagas por ellos, aparecen en los tableros, y miran.

🔴 **Y aquí se cierra el Lab 05 con este:** el número de particiones **se
decide al crear el tópico** y solo se puede **subir**, nunca bajar. O sea: **el
día que creas un tópico estás fijando cuánto vas a poder paralelizar su consumo
para siempre.** Esa es la razón real por la que la elección de particiones es la
decisión más difícil de deshacer de Kafka — y por la que en el Lab 05 los
tópicos de alto volumen llevaban 12 particiones y no 3.

---

### C · Consumir sin grupo

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion --from-beginning
```

**Lo que hay que mirar:** sin `--group`, Kafka le inventa uno
(`console-consumer-XXXXX`) y ese consumidor recibe **todo**. Es el caso del Paso
4 llevado al extremo: cada terminal es su propia brigada.

### D · Rebobinar un grupo

```bash
kafka-cli/reset-group.sh reportes
kafka-cli/describe-group.sh reportes
```

**Lo que hay que mirar:** el `CURRENT-OFFSET` vuelve a 0 y el `LAG` salta al
total. **El grupo tiene que estar sin miembros activos** — tras un `Ctrl+C` hay
que esperar a que la sesión caduque, o el reset falla con *«Assignments can only
be reset if the group is inactive»*.

### E · Las claves y el particionado

```bash
kafka-cli/produce-event.sh --key NVT-1001 "evento alfa"
```

**Lo que hay que mirar:** todos los mensajes con la misma clave caen **siempre
en la misma partición**, y por lo tanto los lee **siempre el mismo miembro** del
grupo, en orden. Es la herramienta para garantizar que los movimientos de un
mismo contribuyente se procesen ordenados.

### F · Los tópicos y grupos del lab original

`novatech.fleet.events` (6 particiones) y los envoltorios de `kafka-cli/`
(`consume-as-group.sh`, `describe-group.sh`, `list-groups.sh`) siguen
funcionando sobre ese tópico. Con 6 particiones, para ver un miembro ocioso
harían falta **siete** consumidores.

### G · El reporte del lab

`plantillas/reporte-entregable.md`, con las respuestas de referencia en
`soluciones/reporte-resuelto.md`.

---

## Cierre

Corta con `Ctrl+C` todos los consumidores que sigan abiertos. Si terminas por
hoy:

```bash
bin/stop-lab.sh
```

**Lo que te llevas:** cuando alguien proponga «levantemos más procesos para ir
más rápido», ahora sabes cuáles son las dos preguntas que hay que hacer antes de
aprobar el gasto — **¿van en el mismo grupo?** y **¿cuántas particiones tiene el
tópico?**
