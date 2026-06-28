# Parte 1: Schema Registry

## Objetivo

Entender por qué los schemas son críticos en Kafka, cómo Schema Registry los gestiona y los modos de compatibilidad. Registrar schemas, evolucionarlos, y verificar empíricamente qué cambios son seguros.

## Contexto

Recuerda el problema del CTO:
> *"Los equipos de analytics, fulfillment y notificaciones cada uno consume el tópico `pedidos`, pero no se pusieron de acuerdo en el formato. Cada cambio rompe a alguien."*

**Schema Registry** resuelve esto:
- Cada productor publica con un **schema** (Avro, JSON Schema, o Protobuf).
- El schema se registra en SR y queda asociado al tópico vía un "subject".
- Los consumers leen el schema desde SR para deserializar.
- SR **rechaza schemas que rompan compatibilidad** según la política configurada.

---

## Arquitectura

```
[Productor]                                        [Consumer]
     ↓ 1. envía mensaje + ID schema                     ↑
[Tópico Kafka] ←─ binario Avro + ID                    │
     ↑                                                  │
     │ 2. registra/lee schema por ID         5. consulta schema por ID
     ↓                                                  │
[Schema Registry] ←──────────────────────────────────── ↑
     ↑
     │ 3. Compatibility check (BACKWARD, FORWARD, FULL)
     ↓
[Subjects: pedidos-value, clientes-value, ...]
```

**Subject naming convention** (default `TopicNameStrategy`):
- `<topic>-value` para el schema del valor
- `<topic>-key` para el schema de la key

---

## Compatibility modes

| Modo | Permite agregar campos | Permite eliminar campos | Caso de uso |
|------|------------------------|-------------------------|-------------|
| **BACKWARD** (default) | Sí, con default | Sí, si era opcional | Consumers nuevos pueden leer datos viejos |
| **FORWARD** | Sí, si era opcional | Sí, con default | Consumers viejos pueden leer datos nuevos |
| **FULL** | Solo cambios compatibles ambas direcciones | | Máxima seguridad |
| **NONE** | Cualquier cambio | | Solo dev local |

---

## Actividad 1: Estado inicial

```bash
schema-cli/list-subjects.sh
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué subjects hay? | |

Esperado: `[]` (lista vacía al inicio).

---

## Actividad 2: Registrar el schema v1 de pedido

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué `id` devolvió SR? | |

Verifica:
```bash
schema-cli/list-subjects.sh
schema-cli/get-schema.sh novatech.lab10.pedidos-value
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece el subject? | |
| ¿Qué versión tiene (1, 2, ...)? | |

---

## Actividad 3: Probar compatibilidad con v2 (compatible)

El schema v2 agrega un campo opcional `prioridad` con `default: null` → debería ser BACKWARD compatible.

```bash
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v2-compatible.avsc
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Respuesta de SR | |
| ¿Es compatible? | |

Si es compatible, regístralo:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido-v2-compatible.avsc
```

```bash
schema-cli/get-schema.sh novatech.lab10.pedidos-value
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál es la versión actual? | |

---

## Actividad 4: Probar compatibilidad con v3 (INCOMPATIBLE)

El schema v3 agrega un campo OBLIGATORIO `tarjeta_credito` SIN default. Esto rompe BACKWARD: un consumer viejo que lea datos nuevos NO sabría qué hacer con un campo que no espera, pero el problema real es que un consumer NUEVO leyendo datos viejos no encontrará `tarjeta_credito` y faltará el dato.

```bash
schema-cli/check-compatibility.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

| Pregunta | Tu respuesta |
|----------|-------------|
| Respuesta de SR | |
| ¿Es compatible? | |
| ¿Por qué NO es compatible? | |

Intenta registrarlo (debería FALLAR):

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido-v3-incompatible.avsc
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿SR devolvió error? | |
| ¿Qué código HTTP? | |

---

## Actividad 5: Inspeccionar en Kafbat UI

Abre **http://localhost:8090** > pestaña **Schema Registry**.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `novatech.lab10.pedidos-value`? | |
| ¿Cuántas versiones tiene? | |
| ¿Puedes ver el contenido de cada versión? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría sin Schema Registry? | |
| ¿Cuándo cambiarías de BACKWARD a FORWARD? | |
| ¿Por qué `_schemas` es un tópico Kafka interno? | |

> **Pista**: Sin SR, cada equipo tiene que coordinar manualmente el formato. SR usa un tópico Kafka (`_schemas`) para persistir los schemas con la misma durabilidad que los datos. FORWARD se usa cuando los consumers viejos deben seguir funcionando indefinidamente (mainframes, sistemas legacy).

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Subject naming | `<topic>-value` |
| BACKWARD compatibility | Agregar campo opcional con default = OK |
| Incompatible change | Campo obligatorio sin default = SR rechaza |
| `_schemas` topic | Persistencia automática de SR en Kafka |

---

## Siguiente paso

Continúa con [Parte 2: Avro en acción](02-avro-en-accion.md).
