# Lab 07 · Pruebas de rendimiento

## ¿Y comparado con qué?

> **Este es el laboratorio que enseña a no creerle a un número.** Vas a medir el
> clúster, vas a medirlo otra vez sin tocar nada, y los dos números van a ser
> distintos. Todo lo demás del laboratorio sale de ahí.

**Duración.** La ejecución son **10 segundos medidos** de punta a punta: seis
comandos que tardan unos dos segundos cada uno. En clase toma 20 minutos, porque
aquí la máquina no es el trabajo — el trabajo es leer lo que devolvió.

**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`).

---

## 1 · EL PROBLEMA

Viene la temporada alta y alguien pregunta cuánto aguanta el clúster. Se corre
una prueba de carga y salen **114 000 mensajes por segundo**. Ese número entra
en una lámina.

El equipo aplica un cambio de tuning que la documentación recomienda, vuelve a
correr la prueba, y salen **111 000**. Conclusión de la reunión: *el cambio
empeoró el clúster, vuélvanlo atrás.*

Las dos mediciones son reales. Las dos salieron de este laboratorio y las vas a
ver en pantalla. Y la conclusión **no se sostiene** — pero cuidado, la contraria
tampoco. Si los números hubieran salido al revés y la reunión hubiera decidido
*«el cambio funciona, déjenlo»*, habrían estado **igual de equivocados**.

El problema no es el tuning. El problema es que **114 000 no significa nada por
sí solo**, y nadie en esa reunión sabía cuánto se mueve ese número cuando no se
cambia nada. Sin eso, ninguna de las dos conclusiones vale.

---

## 2 · LA METÁFORA

Seguimos en el restaurante. El mozo es el broker, el tipo de comanda es el
tópico, los sectores del salón son las particiones, el cocinero es el consumidor
y la brigada es su grupo.

Hoy entra una pieza nueva, del otro lado del salón:

> 🏃 **El ayudante**
> El que recoge las comandas de las mesas y se las lleva al mozo. **Es el
> productor.** Todo lo que vas a tunear hoy son decisiones suyas, no del mozo.

Y el ayudante tiene exactamente tres decisiones:

| Decisión del ayudante | El parámetro | Qué controla |
|---|---|---|
| **Cuánto se queda esperando a que caigan más comandas antes de arrancar** | **`linger.ms`** | **Es el del recorrido de hoy** |
| Cuántas comandas le caben en la bandeja | `batch.size` | Cuántos bytes junta antes de salir |
| A quién le espera el visto bueno | `acks` | A nadie, al mozo, o al mozo y a las libretas de respaldo |

Un ayudante con `linger.ms=0` sale disparado apenas tiene algo en la mano. Si
espera diez segundos más, sale con la bandeja más llena y hace menos viajes.
Mueve más comandas por hora, y cada comanda individual llega un poco más tarde.

**Y aquí está el laboratorio de hoy:** si cronometras **un** viaje del ayudante,
no sabes nada. Ese viaje pudo tocar el ascensor libre o la cocina llena. Para
decir algo hay que cronometrar varios, y hay que cronometrar los dos escenarios
**el mismo día, uno detrás del otro**.

---

## 3 · CÓMO LO RESUELVE

Kafka trae dos herramientas que generan carga sintética y la miden, sin escribir
una línea de código:

| Herramienta | Mide |
|---|---|
| `kafka-producer-perf-test` | Throughput y latencia de **escritura** |
| `kafka-consumer-perf-test` | Throughput de **lectura** |

Hoy usamos la primera. Devuelve una sola línea con todo:

```
50000 records sent, 114942.528736 records/sec (21.92 MB/sec), 60.03 ms avg latency, 197.00 ms max latency, 64 ms 50th, 92 ms 95th, 97 ms 99th, 101 ms 99.9th.
```

> 📊 **Throughput**
> Cuánto trabajo pasa por unidad de tiempo. Aquí, `records/sec` y `MB/sec`. Es
> el número que la gente cita.

> ⏱ **Latencia**
> Cuánto tarda **un** mensaje en confirmarse. Aquí viene cinco veces: el
> promedio, el máximo, y tres percentiles.

> 📈 **Percentil**
> El `99th` es el valor que **el 99 % de los mensajes no superó**. Dicho al
> revés: uno de cada cien tardó **más** que eso.

Y la pieza que hace falta para leer todo lo demás:

🔴 **Un número de rendimiento no se lee solo. Se lee contra otro.** No existe
«114 000 es bueno». Existe «114 000 contra los 118 000 de la corrida de al lado,
con un solo parámetro de diferencia, medidos hace un minuto» — **y aun así hay
que preguntarse si esos 4 000 de diferencia son más de lo que la máquina se
mueve sola.**

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Una sola medición no dice nada. El rendimiento es siempre una comparación.**

Y la comparación tampoco se lee sola:

> ▎ **Una diferencia solo cuenta si es más grande que el ruido de tu máquina.**
> Por eso lo primero que se mide no es la mejora: es el ruido.

Y la consecuencia, que es la que decide si el experimento sirve o no:

> ▎ **Un parámetro a la vez.** Si cambias tres y mejora, no sabes cuál sirvió, y
> el día que uno de los tres te haga daño no vas a saber cuál sacar.

🔴 **Aviso, porque este lab termina distinto a como espera todo el mundo:** al
final del recorrido la respuesta medida va a ser **«en esta máquina no se
distingue»**. No es que el laboratorio salga mal. Es el resultado, y aprender a
decirlo en voz alta es la mitad de la clase.

---

## 5 · LOS PASOS

### Paso 1 · Medir sin tocar nada. Dos veces

**Se explica.**

Antes de tunear nada hay que saber **cuánto se mueve el número cuando no se
cambia nada**. Ese movimiento es el ruido de tu máquina, y cualquier mejora más
chica que ese ruido es indistinguible de la suerte.

Se mide dos veces seguidas, con el clúster en el mismo estado y sin tocar un
solo parámetro.

**Se ejecuta.** Dos veces, el mismo comando:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/perf-test.sh` | Envoltorio del curso. Por dentro llama a `kafka-producer-perf-test` dentro del contenedor y le agrega la ficha didáctica |
| `novatech.tuning.bench` | A qué tópico se le manda la carga. El clúster lo trae creado, con 6 particiones |
| `50000` | Cuántos mensajes generar. A 200 bytes cada uno son unos 10 MB |

