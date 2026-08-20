# Lab 06 · PASOS

> El recorrido en seco: los comandos en orden y los huecos que tú rellenas
> mientras corren. **La explicación está en la guía** —
> `guia/01-grupos-y-quien-repartio-el-trabajo.md`. Este archivo es para tener
> a mano, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, y **cuatro terminales**
abiertas en la carpeta del lab. Llámalas A, B, C y D.

> **D es la terminal de trabajo**: desde ahí se produce y se consulta. A, B y C
> son consumidores y se quedan corriendo.

---

## Paso 1 · El tópico de tres sectores

En **D**:

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --create --topic novatech.validacion \
    --partitions 3 --replication-factor 3

docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.validacion
```

| Campo | Lo que salió |
|---|---|
| `PartitionCount` | |

**La pregunta del paso:** ¿cuántos consumidores como máximo van a poder trabajar
en paralelo sobre este tópico?

---

## Paso 2 · Un cocinero solo

En **A** (se queda corriendo — se sale con `Ctrl+C`):

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group validacion \
    --consumer-property client.id=cons-A \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

En **D**:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

| Pregunta | Lo que salió |
|---|---|
| ¿Cuántas líneas devolvió? | |
| ¿Qué `CLIENT-ID` aparece en las tres? | |
| ¿Cuánto vale `LAG`? | |

---

## Paso 3 · Entra el segundo cocinero

En **B**, el mismo comando del Paso 2 **cambiando solo** `client.id=cons-B`.
`--group validacion` va **idéntico**.

Espera ~20 s y en **D**:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

| Partición | ¿De quién es ahora? |
|---|---|
| 0 | |
| 1 | |
| 2 | |

Ahora los seis comprobantes, en **D**:

```bash
for i in 1 2 3 4 5 6; do
  echo "RUC-2010006660${i}:comprobante_${i}" | \
  docker exec -i kafka-broker-1 kafka-console-producer \
      --bootstrap-server kafka-broker-1:29092 \
      --topic novatech.validacion \
      --property parse.key=true --property key.separator=:
done
```

| Medición | Valor |
|---|---|
| Mensajes que vio **A** | |
| Mensajes que vio **B** | |
| **Suma** | |
| ¿Alguno apareció en las DOS terminales? | |

🔴 **Lo que hay que mirar no es si el reparto fue parejo** —con seis mensajes
puede salir 6–0 y está bien— **sino que la suma sea 6 y los repetidos 0.**

---

## Paso 4 · Se va un cocinero

En **B**: `Ctrl+C`.

Espera ~20 s y en **D**:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

| Pregunta | Lo que salió |
|---|---|
| ¿Cuántos miembros quedan? | |
| ¿Quién tiene ahora la partición que era de `cons-B`? | |
| ¿Ejecutaste algún comando para reasignarla? | |

Tres comprobantes más, en **D**:

```bash
for i in 7 8 9; do
  echo "RUC-2010006660${i}:comprobante_${i}" | \
  docker exec -i kafka-broker-1 kafka-console-producer \
      --bootstrap-server kafka-broker-1:29092 \
      --topic novatech.validacion \
      --property parse.key=true --property key.separator=:
done
```

| Pregunta | Lo que salió |
|---|---|
| ¿Cuántos de los 3 llegaron a **A**? | |
| ¿Se perdió alguno? | |

---

## Paso 5 · El techo · cuatro cocineros, tres sectores

🔴 **El paso que no hay que saltarse.**

Levanta consumidores en **B**, **C** y una cuarta terminal, todos con
`--group validacion`, cambiando solo el `client.id` (`cons-B`, `cons-C`,
`cons-D`).

Espera ~30 s y en **D**:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion --members
```

| `CLIENT-ID` | `#PARTITIONS` |
|---|---|
| `cons-A` | |
| `cons-B` | |
| `cons-C` | |
| `cons-D` | |

| Pregunta | Tu respuesta |
|---|---|
| ¿Cuántos miembros hay? | |
| ¿Cuántos tienen `0`? | |
| ¿Qué está viendo en pantalla el que tiene `0`? | |
| Si mañana el atraso se duplica, ¿agregar un quinto consumidor ayuda? | |
| ¿Qué habría que cambiar para que ayudara? | |

---

## Paso 6 · Otra brigada

En una terminal libre (corta alguna con `Ctrl+C` si hace falta):

```bash
docker exec -it kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.validacion \
    --group reportes \
    --from-beginning \
    --consumer-property client.id=cons-Z \
    --property print.partition=true \
    --property print.key=true --property key.separator='|'
```

| Pregunta | Lo que salió |
|---|---|
| ¿Cuántos mensajes recibió `cons-Z`? | |
| ¿Qué cambió respecto del comando del Paso 2? | |

Y en **D**:

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group validacion
```

| Pregunta | Lo que salió |
|---|---|
| ¿Cambió el `CURRENT-OFFSET` de `validacion`? | |
| ¿Cambió su `LAG`? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · ¿Qué palabra del comando decide si dos procesos colaboran o duplican?**

**2 · Tienes un tópico de 3 particiones y el atraso no baja con 4 consumidores.
¿Qué hay que cambiar?**

**3 · Un compañero dice «levanté otro consumidor y ahora los mensajes se
procesan dos veces». ¿Qué es lo primero que le preguntas?**

---

> Corta con `Ctrl+C` todos los consumidores que sigan abiertos antes de
> terminar.
