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
| **Ejecución total** | **9 s** |
| De eso, esperando | **0 s** — este laboratorio no tiene ninguna espera |
| Cada corrida | ~2 s, la mayor parte arranque de la JVM del contenedor |

## Lo que va a ser distinto en tu máquina

**Todos los valores.** Sin excepción. Este es un laboratorio de mediciones sobre
una máquina compartida con el sistema operativo, Docker y lo que tengas abierto.

| Valor | Por qué cambia |
|---|---|
| `records/sec`, `MB/sec` | Depende de la carga de tu máquina en ese segundo |
| Las latencias | Lo mismo, y con más varianza todavía |
| **Cuántos pares gana el tuneado** | En esta corrida ganó los tres. Dos de tres también es un resultado, y el guion dice qué hacer con él |

## Lo que **no** debería cambiar

- Que **las dos corridas base no coincidan** entre sí.
- Que la diferencia entre la mejor base y la peor tuneada sea **más chica que
  ese ruido**, de modo que con cuatro corridas no se pueda concluir.
- Que los rangos sueltos de las dos configuraciones **se pisen**.
- Que la latencia media **no** separe: `linger.ms` mueve el throughput.
- Que dentro de cualquier corrida, la latencia **máxima** sea varias veces el
  promedio.

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
50000 records sent, 114155.251142 records/sec (21.77 MB/sec), 60.98 ms avg latency, 216.00 ms max latency, 67 ms 50th, 91 ms 95th, 94 ms 99th, 96 ms 99.9th.

===== [t=002s] PASO 1 · la linea base, segunda vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      16384 bytes
  Linger ms:       0
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 104166.666667 records/sec (19.87 MB/sec), 62.30 ms avg latency, 244.00 ms max latency, 73 ms 50th, 89 ms 95th, 94 ms 99th, 96 ms 99.9th.

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
50000 records sent, 118764.845606 records/sec (22.65 MB/sec), 56.61 ms avg latency, 224.00 ms max latency, 63 ms 50th, 75 ms 95th, 80 ms 99th, 82 ms 99.9th.

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
50000 records sent, 117096.018735 records/sec (22.33 MB/sec), 65.78 ms avg latency, 214.00 ms max latency, 75 ms 50th, 89 ms 95th, 92 ms 99th, 94 ms 99.9th.

===== [t=006s] PASO 3 · el tercer par, para poder concluir =====
--- base ---
50000 records sent, 106157.112527 records/sec (20.25 MB/sec), 60.67 ms avg latency, 237.00 ms max latency, 67 ms 50th, 82 ms 95th, 85 ms 99th, 86 ms 99.9th.
--- linger 10 ---
50000 records sent, 111607.142857 records/sec (21.29 MB/sec), 60.97 ms avg latency, 223.00 ms max latency, 66 ms 50th, 81 ms 95th, 88 ms 99th, 92 ms 99.9th.

===== [t=009s] FIN =====
```

---

## La tabla, que es lo que el laboratorio produce

| | records/sec | MB/sec | Lat. media | Lat. p99 | Lat. máx |
|---|---|---|---|---|---|
| Base 1 | 114 155 | 21,77 | 60,98 ms | 94 ms | 216 ms |
| `linger.ms=10` 1 | 118 765 | 22,65 | 56,61 ms | 80 ms | 224 ms |
| Base 2 | 104 167 | 19,87 | 62,30 ms | 94 ms | 244 ms |
| `linger.ms=10` 2 | 117 096 | 22,33 | 65,78 ms | 92 ms | 214 ms |
| Base 3 | 106 157 | 20,25 | 60,67 ms | 85 ms | 237 ms |
| `linger.ms=10` 3 | 111 607 | 21,29 | 60,97 ms | 88 ms | 223 ms |

**Los rangos sueltos, que es lo que engaña:**

```
base       104 167 ──────────── 114 155
linger      111 607 ──────── 118 765          se pisan
```

La mejor base (114 155) le gana a la peor tuneada (111 607).

**Los pares, que es lo que se puede afirmar:**

| Par | Base | `linger.ms=10` | Diferencia |
|---|---|---|---|
| 1 | 114 155 | 118 765 | +4,0 % |
| 2 | 104 167 | 117 096 | +12,4 % |
| 3 | 106 157 | 111 607 | +5,1 % |

Tres de tres. Y la latencia media no separa: el tuneado gana un par y pierde dos.

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

### `batch.size` — al revés que `linger.ms`

Sobre 23 corridas, el throughput **no** separa y la latencia media **sí**:

```
records/sec   base    82 508 ──────── 87 260
              64 KB   80 000 ────────────────────────── 130 208     se pisan

lat. media    base    66,51 ─────────── 106,91 ms
              64 KB   17,29 ──── 42,89 ms                           no se pisan
```

Y con un lote diminuto (`--batch-size 1024`), tres corridas:

| | records/sec | Latencia media |
|---|---|---|
| 1 | 18 195 | 1 194,65 ms |
| 2 | 25 720 | 843,60 ms |
| 3 | 24 260 | 819,75 ms |

Contra una línea base de 82 000–92 000 rec/s y 72–124 ms en esa misma tanda.

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

Por eso el guion del relator manda correr una vez antes de la clase y **descartar
el resultado**. Si repites el lab en tu casa, haz lo mismo.

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
