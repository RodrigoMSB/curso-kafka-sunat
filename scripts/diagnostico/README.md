# Diagnóstico de ambiente — `validar-ambiente.sh`

Herramienta operativa permanente para validar que los 12 labs del curso levantan correctamente en una máquina antes de usarla en clase. Útil para:

- **Instructor** antes de empezar el curso (smoke test del propio entorno).
- **Operaciones** antes de entregar VMs corporativas a los alumnos.
- **CI/CD** futuro (el script tiene exit code 0/1 para integración automatizada).

---

## Cuándo usarlo

| Caso | Ejemplo |
|---|---|
| Antes del curso, validar todo de punta a punta | `./scripts/diagnostico/validar-ambiente.sh` |
| Después de modificar un lab puntual | `./scripts/diagnostico/validar-ambiente.sh --lab 09` |
| Validar solo capítulo 4 | `./scripts/diagnostico/validar-ambiente.sh --from 09` |
| Smoke test de los primeros labs | `./scripts/diagnostico/validar-ambiente.sh --to 04` |

---

## Requisitos previos

- **Docker Desktop corriendo** (con al menos 8 GB asignados).
- Repositorio clonado y con line endings UNIX (LF). Si clonaste en Windows, asegurate de haber configurado `git config --global core.autocrlf input` ANTES del clone.
- Bash compatible: macOS, Linux o **Git Bash en Windows**. PowerShell y CMD no soportados.
- ~30-50 minutos de tiempo. Cada lab tarda entre 30 segundos (Lab 02) y 5 minutos (Lab 09 con descarga inicial de plugin JDBC).

---

## Cómo ejecutarlo

Desde la raíz del repositorio:

```bash
./scripts/diagnostico/validar-ambiente.sh
```

También funciona desde cualquier subdirectorio (el script detecta la raíz del repo automáticamente):

```bash
cd labs/lab-05-resiliencia-y-retencion
../../scripts/diagnostico/validar-ambiente.sh
```

### Opciones disponibles

| Flag | Qué hace |
|---|---|
| (sin flag) | Valida los 12 labs en orden (lab-01 a lab-12) |
| `--lab N` | Valida solo `lab-NN` (ej: `--lab 05`) |
| `--from N` | Valida desde `lab-NN` hasta `lab-12` (ej: `--from 06`) |
| `--to N` | Valida desde `lab-01` hasta `lab-NN` (ej: `--to 04`) |
| `--skip-cleanup` | No ejecuta `docker volume prune` al final de cada lab (útil para debug) |
| `--help` | Muestra la ayuda y sale |

### Comportamiento por lab

Para cada lab seleccionado:

1. Limpia containers conocidos del curso (kafka-broker-*, kafbat-ui, cli-client, gps-producer, control-center, schema-registry, kafka-connect, ksqldb-server, ksqldb-cli, prometheus, grafana, debezium, postgres) — evita colisiones de nombres entre labs.
2. Ejecuta `bin/start-lab.sh` con timeout de **600 segundos** (10 min).
3. Captura exit code y tiempo de ejecución.
4. Ejecuta `bin/stop-lab.sh` (best-effort, sin abortar si falla).
5. Limpieza forzada de containers conocidos.
6. `docker volume prune -f` (a menos que `--skip-cleanup`).
7. Pausa de 5 segundos antes del próximo lab.

**Lab 03 siempre se marca SKIP** porque es un lab manual donde el alumno construye su propio cluster (no hay `start-lab.sh` automatizable).

---

## Cómo interpretar el reporte

Al terminar, el script genera dos artefactos:

### 1. Reporte resumido — `REPORTE-FINAL.txt`

