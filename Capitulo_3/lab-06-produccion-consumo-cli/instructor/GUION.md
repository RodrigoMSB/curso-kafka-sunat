# Lab 06 · Guion de dictado

> **Para el relator, no para el alumno.** Qué decir, qué preguntar antes de cada
> comando, qué va a salir y qué hacer cuando no sale.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH OPERATIVO» | 10 min antes |
| Los 3 brokers sanos | `bin/90-test-lab.sh` aprueba | 10 min antes |
| El tópico **no** existe | `kafka-topics --list` no muestra `novatech.validacion` | 10 min antes |
| **Sin consumidores zombis** | Ver abajo. 🔴 Es el que arruina la clase | 5 min antes |
| Cuatro terminales abiertas | En la carpeta del lab, grandes y visibles | 5 min antes |

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

---

## Presupuesto de tiempo

| Bloque | Minutos | Qué lo hace largo |
|---|---|---|
| 1 · El problema y la metáfora | 5 | Se habla |
| 2 · Pasos 1 y 2 · el tópico y el primer consumidor | 5 | Abrir terminales y leer la tabla |
| 3 · Paso 3 · el reparto | 7 | 🔴 El corazón del lab |
| 4 · Paso 4 · el rebalanceo | 4 | Un `Ctrl+C` y esperar |
| 5 · Paso 5 · el techo | 6 | 🔴 No se recorta |
| 6 · Paso 6 · el otro grupo | 4 | Un comando |
| 7 · Cierre y las cuatro reglas | 4 | Se habla |
| **Total de clase** | **~35** | 🟡 estimado |

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo |
|---|---|---|
| **Ejecución pura** | **189 s** | 🟢 **Medido**, arnés completo (`soluciones/SALIDAS.md`) |
| **Esperas de rebalanceo** | ~95 s de esos 189 | 🟢 Medido. Son los 20–30 s tras cada cambio de miembros |
| **Dictado** | **~35 min** | 🟡 **Estimado, no medido.** 🔴 Es el que manda: el techo de 40 aplica aquí |

🟡 **La estimación de dictado es una estimación**, igual que en el Lab 05. El
primer dictado la convierte en dato. Margen: 5 minutos sobre 40.

🔴 **Si hay que recortar**, se recorta el Paso 6 (se enuncia y se muestra en
Kafbat UI, sin levantar el consumidor): devuelve ~3 min. **El Paso 5 no se
recorta nunca.**

---

## Bloque 1 · El problema y la metáfora — 5 min

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

## Bloque 2 · Pasos 1 y 2 — 5 min

### 🔮 Predicción

> «Voy a crear un tópico de tres particiones. ¿Cuántos procesos como máximo van
> a poder trabajar en paralelo sobre él? Guárdense el número.»

Casi nadie contesta tres a esta altura. **Es la respuesta del Bloque 5.**

### Cómo leer el `describe --group`

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

## Bloque 3 · Paso 3 · el reparto — 7 min

🔴 **Es el corazón del lab. No lo apures.**

### Antes de lanzar el segundo consumidor

> «Miren el comando de la terminal B. Es **el mismo** de la A. Lo único que
> cambia es el nombre que le pongo para poder distinguirlos en la tabla. El
> `--group validacion` va **idéntico**. Ahí está todo el experimento.»

### Cuando salga el describe

> «Antes las tres particiones eran de `cons-A`. Ahora la 0 y la 1 son de `cons-A`
> y la 2 es de `cons-B`. **Kafka rehízo el reparto solo**, nadie ejecutó nada.
>
> Y miren lo que no pasó: **ninguna partición aparece dos veces.**»

### El momento del laboratorio

Produce los seis y deja que miren las dos terminales.

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

## Bloque 4 · Paso 4 · el rebalanceo — 4 min

### 🔮 Predicción

> «Voy a matar a `cons-B` con Ctrl+C. ¿Qué pasa con la partición que tenía? ¿Se
> queda sin atender?»

### Qué decir

> «`Ctrl+C`. Eso es todo. Y esperamos veinte segundos.
>
> Miren: `cons-B` ya no está, y **la partición 2 ahora es de `cons-A`**. Nadie
> ejecutó un comando de reasignación. Kafka rehízo el reparto solo.
>
> Y esto es lo que pasa en producción cuando un pod se reinicia: el trabajo del
> que se fue lo toman los que quedan, sin que nadie intervenga.»

Produce los tres siguientes y muestra que llegan **todos** a la terminal A.