El comando real que corre por debajo, y que es el que vas a escribir en el
servidor de SUNAT donde no hay Docker:

```bash
kafka-producer-perf-test \
    --topic novatech.tuning.bench \
    --num-records 50000 --record-size 200 --throughput -1 \
    --producer-props bootstrap.servers=kafka-broker-1:29092 \
      acks=all batch.size=16384 linger.ms=0 compression.type=none
```

| Parámetro | Para qué está |
|---|---|
| `--num-records` | Cuántos mensajes manda en total |
| `--record-size` | Cuántos bytes pesa cada uno |
| `--throughput -1` | Tope de mensajes por segundo. Con `-1` empuja todo lo que pueda, que es lo que queremos para medir el techo |
| `--producer-props` | Las propiedades del productor. **Aquí vive el tuning** |
| `acks=all` | Cuántas copias confirman antes de dar el mensaje por escrito |
| `batch.size=16384` | 16 KB. Cuántos bytes junta antes de mandar un lote |
| `linger.ms=0` | No espera nada: cierra el lote apenas puede. **Es el valor de fábrica, y el que vamos a mover en el Paso 2** |
| `compression.type=none` | Sin comprimir |

> Kafka 8.x avisa que `--producer-props` está deprecado y sugiere
> `--command-property`. **El flag funciona**; el aviso es de nombre, no de
> comportamiento.

**Qué sale.** Dos líneas, una por corrida:

```
50000 records sent, 114942.528736 records/sec (21.92 MB/sec), 60.03 ms avg latency, 197.00 ms max latency, 64 ms 50th, 92 ms 95th, 97 ms 99th, 101 ms 99.9th.
50000 records sent, 96899.224806 records/sec (18.48 MB/sec), 74.98 ms avg latency, 234.00 ms max latency, 80 ms 50th, 122 ms 95th, 132 ms 99th, 140 ms 99.9th.
```

**Cómo se lee.**

