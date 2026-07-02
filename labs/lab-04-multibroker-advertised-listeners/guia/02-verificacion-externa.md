# Parte 2: Verificación externa de advertised.listeners

## Objetivo

Comprobar desde FUERA de la red Docker que los `advertised.listeners` publican direcciones alcanzables — el error de configuración más común de Kafka en el mundo real.

## Contexto

`advertised.listeners` es la dirección que el broker **le dice al cliente** que use. Si publica un hostname interno de Docker, el cliente de fuera se conecta al bootstrap... y muere al primer metadata. La prueba honesta se hace desde fuera de la red.

---

## Actividad 1: La prueba del cliente externo

Con tus listeners separados (Parte 1) corriendo, simula un cliente externo usando un contenedor **fuera** de la red del clúster:

```bash
docker run --rm confluentinc/cp-kafka:8.2.0 \
  kafka-broker-api-versions --bootstrap-server host.docker.internal:9092 | head -5
```

Si responde con la lista de APIs, el listener EXTERNAL está bien publicado.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Respondió el broker desde fuera de la red? | |
| ¿Qué dirección publica tu EXTERNAL en `advertised.listeners`? | |

---

## Actividad 2: Romperlo a propósito

Cambia temporalmente el `advertised.listeners` EXTERNAL de un broker a un hostname interno (p. ej. `kafka-broker-1:9092`), recréalo, y repite la prueba de la Actividad 1.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué error viste y en qué momento (conexión inicial o después)? | |
| ¿Por qué el bootstrap puede funcionar y aun así el cliente fallar? | |

Restaura el valor correcto al terminar.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Listeners separados | Interno para brokers, externo para clientes |
| advertised.listeners | Es lo que el cliente recibe, no lo que el broker escucha |
| El fallo clásico | Bootstrap OK + metadata con dirección inalcanzable = cliente muerto |