> «Ninguno se perdió. Y el que estaba a mitad de camino tampoco: por eso Kafka
> anota el offset por grupo.»

**Menciona el costo, en una frase:**

> «El rebalanceo es gratis de operar pero no es gratis de correr: mientras dura,
> **el grupo entero para**. Si sus procesos se reinician cada dos minutos, están
> pagando pausas que no ven en ningún tablero.»

---

## Bloque 5 · Paso 5 · el techo — 6 min

🔴 **Este bloque no se recorta. Es el concepto que más cuesta del paradigma.**

### 🔮 Predicción, y aquí sí insiste

> «Tenemos tres particiones. Voy a levantar **cuatro** consumidores en el mismo
> grupo. ¿Qué le va a tocar al cuarto?»

Deja que contesten. Van a decir «un poco de todo», «se turnan», «la cuarta
parte». **Nadie dice nada, y esa es la respuesta.**

### Cuando salga el `--members`

> «Cuatro miembros. Miren la última columna: uno, uno, uno… y **cero**.
>
> `cons-D` está en el grupo, está vivo, está conectado, aparece en el listado. Y
> **no va a recibir un solo mensaje en toda su vida.** Su terminal se va a
> quedar en blanco. No está roto: no hay una cuarta partición que darle.»

Y ahora la frase que hay que dejar caer despacio:

> «Kafka reparte **particiones**, no mensajes. Nadie puede recibir media
> partición. Entonces: con tres particiones, el cuarto validador **no acelera
> nada**. Ni el quinto, ni el octavo. Los pagan, aparecen en el tablero, y
> miran.
>
> Y ahora enlacen con el lab de ayer: **el número de particiones se decide al
> crear el tópico, y solo se puede subir, nunca bajar.** O sea que el día que
> crean un tópico están fijando cuánto van a poder paralelizar su consumo **para
> siempre**. Por eso les insistí en el Lab 05 con que la elección de particiones
> es la decisión más difícil de deshacer de Kafka.»

**Cierra con la pregunta de negocio:**

> «Si mañana el atraso se duplica, ¿qué piden: más servidores, o más
> particiones?»

### ⚠ Errores probables

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Hay **más de un** miembro con `0` | Zombis: hay más de cuatro consumidores vivos | Contar los miembros. Si son más de 4, limpiar zombis y rehacer |
| El `#PARTITIONS` sale vacío | La terminal es angosta y corta la columna | Ensanchar, o `... --members \| cat` |
| Nadie tiene `0` | Se levantaron solo 3 consumidores | Contar las terminales |

---

## Bloque 6 · Paso 6 · la otra brigada — 4 min

### Qué decir

> «Hasta aquí todos estaban en el mismo grupo. Ahora cambio **una sola palabra**:
> `--group reportes` en vez de `--group validacion`.
>
> En SUNAT es el caso real: el equipo de reportes necesita leer **todos** los
> comprobantes para su analítica, y no puede quitarle trabajo al de validación.»

Cuando aparezcan los nueve:

> «Los nueve. Todos, en una sola terminal, incluidos los que el grupo de
> validación ya había procesado. **Una palabra distinta y el comportamiento es
> el opuesto.**
>
> Y salen agrupados por partición, no en orden de escritura. Anoten eso porque
> se pregunta siempre: **Kafka garantiza el orden dentro de cada partición,
> nunca entre particiones.**»

Y el cierre, con el `describe` del otro grupo:

> «`validacion` no se movió ni un offset. Que `reportes` haya leído los nueve
> **no le quitó nada**. Cada brigada lleva su propia cuenta.»

---

## Bloque 7 · Cierre — 4 min

Lee las cuatro reglas de la guía. La que hay que subrayar es la **primera**:

> «`--group` es la palabra más importante del comando, y es la que nadie mira en
> una revisión de código. Con el mismo nombre colaboran; con nombres distintos
> duplican. **Es una decisión de arquitectura escondida en una línea de
> configuración**, y el día que alguien la cambia sin darse cuenta, los
> comprobantes se procesan dos veces y nadie se entera hasta fin de mes.»

Y la pregunta con la que se van:

> «Cuando alguien proponga *levantemos más procesos para ir más rápido*, ¿cuáles
> son las dos preguntas que hacen antes de aprobar el gasto?»

*(¿Van en el mismo grupo? ¿Cuántas particiones tiene el tópico?)*

---

## Limpieza al terminar

```bash
docker exec kafka-broker-1 sh -c 'pkill -INT -f ConsoleConsumer'
```

El clúster puede quedar arriba. Si no, `bin/stop-lab.sh`.
