# Lab 07 · SALIDAS — la corrida real

> **Esto no es un ejemplo escrito a mano.** Es la transcripción literal del
> recorrido de clase —seis corridas, tres pares— contra el clúster de tres
> brokers del laboratorio. Los `[t=NNNs]` son segundos desde el inicio.
>
> **Para qué sirve:** para contrastar. 🔴 **En este lab, contrastar no es buscar
> tus números aquí** — no los vas a encontrar. Es comprobar que la **relación**
> entre ellos sea la misma.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total** | **10 s** |
| De eso, esperando | **0 s** — este laboratorio no tiene ninguna espera |
| Cada corrida | ~2 s, la mayor parte arranque de la JVM del contenedor |

## Lo que va a ser distinto en tu máquina

**Todos los valores.** Sin excepción. Este es un laboratorio de mediciones sobre
una máquina compartida con el sistema operativo, Docker y lo que tengas abierto.

| Valor | Por qué cambia |
|---|---|
| `records/sec`, `MB/sec` | Depende de la carga de tu máquina en ese segundo |
| Las latencias | Lo mismo, y con más varianza todavía |
| **Cuántos pares gana el tuneado** | En esta corrida ganó los tres. Que gane cero también pasa: la tanda de control de más abajo salió 5 a 5 |
| **El tamaño del ruido del Paso 1** | Aquí salió 15,7 %. Puede salir 3 % o 20 % |

## Lo que **no** debería cambiar

- Que **las dos corridas base no coincidan** entre sí.
- Que los rangos sueltos de las dos configuraciones **se pisen**, de modo que la
  mejor base le gane a la peor tuneada.
- Que **la ganancia de cada par sea del orden del ruido que mediste en el
  Paso 1**, o más chica. Ese es el corazón del laboratorio.
- Que dentro de cualquier corrida, la latencia **máxima** sea varias veces el
  promedio.

🔴 **Lo que sí puede cambiar, y mucho, es cuántos pares gana el tuneado.** No
está entre los invariantes a propósito. Si tu corrida da 3-0, 0-3 o 2-1, la
lectura del laboratorio es la misma, porque la lectura no es quién ganó: es
**cuánto ganó comparado con tu ruido.**

---

## Transcripción

```

===== [t=000s] PASO 1 · la linea base, primera vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      16384 bytes
  Linger ms:       0
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 114942.528736 records/sec (21.92 MB/sec), 60.03 ms avg latency, 197.00 ms max latency, 64 ms 50th, 92 ms 95th, 97 ms 99th, 101 ms 99.9th.

===== [t=001s] PASO 1 · la linea base, segunda vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      16384 bytes
  Linger ms:       0
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 96899.224806 records/sec (18.48 MB/sec), 74.98 ms avg latency, 234.00 ms max latency, 80 ms 50th, 122 ms 95th, 132 ms 99th, 140 ms 99.9th.

===== [t=003s] PASO 2 · un solo parametro cambiado: linger.ms=10, primera vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      16384 bytes
  Linger ms:       10
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 118764.845606 records/sec (22.65 MB/sec), 62.85 ms avg latency, 204.00 ms max latency, 71 ms 50th, 85 ms 95th, 89 ms 99th, 92 ms 99.9th.

===== [t=005s] PASO 2 · un solo parametro cambiado: linger.ms=10, segunda vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      16384 bytes
  Linger ms:       10
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 110375.275938 records/sec (21.05 MB/sec), 65.93 ms avg latency, 220.00 ms max latency, 65 ms 50th, 106 ms 95th, 110 ms 99th, 112 ms 99.9th.

===== [t=006s] PASO 3 · el tercer par, para poder concluir =====
--- base ---
50000 records sent, 117096.018735 records/sec (22.33 MB/sec), 60.65 ms avg latency, 205.00 ms max latency, 68 ms 50th, 83 ms 95th, 87 ms 99th, 89 ms 99.9th.
--- linger 10 ---
50000 records sent, 120192.307692 records/sec (22.92 MB/sec), 46.60 ms avg latency, 206.00 ms max latency, 49 ms 50th, 70 ms 95th, 76 ms 99th, 79 ms 99.9th.

===== [t=010s] FIN =====
```

---

## La tabla, que es lo que el laboratorio produce

