# SPEC-68 · ficha-operativa

**Repo:** `RodrigoMSB/curso-kafka-sunat` · partir desde `main` con la SPEC-66 pusheada, árbol limpio
**Rol:** Dev ejecuta · Arquitecto revisa · PO aprueba
**Alcance:** variante operativa de la ficha en el canónico, aplicada a los 16 scripts operativos de los labs 01–04.

---

## 0 · FORMATO DEL REPORTE — cada checkpoint

Primera línea literal: `REPORTE · SPEC-68 · ficha-operativa`
Secciones: **qué hice · estado · hallazgos · autoauditoría · necesito decidir · próximo paso**.
Rigen las reglas de la 66: ningún número sin comando, cada verde con salida pegada, hallazgo urgente y trabajo terminado en bloques separados.

---

## 1 · POR QUÉ IMPORTA

Los scripts operativos (`stop`, `reset`, `95-recuperar`, `90-test`) son los que el alumno corre **cuando algo ya se rompió o está por romperse** — y hoy arrancan mudos. Un alumno que ejecuta `reset-mi-cluster.sh` sin saber que borra sus datos aprende a tenerle miedo a la terminal; uno que lee primero qué conserva y qué destruye aprende higiene operacional. Es la lección que ningún flag enseña.

Y el riesgo de hacerlo mal es concreto: **el alumno corre esto en Git Bash sobre Windows**, la plataforma donde este curso ya se quebró una vez (MSYS). Una ficha que se ve bien en macOS y sale rota en la VM de Netec es peor que ninguna.

## 2 · CRITERIO DE ÉXITO — una frase

▎ **Los 16 scripts operativos de los labs 01–04 anuncian en una ficha compacta qué van a hacer, qué conservan y qué destruyen, antes de hacerlo, renderizando correcto en Git Bash sobre Windows, sin crecer el canónico de lección ni tocar una sola réplica existente.**

## 3 · LA VARIANTE OPERATIVA

**Qué es.** Una segunda familia de funciones en el motor (`ficha_op_*` o equivalente), no una copia de la de lección. Contrato visual:

- **Máximo 10 líneas** — la mitad de la de lección. Quien corre un `95-recuperar` está pegado y estresado, no en modo estudio. Este techo es duro: la lección de la SPEC-49–58 fue que 15→17 líneas era regresión.
- Misma caja y colores del formato aprobado (marcos CYAN, banderas YELLOW, flechas grises).
- Contenido fijo en cuatro bloques: **QUÉ HACE** (una línea) · **CONSERVA** · **DESTRUYE** (con el proyecto compose al que se limita, heredando el contrato del F5) · **CUÁNDO USARLO** (una línea).
- **Solo con TTY**, igual que la de lección: en un pipe o en las guías publicadas, ni un byte de más.
- El `reset` y el `95` ya piden confirmación — la ficha va **antes** de la pregunta, para que el "¿Continuar? (s/N)" se responda informado.

**Dónde vive.** El motor extendido en `tools/ficha/ficha.sh` (canónico), replicado por hash como siempre. Los cuatro tipos operativos (`stop`, `reset`, `95-recuperar`, `90-test`) **no** entran a `tools/ficha/wrappers/` como archivos completos — son scripts con lógica por lab. Lo canónico es **la función que pinta la ficha**; cada script la llama con sus textos.

**El caso del `90-test-lab.sh`.** Es distinto por lab (cada uno valida lo suyo). Su ficha es el encabezado estándar ("QUÉ VA A VERIFICAR" + las N líneas de sus chequeos) con contenido propio por lab. **Ojo:** los e2e de la 66 leen su salida y buscan la línea de conteo — la ficha solo con TTY garantiza que no rompe nada, y la compuerta lo demuestra.

## 4 · GIT BASH ES CIUDADANO DE PRIMERA — exigencias del PO

