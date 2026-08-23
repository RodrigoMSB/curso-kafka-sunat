# Lab 07 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado**, como en los labs 05 y 06. Este guion
está recortado a ese techo **botando bloques enteros**, no acortando párrafos.

🔴 **Y este lab tiene una trampa propia: los números que salgan en tu clase no
van a ser los de este guion.** Es un laboratorio de mediciones sobre una máquina
compartida. Lo que se demuestra no son los valores, es la **relación** entre
ellos, y esa sí se repite. Abajo está qué hacer si te sale al revés.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH OPERATIVO» | 10 min antes |
| Los 3 brokers sanos | `bin/90-test-lab.sh` → 3 verificaciones OK | 10 min antes |
| El tópico de bench existe | `novatech.tuning.bench`, lo crea `start-lab.sh` | 10 min antes |
| 🔴 **La JVM ya arrancó una vez** | Ver abajo | 5 min antes |

### 🔴 El calentamiento, que decide si el Paso 1 se entiende

**Corre una vez el perf-test antes de que entre la clase, y descarta el
resultado:**

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

La primera corrida contra un clúster recién levantado arranca la JVM del
contenedor en frío y sale **muchísimo** peor que las siguientes. Medido: en una
tanda en frío la latencia media de la línea base fue de 196 ms; en la misma
máquina, ya caliente, fue de 27 ms.

Si esa corrida en frío es la primera que ve la clase, el Paso 1 deja de mostrar
«ruido» y pasa a mostrar un escalón gigante que se explica solo por el arranque.
**El laboratorio se entiende peor, no mejor.**

🔴 **Cierra todo lo demás que esté corriendo en tu máquina.** Un navegador con
cuarenta pestañas mete más ruido que el que vas a demostrar.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 5 |
| 2 · Medir dos veces sin tocar nada | minuto 5 | `perf-test.sh` dos veces, mismo comando | 4 |
| 3 · Cambiar un parámetro y medir | minuto 9 | `perf-test.sh --batch-size 65536`, dos veces | 3 |
| 4 · La tabla y las tres lecturas | minuto 12 | Las cuatro salidas juntas. **Aquí está el lab** | 6 |
| 5 · Los `acks` y el cierre | minuto 18 | Nada. Se habla sobre la tabla | 2 |
| **Total de dictado** | | | **20** |

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo |
|---|---|---|
| **Ejecución pura** | **7 s** | 🟢 **Medido**, las cuatro corridas del recorrido, 23-ago-2026 |
| **Espera** | **0 s** | 🟢 Este laboratorio **no tiene ninguna**. Cada comando devuelve en dos segundos |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido. 🔴 Es el que manda |

🔴 **La ausencia de espera es lo que hay que administrar aquí, y es al revés que
en el Lab 05.** Allá había cuatro minutos de hueco que llenar; aquí los cuatro
comandos se acaban en siete segundos y te quedan **trece minutos de pura
explicación**. Si vas rápido, en el minuto ocho te quedaste sin laboratorio y
con la clase mirando. **El Bloque 4 es el laboratorio**, y hay que llegar ahí
con tiempo, no con prisa.

🟡 **La estimación de dictado es una estimación.** El primer dictado la
convierte en dato.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| Los tres niveles de `acks` **ejecutados** | Guía, *Para profundizar A*, con las nueve corridas medidas |
| Las pruebas de compresión | Guía, *Para profundizar B* |
| La combinación de parámetros | Guía, *Para profundizar C* |
| El lado del consumidor | Guía, *Para profundizar D* |
| Los retos de particionado | Guía, *Para profundizar E* |

Los `acks` **sí se explican** en el Bloque 5, sobre la tabla y sin ejecutar. Hay
una razón medida para no correrlos, y está en el Bloque 5.

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 5 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «Viene la temporada alta y alguien pregunta cuánto aguanta el clúster. Se
> corre una prueba de carga, sale **ochenta y siete mil mensajes por segundo**,
> y ese número entra en una lámina.
>
> A la semana siguiente el equipo sube un parámetro de tuning, vuelve a correr
> la prueba, y salen **ochenta mil**. Conclusión de la reunión: el tuning empeoró
> el clúster, vuélvanlo atrás.
>
> Las dos mediciones son reales. Las dos salieron de este laboratorio, las van a
> ver en pantalla en diez minutos. Y la conclusión está **al revés**.
>
> No porque alguien mintiera. Porque nadie en esa reunión sabía **cuánto se
> mueve ese número cuando no se cambia nada**.»

