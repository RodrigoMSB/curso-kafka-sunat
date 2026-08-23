# Lab 07 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado**, como en los labs 05 y 06. Este guion
está recortado a ese techo **botando bloques enteros**, no acortando párrafos.

🔴 **Y este lab tiene una trampa propia: los números que salgan en tu clase no
van a ser los de este guion.** Es un laboratorio de mediciones sobre una máquina
compartida. Lo que se demuestra no son los valores, es la **relación** entre
ellos. Abajo está qué hacer si te sale al revés.

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
| 3 · Cambiar un parámetro y medir | minuto 9 | `perf-test.sh --linger-ms 10`, dos veces | 3 |
| 4 · Un par más, la tabla y los `acks` | minuto 12 | El tercer par, y el análisis. **Aquí está el lab** | 6 |
| 5 · Cierre | minuto 18 | Nada. Se habla | 2 |
| **Total de dictado** | | | **20** |

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo |
|---|---|---|
| **Ejecución pura** | **9 s** | 🟢 **Medido**, las seis corridas del recorrido, 23-ago-2026 |
| **Espera** | **0 s** | 🟢 Este laboratorio **no tiene ninguna**. Cada comando devuelve en dos segundos |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido. 🔴 Es el que manda |

🔴 **La ausencia de espera es lo que hay que administrar aquí, y es al revés que
en el Lab 05.** Allá había cuatro minutos de hueco que llenar; aquí los seis
comandos se acaban en nueve segundos y te quedan **trece minutos de pura
explicación**. Si vas rápido, en el minuto ocho te quedaste sin laboratorio y con
la clase mirando. **El Bloque 4 es el laboratorio**, y hay que llegar ahí con
tiempo, no con prisa.

🟡 **La estimación de dictado es una estimación.** El primer dictado la
convierte en dato.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| Los tres niveles de `acks` **ejecutados** | Guía, *Para profundizar A*, con las nueve corridas medidas |
| `batch.size` | Guía, *Para profundizar B* |
| Las pruebas de compresión | Guía, *Para profundizar C* |
| La combinación de parámetros | Guía, *Para profundizar D* |
| El lado del consumidor | Guía, *Para profundizar E* |
| Los retos de particionado | Guía, *Para profundizar F* |

Los `acks` **sí se explican**, y no al final: van **dentro del análisis del
Bloque 4**, que es donde el alumno ya tiene una tabla delante y entiende por qué
un número puede no significar nada.

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 5 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «Viene la temporada alta y alguien pregunta cuánto aguanta el clúster. Se
> corre una prueba de carga y salen **ciento catorce mil mensajes por segundo**.
> Ese número entra en una lámina.
>
> El equipo aplica un cambio de tuning que la documentación recomienda, vuelve a
> correr la prueba, y salen **ciento once mil**. Conclusión de la reunión: el
> cambio empeoró el clúster, vuélvanlo atrás.
>
> Las dos mediciones son reales. Las dos salieron de este laboratorio y las van
> a ver en pantalla en diez minutos. Y la conclusión está **al revés**: ese
> cambio, medido bien, mejora el throughput **todas** las veces.
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
> Y tiene tres, nada más. Cuánto se queda esperando a que caigan más comandas
> antes de arrancar — eso es `linger.ms`, y es el de hoy. Cuántas comandas le
> caben en la bandeja — eso es `batch.size`. Y a quién le espera el visto bueno
> — eso es `acks`.
>
> Un ayudante con `linger.ms` en cero sale disparado apenas tiene algo en la
> mano. Si lo dejo esperar diez milisegundos, sale con la bandeja más llena y
> hace menos viajes.»

Y ahora la frase que sostiene el laboratorio entero:

> «Ahora piensen esto: si yo cronometro **un** viaje del ayudante, ¿sé cuánto
> tarda el servicio? No. Ese viaje pudo tocar el ascensor libre o la cocina
> llena. Para decir algo hay que cronometrar varios — y hay que cronometrar los
> dos escenarios **el mismo día, uno detrás del otro**.»

### 🔮 Predicción para la clase

