# Lab 07 · Pruebas de rendimiento

## ¿Y comparado con qué?

> **Este es el laboratorio que enseña a no creerle a un número.** Vas a medir el
> clúster, vas a medirlo otra vez sin tocar nada, y los dos números van a ser
> distintos. Todo lo demás del laboratorio sale de ahí.

**Duración.** La ejecución son **7 segundos medidos** de punta a punta: cuatro
comandos que tardan dos segundos cada uno. En clase toma 20 minutos, porque
aquí la máquina no es el trabajo — el trabajo es leer lo que devolvió.

**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`).

---

## 1 · EL PROBLEMA

Viene la temporada alta y alguien pregunta cuánto aguanta el clúster. Se corre
una prueba de carga, sale **87 000 mensajes por segundo**, y ese número entra en
una lámina.

A la semana siguiente el equipo sube `batch.size`, vuelve a correr la prueba, y
salen **80 000**. Conclusión de la reunión: *el tuning empeoró el clúster,
vuélvanlo atrás.*

Las dos mediciones son reales. Las dos salieron de este laboratorio. Y la
conclusión está **al revés**, porque las dos son la misma medición repetida
sobre una máquina que no da el mismo número dos veces seguidas.

El problema no es el tuning. El problema es que **87 000 no significa nada por
sí solo**, y nadie en esa reunión sabía cuánto se mueve ese número cuando no se
cambia nada.

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
| Cuántas comandas le caben en la bandeja | `batch.size` | Cuántos bytes junta antes de salir |
| Cuánto se queda esperando a que caigan más | `linger.ms` | Cuánto espera aunque la bandeja no esté llena |
| A quién le espera el visto bueno | `acks` | A nadie, al mozo, o al mozo y a las libretas de respaldo |

Un ayudante que sale corriendo con **una** comanda hace cien viajes. Uno que
espera a llenar la bandeja hace diez. El segundo mueve más comandas por hora, y
cada comanda individual llega un poco más tarde.

**Y aquí está el laboratorio de hoy:** si cronometras **un** viaje del ayudante,
no sabes nada. Ese viaje pudo tocar el ascensor libre o la cocina llena. Para
decir algo hay que cronometrar varios, y hay que cronometrar los dos escenarios
**el mismo día**.

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
50000 records sent, 87260.034904 records/sec (16.64 MB/sec), 66.51 ms avg latency, 256.00 ms max latency, 74 ms 50th, 104 ms 95th, 114 ms 99th, 118 ms 99.9th.
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
«87 000 es bueno». Existe «87 000 contra los 80 000 de la corrida de al lado,
con un solo parámetro de diferencia, medidos hace un minuto».

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **Una sola medición no dice nada. El rendimiento es siempre una comparación.**

Y la consecuencia, que es la que decide si el experimento sirve o no:

> ▎ **Un parámetro a la vez.** Si cambias tres y mejora, no sabes cuál sirvió, y
> el día que uno de los tres te haga daño no vas a saber cuál sacar.

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
| `batch.size=16384` | 16 KB. **Es el valor de fábrica**, y el que vamos a mover en el Paso 2 |
| `linger.ms=0` | No espera nada: cierra el lote apenas puede |
| `compression.type=none` | Sin comprimir |

> Kafka 8.x avisa que `--producer-props` está deprecado y sugiere
> `--command-property`. **El flag funciona**; el aviso es de nombre, no de
> comportamiento.

**Qué sale.** Dos líneas, una por corrida:

```
50000 records sent, 87260.034904 records/sec (16.64 MB/sec), 66.51 ms avg latency, 256.00 ms max latency, 74 ms 50th, 104 ms 95th, 114 ms 99th, 118 ms 99.9th.
50000 records sent, 82508.250825 records/sec (15.74 MB/sec), 106.91 ms avg latency, 262.00 ms max latency, 118 ms 50th, 141 ms 95th, 146 ms 99th, 150 ms 99.9th.
```

**Cómo se lee.**

| Medición | Corrida 1 | Corrida 2 | Diferencia |
|---|---|---|---|
| records/sec | 87 260 | 82 508 | **−5,4 %** |
| MB/sec | 16,64 | 15,74 | −5,4 % |
| Latencia media | 66,51 ms | 106,91 ms | **+61 %** |
| Latencia p99 | 114 ms | 146 ms | +28 % |

🔴 **No se cambió nada entre las dos corridas.** Mismo comando, mismo tópico,
mismo clúster, treinta segundos de diferencia. Y el throughput se movió un 5 % y
la latencia media un 61 %.

**Ese es el ruido de tu máquina, y acabas de medirlo.** Cualquier mejora que
anuncies por debajo de ese margen no es una mejora: es la corrida siguiente.

**A ti te van a salir otros números**, y probablemente otra diferencia. Lo que
no cambia es que **las dos corridas no coinciden**.

---

### Paso 2 · Cambiar un parámetro. Uno solo

**Se explica.**

Ahora sí se tunea. Subimos `batch.size` de 16 KB a 64 KB: la bandeja del
ayudante pasa a ser cuatro veces más grande, así que hace menos viajes con más
comandas cada vez.

🔴 **Solo ese.** `linger.ms` se queda en 0, `acks` en `all`, la compresión en
`none`. Si mueves tres cosas y el número mejora, tienes una mejora que no sabes
atribuir — y el día que una de las tres te muerda en producción, no vas a saber
cuál sacar.

**Se ejecuta.** Dos veces, igual que antes:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536
```

