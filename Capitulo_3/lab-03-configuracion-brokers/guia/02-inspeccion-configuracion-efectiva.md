# Parte 2: Inspección de la configuración efectiva

## Objetivo

Leer la configuración **efectiva** de un broker vivo con `kafka-configs`, y distinguir el origen de cada valor: default, estático o dinámico.

## Contexto

El properties dice lo que se declaró; `kafka-configs` dice lo que el broker **realmente está usando**, y de dónde salió cada valor:

| Origen | Significa |
|--------|-----------|
| `DEFAULT_CONFIG` | Nadie lo tocó: valor de fábrica |
| `STATIC_BROKER_CONFIG` | Vino del properties (tus `KAFKA_*`) — cambiarlo exige reinicio |
| `DYNAMIC_BROKER_CONFIG` | Cambiado en caliente vía API (lo harás en el Lab 08) |

---

## Actividad 1: Configuración efectiva del broker 1

```bash
docker exec kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --describe --entity-type brokers --entity-name 1 --all | head -40
```

Busca tres valores concretos:

```bash
docker exec kafka-broker-1 bash -c 'kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --describe --entity-type brokers --entity-name 1 --all | grep -E "min.insync.replicas|log.retention.hours|num.partitions"'
```

### Anota

| Propiedad | Valor efectivo | Origen |
|-----------|----------------|--------|
| `min.insync.replicas` | | |
| `log.retention.hours` | | |
| `num.partitions` | | |

---

## Actividad 2: Predicción de origen

Antes de mirar, predice: ¿qué origen tendrá una propiedad que declaraste en tu compose vs una que nunca mencionaste? Verifica con dos ejemplos de cada tipo.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué `min.insync.replicas` aparece como STATIC en tu clúster? | |
| ¿Qué diferencia práctica hay entre STATIC y DYNAMIC a la hora de cambiar un valor? | |

---

## Actividad 3: El broker te dice que no

Hasta aquí miraste. Ahora vas a cambiar algo en caliente y a ver la etapa 3
moverse sin que las etapas 1 y 2 se enteren.

**Paso 1 — la foto del antes.** Pregúntale al archivo si conoce esta propiedad:

```bash
docker exec kafka-broker-1 sh -c "grep -c num.replica.fetchers /etc/kafka/kafka.properties"
```

Responde `0`: nunca la escribiste, así que no está en la etapa 2. Su valor
efectivo es `1`, y viene de fábrica.

**Paso 2 — el intento que Kafka rechaza.** Vas a subirla a `4`.

> **Predice antes de ejecutar:** el valor actual es `1`. ¿Kafka acepta cualquier
> número, o hay un límite? Escribe tu respuesta antes de correr el comando.

```bash
docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --entity-type brokers --entity-name 1 \
  --alter --add-config num.replica.fetchers=4
```

Sale una pared de texto Java. **Léela así: las dos primeras líneas, y sáltate
la traza.** La segunda línea trae el motivo:

```
Dynamic thread count update validation failed for num.replica.fetchers=4,
value should not be greater than double the current value 1
```

Eso no es un tropiezo tuyo: **es la lección.** Los cambios dinámicos tienen su
propia validación, y el broker está vivo del otro lado diciéndote *eso no, así
no*. Un `server.properties` en disco no te contesta; un broker corriendo sí.

**Paso 3 — el mismo cambio, dentro del límite.** El doble de `1` es `2`:

```bash
docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --entity-type brokers --entity-name 1 \
  --alter --add-config num.replica.fetchers=2
```

`Completed updating config for broker 1.`

**Paso 4 — de dónde viene ahora.**

```bash
docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --entity-type brokers --entity-name 1 --describe --all | grep num.replica.fetchers
```

```
num.replica.fetchers=2  synonyms={DYNAMIC_BROKER_CONFIG:num.replica.fetchers=2,
                                  DEFAULT_CONFIG:num.replica.fetchers=1}
```

Aparecieron **los dos orígenes**: el DEFAULT de fábrica sigue ahí abajo y el
DYNAMIC le gana encima. Y si vuelves a preguntarle al archivo, sigue devolviendo
`0` — **la etapa 3 se movió y la etapa 2 ni se enteró.**

**Paso 5 — dejarlo como estaba.**

```bash
docker exec -e KAFKA_OPTS= kafka-broker-1 kafka-configs \
  --bootstrap-server kafka-broker-1:29092 \
  --entity-type brokers --entity-name 1 \
  --alter --delete-config num.replica.fetchers
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Acertaste la predicción del paso 2? ¿Qué límite impone Kafka? | |
| Tras el paso 3, ¿qué dice el archivo `kafka.properties`? ¿Por qué? | |
| ¿Por qué un cambio dinámico puede fallar y uno del `server.properties` no? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Mapeo env → properties | Predijiste y verificaste la traducción de `KAFKA_*` |
| Configuración efectiva | Leíste lo que el broker usa de verdad, no lo que crees |
| Orígenes de configuración | Distinguiste DEFAULT / STATIC / DYNAMIC |
| Validación en caliente | Kafka rechazó tu cambio y te dijo por qué |
| Leer errores de Java | Las dos primeras líneas; la traza casi nunca importa |

> En el **Lab 08** cerrarás el círculo: cambiarás configuración DYNAMIC en caliente, sin reiniciar.
