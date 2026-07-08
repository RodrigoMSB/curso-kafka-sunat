# Guion de Slides — Capítulo 2: KRaft — metadatos, quorum y resiliencia

**Curso:** Administración de Confluent Apache Kafka (SUNAT)
**Sesiones cubiertas:** 3 teóricas (KRaft a fondo · Parámetros clave · Dimensionamiento del quorum) + 2 prácticos (Lab 01, Lab 02)
**Narrativa:** NovaTech Logistics — Plataforma de eventos de la flota
**Estado:** Guion de contenido. Pendiente vertido a template Netec.

**Convenciones de este guion:**
- `S#` = número de slide propuesto.
- **Contenido** = bullets que van en la slide (español neutro, alumno). Conceptos fuertes, no párrafos.
- **Nota** = nota del orador (qué decir, énfasis, anécdotas).
- **Diagrama [ANCLA]** = diagrama que SÍ va renderizado en la PPT.
- **[PIZARRA]** = el instructor lo dibuja en vivo; slide limpia con el concepto.
- **[LAB]** = slide puente que enmarca un laboratorio ya construido; anuncia el práctico, no lo desarrolla.

**Presupuesto:** ~20 slides teóricas + 2 puente de lab. Techo global del curso: 200 slides.

---

## SESIÓN 1 — KRaft a fondo: roles, líder de metadatos y tolerancia a fallos

**Objetivo:** que el alumno entienda por qué Kafka mató a ZooKeeper, qué es el plano de control de metadatos, y cómo un quorum de controladores reemplaza a un sistema externo — con más simplicidad y la misma (o mejor) resiliencia.

### Bloque 1 — El problema que KRaft resuelve (18 min, S1–S4)

**S1 — Portada del capítulo**
- Contenido: "Capítulo 2 · KRaft — metadatos, quorum y resiliencia". Objetivos del capítulo a la derecha.
- Nota: Retomar el hilo del cierre del Cap 1: "ayer dijimos que alguien tiene que llevar la cuenta de quién es líder de qué. Hoy conocemos a ese alguien — y la buena noticia es que ya no es un inquilino externo".

**S2 — Recap: el plano de control (para los que llegan)**
- Contenido: Plano de datos = los eventos (lo del Cap 1). Plano de control = los metadatos: qué brokers hay, qué particiones existen, quién lidera cada una, quién está en el ISR. Alguien debe custodiar esa verdad.
- Nota: 2 min. Enganchar con lo ya visto. La metadata no es un detalle administrativo: si se corrompe o se pierde el consenso sobre ella, el clúster no sabe quién manda y se paraliza.

**S3 — La era ZooKeeper: el inquilino externo**
- Contenido: Durante años Kafka guardó su metadata en ZooKeeper, un sistema de consenso **separado**. Funcionaba, pero: dos sistemas que operar, dos que asegurar, dos que actualizar; un salto de red entre Kafka y su propia verdad; y un límite de escala en la cantidad de particiones.
- Nota: Analogía ancla de la sesión — **la empresa que arrienda su bóveda en el banco de enfrente**. Cada vez que necesita consultar un documento crítico, cruza la calle. Funciona… hasta que el banco cierra, la calle se corta, o el trámite de cruzar se vuelve el cuello de botella. KRaft es construir la bóveda **dentro** de la propia empresa.
- Nota extra: para la audiencia con veteranos de ZooKeeper (los que identificamos en el Cap 1), validar su experiencia: "los que operaron ZooKeeper saben del dolor del split-brain y del `zookeeper.connect`".

**S4 — KRaft: la metadata se muda adentro**
- Contenido: KRaft (Kafka Raft) mete el consenso de metadatos **dentro** de Kafka. Un subconjunto de nodos asume el rol de **controladores** y mantiene la metadata como… un log de eventos (¡el mismo concepto del Cap 1!). Sin ZooKeeper. Un solo sistema.
- Nota: El "aha" de la sesión: Kafka aplica su propia medicina. La metadata es un topic interno replicado (`__cluster_metadata`); los controladores se ponen de acuerdo sobre él con el algoritmo Raft. Sembrar: "el mismo log que aprendieron ayer ahora también gobierna el clúster".

