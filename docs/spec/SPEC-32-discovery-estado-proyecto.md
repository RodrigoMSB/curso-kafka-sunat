# SPEC-32 — Discovery: mapeo del estado actual del proyecto SUNAT

**Tipo:** Discovery / Handoff (preguntas + respuestas verificadas)
**Fecha:** 2026-07-08
**Autor:** Arquitecto (Claude) · **Responde:** Mocito (Claude Code, dev) · **PO:** Rodrigo
**Rama de referencia:** `spec-01-reestructura-sunat`
**Estado:** CERRADO — respondido con evidencia

> Regla del ejercicio: nada de memoria. Cada respuesta cita comando/output o `ruta:línea`.
> Lo no verificable → `NO-VERIFICADO` + motivo. Evidencia capturada el 2026-07-08 sobre HEAD `f44e668`
> (previo a los commits SPEC-33 `9157bed` y la creación de `docs/spec/`).

---

## 1. Control de versiones

**P1.1 — HEAD / rama.** HEAD `f44e668` en `spec-01-reestructura-sunat`, **viva y sin mergear**.
`git rev-list --left-right --count origin/main...spec-01` → `0  118` (0 en main-only, 118 spec-only).
`main` no ha recibido nada de este trabajo.

**P1.2 — Working tree.** No limpio, pero **todo untracked** (nada staged/modificado sobre tracked):
`VALIDACION-STATUS.md`, `presentacion/guiones/guion-slides-cap{2..5}.md`,
`presentacion/ppt-template/template-sunat.pptx`, `presentacion/ppt/arregladas/`.

**P1.3 — Últimos commits.** Lo reciente es presentación (PPT Cap 1) sobre el cierre de labs/tests.
**Corrección:** el historial **no menciona ningún `SPEC-NN`** en mensajes de commit.

**P1.4 — `.git`.** Real y versionado. Remoto `origin = https://github.com/RodrigoMSB/curso-kafka-sunat.git`.
Que el zip no trajera `.git` fue recorte del empaquetado.

---

## 2. Los dos fixes de script

**P2.1 — Lab 07 (`--threads`): FIX APLICADO.** `consumer-perf-test.sh:44-48` usa `--fetch-size`, sin
`--threads` (`grep -rn "\-\-threads" labs/` → NONE). Commit `fb128e6`. El harness lo ejercita directo
(`tests/lab-07.sh:26`). El `VALIDACION-STATUS.md` que lo da FAIL es **previo al fix** (untracked, 06-30).

**P2.2 — Lab 10 (`}` de más): FIX APLICADO.** `rest-produce.sh:6-11` — default en `DEFAULT_VALUE` y
`VALUE="${2:-$DEFAULT_VALUE}"`, sin `}` anidado. Commit `cb4c06f`. Ejercitado por `tests/lab-10.sh:31`.

**P2.3 — Confianza en 14/14: ALTA.** El harness invoca los mismos `.sh` del alumno y además corre
`bin/90-test-lab.sh` sobre el clúster vivo. Matiz: cubre las rutas felices que cada `tests/lab-NN.sh`
decide ejercitar; un flag no invocado podría divergir. Para los dos casos preguntados, la ruta rota
es la ruta testeada.

---

## 3. Cierre del "SPEC-31"

**P3.1 — Trabajo commiteado; el "SPEC-31" como documento NO existe en el repo.**
`git log --grep="SPEC-31"` → vacío. El trabajo F-04/F-11/F-13 vive en commits descriptivos
(`b7137ae`, `14d4b44`, `5b3e32a`, `12c577f`, `323d7d9`). Cerrado.

**P3.2 — Apodo del operador: CERO en todas las zonas** (active/`_fuente-extra`/auditoria/presentacion).
Más limpio que lo que esperaba la auditoría. `_archive-28h/` está **borrado** (`git rm -r`, 147 archivos
solo en historial). `_fuente-extra/` sí persiste.

**P3.3 — Soluciones F-01/02/03 redactadas** (commits `43bd7ff`, `09a71f1`): lab-05 Parte 4 sin celdas
vacías; lab-07 Parte 3 respondida; lab-14 plantilla expandida (109 líneas). F-12 también cerrado
(plantilla ya se llama `reporte-entregable.md`).

---

## 4. Frontera repo ⇄ PPT ⇄ materiales

**P4.1 — El PPT vive en `presentacion/`.** Al momento del discovery **no existía** el deck COMPLETO
(solo Cap 1, 30 slides). *Actualizado:* el PO versionó `curso-sunat-COMPLETO.pptx` (147 slides), objeto
del SPEC-33. La "premisa de 147 slides" venía confundida con el deck fuente Strimzi (128 slides), del
que se extrajo la plantilla Netec.

