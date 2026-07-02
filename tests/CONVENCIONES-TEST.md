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

## 8. Estado de cobertura

- **Pares construidos y en verde** (build-and-run, Docker real): **los 14 labs (01–14)**.
- Labs 05–14: molde estándar (`start-lab.sh` + `wait_for_brokers`).
- Labs 01–04: variante build-your-own (despliegan `soluciones/` + `wait_for_broker_api` + `byo_teardown`).
