# `tools/msys/` — ver desde macOS un defecto que solo aparece en Windows

Los alumnos trabajan en la VM de Netec, con **Git Bash (MSYS)**. MSYS traduce toda ruta
absoluta a una ruta de Windows **antes de que `docker` la vea**:

```
docker exec kafka-broker ls -la /var/lib/kafka/data
   →  ls: cannot access 'C:/Program Files/Git/var/lib/kafka/data'
```

El daño no es que falle. Es que **falla afirmando algo falso**: en la SPEC-62,
`verify-storage.sh` se caía por la ruta convertida, tomaba su camino alternativo, ese se
caía por lo mismo, y el diagnóstico concluía *«⚠ No aparece meta.properties. Este
directorio no está formateado»* sobre un almacenamiento que estaba perfectamente
formateado. Le decía al alumno que su lab estaba roto cuando estaba bien.

El arreglo es `export MSYS_NO_PATHCONV=1` en el `bin/common.sh` del lab, que los wrappers
importan antes de cualquier `docker exec`.

Este shim existe para que **el próximo caso de este tipo no lo descubramos frente a los
alumnos**.

---

## Cómo se usa

Se antepone al PATH. No se instala, no se enlaza, no tiene efecto si no está en el PATH.

```bash
PATH="$(pwd)/tools/msys:$PATH" bash bin/verify-storage.sh kafka-broker
```

Para ver cada conversión en stderr:

```bash
MSYS_SHIM_VERBOSE=1 PATH="$(pwd)/tools/msys:$PATH" bash bin/verify-storage.sh kafka-broker
```

| Variable | Default | Para qué |
|---|---|---|
| `MSYS_SHIM_ROOT` | `C:/Program Files/Git` | La raíz que se antepone, igual que la instalación de Git en la VM. |
| `MSYS_SHIM_VERBOSE` | *(vacío)* | `1` imprime cada conversión en stderr. |

### Reproducir el rojo y el verde

Con un broker vivo llamado `kafka-broker`. El rojo se produce **quitando la línea del
archivo**, nunca dejando la variable en vacío (ver más abajo por qué):

```bash
cd Capitulo_2/lab-01-inicializacion-kraft

# ROJO — sin la línea en bin/common.sh
grep -v '^export MSYS_NO_PATHCONV=1$' bin/common.sh > /tmp/sin.sh && cp /tmp/sin.sh bin/common.sh
env -u MSYS_NO_PATHCONV PATH="$(cd ../.. && pwd)/tools/msys:$PATH" \
    FICHA_FORZAR=1 bash bin/verify-storage.sh kafka-broker
#   ⚠ No aparece meta.properties. Este directorio no está formateado.

git checkout bin/common.sh   # el árbol tiene que estar limpio ANTES de esto

# VERDE — con la línea
env -u MSYS_NO_PATHCONV PATH="$(cd ../.. && pwd)/tools/msys:$PATH" \
    FICHA_FORZAR=1 bash bin/verify-storage.sh kafka-broker
#   El almacenamiento de kafka-broker está formateado y en pie.
```

`FICHA_FORZAR=1` es necesario porque la ficha solo se dibuja en una terminal, y al
capturar la salida no hay TTY.

---

## Qué emula, exactamente

**Solo la conversión de rutas, y solo en la forma más común**: un argumento que **es**
una ruta absoluta, empezando con una barra sola.

- `/var/lib/kafka/data` → `C:/Program Files/Git/var/lib/kafka/data` ✅
- `//foo` → sin tocar. Es el escape que MSYS respeta. ✅
- `ps`, `exec`, `kafka-broker`, `-la` → sin tocar (no empiezan con `/`). ✅

Respeta la semántica real de la variable: **MSYS solo mira si `MSYS_NO_PATHCONV` existe,
no su valor.** Con la variable en vacío tampoco convierte. Por eso el chequeo del shim es
`${MSYS_NO_PATHCONV+x}` y no `${MSYS_NO_PATHCONV:-}`, y por eso **un test que la dejara en
vacío daría un falso verde**.

## Qué NO emula

Esta lista importa tanto como la anterior. El shim **no** reproduce:

- **`--flag=/ruta`**, donde MSYS convierte la parte de después del `=`. El shim solo mira
  el inicio del argumento completo. **Si un wrapper usa `--file=/tmp/x.sql` en vez de
  `--file /tmp/x.sql`, este shim lo deja pasar en verde y la VM igual lo rompería.**
- **Listas separadas por `:`** (`/a:/b`), que MSYS trata como PATH y convierte entera.
- **La forma de letra de unidad**: `/c/Users/...` → `C:\Users\...`.
- **Las barras invertidas**: MSYS produce a veces `C:\...` y no `C:/...`.
- **Todo el resto de MSYS**: emulación de fork, permisos, enlaces simbólicos, terminales,
  traducción de variables de entorno, comportamiento de `docker.exe` en Windows.

## Su verde no es una garantía

**Rojo en este shim = defecto real, arréglalo.** Un rojo acá es información confiable:
reproduce la cadena causal completa contra el wrapper y el broker de verdad.

**Verde en este shim ≠ verde en Windows.** Es una red temprana, no una prueba. Cubre una
sola forma de un solo comportamiento de MSYS, y lo hace con código que escribimos
nosotros: que el shim respete `MSYS_NO_PATHCONV` lo decidimos acá, no lo comprobamos.
Que MSYS de verdad lo respete quedó probado en la VM de Netec el 2026-08-05, en la
máquina real. **Antes de una clase, lo que vale es la corrida en la VM.**

---

## Plan pendiente

Al 2026-08-05 la línea `export MSYS_NO_PATHCONV=1` está solo en los `bin/common.sh` de los
labs **01, 02 y 03**: la SPEC-62 se acotó a la clase de ese día. En orden:

### 1 · Barrido de protecciones inline en los 14 `tests/*.sh` — va primero

`MSYS_NO_PATHCONV` estaba parchado en los tests y no en la biblioteca del alumno. **Puede
haber más.** Se busca toda protección que un test se puso a sí mismo y se pregunta, en cada
una, si el entorno del alumno también la necesita. Es el punto que puede destapar algo
grande, y por eso va antes que el resto. Regla en `tests/CONVENCIONES-TEST.md` §2.

### 2 · La línea en los `common.sh` de los labs 04 al 14

### 3 · Barrido del patrón de rutas — son DOS formas, y el shim cubre una sola

`grep` de `docker exec` / `docker run` buscando:

| Forma | Ejemplo | Cómo se detecta |
|---|---|---|
| Argumento suelto que empieza con `/` | `ls -la /var/lib/kafka/data` | **El shim la pilla.** |
| `--flag=/ruta` | `--file=/tmp/statements.sql` | **A ojo.** MSYS convierte lo de después del `=`; el shim solo mira el inicio del argumento completo y la deja pasar en verde. |

Un verde del shim en este barrido **no cierra el punto**: solo cierra la primera forma. La
segunda hay que leerla.

Puntos ya identificados, ambos de la primera forma:

- `format-storage.sh:141` — verificado en verde en la VM el 2026-08-05, pero solo en los
  labs 01 y 03.
- `Capitulo_5/lab-12-ksqldb/ksql-cli/execute-file.sh:19` — `--file /tmp/statements.sql`,
  sin verificar.
