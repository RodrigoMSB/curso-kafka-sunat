# SPEC-37 — Remover `presentacion/` del repo (entrega Netec)

**Tipo:** Git hygiene / Borrado formal
**Fecha:** 2026-07-18
**Autor:** Arquitecto (Claude)
**Ejecuta / commitea:** Mocito (Claude Code, dev)
**PO:** Rodrigo
**Rama:** `spec-01-reestructura-sunat`
**Estado:** CERRADO — commit `c6f3db6`

---

## 0. Contexto y decisión del PO

Netec solicita la entrega con el material técnico (labs) separado de la presentación. Por decisión
del PO, la carpeta `presentacion/` completa sale del repositorio: el repo queda como entregable
técnico (labs + tests + docs), y la presentación se entrega por el canal que Netec indique, fuera de git.

Estado al abrir (SPEC-36): `presentacion/` borrada del working tree pero sin stage; contenido vivo en
`HEAD`. Este SPEC convierte ese borrado accidental en un borrado formal, intencional y commiteado.

> **Trazabilidad:** el contenido no se pierde del histórico. Cualquier commit anterior a este SPEC
> seguirá conteniendo `presentacion/`; recuperable con `git checkout <commit> -- presentacion/`.

---

## 1. Pre-requisito obligatorio

**P0 — Confirmar respaldo externo ANTES de borrar.** Copia fuera del repo de: `curso-sunat-COMPLETO.pptx`,
`cap1-arquitectura-fundamentos.pptx`, `plantilla-netec.pptx`, guiones cap1..5, `canonizar-pptx.sh`.

> R: Respaldo extraído desde HEAD antes de borrar: `~/backup-presentacion-sunat.tar` (12M) +
> `~/presentacion-sunat-backup/`. Los 3 `.pptx` verificados como ZIP válidos. PO confirmó → proceder.

---

## 2. Borrado formal

**P1 —** `git rm -r presentacion/` → stagea el borrado.
> R: 12 archivos staged como `deleted`.

**P2 —** `git ls-files presentacion/` → vacío.
> R: Vacío tras el commit.

**P3 —** `.gitignore` (opcional): `echo "presentacion/" >> .gitignore`.
> R: Añadido (confirmado por PO), incluido en el mismo commit.

---

## 3. Commit

**P4 —** Un commit, sin firmas de IA.
> R: `c6f3db6 chore: remover presentacion/ del repo (entrega Netec separada)`. 13 files changed, 941 deletions.

**P5 —** NO push ni merge.
> R: Commit local; sin push ni merge.

---

## 4. DoD

- [x] PO confirmó respaldo externo (P0).
- [x] `git ls-files presentacion/` vacío.
- [x] Working tree limpio.
- [x] Commit sin firmas de IA.
- [x] Sin push ni merge.
- [x] Reporte: hash `c6f3db6`; 494 → 482 archivos trackeados (salieron 12).

---

*SPEC-37 · Remover presentacion/ del repo · Arquitecto → Mocito · 2026-07-18 · respaldo antes de borrar.*
