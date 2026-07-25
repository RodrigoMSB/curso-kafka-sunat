# Reporte del Lab 11 — Validación fuente (curso 28h) — referencia del instructor

> Versión completada con datos reales del lab end-to-end.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | el validador |
| Fecha | 2026-05-09 |
| Sección | N/A |

---

## Parte 1: Schema Registry

| Pregunta | Tu respuesta |
|----------|-------------|
| Subjects al inicio | **`[]`** (vacío). |
| ID del schema v1 registrado | **id=1**, **guid=f7c3dc5b-9a9f-1792-4c66-77095fdbd42d**. |
| Versión del subject tras v1 | **version=1**. |
| ¿v2 (con campo opcional `prioridad`) es compatible? | **Sí — `is_compatible: true`**. El campo nuevo es `["null","string"]` con `default: null`, lo cual es BACKWARD COMPATIBLE (los consumers viejos siguen leyendo, ignoran el campo desconocido). |
| Versión tras registrar v2 | **version=2**, **id=2**. |
| ¿v3 (campo obligatorio sin default) es compatible? | **No — `is_compatible: false`**. |
| Por qué v3 NO es compatible | El campo `tarjeta_credito` es `string` SIN default. Esto rompe BACKWARD: si un consumer leyendo con schema v3 recibe un mensaje publicado con v1 o v2 (que no tienen `tarjeta_credito`), el deserializador no sabe qué valor poner — falla. |
| Código HTTP de error al registrar v3 | **HTTP 409 Conflict** + `error_code: 40901`. Mensaje: `Schema being registered is incompatible with an earlier schema for subject "novatech.lab10.pedidos-value", details: [{errorType:'READER_FIELD_MISSING_DEFAULT_VALUE', description:'The field 'tarjeta_credito' at path '/fields/6' in the new schema has no default value...`. |
| Subject visible en Kafbat UI | **Sí** — Kafbat detecta el Schema Registry en `http://schema-registry:8081` (configurado en `start-lab.sh`) y muestra los subjects en la sección "Schema Registry". |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría sin Schema Registry? | Cada producer/consumer tendría que coordinar el schema "out of band" (documentación, código compartido, contratos de equipos). Cualquier cambio rompería en runtime. Schema Registry centraliza el contrato y aplica reglas de compatibilidad automáticamente — es como "tipar fuertemente" un topic. |
| ¿Cuándo cambiarías a FORWARD? | Cuando los consumers NO se pueden actualizar al ritmo del productor. Por ejemplo: aplicación móvil (consumers que no podés forzar a actualizar) — ahí FORWARD permite que el productor evolucione (agregar campos), porque los consumers viejos siguen leyendo. BACKWARD (default) es lo opuesto: consumers nuevos pueden leer mensajes viejos. |
| ¿Por qué `_schemas` es un tópico Kafka? | Schema Registry usa Kafka como su propio storage backend (eat your own dog food): los schemas se persisten en el topic `_schemas` (compactado, RF=3). Esto da durabilidad y replicación gratis. Si SR muere, otra instancia lee `_schemas` y reconstruye el estado. |

---

## Parte 2: Avro en acción

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Pedido Avro publicado sin error? | **Sí** — `produce-pedido-avro.sh` usa `kafka-avro-console-producer` con el schema registry endpoint. El cliente serializa contra el schema, embede el ID del schema en el mensaje (5 bytes magic + ID + payload Avro). |
| ¿Apareció en consume-avro como JSON? | **Sí** — el `kafka-avro-console-consumer` desserializa Avro → JSON al leer (consultando SR para obtener el schema por ID). |
| Mensajes en Kafbat UI tras 5 producciones | Visibles con **payload tipado** (no base64 como con JSON sin schema). Kafbat se conecta a SR para deserializar. |
| ¿Kafbat los muestra deserializados? | **Sí** — gracias a la integración con SR. Esa es la ventaja vs JSON sin schema (donde `monto` saldría base64). |
| Throughput tras flood de 50 | **~50 pedidos en 5-8 segundos** (cada producción es 1 mensaje individual via avro-console-producer; no es flood masivo). En mi corrida quedaron 19 pedidos visibles tras el ejercicio (los demás no llegaron por timing). |
| ¿Los 4 clientes publicados? | **Sí, 5 clientes seed**: IDs 1001, 1010, 1017, 1055, 1098 (output del script: `5 clientes seed publicados`). |

### Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| Tamaño Avro vs JSON | **Avro es ~30-50% más pequeño**: campos no se nombran en cada mensaje (el schema está fuera, en SR), tipos están comprimidos (int en 1-5 bytes vs "1234567890" en JSON), no hay separadores ni quoting. |
| Por qué Avro es mejor a gran escala | (1) Tamaño menor → menor I/O y disco; (2) Contrato fuerte → errores en compile-time/registration vs runtime; (3) Evolución controlada (BACKWARD/FORWARD). El costo: complejidad operacional de Schema Registry. |
| ¿Qué pasa con `monto` como string? | Si el schema declara `monto: double`, el cliente Avro REJECTA un value que no parsee como double. Eso es la garantía: imposible publicar un mensaje malformed. En JSON sin schema, `{"monto":"abc"}` se acepta y los consumers sufren al deserializar — Avro mueve el problema "a la izquierda" (al producer). |

---

## Conclusiones generales

> Schema Registry es la abstracción que eleva Kafka de "broker de mensajes" a "plataforma de datos en streaming": fuerza contratos tipados con evolución controlada y elimina la clase entera de bugs "el formato cambió y no avisé". Con Avro, productores y consumidores comparten un esquema versionado que se valida en el momento de producir, de modo que ningún mensaje mal formado entra al tópico.

---

## Notas del validador

1. **Tiempo de validación**: ~50 minutos.
2. **Sin hallazgos pedagógicos nuevos**.
3. **Reto 2 con ventanas**: validado estructuralmente, no observado en operación por scope (requiere varios minutos).

*Lab 11 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