| Medición | Corrida 1 | Corrida 2 | Diferencia |
|---|---|---|---|
| records/sec | 114 943 | 96 899 | **−15,7 %** |
| MB/sec | 21,92 | 18,48 | −15,7 % |
| Latencia media | 60,03 ms | 74,98 ms | +24,9 % |
| Latencia p99 | 97 ms | 132 ms | +36,1 % |

🔴 **No se cambió nada entre las dos corridas.** Mismo comando, mismo tópico,
mismo clúster, un segundo de diferencia. Y el throughput se movió un 15,7 %.

**Ese es el ruido de tu máquina, y acabas de medirlo.** Cualquier mejora que
anuncies por debajo de ese margen no es una mejora: es la corrida siguiente.

🔴 **Anota ese número.** Es la vara con la que se mide todo lo que viene
después, y en el Paso 3 lo vas a usar para decidir si puedes concluir algo o
no.

**A ti te van a salir otros números**, y probablemente otra diferencia. Lo que
no cambia es que **las dos corridas no coinciden**.

---

### Paso 2 · Cambiar un parámetro. Uno solo

**Se explica.**

Ahora sí se tunea. Subimos `linger.ms` de 0 a 10: el ayudante, en vez de salir
disparado con lo que tenga en la mano, se queda hasta diez milisegundos juntando
comandas antes de arrancar. Menos viajes, cada uno más lleno.

🔴 **Solo ese.** `batch.size` se queda en 16 KB, `acks` en `all`, la compresión
en `none`. Si mueves tres cosas y el número mejora, tienes una mejora que no
sabes atribuir — y el día que una de las tres te muerda en producción, no vas a
saber cuál sacar.

**Se ejecuta.** Dos veces, igual que antes:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

| Parámetro | Valor | Para qué está |
|---|---|---|
| `--linger-ms` | `10` | Cuántos milisegundos espera el productor juntando mensajes antes de mandar el lote, aunque no esté lleno |

**Qué sale.**

```
50000 records sent, 118764.845606 records/sec (22.65 MB/sec), 62.85 ms avg latency, 204.00 ms max latency, 71 ms 50th, 85 ms 95th, 89 ms 99th, 92 ms 99.9th.
50000 records sent, 110375.275938 records/sec (21.05 MB/sec), 65.93 ms avg latency, 220.00 ms max latency, 65 ms 50th, 106 ms 95th, 110 ms 99th, 112 ms 99.9th.
```

**Cómo se lee.** Todavía no. Y con estas cuatro corridas **tampoco se va a poder
concluir**: el Paso 3 empieza mostrando por qué.

---

### Paso 3 · Un par más, y la tabla

**Se explica.**

Pon las cuatro corridas juntas y mira la columna que importa:

| | records/sec |
|---|---|
| Base, corrida 1 | **114 943** |
| Base, corrida 2 | 96 899 |
| `linger.ms=10`, corrida 1 | 118 765 |
| `linger.ms=10`, corrida 2 | 110 375 |

Parece limpio: las dos tuneadas están arriba de la peor base. **Pero fíjate en
las distancias.** La mejor base (114 943) y la mejor tuneada (118 765) están a un
3,3 % — y en el Paso 1 mediste que el ruido de tu máquina es del **15,7 %**.

🔴 **La diferencia que quieres celebrar es casi cinco veces más chica que el
ruido que ya mediste.** Con estas cuatro corridas no se puede concluir nada, y
esa es la respuesta correcta del Paso 2.

**Se ejecuta.** Un par más, uno detrás del otro:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

```
50000 records sent, 117096.018735 records/sec (22.33 MB/sec), 60.65 ms avg latency, 205.00 ms max latency, 68 ms 50th, 83 ms 95th, 87 ms 99th, 89 ms 99.9th.
50000 records sent, 120192.307692 records/sec (22.92 MB/sec), 46.60 ms avg latency, 206.00 ms max latency, 49 ms 50th, 70 ms 95th, 76 ms 99th, 79 ms 99.9th.
```

**Cómo se lee, y son tres lecturas distintas.**

