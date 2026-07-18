# SPEC-36 — Verificación de estado del repo (pre-entrega)

**Tipo:** Discovery / Solo lectura (CERO cambios, cero commits)
**Fecha:** 2026-07-18
**Autor:** Arquitecto (Claude)
**Destinatario:** Mocito (Claude Code, dev)
**PO:** Rodrigo
**Rama esperada:** `spec-01-reestructura-sunat`
**Estado:** CERRADO — reporte entregado

---

## 0. Propósito

Antes de declarar la entrega, necesito la foto exacta del repo vivo. Este SPEC **no cambia nada**:
solo corre comandos de lectura y reporta. Regla de oro: **evidencia, no memoria.** Pega el output
crudo de cada comando. Si algo no aplica o sale vacío, dilo explícito.

**No hagas commits, no hagas push, no hagas merge, no borres nada.** Solo mirar y reportar.

---

## 1. Estado de la rama y el árbol

**C1 —** Foto general:
```
git status -sb
git status --porcelain
```
¿Working tree limpio, o hay untracked/modificados? Lista lo que haya.

> R: Working tree NO limpio: 12 archivos borrados (`D` no staged), todos bajo `presentacion/`.
> Verificado: la carpeta `presentacion/` completa no existía en disco. Committed intacto.

**C2 —** Posición vs `main`:
```
git rev-list --left-right --count origin/main...HEAD
git log --oneline -12
```
¿Cuántos commits adelante/detrás de `origin/main`? ¿Sigue sin mergear?

> R: 124 adelante, 0 detrás. Sin mergear.

**C3 —** Rama actual y remoto:
```
git branch -vv
git remote -v
```

> R: Rama `spec-01-reestructura-sunat`, sincronizada con su remoto. Origin: `RodrigoMSB/curso-kafka-sunat`.

---

## 2. Presencia de los entregables clave (¿están versionados?)

**C4 — PPT del curso (147 slides, pulido SPEC-33):**
```
git ls-files "presentacion/**/*.pptx"
```
> R: Trackeado en `presentacion/ppt/curso-sunat-COMPLETO.pptx`, pero ausente en disco (borrado del working tree).

**C5 — Documento de setup de laboratorios:**
```
git ls-files | grep -iE "setup|laboratorios.*confluent|recomendaciones"
```
> R: No versionado (vive fuera del repo).

**C6 — Examen de certificación y banco de quizzes corregido:**
```
git ls-files | grep -iE "examen|certificac|preguntas_generad|quiz"
```
> R: No versionados (entregables Netec, fuera del repo).

**C7 — SPECs en `docs/spec/`:**
```
git ls-files "docs/spec/**"
```
> R: Versionados 32, 33, 34. 35/36 no aparecen aún.

**C8 — README raíz:**
```
git ls-files | grep -iE "^README"
```
> R: Existe `README.md` raíz (commit `1f29a33`).

---

## 3. Salud del código

**C9 — Harness de validación:**
> R: No corrido en esa sesión; pendiente corrida fresca (se hace en SPEC-39).

**C10 — Inconsistencia conocida a confirmar:** `cp-ksqldb-cli` en 8.0.3 vs stack 8.2.0.
```
grep -rn "ksqldb-cli" labs/*/infra/docker-compose.yml
```
> R: Confirmado. lab-12: todo el stack en 8.2.0 excepto `cp-ksqldb-cli:8.0.3`. Duda abierta → cerrada en SPEC-38.

---

## 4. Lo que el repo NO controla (para el acta)

**C11 —**
```
git tag -l
git log --oneline --decorate -5
```
> R: Sin tags. Ningún `v1.0.0`. `main` no apunta a la rama (sin mergear).

---

## 5. TL;DR

1. Working tree con pendientes: `presentacion/` borrada del árbol (12 archivos), committed intacto.
2. 124 adelante de main, sin mergear.
3. PPT versionado sí (`presentacion/ppt/curso-sunat-COMPLETO.pptx`), ausente en disco.
4. Documento de setup: no versionado.
5. Examen/quizzes: fuera del repo.
6. Falta: decidir `presentacion/` borrada, mergear a main, tag de versión, resolver `ksqldb-cli`, corrida fresca del harness.

---

*SPEC-36 · Verificación de estado pre-entrega · Arquitecto → Mocito · 2026-07-18 · solo lectura.*
