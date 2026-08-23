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

**Corre el perf-test varias veces antes de que entre la clase, y descarta todos
los resultados:**

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

La primera corrida contra un clúster recién levantado arranca la JVM del
contenedor en frío y sale **muchísimo** peor que las siguientes. Medido: en una
tanda en frío la latencia media de la línea base fue de 196 ms; en la misma
máquina, ya caliente, fue de 27 ms.

🔴 **Y una sola corrida de calentamiento no basta.** En la tanda con la que se
grabó este lab, el p50 tardó **seis corridas** en dejar de bajar: 199 → 111 → 73
→ 84 → 123 → 62 ms. Corre seis y mira que el número deje de mejorar solo. Si
arrancas la clase todavía en la rampa, el Paso 1 te va a dar un ruido enorme que
no es ruido: es la máquina calentando.

Si esa corrida en frío es la primera que ve la clase, el Paso 1 deja de mostrar
«ruido» y pasa a mostrar un escalón gigante que se explica solo por el arranque.
**El laboratorio se entiende peor, no mejor.**

🔴 **Cierra todo lo demás que esté corriendo en tu máquina.** Un navegador con
cuarenta pestañas mete más ruido que el que vas a demostrar.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 4 |
| 2 · Medir dos veces sin tocar nada | minuto 4 | `perf-test.sh` dos veces, mismo comando | 4 |
| 3 · Cambiar un parámetro y medir | minuto 8 | `perf-test.sh --linger-ms 10`, dos veces | 3 |
| 4 · Un par más, la tabla y los `acks` | minuto 11 | El tercer par, y el análisis. **Aquí está el lab** | 7 |
| 5 · Cierre | minuto 18 | Nada. Se habla | 2 |
| **Total de dictado** | | | **20** |

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo |
|---|---|---|
| **Ejecución pura** | **10 s** | 🟢 **Medido**, las seis corridas del recorrido, 23-ago-2026 |
| **Espera** | **0 s** | 🟢 Este laboratorio **no tiene ninguna**. Cada comando devuelve en dos segundos |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido. 🔴 Es el que manda |

🔴 **La ausencia de espera es lo que hay que administrar aquí, y es al revés que
en el Lab 05.** Allá había cuatro minutos de hueco que llenar; aquí los seis
comandos se acaban en diez segundos y te quedan **trece minutos de pura
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

## Bloque 1 · minuto 0 · El problema y la metáfora — 4 min

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
> a ver en pantalla en diez minutos. Y la conclusión **no se sostiene** — pero
> ojo, tampoco se sostendría la contraria. Si los números hubieran salido al
> revés y la reunión hubiera decidido «el cambio funciona, déjenlo», habrían
> estado **igual de equivocados**.
>
> No porque alguien mintiera. Porque nadie en esa reunión sabía **cuánto se
> mueve ese número cuando no se cambia nada**. Y sin eso, ninguna de las dos
> conclusiones vale.
>
> Hoy vamos a medir eso primero. Y les adelanto el final, porque no es el que
> esperan: **vamos a terminar sin poder afirmar que el cambio sirva.** Ese va a
> ser el resultado, y es el resultado que casi nadie les muestra.»

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

## Bloque 2 · minuto 4 · Medir dos veces sin tocar nada — 4 min

**En pantalla:** el mismo comando, dos veces.

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

Córrelo, espera los dos segundos, y **córrelo otra vez sin decir nada**. Deja que
la clase vea que es el mismo comando.

**Qué salió en la corrida medida:**

```
50000 records sent, 114942.528736 records/sec (21.92 MB/sec), 60.03 ms avg latency, 197.00 ms max latency, 64 ms 50th, 92 ms 95th, 97 ms 99th, 101 ms 99.9th.
50000 records sent, 96899.224806 records/sec (18.48 MB/sec), 74.98 ms avg latency, 234.00 ms max latency, 80 ms 50th, 122 ms 95th, 132 ms 99th, 140 ms 99.9th.
```

### Qué decir

> «Mismo comando. Mismo tópico. Nada tocado. Y el throughput se movió un
> **quince coma siete por ciento**.
>
> Eso que acaban de ver es **el ruido de esta máquina**, y ya está medido.
> Anótenlo, porque lo vamos a usar en siete minutos: a partir de ahora, cualquier
> mejora que yo les anuncie que sea más chica que esto, no es una mejora. Es la
> corrida siguiente.»

🔴 **Escribe ese porcentaje en la pizarra, grande, y no lo borres hasta el final
de la clase.** Todo el Bloque 4 es esa cifra contra las otras. Si no está a la
vista, el bloque no funciona — literalmente no hay con qué comparar.

