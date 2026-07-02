# Guion de Slides — Capítulo 1: Arquitectura, fundamentos y ecosistema

**Curso:** Administración de Confluent Apache Kafka (SUNAT)
**Sesiones cubiertas:** 1, 2 y 3 (180 min de teoría — Unidad 1 completa)
**Narrativa:** NovaTech Logistics — Plataforma de eventos de la flota
**Estado:** Guion de contenido. Pendiente vertido a template Netec.

**Convenciones de este guion:**
- `S#` = número de slide propuesto.
- **Contenido** = bullets que van en la slide (español neutro, alumno). Conceptos fuertes, no párrafos.
- **Nota** = nota del orador (qué decir, énfasis, anécdotas).
- **Diagrama [ANCLA]** = diagrama que SÍ va renderizado en la PPT (pocos, los que valen imagen).
- **[PIZARRA]** = el instructor lo dibuja en vivo; la slide NO lleva placeholder, solo el concepto.
- Tiempos por bloque para calzar los 60 min de cada sesión.

**Presupuesto:** ~30 slides (Unidad 1 es la más teórica del curso). Techo global del curso: 200 slides.

---

## SESIÓN 1 — Mensajería basada en eventos y el rol de Kafka

**Objetivo:** entender *por qué* existe Kafka antes de *qué* es — el costo del acoplamiento síncrono y por qué el log distribuido es una respuesta distinta a la cola de siempre.

### Bloque 1 — Apertura y narrativa (12 min, S1–S3)

**S1 — Portada del curso**
- Contenido: Título, instructor, logo Netec (layout Portada).
- Nota: Presentación breve. CCAAK + experiencia. Encuadre para esta audiencia: "ustedes ya administran infraestructura; acá hablamos de operar Kafka 4.2 en serio, en KRaft, sin ZooKeeper".

**S2 — Agenda y las reglas del juego**
- Contenido: Las 4 unidades en una línea cada una · 45% teoría / 55% práctica · 14 labs + capstone · Stack: Kafka 4.2 / Confluent Platform 8.2.0 / KRaft / Docker.
- Nota: Vender el arco: "al final inicializan un clúster KRaft desde cero, lo tunean, lo escalan en caliente y lo cierran con seguridad y failover sin pérdida". Aclarar: la Unidad 1 es la única de teoría pura.

**S3 — NovaTech Logistics: el caso que nos acompaña**
- Contenido: Flota de miles de vehículos emitiendo posición y eventos. Sistemas hoy acoplados y frágiles. Decisión: una Plataforma de Eventos sobre Kafka. El curso la construye.
- Nota: "Esto les va a sonar a algo que ya vivieron". Sembrar los tópicos reales: `novatech.fleet.events`, `novatech.fleet.gps`.
- Diagrama [ANCLA]: Flota → Plataforma de Eventos (Kafka) → consumidores (ruteo, facturación por km, tablero de operaciones, detección de anomalías). Mapa narrativo del curso.

### Bloque 2 — El problema que Kafka resuelve (25 min, S4–S7)

**S4 — El cableado directo: la telaraña que se paga cara**
- Contenido: N sistemas hablándose directo = N×(N−1) conexiones. Cada sistema nuevo obliga a tocar los existentes. Acoplamiento estructural.
- Nota: Analogía ancla — **la centralita telefónica de los años 20**: una operadora conectaba cables a mano; sumar un abonado era re-cablear el tablero. Kafka es el salto a la central automática: marcas a un número (un tópico) y no te importa quién contesta.
- [PIZARRA]: la telaraña (6 cajas todas-contra-todas) → al lado, las mismas 6 colgando de un bus central. El contraste en vivo pega más que renderizado.

**S5 — Acoplamiento temporal: el tirano invisible**
- Contenido: Síncrono = el que llama espera al que responde. Si el receptor cae, el emisor cae con él. La disponibilidad de un sistema queda atada a la de todos a los que llama.
- Nota: Ejemplo NovaTech: si registrar un evento GPS exige respuesta de facturación y facturación se cae, la flota deja de reportar. Absurdo. Pregunta a la sala: "¿cuántos incidentes suyos fueron un timeout en cascada?".