### Bloque 2 — Anatomía del plano de control KRaft (25 min, S5–S9)

**S5 — Roles: controlador, broker, o ambos**
- Contenido: En KRaft un nodo declara su rol con `process.roles`: `controller` (gobierna metadata), `broker` (sirve datos), o `controller,broker` (combinado, para clústeres chicos). Los controladores forman el quorum; los brokers hacen el trabajo de datos.
- Nota: Aterrizar para admins: en producción seria, controladores dedicados (aíslan el plano de control del ruido de datos); en labs y entornos chicos, combinado. Anticipar que en el Lab 01 levantarán controladores.
- Diagrama [ANCLA]: tres nodos marcados `controller`, tres marcados `broker`, y una variante combinada — mostrando las tres configuraciones de `process.roles`.

**S6 — El quorum de controladores y el líder de metadatos**
- Contenido: Los controladores forman un **quorum**: un grupo impar (3 o 5) que vota. Uno es el **líder de metadatos** (el active controller); el resto son seguidores que replican el log de metadata. Si el líder cae, el quorum **elige** uno nuevo — igual que las réplicas de datos eligen líder.
- Nota: El paralelo es hermoso y hay que explotarlo: "lo que aprendieron ayer sobre líder/réplicas/ISR de datos, KRaft lo aplica a la metadata". Un solo modelo mental para todo el clúster.
- [PIZARRA]: dibujar 3 controladores, marcar el líder, tacharlo, y mostrar la reelección — reusando visualmente el failover del Cap 1.

**S7 — Raft: cómo se ponen de acuerdo (sin entrar al paper)**
- Contenido: Raft es el algoritmo de consenso: una escritura de metadata se considera confirmada cuando la **mayoría** del quorum la registró. Con 3 controladores, la mayoría es 2; con 5, es 3. La mayoría garantiza que nunca haya dos verdades.
- Nota: NO entrar al detalle académico de Raft. La idea operativa: **mayoría = verdad única**. Analogía — **un directorio que solo aprueba un acuerdo si vota la mayoría**: aunque un director se ausente, la decisión es válida y consistente; pero si se ausenta la mayoría, no hay acuerdo válido (y eso es a propósito, para no decidir en falso).

**S8 — Tolerancia a fallos: cuántos controladores puedo perder**
- Contenido: Un quorum de N controladores tolera perder ⌊(N−1)/2⌋ y seguir operando: 3 → tolera 1; 5 → tolera 2. Perder la mayoría = el plano de control se detiene (no acepta cambios de metadata) para no arriesgar inconsistencia.
- Nota: Conectar con el "límite honesto" del Cap 1: la resiliencia se dimensiona. Aquí el número es de controladores, no de réplicas de datos. Sembrar la sesión 3 (3 vs 5).
- Diagrama [ANCLA]: tabla visual — quorum de 3 (tolera 1) vs quorum de 5 (tolera 2), con los nodos caídos en rojo y la mayoría sobreviviente en verde.

**S9 — Por qué esto es mejor (el cierre honesto)**
- Contenido: Menos piezas (un sistema, no dos) · arranque y recuperación más rápidos · más particiones soportadas · un solo modelo de seguridad y operación. Kafka 4.x es **KRaft-only**: ZooKeeper ya no es opción.
- Nota: Dato de credibilidad: KRaft es el presente, no el futuro — Kafka 4.x eliminó ZooKeeper por completo. Este curso trabaja el mundo real de 2026, no el legado. Argumento de venta silencioso para esta audiencia.

### Bloque 3 — Cierre de sesión (5 min, S10)

