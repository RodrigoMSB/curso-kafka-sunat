# Guion de Slides — Capítulo 5: Procesamiento, integración, HA/DR y seguridad

**Curso:** Administración de Confluent Apache Kafka (SUNAT)
**Sesiones cubiertas:** 3 bloques teóricos (ksqlDB · Kafka Connect · observabilidad y alta disponibilidad) + 3 prácticos (Lab 12 ksqlDB · Lab 13 Connect · Lab 14 Capstone de resiliencia y seguridad)
**Narrativa:** NovaTech Logistics — Plataforma de eventos de la flota
**Estado:** Guion de contenido. Pendiente vertido a template Netec.

**Convenciones de este guion:**
- `S#` = número de slide propuesto.
- **Contenido** = bullets que van en la slide (español neutro, alumno). Conceptos fuertes, no párrafos.
- **Nota** = nota del orador (qué decir, énfasis, anécdotas).
- **Diagrama [ANCLA]** = diagrama que SÍ va renderizado en la PPT.
- **[PIZARRA]** = el instructor lo dibuja en vivo; slide limpia con el concepto.
- **[LAB]** = slide puente que enmarca un laboratorio ya construido; anuncia el práctico, no lo desarrolla.

**Nota de estructura:** segunda mitad de la Unidad 4 y cierre del curso. El capstone (Lab 14) integra seguridad TLS/SASL/ACL + failover. Presupuesto: ~15 slides teóricas + 3 puente de lab.

---

## APERTURA

**S1 — Portada del capítulo**
- Contenido: "Capítulo 5 · Procesamiento, integración, HA/DR y seguridad". Objetivos a la derecha.
- Nota: Encuadre del cierre: "última unidad. Vamos a procesar los flujos en movimiento, a integrarlos con el mundo exterior, a observar y blindar el clúster, y a cerrar con un capstone que junta todo". Retomar el diagrama de capas del Cap 1: encendemos los anillos que faltan.

---

## BLOQUE A — ksqlDB: procesamiento de flujos  →  Lab 12

**S2 — Del evento suelto al flujo con sentido**
- Contenido: Hasta ahora movimos eventos. Procesarlos en tiempo real —filtrar, agrupar, unir, agregar— tradicionalmente exigía escribir aplicaciones. **ksqlDB** permite hacerlo con SQL: consultas que corren para siempre sobre flujos en movimiento.
- Nota: El salto conceptual: de transportar datos a transformarlos en vuelo. Para esta audiencia (que conoce SQL), el gancho es inmediato: "el SQL que ya saben, aplicado a datos que nunca dejan de llegar".

**S3 — STREAM vs TABLE: la película y la foto**
- Contenido: Un **STREAM** es la secuencia completa de eventos (cada hecho, en orden): la historia. Una **TABLE** es el estado actual derivado de esos eventos (el último valor por clave): el ahora. Uno cuenta cómo se llegó; el otro, dónde se está.
- Nota: Analogía ancla — **el extracto bancario vs el saldo**. El STREAM es el extracto: cada movimiento, línea por línea, en orden. La TABLE es el saldo: un solo número que resume todos los movimientos hasta ahora. Y lo profundo: el saldo se **reconstruye** sumando el extracto — una TABLE es un STREAM colapsado por clave. Retomar "foto vs película" del Cap 1 y profundizarla.
- Diagrama [ANCLA]: un STREAM de eventos (depósitos y retiros de una cuenta) a la izquierda; a la derecha, la TABLE (saldo actual) que resulta de agregarlos. La flecha que muestra la reconstrucción.

**S4 — Consultas persistentes: SQL que no termina**
- Contenido: Una consulta normal responde una vez y termina. Una **consulta persistente** de ksqlDB corre indefinidamente: cada evento nuevo que llega la reevalúa y actualiza su resultado. `CREATE STREAM ... AS SELECT ...` define una transformación que vive mientras el flujo viva.
- Nota: El cambio mental para quien viene de bases de datos: aquí la consulta no es un evento puntual, es un proceso continuo. Ejemplo NovaTech: una consulta que detecta en vivo vehículos que exceden velocidad, alimentando el sistema de anomalías. Sembrar el Lab 12.

**S5 — [LAB] Lab 12 · ksqlDB**
- Contenido:
  - **Objetivo**: consultar y transformar flujos en tiempo real con SQL; trabajar STREAM, TABLE y consultas persistentes.
  - **Vas a hacer**: crear streams sobre tópicos de la flota, derivar tablas de estado, y escribir una consulta persistente que transforme datos en vivo.
  - **Entorno**: Docker Compose · Kafka 4.2 · ksqlDB.
- Nota: El "extracto vs saldo" (S3) hecho consultas. El momento revelador: ver una TABLE actualizarse sola cada vez que llega un evento al STREAM. Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE B — Kafka Connect: integración  →  Lab 13