| | records/sec | MB/sec | Lat. media | Lat. p99 | Lat. máx |
|---|---|---|---|---|---|
| Base 1 | 114 943 | 21,92 | 60,03 ms | 97 ms | 197 ms |
| `linger.ms=10` 1 | 118 765 | 22,65 | 62,85 ms | 89 ms | 204 ms |
| Base 2 | 96 899 | 18,48 | 74,98 ms | 132 ms | 234 ms |
| `linger.ms=10` 2 | 110 375 | 21,05 | 65,93 ms | 110 ms | 220 ms |
| Base 3 | 117 096 | 22,33 | 60,65 ms | 87 ms | 205 ms |
| `linger.ms=10` 3 | 120 192 | 22,92 | 46,60 ms | 76 ms | 206 ms |

**El ruido del Paso 1**, que es la vara de todo lo demás:

```
114 943  vs  96 899   ->  15,7 %   sin tocar un solo parámetro
```

**Los rangos sueltos, que es lo que engaña:**

```
base        96 899 ────────────────── 117 096
linger              110 375 ───────────────── 120 192      se pisan
```

La mejor base (117 096) le gana a la peor tuneada (110 375). Y quien compare la
base 2 contra la tuneada 3 se lleva un **+24 %** que no existe.

**Los pares:**

| Par | Base | `linger.ms=10` | Diferencia | ¿Supera el ruido de 15,7 %? |
|---|---|---|---|---|
| 1 | 114 943 | 118 765 | +3,3 % | **No** |
| 2 | 96 899 | 110 375 | +13,9 % | **No** |
| 3 | 117 096 | 120 192 | +2,6 % | **No** |

🔴 **Tres de tres a favor, y aun así no se puede concluir nada:** las tres
ganancias caben dentro del ruido que la propia máquina mostró en el Paso 1.

---

## La tanda de control — 10 pares, y por qué existe

Tres pares se ven convincentes y no alcanzan. Para poder escribir la conclusión
de este laboratorio se corrieron **10 pares más**, con el clúster ya caliente y
**alternando el orden** (en los pares impares corre primero la base, en los pares
corre primero el tuneado), para que ninguna de las dos configuraciones se
beneficie de correr siempre en la misma posición.

| Par | Orden | Base | `linger.ms=10` | Diferencia |
|---|---|---|---|---|
| 1 | base 1º | 114 943 | 117 371 | +2,1 % |
| 2 | linger 1º | 114 943 | 97 466 | **−15,2 %** |
| 3 | base 1º | 119 904 | 117 647 | −1,9 % |
| 4 | linger 1º | 122 850 | 114 943 | −6,4 % |
| 5 | base 1º | 101 420 | 99 404 | −2,0 % |
| 6 | linger 1º | 121 951 | 122 249 | +0,2 % |
| 7 | base 1º | 121 951 | 107 527 | −11,8 % |
| 8 | linger 1º | 97 466 | 114 155 | **+17,1 %** |
| 9 | base 1º | 119 904 | 122 249 | +2,0 % |
| 10 | linger 1º | 121 655 | 124 378 | +2,2 % |

```
linger.ms=10 gana 5, pierde 5

media base    115 699 rec/s
media linger  113 739 rec/s      ->  −1,7 %, que es menos que cualquier ruido de la tabla

la diferencia por par va de  −15,2 %  a  +17,1 %,  repartida alrededor de cero
```

🔴 **Ese 5 a 5 es la conclusión del laboratorio:** en esta máquina, con esta
carga, `linger.ms=10` **no se distingue** de la línea base. Los tres pares del
recorrido, que salieron 3 a 0 a favor, eran demasiado pocos — y ese es
exactamente el error que el laboratorio enseña a no cometer.

**La latencia tampoco separa.** En la misma tanda de control, la media del
tuneado gana 4 pares y pierde 6: 54,8 ms de media la base contra 58,7 ms el
tuneado. Con `linger.ms` en esta máquina **no se mueve ninguna de las dos
métricas** de forma que se pueda afirmar.

### Nota sobre el efecto de la posición

En una tanda anterior, corrida **sin** alternar el orden, la configuración que
corría primero salía un 2,1 % mejor de media, y eso hizo sospechar de un sesgo
de posición. Con el orden alternado de la tabla de arriba la diferencia cae a
**+0,7 %**, que está dentro del ruido. **No hay efecto de posición demostrable**;
lo que había era ruido leído sin balancear. Se deja anotado porque es el mismo
error, un nivel más arriba: un patrón visto en pocas corridas que se desarma al
medirlo bien.

---

## Las otras corridas, las de PARA PROFUNDIZAR

Tres corridas de cada configuración, mismo clúster, misma sesión.

### Los tres niveles de `acks` — `records/sec`

