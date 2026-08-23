# Lab 07 · PASOS

> El recorrido en seco: los comandos en orden y los huecos que tú rellenas
> mientras corren. **La explicación de por qué hace cada cosa está en la guía** —
> `guia/01-medir-y-comparado-con-que.md`. Este archivo es para tener a mano en
> la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba.

> **Estos son los tres pasos del recorrido de clase.** Los acks medidos, la
> compresión, la combinación de parámetros, el lado del consumidor y el
> particionado salieron por tiempo y están en la sección **PARA PROFUNDIZAR** de
> la guía, con su comando y su salida real.

---

## Paso 1 · Medir sin tocar nada. Dos veces

**El mismo comando, dos veces seguidas.** No cambies nada entre una y otra.

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

| Medición | Corrida 1 | Corrida 2 |
|---|---|---|
| records/sec | | |
| MB/sec | | |
| Latencia media (ms) | | |
| Latencia p99 (ms) | | |
| Latencia máxima (ms) | | |

**La pregunta del paso:** no cambiaste nada. ¿Por qué los dos números son
distintos, y de cuánto es la diferencia en `records/sec`?

🔴 **Esa diferencia es el ruido de tu máquina.** Anótala: cualquier «mejora» más
chica que eso no es una mejora.

---

## Paso 2 · Cambiar un parámetro. Uno solo

**Primero decide qué esperas que pase.** Escríbelo antes de correr:

| Pregunta | Tu apuesta |
|---|---|
| Al subir `batch.size` de 16 KB a 64 KB, ¿el throughput sube o baja? | |
| ¿Y la latencia media? | |

Ahora sí, dos veces:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536
```

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --batch-size 65536
```

| Medición | Corrida 1 | Corrida 2 |
|---|---|---|
| records/sec | | |
| MB/sec | | |
| Latencia media (ms) | | |
| Latencia p99 (ms) | | |
| Latencia máxima (ms) | | |

🔴 **`linger.ms`, `acks` y la compresión no se tocan.** Un parámetro a la vez, o
la comparación no sirve.

---

## Paso 3 · La tabla, que es el paso de verdad

Junta las cuatro corridas:

| | records/sec | Latencia media | Latencia p99 | Latencia máx |
|---|---|---|---|---|
| Base, corrida 1 | | | | |
| Base, corrida 2 | | | | |
| 64 KB, corrida 1 | | | | |
| 64 KB, corrida 2 | | | | |

**Las tres lecturas:**

| Pregunta | Tu respuesta |
|---|---|
| 1 · ¿Se pisan los rangos de `records/sec` de las dos configuraciones? | |
| 1b · Si compararas solo la peor tuneada contra la mejor base, ¿qué concluirías? | |
| 2 · ¿Se pisan los rangos de latencia media? | |
| 2b · Entonces, ¿qué mejora **sí** puedes afirmar? | |
| 3 · En **una sola** corrida tuneada: promedio, p99 y máximo. ¿Cuántas veces el promedio es el máximo? | |
| 3b · Si tu tablero solo muestra el promedio, ¿qué mensaje no aparece? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · Un compañero te dice «subí `batch.size` y el throughput bajó un 3 %».
¿Qué le preguntas antes de creerle?**

**2 · Cambiaste tres parámetros a la vez y mejoró un 20 %. ¿Qué sabes y qué no
sabes?**

**3 · Tienes que escribir un acuerdo de nivel de servicio para el equipo de
comprobantes. ¿Pones el promedio o el p99, y por qué?**

---

> **Lo que sigue** — los tres niveles de `acks` medidos, la compresión, la
> combinación de parámetros, el lado del consumidor y el particionado están
> listados en la sección **PARA PROFUNDIZAR** de la guía, con su comando
> completo y su salida real.
