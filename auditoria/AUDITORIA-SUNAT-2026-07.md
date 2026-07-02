# Auditoría clasificada — Curso Kafka SUNAT

**Fecha:** 2026-07-02 · **Rama:** `spec-01-reestructura-sunat` (sin mergear) · **Rol:** auditor escéptico
**Alcance:** los 14 labs + tests + docs. Solo REPORTA; cero fixes (salen en un spec posterior tras clasificación en firme de Rodrigo/arquitecto).
**Método:** verificación empírica local (provocar el comando y ver qué pasa) > consistencia mecánica (grep/diff/conteo) > lo no verificable localmente → PENDIENTE-EXTERNA (no se valida de memoria).

---

## 1. Resumen ejecutivo

| Clasificación | Conteo |
|---|---|
| CRÍTICO | 0 |
| MAYOR | 5 |
| MENOR | 11 |
| COSMÉTICO | 1 |
| PENDIENTE-EXTERNA | 3 |

**Veredicto general:** el curso **corre** (harness 14/14 verde, verificado) y la **cobertura del temario es sustancialmente completa** (13/14 ítems CUBIERTOS; ítem 20 PARCIAL por diseño de secuencia). **Cero hallazgos CRÍTICOS**: ningún comando enseñado falla ni ninguna afirmación técnica provocada resultó falsa — al contrario, todas las afirmaciones empíricas verificadas (rechazo de thread-count >2×, broker-4 como Observer, 415 por Content-Type, rechazo de schema incompatible, BACKWARD por defecto, rechazo de escritura con ISR<min.insync) se confirmaron con salida real. Los hallazgos se concentran en: (a) **soluciones con partes sin responder** (labs 05, 07, 14), (b) **fuga del apodo "MOCITO"** en nombres de plantillas activas, (c) inconsistencias menores de naming/numeración/duración.

---

## 2. Tabla de hallazgos

