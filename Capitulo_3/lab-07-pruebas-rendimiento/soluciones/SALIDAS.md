# Lab 07 · SALIDAS — la corrida real

> **Esto no es un ejemplo escrito a mano.** Es la transcripción literal del
> recorrido de clase —cuatro corridas— contra el clúster de tres brokers del
> laboratorio. Los `[t=NNNs]` son segundos desde el inicio.
>
> **Para qué sirve:** para contrastar. 🔴 **En este lab, contrastar no es buscar
> tus números aquí** — no los vas a encontrar. Es comprobar que la **relación**
> entre ellos sea la misma.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total** | **7 s** |
| De eso, esperando | **0 s** — este laboratorio no tiene ninguna espera |
| Cada corrida | ~2 s, la mayor parte arranque de la JVM del contenedor |

## Lo que va a ser distinto en tu máquina

**Todos los valores.** Sin excepción. Este es un laboratorio de mediciones sobre
una máquina compartida con el sistema operativo, Docker y lo que tengas abierto.

| Valor | Por qué cambia |
|---|---|
| `records/sec`, `MB/sec` | Depende de la carga de tu máquina en ese segundo |
| Las latencias | Lo mismo, y con más varianza todavía |
| **Cuál de las dos corridas de cada par sale mejor** | Es azar. En esta corrida la segunda tuneada salió peor que las dos base |

## Lo que **no** debería cambiar

- Que **las dos corridas base no coincidan** entre sí.
- Que los rangos de `records/sec` de las dos configuraciones **se pisen**.
- Que la latencia media de las corridas con `batch.size=65536` sea **menor** que
  la de las corridas base, y que ahí **no haya solape**.
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
50000 records sent, 87260.034904 records/sec (16.64 MB/sec), 66.51 ms avg latency, 256.00 ms max latency, 74 ms 50th, 104 ms 95th, 114 ms 99th, 118 ms 99.9th.

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
50000 records sent, 82508.250825 records/sec (15.74 MB/sec), 106.91 ms avg latency, 262.00 ms max latency, 118 ms 50th, 141 ms 95th, 146 ms 99th, 150 ms 99.9th.

===== [t=004s] PASO 2 · un solo parametro cambiado: batch.size, primera vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      65536 bytes
  Linger ms:       0
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 130208.333333 records/sec (24.84 MB/sec), 17.29 ms avg latency, 223.00 ms max latency, 16 ms 50th, 32 ms 95th, 40 ms 99th, 43 ms 99.9th.

===== [t=005s] PASO 2 · un solo parametro cambiado: batch.size, segunda vez =====
[Perf Test] novatech.tuning.bench
  Mensajes:        50000
  Tamaño:          200 bytes
  Acks:            all
  Batch size:      65536 bytes
  Linger ms:       0
  Compresión:      none
  Throughput cap:  -1 msg/seg
Option --producer-props has been deprecated and will be removed in a future version. Use --command-property instead.
50000 records sent, 80000.000000 records/sec (15.26 MB/sec), 42.89 ms avg latency, 315.00 ms max latency, 44 ms 50th, 79 ms 95th, 85 ms 99th, 86 ms 99.9th.

===== [t=007s] FIN =====
```

---

## La tabla, que es lo que el laboratorio produce

| | records/sec | MB/sec | Lat. media | Lat. p99 | Lat. máx |
|---|---|---|---|---|---|
| Base, corrida 1 | 87 260 | 16,64 | 66,51 ms | 114 ms | 256 ms |
| Base, corrida 2 | 82 508 | 15,74 | 106,91 ms | 146 ms | 262 ms |
| `batch.size` 64 KB, corrida 1 | **130 208** | 24,84 | 17,29 ms | 40 ms | 223 ms |
| `batch.size` 64 KB, corrida 2 | **80 000** | 15,26 | 42,89 ms | 85 ms | 315 ms |

**Los rangos, que es lo que hay que mirar:**

```
records/sec    base     82 508 ──────── 87 260
               64 KB    80 000 ────────────────────────── 130 208     se pisan

lat. media     base     66,51 ─────────── 106,91
               64 KB    17,29 ──── 42,89                              no se pisan
```

---

## Las otras corridas, las de PARA PROFUNDIZAR

Tres corridas de cada configuración, mismo clúster, misma sesión.

### Los tres niveles de `acks` — `records/sec`

| `acks` | 1 | 2 | 3 |
|---|---|---|---|
| `0` | 86 059 | 85 763 | 87 566 |
| `1` | 115 207 | 86 655 | 83 472 |
| `all` | 103 520 | 78 247 | 76 104 |

Los tres rangos se pisan enteros. `acks=0` no salió más rápido que `acks=all`.

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
| Las pruebas de compresión | *Para profundizar B* |
| La combinación de parámetros | *Para profundizar C* |
| El lado del consumidor | *Para profundizar D* |
| Los retos de particionado | *Para profundizar E* |