**S10 — Cierre Sesión 1**
- Contenido: Tres ideas: (1) la metadata se mudó adentro con KRaft, sin ZooKeeper; (2) los controladores forman un quorum que elige un líder de metadatos; (3) Raft = mayoría = verdad única. Próxima sesión: los parámetros que hacen todo esto realidad.
- Nota: Puente a la sesión 2: "ahora que entienden el qué y el porqué, vamos al cómo: los parámetros exactos que ustedes van a escribir".

---

## SESIÓN 2 — Parámetros clave de KRaft

**Objetivo:** que el alumno conozca por nombre y función los parámetros que definen un nodo KRaft, y entienda el rol de `kafka-storage.sh` en el formateo y el cluster id — dejando todo listo para el Lab 01.

### Bloque 1 — Los parámetros que definen un nodo (25 min, S11–S14)

**S11 — El carnet de identidad de un nodo**
- Contenido: Cuatro parámetros definen quién es un nodo en el clúster: `node.id` (su número único), `process.roles` (qué hace), `controller.quorum.voters` (con quién forma quorum), `controller.listener.names` (por dónde habla el plano de control).
- Nota: Analogía — **el carnet de identidad + el domicilio + la lista de socios**. `node.id` es el RUT; `process.roles` es la profesión; `controller.quorum.voters` es la libreta de contactos del directorio; los listeners son la dirección donde te encuentran.
- Diagrama [ANCLA]: un "carnet" visual de un nodo controlador con sus 4 campos llenos, al lado del de un broker — comparando qué cambia.

**S12 — controller.quorum.voters: la libreta del directorio**
- Contenido: Lista estática de los controladores del quorum, en formato `id@host:puerto`. Todos los nodos la conocen para saber a quién pedirle la metadata y con quién votar. Ejemplo: `1@ctrl1:9093,2@ctrl2:9093,3@ctrl3:9093`.
- Nota: Punto de dolor frecuente: si esta lista no calza entre nodos, el quorum no se forma. Es el equivalente KRaft del viejo `zookeeper.connect`, pero apuntando a los propios controladores. En la sesión 3 veremos que el Dynamic Quorum flexibiliza esto.

**S13 — Listeners: separar el plano de control del de datos**
- Contenido: Un nodo puede exponer varios listeners. `controller.listener.names` designa cuál es para el tráfico entre controladores (votos, replicación de metadata); los otros sirven a clientes y brokers. Separarlos aísla el consenso del ruido de datos.
- Nota: Conectar con `advertised.listeners` que verán en el Lab 04: los listeners son un tema transversal. Aquí el foco es el listener **de controlador**. Analogía — **la línea telefónica privada del directorio**, separada de la centralita que atiende al público.

**S14 — kafka-storage.sh: el acta de nacimiento del clúster**
- Contenido: Antes de arrancar, cada nodo formatea su directorio de metadata con `kafka-storage.sh`. Dos pasos: generar un **cluster id** (un UUID único del clúster) y **formatear** el log de metadata de cada nodo con ese id. Sin este paso, el nodo no sabe a qué clúster pertenece.
- Nota: Analogía ancla — **el acta de nacimiento con número de folio**. El cluster id es el folio único; formatear es inscribir a cada nodo bajo ese folio. Sembrar el error clásico del Lab 01: si dos nodos se formatean con cluster ids distintos, se rechazan (`InconsistentClusterIdException`) — como dos hermanos con actas de familias distintas.

### Bloque 2 — Del parámetro al arranque (15 min, S15–S16)

**S15 — El ciclo de vida de un arranque KRaft**
- Contenido: Secuencia: (1) generar cluster id → (2) formatear cada nodo con `kafka-storage.sh format` → (3) arrancar los controladores → (4) forman quorum y eligen líder → (5) arrancan los brokers y se registran. El clúster está vivo.
- Nota: Este es el mapa del Lab 01. Recorrerlo prometiendo: "estos cinco pasos son exactamente lo que van a teclear en el próximo práctico".
- Diagrama [ANCLA]: los 5 pasos como flujo numerado, del cluster id al clúster operativo.

