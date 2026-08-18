# Lab 08b · Troubleshooting

---

## El laboratorio no levanta

### `systemd` no llega a estado operativo

`bin/start-lab.sh` se detiene en el paso 3 con este mensaje:

```
[ERROR] systemd no llego a estado operativo dentro del contenedor.
```

Mira qué dijo el contenedor al arrancar:

```bash
docker logs kafka-rhel
```

Si aparece esto:

```
Failed to create /init.scope control group: Read-only file system
```

es que `systemd` no pudo escribir en el árbol de cgroups. El compose lo monta para eso:

```
- /sys/fs/cgroup:/sys/fs/cgroup:rw
```

Comprueba que la línea siga en `infra/docker-compose.yml` y que el montaje llegó:

```bash
docker inspect kafka-rhel --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Mode}}){{println}}{{end}}'
```

> **Si esto falla en tu máquina y no en la del relator, avísale antes de tocar nada.** No lo resuelvas agregando `--privileged` al compose: es un permiso mucho mayor y el laboratorio está diseñado explícitamente para no necesitarlo.

### La construcción falla al descargar

La primera construcción descarga unos 255 MB desde `packages.confluent.io` y desde el registro de Red Hat. Si estás detrás de un proxy corporativo, `dnf` va a fallar con un error de red. Vuelve a intentar con:

```bash
bin/reset-lab.sh
bin/start-lab.sh
```

Si persiste, el problema es de salida a internet, no del laboratorio.

---

## Estoy dentro del servidor pero algo no funciona

### `docker exec -it` no me deja entrar (Git Bash / Windows)

Si al ejecutar `docker exec -it kafka-rhel bash` tu terminal responde algo como *"the input device is not a TTY"*, antepón `winpty`:

```bash
winpty docker exec -it kafka-rhel bash
```

Es una particularidad de cómo Git Bash maneja las terminales interactivas, no un problema del laboratorio.

### El servicio no arranca y el journal habla de permisos

Síntoma típico tras formatear como `root` en vez de como `cp-kafka`:

```bash
journalctl -u confluent-kafka -n 30
```

Si ves errores de escritura o de acceso sobre `/var/lib/kafka/data`, revisa quién es el dueño:

```bash
ls -ld /var/lib/kafka/data
```

Debe decir `cp-kafka confluent`. Si dice `root root`, arréglalo y vuelve a arrancar:

```bash
chown -R cp-kafka:confluent /var/lib/kafka/data
systemctl start confluent-kafka
```

**Éste es el error más común al instalar Kafka a mano**, y por eso la guía formatea con `runuser -u cp-kafka`.

### El servicio arranca y se cae enseguida

```bash
journalctl -u confluent-kafka -n 50
```

Las dos causas habituales:

- **El almacenamiento no está formateado.** El journal menciona que no encuentra los metadatos. Formatea siguiendo el momento 3 de la guía.
- **`log.dirs` apunta a un directorio que no existe o que no es del usuario del servicio.** Comprueba a dónde apunta:

  ```bash
  grep ^log.dirs /etc/kafka/server.properties
  ```

### `systemctl is-active` dice `failed` después de que yo lo apagué

**Es lo esperado, y no significa que algo esté roto.** La unidad que publica Confluent no declara `SuccessExitStatus`, y `kafka-server-start` termina con un código distinto de cero cuando recibe la señal de apagado. `systemd` lo anota como fallo aunque el apagado haya sido ordenado.

Compruébalo tú: arranca de nuevo y busca la marca que deja Kafka.

```bash
systemctl start confluent-kafka
journalctl -u confluent-kafka | grep "clean shutdown"
```

```
Skipping recovery of 3 logs from /var/lib/kafka/data since clean shutdown file was found
```

Kafka encontró la marca de apagado limpio. En un servidor de SUNAT ocurre igual.

### Los comandos `kafka-*` no se encuentran

```bash
rpm -q confluent-kafka
ls /usr/bin/kafka-* | wc -l
```

Deben responder `confluent-kafka-8.2.0-1.noarch` y `40`. Si no, la instalación quedó incompleta: reconstruye con `bin/reset-lab.sh` y `bin/start-lab.sh`.

---

## Reanudar y empezar de nuevo

### Apagué el laboratorio y al volver el broker no está corriendo

**Es correcto.** La unidad viene `disabled`, así que no arranca sola al encender el servidor — igual que en un servidor real recién instalado. Enciéndela:

```bash
systemctl start confluent-kafka
```

Y si quieres que arranque sola en adelante:

```bash
systemctl enable confluent-kafka
```

### ¿Perdí el `server.properties` que edité?

No, si usaste `bin/stop-lab.sh`. Ese script apaga el servidor conservándolo entero, y `bin/start-lab.sh` lo reanuda tal como lo dejaste — te lo dice al arrancar:

```
[1/3] El servidor ya existe: se reanuda tal como lo dejaste.
```

**`bin/reset-lab.sh` sí borra tu trabajo**: destruye el contenedor y el volumen de datos para devolverte un servidor recién instalado. Úsalo cuando quieras repetir el laboratorio desde cero.

Para ver en qué estado quedó todo:

```bash
bin/90-test-lab.sh
```

---

## Frontera del laboratorio

Este laboratorio vive en el proyecto compose `novatech-lab08b`, con su propia red y su propio volumen, y **no publica ningún puerto en el host**. No puede alcanzar los recursos de ningún otro laboratorio, y ningún otro puede alcanzar los suyos.

Si `bin/start-lab.sh` te dice que el nombre `kafka-rhel` lo tiene un contenedor que no es del curso, no lo borra: te lo dice y se detiene, para que decidas tú.
