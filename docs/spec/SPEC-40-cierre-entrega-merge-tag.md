# SPEC-40 — Cierre de entrega: merge a `main` + tag `v1.0.0`

**Tipo:** Release / Merge (operación de integración)
**Fecha:** 2026-07-18
**Autor:** Arquitecto (Claude)
**Ejecuta / commitea:** Mocito (Claude Code, dev)
**PO:** Rodrigo — **autorización explícita otorgada para push y merge**
**Rama origen:** `spec-01-reestructura-sunat` (HEAD `54c4c22`, 14/14 verde en SPEC-39)
**Rama destino:** `main`
**Estado:** EN EJECUCIÓN — autorizado

---

## 0. Contexto y decisiones del PO

Todo el trabajo del curso vive en `spec-01-reestructura-sunat`, 126 commits adelante de `main`, 14/14
verde confirmado hoy (SPEC-39). Este SPEC integra la rama a `main` y marca la versión de entrega.
Decisiones del PO (SPEC-35): merge `--no-ff`, tag `v1.0.0`, `main` = repo técnico.

---

## 1. Pre-vuelo

**P1 — Árbol limpio y HEAD correcto.**
> R: Working tree limpio, HEAD `54c4c22`.

**P2 — Push de la rama a su remoto.**
> R:

**P3 — Versionar SPEC-35..40 en `docs/spec/`.**
> R: SPEC-35 provisto por el PO; 36-40 reconstruidos verbatim de la conversación. Los 6 en un commit.

---

## 2. Merge a `main`

Vía elegida por el PO: **CLI local `--no-ff`** (no PR).
```
git checkout main
git pull origin main
git merge --no-ff spec-01-reestructura-sunat -m "Release v1.0.0 — curso Kafka SUNAT (merge spec-01)"
git push origin main
```
> R (vía usada): CLI local `--no-ff`.

---

## 3. Tag de versión

**P6 —** Tag anotado sobre el commit de merge:
```
git tag -a v1.0.0 -m "Curso Administración de Confluent Apache Kafka (SUNAT) — entrega v1.0.0"
git push origin v1.0.0
```
> R (hash taggeado):

---

## 4. Verificación post-merge (DoD)

- [ ] `git log --oneline main -3` muestra el merge en la punta de `main`.
- [ ] `git rev-list --left-right --count main...spec-01-reestructura-sunat` → `0  0`.
- [ ] `git tag -l` incluye `v1.0.0`; `git show v1.0.0` apunta al merge.
- [ ] `git ls-files | wc -l` en `main` = conteo de la rama.
- [ ] En `main`: existen `README.md`, `labs/` (14), `tests/`, `docs/spec/` (32..40), `docs/adr/`; no existe `presentacion/`.
- [ ] Sin firmas de IA en merge ni tag.

---

## 5. Post-entrega (anotado)

Fix del preflight de `validar-todo.sh` (SPEC-39): se auto-matchea contra `tests/CONVENCIONES-TEST.md` y
aborta antes de correr los labs. Cosmético, preexistente (`8cc1519`), no bloquea. SPEC aparte tras el release.

---

## 6. Restricciones

- Push y merge autorizados solo para esta operación.
- Estrategia `--no-ff` obligatoria; nada de squash/rebase.
- Sin firmas de IA.
- Si el pre-vuelo sale distinto de lo esperado, detenerse y reportar.

---

*SPEC-40 · Cierre de entrega: merge + tag v1.0.0 · Arquitecto → Mocito · 2026-07-18 · push/merge autorizados por el PO.*