**S16 — Cierre Sesión 2**
- Contenido: Los parámetros son el carnet del nodo; `kafka-storage.sh` es el acta de nacimiento; el arranque es una secuencia predecible. Próxima sesión: cuántos controladores y el Dynamic Quorum.
- Nota: Puente a la sesión 3. Anticipar que después del último bloque teórico, se abre la terminal.

---

## SESIÓN 3 — Dimensionamiento del quorum y Dynamic Quorum

**Objetivo:** que el alumno sepa decidir entre 3 y 5 controladores con criterio, y entienda cómo el Dynamic Quorum permite incorporar y dar de baja controladores sin reformatear el clúster.

### Bloque 1 — 3 vs 5: la decisión de dimensionamiento (22 min, S17–S19)

**S17 — La pregunta del millón: ¿3 o 5 controladores?**
- Contenido: 3 controladores → tolera 1 caída, mayoría = 2, menos overhead de replicación. 5 → tolera 2 caídas, mayoría = 3, más resiliencia pero más tráfico de consenso. Número **impar** siempre (para que la mayoría sea inequívoca).
- Nota: La regla práctica para esta audiencia: 3 cubre la gran mayoría de los casos; 5 se justifica cuando tolerar 2 fallos simultáneos es un requisito duro (multi-rack, multi-AZ). Más de 5 rara vez vale el costo de consenso.
- Diagrama [ANCLA]: comparativa lado a lado — quorum de 3 vs 5, con "tolera N caídas", "mayoría", y "costo de consenso" en cada uno.

**S18 — Por qué SIEMPRE impar**
- Contenido: Con número par, un empate es posible (2 vs 2) y no hay mayoría clara → riesgo de indecisión o split-brain. Impar garantiza que siempre haya una mayoría estricta. 4 controladores no toleran más fallos que 3, pero cuestan más: lo peor de ambos mundos.
- Nota: Dato contraintuitivo que engancha: 4 controladores toleran lo mismo que 3 (una caída) pero con más overhead. Por eso nadie usa números pares. Analogía — **un jurado con número impar para que nunca haya empate**.

**S19 — Dynamic Quorum: cambiar el directorio en caliente**
- Contenido: Históricamente el quorum era estático (la libreta `controller.quorum.voters` fija). El **Dynamic Quorum** (KIP-853) permite **agregar y quitar controladores en caliente**, sin reformatear ni parar el clúster — usando `kafka-metadata-quorum.sh` para gestionar los votantes.
- Nota: Novedad relevante de Kafka moderno. Aterrizar en NovaTech: "si mañana NovaTech necesita pasar de 3 a 5 controladores por crecimiento, no reconstruye el clúster: incorpora los nuevos en vivo". Conecta directo con el Lab 02, donde validarán el quorum.

### Bloque 2 — Cierre teórico de la unidad (8 min, S20)

**S20 — Cierre de la teoría de KRaft**
- Contenido: Síntesis: (1) KRaft interioriza la metadata sin ZooKeeper; (2) los parámetros definen roles, quorum y listeners; (3) se dimensiona impar (3 o 5) y el Dynamic Quorum lo flexibiliza. Ahora: manos a la terminal.
- Nota: Cierre del bloque teórico de la Unidad 2. Transición a los dos laboratorios: "dejamos la pizarra; vamos a inicializar un clúster KRaft de verdad y a romperlo a propósito para verlo resistir".

---

## SESIÓN 4 (PRÁCTICO) — Lab 01: Inicialización KRaft

**S21 — [LAB] Lab 01 · Inicialización KRaft**
- Contenido:
  - **Objetivo**: formatear el log de metadatos y hacer el bootstrap de un quorum de tres controladores con `kafka-storage.sh`.
  - **Vas a hacer**: generar el cluster id, formatear cada nodo, arrancar el quorum, verificar que el clúster nace sin ZooKeeper.
  - **El desafío**: provocar y entender el `InconsistentClusterIdException`.
  - **Entorno**: Docker Compose · Kafka 4.2 · KRaft.