| ID | Dim | Ubicación | Hallazgo | Evidencia | Clasif. propuesta | Fix (1 línea) |
|---|---|---|---|---|---|---|
| **F-01** | E | labs/lab-05-*/soluciones/reporte-resuelto.md (Parte 4) | La solución deja la Parte 4 (retención) con celdas EN BLANCO — preguntas de guía+reporte sin respuesta modelo | `reporte-resuelto.md:68,70,71` filas `| … | |` vacías (offset `--time -2`, tamaño en disco, borrado por segmentos) | **MAYOR** | Redactar las 3 respuestas modelo de retención |
| **F-02** | E | labs/lab-07-*/soluciones/reporte-resuelto.md (Parte 3) | Solución deja el "Análisis" de Parte 3 sin responder | `reporte-resuelto.md:72-73` preguntas "¿cuál throughput mayor?/¿qué parámetro impactó más?" sin respuesta | **MAYOR** | Redactar las 2 respuestas de análisis |
| **F-03** | E | labs/lab-14-*/plantillas/reporte-evaluacion-final.md + soluciones | Plantilla condensada deja huérfanas muchas preguntas de las 6 guías (TLS alias/SANs, SASL usuarios, ACL a app3, min.ISR con RF=5) sin fila ni respuesta modelo | guia/01:77-79,121-123 · guia/02:46-48,125-127 · guia/03:150-152 · guia/04:49-50,192-194 sin correspondencia en plantilla/solución | **MAYOR** | Expandir plantilla+solución del 14 a las preguntas de guía |
| **F-04** | D | labs/lab-{07,11,12,13}/plantillas/reporte-entregable-VALIDADO-MOCITO.md | El apodo del operador ("MOCITO") aparece en NOMBRES de archivo trackeados en plantillas ACTIVAS del curso | `git ls-files \| grep MOCITO` → 4 archivos en plantillas activas (+ 3 en `_archive-28h/`) | **MAYOR** | Renombrar/mover a `_fuente-extra/` sin el sufijo MOCITO |
| **F-05** | A | labs/lab-01-*/guia/02-mi-primer-broker.md | Ítem 20 nombra "bootstrap de quórum de TRES controladores"; el Lab 01 termina en 1 nodo (los 3 llegan en Lab 02) | guia/02:1 "broker solitario"; :50 `1@kafka-broker:39092` (un voter); cierre → "en el Lab 02… 3 nodos". Lab 02 guia/01:41-45 los 3 voters | **MAYOR** (¿reclasificar a cobertura repartida válida?) | Decisión de arquitecto: aceptar reparto 01→02 o mover el bootstrap-3 al Lab 01 |
| **F-06** | C | los 14 README | Duración declarada vs 60 min/práctico del temario: 01/02=45, 03/04=40, 14=90 | grep "Duración estimada" por README | **MENOR** | Alinear o justificar deltas (14=capstone) |
| **F-07** | C | kafka-cli/infra de labs 11,12,13,14 | Identificadores de tópico heredados no coinciden con el nº de lab: 11/12 usan `novatech.lab10.*`, 13 usa `novatech.lab09.*`, 14 usa `novatech.lab12.*` | `grep -rhoE 'novatech\.[a-z0-9.]+'` por lab | **MENOR** | Renombrar a `lab11/12/13/14` o documentar la herencia |
| **F-08** | E | 11 de 14 README | Solo 01/02/04 mencionan `bin/90-test-lab.sh`; el 95 sí es uniforme (SPEC-29) | Menciones 90 solo en lab-01:36, lab-02:42, lab-04:42 | **MENOR** | Añadir la línea del 90 a los 11 README restantes |
| **F-09** | C | labs/lab-07-*/guia/04-desafio-particionado-y-throughput.md:1 | Título "# Parte 5" en el 4º archivo de guía; el enlace entrante lo llama "Parte 4" (salto 3→5) | guia/03:68 enlaza "Parte 4"; guia/04:1 dice "Parte 5" | **MENOR** | Renumerar el H1 a "Parte 4" |
| **F-10** | C | labs/lab-11-*/guia/02-avro-en-accion.md:89 | Referencia a "Parte 4 (JOIN)" inexistente en el lab-11 (el JOIN ocurre en lab-12) | `## Actividad 6: … (para JOIN en Parte 4)` | **MENOR** | Reformular la referencia (apuntar al Lab 12) |
| **F-11** | E | plantillas de labs 05,06 (VALIDADO) y 07,11,12,13 (VALIDADO-MOCITO) | Plantillas "VALIDADO" stale duplicadas en `plantillas/` activas (en 01-04 ya se movieron a `_fuente-extra/` en SPEC-26; en 05-14 no) | `git ls-files \| grep VALIDADO` fuera de `_fuente-extra` | **MENOR** | Mover a `_fuente-extra/` (unifica con 01-04) |
| **F-12** | C/E | labs/lab-14-*/plantillas/ | El 14 usa `reporte-evaluacion-final.md` (no `reporte-entregable.md` como los otros 13) y no se referencia desde guía/README | Tabla de estructura: lab-14 "NO" en columna reporte-entregable | **MENOR** | Renombrar a `reporte-entregable.md` o referenciarlo |
| **F-13** | D | `_archive-28h/` (raíz, 147 archivos trackeados) | El curso viejo de 28h está versionado; contiene identidad "28h" y nombres "MOCITO" | `git ls-files _archive-28h \| wc -l` = 147 | **MENOR** | Decidir: `.gitignore` / rama aparte / conservar como histórico |
| **F-14** | A | labs/lab-11-* | Modos de compatibilidad: solo BACKWARD se ejercita; FORWARD/FULL quedan conceptuales (no hay `set-compatibility`) | Agente A: tabla explica los 4 modos; solo BACKWARD activo | **MENOR** | Añadir actividad opcional que cambie a FORWARD/FULL |
| **F-15** | A/H4 | labs/lab-10-*/README.md | La sustitución Landoop→kafbat vive en el ADR pero es invisible al alumno del lab-10 (cero mención de "Landoop") | `grep -rin landoop labs/lab-10-*` → vacío; ADR-001 sí la documenta | **MENOR** | Nota de 1 línea en README lab-10 aludiendo al ítem "Landoop" |
| **F-16** | E | labs/lab-02-*/soluciones vs plantillas | La solución (Parte 1) responde preguntas distintas a las de la plantilla (voters vs CLUSTER_ID/puertos); "evidencia de descubrimiento" sin respuesta modelo | reporte-resuelto.md:26-31 vs reporte-entregable.md:9-11 | **MENOR** | Alinear preguntas plantilla↔solución |
| **F-17** | E | labs/lab-01-*/plantillas vs guía | Divergencia de redacción plantilla↔guía (usuario/dirs vs binarios/Java/paths); la solución sí cubre la guía | reporte-entregable.md:9-10 vs guia/01:31-34 | **COSMÉTICO** | Alinear redacción de la plantilla |

