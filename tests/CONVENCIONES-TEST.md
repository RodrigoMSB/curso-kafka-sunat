# Convenciones del harness de validación — SUNAT

Estándar del activo para validar los laboratorios. Dos niveles por lab, más un
orquestador global. Este documento es el molde: síguelo al agregar o mantener tests.

---

## 1. Arquitectura de dos niveles

| Pieza | Archivo | Vive en | Para quién |
|-------|---------|---------|------------|
| **Validador del alumno (90)** | `bin/90-test-lab.sh` | dentro de cada lab | Alumno en clase: valida SU estado actual, **no destruye nada**, dice qué está OK y qué falta con sugerencias. |
| **E2E del instructor** | `tests/lab-NN.sh` | `tests/` central | Instructor/dry-run: de cero → lab entero → verificación → teardown → veredicto binario. |
| **Orquestador global** | `tests/run-all.sh` | `tests/` | Corre los labs en serie + reporte con duración. |
| **Librería compartida** | `tests/lib-test.sh` | `tests/` | La sourcean los `tests/lab-NN.sh`. No se ejecuta sola. |

**Por qué el 90 es autocontenido** (aserciones inline, sin `source` a `tests/`): el lab
debe poder viajar solo. Si se empaqueta un lab suelto, su validador va adentro. El e2e del
instructor sí usa la lib central (DRY).

---

## 2. Patrón anti-frágil (lo que hace confiables a los tests)

- **Marca única por corrida**: `new_mark` → `e2e-<epoch>-<RANDOM>`. Nunca se asume un estado
  previo; cada corrida produce y verifica lo suyo.
- **Ground truth por consumo propio**: se cuentan las marcas que YO produje, no el estado global.
- **`grep '^<mark>-'` inmune a warnings**: los avisos de deprecación u otros textos en stdout no
  inflan los conteos (lección del capstone: `--consumer.config` warning contaba como mensaje).
- **Conteos dinámicos, no fijos frágiles**: p. ej. particiones = líneas `Partition: N`; ISR = tamaño
  mínimo de `Isr:`; réplicas parseando `Replicas:` (no `assert_contains " 4"`).
- **Nunca se compara contra la salida cruda de una caja**: los wrappers con ficha didáctica dibujan
  un marco de 76 columnas y **envuelven** las frases largas, así que una frase de dos renglones no
  aparece contigua en la salida. Toda aserción sobre ese texto pasa antes por un aplanado que quita
  el marco y colapsa los espacios:

  ```bash
  plano() {
      printf '%s\n' "$1" | sed 's/^│//; s/│$//' | tr '\n' ' ' | tr -s ' '
  }
  afirmar_contiene_plano() { afirmar_contiene "$1" "$2" "$(plano "$3")"; }
  ```

  Sin esto la aserción se pone roja cuando el texto crece, o peor, pasa en verde porque compara
  contra un fragmento corto que sí quedó contiguo. Ocurrió tres veces en el piloto de la ficha antes
  de escribirse esta regla.
- **Una aserción que no puede distinguir lo correcto de lo incorrecto no es una aserción**: se
  comparan **valores** (el número de particiones, el id del broker que falta, el lag exacto), nunca la
  presencia de una palabra. Antes de dar un test por bueno se lo rompe a propósito y se confirma que
  se pone rojo.
- **La restauración de un sabotaje preserva lo que no era parte del sabotaje**: al demostrar que un
  test se pone rojo se rompe el código a propósito y después se restaura, casi siempre con
  `git checkout`. Ese checkout se lleva puesto **todo** lo que estuviera sin commitear, incluidos los
  tests recién escritos. Se cuenta el total de pruebas **antes y después** de cada sabotaje y se
  verifica que coincida, además de dejar `git diff --stat HEAD` vacío. Ocurrió en el piloto de la
  ficha: un checkout borró el sexto test y se detectó porque el conteo bajó de 31 a 29, no porque
  hubiera un control.
- **El estado que se reporta se lee de la salida de un comando, no de una etiqueta**: antes de
  declarar "árbol limpio" o "suite en verde" se corre el comando y se **lee su salida**. Escribir
  `(vacío = limpio)` al lado de un `git status` que lista archivos no es una verificación, es una
  leyenda. Pasó dos veces en el piloto de la ficha, con tres archivos sin commitear la segunda.
  El orden es **verde primero, push después**: nunca se empuja con la suite en rojo.
