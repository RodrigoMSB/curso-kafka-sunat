# SPEC-33 — Pulido de la presentación del curso SUNAT

**Tipo:** Fix + Decisión documentada (cambios aplicados por el arquitecto; commiteados por el dev)
**Fecha:** 2026-07-08
**Autor:** Arquitecto (Claude)
**Ejecuta / commitea:** Mocito (Claude Code, dev)
**PO:** Rodrigo
**Artefacto:** `presentacion/ppt/curso-sunat-COMPLETO.pptx` (147 slides)
**Estado:** CERRADO — deck commiteado (`9157bed`)
**Depende de:** SPEC-32 (discovery) — respondido

---

## 0. Contexto

Tras versionar el deck completo (147 slides) en `presentacion/ppt/`, se corrió una auditoría
visual + técnica del PPT contra dos fuentes de verdad: el **temario oficial**
(`Confluent_Apache_Kafka_24_horas_SUNAT.xlsx`) y el **repo de labs**. Veredicto: el deck es
**sólido y entregable** — cero desbordes geométricos, diseño Netec consistente, narrativa NovaTech
coherente, 135/147 slides con notas de orador, alineación técnica correcta con el stack real
(Kafka 4.2 · CP 8.2.0 · KRaft), y el ítem "Landoop" del temario resuelto en el propio material
(sustitución a Kafbat UI citando ADR-001, slides 39 y 113).

Este SPEC aplica los pulidos menores detectados y **deja registro de dos decisiones** que hasta
ahora vivían solo en la cabeza del equipo.

---

## 1. Cambios aplicados al archivo

### C-01 · Metadatos de autoría (estaban vacíos)
El deck venía con `core.author` y `core.title` en blanco (se perdieron en la última canonización
con LibreOffice). Repuestos:

| Campo | Valor aplicado |
|---|---|
| `author` | `Rodrigo Silva` |
| `title` | `Administración de Confluent Apache Kafka (SUNAT)` |
| `last_modified_by` | `Rodrigo Silva` |

**Decisión PO (2026-07-08):** se confirma `Rodrigo Silva` como autor (coincide con la identidad git
`RodrigoMSB`). No se ajusta.

**Nota de higiene:** al reescribir la metadata, python-pptx dejó un `docProps/core.xml`
**duplicado** dentro del zip. Se eliminó el viejo dejando un solo `core.xml`. Si el dev regenera el
deck por otra vía, verificar que no reaparezca (`unzip -l archivo.pptx | grep -c docProps/core.xml`
debe dar 1).

### C-02 · Versiones finas del stack en la slide 109 (clientes Java)
- **Antes:** `La versión de kafka-clients debe alinear con el broker (4.2)`
- **Después:** `kafka-clients 4.2.1 sobre Java 21; el cliente Spring corre sobre Spring Boot 4.1 + spring-kafka 4`

Preserva tamaño (16pt) y estilo del run original. Entra sin desborde.

---

## 2. Decisiones registradas

### D-01 · Estructura 5 capítulos vs 4 unidades del temario — ACEPTADA
El temario oficial define **4 unidades**; el PPT las presenta como **5 capítulos**. La Unidad 4 del
temario (8 temas) es desproporcionadamente grande y el deck la parte en dos capítulos con un corte
pedagógico natural:

- **Cap 4** — Ecosistema de clientes, REST y esquemas (escalamiento · Java/Spring · REST Proxy · Schema Registry)
- **Cap 5** — Procesamiento, integración, HA/DR y seguridad (ksqlDB · Connect · observabilidad/HA-DR · capstone/seguridad)

**Decisión (PO, 2026-07-08):** se acepta el reparto 5-capítulos como mejora didáctica. El mapeo a
las 4 unidades vendidas se mantiene 1:1 en contenido (ningún tema se pierde ni se agrega; solo
cambia el agrupamiento de la Unidad 4).

### D-02 · "Landoop" en el material — INTENCIONAL Y CORRECTO
"Landoop" aparece 2 veces (slides 39 y 113), siempre en el patrón: *"el temario nombra Landoop →
descontinuado e incompatible con Kafka 4.x → el curso usa Kafbat UI (ADR-001)"*. Cierra en el
propio deck el hallazgo **F-15** de la auditoría. No requiere cambio. Validado.

---

## 3. Definition of Done — resultado de ejecución (dev)

- [x] `presentacion/ppt/curso-sunat-COMPLETO.pptx` commiteado (`9157bed`). El archivo ya traía los
      cambios C-01/C-02 aplicados; no hubo "reemplazo", solo commit del untracked.
- [x] `unzip -l ... | grep -c 'docProps/core.xml'` → **1**.
- [x] Integridad `unzip -t` → OK · 147 slides · slide 109 con la línea nueva · old phrasing ausente.
- [x] Autor confirmado por PO: `Rodrigo Silva`.
- [ ] **PENDIENTE-PO (no verificable headless):** abrir en PowerPoint Mac y confirmar que abre sin
      aviso de reparación. El dev no tiene GUI; además este deck no tiene evidencia de haber pasado
      por `canonizar-pptx.sh` (LibreOffice), a diferencia del deck Cap 1. Ojo si PowerPoint pide reparar.
- [x] Commit sin firmas de IA (regla dura SPEC-32/P6.4).

---

## 4. Fuera de alcance (explícito)

- **No** se rehace ningún diagrama ni se cambia layout.
- **No** se toca la estructura 5-capítulos (D-01 la acepta como está).
- **No** se modifican notas de orador.
- Materiales de aula (flashcards/biblioteca/quizzes/proyecto final): entregados y cerrados por el
  PO; fuera del alcance de este repo.

---

*SPEC-33 · Pulido presentación SUNAT · Arquitecto → Mocito · 2026-07-08 · cerrado.*