**S6 — Desacoplar en el tiempo, el espacio y el flujo**
- Contenido: Asincronía: el emisor deja el evento y sigue; el receptor lo toma cuando puede. Tres desacoplamientos: temporal (cuándo), espacio (dónde), flujo (a qué ritmo).
- Nota: Recalcar el de flujo: productor rápido + consumidor lento coexisten porque el log amortigua. Reaparece literal en el Lab 07 (rendimiento).

**S7 — Cola vs log de eventos: NO son lo mismo**
- Contenido: Cola clásica: el mensaje se consume y desaparece. Log (Kafka): el mensaje se queda; muchos consumidores leen el mismo evento a su ritmo, cada uno con su offset.
- Nota: El malentendido #1 de quien viene de colas. Analogía: la cola es **un buzón de correo** (sacas la carta y ya no está); el log es **el diario mural del edificio** (la noticia queda, la leen todos, cada uno recuerda por dónde iba). El offset es ese "por dónde iba".
- Diagrama [ANCLA]: arriba una cola vaciándose; abajo un log append-only con 3 consumidores en offsets distintos del MISMO log. Es el concepto que más cuesta.

### Bloque 3 — Anatomía del evento (18 min, S8–S10)

**S8 — El evento: un hecho inmutable con clave**
- Contenido: Un evento es un hecho ya ocurrido ("el vehículo 47 reportó posición X"), no una orden. Los hechos no se editan: se corrigen con nuevos hechos → el log solo crece. Estructura mínima: clave (decide orden y destino), valor, timestamp, headers.
- Nota: Fusiona inmutabilidad + estructura. Sembrar para la Unidad 3: "la clave decide la partición; cuando en el Lab 05 vean por qué no se pueden reducir particiones, esta slide cobra sentido".

**S9 — El log: la estructura más subestimada**
- Contenido: Secuencia ordenada, solo-anexar, numerada. Simple hasta lo aburrido — y por eso rapidísima: escribir es "al final", leer es secuencial. La genialidad de Kafka es distribuir esa estructura trivial.
- Nota: Analogía — **el libro de bitácora de un barco**: nadie borra ni reordena; solo se escribe la siguiente línea con hora. Frase para pizarra: "Kafka es un archivo al que se le agrega al final, hecho a escala planetaria".

**S10 — Cierre Sesión 1: la promesa**
- Contenido: Tres ideas: (1) el acoplamiento síncrono se paga en cascada, (2) el log desacopla en tiempo/espacio/flujo, (3) un evento es un hecho inmutable con clave. Mañana: cómo Kafka vuelve ese log un sistema distribuido.
- Nota: Cierre 5 min. Puente: "¿qué sistema suyo se beneficiaría más de desacoplar en el tiempo?". Recoger 2-3 respuestas.

---

## SESIÓN 2 — Arquitectura de Apache Kafka 4.2

**Objetivo:** conocer el plano de datos por nombre y función —brokers, particiones, productores, consumidores, replicación— y cómo dan durabilidad y tolerancia a fallos.

### Bloque 1 — El plano de datos (25 min, S11–S15)

**S11 — Vista de helicóptero de un clúster**
- Contenido: El elenco completo en un dibujo: brokers formando clúster, tópicos en particiones repartidas, productores escribiendo, consumidores leyendo, réplicas detrás de cada líder.
- Nota: Presentar todo antes de ir pieza por pieza. "Todo lo que aparezca acá lo levantan con sus manos desde mañana".
- Diagrama [ANCLA]: el **mapa maestro del plano de datos** — 3 brokers, un tópico con 3 particiones distribuidas, líderes y réplicas con color. Reaparece iluminada en capítulos siguientes.

**S12 — Broker, tópico y partición**
- Contenido: Broker = proceso que recibe/almacena/sirve eventos (el caballo de carga). Tópico = nombre lógico. Partición = unidad física y de paralelismo; cada una es un log independiente y ordenado. El orden se garantiza DENTRO de una partición, no entre particiones.
- Nota: Fusiona 3 conceptos. Analogía de la partición — **las cajas de un supermercado**: abrir más cajas atiende a más gente en paralelo, pero el orden solo existe dentro de la fila de cada caja; la clave del evento decide a qué caja va cada cliente (y así los eventos de un mismo vehículo mantienen orden).
- [PIZARRA]: dibujar `novatech.fleet.events` abriéndose en 3 particiones con eventos de distinta clave cayendo cada uno a la suya.

