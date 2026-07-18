# Parte 2: Verificación externa de advertised.listeners

## Objetivo

Comprobar que los `advertised.listeners` publican direcciones alcanzables para su público, y ver en vivo el fallo clásico de Kafka: bootstrap que responde, cliente que muere.

## Contexto

`advertised.listeners` es la **tarjeta de presentación** del broker: la dirección que le entrega al cliente para todo lo que viene después del bootstrap. La clave es que una tarjeta no es correcta en absoluto — es correcta **para un público**:

| Público | Listener que le sirve | Qué publica |
|---------|----------------------|-------------|
| Clientes del host (tus apps, los Java del Lab 09) | EXTERNAL | `localhost:9092` |
| Otros brokers y contenedores de la red | INTERNAL (PLAINTEXT) | `kafka-broker-1:29092` |

Si un cliente lee una tarjeta que no fue escrita para él, el bootstrap puede responder... y el cliente muere igual.

---

## Actividad 1: Verificar desde el host (el público del EXTERNAL)

**Paso 1 — Leer la tarjeta de presentación.** Mira qué publica realmente tu broker (usando lo aprendido en el Lab 03):

```bash
docker exec kafka-broker-1 bash -c 'grep advertised.listeners /etc/kafka/*.properties'
```

**Paso 2 — Confirmar el alcance desde el host.** El puerto publicado debe estar vivo desde donde está su público:

```bash
bash -c 'exec 3<>/dev/tcp/localhost/9092 && echo "EXTERNAL alcanzable desde el host"'
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué dirección publica el EXTERNAL en `advertised.listeners`? | |
| ¿El puerto 9092 respondió desde el host? | |

---

## Actividad 2: El fallo clásico, en vivo (sin romper nada)

Sobre el **mismo clúster sano**, un cliente del público equivocado. Lanza un contenedor dentro de la red del clúster y hazlo bootstrapear por el listener EXTERNAL.

Primero descubre el nombre de tu red (Docker Compose le antepone el prefijo del proyecto, así que no es fijo):

```bash
RED=$(docker inspect kafka-broker-1 --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}')
echo "Tu red: $RED"
```

Ahora el cliente-contenedor, bootstrapeando por el EXTERNAL (puerto 9092):

```bash
docker run --rm --network "$RED" confluentinc/cp-kafka:8.2.0 \
  bash -c 'echo "hola" | kafka-console-producer --bootstrap-server kafka-broker-1:9092 \
  --topic prueba.listeners --request-timeout-ms 10000' 2>&1 | tail -5
```

Observa: el bootstrap **conecta** (el contenedor sí alcanza `kafka-broker-1:9092`), pero el produce **falla** con un `TimeoutException` — el metadata le entregó `localhost:9092`, y para ese contenedor "localhost" es él mismo.

Ahora el mismo cliente, leyendo la tarjeta que SÍ es para él (el listener interno, puerto 29092):

```bash
docker run --rm --network "$RED" confluentinc/cp-kafka:8.2.0 \
  bash -c 'echo "hola" | kafka-console-producer --bootstrap-server kafka-broker-1:29092 \
  --topic prueba.listeners --request-timeout-ms 10000'
```

Funciona: el advertised interno publica `kafka-broker-1:29092`, resoluble en la red.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| En el primer intento, ¿qué conectó y qué falló? | |
| ¿Por qué el mismo `advertised.listeners` es correcto para el host e inservible para ese contenedor? | |
| Un colega dice "el bootstrap responde, así que Kafka está bien configurado". ¿Qué le contestas? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Listeners separados | Interno para brokers/contenedores, externo para el host |
| advertised.listeners | Es la tarjeta que recibe el cliente, correcta PARA un público |
| El fallo clásico | Bootstrap OK + metadata con dirección inalcanzable = cliente muerto |