- **Las cantidades esperadas se derivan, no se escriben a mano**: un test que afirma "35 copias"
  se pone rojo en cuanto el mapa crece, y peor, una constante desactualizada no distingue
  "verificó todo" de "no verificó nada". El número sale de la misma fuente que el trabajo, por
  ejemplo `replicar.sh --listar | wc -l`, más una aserción de que esa fuente no está vacía.
- **Una SPEC no se cierra sin la lista de sus decisiones verificada una por una**: al declarar
  cerrada una SPEC se enumeran **todas** las decisiones que el PO tomó en ella, y para cada una se
  pega el comando que la verifica y su salida. Sin esa lista no hay cierre. La SPEC-59 se declaró
  cerrada con tres decisiones del PO y solo dos aplicadas: la de que `check-quorum.sh` respetara el
  TTY nunca se ejecutó y se descubrió dos SPECs después, por casualidad. Es el mismo principio que
  las dos reglas de arriba, aplicado al proceso en vez de a los tests: **no se declara un estado sin
  leer la evidencia que lo prueba.**
- **Un comentario en el código no es evidencia**: si una línea afirma un alcance, una garantía o un
  aislamiento, se verifica **contra el sistema** antes de confiar en ella. `lib-test.sh` decía
  *"down -v scoped al archivo"* y era falso: `-f` elige el archivo, pero el alcance del `down` lo da
  el **proyecto**, que sale del nombre del directorio si no se pasa `-p`. Confiar en ese comentario
  destruyó los volúmenes de un clúster ajeno que compartía nombre de proyecto. Antes de cualquier
  comando que pueda destruir algo, **el chequeo es sobre el proyecto**, no sobre el archivo ni sobre
  el puerto. Todo `docker compose` del harness lleva `-p` explícito.
- **Un test que no verifica que su propio entorno se levantó no puede declarar verde**: antes de la
  primera aserción se confirma que el entorno **propio** existe y responde. No alcanza con que haya
  *un* clúster sano del otro lado. Los composes fijan `container_name`, y Docker exige nombres únicos
  en toda la máquina sin importar el proyecto: si ya existe un contenedor con ese nombre, el `up`
  falla y las aserciones terminan corriendo contra el despliegue ajeno que se llama igual. Pasó: tres
  e2e dieron verde probando un clúster que no era el suyo, y el único que falló fue el único que
  verificaba un puerto del host. **El `up` nunca se silencia**: si falla, el test muere ahí con el
  error a la vista. Un test que no sabe si levantó algo no es un test.
- **El validador del alumno (90) no lleva puertos de host fijos**: es el único de estos archivos que
  corre **en la máquina del alumno, en clase**. Si tiene un `9092` escrito a mano y el entorno publica
  en otro puerto, el alumno ve un `✗` que no entiende y que no es culpa suya. Pasó en
  `lab-04/bin/90-test-lab.sh`, que probaba `localhost:9092` fijo mientras el lab publicaba en otro
  puerto. Los puertos de host salen siempre de la variable, con el default de siempre:
  `EXT_PORT="${BROKER1_EXTERNAL_PORT:-9092}"`. **Este es el tipo de defecto que aparece delante de
  treinta personas, no en un test.**
- **Un wrapper no se da por terminado sin haberlo ejecutado y leído su salida completa**: los tests
  verifican **lo que decidimos verificar**; la salida real muestra **lo que el alumno va a ver**. No
  son lo mismo y la diferencia no la cubre ninguna suite. En `inspect-image.sh` aparecieron cinco
  defectos —el `COMANDO REAL` prometía tres comandos y corrían cuatro, la salida tabular se envolvía
  y quedaba ilegible, el bloque final contaba como total unos binarios que el propio wrapper había
  recortado con `head -20`— **con las tres suites en verde**. Mirar la salida es un paso obligatorio,
  no un extra. Se revisa, como mínimo: que el `COMANDO REAL` liste **todo** lo que se ejecuta, que
  ninguna cifra del bloque final salga de una salida recortada, que ninguna salida tabular quede
  envuelta, y que no quede nada suelto sin formato.
- **Tests negativos que afirman la denegación**: en seguridad, el test PASA cuando la operación
  FALLA. Se lee el **stderr real** del cliente (no el stdout del script del lab, que puede mencionar
  la excepción esperada en su texto de ayuda y dar un falso positivo).

---

## 3. Reglas de implementación

1. **Verificar la realidad del lab antes de escribir el test.** NO confiar en `TOPIC_NAME` del `.env`
   (puede estar obsoleto o alimentar otra cosa). Mirar `infra/scripts/init-*.sh`, `kafka-cli/*.sh`,
   la compose y los healthchecks para conocer el tópico real, los puertos reales y el bootstrap real.