| | records/sec | Latencia media | Latencia p99 | Latencia máx |
|---|---|---|---|---|
| **Base 1** | 114 943 | 60,03 ms | 97 ms | 197 ms |
| **`linger` 1** | 118 765 | 62,85 ms | 89 ms | 204 ms |
| **Base 2** | 96 899 | 74,98 ms | 132 ms | 234 ms |
| **`linger` 2** | 110 375 | 65,93 ms | 110 ms | 220 ms |
| **Base 3** | 117 096 | 60,65 ms | 87 ms | 205 ms |
| **`linger` 3** | 120 192 | 46,60 ms | 76 ms | 206 ms |

**Uno · Los rangos sueltos no separan, y engañan en las dos direcciones.**

```
base        96 899 ────────────────── 117 096
linger              110 375 ───────────────── 120 192      se pisan
```

La **mejor** corrida base (117 096) le gana a la **peor** corrida tuneada
(110 375). Un alumno que corriera esas dos se iría con «el tuning empeoró el
clúster» — que es exactamente la reunión del capítulo 1. Otro que corriera la
base 2 contra la tuneada 3 se iría con «mejoró un **24 %**». **Las dos
conclusiones saldrían de datos reales y las dos estarían mal.**

**Dos · Pareado se ve mucho mejor. Y todavía no alcanza.**

Cada par se midió uno detrás del otro, con la máquina en el mismo estado:

| Par | Base | `linger.ms=10` | Diferencia |
|---|---|---|---|
| 1 | 114 943 | 118 765 | **+3,3 %** |
| 2 | 96 899 | 110 375 | **+13,9 %** |
| 3 | 117 096 | 120 192 | **+2,6 %** |

**Tres de tres.** No hay ningún par donde `linger.ms=10` pierda, y la tentación
de cerrar aquí es enorme. Es el momento exacto en que se escribe la lámina que
dice «`linger.ms=10` mejora el throughput hasta un 14 %».

🔴 **Vuelve a mirar la vara.** El ruido que mediste en el Paso 1, sin tocar nada,
fue del **15,7 %**. Las tres ganancias son **+3,3 %, +13,9 % y +2,6 %**.

```
ruido medido, sin cambiar nada     ├──────────────── 15,7 % ────────────────┤
ganancia del par 1                 ├── 3,3 % ──┤
ganancia del par 2                 ├──────────── 13,9 % ────────────┤
ganancia del par 3                 ├─ 2,6 % ─┤
```

**Las tres caben dentro del ruido.** Ganar tres de tres suena a evidencia, pero
si cada victoria es más chica que lo que la máquina se mueve sola, lo que tienes
no es un efecto: es una moneda que salió cara tres veces.

**Tres · Entonces, ¿qué sí se puede afirmar?**

Para poder cerrar esta guía se corrieron **diez pares más**, con el clúster ya
caliente y alternando el orden dentro de cada par. El resultado está completo en
`soluciones/SALIDAS.md`, y es este:

```
linger.ms=10 gana 5 pares, pierde 5

media base    115 699 rec/s
media linger  113 739 rec/s

la diferencia por par va de −15,2 % a +17,1 %, repartida alrededor de cero
```

🔴 **Cinco a cinco.** La conclusión honesta de este laboratorio, y la única
defendible, es:

> ▎ **En esta máquina, con esta carga, `linger.ms=10` no se distingue de la
> línea base.** No es que sea peor: es que el efecto, si existe, es más chico
> que lo que esta máquina se mueve sola, y con estas herramientas no lo podemos
> medir.

Y fíjate en lo que hizo falta para poder decir eso: **no una métrica distinta ni
un comando más listo, sino repetir hasta que el ruido dejara de mandar.**

**«No se distingue» es un resultado, no un fracaso.** Es lo que un ingeniero le
lleva a su jefe cuando el jefe le pidió un número: *«medí, y la diferencia es más
chica que mi error de medición; si quieres que la persiga, necesito otro banco de
pruebas.»* Esa frase vale más que la lámina del 14 %, porque la lámina del 14 %
se cae sola la primera vez que alguien la repite.

**¿Y algo se distingue en este lab?** Sí, y está en *Para profundizar B*:
`batch.size` mueve la **latencia media** de 66–107 ms a 17–43 ms. Esos rangos no
se pisan. **Así se ve un efecto real**: no hay que ir a buscarlo con pares, se
ve a simple vista. Que `linger.ms` haya necesitado trece pares para decir «no sé»
y `batch.size` no haya necesitado ninguno para decir «sí» es la comparación que
vale la pena llevarse.

