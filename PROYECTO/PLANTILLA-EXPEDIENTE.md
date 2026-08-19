# Expediente técnico · Proyecto final

## Administración integral del clúster de eventos de NovaTech Logistics

---

**Alumno:** [tu nombre completo]
**Curso:** Administración de Confluent Apache Kafka · 24 horas
**Fecha de entrega:** [fecha]

---

> **Cómo usar esta plantilla**
>
> Todo lo que está entre corchetes `[…]` lo escribes tú. El resto es la estructura, que sigue el mismo orden en que se evalúa el proyecto.
>
> Cuando termines, exporta a PDF y borra este recuadro.
>
> Si no sabes cuánto escribir en una sección, mira `EJEMPLOS-DE-RESPUESTA.md`.

---
---

# 1 · Resumen ejecutivo

*Media página. Qué construiste, en una lectura de dos minutos. Escríbelo al final, cuando ya tengas todo lo demás.*

[Describe en un párrafo qué plataforma construiste para NovaTech: cuántos nodos, en qué modo, qué componentes del ecosistema, y qué garantías ofrece en cuanto a resiliencia, durabilidad y seguridad.]

[En un segundo párrafo, di qué es lo más sólido de tu implementación y qué quedaría pendiente para un despliegue productivo real.]

---
---

# 2 · Hito 1 · Diseño de la arquitectura

## 2.1 Topología del clúster

[Inserta aquí tu diagrama. Tiene que mostrar los brokers, los controladores, los tópicos principales y los componentes del ecosistema que elegiste.]

**Descripción:**

[Explica el diagrama en un párrafo. Qué hay, cómo se conecta, y qué rol cumple cada pieza.]

## 2.2 Componentes del ecosistema seleccionados

| Componente | ¿Lo incluyes? | Justificación |
|---|---|---|
| Schema Registry | [sí / no] | [por qué] |
| Kafka Connect | [sí / no] | [por qué] |
| REST Proxy | [sí / no] | [por qué] |
| ksqlDB | [sí / no] | [por qué] |
| Interfaz de administración | [sí / no] | [por qué] |

> **Ojo:** decir «no» a un componente con una buena razón vale tanto como decir «sí». Lo que se evalúa es el criterio, no la cantidad.

## 2.3 Dimensionamiento

| Decisión | Valor | Justificación |
|---|---|---|
| Número de brokers | [ ] | [por qué ese número y no otro] |
| Número de controladores | [ ] | [por qué] |
| Modo de operación | [combinado / separado] | [por qué] |
| Particiones por tópico principal | [ ] | [según qué carga estimada] |
| Factor de replicación | [ ] | [por qué] |

## 2.4 Tópicos definidos

| Tópico | Particiones | Réplicas | Política de retención | Para qué sirve |
|---|---|---|---|---|
| [nombre] | [ ] | [ ] | [ ] | [ ] |
| [nombre] | [ ] | [ ] | [ ] | [ ] |
| [nombre] | [ ] | [ ] | [ ] | [ ] |

---
---

# 3 · Hito 2 · Despliegue en KRaft y resiliencia

## 3.1 El clúster desplegado

[Describe cómo quedó desplegado: qué nodos, qué identidad de clúster, cómo se formó el quórum.]

**Evidencia:** `evidencias/hito-2/quorum-inicial.txt`

[Pega aquí la parte relevante de la salida, o resume qué muestra.]

**Qué demuestra esta salida:**

[Explica qué campos leíste y qué significan. No basta con pegar la salida: hay que decir qué prueba.]

## 3.2 La prueba de resiliencia

**Qué hice:**

[Describe el procedimiento: qué nodo detuviste, por qué elegiste ese, y qué esperabas que pasara.]

**Estado antes de la caída:**

[Resume qué mostraban `quorum-inicial.txt` y `topico-antes.txt`.]

**Estado después de la caída:**

[Resume qué cambió en `quorum-tras-caida.txt` y `topico-tras-caida.txt`. Nombra los campos concretos.]

**La recuperación:**

[Qué pasó al devolver el nodo. Cuánto tardó en ponerse al día.]

## 3.3 Conclusión del hito

[Una afirmación clara sobre qué tolera tu clúster y qué no. Sé específico: «tolera la caída de un nodo» es distinto de «tolera fallas».]

---
---

# 4 · Hito 3 · Configuración y rendimiento

## 4.1 Operación multi-broker

[Cómo quedó configurada la operación con varios brokers y cómo se reparten el trabajo.]

## 4.2 Tópicos con sus políticas

[Explica por qué cada tópico tiene la configuración que tiene. Aquí lo que se evalúa es que las decisiones respondan a necesidades distintas, no que todos estén configurados igual.]

**Evidencias:** `evidencias/hito-3/topico-*.txt`

| Tópico | Configuración distintiva | Por qué |
|---|---|---|
| [nombre] | [ej: retention.ms=3600000] | [ ] |
| [nombre] | [ej: retention.ms=-1] | [ ] |
| [nombre] | [ej: cleanup.policy=compact] | [ ] |

## 4.3 Conectividad resuelta

[Explica la diferencia entre los listeners y los advertised.listeners de tu clúster, y qué problema resuelve esa configuración.]

**Evidencia:** `evidencias/hito-3/listeners.txt`

## 4.4 Ajuste de rendimiento

**Medición base:**

