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
kafka-cli/describe-broker-config.sh 1
```

El wrapper te muestra un recorte con las propiedades que interesan en este lab,
y cuenta los orígenes sobre la salida **completa**, no sobre el recorte. Fíjate
en los `synonyms`: de esa lista manda el **primero**; los de más abajo quedaron
tapados.

Si quieres la salida entera, sin ficha, el mismo wrapper tuberiado te la da:

```bash
kafka-cli/describe-broker-config.sh 1 | head -40
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
kafka-cli/alter-broker-config.sh 1 num.replica.fetchers 4
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
kafka-cli/alter-broker-config.sh 1 num.replica.fetchers 2
```

`Completed updating config for broker 1.`

**Paso 4 — de dónde viene ahora.**

El propio wrapper del paso 3 ya te mostró el **antes** y el **ahora**. Si
quieres volver a mirarlo:

```bash
kafka-cli/describe-broker-config.sh 1 | grep num.replica.fetchers
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
kafka-cli/alter-broker-config.sh 1 num.replica.fetchers --delete
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
