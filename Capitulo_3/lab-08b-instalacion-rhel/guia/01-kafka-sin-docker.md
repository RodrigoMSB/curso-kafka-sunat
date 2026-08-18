# Lab 08b · Kafka sobre RHEL 9, sin Docker adelante

**Curso**: Administración de Confluent Apache Kafka (SUNAT)
**Duración**: ~45 minutos · **Modalidad**: conducido por el relator


> **Reparto del tiempo** (estimación del relator, para calibrar en clase): introducción 3 · momento 1 · 6 · momento 2 · 11 · momento 3 · 8 · momento 4 · 10 · momento 5 · 5 · cierre 2 = **45 min**.
> Si el bloque se aprieta, lo primero que se recorta está señalado dentro del momento 5. El momento 4 no se recorta: es el corazón del laboratorio.

---

## Por qué existe este laboratorio

En los trece laboratorios anteriores ejecutaste comandos reales de Kafka contra clústeres reales. Nada de eso fue una simulación. Pero hubo una capa que no viste nunca, porque Docker la tapa entera:

- El paquete, y de dónde sale
- El servicio, con su arranque, su estado y sus logs
- El `server.properties` como **archivo que se edita**, no como variable de un compose
- El usuario que corre el proceso, los permisos y dónde viven los datos

En SUNAT los clústeres están instalados sobre **RHEL con `yum`**. Este laboratorio levanta esa tapa en 45 minutos y termina ejecutando **los mismos comandos de los labs 01 y 02, sin `docker exec` adelante**.

Si al final dices *"es lo mismo, pero sin Docker adelante"*, el laboratorio cumplió.

---

## Antes de empezar · tres cosas dichas de frente

Un laboratorio que enseña plataforma no puede mentir sobre su propia plataforma.

**1 · El sistema es RHEL 9 de verdad.**
La imagen base es UBI 9 (*Universal Base Image*), la imagen oficial de Red Hat, libre y sin suscripción. No es Rocky ni AlmaLinux —que son binario-compatibles pero no son RHEL—: es RHEL. Lo vas a comprobar tú mismo en un momento.

**2 · El paquete que instalamos es el broker, no la plataforma completa.**
En producción, SUNAT instala **`confluent-platform`**, que arrastra Schema Registry, ksqlDB, Connect y Control Center: unos 2,4 GB para un laboratorio de un solo broker. Aquí instalamos **`confluent-kafka`**, el broker Apache empaquetado por Confluent, que trae **exactamente los mismos comandos** que la imagen usada en los otros trece labs.

El procedimiento —repositorio, clave GPG, `yum install`— es **idéntico** al de producción. Lo único que cambia es el nombre del paquete. Esa elección es deliberada: permite comparar las salidas de este lab con las que ya viste, línea por línea, sin ruido.

**3 · `systemd` corre dentro de un contenedor, y eso necesita un permiso.**
Este laboratorio monta el árbol de cgroups del sistema para que `systemd` pueda arrancar dentro del contenedor. Es lo mínimo que necesita: **no usa `--privileged` y no agrega ninguna capacidad**, así que el contenedor tiene los mismos permisos que cualquier otro lab del curso. En un servidor real esto no hace falta, porque allí `systemd` *es* el sistema.

---

## Entrar al servidor

```bash
bin/start-lab.sh
```

Y entras una sola vez:

```bash
docker exec -it kafka-rhel bash
```

**Ese es el único `docker` de todo el laboratorio.** De aquí en adelante estás dentro de un servidor RHEL y todos los comandos son los de siempre.

---

## Momento 1 · ¿De dónde sale Kafka sin Docker? (~6 min)

Sin Docker, Kafka sale de un repositorio de paquetes. Mira el que quedó declarado en el servidor:

```bash
cat /etc/yum.repos.d/confluent.repo
```

```
[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/8.2
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/8.2/archive.key
enabled=1
```

Tres cosas que importan en un servidor de producción:

- **`baseurl`** es la rama 8.2 del repositorio oficial de Confluent.
- **`gpgkey`** es la clave pública con la que Confluent firma sus paquetes.
- **`gpgcheck=1`** no es decorativo: obliga a `yum` a verificar esa firma antes de instalar. Sin él, `yum` instalaría lo que sea que responda en esa URL.

Con eso declarado, la instalación fue una línea:

```
yum install confluent-kafka-8.2.0
```

Comprueba qué quedó instalado:

```bash
rpm -q confluent-kafka
rpm -qi confluent-kafka | grep -E "^(Name|Version|License)"
```

```
confluent-kafka-8.2.0-1.noarch
Name        : confluent-kafka
Version     : 8.2.0
License     : Apache (v2)
```

**Sobre la versión fija.** El repositorio sirve toda la rama 8.2, y hoy ya ofrece una versión más nueva que la 8.2.0. El laboratorio la fija a propósito: es la misma de los otros trece labs, y sin esa igualdad las salidas que vas a comparar dentro de un rato dejarían de calzar. En producción se hace lo mismo, por la misma razón — un clúster no se actualiza porque el repositorio publicó algo el martes.

### Dónde quedaron los comandos

```bash
ls /usr/bin/kafka-*
ls /usr/bin/kafka-* | wc -l
```

```
/usr/bin/kafka-acls
/usr/bin/kafka-broker-api-versions
/usr/bin/kafka-client-metrics
/usr/bin/kafka-cluster
/usr/bin/kafka-configs
...
40
```

**Cuarenta comandos, en `/usr/bin`, en el PATH.** Son exactamente los mismos cuarenta que hay dentro de la imagen `cp-kafka:8.2.0` que usaste en los labs 01 al 08 — mismo nombre, misma cantidad, mismo origen. Lo que cambió es que aquí no hay ningún contenedor delante: son binarios del sistema, como `ls` o `grep`.

> **Anota:** ¿cuántos de esos 40 comandos usaste ya en el curso?

---

## Momento 2 · ¿Dónde está la configuración de verdad? (~11 min)

Este es el momento que conecta con el **lab 03**, y conviene recordar qué pasó allí.

En el lab 03 listaste los `.properties` de un broker en Docker y descubriste algo incómodo: había un archivo llamado `server.properties`… **que no era el que el broker estaba usando**. El que mandaba era `kafka.properties`, y no lo había escrito nadie: lo **generaba la imagen** al arrancar, traduciendo las variables `KAFKA_*` de tu compose.

Compruébalo aquí. Primero, cuenta los archivos:

```bash
ls /etc/kafka/*.properties | wc -l
```

```
12
```

En un contenedor de los labs anteriores, ese mismo comando devuelve **13**. El decimotercero es `kafka.properties`, y **solo existe cuando el contenedor está corriendo**: en la imagen apagada no está. Aquí no aparece nunca, porque nadie lo genera.

Y ahora la diferencia que importa. En Docker, el proceso arrancaba así:

```
java ... kafka.Kafka /etc/kafka/kafka.properties      <- el generado
```

Aquí, mira qué archivo usa el servicio:

```bash
grep ExecStart /usr/lib/systemd/system/confluent-kafka.service
```

```
ExecStart=/usr/bin/kafka-server-start /etc/kafka/server.properties
```

**`server.properties`. El archivo que vas a editar tú, con `vi`, ahora mismo.** No hay traducción, no hay generación, no hay variable de entorno intermedia. Lo que escribes es lo que lee el broker.

### Míralo antes de tocarlo

```bash
grep -vE "^#|^$" /etc/kafka/server.properties | head -12
```

```
process.roles=broker,controller
node.id=1
controller.quorum.bootstrap.servers=localhost:9093
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
inter.broker.listener.name=PLAINTEXT
advertised.listeners=PLAINTEXT://localhost:9092,CONTROLLER://localhost:9093
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
```

Reconoces todo. `process.roles=broker,controller` es el nodo combinado del lab 01. `node.id`, los `listeners`, el `controller.listener.names` — todo eso lo escribiste como variables `KAFKA_*` en un compose. Aquí ya viene escrito, en su forma nativa, en un archivo de texto.

