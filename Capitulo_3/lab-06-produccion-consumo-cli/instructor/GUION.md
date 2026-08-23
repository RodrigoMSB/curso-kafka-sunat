# Lab 06 · Guion de dictado

> **Para el relator, no para el alumno.** Qué decir, qué preguntar antes de cada
> comando, qué va a salir y qué hacer cuando no sale.

🔴 **El techo es 20 minutos de dictado.** Tres sesiones de 180 minutos para once
laboratorios dan 45 minutos por lab, y en esos 45 entra también la demostración
de apertura, las preguntas y el cambio de un lab a otro. Este guion está
recortado a ese techo **botando bloques enteros**, no acortando párrafos: lo que
quedó, quedó completo.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH OPERATIVO» | 10 min antes |
| Los 3 brokers sanos | `bin/90-test-lab.sh` aprueba | 10 min antes |
| El tópico **no** existe | `kafka-topics --list` no muestra `novatech.validacion` | 10 min antes |
| **Sin consumidores zombis** | Ver abajo. 🔴 Es el que arruina la clase | 5 min antes |
| Cuatro terminales abiertas | En la carpeta del lab, grandes y visibles | 5 min antes |
| 🔴 **El tópico creado y `cons-A` corriendo** | Ver *El montaje*. **Esto antes se hacía en clase** | 5 min antes |

### 🔴 Los zombis, que es el problema real de este lab

Un consumidor que quedó de un ensayo **sigue en el grupo** y se lleva una
partición. Con tres particiones, un zombi te deja el reparto irreconocible y la
demostración no se entiende.

```bash
# ¿hay consumidores vivos dentro del contenedor?
docker exec kafka-broker-1 sh -c 'ps -ef | grep -c "[C]onsoleConsumer"'

# matarlos a todos
docker exec kafka-broker-1 sh -c 'pkill -9 -f ConsoleConsumer'

# y borrar los grupos (falla si todavía hay miembros: espera ~45 s y repite)
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 --delete --group validacion
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 --delete --group reportes
```

⚠️ **`pkill -f "console-consumer"` NO funciona.** Esa cadena no aparece en la
línea de comandos del proceso: hay que buscar `ConsoleConsumer`, que es la clase
Java. Medido — con el patrón equivocado `ps` devuelve 0 mientras hay once
consumidores vivos.

### 🔴 El montaje, que ya no se hace delante de la clase

Crear el tópico y levantar el primer consumidor ocupaban 5 minutos de dictado
tecleando y abriendo terminales. **Ese tiempo no enseña nada**, así que se hace
antes de que entre la clase. La sala entra con la terminal A ya corriendo y en
pantalla.

En la **terminal D** (la de trabajo):

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --create --topic novatech.validacion \
    --partitions 3 --replication-factor 3
