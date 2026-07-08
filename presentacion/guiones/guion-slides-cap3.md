# Guion de Slides — Capítulo 3: Configuración del clúster, tópicos y rendimiento

**Curso:** Administración de Confluent Apache Kafka (SUNAT)
**Sesiones cubiertas:** 4 bloques teóricos (config e inicialización · operación de tópicos · producción/consumo CLI · rendimiento · réplicas) + 6 prácticos (Labs 03–08)
**Narrativa:** NovaTech Logistics — Plataforma de eventos de la flota
**Estado:** Guion de contenido. Pendiente vertido a template Netec.

**Convenciones de este guion:**
- `S#` = número de slide propuesto.
- **Contenido** = bullets que van en la slide (español neutro, alumno). Conceptos fuertes, no párrafos.
- **Nota** = nota del orador (qué decir, énfasis, anécdotas).
- **Diagrama [ANCLA]** = diagrama que SÍ va renderizado en la PPT.
- **[PIZARRA]** = el instructor lo dibuja en vivo; slide limpia con el concepto.
- **[LAB]** = slide puente que enmarca un laboratorio ya construido; anuncia el práctico, no lo desarrolla.

**Nota de estructura:** la Unidad 3 es la más práctica del curso (6 labs). La teoría es ligera y va justo antes de cada práctico. Presupuesto: ~16 slides teóricas + 6 puente de lab.

---

## APERTURA DE LA UNIDAD

**S1 — Portada del capítulo**
- Contenido: "Capítulo 3 · Configuración del clúster, tópicos y rendimiento". Objetivos a la derecha.
- Nota: Encuadre: "las Unidades 1 y 2 fueron para entender; esta es para operar. Seis laboratorios. Aquí se ensucian las manos de verdad". Recordar que ya tienen un clúster KRaft vivo del Cap 2.

**S2 — El mapa de la Unidad 3**
- Contenido: Del clúster a la operación diaria: configurar brokers → exponerlos a clientes → administrar tópicos → producir/consumir → medir rendimiento → mantener el clúster en caliente. Seis prácticos, un hilo.
- Nota: Vender el arco de la unidad. Mostrar que cada bloque teórico desemboca en un lab. "No van a ver una slide sin después tocarla en la terminal".
- Diagrama [ANCLA]: línea de progresión de los 6 labs de la unidad, cada uno con su verbo (configurar, exponer, administrar, producir, medir, mantener).

---

## BLOQUE A — Configuración e inicialización de brokers  →  Lab 03

**S3 — El broker por dentro: los archivos que mandan**
- Contenido: Un broker se define por su configuración: `log.dirs` (dónde viven los datos), `listeners`/puerto (por dónde atiende), `node.id` (quién es), y los parámetros base de KRaft. Configurar un broker es escribir su identidad y su comportamiento.
- Nota: Analogía ancla — **el manual de puesto de un empleado nuevo**: dónde se sienta (`log.dirs`), por qué teléfono lo llaman (listeners/puerto), su número de legajo (`node.id`), y sus funciones. Sin manual claro, el empleado no sabe qué hacer. Conectar con los parámetros KRaft del Cap 2: aquí los aplicamos a un broker de datos.

**S4 — Docker Compose: el clúster como código**
- Contenido: El entorno de laboratorio se levanta con Docker Compose: cada broker es un servicio, con su configuración declarada. Un archivo describe el clúster completo; `docker compose up` lo materializa. Reproducible, versionable, desechable.
- Nota: Para esta audiencia (DevOps/SRE), el ángulo es familiar: infraestructura declarativa. La ventaja pedagógica: pueden romper y reconstruir el clúster mil veces sin miedo. Anticipar el Lab 03.

**S5 — [LAB] Lab 03 · Configuración e inicialización de brokers**
- Contenido:
  - **Objetivo**: desplegar el entorno con Docker Compose y revisar los archivos de configuración esenciales del broker.
  - **Vas a hacer**: levantar brokers funcionales en modo KRaft, inspeccionar `log.dirs`, puerto, `node.id` y los parámetros base.
  - **Entorno**: Docker Compose · Kafka 4.2 · KRaft.
- Nota: Se abre la terminal. Conectar con S3: el "manual de puesto" que acaban de ver, ahora lo leen en un broker real. Duración ~60 min. Remitir al README del Lab 03 y a `bin/90-test-lab.sh`.

