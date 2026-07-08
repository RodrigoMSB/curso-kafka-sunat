# Guion de Slides — Capítulo 4: Ecosistema de clientes, REST y esquemas

**Curso:** Administración de Confluent Apache Kafka (SUNAT)
**Sesiones cubiertas:** 4 bloques teóricos (escalamiento y tuning · clientes Java/Spring · REST Proxy · Schema Registry) + 3 prácticos (Labs 09, 10, 11)
**Narrativa:** NovaTech Logistics — Plataforma de eventos de la flota
**Estado:** Guion de contenido. Pendiente vertido a template Netec.

**Convenciones de este guion:**
- `S#` = número de slide propuesto.
- **Contenido** = bullets que van en la slide (español neutro, alumno). Conceptos fuertes, no párrafos.
- **Nota** = nota del orador (qué decir, énfasis, anécdotas).
- **Diagrama [ANCLA]** = diagrama que SÍ va renderizado en la PPT.
- **[PIZARRA]** = el instructor lo dibuja en vivo; slide limpia con el concepto.
- **[LAB]** = slide puente que enmarca un laboratorio ya construido; anuncia el práctico, no lo desarrolla.

**Nota de estructura:** primera mitad de la Unidad 4. Presupuesto: ~15 slides teóricas + 3 puente de lab.

---

## APERTURA

**S1 — Portada del capítulo**
- Contenido: "Capítulo 4 · Ecosistema de clientes, REST y esquemas". Objetivos a la derecha.
- Nota: Encuadre: "ya operan un clúster de punta a punta. Ahora lo rodeamos de su ecosistema: cómo se conectan las aplicaciones reales, cómo se gobierna la forma de los datos". Retomar el diagrama de capas del Cap 1 (S22) mostrando qué anillos abrimos ahora.

---

## BLOQUE A — Escalamiento y tuning de productor/consumidor

**S2 — Cómo escala Kafka: particiones y grupos**
- Contenido: El paralelismo de consumo está atado a las particiones: un consumer group reparte las particiones entre sus miembros, y **una partición la lee un solo miembro del grupo a la vez**. Más particiones = más paralelismo posible; más consumidores que particiones = miembros ociosos.
- Nota: Regla dura que hay que fijar: el número de particiones es el techo del paralelismo de un grupo. Analogía ancla — **las cajas de peaje de una autopista**: cada caja (partición) atiende un auto a la vez; sumar cobradores (consumidores) más allá del número de cajas no acelera nada — sobran cobradores mirando. Dimensionar particiones es dimensionar el peaje.
- Diagrama [ANCLA]: un tópico de 4 particiones con un grupo de 4 consumidores (balance perfecto), luego 6 consumidores (2 ociosos), luego 2 consumidores (cada uno lee 2 particiones). Los tres escenarios.

**S3 — Las perillas del productor y del consumidor**
- Contenido: Productor: `acks` (durabilidad), `batch.size`/`linger.ms` (throughput vs latencia), `compression.type`. Consumidor: `fetch.min.bytes`/`max.poll.records` (cuánto trae por viaje), `enable.auto.commit` (cómo confirma offsets). Cada perilla es un trade-off, no un "más es mejor".
- Nota: Retomar la tríada de durabilidad del Cap 1 (acks/RF/min.ISR). Aquí se suman las perillas de rendimiento del cliente. El mensaje: no hay configuración universal; se calibra según si el caso prioriza latencia, throughput o durabilidad.

**S4 — Rebalanceo: cuando el grupo se reorganiza**
- Contenido: Cuando un consumidor entra o sale del grupo, Kafka **rebalancea**: redistribuye las particiones entre los miembros vivos. Durante el rebalanceo hay una pausa breve. Estrategias modernas (cooperative sticky) minimizan la interrupción.
- Nota: Aterrizar el dolor operativo: un rebalanceo mal manejado (consumidores que entran y salen constantemente) genera "rebalance storms". Analogía — **repartir de nuevo las mesas entre los mozos cuando entra o sale uno**: necesario, pero si pasa cada dos minutos, nadie atiende bien. Sembrar que las particiones del productor y el grupo del consumidor trabajan juntos.

---

## BLOQUE B — Clientes Java y Spring  →  Lab 09

