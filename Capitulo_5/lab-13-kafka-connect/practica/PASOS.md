# Lab 13 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-connect-y-quien-creo-ese-topico.md`. Este archivo es
> para tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba,
PostgreSQL sano y Kafka Connect respondiendo en `http://localhost:8083`.

**Sobre los comandos:** los que hablan con Connect son `curl`, porque Connect
solo se configura por su API REST. El laboratorio trae envoltorios más cortos en
`connect-cli/`, pero usan `python3`, que Git Bash no trae. Si el tuyo lo tiene,
sírvete.

**Cuánto toma:** la corrida completa son **21 segundos medidos**, de los cuales
**9 son esperar** al conector. La ejecución pura son 12 segundos. Los dos tramos
de espera midieron entre 1 y 8 segundos según la corrida: no esperes el mismo
número dos veces.

---

## Paso 1 · El antes

```bash
kafka-cli/list-topics.sh
```

| Hueco | Tu respuesta |
|---|---|
| ¿Cuántos tópicos hay? | |
| ¿Está `novatech.lab09.pedidos` en la lista? | |
| ¿Para qué crees que son los tres que empiezan con `_connect-`? | |

```bash
docker exec postgres psql -U novatech -d novatech_orders -c "SELECT count(*) FROM pedidos;"
```

| Hueco | Tu respuesta |
|---|---|
| Filas en la tabla `pedidos` | |
| Mensajes en Kafka | |

🔴 **Anota los dos números.** Todo el laboratorio consiste en mirar cómo el
segundo alcanza al primero sin que tú escribas en Kafka.

---

## Paso 2 · La instrucción

**Primero léela.** No la envíes todavía.

```bash
cat infra/connect/jdbc-source-pedidos.json
```

| Campo del JSON | Su valor | Qué crees que decide |
|---|---|---|
| `table.whitelist` | | |
| `mode` | | |
| `incrementing.column.name` | | |
| `topic.prefix` | | |
| `poll.interval.ms` | | |

**La pregunta del paso, antes de enviar nada:** en ninguna parte de ese JSON
dice cómo se va a llamar el tópico. ¿De dónde va a salir el nombre?

Ahora sí:

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/json" \
    --data @infra/connect/jdbc-source-pedidos.json \
    http://localhost:8083/connectors \
  | fold -s -w 88

curl -s http://localhost:8083/connectors/novatech-source-pedidos/status \
  | tr ',' '\n'
```

| Hueco | Lo que salió |
|---|---|
| El código `HTTP` del `create` | |
| `tasks` en la respuesta del `create` | |
| `connector.state` (bajo `"connector":{`) | |
| `tasks[0].state` (bajo `"tasks":[{`) | |

> ⚠️ Si el `status` te contesta `404 No status found`, no está roto: el estado
> se publica un instante después. Vuelve a correr el mismo comando.

**La pregunta del paso:** hay dos `state` distintos. ¿Qué combinación sería la
peligrosa, la que se ve bien por encima y no está copiando nada?

---

## Paso 3 · El tópico que apareció solo

```bash
kafka-cli/list-topics.sh
```

| Hueco | Lo que salió |
|---|---|
| ¿Cuántos tópicos hay ahora? | |
| ¿Cuál es el nuevo? | |
| ¿Qué comando lo creó? | |

> ⚠️ **Si el tópico todavía no está, llegaste antes que el conector.** Espera
> unos segundos y repite. Mientras no exista, `kafka-get-offsets` contesta
> `Could not match any topic-partitions` y el consumidor avisa
> `UNKNOWN_TOPIC_OR_PARTITION`. Las tres cosas significan lo mismo.

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos --time -1
```

| Hueco | Lo que salió |
|---|---|
| La línea completa (`tópico:partición:offset`) | |
| ¿Cuántos mensajes son? | |
| ¿Coincide con las filas que contaste en el Paso 1? | |

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --from-beginning --max-messages 5
```

| Hueco | Tu respuesta |
|---|---|
| ¿De dónde salieron los nombres de los campos del JSON? | |
| El campo `monto` sale como `"ExLQ"`. ¿Está corrupto? | |
| ¿Por qué crees que ese campo no sale como número? | |

---

## Paso 4 · La fila nueva

🔴 **Elige un texto de producto que reconozcas.** Lo vas a buscar dentro de un
mensaje de Kafka en un minuto.

```bash
kafka-cli/insertar-pedido.sh 2001 "Pedido de la clase" 5 25000.00
```

| Hueco | Lo que salió |
|---|---|
| El `id` que devolvió `RETURNING` | |
| **Antes de mirar Kafka: ¿cuánto crees que va a tardar en aparecer?** | |

Espera unos segundos y pregunta:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos --time -1
```

| Medición | Antes (Paso 3) | Después |
|---|---|---|
| offset del tópico | | |
| **mensajes** | | |
| ¿Cuántos segundos tardó? | — | |
| ¿Qué parámetro del JSON explica ese número? | — | |

Y el mensaje. *(El offset es el número de mensajes menos uno, porque empiezan
en 0.)*

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --partition 0 --offset 5 --max-messages 1
```

| Hueco | Tu respuesta |
|---|---|
| ¿Aparece el texto que escribiste? | |
| ¿Cuántos comandos de Kafka ejecutaste para que ese mensaje existiera? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · ¿Quién creó el tópico `novatech.lab09.pedidos`, y de dónde sacó su
nombre?**

**2 · ¿Cuántas líneas de código escribiste hoy? ¿Y cuántas habrías escrito para
hacer lo mismo con un programa propio, contando reintentos, memoria de dónde
quedó y monitoreo?**

**3 · Mañana alguien corre un `UPDATE` sobre una fila que ya viajó. ¿Aparece un
mensaje nuevo en Kafka? ¿Por qué, y qué habría que usar en su lugar?**

---

> **Lo que sigue** — verificar Connect y sus plugins, el dedo del conector, el
> camino de vuelta con el Sink, romperlo a propósito, la inserción masiva y el
> importe en base64 están listados en la sección **PARA PROFUNDIZAR** de la
> guía, con su comando completo y su salida medida.