---

## BLOQUE B — Clúster multi-broker y advertised.listeners  →  Lab 04

**S6 — advertised.listeners: la dirección que Kafka le da a los clientes**
- Contenido: Un broker escucha en una dirección interna, pero le **anuncia** a los clientes otra: `advertised.listeners`. El cliente se conecta primero a un broker, recibe la lista de dónde están todos, y se reconecta a esas direcciones anunciadas. Si lo anunciado no es alcanzable, el cliente falla — aunque el broker esté vivo.
- Nota: Este es EL parámetro que más dolores de cabeza da, y hay que darle peso. Analogía ancla — **el conserje que te da mal la dirección de la oficina**: llegas al edificio (el broker de bootstrap), preguntas por la sala 3 (otra partición/broker), y el conserje te manda a una dirección que no existe. Tú ves el edificio, pero nunca llegas a la sala. El drama del `advertised.listeners` mal configurado es exactamente eso.
- Diagrama [ANCLA]: cliente → broker bootstrap → recibe lista de advertised.listeners → se reconecta. Mostrar el caso bueno (dirección alcanzable) y el malo (dirección interna que el cliente externo no resuelve).

**S7 — Un clúster de varios: reparto y descubrimiento**
- Contenido: En multi-broker, los brokers se descubren entre sí y reparten las particiones. El cliente solo necesita **un** broker de bootstrap para conocer a todos. La topología de red (interna vs externa, Docker vs host) determina qué `advertised.listeners` usar.
- Nota: Conectar con el plano de datos del Cap 1: las particiones se reparten entre estos brokers. Aquí el foco es la **conectividad**: que el reparto sea alcanzable desde donde el cliente vive.

**S8 — [LAB] Lab 04 · Clúster multi-broker y advertised.listeners**
- Contenido:
  - **Objetivo**: levantar un clúster multi-broker y configurar `advertised.listeners` correctamente.
  - **Vas a hacer**: exponer brokers a clientes internos y externos, diagnosticar errores típicos de exposición y resolución de direcciones.
  - **El desafío**: reproducir y arreglar el error de "veo el broker pero no me conecto".
  - **Entorno**: Docker Compose · Kafka 4.2 · multi-broker.
- Nota: El "conserje que da mal la dirección" (S6) hecho realidad. Conectar el `TimeoutException` que verán con la teoría. Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE C — Operación de tópicos y producción/consumo  →  Labs 05 y 06

**S9 — Administrar tópicos: kafka-topics.sh**
- Contenido: El tópico se crea, lista, describe y modifica con `kafka-topics.sh`: número de particiones, factor de replicación, configuraciones. Crear un tópico es una decisión de diseño: las particiones definen el paralelismo máximo; el RF, la durabilidad.
- Nota: Retomar del Cap 1 (particiones = cajas de supermercado, RF = escriba y copistas). Aquí lo hacen con el comando real. Punto clave: se pueden **aumentar** particiones pero nunca reducir (rompe el orden por clave) — sembrar el desafío del Lab 05.

**S10 — Retención, segmentación y compresión: el ciclo de vida del dato**
- Contenido: Un tópico no guarda datos para siempre. `retention.ms`/`retention.bytes` definen cuánto vive un mensaje; `segment.ms` cómo se trocea el log en archivos; `compression.type` cómo se comprime. Kafka borra por **segmentos completos**, no mensaje a mensaje.
- Nota: Analogía ancla — **el archivo de una oficina que se purga por cajas, no por hojas**. No sacas hojas sueltas de una carpeta archivada; cuando una caja cumple su plazo, se elimina entera. Por eso `segment.ms` importa: define el tamaño de la "caja". Sembrar el Lab 05 (verán la retención eliminar datos en vivo).
- Diagrama [ANCLA]: un log troceado en segmentos; el segmento viejo (vencido) se elimina completo, el activo sigue creciendo. Mostrar por qué borrar por segmento es O(1) y borrar por mensaje sería costoso.

**S11 — [LAB] Lab 05 · Operación de tópicos**
- Contenido:
  - **Objetivo**: administrar tópicos con `kafka-topics.sh` y observar retención/segmentación/compresión en vivo.
  - **Vas a hacer**: crear tópicos con distinta personalidad, modificarlos en caliente, y ver la retención eliminar mensajes viejos de verdad.
  - **El desafío**: intentar reducir particiones y entender por qué Kafka lo prohíbe.
  - **Entorno**: Docker Compose · Kafka 4.2 · Kafbat UI para observar.
