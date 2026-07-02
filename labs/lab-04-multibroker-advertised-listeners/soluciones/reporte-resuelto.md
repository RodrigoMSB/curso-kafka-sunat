# Lab 04 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Listeners separados y advertised.listeners

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Listeners en mismo puerto | El broker se niega a arrancar: `IllegalArgumentException: requirement failed: Each listener must have a different port`. Esto previene conflictos de socket |
| EXTERNAL anunciado como `kafka-broker-1` | El cliente del host no puede resolver `kafka-broker-1` porque ese hostname solo existe dentro de la red Docker. Por eso `localhost` es la dirección correcta para clientes externos |
| INTER_BROKER vs CONTROLLER | El tráfico de datos (entre brokers, replicación) y el tráfico de control (quorum, metadatos) se aíslan. Permite aplicar políticas distintas: cifrado, autenticación, QoS |

---

*Solución - Lab 04*

## Parte 2: Verificación externa de advertised.listeners

| Pregunta | Respuesta esperada |
|----------|--------------------|
| ¿Respondió el broker desde fuera de la red? | Sí, si el EXTERNAL publica una dirección alcanzable desde el host (p. ej. `localhost:9092`). |
| ¿Qué dirección publica tu EXTERNAL? | La del host (`localhost:<puerto>`), no un hostname interno de Docker. |
| Al romperlo (advertised interno), ¿qué error y cuándo? | El bootstrap inicial puede conectar, pero al recibir metadata con un hostname interno inalcanzable el cliente falla en la primera operación real (timeout / host no resoluble). |
| ¿Por qué bootstrap OK pero cliente falla? | El bootstrap solo obtiene la lista de brokers (advertised.listeners); si esas direcciones no son alcanzables desde el cliente, toda operación posterior muere aunque la conexión inicial pareciera exitosa. |

---

*Solución - Lab 04 (rebanada: listeners + verificación externa)*