🔴 **No pases de aquí sin que hayan visto que los dos números no coinciden.** Si
por casualidad te salieron casi iguales, **corre una tercera**.

### ⚠ Errores probables en este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| La primera corrida es muchísimo peor que la segunda | La JVM arrancó en frío | Es lo que evita el calentamiento de *Antes de la clase*. Dilo, descarta esa corrida y corre dos más |
| Las dos corridas salen casi idénticas | Máquina muy descargada | Corre una tercera, o sube a `100000`. El ruido aparece |
| `Option --producer-props has been deprecated` | Kafka 8.x avisa del cambio de nombre | Ignorarlo en voz alta, para que nadie crea que falló |

---

## Bloque 3 · minuto 8 · Cambiar un parámetro. Uno solo — 3 min

**En pantalla:** el mismo comando con un flag más, dos veces.

### 🔮 Predicción antes de ejecutar

> «Voy a subir `linger.ms` de cero a diez: el ayudante, en vez de salir
> disparado, se queda hasta diez milisegundos juntando comandas. ¿El throughput
> sube o baja? ¿Y la latencia?»

Van a decir que el throughput sube y la latencia empeora. **Guarda las dos
respuestas en la pizarra.** En el Bloque 4 no se va a poder confirmar **ninguna
de las dos**, y ese es el golpe: no porque la clase se equivocara, sino porque
los datos no alcanzan para darles la razón ni para quitársela.

### Se ejecuta

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

Dos veces, igual que antes.