### Ahora edítalo

```bash
vi /etc/kafka/server.properties
```

Haz **dos** cambios:

**1 · El quórum, en la forma que estudiaste en el lab 02.** Busca la línea:

```
controller.quorum.bootstrap.servers=localhost:9093
```

y déjala así:

```
controller.quorum.voters=1@localhost:9093
```

Esta es literalmente la propiedad que analizaste en el lab 02, con su formato `id@host:puerto`. Escribirla a mano, en el archivo real, es distinto a verla generada.

**2 · Dónde viven los datos.** Busca:

```
log.dirs=/tmp/kraft-combined-logs
```

y déjala así:

```
log.dirs=/var/lib/kafka/data
```

`/tmp` se borra al reiniciar. `/var/lib/kafka/data` es la ruta que usaron todos los labs anteriores, y en este servidor está sobre un disco que persiste.

Verifica tus cambios:

```bash
grep -E "^(process.roles|node.id|controller.quorum.voters|log.dirs)" /etc/kafka/server.properties
```

```
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093
log.dirs=/var/lib/kafka/data
```

> **Anota:** en el lab 03, ¿qué habría pasado si editabas `server.properties` en el contenedor y reiniciabas?

---

## Momento 3 · ¿Cómo se enciende? (~8 min)

### Primero, formatear el almacenamiento

Es **el mismo comando del lab 01**. Compáralo mentalmente con el que corriste allí:

```bash
runuser -u cp-kafka -- kafka-storage format \
  --cluster-id MkU3OEVBNTcwNTJENDM2Qk \
  --config /etc/kafka/server.properties
```

```
Formatting metadata directory /var/lib/kafka/data with metadata.version 4.2-IV1.
```

Dos detalles que Docker te ahorraba:

- **`runuser -u cp-kafka`**: el formateo lo hace el usuario del servicio, no `root`. Si formateas como `root`, los archivos quedan de `root` y el servicio —que corre como `cp-kafka`— no podrá escribir. Es el error de permisos más común al instalar Kafka a mano.
- **`--config /etc/kafka/server.properties`**: le pasas el archivo que acabas de editar. En Docker ese argumento venía cocinado.

### Ahora arrancar el servicio

```bash
systemctl start confluent-kafka
systemctl status confluent-kafka
```

```
● confluent-kafka.service - Apache Kafka - broker
     Loaded: loaded (/usr/lib/systemd/system/confluent-kafka.service; disabled; preset: disabled)
     Active: active (running) since Tue 2026-08-18 16:24:38 UTC; 4s ago
       Docs: http://docs.confluent.io/
   Main PID: 273 (java)
      Tasks: 124 (limit: 79998)
     Memory: 392.2M (peak: 395.0M)
```

Lee la unidad completa, que es corta y lo dice todo:

```bash
cat /usr/lib/systemd/system/confluent-kafka.service
```

```
[Unit]
Description=Apache Kafka - broker
After=network.target

[Service]
Type=simple
User=cp-kafka
Group=confluent
ExecStart=/usr/bin/kafka-server-start /etc/kafka/server.properties
LimitNOFILE=1000000
TimeoutStopSec=180
Restart=no

[Install]
WantedBy=multi-user.target
```

Cuatro líneas que en producción se revisan siempre:

| Línea | Qué significa |
|-------|---------------|
| `User=cp-kafka` | El broker **no corre como root**. |
| `LimitNOFILE=1000000` | Kafka abre un descriptor por segmento y por conexión. Con el límite por defecto del sistema, un broker con carga real se cae. |
| `TimeoutStopSec=180` | `systemd` le da tres minutos para cerrar ordenado antes de matarlo. |
| `Restart=no` | Si el broker muere, **no se levanta solo**. En un clúster eso es deliberado: prefieres saberlo. |

### Dónde se miran los logs

Hay dos caminos, y conviene conocer los dos:

```bash
journalctl -u confluent-kafka -n 50
ls /var/log/kafka/
```