2. **Fail-fast** con `abort_test "motivo"`: si el clúster no sube, se imprime veredicto FALLIDO y se sale
   (el `trap` hace el teardown). No tiene sentido seguir aserciones sobre un clúster muerto.
3. **Teardown por `trap ... EXIT`**: `trap 'lab_teardown "$LAB_DIR"' EXIT`. Pase lo que pase, se limpia.
4. **Veredicto binario 0/1 + duración**: `test_end` devuelve 0 si todo PASS, 1 si hubo fallos, con los
   segundos que tardó. `run-all.sh` agrega el veredicto global.
5. **N/A explícito** cuando falta un prerequisito del host (caso Lab 09 sin JDK/Maven): imprimir una
   línea `E2E N/A` y salir 0, para no romper `run-all` en máquinas sin ese stack.
6. **Portabilidad bash 3.2 / sin GNU-ismos**: nada de `mapfile`, `declare -A`, `grep -P`, `sed -i` sin
   sufijo, `timeout` de GNU. Para acotar operaciones que podrían colgar, usar `curl --max-time` o un
   bucle `until ... [ $W -ge N ]` con `sleep`.
7. **`-e KAFKA_OPTS=` y `MSYS_NO_PATHCONV=1`** en los `docker exec` que ejecutan herramientas Kafka:
   obligatorio en labs con JMX o seguridad; inofensivo en el resto (se usa siempre por consistencia).
8. **Estado del arte Kafka 4.2**: `--command-property` (no `--producer-property`) y `--command-config`
   (no `--producer.config`/`--consumer.config`).
9. **Los e2e no redescubren bugs ya arreglados**: usar los valores correctos (p. ej. `num.replica.fetchers=2`
   en el Lab 08, tope válido en 4.2).

---

## 4. Cómo agregar el par a un lab nuevo (checklist de 6 pasos)

1. **Reconocer la realidad**: tópico(s) real(es), scripts de `kafka-cli/`, puertos de servicios
   (SR 8081, REST 8082, ksqlDB 8088, Connect 8083, kafbat 8090), bootstrap interno (`kafka-broker-1:29092`),
   nombres de contenedores y healthchecks.
2. **Escribir `bin/90-test-lab.sh`** (copiar el molde): autocontenido, no destructivo, cada `✗` con
   sugerencia didáctica, `exit 0/1`. Valida el estado ACTUAL de lo que el lab enseña.
3. **Escribir `tests/lab-NN.sh`**: `source lib-test.sh` → localizar `LAB_DIR` con el glob → `trap lab_teardown`
   → `test_start` → `start-lab` → `wait_for_brokers N || abort_test` → aserciones con marca única →
   al final **correr el 90 sobre el lab vivo** y `assert_success`.
4. **`chmod +x`** ambos y `bash -n` sin errores.
5. **Correr el e2e** (`bash tests/lab-NN.sh`): esa corrida ES su validación. Debe dar `E2E APROBADO`,
   exit 0, teardown limpio (sin contenedores del curso al final).
6. **Probar el 90 con el lab apagado**: debe fallar amable (exit 1, sugerencias) — valida su cara didáctica.

---

## 5. Cómo corre el instructor todo

```bash
bash tests/run-all.sh
```

- Corre cada `tests/lab-*.sh` en serie, con teardown entre cada uno.
- Genera `tests/VALIDACION-REPORT.md` (ignorado por git) con tabla `Lab | Resultado | Duración`.
- Avisa `OJO` (sin matar) si quedan contenedores del ecosistema del curso tras un lab.
- Sale 0 si todos aprueban; 1 si alguno falla.

---

## 6. Helpers de `lib-test.sh`

| Helper | Qué hace |
|--------|----------|
| `test_start <nombre>` / `test_end` | Abre el bloque / imprime veredicto binario + duración. |
| `new_mark` | Marca única `e2e-<epoch>-<RANDOM>`. |
| `assert_eq` / `assert_ge` / `assert_contains` / `assert_success` | Aserciones con conteo PASS/FAIL. |
| `abort_test <motivo>` | Fail-fast: registra fatal, imprime veredicto y `exit 1`. |
| `wait_for_brokers <n> [to]` | Espera N brokers `healthy` (por `.State.Health.Status`). |
| `wait_for_container <name> [to]` | Espera un contenedor `healthy` o al menos `running`. |
| `produce_marked <ctr> <boot> <topic> <mark> <count> [cfg]` | Produce marcas (auth opcional vía `--command-config`). |
| `consume_count_mark <ctr> <boot> <topic> <mark> [tms] [cfg]` | Cuenta cuántas de MIS marcas llegaron. |
| `lab_teardown <lab_dir>` | Teardown scoped al lab (su `reset-lab.sh`; `down -v` solo su proyecto). |

