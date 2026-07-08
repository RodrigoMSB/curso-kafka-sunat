# SPEC-34 — Revisión de git y commit de pendientes

**Tipo:** Higiene de repositorio
**Fecha:** 2026-07-08
**Autor:** Arquitecto (Claude) · **Ejecuta / commitea:** Mocito (Claude Code, dev) · **PO:** Rodrigo
**Rama:** `spec-01-reestructura-sunat`
**Estado:** EN CURSO — parte commiteada, parte pendiente de decisión del PO
**Depende de:** SPEC-32 (discovery), SPEC-33 (pulido presentación)

---

## 0. Objetivo

Dejar el working tree limpio: revisar qué quedó sin commitear y meterlo con mensajes correctos, sin
`git add -A`. Cada archivo a su commit lógico; lo dudoso (basura, temporales, DRM/credenciales,
gitignored) se deja fuera y se justifica.

---

## 1. Estado al abrir el SPEC (evidencia)

`git status --porcelain` mostró 7 untracked (dos candidatos del SPEC-34 ya estaban resueltos por
SPEC-33: `curso-sunat-COMPLETO.pptx` en commit `9157bed`, y SPEC-32/33 en `docs/spec/` en `5b7be40`):

```
?? VALIDACION-STATUS.md
?? presentacion/guiones/guion-slides-cap2.md
?? presentacion/guiones/guion-slides-cap3.md
?? presentacion/guiones/guion-slides-cap4.md
?? presentacion/guiones/guion-slides-cap5.md
?? presentacion/ppt-template/template-sunat.pptx
?? presentacion/ppt/arregladas/
```

---

## 2. Clasificación y decisión

| Untracked | Evidencia | Decisión |
|---|---|---|
| `guion-slides-cap{2,3,4,5}.md` | 191/177/139/155 líneas, H1 de contenido por capítulo (KRaft · config/tópicos/rendimiento · clientes/REST/esquemas · procesamiento/HA-DR/seguridad) | **VA** — commit `docs(presentacion): guiones de slides cap 2-5` |
| `VALIDACION-STATUS.md` | Obsoleto (cabecera "SPEC-21", pre-fix; SPEC-32/P2 lo marcó desactualizado); untracked | **PREGUNTAR PO** — recomendación: no versionar (borrar o mover a `_fuente-extra/`) |
| `ppt/arregladas/cap1-*.pptx` | Otra copia del Cap 1 que **ya está versionado** en `ppt/cap1-*.pptx` (md5 distinto pero mismo deck); el deck COMPLETO 147 slides ya lo subsume | **PREGUNTAR PO** — evitar dos copias del mismo material |
| `ppt-template/template-sunat.pptx` | Intermedio de 69 slides (ni base de 0, ni Cap 1 de 30, ni completo de 147); no descrito en `ppt-template/README.md` | **PREGUNTAR PO** — posible scratch de construcción; versionar solo si aporta |

---

## 3. Commits realizados

- `docs(presentacion): guiones de slides cap 2-5` — los 4 guiones de contenido.
- `docs(spec): versiona SPEC-34 (higiene de git)` — este documento.

*(Sin firmas de IA — regla dura SPEC-32/P6.4. Solo commits locales en la rama; sin push/merge a main.)*

---

## 4. Pendientes de decisión del PO (working tree no-limpio justificado)

Quedan 3 untracked a la espera de decisión (ver tabla §2): `VALIDACION-STATUS.md`,
`ppt/arregladas/`, `ppt-template/template-sunat.pptx`. Ninguno se versiona ni se borra sin luz verde.

---

## 5. Definition of Done

- [x] Cada commit con mensaje descriptivo y sin firmas de IA.
- [x] Guiones cap 2-5 versionados.
- [x] SPEC-34 versionado en `docs/spec/` (SPEC-32/33 ya estaban).
- [x] Reporte de qué se commiteó, qué se dejó fuera y por qué.
- [ ] Resolución de los 3 pendientes según decisión del PO.

---

*SPEC-34 · Higiene de git · Arquitecto → Mocito · 2026-07-08 · revisar antes de commitear.*