- **bash 3.2 y Git Bash (MSYS):** sin `declare -A`, `mapfile`, `grep -P`, `sed -i`, `jq`. Lo de siempre, sin excepciones.
- **La detección de TTY se prueba en las dos plataformas.** `[ -t 1 ]` se comporta distinto bajo mintty/winpty que en Terminal de macOS; el shim no emula esto. La compuerta de VM lo cubre.
- **Caracteres de caja y ancho:** los mismos bordes del formato aprobado, medidos en caracteres (≤76), verificando que mintty no los parta. La ficha de lección ya rindió bien en la VM (labs 01–03, SPEC-62) — la operativa usa exactamente el mismo juego de caracteres, ninguno nuevo.
- **Nada de rutas absolutas nuevas como argumento a docker** en el código de las fichas. La guardia de la biblioteca protege, pero no se le da trabajo extra.

## 5 · ALCANCE EXACTO

**Se toca:**
- `tools/ficha/ficha.sh` (motor: la familia operativa) y sus tests
- `tools/ficha/replicar.sh` si el mapa necesita los nuevos destinos del motor
- Los 16 scripts: `stop-mi-cluster.sh`, `reset-mi-cluster.sh`, `95-recuperar-lab.sh`, `90-test-lab.sh` × labs 01–04

**No se toca:**
- Los 7 wrappers de lección del canónico ni sus 51 réplicas — **ni una línea, ni un byte**. La suite de fichas existente (32/32) debe seguir verde idéntica.
- Los e2e de la 66, el contrato del F5, `common.sh`
- Los labs 05–14 (van en la SPEC-69)
- Las guías del alumno

## 6 · COMPUERTAS

**6.a Suite previa intacta.** `test-lee.sh` → 32/32 en verde **antes y después**, salidas pegadas. Si un test de lección cambia de resultado, el motor se contaminó → rojo del frente.

> **Enmienda del Arquitecto:** la compuerta 6.a cubre **las dos** suites — `test-lee.sh` (32/32) y `test-sesiones-1-3.sh` (36/36), antes y después. **68/68.** La segunda valida justo los labs 01–03, que se dictan al día siguiente.

**6.b Techo de líneas.** Cada ficha operativa medida con comando: ≤10 líneas. La más larga, pegada con su conteo.

**6.c TTY / sin TTY.** Cada uno de los 16 corrido con TTY (ficha visible) y con `> salida.txt` (cero códigos ANSI: `grep -c $'\033' salida.txt` → 0, y cero líneas de ficha). En particular: **los 4 e2e de los labs 01–04 corren en verde después del cambio** — si la ficha del `90` se filtró al e2e, se ve ahí.

**6.d Sabotaje de contenido.** En un script, invertir CONSERVA y DESTRUYE a propósito y mostrar que el test del motor lo pilla (o declarar honesto que el motor no valida contenido semántico y qué valida en su lugar). Un arnés se valida demostrando que puede decir NO.

**6.e Portabilidad.** `grep -nE 'declare -A|mapfile|grep -P'` sobre lo tocado → cero, con el comando pegado.

**6.f La VM de Netec.** Rojo/verde no aplica acá; lo que aplica es **render real**: los 16 corridos en la VM (o los 4 de un lab como muestra representativa, decisión del PO en el momento), con pantallazo o transcript. **Esta compuerta la corre el PO** — el Dev deja todo listo y lo dice en el reporte. Sin la VM, la SPEC queda en "cerrada salvo VM", no en cerrada.

## 7 · 🔴 PAROs

- 🔴 La ficha operativa no cabe en 10 líneas para algún script → **PARO**: se recorta contenido, no se sube el techo. Si de verdad no se puede, se trae el caso al PO.
- 🔴 Cualquier cambio obliga a tocar un wrapper de lección o una réplica → **PARO**.
- 🔴 Un e2e de la 66 cambia de resultado → **PARO**, ahí hay una filtración de ficha sin TTY.
- 🔴 `alchemia-postgres` (5432) y el 8081 — lo de siempre: no se tocan sin autorización en el momento.
- 🔴 Construcciones bash 4+ → **PARO**.

## 8 · ORDEN

Motor + tests primero (con 6.a y 6.d) → los 16 scripts (con 6.b, 6.c, 6.e) → reporte → compuerta 6.f en la VM cuando el PO pueda. Commit por etapa: `feat(spec-68/motor)` y `feat(spec-68/labs-01-04)`. Push con autorización del PO leyendo el reporte final.