---

## 7. Variante build-your-own (labs 01–04)

Los labs 01–04 son de **"construye tu propio clúster"**: el alumno arma su compose a partir de
`plantillas/*.template.yml` en `mi-cluster/`, sin `start-lab.sh` y sin healthchecks garantizados.
El molde estándar no calza; esta variante lo adapta:

| Pieza | Molde estándar | Variante build-your-own |
|-------|----------------|-------------------------|
| Arranque e2e | `bin/start-lab.sh` | **desplegar el compose de `soluciones/`** (`docker compose -f <sol> up -d`): el e2e valida la solución de referencia = el estado final esperado del alumno. |
| Espera | `wait_for_brokers` (lee `.State.Health`) | **`wait_for_broker_api`**: sondea `kafka-broker-api-versions` (el compose del alumno puede no tener healthcheck). |
| Teardown | `lab_teardown` (`reset-lab.sh`) | **`byo_teardown <lab_dir> <compose>`**: `docker compose -f <sol> down -v`. |
| 90 del alumno | valida el lab de `start-lab` | valida **SU clúster construido a mano**, con sugerencias que apuntan a la **guía** o a **`soluciones/`**. |

Reglas propias de la variante:
- **Paso 0 obligatorio**: localizar el compose real de `soluciones/` (`find soluciones -name 'docker-compose*.yml'`)
  y confirmar su convención de nombres/puertos. **No asumir** `kafka-broker-N`: el Lab 01 usa un único
  contenedor llamado **`kafka-broker`** (singular); labs 02–04 usan `kafka-broker-1/2/3`.
- **Listener EXTERNAL**: cuando `advertised.listeners` publica `localhost:<port>`, solo es alcanzable desde
  **el host**, no desde otro contenedor (un contenedor resolvería `localhost` a sí mismo). La verificación
  EXTERNAL se hace por **conexión TCP desde el host** (`/dev/tcp`, portable), no con un `docker run` sonda.
- Todo lo demás (marca única, ground truth, `--command-property`, fail-fast, `trap` teardown, veredicto
  binario) es idéntico al molde estándar.

## 8. El 95 (recuperación del alumno)

`bin/95-recuperar-lab.sh` lleva a un alumno rezagado a un **estado funcional** para seguir la clase sin
depurar con el grupo esperando. Contrato uniforme en los 14 labs:

1. **Advertir y confirmar** (es destructivo sobre el estado actual): «Esto reemplaza tu estado actual…
   ¿Continuar? (s/N)». Flag **`--si`** salta la confirmación (lo usa la validación automatizada).
2. **Limpiar** el estado actual (teardown del lab).
3. **Reconstruir** la línea base funcional: `start-lab.sh` (estándar) o desplegar `soluciones/` (build-your-own).
4. **Modo `--completo`** (opcional, donde aplique): aplica además los pasos resueltos clave para quien quedó
   atrás en partes avanzadas — Lab 09 compila los proyectos; Lab 11 registra el schema + siembra Avro;
   Lab 12 crea el STREAM base; Lab 13 crea el connector y espera RUNNING. En los demás labs `--completo`
   no aplica (la línea base ya es el estado final).
5. **Autoverificarse**: al final corre `bin/90-test-lab.sh`; si aprueba imprime «LAB RECUPERADO — puedes
   continuar en …»; si no, lo dice honesto y sugiere pedir ayuda al instructor.

Autocontenido (sin `source` a `tests/`), portable bash 3.2, `-e KAFKA_OPTS=`/`MSYS_NO_PATHCONV=1` donde toca.

**Checklist para un lab nuevo**: copiar el esqueleto → adaptar el bloque de teardown y el de reconstrucción
a la arquitectura del lab → añadir el bloque `--completo` solo si hay pasos resueltos scriptados → dejar la
autoverificación con el 90 tal cual → probarlo con `bin/95-recuperar-lab.sh --si` (debe terminar en
«LAB RECUPERADO»).

## 9. Estado de cobertura

- **Pares 90 + e2e construidos y en verde** (build-and-run, Docker real): **los 14 labs (01–14)**.
- Labs 05–14: molde estándar (`start-lab.sh` + `wait_for_brokers`).
- Labs 01–04: variante build-your-own (despliegan `soluciones/` + `wait_for_broker_api` + `byo_teardown`).
- **`95-recuperar-lab.sh`** presente y validado (`--si`) en los 14 labs.