```
controller.log
kafka-authorizer.log
kafka-request.log
kafkaServer-gc.log
log-cleaner.log
server.log
state-change.log
```

`journalctl` te da lo que `systemd` capturó de la salida del proceso. `/var/log/kafka/` son los archivos que escribe el propio Kafka vía log4j, con mucho más detalle y separados por tema. En Docker esto era `docker logs` y punto.

---

## Momento 4 · Los mismos comandos, sin envase (~10 min)

Este es el corazón del laboratorio. Todo lo que sigue lo ejecutaste ya en los labs 01 y 02 — con `docker exec` adelante. Ahora no.

### La carta de servicios del broker

```bash
kafka-broker-api-versions --bootstrap-server localhost:9092
```

```
localhost:9092 (id: 1 rack: null isFenced: false) -> (
	Produce(0): 0 to 13 [usable: 13],
	Fetch(1): 4 to 18 [usable: 18],
	ListOffsets(2): 1 to 11 [usable: 11],
	Metadata(3): 0 to 13 [usable: 13],
	OffsetCommit(8): 2 to 10 [usable: 10],
```

### Crear, listar y describir un tópico

```bash
kafka-topics --bootstrap-server localhost:9092 \
  --create --topic novatech.lab08b.demo --partitions 3 --replication-factor 1

kafka-topics --bootstrap-server localhost:9092 --list

kafka-topics --bootstrap-server localhost:9092 --describe --topic novatech.lab08b.demo
```

```
Created topic novatech.lab08b.demo.
novatech.lab08b.demo
Topic: novatech.lab08b.demo	TopicId: zdY-o2r1QRi52JDfqPSoNA	PartitionCount: 3	ReplicationFactor: 1	Configs: min.insync.replicas=1
	Topic: novatech.lab08b.demo	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr:
	Topic: novatech.lab08b.demo	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr:
	Topic: novatech.lab08b.demo	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr:
```

### El quórum

```bash
kafka-metadata-quorum --bootstrap-server localhost:9092 describe --status
```

```
ClusterId:              MkU3OEVBNTcwNTJENDM2Qk
LeaderId:               1
LeaderEpoch:            1
HighWatermark:          120
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   0
CurrentVoters:          [{"id": 1, "endpoints": ["CONTROLLER://localhost:9093"]}]
CurrentObservers:       []
```

### Lado a lado

Estos mismos cuatro comandos se corrieron contra un broker en Docker con la configuración del lab 01, con el mismo `--cluster-id`. El resultado:

| Comando | Diferencia entre Docker y RHEL |
|---------|--------------------------------|
| `kafka-broker-api-versions` | **Ninguna. Idénticas byte a byte.** |
| `kafka-topics --create` | **Ninguna. Idénticas byte a byte.** |
| `kafka-topics --describe` | Solo el `TopicId`, que Kafka genera al azar en cada tópico. |
| `kafka-metadata-quorum` | Solo el `HighWatermark` —un contador que avanza con el tiempo— y el endpoint del controlador: `CONTROLLER://kafka-broker:39092` en Docker contra `CONTROLLER://localhost:9093` aquí. Es el nombre de host y el puerto que eligió cada laboratorio, no una diferencia de plataforma. |

**No hay ninguna diferencia atribuible a estar sobre RHEL en vez de sobre Docker.** Los comandos, los flags y las salidas son los mismos. Eso es exactamente lo que el curso viene afirmando desde el lab 01, y aquí queda demostrado.

---

## Momento 5 · Lo que Docker escondía (~5 min)

### El usuario y los permisos

```bash
ps -o user=,pid=,comm= -C java
id cp-kafka
ls -ld /var/lib/kafka/data
```

```
cp-kafka   273 java
uid=998(cp-kafka) gid=998(confluent) groups=998(confluent)
drwxr-xr-x 6 cp-kafka confluent 4096 Aug 18 16:26 /var/lib/kafka/data
```

El paquete creó el usuario `cp-kafka` y el grupo `confluent` al instalarse. El broker corre con ese usuario, y el directorio de datos le pertenece. **En producción esto es lo primero que se revisa cuando un broker no arranca:** casi siempre alguien formateó o copió archivos como `root`.

