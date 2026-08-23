# Lab 07 · PASOS

> El recorrido en seco: los comandos en orden y los huecos que tú rellenas
> mientras corren. **La explicación de por qué hace cada cosa está en la guía** —
> `guia/01-medir-y-comparado-con-que.md`. Este archivo es para tener a mano en
> la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba.

> **Estos son los tres pasos del recorrido de clase.** Los tres niveles de
> `acks` medidos, `batch.size`, la compresión, la combinación de parámetros, el
> lado del consumidor y el particionado salieron por tiempo y están en la sección
> **PARA PROFUNDIZAR** de la guía, con su comando y su salida real.

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
| Latencia media (ms) | | |
| Latencia p99 (ms) | | |
| Latencia máxima (ms) | | |

**La pregunta del paso:** no cambiaste nada. ¿De cuánto por ciento es la
diferencia en `records/sec`?

🔴 **Ese porcentaje es el ruido de tu máquina.** Anótalo aquí: **______ %**.
Cualquier «mejora» más chica que eso no es una mejora.

---

## Paso 2 · Cambiar un parámetro. Uno solo

**Primero decide qué esperas que pase.** Escríbelo antes de correr:

| Pregunta | Tu apuesta |
|---|---|
| Al subir `linger.ms` de 0 a 10, ¿el throughput sube o baja? | |
| ¿Y la latencia media? | |

Ahora sí, dos veces:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

| Medición | Corrida 1 | Corrida 2 |
|---|---|---|
| records/sec | | |
| Latencia media (ms) | | |
| Latencia p99 (ms) | | |
| Latencia máxima (ms) | | |

🔴 **`batch.size`, `acks` y la compresión no se tocan.** Un parámetro a la vez, o
la comparación no sirve.

---

## Paso 3 · Un par más, y la tabla

**Antes de correr nada**, compara lo que ya tienes:

| Pregunta | Tu respuesta |
|---|---|
| Tu **mejor** corrida base | |
| Tu **peor** corrida con `linger.ms=10` | |
| ¿Cuánto por ciento las separa? | |
| ¿Es más o menos que el ruido que anotaste en el Paso 1? | |

🔴 **Si la diferencia es más chica que el ruido, no puedes concluir nada
todavía.** Por eso viene un par más.

Un par, uno detrás del otro:

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000
```

```bash
kafka-cli/perf-test.sh novatech.tuning.bench 50000 --linger-ms 10
```

Ahora los tres pares, **cada uno contra el suyo**:

| Par | Base | `linger.ms=10` | ¿Quién ganó? | Diferencia |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

**Las tres lecturas:**

| Pregunta | Tu respuesta |
|---|---|
| 1 · ¿Se pisan los rangos sueltos de las dos configuraciones? | |
| 1b · Si compararas tu mejor base contra tu peor tuneada, ¿qué concluirías? | |
| 2 · ¿Cuántos de los tres pares ganó `linger.ms=10`? | |
| 2b · Escribe la conclusión afirmable en una frase, con el rango de mejora | |
| 2c · ¿Y qué pasó con la latencia media? ¿`linger.ms` la movió? | |
| 3 · En **una sola** corrida: promedio, p99 y máximo. ¿Cuántas veces el promedio es el máximo? | |
| 3b · Si tu tablero solo muestra el promedio, ¿qué mensaje no aparece? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · Un compañero te dice «subí `linger.ms` y el throughput bajó un 3 %».
¿Qué le preguntas antes de creerle?**

**2 · Cambiaste tres parámetros a la vez y mejoró un 20 %. ¿Qué sabes y qué no
sabes?**

**3 · La guía dice que en este clúster `acks=0` no salió más rápido que
`acks=all`. ¿Significa que `acks` da lo mismo? ¿Qué medirías tú antes de
decidirlo para SUNAT?**

---

> **Lo que sigue** — los tres niveles de `acks` medidos, `batch.size`, la
> compresión, la combinación de parámetros, el lado del consumidor y el
> particionado están listados en la sección **PARA PROFUNDIZAR** de la guía, con
> su comando completo y su salida real.