- Nota: Aquí se abre la terminal. Conectar con la teoría recién vista: "el acta de nacimiento (S14) y los 5 pasos del arranque (S15) los van a ejecutar ahora de verdad". Recordar el patrón del cluster id: los nodos deben compartir folio o se rechazan. Duración ~60 min. Remitir al README del Lab 01 y al reporte entregable. Tener a mano `bin/90-test-lab.sh` para que el alumno valide su avance.

---

## SESIÓN 5 (PRÁCTICO) — Lab 02: Validación de quorum y prueba de resiliencia

**S22 — [LAB] Lab 02 · Validación de quorum y prueba de resiliencia**
- Contenido:
  - **Objetivo**: validar el estado del quorum con `kafka-metadata-quorum.sh` y ejecutar una prueba de resiliencia real.
  - **Vas a hacer**: inspeccionar el quorum y el líder de metadatos, **apagar un controlador**, y verificar la reelección del líder y la continuidad del servicio.
  - **El momento de la verdad**: ver el failover del plano de control en vivo — lo que dibujamos en pizarra, ahora pasando de verdad.
  - **Entorno**: Docker Compose · Kafka 4.2 · KRaft · quorum de 3.
- Nota: El "wow" honesto de la Unidad 2 hecho realidad. Conectar con S6 y S8: el quorum tolera perder 1 controlador; lo van a comprobar apagándolo. Enfatizar la lectura de `kafka-metadata-quorum.sh` (quién era líder antes y después). Duración ~60 min. Remitir al README y al reporte. Cierre de la Unidad 2: "inicializaron un clúster KRaft y lo vieron sobrevivir a la caída de un controlador — sin ZooKeeper, sin intervención manual".

---

## Resumen ejecutivo del guion

| Sesión | Tipo | Slides | Diagramas [ANCLA] |
|---|---|---|---|
| 1 · KRaft a fondo | Teoría | S1–S10 (10) | Roles process.roles (S5), Tolerancia 3vs5 (S8) |
| 2 · Parámetros clave | Teoría | S11–S16 (6) | Carnet del nodo (S11), Ciclo de arranque (S15) |
| 3 · Dimensionamiento | Teoría | S17–S20 (4) | Comparativa 3 vs 5 (S17) |
| 4 · Lab 01 | Práctico | S21 (1, puente) | — |
| 5 · Lab 02 | Práctico | S22 (1, puente) | — |

**Total Cap 2: 22 slides** (20 teóricas + 2 puente de laboratorio).

**Analogías ancla del capítulo (para pizarra):**
- La empresa que arrienda su bóveda en el banco de enfrente → ZooKeeper externo vs KRaft interno (S3).
- Kafka toma su propia medicina: la metadata es un log → KRaft (S4).
- El directorio que vota por mayoría → consenso Raft (S7).
- El carnet + domicilio + libreta de socios → parámetros del nodo (S11).
- El acta de nacimiento con folio → cluster id y kafka-storage.sh (S14).
- El jurado de número impar → por qué 3 o 5, nunca par (S18).

**Diagramas [ANCLA] a renderizar (5):** S5, S8, S11, S15, S17.
**Todo lo demás marcado [PIZARRA]:** el instructor lo dibuja en clase.

**Slides puente de laboratorio (2):** S21 (Lab 01), S22 (Lab 02) — enmarcan prácticos ya construidos y validados; no los desarrollan.

**Pendientes que este guion deja registrados:**
1. Vertido a template Netec (misma plantilla que Cap 1).
2. Los 5 diagramas ANCLA a renderizar en la fase visual.
3. Confirmar contra el material del Lab 01/02 los nombres exactos de scripts al armar las slides puente (el guion cita los del temario: `kafka-storage.sh`, `kafka-metadata-quorum.sh`).