### Dónde están los datos, en un disco de verdad

> **Ésta es la sección que se recorta si el bloque va apretado.** Lo esencial del momento 5 son el usuario, los permisos y el `failed` de más abajo.


```bash
ls /var/lib/kafka/data
df -h /var/lib/kafka/data
```

```
__cluster_metadata-0
bootstrap.checkpoint
cleaner-offset-checkpoint
log-start-offset-checkpoint
meta.properties
novatech.lab08b.demo-0
/dev/vda1       911G  120G  745G  14% /var/lib/kafka/data
```

Un directorio por partición, y `__cluster_metadata-0`, que es el log de KRaft del lab 01 y 02. **Kafka se queda sin disco antes que sin memoria**, y ese `df` es la línea que se vigila en un servidor real.

### Cuando el servicio no arranca — y un `failed` que no es un fallo

Apaga el servicio y mira el estado:

```bash
systemctl stop confluent-kafka
systemctl is-active confluent-kafka
```

```
failed
```

**`failed`, después de un apagado ordenado que tú pediste.** No es un error tuyo ni del laboratorio: es la unidad tal como la publica Confluent. `kafka-server-start` termina con un código distinto de cero cuando recibe la señal de apagado, la unidad no declara `SuccessExitStatus`, y `systemd` lo anota como fallo. **En un servidor de SUNAT pasa exactamente igual.**

La prueba de que el apagado fue limpio la da el propio Kafka la próxima vez que arranca:

```bash
systemctl start confluent-kafka
journalctl -u confluent-kafka | grep "clean shutdown"
```

```
Skipping recovery of 3 logs from /var/lib/kafka/data since clean shutdown file was found
```

Kafka encontró la marca de apagado limpio y se saltó la recuperación de los logs. **La lección:** una palabra en `systemctl` no es un diagnóstico. El diagnóstico está en el journal.

### Y una última: la unidad no arranca sola

```bash
systemctl is-enabled confluent-kafka
```

```
disabled
```

`start` enciende el servicio **ahora**. `enable` hace que arranque **al encender el servidor**. Son cosas distintas y se confunden todo el tiempo. Si solo hiciste `start`, el día que ese servidor se reinicie el broker no vuelve.

```bash
systemctl enable confluent-kafka
```

> **Anota:** en tu clúster de SUNAT, ¿las unidades de Kafka están `enabled`?

---

## Cierre

Recapitula lo que acaba de pasar:

| | Labs 01 a 08 (Docker) | Este laboratorio (RHEL 9) |
|---|---|---|
| **De dónde sale Kafka** | `docker pull` de una imagen | `yum install` de un repositorio firmado |
| **La configuración** | Variables `KAFKA_*` en el compose, traducidas a `kafka.properties` | `/etc/kafka/server.properties`, editado con `vi` |
| **Cómo se enciende** | `docker compose up` | `kafka-storage format` + `systemctl start` |
| **Los logs** | `docker logs` | `journalctl -u` y `/var/log/kafka/` |
| **Quién corre el proceso** | Invisible | `cp-kafka`, con su grupo y sus permisos |
| **Los comandos de Kafka** | `kafka-topics`, `kafka-configs`, … | **Los mismos 40, idénticos** |

La última fila es la que importa. Todo lo que aprendiste en trece laboratorios se aplica igual cuando le quitas el envase. Lo que cambia es la capa de abajo: el paquete, el servicio, el archivo y el usuario. Y ésa es, justamente, la capa que administras en SUNAT.

---

## Cuando termines

```bash
exit                # salir del servidor RHEL
bin/90-test-lab.sh  # ver el estado del laboratorio
bin/stop-lab.sh     # apagar conservando tus datos y tu configuración
```

Si vuelves con `bin/start-lab.sh`, el servidor se reanuda **tal como lo dejaste**: tu `server.properties` editado sigue ahí. Para volver al servidor recién instalado y repetir el laboratorio desde cero, usa `bin/reset-lab.sh`.