```

Y en la **terminal A**, que queda corriendo:

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group validacion \
    --consumer-property client.id=cons-A \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

🔴 **Deja escrito en la terminal B el mismo comando con `client.id=cons-B`, sin
ejecutarlo.** En el Bloque 3 tienes que poder mostrarlo y lanzarlo sin teclear:
el punto pedagógico es que los dos comandos son idénticos salvo el nombre.

**Di en clase que el tópico y el primer consumidor ya estaban levantados**, y
que los dos comandos están en la guía. Un alumno que no lo oye cree que el lab
empieza en el aire.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 5 |
| 2 · El cocinero solo | minuto 5 | `describe --group` con un solo miembro | 2 |
| 3 · El reparto | minuto 7 | Entra `cons-B`, seis comprobantes, las dos terminales | 7 |
| 4 · La otra brigada | minuto 14 | `cons-Z` con `--group reportes` | 4 |
| 5 · Cierre | minuto 18 | Nada. Se habla | 2 |
| **Total de dictado** | | | **20** |

El montaje —crear el tópico y levantar `cons-A`— ya no está en la cuenta: se
hace antes de que entre la clase.

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo |
|---|---|---|
| **Ejecución pura** | **96 s** | 🟢 **Medido**, recorrido recortado completo (los 4 pasos), 22-ago-2026 |
| **Esperas de rebalanceo** | **~70 s** de esos 96 | 🟢 Medido. Son los 20–30 s tras cada cambio de miembros del grupo |
| **Dictado** | **20 min** | 🟡 **Estimado, no medido.** 🔴 Es el que manda: el techo de 20 aplica aquí |

🟡 **La estimación de dictado sigue siendo una estimación.** Los Bloques 1, 3 y
4 llevan los mismos minutos que ya tenían antes del recorte. Los otros dos son
números nuevos:

- El **Bloque 2 son 2 y no 5** porque el montaje —crear el tópico, abrir
  terminales, levantar `cons-A`— salió de la clase. Lo que queda es leer una
  tabla de cuatro líneas.
- El **Bloque 5 son 2 y no 4** porque ya no se leen las cuatro reglas una por
  una: se lee la primera y se nombra el techo.

🔴 **Esos dos son los números frágiles de la tabla**, y el Bloque 5 es el más
apretado de los dos: son dos minutos de hablar sin una sola pausa. Si se estira,
lo que se bota es la pregunta con la que se van — no la frase del techo, que es
la que evita que se lleven la conclusión al revés.

🔴 **El margen es cero.** Y los ~70 segundos de rebalanceo no son huecos que se
puedan llenar con otro bloque: son de veinte y treinta segundos, no de cuatro
minutos como la espera del Lab 05. Se llenan diciendo qué está pasando.

### Lo que se botó de este guion

| Bloque botado | Minutos que devolvió | Dónde quedó |
|---|---|---|
| El montaje: crear el tópico y levantar `cons-A` en pantalla | 3 | *Antes de la clase*, aquí arriba |
| El Paso 4 · el rebalanceo al matar un consumidor | 4 | Guía, *Para profundizar A* |
| El Paso 5 · el techo · cuatro cocineros, tres sectores | 6 | Guía, *Para profundizar B* |
| Las cuatro reglas leídas una por una | 2 | Guía, sección 6. En clase se lee **la primera** |

🔴 **El techo es el que más duele botar**, y el guion anterior decía «no se
recorta nunca». Con 20 minutos no cabe: son 6 minutos, y con ellos el lab queda
en 26. Lo que **sí** se dice, en una frase, es que existe y dónde está — está
escrito en el Bloque 5. **No se explica a medias**: un alumno que se lleva medio
techo se lleva la conclusión al revés.

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 5 min

**En pantalla no hay nada**, salvo la terminal A esperando. Este bloque es solo
palabra.

### Qué decir

> «El proceso que valida comprobantes se está quedando corto. Llegan más rápido
> de lo que se validan y a las seis de la tarde hay cuatro horas de atraso.
>
> Alguien en la reunión dice lo obvio: *levantemos un segundo validador*. Y ahí
> viene la pregunta que nadie sabe contestar: **si levanto un segundo proceso,
> ¿se reparten los comprobantes o los dos validan los mismos?**
>
> Piénsenlo, porque las dos consecuencias son opuestas. Si se reparten, el
> atraso se corta a la mitad. Si los dos leen todo, cada comprobante se valida
> dos veces —en un proceso tributario eso es un comprobante contabilizado dos
> veces— y además el atraso sigue igual.
>
> Y lo peor: **por fuera se ven idénticos.** Dos procesos, el mismo tópico, el
> mismo comando. Nada en la pantalla les dice en cuál de los dos mundos están.»

### La metáfora, ya redactada

> «Seguimos en el restaurante, pero hoy cruzamos a la cocina. Hasta ahora
> miramos siempre al mozo: quién anota, dónde se guarda, cuánto dura.
>
> El **cocinero** es el consumidor: el que va sacando comandas del espiche para
> prepararlas. Y la **brigada** es el grupo de consumo: los cocineros que
> trabajan la misma carta y se reparten las comandas entre ellos.
>
> Con eso el problema se dice solo: si entra un segundo cocinero, ¿se reparte
> las comandas o prepara todos los platos otra vez? Y la respuesta del
> restaurante es la de Kafka: **depende de si los pusiste en la misma
> brigada.**»

### 🔮 Predicción para la clase

> «Antes de tocar nada, votemos. Voy a levantar dos consumidores con el mismo
> comando y a escribir seis comprobantes. ¿Cuántos mensajes va a ver cada uno?
> Levanten la mano los que dicen seis y seis.»

**Guarda el conteo de manos.** Es el que se retoma en el Bloque 3.

---

## Bloque 2 · minuto 5 · El cocinero solo — 2 min

**En pantalla:** el `describe --group` del grupo `validacion`, con un solo
miembro. Es la línea base contra la que se compara todo lo demás.

Di primero de dónde salió lo que ya está corriendo:

> «Antes de que entraran dejé dos cosas hechas, y están las dos en la guía: creé
> un tópico llamado `novatech.validacion` con **tres particiones**, y levanté un
> consumidor en esa terminal, dentro de un grupo llamado `validacion`. No hizo
> nada todavía: está esperando.»

### 🔮 Predicción

> «Tres particiones. ¿Cuántos procesos como máximo van a poder trabajar en
> paralelo sobre ese tópico? Guárdense el número.»

Casi nadie contesta tres. **La respuesta va en el cierre**, y hoy no se
demuestra en pantalla — se dice y se manda al repositorio.

### Se ejecuta, en la terminal D

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

**Qué sale.**

```
GROUP       TOPIC                PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG  CONSUMER-ID                                  HOST         CLIENT-ID
validacion  novatech.validacion  0          0               0               0    cons-A-d20687de-61a5-4c6a-a35f-312a72502706  /172.27.0.4  cons-A
validacion  novatech.validacion  1          0               0               0    cons-A-d20687de-61a5-4c6a-a35f-312a72502706  /172.27.0.4  cons-A
validacion  novatech.validacion  2          0               0               0    cons-A-d20687de-61a5-4c6a-a35f-312a72502706  /172.27.0.4  cons-A
```

### Cómo leerlo

Con **un solo consumidor**, las tres líneas tienen el mismo `CLIENT-ID`:

> «Tres líneas, una por partición, y en las tres dice `cons-A`. Es el único
> cocinero: atiende el salón entero.
>
> Y fíjense en la columna `LAG`: cero. Ese es el número que se vigila en
> producción, y es el que en el problema del principio valía cuatro horas.»

🔴 **Explica el `client.id` en una frase.** Sin él, Kafka pone
`console-consumer-40f2d1ba-9ba2-…` y la tabla se vuelve ilegible en pantalla
compartida. Con él dice `cons-A`. Es una comodidad, no un requisito.

---

## Bloque 3 · minuto 7 · El reparto — 7 min

**En pantalla:** entra `cons-B`, el `describe --group` cambia, y los seis
comprobantes se reparten entre las dos terminales.

🔴 **Es el corazón del lab. No lo apures.** Es el único bloque que no se recorta
por ningún motivo.

### Antes de lanzar el segundo consumidor

> «Miren el comando de la terminal B. Es **el mismo** de la A. Lo único que
> cambia es el nombre que le pongo para poder distinguirlos en la tabla. El
> `--group validacion` va **idéntico**. Ahí está todo el experimento.»

Lánzalo y espera los ~25 segundos del rebalanceo. **Ese hueco se llena diciendo
lo que está pasando**, no con silencio:

> «Kafka está rehaciendo el reparto ahora mismo. Nadie ejecutó una
> reasignación: entró un miembro al grupo y el grupo se reorganiza solo. Tarda
> unos veinte segundos y durante ese rato el grupo entero está detenido.»

### Cuando salga el describe

```
GROUP       TOPIC                PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG  CONSUMER-ID                                  HOST         CLIENT-ID
validacion  novatech.validacion  0          0               0               0    cons-A-d20687de-61a5-4c6a-a35f-312a72502706  /172.27.0.4  cons-A
validacion  novatech.validacion  1          0               0               0    cons-A-d20687de-61a5-4c6a-a35f-312a72502706  /172.27.0.4  cons-A
validacion  novatech.validacion  2          0               0               0    cons-B-da5ac6b7-bda9-4331-9b5d-083345c5a647  /172.27.0.4  cons-B
```

> «Antes las tres particiones eran de `cons-A`. Ahora la 0 y la 1 son de
> `cons-A` y la 2 es de `cons-B`. **Kafka rehízo el reparto solo**, nadie
> ejecutó nada.
>
> Y miren lo que no pasó: **ninguna partición aparece dos veces.**»

### El momento del laboratorio

Produce los seis desde la terminal D:

```bash
for i in 1 2 3 4 5 6; do
  echo "RUC-2010006660${i}:comprobante_${i}" | \
  docker exec -i kafka-broker-1 kafka-console-producer \
      --bootstrap-server kafka-broker-1:29092 \
      --topic novatech.validacion \
      --property parse.key=true --property key.separator=:
done
```

Y deja que miren las dos terminales. En la corrida medida salió así:

```
terminal A (cons-A)                          terminal B (cons-B)
Partition:1|RUC-20100066601|comprobante_1    Partition:2|RUC-20100066604|comprobante_4
Partition:0|RUC-20100066602|comprobante_2    Partition:2|RUC-20100066606|comprobante_6
Partition:1|RUC-20100066603|comprobante_3
Partition:0|RUC-20100066605|comprobante_5
```

> «Cuatro aquí, dos allá. Suman seis. Y ni uno solo está en las dos pantallas.
>
> Vuelvan a la votación del principio: los que dijeron seis y seis, esa es la
> otra respuesta posible, y la vamos a ver en el último paso. Pero dentro del
> mismo grupo, **el trabajo se reparte**.»

### 🔴 La honestidad sobre el 4–2, que hay que decir sí o sí

> «No es cuatro y dos porque Kafka reparta desparejo a propósito. Es que
> **Kafka reparte particiones, no mensajes**: `cons-A` tenía dos particiones y
> `cons-B` una. Y encima, en qué partición cae cada comprobante lo decide el
> hash de su clave, que con seis mensajes no reparte parejo.
>
> Les puede salir tres y tres, o cinco y uno, o **seis y cero**. Si les sale
> seis y cero **no está roto**: significa que las seis claves cayeron en las
> particiones del mismo cocinero. Lo que demuestra este lab no es que el reparto
> sea parejo — es que **cada mensaje lo recibe uno solo**. Miren la suma y miren
> los repetidos.»

**Si en clase sale 6–0**, úsalo: es mejor material que el reparto bonito.
Pregunta *«¿está roto?»*, deja que duden, y muestra el `describe --group`: las
particiones están repartidas, lo que no se repartió fueron las claves.

### ⚠ Errores probables

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Los 6 llegan a la misma terminal **y** el `describe` muestra un solo `CLIENT-ID` | El segundo consumidor no entró al grupo (typo en `--group`) | Revisar que el `--group` sea idéntico |
| Aparece un tercer `CLIENT-ID` que no lanzaste | Un zombi de un ensayo previo | Ver *Los zombis* al inicio. 🔴 Es lo más común |
| Los 6 caen todos en una partición | Se fue `--property parse.key=true` y la clave viajó dentro del valor | Repetir el `for` completo |
| El `describe` no muestra a nadie | No pasaron los ~20 s del rebalanceo | Esperar y repetir |

---

## Bloque 4 · minuto 14 · La otra brigada — 4 min

**En pantalla:** una terminal nueva con `--group reportes`, que recibe **los
seis** comprobantes, y el `describe` de `validacion`, que no se movió.

### Qué decir

> «Hasta aquí todos estaban en el mismo grupo. Ahora cambio **una sola palabra**:
> `--group reportes` en vez de `--group validacion`.
>
> En SUNAT es el caso real: el equipo de reportes necesita leer **todos** los
> comprobantes para su analítica, y no puede quitarle trabajo al de validación.»

### Se ejecuta, en una terminal libre

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

```
Partition:2|RUC-20100066604|comprobante_4
Partition:2|RUC-20100066606|comprobante_6
Partition:0|RUC-20100066602|comprobante_2
Partition:0|RUC-20100066605|comprobante_5
Partition:1|RUC-20100066601|comprobante_1
Partition:1|RUC-20100066603|comprobante_3
```

Cuando aparezcan los seis:

> «Los seis. Todos, en una sola terminal, incluidos los que el grupo de
> validación ya había procesado y dado por cerrados. **Una palabra distinta y el
> comportamiento es el opuesto.**
>
> Y salen agrupados por partición, no en orden de escritura. Anoten eso porque
> se pregunta siempre: **Kafka garantiza el orden dentro de cada partición,
> nunca entre particiones.**»

Y el cierre, con el `describe` del otro grupo:

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

> «`validacion` no se movió ni un offset. Que `reportes` haya leído los seis
> **no le quitó nada**. Cada brigada lleva su propia cuenta.»

🔴 **El `--from-beginning` no es decorativo y hay que decirlo.** Un grupo nuevo
no tiene posición guardada; sin ese flag, `reportes` arrancaría desde el final y
la terminal se quedaría vacía, que es exactamente el susto que no queremos.

---

## Bloque 5 · minuto 18 · Cierre — 2 min

**No se leen las cuatro reglas una por una.** Se lee **la primera**, que es la
que contesta la pregunta con la que empezó la clase:

> «`--group` es la palabra más importante del comando, y es la que nadie mira en
> una revisión de código. Con el mismo nombre colaboran; con nombres distintos
> duplican. **Es una decisión de arquitectura escondida en una línea de
> configuración**, y el día que alguien la cambia sin darse cuenta, los
> comprobantes se procesan dos veces y nadie se entera hasta fin de mes.»

### 🔴 El techo, que hoy no se demostró y hay que nombrar igual

> «Y falta una que no alcanzamos a ver en pantalla, así que se las digo y está
> en el repositorio con el comando: **Kafka reparte particiones, no mensajes.**
> Ese tópico tiene tres. Si levantan un cuarto validador en el mismo grupo, el
> cuarto **no recibe nada**: está vivo, aparece en el listado, y mira. Lo pagan
> igual. Y el número de particiones se fija al crear el tópico y solo se puede
> subir, nunca bajar.
>
> Está en la guía, en *Para profundizar B*, con la salida real: cuatro miembros
> y la columna de particiones diciendo uno, uno, uno y **cero**.»

### La pregunta con la que se van

> «Cuando alguien proponga *levantemos más procesos para ir más rápido*, ¿cuáles
> son las dos preguntas que hacen antes de aprobar el gasto?»

*(¿Van en el mismo grupo? ¿Cuántas particiones tiene el tópico?)*

### 🔴 La frase que hay que decir en voz alta

> «Y una cosa: **este laboratorio tiene más operaciones que las que vimos hoy.
> Están todas en el repositorio, con la clase grabada.** El rebalanceo cuando se
> cae un proceso, el techo de particiones, rebobinar un grupo, consumir sin
> grupo. Está en la guía, sección *Para profundizar*, con el comando escrito y
> la salida real.»

Sin esa frase, el alumno que abra la guía después va a creer que se saltó algo.

---

## Si el tiempo se acorta

Ya no hay bloque de reserva: este guion **es** el recorte. Si aun así te vas de
20 minutos, se bota en este orden y **se reporta**:

1. El Bloque 4 se enuncia y se muestra en Kafbat UI sin levantar el consumidor.
   Devuelve ~3 min, y deja la segunda mitad de la afirmación sin demostrar.
2. El Bloque 1 se bota completo y se entra directo al `describe --group`.
   Devuelve 5 min y es la peor salida posible.

**El Bloque 3 no se recorta nunca.**

## Limpieza al terminar

```bash
docker exec kafka-broker-1 sh -c 'pkill -INT -f ConsoleConsumer'
```

El clúster puede quedar arriba. Si no, `bin/stop-lab.sh`.
