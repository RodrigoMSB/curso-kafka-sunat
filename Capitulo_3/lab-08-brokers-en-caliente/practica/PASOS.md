# Lab 08 · PASOS

> El recorrido en seco: los comandos en orden y los huecos que tú rellenas
> mientras corren. **La explicación de por qué hace cada cosa está en la guía** —
> `guia/01-y-quien-mueve-los-datos.md`. Este archivo es para tener a mano en la
> terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba.

> **Los pasos 1 a 3 son el recorrido de clase.** Deshacer con el plan de vuelta,
> los throttles a mano, el drenaje del broker, la configuración dinámica y el
> ciclo completo salieron por tiempo y están en la sección **PARA PROFUNDIZAR**
> de la guía, con su comando y su salida real.

---

## Paso 1 · La foto, y el tráfico corriendo

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

| Partición | `Replicas` (qué brokers) | `Leader` |
|---|---|---|
| 0 | | |
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

| Pregunta | Tu respuesta |
|---|---|
| ¿Qué números aparecen en toda la columna `Replicas`? | |
| ¿Cuántas réplicas hay en total? (particiones × RF) | |

**Ahora el tráfico.** En **otra terminal**, y se queda corriendo todo el lab:

```bash
kafka-cli/produce-sample.sh novatech.lab08.pedidos 300000
```

🔴 **Sin esto, el laboratorio no demuestra nada.** «No se cortó el servicio» no
significa nada si no había servicio.

---

## Paso 2 · Agregar el broker 4

**Primero decide qué esperas que pase.** Escríbelo antes de correr:

| Pregunta | Tu apuesta |
|---|---|
| Cuando el broker 4 entre, ¿va a empezar a recibir mensajes solo? | |
| ¿El quórum de controladores va a pasar de 3 a 4? | |

```bash
kafka-cli/add-broker.sh
kafka-cli/list-brokers.sh
```

| Pregunta | Tu respuesta |
|---|---|
| ¿El broker 4 aparece en la lista? | |
| `CurrentVoters` — ¿quiénes son? | |
| `CurrentObservers` — ¿quién es? | |
| ¿Acertaste la segunda apuesta? | |

Ahora vuelve a la foto:

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

| Pregunta | Tu respuesta |
|---|---|
| ¿Aparece algún `4` en la columna `Replicas`? | |
| 🔴 Entonces, ¿qué está haciendo el servidor que acabas de encender? | |

---

## Paso 3 · Reasignar hacia los cuatro

```bash
kafka-cli/reassign-partitions.sh novatech.lab08.pedidos 1,2,3,4 8000000
```

**Mientras corre**, en otra terminal:

```bash
kafka-cli/describe-broker-config.sh 1 | grep throttled
```

| Pregunta | Tu respuesta |
|---|---|
| ¿Qué `throttled.rate` tiene puesto el broker 1 durante la copia? | |

### Lectura uno · dónde quedaron las réplicas

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

| Pregunta | Tu respuesta |
|---|---|
| ¿En cuántas de las 6 particiones aparece ahora el broker 4? | |
| ¿Es `Leader` de alguna? | |

### Lectura dos · el plan de vuelta

Busca en la salida del `--execute` el bloque `Current partition replica assignment`.

| Pregunta | Tu respuesta |
|---|---|
| ¿Qué frase escribe Kafka justo debajo de ese bloque? | |
| ¿Para qué sirve ese JSON? | |
| ¿En qué archivo te lo guardó el script? | |
| 🔴 En tu servidor de SUNAT, ¿quién te lo guarda? | |

### Lectura tres · los frenos

| Pregunta | Tu respuesta |
|---|---|
| ¿Qué `Warning:` imprimió el `--execute`? | |
| ¿Qué fase quita los throttles? | |
| ¿Los quita si todavía queda una partición `in progress`? | |
| Comprueba que quedó limpio: `kafka-cli/describe-broker-config.sh 1 \| grep throttled` | |

🔴 **Si esa última comprobación devuelve algo, la operación no terminó.**

### Lectura cuatro · qué sintieron los clientes

Mira el productor que dejaste corriendo en el Paso 1.

| Pregunta | Tu respuesta |
|---|---|
| ¿Aparece algún `NOT_LEADER_OR_FOLLOWER`? ¿Cuántos? | |
| ¿Son `WARN` o `ERROR`? | |
| ¿Cuántos mensajes se enviaron en total, de los que pediste? | |
| Latencia **media** del resumen final | |
| Latencia **p95** del resumen final | |
| Latencia **p99** del resumen final | |
| Latencia **p99.9** del resumen final | |
| 🔴 ¿Cuántas veces más grande es el p99 que el p95? | |

> 💡 **Si esas dos últimas te sorprendieron, es el punto.** No se perdió un
> mensaje y el promedio no se movió — y aun así hubo mensajes que tardaron más de
> un segundo. Es la lección del Lab 07 aplicada a una operación.

---

## Cierre · Las cuatro preguntas del laboratorio

**1 · Tu jefe dice «agregamos el broker 4 el viernes y el clúster sigue igual de
lento». ¿Qué le preguntas primero?**

**2 · Ejecutaste una reasignación, el plan te dejó las tres réplicas de la
partición caliente en el mismo rack, y quieres volver atrás. ¿Qué necesitas, y
cuándo tendrías que haberlo guardado?**

**3 · Un compañero corre `--execute --throttle`, ve `is completed` en la mitad de
las particiones, y se va a almorzar. ¿Qué queda encendido en el clúster, y cómo
lo comprobarías?**

**4 · La reasignación no perdió ni un mensaje y la latencia media no se movió.
¿Puedes decirle al negocio que la operación fue transparente? Justifica con un
número.**

---

> **Lo que sigue** — deshacer con el plan de vuelta, limpiar throttles a mano,
> drenar y quitar el broker, la configuración dinámica y el ciclo completo con
> tráfico están en la sección **PARA PROFUNDIZAR** de la guía, con su comando
> completo y su salida real.