**Y la latencia con `linger.ms`, para cerrar:** en la tanda de control el tuneado
gana 4 pares y pierde 6, con medias de 54,8 ms contra 58,7 ms. **Tampoco separa.**
Con `linger.ms` en esta máquina no se mueve ninguna de las dos métricas de forma
afirmable.

**Cuatro · El promedio esconde los casos malos.** Ahora no compares corridas:
quédate dentro de **una sola línea**, la primera.

| Métrica de la misma corrida | Valor |
|---|---|
| Latencia media | 60,03 ms |
| Latencia p99 | 97 ms |
| Latencia máxima | **197 ms** |

El promedio dice 60 ms. Pero uno de cada cien mensajes tardó más de 97, y hubo
al menos uno que tardó **197 ms, más del triple del promedio**. Si tu tablero
muestra el promedio, ese mensaje **no aparece en ninguna parte** — y es
exactamente el que el usuario nota, porque es el que se quedó esperando.

> 🔴 **Por eso el rendimiento se mira en percentiles.** El promedio te dice cómo
> le fue al sistema. El p99 te dice cómo le fue al peor de cada cien usuarios.
> Los acuerdos de nivel de servicio se escriben con percentiles, nunca con
> promedios.


### Y el tercer parámetro del ayudante, que no vamos a medir

Falta `acks`: a quién le espera el visto bueno el ayudante.

| `acks` | Espera a | Qué pasa si el líder muere justo después de confirmar |
|---|---|---|
| `0` | Nadie | El mensaje se pierde y el productor nunca se entera |
| `1` | El líder | Se pierde si murió antes de que las réplicas copiaran |
| `all` | El líder y las réplicas en ISR | No se pierde |

El manual dice que `acks=0` es el más rápido y `acks=all` el más lento, y en
producción es así. **Aquí no.** Se midió en este mismo clúster, tres corridas de
cada nivel, y los tres rangos se pisan enteros: `acks=0` no salió más rápido que
`acks=all`. Las nueve corridas están en *Para profundizar A*.

🔴 **La razón no es que el manual esté equivocado: es que este clúster no se
parece a producción.** Los tres brokers viven en la misma máquina, así que
esperar la confirmación de las réplicas no cruza una red de verdad y no cuesta
casi nada. En un clúster real, con los brokers en servidores distintos y switches
en el medio, la diferencia aparece.

Y de ahí sale la regla que vale más que el número:

> ▎ **Un banco de pruebas que no se parece a producción mide el banco de
> pruebas.** Lo que `acks` decide de verdad no es la velocidad: es qué se pierde
> cuando un broker se cae. Eso se elige por riesgo, no por benchmark.

### ⚠ Errores probables en este paso

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Los tres pares los gana el tuneado | Lo mismo que salió en la corrida grabada | **No cierres ahí.** Compara cada ganancia contra el ruido del Paso 1. Si caben dentro, la respuesta sigue siendo «no se distingue» |
| Los tres pares los pierde el tuneado | También pasa, y en la tanda de control pasó la mitad de las veces | Idéntico tratamiento. La conclusión no depende de quién ganó |
| Los tres pares salen repartidos | Es el resultado más frecuente con muchos pares | Es la conclusión del lab, servida en bandeja |
| Una ganancia **sí** supera tu ruido, y por mucho | Puede ser un efecto real, o la máquina hizo algo raro en esa corrida | Corre tres pares más. Un efecto real se repite; una corrida rara, no |
| El ruido del Paso 1 te salió minúsculo (1–2 %) | Máquina muy descargada | **Cuidado:** con un ruido así, ganancias del 3 % sí lo superan. Corre la base tres o cuatro veces más — el ruido casi siempre es mayor de lo que muestran dos corridas |
| `Option --producer-props has been deprecated` | Kafka 8.x avisa del cambio de nombre del flag | Ignorarlo. El flag funciona |

---

## 6 · QUÉ QUEDÓ

### Lo que se demostró

> ▎ **Una sola medición no dice nada. El rendimiento es siempre una comparación.**