| Parámetro | Valor | Para qué está |
|---|---|---|
| `--batch-size` | `65536` | 64 KB. Cuántos bytes junta el productor antes de mandar un lote |

**Qué sale.**

```
50000 records sent, 130208.333333 records/sec (24.84 MB/sec), 17.29 ms avg latency, 223.00 ms max latency, 16 ms 50th, 32 ms 95th, 40 ms 99th, 43 ms 99.9th.
50000 records sent, 80000.000000 records/sec (15.26 MB/sec), 42.89 ms avg latency, 315.00 ms max latency, 44 ms 50th, 79 ms 95th, 85 ms 99th, 86 ms 99.9th.
```

**Cómo se lee.** Todavía no. Primero hay que ponerlas al lado de las otras dos.

---

### Paso 3 · La tabla, que es el paso de verdad

**Se explica.**

Las cuatro corridas, juntas. Esta tabla es el laboratorio: los comandos fueron
la excusa para llegar hasta aquí.

| | records/sec | MB/sec | Latencia media | Latencia p99 | Latencia máx |
|---|---|---|---|---|---|
| **Base, corrida 1** | 87 260 | 16,64 | 66,51 ms | 114 ms | 256 ms |
| **Base, corrida 2** | 82 508 | 15,74 | 106,91 ms | 146 ms | 262 ms |
| **`batch.size` 64 KB, corrida 1** | **130 208** | 24,84 | 17,29 ms | 40 ms | 223 ms |
| **`batch.size` 64 KB, corrida 2** | **80 000** | 15,26 | 42,89 ms | 85 ms | 315 ms |

**Cómo se lee, y son tres lecturas distintas.**

**Uno · El throughput no separa nada.** Mira la columna `records/sec`. La mejor
corrida tuneada da 130 208, que parece un +49 %. Y la peor corrida tuneada da
**80 000, que es menos que las dos corridas base**. Los dos rangos se pisan:

```
base       82 508 ──────────── 87 260
tuneado    80 000 ────────────────────────────────── 130 208
```

Un alumno que corriera **una** base y **una** tuneada podría irse con «mejoró un
49 %» o con «empeoró un 3 %», según cuáles dos le tocaran. **Las dos
conclusiones estarían mal**, y las dos vendrían de datos reales.

**Dos · La latencia media sí separa.** Misma tabla, otra columna:

```
base       66,51 ms ─────────────── 106,91 ms
tuneado    17,29 ms ──── 42,89 ms
```

Ahí no hay solape: **la peor corrida tuneada (42,89 ms) sigue siendo mejor que
la mejor corrida base (66,51 ms)**. Esa es la mejora que sí se puede afirmar, y
es lo que uno esperaría: menos viajes con más comandas cada uno significa que
cada comanda espera menos en la bandeja.

🔴 **La conclusión del laboratorio no es «`batch.size` sube el throughput».** Es
que con estos datos **eso no se puede afirmar**, y lo que sí se puede afirmar es
que baja la latencia.

**Tres · El promedio esconde los casos malos.** Ahora no compares corridas:
quédate dentro de **una sola línea**, la primera tuneada.

| Métrica de la misma corrida | Valor |
|---|---|
| Latencia media | 17,29 ms |
| Latencia p99 | 40 ms |
| Latencia máxima | **223 ms** |

El promedio dice 17 ms. Pero uno de cada cien mensajes tardó más de 40, y hubo
al menos uno que tardó **223 ms, trece veces el promedio**. Si tu tablero
muestra el promedio, ese mensaje de 223 ms **no aparece en ninguna parte** — y
es exactamente el que el usuario nota, porque es el que se quedó esperando.

> 🔴 **Por eso el rendimiento se mira en percentiles.** El promedio te dice cómo
> le fue al sistema. El p99 te dice cómo le fue al peor de cada cien usuarios.
> Los acuerdos de nivel de servicio se escriben con percentiles, nunca con
> promedios.

### ⚠ Errores probables en este paso