**P4.2 — El PPT se DERIVA de los labs, pero la sync es MANUAL** (guion → python-pptx). No hay mecanismo
automático ni checklist. Frágil.

**P4.3/P4.4/P4.5 — NO-VERIFICADO:** materiales de aula, plantillas Netec con DRM y banco de quizzes
**no están en el repo** (`find` → vacío). Viven fuera (Drive/local); su estado lo confirma el PO.

---

## 5. Reproducibilidad y entorno

**P5.1 — Versiones por variable en `.env`, tag exacto** (`image: confluentinc/cp-kafka:${KAFKA_VERSION}`,
`KAFKA_VERSION=8.2.0`, `KAFBAT_UI_VERSION=v1.5.0`), no `@sha256` en la línea `image:` (el digest de
kafbat solo va en comentario). `KAFKA_VERSION=8.2.0` = tag de imagen Confluent Platform, no "Kafka 4.2.1".

**P5.2 — NO hay CI** (`.github` inexistente). Validación 100% manual en Mac Studio. El "por qué" →
NO-VERIFICADO.

**P5.3 — Portabilidad Windows/Git-Bash: solo auditada estáticamente.** Sin evidencia de corrida en
Windows real. Entorno objetivo del alumno SUNAT no documentado → NO-VERIFICADO.

**P5.4 — 794s / ~13 min es UNA corrida** (report gitignored). Estabilidad no garantizada; labs 13/14
son los más dependientes de recursos locales → NO-VERIFICADO.

---

## 6. DoD y convenciones

**P6.1 — Estructura de "lab terminado" uniforme:** `guia/ soluciones/ plantillas/ kafka-cli|infra/
bin/{90,95}-*.sh docs/troubleshooting.md README.md _fuente-extra/` + `tests/lab-NN.sh`. Los 14 tienen
`troubleshooting.md`. Rúbrica formal → NO-VERIFICADO (no está en el repo).

**P6.2 — Los SPEC NO se versionaban en el repo** (sin carpeta `specs/`, sin SPEC-NN en el log).
*Resuelto por SPEC-33:* se crea `docs/spec/` y se versionan SPEC-32 y SPEC-33.

**P6.3 — Numeración:** el repo no conocía ningún SPEC → NO-VERIFICADO desde git. Se acepta 32/33 según
registro del equipo.

**P6.4 — Regla dura confirmada:** autoría 100% `RodrigoMSB`, cero `Co-authored-by` / firmas de IA en
los 119 commits. Se respeta en todo lo producido.

---

## 7. Deuda técnica

**P7.1 —** F-07 (tópicos heredados `novatech.lab10/09/12.*`): **no renombrados, documentados como
intencionales** (`lab-11/README.md:115`, commit `2db67fe`). F-14 (FORWARD/FULL): **actividad opcional
añadida** (`lab-11/guia/01-schema-registry.md:152-157`, commit `8160a7b`).

**P7.2 —** F-05 (ítem 20, quórum 3 controladores): **cerrado por documentación** como cobertura
repartida Lab 01→02 (commit `b3855fe`).

**P7.3 — Deuda no cazada por la auditoría:** (1) sync labs↔PPT manual sin red de seguridad;
(2) 14/14 de una sola corrida, sin CI/regresión; (3) `consume-avro.sh` usa `docker exec -it` (falla sin
TTY en pipe); (4) guiones cap2-5 y varios PPT untracked.

---

## 8. Entrega y calendario

**P8.1/P8.2 — NO-VERIFICADO desde el repo:** no lleva estado de entrega, deadlines ni definición de
entregable. Los materiales de aula no están versionados aquí.

**P8.3 — Mayor riesgo:** la frontera **no versionada y sincronizada a mano** entre el repo (labs, sano,
14/14) y todo lo que vive fuera (PPT a medio construir + materiales de aula ausentes del repo +
plantillas Netec bloqueadas por DRM).

---

## TL;DR

1. **Rama/HEAD:** `spec-01-reestructura-sunat` @ `f44e668`, viva y sin mergear (118 adelante de main).
2. **14/14:** real y confiable — fixes lab 07/10 aplicados (`fb128e6`, `cb4c06f`); `VALIDACION-STATUS.md`
   que los da FAIL está obsoleto (untracked, pre-fix).
3. **"SPEC-31":** trabajo commiteado y cerrado; el SPEC como documento no existía en el repo.
4. **PPT/materiales:** PPT en `presentacion/` (Cap 1 al momento del discovery; deck COMPLETO de 147
   slides versionado después → SPEC-33). Materiales de aula NO en el repo.
5. **Mayor riesgo:** frontera no versionada repo ⇄ entregable de aula (fuera de git, con DRM Netec).

---

*SPEC-32 · Discovery del estado del proyecto · Arquitecto → Mocito · 2026-07-08 · cerrado.*
