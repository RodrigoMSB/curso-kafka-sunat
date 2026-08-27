# Lab 10 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-el-tablero-y-las-tres-de-la-manana.md`. Este archivo es
> para tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba, REST
Proxy en el **8082** y Kafbat UI en el **8090**.

**Cuánto toma:** **13 segundos medidos**, en 11 comandos. El tiempo de verdad se
va mirando el navegador.

🔴 **Los números de partición te van a salir distintos.** Los tres mensajes que
siembra el `start-lab.sh` van sin clave y caen todos juntos en una partición que
el productor elige: en las corridas medidas fueron la 2 y la 0. Lo que importa
es que **dos queden en cero y una con todo**.

---

## Paso 1 · Qué hay que mirar, antes de mirarlo

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.lab10.pedidos
```

Anota, porque es la **respuesta correcta** contra la que vas a comparar el
tablero:

| Campo | Lo que salió |
|---|---|
| `PartitionCount` | |
| `ReplicationFactor` | |
| `Leader` de la partición 0 | |
| `Isr` de la partición 0 | |

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1
```

| Partición | Mensajes |
|---|---|
| 0 | |
| 1 | |
| 2 | |

**La pregunta del paso:** los tres mensajes están todos en la misma partición y
dos están vacías. ¿Por qué? Y en un tópico de doscientas particiones, ¿cómo te
enterarías tú de que ciento noventa están vacías?

---

## Paso 2 · La misma verdad, dos veces

Abre **http://localhost:8090**. 🔴 **El 8090, no el 8080.**

Recorre y compara con lo que anotaste arriba:

| Dónde hacer clic | Qué buscar | ¿Coincide con tu tabla? |
|---|---|---|
| **Dashboard** | El clúster en verde, 3 brokers | |
| **Topics** → `novatech.lab10.pedidos` | Partitions, Replication Factor | |
| Pestaña **Partitions** | El *Leader* y las réplicas de cada una | |
| La columna de mensajes por partición | Dos en 0 y una con 3 | |
| Pestaña **Messages** | Los tres pedidos | |

| Hueco | Tu respuesta |
|---|---|
| ¿Hay algún dato en esa pantalla que no pudieras sacar de la consola? | |
| ¿Hay algo que la pantalla te muestre **más rápido**? ¿Qué? | |

---

## Paso 3 · Lo que el tablero suma por ti

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --group fiscalizacion --from-beginning --max-messages 3
```

Ahora entran cinco por la ventanilla HTTP:

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.kafka.json.v2+json" \
    --data '{"records":[{"value":{"pedido":2001}},{"value":{"pedido":2002}},{"value":{"pedido":2003}},{"value":{"pedido":2004}},{"value":{"pedido":2005}}]}' \
    http://localhost:8082/topics/novatech.lab10.pedidos
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué código HTTP? | |
| ¿Cuántas entradas trae `offsets`? | |
| ¿Qué trae cada una? | |
| ¿Qué valor tiene el campo `error` de cada una? | |

**La pregunta del paso:** ¿podría este comando devolver `HTTP 200` y aun así
haber fallado un mensaje? ¿Dónde lo verías?

Ahora el retraso, por consola:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group fiscalizacion
```

| Columna | Valor en la partición que tiene datos |
|---|---|
| `CURRENT-OFFSET` | |
| `LOG-END-OFFSET` | |
| `LAG` | |

Y el mismo dato en el tablero: **Consumers** → `fiscalizacion`.

| Hueco | Tu respuesta |
|---|---|
| ¿Qué estado muestra el tablero para el grupo? | |
| ¿El tablero te da el lag sumado o repartido? | |
| ¿Cuántas filas tuviste que leer en la consola para encontrar el mismo número? | |

---

## Paso 4 · Y ahora se cae el tablero

🔴 **Predice antes de ejecutar. Escríbelo aquí:**

| Con Kafbat apagado… | Tu predicción | Lo que pasó |
|---|---|---|
| ¿Siguen estando los 8 mensajes? | | |
| ¿Sigue el lag en 5? | | |
| ¿Sigue respondiendo el REST Proxy? | | |

```bash
docker stop kafbat-ui
```

```bash
curl -sS --max-time 5 http://localhost:8090/
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué dijo `curl`? | |
| ¿Es un `404`, un `500`, u otra cosa? ¿Qué significa la diferencia? | |

Ahora contesta las tres predicciones con comandos:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1
```

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group fiscalizacion
```

```bash
curl -s -o /dev/null -w "REST Proxy: HTTP %{http_code}\n" http://localhost:8082/topics
```

Y devuelve el tablero:

```bash
docker start kafbat-ui
```

| Hueco | Tu respuesta |
|---|---|
| Al recargar el navegador, ¿hubo que recuperar algo? | |
| ¿Por qué no? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · Un compañero te dice «Kafka está caído, la pantalla no carga». ¿Qué
comando escribes tú antes de creerle?**

**2 · ¿Qué sabe Kafbat UI que tú no puedas averiguar con la línea de comandos? ¿Y
qué hace mejor que ella?**

**3 · Son las tres de la mañana, tienes un SSH a un servidor sin navegador y te
dicen que «los pedidos no están llegando». ¿Cuáles son tus tres primeros
comandos, y en qué orden?**

---

> **Lo que sigue** — los endpoints del REST Proxy uno por uno, el ciclo completo
> de consumo por HTTP con su crear-suscribir-poll-borrar, el desafío del socio
> que solo hace `curl`, la interoperabilidad HTTP ↔ nativo y la API del propio
> tablero están listados en la sección **PARA PROFUNDIZAR** de la guía, con su
> comando completo.