```
===========================================
  VALIDACIÓN DE AMBIENTE - CURSO KAFKA
===========================================

Fecha:           2026-05-08 14:32:15
Sistema:         Darwin Macbook 25.3.0 ...
Docker:          Docker version 28.5.1, build ...
Docker memoria:  8 GB asignados
...

RESULTADOS:

  [01] lab-01-radiografia-cluster        OK    28s
  [02] lab-02-pubsub-en-accion           OK    25s
  [03] lab-03-construye-tu-cluster       SKIP (lab manual)
  [04] lab-04-operando-topicos           OK    30s
  ...

RESUMEN:
  - OK:    10
  - FAIL:   1
  - SKIP:   1
  - TOTAL: 12 labs probados
```

### 2. Logs detallados por lab

En el mismo directorio que el reporte, hay un archivo `lab-NN-*.log` por cada lab probado, con la salida completa de `start-lab.sh` y `stop-lab.sh`. Estos logs son la fuente de verdad para diagnosticar fallas.

Ruta de los artefactos:

```
scripts/diagnostico/logs/validacion-YYYYMMDD-HHMMSS/
├── REPORTE-FINAL.txt
├── lab-01-radiografia-cluster.log
├── lab-02-pubsub-en-accion.log
├── lab-04-operando-topicos.log
└── ...
```

---

## Qué hacer si un lab falla

1. Abrí el log específico: `scripts/diagnostico/logs/validacion-XXXX/lab-NN-*.log`.
2. Buscá el primer `ERROR`, `FAIL`, o `unhealthy` cerca del final.
3. Issues comunes:
   - **`Container name already in use`**: cleanup falló entre labs (reportar — el script intenta prevenirlo).
   - **`unhealthy`**: el broker no respondió al healthcheck. Mirar `docker logs kafka-broker-1` mientras el lab está corriendo (con `--skip-cleanup`) o revisar el log capturado.
   - **`Connection refused`**: bootstrap-server apuntando a un broker que no existe; revisar config del lab.
   - **`TIMEOUT (>600s)`**: el lab tarda demasiado en levantar; típicamente Lab 09 (descarga plugin JDBC) o Lab 11 (descarga grafana). Si pasa una segunda vez con cache caliente, reportar.
4. Revisá el troubleshooting específico del lab: `labs/lab-NN-*/docs/troubleshooting.md`.

---

## Tiempo estimado de ejecución

| Lab | Tiempo típico (cache caliente) | Tiempo primera vez (descarga imágenes) |
|---|---|---|
| 01 | 25-35 s | 60-90 s |
| 02 | 25-30 s | 30-60 s |
| 03 | SKIP | SKIP |
| 04 | 25-30 s | 30-60 s |
| 05 | 30-40 s | 30-60 s |
| 06 | 30-40 s | 30-60 s |
| 07 | 30-40 s | 30-60 s |
| 08 | 60-90 s | 3-5 min (CP 7.9.0 nuevo) |
| 09 | 90-120 s | 3-5 min (plugin JDBC) |
| 10 | 60-90 s | 90-120 s |
| 11 | 60-90 s | 2-3 min (Grafana, Prometheus) |
| 12 | 90-120 s | 2-3 min (eclipse-temurin para certs) |

**Total**: ~10-15 min con cache caliente, ~30-50 min en máquina virgen.

---

## Idempotencia

El script es seguro de ejecutar varias veces seguidas:

- Cada ejecución crea un directorio de logs **nuevo** con timestamp (no pisa anteriores).
- Limpia containers conocidos antes y después de cada lab.
- `docker volume prune` evita acumular volúmenes huérfanos entre runs.

Si querés mantener todo entre ejecuciones para debug:

```bash
./scripts/diagnostico/validar-ambiente.sh --skip-cleanup
```

---

## Exit codes

| Código | Significado |
|---|---|
| 0 | Todos los labs pasaron (o quedaron SKIP) |
| 1 | Al menos un lab falló o hizo timeout |
| 2 | Argumento de línea de comandos inválido |

Útil para integración futura con CI/CD:

```bash
if ./scripts/diagnostico/validar-ambiente.sh; then
    echo "Ambiente válido, podemos seguir"
else
    echo "Ambiente roto, abortar deploy"
    exit 1
fi
```