| La afirmación decía | Y en pantalla se vio |
|---|---|
| **una sola medición no dice nada** | Dos corridas idénticas, sin tocar nada: 114 943 y 96 899, un **15,7 %** de diferencia |
| **es siempre una comparación** | Los rangos sueltos se pisaban: la mejor base le ganaba a la peor tuneada, y otro par de corridas daba un +24 % que no existe |
| **y la comparación hay que medirla contra el ruido** | Tres pares ganados de tres, y aun así **ninguna ganancia superaba el ruido**. Con diez pares más el marcador quedó **5 a 5** |
| **un parámetro a la vez** | Se movió `linger.ms` y nada más — por eso el «no se distingue» se le puede atribuir a él y no a otra cosa |

### Las cuatro reglas, para llevarse a SUNAT

**1 · Mide dos veces antes de tunear una.**
La primera medición no es la línea base: es una muestra. La línea base es el
**rango** entre dos o tres corridas sin tocar nada. Todo lo que caiga dentro de
ese rango es ruido.

**2 · Un parámetro a la vez.**
Si cambias `linger.ms`, `batch.size` y la compresión juntos y mejora, tienes una
mejora que no sabes atribuir. Sirve para la lámina y no sirve para operar.

**3 · Compara pares, no rangos, y mide los dos el mismo día.**
Cada configuración contra la otra, una detrás de la otra, varias veces. Y
comparar la corrida de hoy contra un número anotado el mes pasado es comparar
ruido.

**3 bis · Una mejora solo cuenta si es más grande que tu ruido.**
Es la regla que este laboratorio existe para enseñar. Ganar tres pares de tres
no es evidencia si cada victoria cabe dentro de lo que la máquina se mueve sola.
Antes de anunciar una mejora, pon la ganancia al lado del ruido que mediste. Si
no lo supera, la respuesta correcta es **«no se distingue»** — y esa respuesta es
un resultado, no un fracaso.

**4 · El promedio se reporta, el percentil se vigila.**
El promedio esconde la cola. Si un tablero solo muestra promedios, los casos que
el usuario nota son invisibles en él.

### La lectura que se usa para todo

> **Un número de rendimiento sin su comparación, su repetición y su percentil no
> es un dato. Es una anécdota.**

Y su corolario, que es lo que separa a quien mide de quien presenta:

> **La respuesta «no se distingue» es una medición. La respuesta «mejoró un
> 14 %», dicha sin saber cuánto se mueve la máquina sola, no lo es.**

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue está fuera del recorrido de hoy **por tiempo, no por
dificultad**. **Los comandos de esta sección se ejecutaron uno por uno contra
este mismo clúster antes de publicarlos**, así que corren tal cual están
escritos, y las salidas de abajo son las que dieron.

🔴 **Y todos se leen con la regla del recorrido:** pares intercalados, varias
veces, y cada diferencia se compara **contra el ruido**, no contra cero.

### A0 · La tanda de control que cierra el recorrido

Es la que produce el «no se distingue» del Paso 3, y la que conviene rehacer si
quieres convencerte por tu cuenta. Diez pares, clúster caliente, **alternando el
orden dentro de cada par**:

```bash
# los pares impares, la base primero
kafka-cli/perf-test.sh novatech.tuning.bench 50000
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10

# los pares, el tuneado primero
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

**Por qué se alterna.** Si una configuración corre siempre en la misma posición,
cualquier cosa que dependa de la posición —cachés que se calientan, otra tarea
del sistema que arranca— se le suma o se le resta siempre a la misma. Alternar
reparte ese efecto entre las dos.

La tabla completa de los diez pares está en `soluciones/SALIDAS.md`. El
resultado: **5 a 5**, medias de 115 699 contra 113 739 rec/s, y diferencias por
par que van de −15,2 % a +17,1 % repartidas alrededor de cero.

> 🔬 **Un detalle que vale la clase entera.** Antes de alternar el orden, una
> tanda sin balancear sugería que la configuración que corría primero salía un
> 2,1 % mejor. Parecía un sesgo real. Con el orden alternado la diferencia cae a
> **+0,7 %** — dentro del ruido. **No había tal sesgo.** Era el mismo error del
> laboratorio, un nivel más arriba: un patrón visto en pocas corridas que se
> desarma al medirlo bien. Si alguna vez encuentras un efecto interesante,
> sospecha primero de tu diseño.

### A · Los tres niveles de `acks`, medidos

Es lo que el Paso 3 explica sin ejecutar. Estas son las corridas.

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --acks 0
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --acks 1
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --acks all
```