**S6 — El problema de la integración: Kafka no vive solo**
- Contenido: Los datos valiosos suelen nacer fuera de Kafka (bases de datos, sistemas legados) y deben terminar fuera (data warehouses, índices de búsqueda). Escribir integradores a mano para cada sistema es repetitivo y frágil. **Kafka Connect** industrializa ese movimiento.
- Nota: Retomar del Cap 1 (Connect = el equipo de mudanzas). Aquí el foco es el problema de fondo: sin Connect, cada integración es código artesanal que alguien debe mantener. Con Connect, es configuración.

**S7 — Source, Sink, workers y tasks**
- Contenido: Un **Source connector** trae datos hacia Kafka; un **Sink connector** los lleva desde Kafka hacia afuera. Los **workers** son los procesos que ejecutan connectors; las **tasks** son las unidades de paralelismo dentro de un connector. Todo configurable, sin escribir código de integración.
- Nota: Analogía ancla — **una cinta transportadora de aeropuerto**: el source es la cinta que trae las maletas al sistema (facturación → Kafka); el sink es la que las entrega en destino (Kafka → recogida). Los workers son los motores; las tasks, los tramos paralelos de cinta. Nadie carga maletas a mano.
- Diagrama [ANCLA]: BD externa → Source connector → Kafka → Sink connector → sistema destino. Con workers/tasks marcados como la maquinaria que mueve la cinta.

**S8 — CDC: capturar cambios sin tocar la fuente**
- Contenido: Un caso estrella de Source es **Change Data Capture**: capturar los cambios de una base de datos (inserts, updates, deletes) y publicarlos como eventos en Kafka, casi sin impactar la BD origen. El sistema legado sigue operando; sus cambios fluyen a Kafka en tiempo real.
- Nota: Aterrizar en NovaTech: el core legado de la flota vive en una base de datos relacional; CDC lleva cada cambio a Kafka sin que el equipo legado modifique nada. Es la forma moderna de integrar lo viejo con lo nuevo. Sembrar el Lab 13.

**S9 — [LAB] Lab 13 · Kafka Connect**
- Contenido:
  - **Objetivo**: desplegar Kafka Connect e implementar una integración de datos entre Kafka y un sistema externo.
  - **Vas a hacer**: configurar workers, desplegar un connector (source y/o sink), gestionar tasks y offsets, y ver datos fluir sin código de integración.
  - **Entorno**: Docker Compose · Kafka 4.2 · Kafka Connect.
- Nota: La "cinta transportadora" (S7) en operación. Enfatizar: cero código de integración, todo configuración declarativa. Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE C — Observabilidad y alta disponibilidad

**S10 — Observar el clúster: qué mirar y con qué**
- Contenido: Un clúster en producción se vigila: salud de brokers, throughput, **consumer lag** (cuánto se atrasan los consumidores), estado del ISR. Las herramientas: Control Center (consola Confluent), y la dupla **Prometheus** (recolecta métricas) + **Grafana** (las visualiza).
- Nota: El consumer lag es la métrica reina para un admin de Kafka: mide si los consumidores siguen el ritmo de producción. Analogía ancla — **el tablero de un avión**: no vuelas mirando por la ventana; miras altímetro, velocidad y combustible. Prometheus son los sensores; Grafana, el tablero; el consumer lag, el indicador de combustible que nunca dejas de vigilar.
- Diagrama [ANCLA]: brokers → exponen métricas → Prometheus (recolecta) → Grafana (dashboard). El consumer lag destacado como el indicador crítico.

**S11 — Alta disponibilidad y recuperación ante desastres**
- Contenido: **HA** (alta disponibilidad) es sobrevivir a fallos locales: réplicas, ISR, `min.insync.replicas`, elección de líder — todo lo que ya conocen. **DR** (recuperación ante desastres) es sobrevivir a la pérdida de un sitio completo: replicar a otro clúster/región. Son capas distintas de resiliencia.
- Nota: Distinguir claramente HA de DR, que se confunden. HA = un broker cae, el clúster sigue (lo vieron en el Cap 2 y en el Lab 08). DR = el data center entero cae, otro clúster toma el relevo. Conectar con el capstone: van a probar el failover de HA en vivo.

**S12 — La tríada de durabilidad, en serio esta vez**
- Contenido: Retomamos `acks` + `replication.factor` + `min.insync.replicas`, pero ahora para configurarla de verdad. La combinación define la garantía: RF=3 + min.ISR=2 + acks=all tolera perder 1 broker sin perder ni un mensaje ni aceptar escrituras inseguras. Bajar cualquiera de las tres relaja la garantía.
- Nota: Este es el pago de la promesa del Cap 1 (la balanza de durabilidad). Aquí se aterriza en números que van a configurar en el capstone. El error que van a provocar: con el ISR bajo el mínimo y acks=all, el productor recibe `NotEnoughReplicasException` — la durabilidad rechazando una escritura insegura. Sembrar el Lab 14.
- Diagrama [ANCLA]: la balanza del Cap 1, ahora con valores concretos — RF=3/min.ISR=2/acks=all en el platillo de durabilidad, y qué pasa cuando el ISR cae a 1.

---

## BLOQUE D — Cierre con seguridad: el Capstone  →  Lab 14