| `acks` | 1 | 2 | 3 |
|---|---|---|---|
| `0` | 86 059 | 85 763 | 87 566 |
| `1` | 115 207 | 86 655 | 83 472 |
| `all` | 103 520 | 78 247 | 76 104 |

Los tres rangos se pisan enteros. `acks=0` no salió más rápido que `acks=all`, y
el mejor número de la tabla lo dio `acks=1`.

### `batch.size` — el que sí movió algo

Sobre 23 corridas, el throughput **no** separa y la latencia media **sí**:

```
records/sec   base    82 508 ──────── 87 260
              64 KB   80 000 ────────────────────────── 130 208     se pisan

lat. media    base    66,51 ─────────── 106,91 ms
              64 KB   17,29 ──── 42,89 ms                           no se pisan
```

🔴 Este es el contraste que vale la pena mirar: `batch.size` es **el único
parámetro de todo el lab cuyo efecto sobrevive al ruido**, y sobrevive en la
latencia, no en el throughput.

Y con un lote diminuto (`--batch-size 1024`), tres corridas:

| | records/sec | Latencia media |
|---|---|---|
| 1 | 18 195 | 1 194,65 ms |
| 2 | 25 720 | 843,60 ms |
| 3 | 24 260 | 819,75 ms |

Contra una línea base de 82 000–92 000 rec/s y 72–124 ms en esa misma tanda. Un
efecto de este tamaño **no necesita pares**: se ve a simple vista. Esa es la
diferencia entre un efecto real y grande y uno que hay que ir a buscar.

### Compresión — latencia media

| | 1 | 2 | 3 |
|---|---|---|---|
| `lz4` | 49,26 ms | 46,07 ms | 48,26 ms |
| `zstd` | 17,45 ms | 9,69 ms | 38,82 ms |

### El consumidor, y su trampa

```
data.consumed.in.MB, MB.sec, data.consumed.in.nMsg, nMsg.sec,   rebalance.time.ms, fetch.time.ms, fetch.nMsg.sec
19.1212,             4.9396, 100250,                25897.7009, 3589,              282,           355496.4539
```

De los 3 871 ms que duró la prueba, **3 589 fueron rebalanceo** y 282 fueron
leer. El `nMsg.sec` de 25 897 está midiendo casi puro arranque; el
`fetch.nMsg.sec` de 355 496 es la velocidad real de lectura.

### El particionado por clave

50 000 mensajes con la misma clave (`K`), y los offsets de las 6 particiones
antes y después:

```
antes                             despues
novatech.tuning.bench:0:359318    novatech.tuning.bench:0:359318
novatech.tuning.bench:1:369923    novatech.tuning.bench:1:369923
novatech.tuning.bench:2:370190    novatech.tuning.bench:2:370190
novatech.tuning.bench:3:370550    novatech.tuning.bench:3:370550
novatech.tuning.bench:4:359121    novatech.tuning.bench:4:409121   <- +50 000
novatech.tuning.bench:5:371898    novatech.tuning.bench:5:371898
```

Cinco particiones no se movieron ni un offset.

---

## Nota sobre la línea base

**La primera corrida contra un clúster recién levantado sale muchísimo peor que
las siguientes**, porque arranca la JVM del contenedor en frío. Medido en esta
misma máquina:

| | Latencia media de la línea base |
|---|---|
| Primera corrida tras `start-lab.sh` | **195,93 ms** |
| Ya caliente, misma máquina | **27,34 ms** |

Y no basta con una corrida de calentamiento: en la tanda con la que se grabó
este archivo, el p50 tardó **seis corridas** en dejar de bajar (199 → 111 → 73 →
84 → 123 → 62 ms). Por eso el guion del relator manda correr varias veces antes
de la clase y **descartar todos esos resultados**. Si repites el lab en tu casa,
haz lo mismo.

---

## Lo que salió del recorrido y dónde quedó

Este laboratorio tenía 14 actividades repartidas en cuatro archivos de guía. El
recorrido de clase son tres pasos. Lo que salió no se perdió: está en la sección
**7 · PARA PROFUNDIZAR** de la guía, con su comando y con las salidas de arriba.

| Salió del recorrido | Dónde está |
|---|---|
| Los tres niveles de `acks` ejecutados | *Para profundizar A* |
| `batch.size` | *Para profundizar B* |
| Las pruebas de compresión | *Para profundizar C* |
| La combinación de parámetros | *Para profundizar D* |
| El lado del consumidor | *Para profundizar E* |
| Los retos de particionado | *Para profundizar F* |