Tres corridas de cada uno, en `records/sec`:

| `acks` | Corrida 1 | Corrida 2 | Corrida 3 |
|---|---|---|---|
| `0` | 86 059 | 85 763 | 87 566 |
| `1` | 115 207 | 86 655 | 83 472 |
| `all` | 103 520 | 78 247 | 76 104 |

**Lo que hay que mirar:** `acks=0` **no** salió más rápido que `acks=all`. Los
tres rangos se pisan enteros, y el mejor resultado de toda la tabla es de
`acks=1`, que ni siquiera es el nivel más laxo. Es el banco de pruebas hablando
de sí mismo, no de Kafka.

### B · `batch.size`, el otro parámetro del lote

`batch.size` es cuántos **bytes** junta el productor antes de mandar el lote;
`linger.ms` es cuánto **tiempo** espera. Se suele confundir con el del recorrido.

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536
```

**Lo que hay que mirar:** sobre 23 corridas medidas, `batch.size=65536` **no**
separa en throughput —los rangos se pisan enteros, y hubo corridas tuneadas más
lentas que las de la línea base— pero sí separa en **latencia media**, y ahí sin
solape:

```
lat. media   base    66,51 ─────────── 106,91 ms
             64 KB   17,29 ──── 42,89 ms
```

🔴 **Este es el contraste que cierra el laboratorio.** `linger.ms` necesitó trece
pares para responder «no sé». `batch.size` no necesita ninguno: los dos rangos de
latencia **no se tocan**, y eso se ve a simple vista, sin estadística y sin
pares. Así se ve un efecto de verdad. Cuando hay que pelear con el ruido para
encontrar una mejora, casi siempre la mejora no está.

Y ojo con el reflejo de decir «entonces `batch.size` es el bueno»: lo que mejoró
fue la **latencia**, no el throughput. Si tu problema era el throughput, este
parámetro tampoco te sirve. Cada uno mueve una cosa distinta, y es el mejor
argumento contra tocarlos juntos.

Y el extremo opuesto, que es el más instructivo de todos:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 1024
```

Con un lote de 1 KB el throughput se desploma a **18 000–26 000 records/sec** —
una cuarta parte— y la latencia media sube a **820–1 195 ms**, un orden de
magnitud por encima de la línea base de esa misma tanda (72–124 ms). El batching
no es un ajuste fino: es lo que sostiene el rendimiento.

### C · Compresión

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --compression lz4
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --compression zstd
```

Latencia media, tres corridas de cada uno:

| | Corrida 1 | Corrida 2 | Corrida 3 |
|---|---|---|---|
| `lz4` | 49,26 ms | 46,07 ms | 48,26 ms |
| `zstd` | 17,45 ms | 9,69 ms | 38,82 ms |

**Lo que hay que mirar:** `lz4` es notablemente **estable** —tres corridas casi
idénticas— y `zstd` es más rápido pero mucho más disperso. Con datos de relleno
como los de esta prueba la compresión rinde muchísimo; con datos reales, que
comprimen peor, rinde menos. **Nunca midas compresión con datos sintéticos y
lleves ese número a una decisión.**

### D · Combinar parámetros, y por qué se hace al final

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536 --linger-ms 10
```

**Lo que hay que mirar:** combinar solo tiene sentido **después** de haber
medido cada parámetro por separado. Ya sabes que uno mueve el throughput y el
otro la latencia; si vas directo a la combinación y algo mejora, no sabes cuál
de los dos fue, ni si uno está tapando que el otro hace daño.

### E · El lado del consumidor, y una trampa

```bash
kafka-cli/consumer-perf-test.sh novatech.tuning.bench 100000
kafka-cli/consumer-perf-test.sh novatech.tuning.bench 100000 --fetch-size 5242880
```

Salida real, con las columnas que importan:

```
data.consumed.in.MB, MB.sec, data.consumed.in.nMsg, nMsg.sec, rebalance.time.ms, fetch.time.ms
19.1212,              4.9396, 100250,                25897.7009, 3589,            282
```

**Lo que hay que mirar, y es una trampa fea:** `nMsg.sec` dice 25 897 mensajes
por segundo. Pero mira las dos últimas columnas: de los ~3 871 ms que duró la
prueba, **3 589 fueron el rebalanceo** y solo **282 fueron leer**. El
`nMsg.sec` está midiendo casi puro arranque.

La columna honesta es la de al lado, `fetch.nMsg.sec`, que en esa misma corrida
dio **355 496**. Catorce veces más.

Por eso subir `--fetch-size` a 5 MB no mueve el `nMsg.sec`: no era el fetch el
que mandaba. **Antes de tunear algo, confirma que ese algo es el cuello de
botella.**

### F · Particionado · todo el tráfico en una partición

Producir con **una sola clave** manda todo a **una** partición, y una partición
es un solo broker líder: sin paralelismo.

Primero anota dónde está cada partición:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.tuning.bench --time -1
```

Ahora escribe 50 000 mensajes con clave:

```bash
seq 1 50000 | awk '{ print "K:msg_"$1 }' | \
    docker exec -i kafka-broker-1 kafka-console-producer \
        --bootstrap-server kafka-broker-1:29092 \
        --topic novatech.tuning.bench \
        --property "parse.key=true" --property "key.separator=:" \
        --producer-property "batch.size=65536" --producer-property "linger.ms=10"
```

🔴 **Ojo con lo que es la clave aquí, porque no es lo que parece.**
`key.separator=:` corta en el **primer** dos puntos, así que de la línea
`K:msg_1` la clave es **`K`** y el valor es `msg_1`. Las 50 000 líneas llevan la
**misma** clave. Ese es todo el truco del ejercicio.

Vuelve a mirar los offsets. Salida real, antes y después:

```
antes                             después
novatech.tuning.bench:0:359318    novatech.tuning.bench:0:359318
novatech.tuning.bench:1:369923    novatech.tuning.bench:1:369923
novatech.tuning.bench:2:370190    novatech.tuning.bench:2:370190
novatech.tuning.bench:3:370550    novatech.tuning.bench:3:370550
novatech.tuning.bench:4:359121    novatech.tuning.bench:4:409121   ← +50 000
novatech.tuning.bench:5:371898    novatech.tuning.bench:5:371898
```

**Lo que hay que mirar:** cinco particiones no se movieron **ni un offset**. Las
50 000 cayeron enteras en la 4, porque el hash de `K` da esa y siempre va a dar
esa. Seis brokers de capacidad, uno trabajando.

> ⚠️ **Lo que este ejercicio *no* mide es el throughput.** `kafka-console-producer`
> no imprime `records/sec`, así que no hay número que comparar con el del
> recorrido. Lo que demuestra es **dónde caen los mensajes**, y eso se mide con
> los offsets.

**La pregunta que vale:** si seis vehículos VIP generan el 80 % del tráfico y
particionas por clave, ¿qué le pasa a la partición que les tocó? Es el *hot
partitioning*, y es el precio de garantizar orden por clave.

### G · El reporte del lab

`plantillas/reporte-entregable.md` recorre las actividades de esta sección con
sus preguntas. Las respuestas de referencia están en
`soluciones/reporte-resuelto.md`.

---

## Cierre

El clúster queda arriba para el Lab 08. Si terminas por hoy:

```bash
bin/stop-lab.sh
```

**Lo que te llevas:** la próxima vez que alguien te muestre un número de
rendimiento, la primera pregunta ya no es «¿es bueno?». Es **«¿comparado con
qué, cuántas veces lo mediste, y cuánto se mueve solo?»**.

Y la segunda cosa que te llevas, que cuesta más: **este laboratorio terminó sin
encontrar la mejora que fue a buscar, y eso está bien.** Medir en serio incluye
poder decir «no se distingue». El que nunca reporta ese resultado no es que tenga
mejores parámetros — es que no está midiendo el ruido.

**Siguiente:** Lab 08 — *¿se le puede agregar un servidor a un clúster que está
atendiendo?*