| Métrica | Valor |
|---|---|
| Throughput (msg/s) | [ ] |
| Throughput (MB/s) | [ ] |
| Latencia p50 | [ ] |
| Latencia p95 | [ ] |
| Latencia p99 | [ ] |

**Qué parámetro ajusté y por qué:**

[Un solo parámetro. Explica qué esperabas que pasara.]

**Medición después del ajuste:**

| Métrica | Antes | Después | Diferencia |
|---|---|---|---|
| Throughput (msg/s) | [ ] | [ ] | [ ] |
| Latencia p99 | [ ] | [ ] | [ ] |

**Interpretación:**

[Qué mejoró, qué empeoró, y si el intercambio vale la pena para el caso de NovaTech.]

---
---

# 5 · Hito 4 · Seguridad, alta disponibilidad y operación

## 5.1 Cifrado en tránsito

[Cómo quedó configurado TLS. Qué listener lo exige.]

**Evidencia:** `evidencias/hito-4/pki-generada.txt`

## 5.2 Autenticación

[Qué mecanismo SASL usaste y qué principales definiste.]

## 5.3 Autorización

[Qué ACLs definiste y con qué criterio.]

**Evidencia:** `evidencias/hito-4/acls.txt`

| Principal | Puede hacer | Sobre qué recurso |
|---|---|---|
| [ ] | [ ] | [ ] |
| [ ] | [ ] | [ ] |

## 5.4 Pruebas negativas

> Esta sección vale mucho. Demuestra que la seguridad **rechaza** lo que tiene que rechazar.

**Rechazo por falta de credenciales:**

[Qué intentaste, qué pasó, y qué capa lo detuvo.]

**Rechazo por falta de permiso:**

[Qué intentaste, qué pasó, y en qué se diferencia del caso anterior.]

**La diferencia entre ambos:**

[Explica en tus palabras la diferencia entre autenticación y autorización, usando tus dos casos como ejemplo.]

## 5.5 Alta disponibilidad

| Configuración | Valor | Qué garantiza |
|---|---|---|
| `min.insync.replicas` | [ ] | [ ] |
| `acks` en el productor | [ ] | [ ] |
| Factor de replicación | [ ] | [ ] |

[Explica cómo se combinan esos tres valores. Uno solo no garantiza nada.]

## 5.6 Plan de recuperación ante desastres

**Escenarios cubiertos:**

| Escenario | ¿Cubierto? | Cómo se recupera |
|---|---|---|
| Caída de un broker | [ ] | [ ] |
| Caída de dos brokers | [ ] | [ ] |
| Pérdida del sitio completo | [ ] | [ ] |
| Corrupción de datos | [ ] | [ ] |

**Drill ejecutado:**

[Describe la prueba de recuperación que hiciste y su resultado.]

**Evidencia:** `evidencias/hito-4/sin-perdida.txt`

**Objetivos pendientes de definir con el negocio:**

[Qué cifras necesitarías del negocio para completar el plan.]

## 5.7 Runbook de operación

*Un runbook es la hoja que consulta quien está de turno cuando algo falla. Corto y accionable.*

| Situación | Cómo se detecta | Qué hacer |
|---|---|---|
| Un broker no responde | [ ] | [ ] |
| El ISR está incompleto | [ ] | [ ] |
| Los productores reciben errores de escritura | [ ] | [ ] |
| El disco de datos se está llenando | [ ] | [ ] |

---
---

# 6 · Preguntas de reflexión

> Estas seis preguntas son parte de la evaluación. Consulta `EJEMPLOS-DE-RESPUESTA.md` para ver la profundidad esperada — pero escribe con tus propios datos.

## 6.1 ¿Qué enfoque usarías para dimensionar el quórum de controladores de NovaTech y por qué?

[Tu respuesta]

## 6.2 ¿Qué afirmaciones del resultado obtenido respaldan que tu clúster tolera la caída de un nodo?

[Tu respuesta]

## 6.3 ¿Cómo comprobarías que la configuración de retención y replicación cumple los objetivos de durabilidad?

[Tu respuesta]

## 6.4 ¿Qué aspectos seleccionarías para demostrar que el ajuste de rendimiento tuvo efecto?

[Tu respuesta]

## 6.5 ¿Cómo determinarías que las políticas de seguridad aplicadas protegen efectivamente la plataforma?

[Tu respuesta]

## 6.6 ¿Cómo valorarías la preparación de NovaTech ante un desastre a partir de tu plan de recuperación?

[Tu respuesta]

---
---

# 7 · Anexo · Índice de evidencias

*Para que quien evalúa encuentre cada archivo sin abrir el ZIP a ciegas.*

| Archivo | Qué demuestra | Hito |
|---|---|---|
| [nombre-del-archivo] | [ ] | [ ] |
| [nombre-del-archivo] | [ ] | [ ] |
| [nombre-del-archivo] | [ ] | [ ] |

---

# 8 · Declaración de origen de los archivos de configuración

*Durante el curso algunos laboratorios se construyen y otros se demuestran. Las dos formas valen. Solo hay que declararlo.*

| Archivo de configuración | Origen |
|---|---|
| `hito-2-kraft/docker-compose.yml` | [construido por mí / tomado de soluciones/] |
| `hito-3-multibroker/docker-compose.yml` | [ ] |
| `hito-4-seguridad/docker-compose.yml` | [ ] |