**S13 — Seguridad: las tres preguntas**
- Contenido: Asegurar Kafka responde tres preguntas. **¿El canal es privado?** → TLS (cifra el tráfico). **¿Quién eres?** → SASL (autenticación). **¿Qué puedes hacer?** → ACLs (autorización). Las tres juntas cierran el clúster.
- Nota: Analogía ancla — **la entrada a un edificio corporativo seguro**: el pasillo con cámaras y vidrio blindado es TLS (nadie espía el trayecto); el guardia que verifica tu credencial es SASL (demuestras quién eres); la lista que dice a qué pisos puedes subir es la ACL (qué te está permitido). Te falta una y el edificio no es seguro.
- Diagrama [ANCLA]: las tres capas como puertas sucesivas — canal cifrado (TLS) → identidad verificada (SASL) → permisos comprobados (ACL) → acceso al recurso. Un intento sin permiso rebotando en la tercera puerta.

**S14 — [LAB] Lab 14 · Capstone: resiliencia y seguridad**
- Contenido:
  - **Objetivo**: actividad integradora final — configurar autenticación TLS/SASL y autorización con ACLs, y ejecutar un flujo de extremo a extremo con prueba de failover.
  - **Vas a hacer**: cifrar el tráfico con TLS, autenticar usuarios con SASL, definir ACLs diferenciadas, provocar una denegación de autorización, ajustar `min.insync.replicas` y **ver el failover sin pérdida de datos**.
  - **El cierre del curso**: todo lo aprendido, junto, en un solo escenario realista.
  - **Entorno**: Docker Compose · Kafka 4.2 · TLS + SASL + ACLs · multi-broker.
- Nota: El gran final. Las tres puertas de seguridad (S13) + la tríada de durabilidad (S12) + el failover (Cap 2) integrados. El momento cumbre: un mensaje que sobrevive a la caída de un broker con las garantías configuradas correctamente, y un acceso no autorizado que es correctamente denegado. Duración ~60 min. Remitir al README y al reporte de evaluación final.

**S15 — Cierre del curso**
- Contenido: El recorrido completo: entendieron por qué existe Kafka, inicializaron KRaft, operaron el clúster, lo escalaron y midieron, conectaron aplicaciones, gobernaron los datos, procesaron flujos, integraron sistemas, observaron y aseguraron. De la teoría al capstone: administradores de Kafka 4.2.
- Nota: Cierre emocional y honesto. Recontar el arco: "empezaron preguntándose por qué desacoplar sistemas; terminan asegurando un clúster con failover en vivo". Espacio para preguntas finales, feedback, y próximos pasos (certificación CCAAK como horizonte, si aplica). Agradecer.

---

## Resumen ejecutivo del guion

| Bloque | Tema | Slides | Lab puente | Diagramas [ANCLA] |
|---|---|---|---|---|
| Apertura | Portada | S1 | — | — |
| A | ksqlDB | S2–S5 | Lab 12 | STREAM vs TABLE (S3) |
| B | Kafka Connect | S6–S9 | Lab 13 | Source/Sink/workers (S7) |
| C | Observabilidad y HA/DR | S10–S12 | — | Prometheus/Grafana (S10), Balanza con valores (S12) |
| D | Seguridad · Capstone | S13–S15 | Lab 14 | Tres puertas TLS/SASL/ACL (S13) |

**Total Cap 5: 15 slides** (12 teóricas + 3 puente de laboratorio).

**Analogías ancla del capítulo (para pizarra):**
- El extracto bancario vs el saldo → STREAM vs TABLE (S3).
- La cinta transportadora de aeropuerto → Source/Sink/workers/tasks (S7).
- El tablero de un avión → observabilidad con Prometheus/Grafana (S10).
- La entrada al edificio corporativo seguro → TLS/SASL/ACL (S13).

**Diagramas [ANCLA] a renderizar (5):** S3, S7, S10, S12, S13.
**Todo lo demás marcado [PIZARRA]:** el instructor lo dibuja en clase.

**Slides puente de laboratorio (3):** S5 (Lab 12), S9 (Lab 13), S14 (Lab 14 capstone) — enmarcan prácticos ya construidos y validados.

**Pendientes que este guion deja registrados:**
1. Vertido a template Netec.
2. Los 5 diagramas ANCLA a renderizar en la fase visual.
3. Confirmar contra el material real del Lab 14 los nombres exactos de scripts de seguridad y failover al armar la slide puente.

---

## CIERRE DEL CURSO COMPLETO (los 5 capítulos)

| Capítulo | Unidad | Teóricas | Labs puente | Total slides |
|---|---|---|---|---|
| 1 · Arquitectura y fundamentos | U1 | 3 sesiones | — | 30 |
| 2 · KRaft | U2 | 3 sesiones | Labs 01–02 | 22 |
| 3 · Config, tópicos, rendimiento | U3 | intercalada | Labs 03–08 | 20 |
| 4 · Clientes, REST, esquemas | U4a | 4 bloques | Labs 09–11 | 14 |
| 5 · Procesamiento, HA/DR, seguridad | U4b | 3 bloques | Labs 12–14 | 15 |

**Total del curso: ~101 slides** — cómodamente bajo el techo de 200, con espacio de sobra para la pizarra.