**S13 — Productor, consumidor y consumer group**
- Contenido: Productor escribe (y vía la clave influye la partición). Consumidor lee y lleva su offset. Los consumidores se agrupan para repartirse las particiones y escalar horizontalmente.
- Nota: Sembrar el consumer group sin agotarlo (tiene su tratamiento en Unidad 4): "un grupo es un equipo que se reparte las particiones; entra un miembro y Kafka reasigna solo". Conecta con el desacoplamiento de flujo.

**S14 — El offset: la memoria de quién leyó qué**
- Contenido: Cada evento tiene un número secuencial: el offset. El consumidor no borra; solo avanza. Dos consumidores leen el mismo evento sin estorbarse porque cada uno recuerda su posición.
- Nota: Reforzar el contraste con la cola (diario mural vs buzón). Aterrizar en operación: "un consumidor cae y vuelve → retoma desde su último offset confirmado, no desde cero". Base de la resiliencia prometida.

**S15 — Recap del plano de datos**
- Contenido: Diagrama de S11 anotado: broker (trabajo), partición (paralelismo+orden), offset (memoria), y lo que viene: réplicas.
- Nota: 2 min de síntesis antes de entrar a durabilidad.

### Bloque 2 — Durabilidad y tolerancia a fallos (25 min, S16–S19)

**S16 — Replicación e ISR: el círculo de confianza**
- Contenido: Cada partición se copia en varios brokers (factor de replicación). Una es líder; las demás, seguidoras que copian. Las que están *al día* forman el ISR (in-sync replicas). Solo una del ISR puede ser promovida a líder.
- Nota: Fusiona replicación + ISR. Analogía — **el escriba y sus copistas**: el escriba (líder) redacta el acta; los copistas al día (ISR) transcriben; si el escriba enferma, un copista *al día* toma la pluma. Frase: "estar replicado no basta; hay que estar replicado Y al día".
- Diagrama [ANCLA]: una partición con líder en broker-1, seguidoras en broker-2/3, flechas de replicación, y el ISR marcado. Sostiene S17 y S18.

**S17 — La tríada de la durabilidad: acks, RF y min.ISR**
- Contenido: Tres perillas que juntas responden "¿cuán seguro está mi evento?": factor de replicación (cuántas copias), `min.insync.replicas` (cuántas al día para aceptar la escritura), `acks` del productor (cuántas confirmaciones espera). Se calibran en conjunto.
- Nota: NO agotar números (eso es Unidad 3 / Lab 14). Instalar el modelo mental: "durabilidad y disponibilidad son una balanza; estas tres perillas la ajustan". Prometer el experimento en vivo del capstone.
- [PIZARRA]: la balanza — platillo "Durabilidad" (RF alto, min.ISR alto, acks=all) vs "Disponibilidad/latencia", con las 3 perillas como pesas. Perfecta para dibujar moviendo las pesas en vivo.

**S18 — Cuando un broker cae: el momento de la verdad**
- Contenido: Secuencia: cae el líder de ciertas particiones → Kafka lo detecta → promueve una réplica del ISR a nueva líder → productores/consumidores redirigen → el servicio continúa. Sin humanos.
- Nota: El "wow" honesto. NovaTech: "el broker de la zona norte se apaga; en segundos otro es líder de esas particiones y los camiones siguen reportando, sin llamar a soporte". Este flujo EXACTO se prueba en el Lab 14 — venderlo.
- [PIZARRA]: 3 viñetas (sano → líder tachado con flecha de elección → nuevo líder), el ISR bajando de 3 a 2. Ideal para animarlo con el plumón.

**S19 — El límite honesto de la replicación**
- Contenido: Tolerar la caída de N brokers exige más de N réplicas al día — cuesta disco, red, latencia. Un clúster de 3 con RF 3 tolera perder 1, no 2. La resiliencia se dimensiona, no se desea.
- Nota: Honestidad de ingeniería para esta audiencia: no vender Kafka como indestructible. Conecta con el dimensionamiento del quorum de la Unidad 2 (3 vs 5) — hilo tendido.

### Bloque 3 — Puente a KRaft (10 min, S20)

