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

## Parte 2: Verificación externa de advertised.listeners

| Pregunta | Respuesta esperada |
|----------|--------------------|
| ¿Qué dirección publica el EXTERNAL? ¿Respondió el puerto 9092 desde el host? | El EXTERNAL publica `localhost:9092`; el puerto 9092 responde desde el host (es su público). |
| En el primer intento (contenedor por el EXTERNAL), ¿qué conectó y qué falló? | **Conectó el bootstrap** (TCP a `kafka-broker-1:9092`, alcanzable en la red), pero **falló el produce** con `TimeoutException`: el metadata devolvió `localhost:9092` y el contenedor resolvió "localhost" a sí mismo. |
| ¿Por qué el mismo advertised es correcto para el host e inservible para ese contenedor? | Porque la tarjeta se escribe para un público: para el host `localhost` ES el broker publicado; para el contenedor `localhost` es él mismo. El valor no es correcto "en absoluto", sino para quién lo lee. |
| Al colega del "bootstrap responde" | El bootstrap solo prueba la primera conexión; el cliente vive de las direcciones **advertidas** en el metadata. Bootstrap OK no garantiza nada — hay que validar el advertised con un cliente del público real. |

---

*Solución - Lab 04 (rebanada: listeners + verificación externa)*