**S5 — De la CLI al código: el cliente Java**
- Contenido: Las herramientas de consola fueron para aprender; las aplicaciones reales usan la librería `kafka-clients`. Un `KafkaProducer` envía registros; un `KafkaConsumer` los lee en un loop de `poll()`. La configuración que vieron en CLI ahora son propiedades del cliente en código.
- Nota: Puente natural: "todo lo que hicieron con `kafka-console-*` tiene su equivalente programático". Para esta audiencia (muchos con background de desarrollo o infra), el salto es cómodo. Mencionar que la versión de `kafka-clients` debe alinear con el broker (4.2).

**S6 — Spring for Apache Kafka: el cliente con superpoderes**
- Contenido: Spring Kafka abstrae el boilerplate: `KafkaTemplate` para producir, `@KafkaListener` para consumir, gestión de serialización, reintentos y transacciones declarativas. Menos código repetitivo, más foco en la lógica de negocio.
- Nota: Analogía ancla — **conducir con caja automática vs manual**: `kafka-clients` es la caja manual (control total, más trabajo); Spring Kafka es la automática (productiva, ergonómica, con asistencias). Ambas llegan al mismo lugar; se elige según el contexto. Nota técnica honesta: Spring Boot moderno (4.x) usa Jackson 3 y exige cuidar la serialización de tipos — se ve en el lab.
- Diagrama [ANCLA]: dos columnas — el mismo "producir un evento" en kafka-clients (varias líneas de setup) vs Spring (`kafkaTemplate.send(...)`), mostrando la diferencia de ergonomía.

**S7 — [LAB] Lab 09 · Clientes Java y Spring**
- Contenido:
  - **Objetivo**: producir y consumir mensajes programáticamente con `kafka-clients` y Spring for Apache Kafka.
  - **Vas a hacer**: escribir un productor y un consumidor, configurar serialización, y comparar el enfoque nativo con el de Spring.
  - **Entorno**: Java 21 · Maven · kafka-clients 4.2 · Spring Boot 4.x.
- Nota: El primer lab con código del curso. La "caja manual vs automática" (S6) hecha realidad. Advertir el detalle de serialización de tipos con Jackson 3 (el `ADD_TYPE_INFO_HEADERS`). Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE C — REST Proxy  →  Lab 10

**S8 — REST Proxy: Kafka para el resto del mundo**
- Contenido: No toda aplicación puede o quiere incrustar un cliente Kafka nativo. El **Confluent REST Proxy** expone Kafka sobre HTTP: producir es un `POST`, consumir es un `GET`. Cualquier lenguaje con un cliente HTTP puede hablar con Kafka.
- Nota: Retomar del Cap 1 (Kafka para quien no habla protocolo Kafka). Analogía ancla — **el traductor en una reunión internacional**: los delegados que no hablan el idioma común (protocolo Kafka nativo) hablan con el traductor (REST Proxy) en su propio idioma (HTTP), y el traductor transmite. Cómodo, pero cada traducción cuesta tiempo — por eso no es para alto throughput.
- Diagrama [ANCLA]: cliente HTTP → REST Proxy (traduce) → Kafka. Al lado, cliente nativo → Kafka directo. Mostrar la capa extra de traducción y su costo.

**S9 — Exploración visual del clúster (Kafbat UI)**
- Contenido: Para inspeccionar tópicos, mensajes, consumer groups y offsets sin línea de comandos, se usa una UI de exploración. El temario nombra "Landoop"; el curso usa **Kafbat UI**, su reemplazo activo y compatible con Kafka 4.x (ADR-001).
- Nota: Transparencia técnica que esta audiencia valora: por qué el cambio (Landoop quedó descontinuado). Es la misma UI que ya usaron para observar retención en el Lab 05 — aquí se formaliza como herramienta de operación.

**S10 — [LAB] Lab 10 · REST Proxy y exploración visual**
- Contenido:
  - **Objetivo**: exponer Kafka por HTTP con el REST Proxy y explorar el clúster visualmente.
  - **Vas a hacer**: producir y consumir vía llamadas REST, y navegar tópicos/mensajes/consumidores en la UI.
  - **Entorno**: Docker Compose · Kafka 4.2 · Confluent REST Proxy · Kafbat UI.
- Nota: El "traductor" (S8) en acción. Contrastar el esfuerzo de producir por REST vs por cliente nativo. Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE D — Schema Registry  →  Lab 11