**S20 — Quién manda aquí: el plano de control**
- Contenido: Alguien lleva la cuenta de qué brokers existen, qué particiones hay, quién es líder, y decide las elecciones. Eso es el plano de control (metadatos), distinto del plano de datos (los eventos). Antes lo hacía ZooKeeper; Kafka 4.2 lo hace *dentro*, con KRaft. La Unidad 2 se dedica a eso.
- Nota: Cerrar Sesión 2 con hambre: "mañana dejamos de dibujar y encendemos el primer clúster; antes, la próxima sesión cierra la teoría con el ecosistema Confluent". Transición a Sesión 3.

---

## SESIÓN 3 — Componentes de Confluent Platform 8.2.0

**Objetivo:** ubicar cada componente del ecosistema —qué problema resuelve y en qué lab aparece— para que el resto del curso sea un sistema, no piezas sueltas.

### Bloque 1 — Kafka desnudo vs plataforma (15 min, S21–S23)

**S21 — Apache Kafka vs Confluent Platform**
- Contenido: Apache Kafka (open source) = el núcleo: brokers, tópicos, el log. Confluent Platform 8.2.0 lo empaqueta y le añade componentes empresariales. Este curso trabaja sobre Confluent Platform, en KRaft.
- Nota: Transparencia: "el corazón es Apache Kafka; Confluent es la distro que lo rodea de herramientas, como una distro de Linux empaqueta el kernel". Sin marketing.

**S22 — El ecosistema en una imagen**
- Contenido: Capas concéntricas: centro Kafka (brokers + KRaft); anillo 1 conectores (Connect, REST Proxy); anillo 2 gobierno (Schema Registry); anillo 3 procesamiento (ksqlDB); alrededor operación (Control Center, CLI).
- Nota: Este es el mapa de las Unidades 3 y 4. "Cada anillo es uno o más labs que van a hacer". Reaparece al inicio de la Unidad 4.
- Diagrama [ANCLA]: las capas concéntricas alrededor de Kafka. Pieza de orientación clave; reutilizable.

**S23 — Cómo se conectan: todo pasa por Kafka**
- Contenido: Connect escribe/lee tópicos, Schema Registry guarda esquemas en un tópico, ksqlDB consume/produce tópicos, REST Proxy traduce HTTP a protocolo Kafka. Kafka es el sustrato; el resto, especialistas conectados.
- Nota: Idea ancla — **el ecosistema es un mercado y Kafka es la plaza central**: cada puesto tiene su especialidad, pero todos comercian en la misma plaza. Nadie se la salta. Por eso entender Kafka primero era obligatorio.

### Bloque 2 — Los componentes, uno por uno (35 min, S24–S28)

**S24 — Kafka Connect: integración sin código**
- Contenido: Mueve datos entre Kafka y sistemas externos con *connectors* configurables. Source (hacia Kafka) y Sink (desde Kafka). Workers, tasks, offsets.
- Nota: NovaTech: "el core legado vive en una BD; un source connector lleva sus cambios a Kafka sin programar un integrador". Anunciar Lab 13. Frase: "Connect es el equipo de mudanzas: mueve datos, no los transforma".

**S25 — Schema Registry: el notario de los datos**
- Contenido: Registra y versiona esquemas. Verifica compatibilidad (BACKWARD, FORWARD, FULL) e impide publicar mensajes que rompan el contrato con los consumidores existentes.
- Nota: Analogía — **el notario**: antes de que un productor cambie la forma de sus eventos, verifica que el cambio no deje "sin poder leer" a quienes firmaron el contrato anterior. Anunciar Lab 11, donde el notario *rechaza* un cambio incompatible en vivo.

**S26 — ksqlDB y REST Proxy**
- Contenido: ksqlDB = SQL sobre flujos en movimiento (STREAM, TABLE, consultas persistentes). REST Proxy = Kafka sobre HTTP, para quien no habla protocolo Kafka nativo.
- Nota: Fusiona dos componentes. ksqlDB: **la foto vs la película** — una tabla tradicional es la foto del estado actual; un STREAM es la película de cómo se llegó ahí; una TABLE es la foto reconstruida desde la película. REST Proxy: cómodo pero con costo de rendimiento, no para alto throughput. Labs 12 y 10.