### La metáfora, ya redactada

> «Seguimos en el restaurante. El mozo es el broker, el tipo de comanda es el
> tópico, los sectores del salón son las particiones, el cocinero es el
> consumidor y la brigada es su grupo.
>
> Hoy entra una pieza nueva, del otro lado del salón: **el ayudante**, el que
> recoge las comandas de las mesas y se las lleva al mozo. **Ese es el
> productor**, y todo lo que vamos a tunear hoy son decisiones suyas.
>
> Y tiene tres, nada más. Cuántas comandas le caben en la bandeja — eso es
> `batch.size`. Cuánto se queda esperando a que caigan más antes de arrancar —
> eso es `linger.ms`. Y a quién le espera el visto bueno — eso es `acks`.
>
> Un ayudante que sale corriendo con una sola comanda hace cien viajes. Uno que
> espera a llenar la bandeja hace diez.»

Y ahora la frase que sostiene el laboratorio entero:

> «Ahora piensen esto: si yo cronometro **un** viaje del ayudante, ¿sé cuánto
> tarda el servicio? No. Ese viaje pudo tocar el ascensor libre o la cocina
> llena. Para decir algo hay que cronometrar varios — y hay que cronometrar los
> dos escenarios **el mismo día**.»

### 🔮 Predicción para la clase

> «Voy a correr la prueba de carga dos veces seguidas, sin cambiar
> absolutamente nada. Mismo comando, mismo tópico, treinta segundos de
> diferencia. Levanten la mano los que creen que va a dar el mismo número.»

Casi nadie levanta la mano — pero **casi todos operan como si diera el mismo
número**. Vale la pena decirlo así de literal.

---

## Bloque 2 · minuto 5 · Medir dos veces sin tocar nada — 4 min

**En pantalla:** el mismo comando, dos veces.

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

Córrelo, espera los dos segundos, y **córrelo otra vez sin decir nada**. Deja que
la clase vea que es el mismo comando.

**Qué salió en la corrida medida:**

```
50000 records sent, 87260.034904 records/sec (16.64 MB/sec), 66.51 ms avg latency, 256.00 ms max latency, 74 ms 50th, 104 ms 95th, 114 ms 99th, 118 ms 99.9th.
50000 records sent, 82508.250825 records/sec (15.74 MB/sec), 106.91 ms avg latency, 262.00 ms max latency, 118 ms 50th, 141 ms 95th, 146 ms 99th, 150 ms 99.9th.
```

### Qué decir

> «Mismo comando. Mismo tópico. Nada tocado. Y el throughput se movió un cinco
> por ciento y la latencia media un **sesenta y uno**.
>
> Eso que acaban de ver es **el ruido de esta máquina**, y ya está medido. A
> partir de ahora, cualquier mejora que yo les anuncie que sea más chica que
> esto, no es una mejora: es la corrida siguiente.»

🔴 **No pases de aquí sin que hayan visto que los dos números no coinciden.** Si
por casualidad te salieron casi iguales, **corre una tercera**. Es el cimiento
del bloque 4 y sin él el resto no se sostiene.

### ⚠ Errores probables en este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| La primera corrida es muchísimo peor que la segunda | La JVM arrancó en frío | Es lo que evita el calentamiento de *Antes de la clase*. Dilo, descarta esa corrida y corre dos más |
| Las dos corridas salen casi idénticas | Máquina muy descargada | Corre una tercera, o sube a `100000`. El ruido aparece |
| `Option --producer-props has been deprecated` | Kafka 8.x avisa del cambio de nombre | Ignorarlo en voz alta, para que nadie crea que falló |

---

## Bloque 3 · minuto 9 · Cambiar un parámetro. Uno solo — 3 min

**En pantalla:** el mismo comando con un flag más, dos veces.

