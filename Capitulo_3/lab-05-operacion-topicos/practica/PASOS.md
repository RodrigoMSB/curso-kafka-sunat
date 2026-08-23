# Lab 05 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-retencion-y-si-nadie-los-borro.md`. Este archivo
> es para tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado, los 3 brokers arriba.

---

## Paso 1 · Crear el tópico de la demostración

**Primero decide los tres valores.** No copies el comando todavía: escribe
aquí lo que vas a poner, y recién después tecléalo. La guía justifica los tres
en el Paso 1.

| Hueco | Tu valor | Por qué ese |
|---|---|---|
| `--partitions` | | |
| `--config retention.ms=` | | (60 segundos, en milisegundos) |
| `--config segment.ms=` | | (10 segundos, en milisegundos) |

🔴 **El de `--partitions` es el que decide si el laboratorio funciona o no.**
Si dudas, vuelve al Paso 1 de la guía antes de teclear.

Ahora sí:

```bash
kafka-cli/create-topic.sh novatech.lab05.efimero \
    --partitions ___ \
    --rf 3 \
    --config retention.ms=___ \
    --config segment.ms=___
```

> El mismo comando, ya resuelto y con el porqué de cada valor comentado línea
> por línea, está en `soluciones/crear-topicos.sh`. Míralo **después** de
> intentarlo.

---

## Paso 2 · Describirlo y leer la línea `Configs`

```bash
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -2
```

Anota de la **primera línea**:

| Campo | Lo que salió |
|---|---|
| `PartitionCount` | |
| `ReplicationFactor` | |
| `Configs` (lo que aparece listado) | |

Y de la línea de la **partición 0**:

| Campo | Lo que salió |
|---|---|
| `Leader` | |
| `Replicas` | |
| `Isr` | |

**La pregunta del paso:** `Configs` trae tres valores. ¿Significa que el tópico
tiene tres configuraciones? ¿Y dónde está `cleanup.policy`, que es el que
decide qué pasa cuando un espiche vence?

---

## Paso 3 · Escribir 100 comprobantes y contarlos

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 100
```

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -1

docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

| Medición | Valor |
|---|---|
| offset más nuevo (`--time -1`) | |
| offset más antiguo (`--time -2`) | |
| **mensajes vivos** (la resta) | |
| hora del reloj | |

---

## Paso 4 · Cerrar el espiche

Espera unos 15 segundos y escribe unos pocos mensajes más:

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 5
```

```bash
MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 \
    ls /var/lib/kafka/data/novatech.lab05.efimero-0
```

| Pregunta | Lo que salió |
|---|---|
| ¿Cuántos archivos `.log` hay? | |
| ¿Cómo se llaman? | |

🔴 **Si solo hay un `.log`, no sigas.** El segmento no rotó. Espera diez
segundos más, vuelve a escribir 5 mensajes, y mira de nuevo. Sin un segundo
`.log` el Paso 5 no va a mostrar nada.

---

## Paso 5 · Esperar, y contar de nuevo

Repite esto cada minuto hasta que el número cambie. Puede tardar **hasta 5
minutos**, y la guía explica por qué.

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

| Momento | offset más antiguo |
|---|---|
| primera consulta | |
| segunda | |
| tercera | |
| cuando cambió | |

Y la cuenta final:

| Medición | Antes (Paso 3) | Después |
|---|---|---|
| offset más nuevo (`--time -1`) | | |
| offset más antiguo (`--time -2`) | | |
| **mensajes vivos** | | |

En disco:

```bash
MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 \
    ls /var/lib/kafka/data/novatech.lab05.efimero-0
```

| Pregunta | Lo que salió |
|---|---|
| ¿Sigue estando `00000000000000000000.log`? | |
| Si ves archivos terminados en `.deleted`, ¿qué crees que son? | |

---

## Cierre · Las tres preguntas del laboratorio

**1 · ¿Quién borró los comprobantes?**

**2 · ¿Qué comando de los que ejecutaste hoy borró algo?**

**3 · Si mañana un tópico de producción pierde datos que alguien esperaba
tener, ¿cuál es la primera línea que vas a ir a mirar, y con qué comando?**

---

> **Lo que sigue** — el resto de la operación de tópicos (los cuatro perfiles,
> compactación, cambios en caliente, particiones) está listado en la sección
> **PARA PROFUNDIZAR** de la guía, con su comando completo.