> «Voy a correr la prueba de carga dos veces seguidas, sin cambiar
> absolutamente nada. Mismo comando, mismo tópico, dos segundos de diferencia.
> Levanten la mano los que creen que va a dar el mismo número.»

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
50000 records sent, 114155.251142 records/sec (21.77 MB/sec), 60.98 ms avg latency, 216.00 ms max latency, 67 ms 50th, 91 ms 95th, 94 ms 99th, 96 ms 99.9th.
50000 records sent, 104166.666667 records/sec (19.87 MB/sec), 62.30 ms avg latency, 244.00 ms max latency, 73 ms 50th, 89 ms 95th, 94 ms 99th, 96 ms 99.9th.
```

### Qué decir

> «Mismo comando. Mismo tópico. Nada tocado. Y el throughput se movió casi un
> **nueve por ciento**.
>
> Eso que acaban de ver es **el ruido de esta máquina**, y ya está medido.
> Anótenlo, porque lo vamos a usar en tres minutos: a partir de ahora, cualquier
> mejora que yo les anuncie que sea más chica que esto, no es una mejora. Es la
> corrida siguiente.»

🔴 **Escribe ese porcentaje en la pizarra.** El Bloque 4 lo usa como vara, y si
no está a la vista el golpe se pierde.

🔴 **No pases de aquí sin que hayan visto que los dos números no coinciden.** Si
por casualidad te salieron casi iguales, **corre una tercera**.

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

> «Voy a subir `linger.ms` de cero a diez: el ayudante, en vez de salir
> disparado, se queda hasta diez milisegundos juntando comandas. ¿El throughput
> sube o baja? ¿Y la latencia?»

Van a decir que el throughput sube y la latencia empeora. **Guarda las dos
respuestas**: la primera se confirma en el Bloque 4 y la segunda **no**.

### Se ejecuta

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

Dos veces, igual que antes.

```
50000 records sent, 118764.845606 records/sec (22.65 MB/sec), 56.61 ms avg latency, 224.00 ms max latency, 63 ms 50th, 75 ms 95th, 80 ms 99th, 82 ms 99.9th.
50000 records sent, 117096.018735 records/sec (22.33 MB/sec), 65.78 ms avg latency, 214.00 ms max latency, 75 ms 50th, 89 ms 95th, 92 ms 99th, 94 ms 99.9th.
```

### 🔴 Lo que hay que decir aquí y no en el bloque siguiente

> «Fíjense en lo único que cambió en el comando: **un flag**. `batch.size` sigue
> en dieciséis kilobytes, `acks` sigue en `all`, la compresión sigue apagada.
>
> Si yo hubiera movido tres cosas y esto mejorara, tendría una mejora que **no
> sé a quién atribuirle** — y el día que una de las tres me haga daño en
> producción, no voy a saber cuál sacar.»

**No leas los números todavía.** Se leen en el Bloque 4. Si los comentas aquí, el
bloque 4 pierde el golpe.

---

## Bloque 4 · minuto 12 · Un par más, la tabla y los `acks` — 6 min

🔴 **Este bloque es el laboratorio.** Los tres anteriores fueron la excusa para
llegar aquí. No lo apures y no lo recortes.

### Primero, la trampa: parece que ya está

Escribe solo la columna del throughput, con las cuatro corridas que ya hay:

| | records/sec |
|---|---|
| Base 1 | **114 155** |
| Base 2 | 104 167 |
| `linger` 1 | 118 765 |
| `linger` 2 | 117 096 |

> «Las dos tuneadas le ganan a las dos base. ¿Listo, concluimos que funciona?»

Deja que digan que sí. Y entonces:

> «Miren la distancia entre la **mejor base**, ciento catorce mil, y la **peor
> tuneada**, ciento diecisiete mil. Son un dos coma seis por ciento.
>
> Y ahora miren la pizarra: el ruido que medimos sin tocar nada era del **nueve**.
> **La diferencia que quiero celebrar es tres veces más chica que el ruido que ya
> medí.** Con estas cuatro corridas no puedo concluir nada.»

### Se ejecuta: un par más, uno detrás del otro

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

```
50000 records sent, 106157.112527 records/sec (20.25 MB/sec), 60.67 ms avg latency, 237.00 ms max latency, 67 ms 50th, 82 ms 95th, 85 ms 99th, 86 ms 99.9th.
50000 records sent, 111607.142857 records/sec (21.29 MB/sec), 60.97 ms avg latency, 223.00 ms max latency, 66 ms 50th, 81 ms 95th, 88 ms 99th, 92 ms 99.9th.
```

### Lectura uno · los rangos sueltos engañan en las dos direcciones

> «Ahora tengo seis corridas. Miren los rangos sueltos: la base va de ciento
> cuatro a ciento catorce mil; la tuneada, de ciento once a ciento diecinueve.
> **Se pisan.**
>
> Y fíjense en esto: mi **mejor** corrida base, ciento catorce mil, le gana a mi
> **peor** corrida tuneada, ciento once mil. El que corriera solo esas dos se
> iría diciendo que el tuning empeoró el clúster — **que es exactamente la
> reunión con la que empezamos la clase.**
>
> Y el que corriera la base dos contra la tuneada uno se iría diciendo que
> mejoró un catorce por ciento. Las dos conclusiones salen de datos reales y las
> dos están mal.»

### Lectura dos · pareado sí se puede afirmar

Ahora la tabla que sí sirve, cada par medido uno detrás del otro:

| Par | Base | `linger.ms=10` | Diferencia |
|---|---|---|---|
| 1 | 114 155 | 118 765 | **+4,0 %** |
| 2 | 104 167 | 117 096 | **+12,4 %** |
| 3 | 106 157 | 111 607 | **+5,1 %** |

> «Tres de tres. No hay ningún par donde el tuneado pierda.
>
> **Eso** sí lo puedo afirmar. Y miren lo que hizo falta para poder decirlo: no
> una métrica más fina, no un comando más listo. **Repetir.**»

🔴 **La conclusión no es «`linger.ms` da un 12 % más».** Ese 12 % es un par. Es
«ganó los tres pares, con mejoras de entre 4 % y 12 %» — más fea, y la única
defendible. Dilo con esas palabras.

**Y ahora vuelve a la predicción del Bloque 3**, donde dijeron que la latencia
empeoraría:

> «Latencia media: sesenta y uno, cincuenta y siete, sesenta y dos, sesenta y
> seis, sesenta y uno, sesenta y uno. Ahí no pasa nada: el tuneado gana un par y
> pierde dos. **`linger.ms` movió el throughput y no movió la latencia**, y eso
> también hay que decirlo, aunque el libro sugiera otra cosa.»

### Lectura tres · el promedio esconde los casos malos

Deja de comparar corridas y quédate en **una sola línea**, la primera:

> «Promedio: sesenta y un milisegundos. p99: noventa y cuatro. Máximo:
> **doscientos dieciséis**. Misma corrida, mismos cincuenta mil mensajes.
>
> Hubo un mensaje que tardó tres veces y media el promedio. Si su tablero muestra
> el promedio, ese mensaje **no aparece en ninguna parte** — y es justo el que el
> usuario nota, porque es el que se quedó esperando.
>
> Por eso el rendimiento se mira en percentiles. El promedio les dice cómo le fue
> al sistema. El p99 les dice cómo le fue **al peor de cada cien usuarios**. Los
> acuerdos de nivel de servicio se escriben con percentiles, nunca con
> promedios.»

### Y los `acks`, que se explican aquí y no se ejecutan

Es el tercer parámetro del ayudante, y el momento de nombrarlo es este: la clase
ya tiene una tabla delante y ya sabe que un número puede no significar nada.

> «Falta el tercero: a quién le espera el visto bueno. `acks=0` es no esperar a
> nadie. `acks=1` es esperar al mozo. `acks=all` es esperar al mozo **y** a las
> libretas de respaldo.
>
> El manual dice que cero es el más rápido y `all` el más lento. **Yo los medí en
> este clúster, tres corridas de cada uno, y no es así**: los tres rangos se
> pisan enteros, y el mejor número de toda la tabla lo dio `acks=1`, que ni
> siquiera es el nivel más laxo. Están las nueve corridas en la guía.
>
> ¿Por qué? Porque aquí los tres brokers viven **en la misma máquina**. Esperar a
> las réplicas no cruza una red de verdad, así que no cuesta casi nada. En un
> clúster real, con los brokers en servidores distintos y switches en el medio,
> la diferencia aparece.
>
> Y esa es la frase que se llevan: **un banco de pruebas que no se parece a
> producción mide el banco de pruebas.** Lo que `acks` decide de verdad no es la
> velocidad — es qué se pierde cuando un broker se cae. Eso se elige por riesgo,
> no por benchmark.»

### 🔴 Si en tu clase los números salen distintos

Van a salir distintos. Lo que se demuestra es la **relación**, y esta es la guía
de rescate:

| Lo que te salió | Qué decir |
|---|---|
| El tuneado gana los tres pares | Es lo esperado. Sigue el guion |
| El tuneado pierde uno de los tres | **Mejor material todavía.** «Dos de tres no alcanza. ¿Qué haríamos en serio? Más pares.» Corre uno más en vivo: cuesta cuatro segundos |
| El tuneado pierde dos o tres | **Dilo, no lo tapes.** «En esta máquina, hoy, no se distingue. Eso es un resultado, no un fracaso — y es más honesto que la lámina de la reunión del principio» |
| Todo sale parejísimo | Máquina descargada. La lección de fondo —repetir antes de concluir— se sostiene igual |

**Nunca fuerces la conclusión que dice el guion si tus números dicen otra cosa.**
Este es el único lab del curso donde eso puede pasar, y donde admitirlo en voz
alta *es* la clase.

---

## Bloque 5 · minuto 18 · Cierre — 2 min

### Las cuatro reglas

Léelas de la guía, sección **6 · QUÉ QUEDÓ**. La que hay que subrayar es la
**tercera**:

> «Compara pares, no rangos, y mide los dos el mismo día. Lo que se afirma es
> **cuántos pares ganó**, no cuánto ganó el mejor par. Y comparar la corrida de
> hoy contra un número anotado el mes pasado es comparar ruido: la máquina, la
> carga y hasta lo que había abierto cambiaron.»

### La pregunta con la que se van

> «La próxima vez que alguien les muestre un número de rendimiento, ¿cuál es la
> primera pregunta?»

*(¿Comparado con qué, y cuántas veces lo mediste?)*

### 🔴 La frase que hay que decir en voz alta

> «Y una cosa: **este laboratorio tiene más mediciones que las que vimos hoy.
> Están todas en el repositorio, con la clase grabada.** Los `acks` medidos,
> `batch.size`, la compresión, combinar parámetros, el lado del consumidor y el
> particionado. Está en la guía, sección *Para profundizar*, con el comando
> escrito y la salida real.»

El clúster queda arriba para el Lab 08.

---

## Si el tiempo se acorta

Este guion **es** el recorte, y no hay bloque de reserva. Si aun así te vas de
20 minutos, se bota en este orden y **se reporta**:

1. El Bloque 5 se reduce a la pregunta final y a la frase del repositorio.
   Devuelve ~1,5 min.
2. El bloque de los `acks` dentro del Bloque 4 se enuncia en dos frases —que no
   se distinguen aquí y por qué— sin la tabla de riesgo. Devuelve ~1,5 min.
3. La lectura tres —el promedio y la cola— se enuncia en una frase y se manda a
   leer. Devuelve ~2 min. **Es lo último que se toca.**

**Los bloques 2 y 3, y las lecturas uno y dos del Bloque 4, no se recortan**: son
la demostración entera.

## Si sobra tiempo

Te va a sobrar: la máquina se toma nueve segundos. Antes de improvisar, lo que
más rinde es **correr un cuarto y un quinto par** delante de la clase y agregarlos
a la tabla. Cada par cuesta cuatro segundos y cada uno refuerza el punto.

Después de eso, *Para profundizar B* (`batch.size`) es lo que mejor engancha,
porque mueve **la latencia y no el throughput** — justo al revés que el del
recorrido, y es el mejor argumento contra tocar los dos juntos.