```
50000 records sent, 118764.845606 records/sec (22.65 MB/sec), 62.85 ms avg latency, 204.00 ms max latency, 71 ms 50th, 85 ms 95th, 89 ms 99th, 92 ms 99.9th.
50000 records sent, 110375.275938 records/sec (21.05 MB/sec), 65.93 ms avg latency, 220.00 ms max latency, 65 ms 50th, 106 ms 95th, 110 ms 99th, 112 ms 99.9th.
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

## Bloque 4 · minuto 11 · Un par más, la tabla y los `acks` — 7 min

🔴 **Este bloque es el laboratorio.** Los tres anteriores fueron la excusa para
llegar aquí. No lo apures y no lo recortes.

🔴 **Y este bloque termina en «no se distingue».** Léelo entero antes de la clase.
El instinto de todo relator es cerrar con una victoria, y aquí la victoria es
justamente no cerrar con una. Si improvisas, vas a anunciar la mejora del 14 % —
que es exactamente lo que la clase vino a desaprender.

### Primero, la trampa: parece que ya está

Pon las cuatro corridas juntas en pantalla y **no** las interpretes todavía.

| | records/sec |
|---|---|
| Base 1 | **114 943** |
| Base 2 | 96 899 |
| `linger.ms=10` 1 | 118 765 |
| `linger.ms=10` 2 | 110 375 |

> «Miren. Las dos tuneadas están arriba de la peor base. ¿Cerramos? ¿Escribo la
> lámina que dice que `linger.ms` mejoró el clúster?»

Deja que digan que sí. Alguno va a dudar. **Ese es el momento.**

> «Y ahora miren la pizarra: el ruido que medimos sin tocar nada era del
> **quince coma siete por ciento**. La distancia entre mi mejor base y mi mejor
> tuneada es del **tres**. **Cinco veces más chica que el ruido que ya medí.**
>
> Con estas cuatro corridas no puedo concluir nada. Necesito más.»

### Se ejecuta: un par más, uno detrás del otro

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

```
50000 records sent, 117096.018735 records/sec (22.33 MB/sec), 60.65 ms avg latency, 205.00 ms max latency, 68 ms 50th, 83 ms 95th, 87 ms 99th, 89 ms 99.9th.
50000 records sent, 120192.307692 records/sec (22.92 MB/sec), 46.60 ms avg latency, 206.00 ms max latency, 49 ms 50th, 70 ms 95th, 76 ms 99th, 79 ms 99.9th.
```

### Lectura uno · los rangos sueltos engañan en las dos direcciones

```
base        96 899 ────────────────── 117 096
linger              110 375 ───────────────── 120 192      se pisan
```

> «Mi **mejor** corrida base, 117 096, le gana a mi **peor** corrida tuneada,
> 110 375. Un compañero de ustedes que hubiera corrido justo esas dos se va a la
> reunión a decir que **el tuning empeoró el clúster**.
>
> Y otro que hubiera corrido la base 2 contra la tuneada 3 se va a la misma
> reunión a decir que **mejoró un veinticuatro por ciento**.
>
> Los dos midieron de verdad. Los dos están mirando datos reales. Y los dos
> están mal. Esa reunión es la del capítulo 1.»

### Lectura dos · pareado se ve mejor, y todavía no alcanza

| Par | Base | `linger.ms=10` | Diferencia |
|---|---|---|---|
| 1 | 114 943 | 118 765 | **+3,3 %** |
| 2 | 96 899 | 110 375 | **+13,9 %** |
| 3 | 117 096 | 120 192 | **+2,6 %** |

> «Ahora comparo de a pares, cada uno medido pegado al otro. **Tres de tres.**
> `linger.ms=10` no perdió ni uno.
>
> ¿Ahora sí escribo la lámina?»

**Deja que digan que sí.** Esta vez van a estar mucho más seguros que la primera,
y con razón: tres de tres suena a evidencia.

🔴 **Y aquí va el golpe del laboratorio. Señala la pizarra.**

> «Tres coma tres por ciento. Trece coma nueve. Dos coma seis.
>
> Y el ruido que medimos al principio, **sin cambiar absolutamente nada**, fue
> de quince coma siete.
>
> **Las tres ganancias caben dentro de mi propio ruido.** Gané tres de tres con
> victorias que son más chicas que lo que esta máquina se mueve sola cuando no
> la toco. Eso no es un efecto. Es una moneda que salió cara tres veces.»

Escríbelo en la pizarra, debajo del 15,7 %:

```
ruido, sin tocar nada    ├──────────── 15,7 % ────────────┤
par 1                    ├── 3,3 % ──┤
par 2                    ├────────── 13,9 % ──────────┤
par 3                    ├─ 2,6 % ─┤
```

### Lectura tres · la respuesta, que no es la que esperan

> «Para poder escribir esta guía corrimos **diez pares más**, con el clúster
> caliente y alternando el orden. ¿El resultado?
>
> **Cinco a cinco.**
>
> Medias: 115 699 contra 113 739. Diferencias por par de menos quince a más
> diecisiete por ciento, repartidas alrededor de cero.»

> «Así que la respuesta honesta de este laboratorio, y la única que yo puedo
> defender, es: **en esta máquina, con esta carga, `linger.ms=10` no se distingue
> de la línea base.**
>
> No digo que sea peor. Digo que si el efecto existe, es más chico que mi error
> de medición, y con estas herramientas **no lo puedo ver**.»

🔴 **Aquí se hace el silencio, y hay que sostenerlo.** Alguien va a preguntar
«¿entonces el laboratorio salió mal?». Es la mejor pregunta de la clase.

> «No. Éste es **el** resultado. Y es el que casi nunca les van a mostrar.
>
> Cuando alguien tunea un parámetro y no encuentra nada, no hace la lámina. La
> lámina se hace cuando el número salió lindo. Por eso todas las láminas de
> tuning que ustedes han visto dicen que el tuning funcionó — **no porque
> siempre funcione, sino porque las otras no se presentan.**
>
> Lo que yo les acabo de mostrar es lo que un ingeniero le lleva a su jefe:
> *medí, repetí trece veces, y la diferencia es más chica que mi error de
> medición. Si quieres que la persiga, necesito un banco de pruebas que se
> parezca a producción.* Esa frase vale más que un catorce por ciento que se cae
> la primera vez que alguien lo repite.»

### Y para que no se vayan con que nada se puede medir

🔴 **Importante, no lo saltes.** Sin esto, la clase se va con «medir no sirve»,
que es la lección contraria.

> «¿Quiere decir que nada se puede medir? No. Miren esto, que también está
> medido, y es `batch.size`:
>
> ```
> latencia media   base    66 ─────────── 107 ms
>                  64 KB   17 ──── 43 ms
> ```
>
> Estos dos rangos **no se tocan**. No necesité pares, ni estadística, ni trece
> corridas: se ve a simple vista. **Así se ve un efecto de verdad.**
>
> Y la regla que se llevan de aquí: **cuando hay que pelear con el ruido para
> encontrar una mejora, casi siempre la mejora no está.** Lo que es grande, se
> ve.»

### Lectura cuatro · el promedio esconde los casos malos

Ahora no compares corridas: quédate dentro de **una sola línea**, la primera.

| Métrica de la misma corrida | Valor |
|---|---|
| Latencia media | 60,03 ms |
| Latencia p99 | 97 ms |
| Latencia máxima | **197 ms** |

> «El promedio dice sesenta milisegundos. Pero uno de cada cien mensajes tardó
> más de noventa y siete, y hubo al menos uno que tardó **ciento noventa y
> siete: más del triple del promedio**.
>
> Si su tablero muestra el promedio, ese mensaje **no aparece en ninguna parte**
> — y es exactamente el que el usuario nota, porque es el que se quedó
> esperando.
>
> Por eso el rendimiento se vigila en percentiles. El promedio les dice cómo le
> fue al sistema. El p99 les dice cómo le fue **al peor de cada cien usuarios**.
> Los acuerdos de nivel de servicio se escriben con percentiles, nunca con
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

Fíjate que `acks` cae redondo aquí: es el **segundo** ejemplo del día de una
medición que no separa, y la clase ya tiene el marco para leerlo.

### 🔴 Si en tu clase los números salen distintos

Van a salir distintos, y **no importa**. Esta es la gracia del lab tal como
quedó: la conclusión ya no depende de quién gane los pares, sino de comparar las
ganancias contra el ruido. Esa comparación funciona con cualquier número.

| Lo que te salió | Qué decir |
|---|---|
| El tuneado gana los tres pares | Es lo que salió en la corrida grabada. Sigue el guion tal cual |
| El tuneado pierde los tres | **Igual de bueno.** «Ni siquiera necesito el argumento del ruido: perdió. Aunque miren cuánto perdió, y compárenlo con la pizarra» |
| Salen repartidos, 2-1 o 1-2 | **El mejor caso.** La conclusión llega sola: «ni siquiera gana siempre» |
| Una ganancia **supera** tu ruido, y por mucho | Dilo y no lo escondas: «esto sí es más grande que mi ruido. ¿Alcanza con un par? No. ¿Qué haría en serio? Más pares». Corre uno más en vivo: cuesta cuatro segundos |
| El ruido del Paso 1 te salió chiquito (1-2 %) | 🔴 **El único caso incómodo**, porque entonces las ganancias sí lo superan. Corre la base dos o tres veces más: el ruido casi siempre es mayor de lo que muestran dos corridas. Si aun así queda chico, usa la tanda de control de la guía —los diez pares, 5 a 5— como el dato que cierra |

**Nunca fuerces la conclusión que dice el guion si tus números dicen otra cosa.**
Este es el único lab del curso donde eso puede pasar, y donde admitirlo en voz
alta *es* la clase.

---

## Bloque 5 · minuto 18 · Cierre — 2 min

### Las reglas

Léelas de la guía, sección **6 · QUÉ QUEDÓ**. La que hay que subrayar es la
**3 bis**, que es la de hoy:

> «Una mejora solo cuenta si es más grande que su ruido. Ganar tres pares de
> tres no es evidencia si cada victoria cabe dentro de lo que la máquina se mueve
> sola. Antes de anunciar una mejora, pongan la ganancia al lado del ruido que
> midieron. Si no lo supera, la respuesta correcta es **no se distingue** — y esa
> respuesta es un resultado, no un fracaso.»

### La pregunta con la que se van

> «La próxima vez que alguien les muestre un número de rendimiento, ¿cuáles son
> las preguntas?»

*(¿Comparado con qué, cuántas veces lo mediste, y cuánto se mueve solo?)*

### 🔴 Y la frase que cierra el laboratorio

> «Hoy no encontramos la mejora que fuimos a buscar. Quiero que se vayan con eso
> bien claro, porque es lo raro de esta clase.
>
> El que nunca reporta un *no se distingue* no es que tenga mejores parámetros.
> **Es que no está midiendo el ruido.**»

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
3. La lectura cuatro —el promedio y la cola— se enuncia en una frase y se manda
   a leer. Devuelve ~2 min.
4. El contraste con `batch.size` se enuncia sin la tabla: «hay un parámetro que
   sí se distingue a simple vista, está en la guía». Devuelve ~1 min. **Es lo
   último que se toca**, y si lo botas asegúrate de decir la frase, porque sin
   ella la clase se va con «medir no sirve».

🔴 **Los bloques 2 y 3, y las lecturas uno, dos y tres del Bloque 4, no se
recortan**: son la demostración entera. La lectura tres —el 5 a 5 y el «no se
distingue»— es la conclusión del laboratorio; sin ella el lab no tiene final.

## Si sobra tiempo

Te va a sobrar: la máquina se toma diez segundos. Antes de improvisar, lo que
más rinde es **correr un cuarto y un quinto par** delante de la clase y agregarlos
a la tabla. Cada par cuesta cuatro segundos, y con la conclusión de hoy cada par
nuevo refuerza el punto **salga como salga**: si gana, se compara contra el ruido;
si pierde, es una victoria del tuneado que se evaporó. 🔴 **Alterna el orden**
—el tuneado primero en los pares nuevos— y dilo en voz alta: es el diseño
experimental de la tanda de control, y explicarlo cuesta treinta segundos.

Después de eso, *Para profundizar B* (`batch.size`) es lo que mejor engancha,
porque mueve **la latencia y no el throughput** — justo al revés que el del
recorrido, y es el mejor argumento contra tocar los dos juntos.