---

## 3. PENDIENTE-EXTERNA (verificación del arquitecto contra fuentes oficiales)

| ID | Afirmación / ubicación | Por qué no se verificó localmente | Acción sugerida |
|---|---|---|---|
| P-01 | Lab 01 desafío (soluciones/reporte-resuelto.md): "arrancar con storage de OTRO cluster-id falla con INCONSISTENT_CLUSTER_ID" | Es un escenario **multi-nodo** (broker vs quórum de otro clúster); el Lab 01 es de UN nodo → no reproducible localmente. La protección del storage (kafka-storage rehúsa reformatear) sí es real pero el mensaje exacto no se aisló limpiamente | Verificar nombre exacto del error vs docs KRaft, o reclasificar la respuesta modelo del desafío |
| P-02 | Lab 09 guías (prosa): Spring Boot 4.1 / spring-kafka 4 / Jackson 3 (`JacksonJsonSerializer`, `ADD_TYPE_INFO_HEADERS`) | Afirmaciones sobre versiones/semántica de frameworks externos; el harness compila e interopera (verificado) pero no valida las versiones declaradas contra release notes | Verificar versiones/APIs vs documentación oficial de Spring/Jackson |
| P-03 | Lab 14: nombre exacto de la excepción `NotEnoughReplicas` | Comportamiento verificado (escritura RECHAZADA con ISR<min.insync, ver B7); el string exacto quedó en la línea de causa del stack no aislada. Semántica estándar de Kafka | El arquitecto puede dar por buena la semántica estándar (acks=all + ISR<min.insync ⇒ NotEnoughReplicas) |

---

## 4. Dictamen de hipótesis (H1–H4)

- **H1 (ítem 20) — CONFIRMADA.** El Lab 01 termina en 1 nodo (`guia/02:50` un voter; título "broker solitario"); los 3 controladores llegan en Lab 02 (`guia/01:41-45`). La secuencia 01→02 cubre "quórum de 3" **antes** del práctico del ítem 21, pero es un **gap del Lab 01 contra su propio ítem 20**. → hallazgo **F-05** (MAYOR; arquitecto decide si es "cobertura repartida válida").
- **H2 (ítem 35) — CONFIRMADA y VERIFICADA EMPÍRICAMENTE.** La prueba negativa existe (`guia/01` Actividad 4, `pedido-v3-incompatible.avsc`) y **funciona**: registrar el schema incompatible devolvió `error_code 40901` (HTTP 409), `READER_FIELD_MISSING_DEFAULT_VALUE` para `tarjeta_credito`. El SR impide la publicación incompatible. Ítem 35 cubierto (matiz FORWARD/FULL en F-14).
- **H3 (ítem 36) — CONFIRMADA.** Lab 12 trabaja TABLE (`CREATE TABLE clientes_table`) y consulta persistente (`CREATE STREAM pedidos_rekey … AS SELECT … PARTITION BY`), no solo STREAM efímero.
- **H4 (ítem 34) — MATIZADA.** La sustitución Landoop→kafbat está documentada en `docs/adr/ADR-001` (visible al instructor) pero **invisible al alumno** del lab-10 (cero mención de "Landoop"). → hallazgo **F-15** (MENOR).

---

## 5. Evidencia empírica (Dimensión B) — provocaciones corridas