- Nota: La teoría de S9–S10 hecha experimento. El momento clave: ver el tópico efímero (retención 60s) perder datos mientras el resiliente los conserva. Duración ~60 min. Remitir al README y al `90`.

**S12 — Producción y consumo desde la CLI**
- Contenido: `kafka-console-producer.sh` inyecta mensajes; `kafka-console-consumer.sh` los lee. Con `--from-beginning` se lee desde el offset 0; sin él, solo lo nuevo. El consumidor avanza su offset a medida que lee — y ese offset es su memoria.
- Nota: Retomar el offset del Cap 1 (la memoria de quién leyó qué). Aquí lo ven moverse en la terminal. Demo mental: producir en una ventana, consumir en otra, ver el mensaje aparecer. Anticipar el Lab 06.

**S13 — [LAB] Lab 06 · Producción y consumo desde CLI**
- Contenido:
  - **Objetivo**: ingerir y descargar mensajes con las herramientas de consola, observando el log distribuido y el manejo de offsets.
  - **Vas a hacer**: producir a tópicos de la flota, consumir desde el principio y desde el final, ver cómo el offset registra el avance.
  - **Entorno**: Docker Compose · Kafka 4.2 · CLI nativa.
- Nota: El offset del Cap 1, ahora tangible. Conectar producir/consumir con la narrativa NovaTech (eventos de la flota entrando y siendo leídos). Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE D — Rendimiento de Kafka  →  Lab 07

**S14 — Los cuatro recursos que deciden el rendimiento**
- Contenido: El rendimiento de Kafka se juega en cuatro frentes: **I/O de disco** (y el page cache del SO), **red** (throughput entre brokers y clientes), **memoria** (heap de la JVM y GC), **CPU** (compresión, checksums). Ninguno se optimiza aislado.
- Nota: Analogía ancla — **una cocina de restaurante en hora punta**: la despensa (disco/page cache), los mozos que llevan platos (red), el espacio en la mesada (RAM), y los cocineros (CPU). Si cualquiera es el cuello de botella, toda la cocina se atasca — y de nada sirve tener diez cocineros si hay un solo mozo. El tuning es balancear los cuatro.
- Diagrama [ANCLA]: los 4 recursos como engranajes conectados; si uno se traba, el conjunto se frena. Etiquetar qué parámetro toca cada uno.

**S15 — El page cache: el arma secreta de Kafka**
- Contenido: Kafka casi no gestiona su propia caché: delega en el **page cache del sistema operativo**. Escribe secuencial (el SO lo bufferiza), lee secuencial (sirve desde RAM sin tocar disco). Por eso Kafka vuela con hardware modesto: aprovecha memoria que el SO ya administra.
- Nota: Dato que sorprende a admins: dar toda la RAM al heap de la JVM es contraproducente — Kafka **quiere** que el SO tenga RAM libre para el page cache. Heap grande = menos page cache = peor rendimiento. Contraintuitivo pero clave.

**S16 — [LAB] Lab 07 · Pruebas de rendimiento**
- Contenido:
  - **Objetivo**: medir throughput y latencia con `kafka-producer-perf-test` y `kafka-consumer-perf-test`.
  - **Vas a hacer**: generar carga sintética, variar parámetros del cliente (batch, linger, compresión, fetch) y medir el impacto de cada ajuste con números reales.
  - **Entorno**: Docker Compose · Kafka 4.2 · herramientas de perf nativas.
- Nota: La "cocina en hora punta" (S14) medida con instrumentos. Advertir: los números dependen del hardware — lo importante es el **delta** entre configuraciones, no el valor absoluto. Duración ~60 min. Remitir al README y al `90`.

---

## BLOQUE E — Ubicación de réplicas y mantenimiento  →  Lab 08

