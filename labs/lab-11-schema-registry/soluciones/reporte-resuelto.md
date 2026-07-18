# Lab 11 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Parte 1: Schema Registry

### Respuestas esperadas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Subjects al inicio | `[]` |
| ID schema v1 | Un entero, típicamente 1 |
| Versión tras v1 | 1 |
| ¿v2 compatible? | Sí (`{"is_compatible": true}`) |
| Versión tras v2 | 2 |
| ¿v3 compatible? | NO (`{"is_compatible": false}`) |
| Por qué v3 NO | Agrega campo OBLIGATORIO sin default. Un consumer leyendo datos producidos con v1 no encontraría `tarjeta_credito` y no sabe qué default usar. Rompe BACKWARD compatibility |
| Código HTTP error | 409 Conflict (Incompatible schema) |

### Reflexión

- **Sin SR**: cada equipo coordina manualmente; cualquier cambio en formato requiere comunicarse con TODOS los consumers. SR centraliza el contrato.
- **Cuándo FORWARD**: cuando consumers viejos NO se pueden actualizar (mainframes legacy, apps de terceros). Permite agregar campos siempre que tengan default razonable.
- **`_schemas` tópico**: SR usa Kafka como su backing store. Mismas garantías de durabilidad y replicación que los datos.

---

## Parte 2: Avro

### Respuestas esperadas

| Pregunta | Respuesta esperada |
|----------|-------------------|
| Pedido Avro publicado | Sí |
| Aparece en consume-avro como JSON | Sí (kafka-avro-console-consumer deserializa) |
| 5 mensajes en Kafbat UI | Sí |
| Kafbat los muestra como JSON | Sí (integración con SR) |
| Throughput flood 50 | Variable, ~5-30 msg/seg en local |
| 4 clientes publicados | Sí |

### Reflexión

- **Avro vs JSON**: Avro ~30-50% del tamaño de JSON equivalente. La razón: schema separado, no se repiten nombres de campos en cada mensaje.
- **Por qué a gran escala**: menos bytes en red + disco + memoria. A 1M msg/seg, la diferencia es enorme.
- **Monto como string**: el producer Avro lo rechaza ANTES de publicar, validando contra el schema. Sin SR, llegaría al tópico y rompería consumers downstream.

---

*Solución - Lab 11*