**S27 — Exploración visual y operación (Landoop → Kafbat)**
- Contenido: Interfaces gráficas para explorar tópicos/mensajes sin CLI. El temario nombra "Landoop"; el curso usa su reemplazo activo, compatible con Kafka 4.x. Confluent CLI y Control Center para operar y observar.
- Nota: Transparencia técnica (esta audiencia lo agradece): Landoop quedó descontinuado e incompatible con Kafka 4.x; el curso usa **Kafbat UI**, su sucesor mantenido (ADR-001). Es lo que separa un curso actualizado de uno copiado. Control Center como pieza empresarial; ser claro sobre qué es demo y qué es práctica.

**S28 — El stack real, sin humo + mapa componente→lab**
- Contenido: Tabla del stack concreto (Kafka 4.2, CP 8.2.0, KRaft, Java 21, Docker, `cp-kafka:8.2.0`, Kafbat UI) + cada componente anotado con su lab (Connect→13, Schema Registry→11, ksqlDB→12, REST Proxy→10, seguridad→14).
- Nota: Cierre de credibilidad: "versiones reales y verificadas, no 'la última genérica'; cuando algo cambió —como Landoop— se los decimos y damos el reemplazo". Argumento de venta silencioso.
- Diagrama [ANCLA]: el ecosistema de S22 con etiquetas de lab sobre cada pieza (reutiliza el ancla, anotado).

### Bloque 3 — Cierre de la Unidad 1 (10 min, S29–S30)

**S29 — Lo que ya sabemos**
- Contenido: Síntesis en tres frases: (1) Kafka desacopla sistemas vía un log de eventos, (2) su arquitectura distribuida da durabilidad y tolerancia a fallos, (3) Confluent rodea ese núcleo con un ecosistema de especialistas. Mañana: manos al clúster con KRaft.
- Nota: Recordatorio de prerrequisitos de lab (Docker, recursos, entorno validado). Pedir confirmar el entorno antes de la Unidad 2 (checklist / VM Netec).

**S30 — Preguntas y discusión dirigida**
- Contenido: Tres preguntas: ¿Qué integran hoy de forma síncrona que dolería desacoplar? ¿Qué componente les resolvería un problema actual? ¿Alguien operó Kafka con ZooKeeper y quiere contrastar con KRaft?
- Nota: Reservar 10 min. Calibra el tono de las unidades prácticas. La tercera identifica a los veteranos de ZooKeeper, aliados narrativos para la Unidad 2.

---

## Resumen ejecutivo del guion

| Sesión | Slides | Bloques | Diagramas [ANCLA] (render) |
|---|---|---|---|
| 1 | S1–S10 (10) | Narrativa → El problema (acoplamiento) → Anatomía del evento | Mapa narrativo NovaTech (S3), Cola vs log (S7) |
| 2 | S11–S20 (10) | Plano de datos → Durabilidad/tolerancia → Puente a KRaft | Mapa maestro del plano de datos (S11), Replicación e ISR (S16) |
| 3 | S21–S30 (10) | Kafka vs Confluent → Componentes → Cierre Unidad 1 | Ecosistema en capas (S22), Ecosistema→Lab (S28) |

**Total Cap 1: 30 slides.** Diagramas renderizados (ANCLA): **6** (S3, S7, S11, S16, S22, S28). El resto de apoyos visuales van a **[PIZARRA]** — el instructor los dibuja en vivo.

**Proyección del curso (techo 200 slides):**
- Cap 1 (Unidad 1, teoría pura): ~30 slides.
- Caps 2–5 (Unidades 2–4, teoría intercalada con labs): ~15–20 slides c/u.
- Estimado total: **~155 slides** — cómodamente bajo 200.

**Analogías ancla del capítulo (para pizarra):**
- Centralita telefónica de los años 20 → cableado punto a punto (S4).
- Buzón vs diario mural → cola vs log (S7).
- Libro de bitácora de un barco → log append-only (S9).
- Cajas del supermercado → particiones y paralelismo (S12).
- Escriba y copistas → líder, réplicas e ISR (S16).
- Plaza central del mercado → Kafka como sustrato del ecosistema (S23).
- Notario de los datos → Schema Registry (S25).
- Foto vs película → TABLE vs STREAM (S26).

**Pendientes que este guion deja registrados:**
1. Vertido a template Netec (misma plantilla que Strimzi).
2. Los 6 diagramas ANCLA: decidir imagen renderizada vs boceto en la fase de diagramas posterior.
