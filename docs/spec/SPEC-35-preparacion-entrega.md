# SPEC-35 — Preparación de entrega (release del curso SUNAT)

**Tipo:** Release / Entrega
**Fecha:** 2026-07-08
**Autor:** Arquitecto (Claude)
**Ejecuta / commitea:** Mocito (Claude Code, dev)
**PO:** Rodrigo
**Rama:** `spec-01-reestructura-sunat`
**Estado:** RESUELTO — decisiones del PO tomadas; ejecución en SPEC-40

---

## 0. Objetivo

Dejar el curso listo para entrega a Netec/SUNAT: repo consolidado, con índice de entrada,
integrado a `main` y marcado con una versión. Cierra el ciclo abierto desde SPEC-32.

**Suposición declarada:** la entrega es el curso técnico = repo de labs + tests + docs. Los
materiales de aula (flashcards, biblioteca, quizzes, proyecto final) y la presentación se
entregan por canal Netec, fuera de este repo.

---

## 1. Decisiones del PO

- **DEC-1 · Estrategia de integración a `main`:** PR con merge `--no-ff` (registro formal + historial preservado).
- **DEC-2 · Tag de versión:** `v1.0.0`.
- **DEC-3 · Composición del paquete:** `main` = repo técnico (labs + tests + docs). La presentación sale del repo (SPEC-37) y se entrega por canal Netec. Materiales de aula, fuera del repo.

---

## 2. Trabajo de preparación

- **T-1 · README raíz:** colocado como `/README.md` (commit `1f29a33`).
- **T-2 · Verificación pre-entrega:** harness 14/14 verde (SPEC-39, corrida fresca 2026-07-18); working tree limpio.
- **T-3 · Higiene:** sin duplicados de decks ni temporales (SPEC-34/37).

---

## 3. Secuencia de release

1. SPEC-37 — remover `presentacion/` (entrega Netec separada). ✓
2. SPEC-38 — documentar pin de `ksqldb-cli` en 8.0.3. ✓
3. SPEC-39 — validación fresca del harness (14/14). ✓
4. SPEC-40 — merge `spec-01 → main` (`--no-ff`) + tag `v1.0.0`. ← ejecución final

---

## 4. Restricciones

- Sin firmas de IA en commits, tags ni archivos. Autoría RodrigoMSB.
- No push ni merge a `main` sin luz verde explícita del PO (otorgada para SPEC-40).

---

## 5. Definition of Done

- [x] README raíz colocado.
- [x] Harness 14/14 verde (SPEC-39).
- [x] Working tree limpio.
- [ ] SPECs versionados en `docs/spec/` (SPEC-40 / P3).
- [ ] Rama integrada a `main` (SPEC-40).
- [ ] Tag `v1.0.0` creado (SPEC-40).
- [x] Composición del paquete definida (DEC-3).

---

*SPEC-35 · Preparación de entrega · Arquitecto → Mocito · 2026-07-08.*
