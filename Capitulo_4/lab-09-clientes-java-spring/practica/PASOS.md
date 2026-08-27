# Lab 09 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-clientes-y-donde-quedaron-tus-flags.md`. Este archivo es
> para tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba y el
tópico `novatech.lab09.pedidos` creado. Y **Maven instalado** — compruébalo con
`mvn -v`, porque es la única cosa de este lab que no vive en Docker.

**Cuánto toma:** **8 segundos medidos**, en tres comandos. La primera vez suma
la descarga de Maven: 4 segundos y 16 MB.

---

## Paso 1 · Los flags que ya sabes

**No ejecutes nada todavía.** Mira este comando, que es el que escribiste en el
Lab 06:

```bash
echo "RUC-20100066601:comprobante_1" | \
docker exec -i kafka-broker-1 kafka-console-producer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --property parse.key=true --property key.separator=:
```

🔴 **Ese tópico es de otro laboratorio: el comando está para leerlo, no para
correrlo.**

Escribe aquí, con tus palabras, qué decidiste con cada flag:

| Flag | Qué decidiste con él |
|---|---|
| `--bootstrap-server` | |
| `--topic` | |
| `--property parse.key=true` | |
| `--property key.separator=:` | |

---

## Paso 2 · El mismo comando, en Java

```bash
cat cliente-java/src/main/java/com/novatech/kafka/ProductorApp.java
```

**Busca en el archivo dónde quedó cada uno de tus cuatro flags.** No copies de
la guía: búscalos.

| Tu flag del Paso 1 | La línea del Java donde está |
|---|---|
| `--bootstrap-server` | |
| `--topic` | |
| `--property parse.key=true` | |
| `--property key.separator=:` | |

| Hueco | Tu respuesta |
|---|---|
| ¿Cuántas líneas tiene el archivo entero? | |
| ¿Cuántas de ellas son configuración de Kafka? | |
| Hay dos propiedades que **no** tenían flag en la consola. ¿Cuáles son? | |
| ¿Por qué crees que en la consola no hacían falta? | |

**La pregunta del paso:** el `BOOTSTRAP` de este archivo dice
`localhost:9092,...` y no `kafka-broker-1:29092`, que es lo que usa la consola.
¿Por qué? *(Pista: ¿desde dónde corre cada uno?)*

---

## Paso 3 · Correrlo

```bash
cd cliente-java
mvn -q compile exec:java \
    -Dexec.mainClass="com.novatech.kafka.ProductorApp" \
    -Dexec.args="5"
```

> ⚠️ Las tres primeras líneas de la salida empiezan con `SLF4J:`. **Son ruido y
> salen siempre.** No es un error.

| Hueco | Lo que salió |
|---|---|
| ¿En qué particiones cayeron los 5 pedidos? | |
| ¿Quién le dijo al programa en qué partición quedaron: el programa o el broker? | |
| ¿Qué línea del archivo obliga a esperar esa confirmación? | |

---

## Paso 4 · Y leerlo con la consola del Lab 06

```bash
cd ..
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --from-beginning --max-messages 5 \
    --formatter-property print.key=true
```

| Hueco | Tu respuesta |
|---|---|
| ¿Tuviste que cambiar algo del comando del Lab 06 para leer lo que escribió Java? | |
| ¿Qué hay a la izquierda del tabulador? | |
| ¿Qué hay a la derecha? | |
| ¿Quién decidió que el valor se viera como JSON: Kafka o el programa? | |

**El experimento del paso.** Corre estos dos, en este orden, y anota cuántos
mensajes trae cada uno:

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 --topic novatech.lab09.pedidos \
    --group mi-grupo-de-prueba --from-beginning --max-messages 5
```

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 --topic novatech.lab09.pedidos \
    --group mi-grupo-de-prueba --from-beginning --timeout-ms 10000
```

| Corrida | Mensajes |
|---|---|
| 1ª, con `--group` | |
| 2ª, con el **mismo** `--group` | |

> ⚠️ **La segunda corrida termina con esto, y es lo esperado:**
>
> ```
> [...] ERROR Error processing message, terminating consumer process:  (org.apache.kafka.tools.consumer.ConsoleConsumer)
> org.apache.kafka.common.errors.TimeoutException
> Processed a total of 0 messages
> ```
>
> **No es un fallo.** Es el `--timeout-ms 10000` cumpliéndose: el consumidor
> esperó diez segundos, no llegó nada, y se fue. **La línea que importa es la
> última.** Medido: tarda 11 segundos y devuelve 0.

**La pregunta del paso:** las dos llevan `--from-beginning`. ¿Por qué la segunda
no trae lo mismo que la primera? ¿Y por qué esto no se nota cuando corres el
consumidor **sin** `--group`?

---

## Cierre · Las tres preguntas del laboratorio

**1 · Un desarrollador te dice que su programa «no conecta con Kafka» y el
clúster está sano. ¿Qué archivo pides y qué línea miras primero?**

**2 · ¿Qué puede ver el broker que le permita distinguir un mensaje escrito por
un programa Java de uno escrito por `kafka-console-producer`?**

**3 · Un consumidor de producción «dejó de recibir mensajes» y el tópico sigue
llenándose. Antes de tocar el clúster, ¿qué miras, y con qué comando del Lab
06?**

---

> **Lo que sigue** — el consumidor Java, los serializers, Spring con
> `KafkaTemplate` y `@KafkaListener`, los consumer groups con procesos reales y
> el desafío de interoperabilidad están listados en la sección
> **PARA PROFUNDIZAR** de la guía, con su comando completo.