| Síntoma | Causa | Qué hacer |
|---|---|---|
| La corrida tuneada salió peor que la base | **Es normal, y es la lección.** Estás dentro del ruido | Mirar la latencia media, que es la columna que separa |
| Las cuatro corridas dan casi lo mismo | Puede pasar si la máquina está muy descargada | Sube a `100000` mensajes y repite. La conclusión no cambia |
| La primera corrida es muchísimo peor que las otras tres | La JVM del contenedor arranca en frío | **Descartar la primera** y correr una más. Es la razón por la que se mide dos veces |
| `Option --producer-props has been deprecated` | Kafka 8.x avisa del cambio de nombre del flag | Ignorarlo. El flag funciona |

---

## 6 · QUÉ QUEDÓ

### Lo que se demostró

> ▎ **Una sola medición no dice nada. El rendimiento es siempre una comparación.**

| La afirmación decía | Y en pantalla se vio |
|---|---|
| **una sola medición no dice nada** | Dos corridas idénticas, sin tocar nada: 87 260 y 82 508 |
| **es siempre una comparación** | El `batch.size` solo se pudo evaluar poniendo las cuatro corridas en una tabla |
| **un parámetro a la vez** | Se movió `batch.size` y nada más, y por eso la mejora en latencia se le puede atribuir a él |

### Las cuatro reglas, para llevarse a SUNAT

**1 · Mide dos veces antes de tunear una.**
La primera medición no es la línea base: es una muestra. La línea base es el
**rango** entre dos o tres corridas sin tocar nada. Todo lo que caiga dentro de
ese rango es ruido.

**2 · Un parámetro a la vez.**
Si cambias `batch.size`, `linger.ms` y la compresión juntos y mejora, tienes una
mejora que no sabes atribuir. Sirve para la lámina y no sirve para operar.

**3 · Las dos configuraciones se miden el mismo día, en la misma tanda.**
Comparar la corrida de hoy contra un número anotado el mes pasado es comparar
ruido: la máquina, la carga y hasta la temperatura del disco cambiaron.

**4 · El promedio se reporta, el percentil se vigila.**
El promedio esconde la cola. Si un tablero solo muestra promedios, los casos que
el usuario nota son invisibles en él.

### La lectura que se usa para todo

> **Un número de rendimiento sin su comparación, su repetición y su percentil no
> es un dato. Es una anécdota.**

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue está fuera del recorrido de hoy **por tiempo, no por
dificultad**. **Los comandos de esta sección se ejecutaron uno por uno contra
este mismo clúster antes de publicarlos**, así que corren tal cual están
escritos, y las salidas de abajo son las que dieron.

🔴 **Y todos se leen con la regla del recorrido:** tres corridas, y se compara el
rango, no la corrida suelta.

### A · Los tres niveles de `acks`, medidos

En clase se explican sobre la tabla y no se ejecutan. Esta es la razón medida,
que es más interesante que la de tiempo.

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
tres rangos se pisan enteros. Y no es que el libro esté equivocado: es que en
este laboratorio **los tres brokers viven en la misma máquina**, así que esperar
la confirmación de las réplicas no cruza una red de verdad y no cuesta casi
nada. En un clúster real, con los brokers en servidores distintos, la diferencia
aparece.

**La lección operativa es esa:** un banco de pruebas que no se parece a
producción mide el banco de pruebas. Lo que `acks` cambia de verdad no es la
velocidad, es **qué se pierde cuando un broker se cae**:

| `acks` | Espera a | Qué pasa si el líder muere justo después de confirmar |
|---|---|---|
| `0` | Nadie | El mensaje se pierde y el productor nunca se entera |
| `1` | El líder | Se pierde si murió antes de que las réplicas copiaran |
| `all` | El líder y las réplicas en ISR | No se pierde |

### B · Compresión

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --compression lz4
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --compression zstd
```

Latencia media, tres corridas de cada uno, contra la base de 66–107 ms:

| | Corrida 1 | Corrida 2 | Corrida 3 |
|---|---|---|---|
| `lz4` | 49,26 ms | 46,07 ms | 48,26 ms |
| `zstd` | 17,45 ms | 9,69 ms | 38,82 ms |

**Lo que hay que mirar:** `lz4` es notablemente **estable** —tres corridas casi
idénticas— y `zstd` es más rápido pero mucho más disperso. Con datos de relleno
como los de esta prueba la compresión rinde muchísimo; con datos reales, que
comprimen peor, rinde menos. **Nunca midas compresión con datos sintéticos y
lleves ese número a una decisión.**

### C · Combinar parámetros, y por qué se hace al final

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536 --linger-ms 10
```

**Lo que hay que mirar:** combinar solo tiene sentido **después** de haber
medido cada parámetro por separado. Si vas directo a la combinación y mejora, no
sabes si fue el `batch.size`, el `linger.ms`, o si uno de los dos está tapando
que el otro hace daño.

### D · El lado del consumidor, y una trampa

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

### E · Particionado · todo el tráfico en una partición

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
antes                          después
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

### F · El reporte del lab

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
qué, y cuántas veces lo mediste?»**.

**Siguiente:** Lab 08 — *¿se le puede agregar un servidor a un clúster que está
atendiendo?*