**S17 — Dónde viven las réplicas y quién lidera**
- Contenido: Kafka distribuye las réplicas de cada partición entre brokers buscando balance. El **líder** de cada partición atiende el tráfico; los seguidores replican. Con el tiempo —brokers nuevos, caídas, crecimiento— esa distribución se desbalancea y hay que **reasignar**.
- Nota: Retomar líder/réplicas/ISR del Cap 1. Aquí el foco operativo: mantener el balance. Analogía — **la distribución de turnos en un hospital**: si todos los médicos senior quedan en el mismo turno, ese turno se sobrecarga y los demás quedan flojos. Reasignar es redistribuir la carga.

**S18 — Reasignación y reconfiguración en caliente**
- Contenido: `kafka-reassign-partitions` mueve réplicas entre brokers sin parar el servicio. Sumar o quitar brokers, redistribuir particiones, aplicar cambios de configuración dinámicos — todo en caliente. El clúster se mantiene vivo mientras se reorganiza.
- Nota: El valor para esta audiencia: cero downtime en mantenimiento. Conectar con el Dynamic Quorum del Cap 2 (cambiar controladores en caliente) — aquí es el equivalente para brokers de datos y particiones. Sembrar el Lab 08.
- Diagrama [ANCLA]: antes/después de una reasignación — un broker sobrecargado y otro flojo → particiones redistribuidas equilibradamente, con el servicio activo durante el proceso.

**S19 — [LAB] Lab 08 · Cambio de configuración de brokers en caliente**
- Contenido:
  - **Objetivo**: añadir y eliminar brokers y aplicar reconfiguraciones dinámicas sin downtime.
  - **Vas a hacer**: reasignar particiones, verificar la continuidad del servicio y la correcta redistribución durante la operación.
  - **Entorno**: Docker Compose · Kafka 4.2 · multi-broker.
- Nota: El cierre operativo de la Unidad 3. La "redistribución de turnos" (S17) ejecutada en vivo. Enfatizar: el servicio nunca se cae durante la reasignación. Duración ~60 min. Remitir al README y al `90`.

**S20 — Cierre de la Unidad 3**
- Contenido: Síntesis: configuraron brokers, los expusieron bien, administraron tópicos con su ciclo de vida, produjeron y consumieron, midieron rendimiento y mantuvieron el clúster en caliente. Tienen un clúster operativo de punta a punta. Próxima unidad: el ecosistema avanzado y la seguridad.
- Nota: Cierre de la unidad más práctica. Recontar los 6 labs como logros. Transición a la Unidad 4: "ya operan Kafka; ahora vamos a rodearlo de su ecosistema — clientes, REST, esquemas, streams, integración— y a cerrarlo con seguridad".

---

## Resumen ejecutivo del guion

| Bloque | Tema | Slides | Lab puente | Diagramas [ANCLA] |
|---|---|---|---|---|
| Apertura | Mapa de la unidad | S1–S2 | — | Progresión 6 labs (S2) |
| A | Config de brokers | S3–S5 | Lab 03 | — |
| B | Multi-broker / listeners | S6–S8 | Lab 04 | advertised.listeners (S6) |
| C | Tópicos + CLI | S9–S13 | Labs 05, 06 | Segmentos y retención (S10) |
| D | Rendimiento | S14–S16 | Lab 07 | 4 recursos (S14) |
| E | Réplicas y mantenimiento | S17–S20 | Lab 08 | Reasignación antes/después (S18) |

**Total Cap 3: 20 slides** (14 teóricas + 6 puente de laboratorio).

**Analogías ancla del capítulo (para pizarra):**
- El manual de puesto del empleado nuevo → configuración del broker (S3).
- El conserje que da mal la dirección → advertised.listeners (S6).
- El archivo que se purga por cajas, no por hojas → retención por segmentos (S10).
- La cocina en hora punta → los 4 recursos del rendimiento (S14).
- La distribución de turnos en un hospital → balance de réplicas (S17).

**Diagramas [ANCLA] a renderizar (5):** S2, S6, S10, S14, S18.
**Todo lo demás marcado [PIZARRA]:** el instructor lo dibuja en clase.

**Slides puente de laboratorio (6):** S5 (Lab 03), S8 (Lab 04), S11 (Lab 05), S13 (Lab 06), S16 (Lab 07), S19 (Lab 08) — enmarcan prácticos ya construidos y validados.

**Pendientes que este guion deja registrados:**
1. Vertido a template Netec.
2. Los 5 diagramas ANCLA a renderizar en la fase visual.
3. Confirmar contra el material real de cada lab los nombres exactos de scripts al armar las slides puente.
