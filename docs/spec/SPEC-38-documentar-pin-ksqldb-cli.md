# SPEC-38 — Documentar el pin de `cp-ksqldb-cli` en 8.0.3

**Tipo:** Doc / Comentario en código (cambio mínimo)
**Fecha:** 2026-07-18
**Autor:** Arquitecto (Claude)
**Ejecuta / commitea:** Mocito (Claude Code, dev)
**PO:** Rodrigo
**Rama:** `spec-01-reestructura-sunat`
**Estado:** CERRADO — commit `54c4c22`

---

## 0. Contexto y decisión

En `lab-12` (ksqlDB), todo el stack va en 8.2.0 excepto `cp-ksqldb-cli`, fijado en 8.0.3. Marcado como
"duda abierta" en SPEC-36. Resuelto por verificación contra Docker Hub (2026-07-18):

- `confluentinc/cp-ksqldb-server` → SÍ tiene tag 8.2.0.
- `confluentinc/cp-ksqldb-cli` → NO tiene tag 8.2.0; su último build es de la serie 7.x (7.9.6).
  Confluent dejó de publicar el CLI a la par de la plataforma.

**Conclusión:** el 8.0.3 no es un descuido; es la versión funcional disponible y opera correctamente
contra el server 8.2.0. **Decisión del PO: dejarlo en 8.0.3** y documentar el porqué. No se cambia la
versión; solo se añade un comentario explicativo.

---

## 1. Cambio

**P1 —** En `labs/lab-12-ksqldb/infra/docker-compose.yml`, sobre la línea `image: confluentinc/cp-ksqldb-cli:8.0.3`,
añadir un comentario explicando el pin intencional.
> R: Comentario de 4 líneas añadido sobre la línea (ahora línea 219), indentación de 4 espacios.

**P2 —** No tocar ninguna otra línea, ni `.env`, ni otros labs.
> R: Solo ese comentario.

---

## 2. Verificación

**P3 —** `git diff` debe mostrar solo líneas de comentario, cero cambios de `image:`.
> R: Diff = 4 líneas `+  #`. Versión intacta en 8.0.3.

**P4 —** (Opcional) `docker pull confluentinc/cp-ksqldb-cli:8.0.3`.
> R: Omitido; el harness ya lo ejercitó (SPEC-39, lab-12 PASS).

---

## 3. Commit

**P5 —** Commit único, sin firmas de IA.
> R: `54c4c22 docs(lab-12): explica pin de cp-ksqldb-cli en 8.0.3 (sin build 8.2.x)`. 1 file, 4 insertions.

**P6 —** NO push ni merge.
> R: Commit local.

---

## 4. DoD

- [x] Comentario añadido sobre la línea de `cp-ksqldb-cli`.
- [x] Versión intacta (8.0.3), diff solo comentario.
- [x] Commit sin firmas de IA.
- [x] Sin push ni merge.
- [x] "Duda abierta" de SPEC-36 → cerrada. Validado en ejecución: lab-12 PASS (SPEC-39).

---

*SPEC-38 · Documentar pin ksqldb-cli · Arquitecto → Mocito · 2026-07-18 · verificado contra Docker Hub.*
