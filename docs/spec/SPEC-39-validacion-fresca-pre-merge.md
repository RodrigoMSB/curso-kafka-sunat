# SPEC-39 — Validación fresca del harness (pre-merge)

**Tipo:** Verificación / Solo lectura (no modifica el repo)
**Fecha:** 2026-07-18
**Autor:** Arquitecto (Claude)
**Ejecuta / reporta:** Mocito (Claude Code, dev)
**PO:** Rodrigo
**Rama:** `spec-01-reestructura-sunat` (HEAD `54c4c22`)
**Estado:** CERRADO — 14/14 verde

---

## 0. Propósito

Confirmar que los 14 labs siguen 14/14 verde en HEAD actual, antes de mergear a `main`. Desde el último
verde conocido se hicieron SPEC-37 (borrado de `presentacion/`) y SPEC-38 (comentario en compose lab-12).
No se mergea sobre un "no debería"; se mergea sobre un verde verificado hoy. Este SPEC no cambia nada.

---

## 1. Ejecución

**P1 —** Punto de partida limpio.
> R: Working tree limpio, HEAD `54c4c22`.

**P2 —** Correr el harness completo.
> R: `./validar-todo.sh` aborta en el PREFLIGHT por un falso positivo preexistente (commit `8cc1519`,
> 2026-07-01): el escáner de portabilidad matchea su propia doc `tests/CONVENCIONES-TEST.md:50`. No
> tiene relación con la funcionalidad de los labs ni con SPEC-37/38. Se corrió el runner funcional
> canónico `tests/run-all.sh` (fase 2 que `validar-todo.sh` invoca), permitido por P2.

**P3 —** Resumen del harness.
> R: **14/14 PASS · 910s (~15 min) · corrida fresca 2026-07-18.** Cero FAIL. (Docker Desktop estaba
> apagado; se arrancó antes de correr.) Detalle: lab-01..14 todos PASS.

---

## 2. Interpretación

**P4 —** lab-12 (tocado en SPEC-38).
> R: PASS (4 aserciones, 82s). El comentario YAML no rompió el parseo del compose; CLI 8.0.3 operó
> contra server 8.2.0.

**P5 —** Salida de `presentacion/` (SPEC-37).
> R: Ningún lab ni test referencia `presentacion/`. El harness corrió los 14 sin quejas. Teardown
> limpio (0 contenedores residuales).

---

## 3. DoD

- [x] Working tree limpio, HEAD `54c4c22`.
- [x] Harness corrido completo, fresco en esta sesión.
- [x] Resultado: 14/14 PASS, 910s.
- [x] lab-12 en verde.
- [x] 14/14 → luz verde para el merge (SPEC-40).

---

## 4. Pendiente detectado (no bloquea la entrega)

Fix del preflight de `validar-todo.sh`: excluir `CONVENCIONES-TEST.md` del scan (o escanear solo `*.sh`).
Cosmético, preexistente; se hará en un SPEC aparte tras el release.

---

*SPEC-39 · Validación fresca pre-merge · Arquitecto → Mocito · 2026-07-18 · no modifica el repo.*