**S11 — El problema: los datos cambian de forma**
- Contenido: Un productor y un consumidor acuerdan tácitamente la forma de los eventos. Pero el productor evoluciona: agrega un campo, cambia un tipo, renombra algo. Si el consumidor no está preparado, se rompe en producción — silenciosamente, a veces. ¿Quién protege ese contrato?
- Nota: Plantear el dolor antes de la solución. Ejemplo NovaTech: el equipo de GPS agrega un campo `altitud` a sus eventos; el consumidor de facturación, que no lo espera, falla al deserializar. Multiplicado por decenas de equipos, es el caos. Este es el problema que Schema Registry resuelve.

**S12 — Schema Registry: el notario de los contratos**
- Contenido: El Schema Registry guarda y versiona los esquemas de los datos (Avro/JSON/Protobuf). Antes de publicar, valida que el nuevo esquema sea **compatible** con el anterior según una política: BACKWARD, FORWARD o FULL. Si rompe el contrato, lo rechaza.
- Nota: Retomar la analogía del Cap 1 (el notario de los datos) y profundizarla. Los tres modos como tres tipos de garantía:
  - **BACKWARD**: los consumidores nuevos leen datos viejos (puedo evolucionar el consumidor primero).
  - **FORWARD**: los consumidores viejos leen datos nuevos (puedo evolucionar el productor primero).
  - **FULL**: ambas cosas (evolución en cualquier orden).
- Diagrama [ANCLA]: los tres modos de compatibilidad como flechas entre "esquema v1" y "esquema v2", mostrando qué dirección de lectura garantiza cada uno. Un cambio incompatible rebotando contra el registro.

**S13 — [LAB] Lab 11 · Schema Registry**
- Contenido:
  - **Objetivo**: registrar esquemas y comprobar los modos de compatibilidad.
  - **Vas a hacer**: registrar un esquema, evolucionarlo de forma compatible, e intentar un cambio incompatible para ver al notario **rechazarlo** en vivo.
  - **El momento clave**: ver el registro impedir la publicación de un mensaje que rompería a los consumidores.
  - **Entorno**: Docker Compose · Kafka 4.2 · Confluent Schema Registry.
- Nota: El notario (S12) haciendo su trabajo. El "aha" es ver el rechazo real de un cambio incompatible — la red de seguridad que un admin serio agradece. Duración ~60 min. Remitir al README y al `90`.

**S14 — Cierre del capítulo**
- Contenido: Síntesis: aprendieron a escalar con particiones y grupos, a conectar aplicaciones reales (Java, Spring, REST), y a gobernar la forma de los datos con Schema Registry. Próximo capítulo: procesamiento de flujos, integración e HA/DR, y el cierre con seguridad.
- Nota: Cierre de la primera mitad de la Unidad 4. Transición al Cap 5: "las aplicaciones ya hablan con Kafka de forma robusta y gobernada; ahora vamos a procesar esos flujos, integrarlos con sistemas externos, y blindar todo con seguridad".

---

## Resumen ejecutivo del guion

| Bloque | Tema | Slides | Lab puente | Diagramas [ANCLA] |
|---|---|---|---|---|
| Apertura | Portada | S1 | — | — |
| A | Escalamiento y tuning | S2–S4 | — | Particiones vs grupo (S2) |
| B | Clientes Java/Spring | S5–S7 | Lab 09 | kafka-clients vs Spring (S6) |
| C | REST Proxy | S8–S10 | Lab 10 | REST Proxy como traductor (S8) |
| D | Schema Registry | S11–S14 | Lab 11 | Modos de compatibilidad (S12) |

**Total Cap 4: 14 slides** (11 teóricas + 3 puente de laboratorio).

**Analogías ancla del capítulo (para pizarra):**
- Las cajas de peaje de una autopista → particiones y paralelismo de consumo (S2).
- Caja automática vs manual → Spring Kafka vs kafka-clients (S6).
- El traductor en una reunión internacional → REST Proxy (S8).
- El notario de los contratos → Schema Registry y sus modos (S12).

**Diagramas [ANCLA] a renderizar (4):** S2, S6, S8, S12.
**Todo lo demás marcado [PIZARRA]:** el instructor lo dibuja en clase.

**Slides puente de laboratorio (3):** S7 (Lab 09), S10 (Lab 10), S13 (Lab 11) — enmarcan prácticos ya construidos y validados.

**Pendientes que este guion deja registrados:**
1. Vertido a template Netec.
2. Los 4 diagramas ANCLA a renderizar en la fase visual.
3. Confirmar contra el material real de cada lab los nombres exactos de scripts/versiones al armar las slides puente (kafka-clients 4.2, Spring Boot 4.x, detalle Jackson 3).
