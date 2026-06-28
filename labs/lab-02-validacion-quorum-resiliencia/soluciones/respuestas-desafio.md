# Lab 03 — Respuestas del desafío (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Reto 1: Listeners en el mismo puerto

**Error esperado en logs:**
```
java.lang.IllegalArgumentException: requirement failed: Each listener must have a different port
```

**Por qué**: cada listener mantiene un socket TCP propio. Dos listeners no pueden bindear el mismo puerto al mismo tiempo.

**Implicación pedagógica**: en producción, esto previene que un misconfiguración accidental rompa el aislamiento entre tráfico de datos y de control.

---

## Reto 2: Advertised listener mal configurado

**Síntoma**: el cliente desde el host no logra completar el handshake con el broker. Después de la conexión inicial, el broker le responde "para producir/consumir, conéctate a `kafka-broker-1:9092`", pero ese hostname no es resoluble desde el host.

**Solución correcta**: el `advertised.listener` debe ser **lo que el cliente puede resolver**:
- Si el cliente está dentro de la red Docker → hostname interno (`kafka-broker-1`)
- Si el cliente está en el host → `localhost` (o la IP pública si es remoto)

Por eso usamos dos listeners distintos:
- `PLAINTEXT` con advertised `kafka-broker-1:29092` → para clientes dentro de Docker
- `EXTERNAL` con advertised `localhost:9092` → para clientes en el host

---

## Reto 3: Reflexión

**¿Por qué CONTROLLER separado?**
- KRaft replica el log de metadatos del clúster (parecido a etcd o Raft puro). Este tráfico es de bajo volumen pero crítico.
- Aislarlo en su propio listener permite aplicar políticas de seguridad y QoS distintas a las del tráfico de datos del cliente.
- Además, en arquitecturas dedicadas (controllers separados de brokers), esos nodos solo abren el listener CONTROLLER, no el PLAINTEXT.

**INTER_BROKER vs CONTROLLER**
- Entre brokers, viaja la replicación de tópicos (datos). Es el grueso del tráfico.
- Entre controllers, viaja el log de metadatos (raft). Es bajo volumen pero crítico.
- Separarlos permite, por ejemplo, usar TLS/SASL solo en CONTROLLER si quieres asegurar el plano de control sin pagar el costo de cifrado en el plano de datos.

**Listener apropiado por origen del cliente**
- Cliente en otro broker dentro de Docker → `INTER_BROKER` (PLAINTEXT)
- Cliente en el quorum (controller) → `CONTROLLER`
- Productor o consumidor desde el host → `EXTERNAL`

---

*Soluciones del desafío - Lab 03*