### 🔮 Predicción antes de ejecutar

> «Voy a subir `batch.size` de dieciséis kilobytes a sesenta y cuatro: la
> bandeja del ayudante, cuatro veces más grande. ¿El throughput sube o baja?»

Van a decir que sube. **Guarda esa respuesta**, porque el Bloque 4 se apoya en
ella.

### Se ejecuta

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536
```

Dos veces, igual que antes.

```
50000 records sent, 130208.333333 records/sec (24.84 MB/sec), 17.29 ms avg latency, 223.00 ms max latency, 16 ms 50th, 32 ms 95th, 40 ms 99th, 43 ms 99.9th.
50000 records sent, 80000.000000 records/sec (15.26 MB/sec), 42.89 ms avg latency, 315.00 ms max latency, 44 ms 50th, 79 ms 95th, 85 ms 99th, 86 ms 99.9th.
```

### 🔴 Lo que hay que decir aquí y no en el bloque siguiente

> «Fíjense en lo único que cambió en el comando: **un flag**. `linger.ms` sigue
> en cero, `acks` sigue en `all`, la compresión sigue apagada.
>
> Si yo hubiera movido tres cosas y esto mejorara, tendría una mejora que **no
> sé a quién atribuirle** — y el día que una de las tres me haga daño en
> producción, no voy a saber cuál sacar.»

**No leas los números todavía.** Se leen en el Bloque 4, sobre la tabla. Si los
comentas aquí, el bloque 4 pierde el golpe.

---

## Bloque 4 · minuto 12 · La tabla y las tres lecturas — 6 min

🔴 **Este bloque es el laboratorio.** Los tres anteriores fueron la excusa para
llegar aquí. No lo apures y no lo recortes.

Escribe la tabla en pantalla, con las cuatro corridas:

| | records/sec | Latencia media | Latencia p99 | Latencia máx |
|---|---|---|---|---|
| Base 1 | 87 260 | 66,51 ms | 114 ms | 256 ms |
| Base 2 | 82 508 | 106,91 ms | 146 ms | 262 ms |
| 64 KB 1 | **130 208** | 17,29 ms | 40 ms | 223 ms |
| 64 KB 2 | **80 000** | 42,89 ms | 85 ms | 315 ms |

### Lectura uno · el throughput no separa nada

> «Miren la primera columna. La mejor corrida tuneada da ciento treinta mil:
> parece un cuarenta y nueve por ciento de mejora. Y la peor corrida tuneada da
> **ochenta mil**, que es menos que las dos corridas base.
>
> O sea que con estos mismos datos yo puedo escribir dos láminas. Una dice que
> el tuning mejoró un cuarenta y nueve por ciento. La otra dice que empeoró un
> tres. **Las dos son datos reales y las dos están mal.**»

Ahí es donde se vuelve a la predicción del Bloque 3: dijeron que el throughput
subía. **La respuesta honesta es que con estos datos no se puede saber.**

### Lectura dos · la latencia media sí separa

> «Ahora la segunda columna. La peor corrida tuneada, cuarenta y dos milisegundos,
> sigue siendo mejor que la mejor corrida base, sesenta y seis. **Ahí no hay
> solape.** Esa mejora sí la puedo afirmar.
>
> Y tiene sentido con el ayudante: menos viajes con más comandas cada uno
> significa que cada comanda espera menos en la bandeja.»

🔴 **La conclusión del lab no es «`batch.size` sube el throughput».** Es que con
estos datos eso **no se puede afirmar**, y lo que sí se puede afirmar es que
baja la latencia. Dilo con esas palabras.

### Lectura tres · el promedio esconde los casos malos

Ahora deja de comparar corridas y quédate en **una sola línea**, la tercera:

> «Promedio: diecisiete milisegundos. p99: cuarenta. Máximo: **doscientos
> veintitrés**. Misma corrida, mismos cincuenta mil mensajes.
>
> El promedio dice diecisiete. Pero hubo un mensaje que tardó doscientos
> veintitrés, **trece veces el promedio**. Si su tablero muestra el promedio, ese
> mensaje **no aparece en ninguna parte** — y es justo el que el usuario nota,
> porque es el que se quedó esperando.»

Y el cierre de la lectura:

> «Por eso el rendimiento se mira en percentiles. El promedio les dice cómo le
> fue al sistema. El p99 les dice cómo le fue **al peor de cada cien usuarios**.
> Los acuerdos de nivel de servicio se escriben con percentiles, nunca con
> promedios.»

### 🔴 Si en tu clase los números salen distintos

Van a salir distintos. Lo que se demuestra es la **relación**, y esta es la guía
de rescate según lo que te toque:

| Lo que te salió | Qué decir |
|---|---|
| El throughput tuneado ganó en las dos corridas | «Miren igual el solape con la corrida base. ¿La distancia es más grande que el ruido que medimos en el Paso 1?» Casi nunca lo es |
| La latencia tuneada **no** separó | Súbelo a `100000` mensajes y repite las dos configuraciones. Si sigue sin separar, **dilo**: es un hallazgo, no un fracaso |
| Todo salió parejísimo | Es una máquina descargada. La lección de fondo —repetir antes de concluir— se sostiene igual |

**Nunca fuerces la conclusión que dice el guion si tus números dicen otra
cosa.** Este es el único lab del curso donde eso puede pasar, y donde admitirlo
en voz alta *es* la clase.

---

## Bloque 5 · minuto 18 · Los `acks` y el cierre — 2 min

**En pantalla no hay nada nuevo.** Se habla sobre la tabla que ya está.

### Los tres niveles de `acks`, explicados y no ejecutados

> «Falta el tercer parámetro del ayudante: a quién le espera el visto bueno.
>
> `acks=0` es no esperar a nadie: suelta la bandeja y se va. `acks=1` es esperar
> a que el mozo la reciba. `acks=all` es esperar a que el mozo **y** las libretas
> de respaldo la tengan.
>
> El libro dice que cero es el más rápido y `all` el más lento. **Y yo los medí
> en este clúster y no es así**: los tres dan lo mismo, y los rangos se pisan
> enteros. Está en la guía con las nueve corridas.
>
> ¿Por qué? Porque aquí los tres brokers viven en la misma máquina. Esperar a
> las réplicas no cruza una red de verdad, así que no cuesta casi nada.
>
> Y esa es la lección que se llevan: **un banco de pruebas que no se parece a
> producción mide el banco de pruebas.** Lo que `acks` cambia de verdad no es la
> velocidad — es qué se pierde cuando un broker se cae.»

### La pregunta con la que se van

> «La próxima vez que alguien les muestre un número de rendimiento, ¿cuál es la
> primera pregunta?»

*(¿Comparado con qué, y cuántas veces lo mediste?)*

### 🔴 La frase que hay que decir en voz alta

> «Y una cosa: **este laboratorio tiene más mediciones que las que vimos hoy.
> Están todas en el repositorio, con la clase grabada.** Los `acks` medidos, la
> compresión, combinar parámetros, el lado del consumidor y el particionado.
> Está en la guía, sección *Para profundizar*, con el comando escrito y la
> salida real.»

El clúster queda arriba para el Lab 08.

---

## Si el tiempo se acorta

Este guion **es** el recorte, y no hay bloque de reserva. Si aun así te vas de
20 minutos, se bota en este orden y **se reporta**:

1. El Bloque 5 se reduce a la pregunta final y a la frase del repositorio.
   Devuelve ~1,5 min.
2. La lectura tres del Bloque 4 —el promedio y la cola— se enuncia en una frase
   y se manda a leer. Devuelve ~2 min. **Es lo último que se toca.**

**Los bloques 2, 3 y 4 no se recortan**: son la demostración entera.

## Si sobra tiempo

Te va a sobrar: la máquina se toma siete segundos. Antes de improvisar, lo que
más rinde es **correr una tercera y una cuarta corrida de la línea base** delante
de la clase y agregarlas a la tabla. Cada corrida nueva refuerza el punto y
cuesta dos segundos.

Después de eso, *Para profundizar A* (los `acks` medidos) es lo que mejor
engancha, porque el resultado contradice lo que todos esperaban.