| # | Afirmación | Resultado | Veredicto |
|---|---|---|---|
| B1 | Lab 01: storage de otro cluster-id falla | No reproducible en single-node; protección de storage real | → **P-01** |
| B2 | Lab 03: props del compose = STATIC_BROKER_CONFIG | Verificado en e2e SPEC-27 (`kafka-configs --all` contiene STATIC) + guía | **VERIFICADO** |
| B3 | Lab 08: rechaza thread-count >2× | Real: *"Dynamic thread count update validation failed for num.replica.fetchers=5, value should not be greater than double the current value 1"* | **VERIFICADO** |
| B4 | Lab 08: broker-4 se une como Observer | `describe --replication` → `NodeId 4 … Status Observer` | **VERIFICADO** |
| B5 | Lab 10: Content-Type incorrecto → 415 | `text/plain` → **HTTP 415**; correcto → 200 | **VERIFICADO** (la guía lo plantea como pregunta, no lo afirma en voz alta) |
| B6 | Lab 11: modo de compatibilidad del SR | `GET /config` → `{"compatibilityLevel":"BACKWARD"}` | **VERIFICADO** |
| B7 | Lab 14: ISR<min.insync + acks=all → error | Con ISR=1<2, produce `acks=all` **rechazado** (`Error when sending message … with error`); string exacto → P-03 | **VERIFICADO (comportamiento)** |
| B8 | Lab 04: dos públicos del EXTERNAL | Verificado en SPEC-28 (contenedor por 9092 → TimeoutException; por 29092 → OK) | **VERIFICADO** |

Todas las provocaciones con **teardown completo** posterior (verificado: cero contenedores del curso al cierre; los `*-postgres` ajenos de Rodrigo intactos).

---

## 6. Inventario de credenciales didácticas (D.2)

Todas confinadas a `labs/lab-14-capstone-resiliencia-seguridad/` (declaradas de laboratorio; **no** es hallazgo, es inventario). No hay secretos fuera del lab-14.

| Credencial | Valor | Ubicación |
|---|---|---|
| Usuario admin / password | `admin` / `admin-secret` | infra/client-properties/admin.properties · infra/.env |
| Usuario app1 / password | `app1` / `app1-secret` | infra/client-properties/app1.properties · infra/.env |
| Usuario app2 / password | `app2` / `app2-secret` | infra/client-properties/app2.properties · infra/.env |
| Truststore / keystore password | `changeit` | client-properties/*.properties · infra/.env (`TLS_KEYSTORE_PASSWORD`) |

Material criptográfico (`*.jks/*.crt/*.key/*.csr`): **nunca trackeado** (árbol actual e histórico `git log --all --diff-filter=A` vacíos); `.gitignore` excluye `**/infra/certs/*`.

---

## 7. Higiene y coherencia — resultados limpios (sin hallazgo)

- **Unidades** (C1): 01-02→U2, 03-08→U3, 09-14→U4 — **todas correctas** vs temario.
- **Identidad vieja** (C6): cero `28 horas`/`Capítulo N`/`Landoop` fuera de `_fuente-extra/`, `_archive-28h/` y el ADR.
- **Autoría** (D3): muestreo 10 commits → 100% RodrigoMSB; sin `Co-authored-by`/`Generated with`. (Única aparición de "claude" en el historial: la ruta `.claude/` citada en el commit `chore: ignore .claude/` — referencia factual, no firma → transparencia, no hallazgo.)
- **Menciones de IA/generadores en contenido** (D4): cero en el texto de los materiales (los "generado por" hallados son prosa legítima: "archivo generado por la imagen"). *La fuga "MOCITO" es en nombres de archivo, no en contenido* → F-04.
- **Scripts referenciados** (E2): todas las rutas `.sh` citadas en guías existen y son ejecutables (14/14 labs).
- **Cross-refs markdown** (C5): cero enlaces `.md` colgantes; los cuelgues son de numeración textual "Parte N" (F-09, F-10).
- **Estructura de soporte** (C7): los 14 labs tienen 90 + 95 + troubleshooting + reporte-resuelto + tests/lab-NN.sh; excepción de naming en reporte-entregable del 14 (F-12).
- **Prerrequisitos encadenados** (C3): 01→02→{03,04} explícitos en README/guías; 05+ independientes con su `start-lab.sh`.

---

*Auditoría — Curso Kafka SUNAT — 2026-07 · solo hallazgos, sin fixes.*
