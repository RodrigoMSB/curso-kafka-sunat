# Lab 08b: Kafka sobre RHEL 9, sin Docker adelante

**Curso**: Administración de Confluent Apache Kafka (SUNAT)  
**Unidad**: 3 - Configuración del clúster, tópicos y rendimiento  
**Duración estimada**: ~45 minutos  
**Modalidad**: conducido por el relator

---

## Contexto

Los trece laboratorios anteriores corren Kafka dentro de contenedores. Los comandos son los reales y las salidas son las reales, pero hay una capa que Docker esconde por completo: el paquete, el servicio, el archivo de configuración en disco y el usuario que corre el proceso.

En SUNAT los clústeres están instalados sobre **RHEL con `yum`**. Este laboratorio cierra esa brecha: instala Kafka como se instala en un servidor, lo arranca como servicio de `systemd`, y ejecuta **los mismos comandos de los labs 01 y 02 sin `docker exec` adelante**.

> **Qué NO es este lab.** No reemplaza al lab 08 ni a ningún otro, y no es un laboratorio de operación avanzada. Es un laboratorio de **plataforma**. Su objetivo se cumple cuando dices: *"es lo mismo, pero sin Docker adelante"*.

---

## ¿Qué vas a ver?

1. **De dónde sale Kafka sin Docker**: el repositorio de Confluent, la clave GPG, `yum install`, y dónde quedan los binarios.
2. **Dónde está la configuración de verdad**: `/etc/kafka/server.properties`, un archivo que se edita con `vi`. En el lab 03 descubriste que el archivo bueno lo *generaba* la imagen a partir de variables del compose. Aquí no hay generación: el archivo es el que editas tú.
3. **Cómo se enciende**: `kafka-storage format` —el mismo del lab 01— y el arranque del servicio con `systemctl`. Dónde se miran los logs.
4. **Los mismos comandos, sin envase**: `kafka-topics`, `kafka-broker-api-versions`, `kafka-metadata-quorum`. Idénticos a los de los labs 01 y 02.
5. **Lo que Docker escondía**: el usuario del servicio, los permisos del directorio de datos, el espacio en disco, y dónde mirar cuando el servicio no arranca.

---

## Arquitectura del lab

| Nodo | Rol | Cómo está instalado |
|------|-----|---------------------|
| `kafka-rhel` | broker + controller (KRaft) | RHEL 9.8, paquete `confluent-kafka` instalado con `yum` |

**Un solo nodo, a propósito.** Con uno se ve todo lo que este lab quiere mostrar: paquete, servicio, archivo y comandos. La lección del quórum ya está en el lab 02, y tres nodos triplicarían el trabajo sin agregar lección.

---

## Decisiones que este lab declara abiertamente

Un laboratorio que enseña plataforma no puede mentir sobre su propia plataforma. Estas tres cosas se dicen en voz alta:

**1 · La imagen base es UBI 9, y es RHEL de verdad.**  
RHEL exige suscripción para `yum`. UBI (*Universal Base Image*) es la imagen oficial de Red Hat, libre y sin suscripción. Adentro, `/etc/redhat-release` dice `Red Hat Enterprise Linux release 9.8 (Plow)`. No es Rocky ni Alma —que son binario-compatibles pero no son RHEL—: es RHEL.

**2 · El paquete instalado es `confluent-kafka`, no `confluent-platform`.**  
En producción SUNAT instala `confluent-platform`, que arrastra Schema Registry, ksqlDB y Connect: unos 2,4 GB para un lab de un solo broker. Aquí se instala `confluent-kafka`, el broker Apache empaquetado por Confluent, que trae **exactamente los mismos comandos `kafka-*`** que la imagen usada en los otros trece labs. Esa igualdad es lo que permite comparar salidas lado a lado. El procedimiento —repositorio, clave GPG, `yum install`— es idéntico al de producción; lo único que cambia es el nombre del paquete.

**3 · `systemd` corre dentro de un contenedor, y eso necesita un permiso.**  
El compose monta el árbol de cgroups del sistema para que `systemd` pueda arrancar. Es lo mínimo que necesita: **no usa `--privileged` y no agrega ninguna capacidad**; el contenedor tiene el mismo conjunto de permisos que cualquier otro lab del curso. En un servidor real esto no hace falta, porque allí `systemd` *es* el sistema.

---

## Prerrequisitos

- Docker Desktop corriendo
- Conexión a internet la primera vez: la construcción descarga unos **255 MB** (imagen base más paquetes)
- Espacio en disco: la imagen resultante ocupa unos **0,6 GB**, comparable a la imagen que ya usan los otros labs

---

## Cómo se usa

```bash
# 1. Levantar el servidor RHEL con Kafka instalado (y apagado)
bin/start-lab.sh

# 2. Entrar al servidor. Este es el único 'docker' de todo el laboratorio.
docker exec -it kafka-rhel bash

# 3. Seguir la guía desde adentro
#    guia/01-kafka-sin-docker.md

# 4. En cualquier momento, ver dónde estás
bin/90-test-lab.sh

# 5. Al terminar
bin/stop-lab.sh     # apaga y conserva los datos
bin/reset-lab.sh    # borra los datos y vuelve al servidor recién instalado
```

**El broker no arranca solo.** `start-lab.sh` deja Kafka instalado y apagado a propósito: formatear el almacenamiento y encender el servicio *es* el laboratorio.

---

## Estructura

```
lab-08b-instalacion-rhel/
├── README.md
├── guia/            los cinco momentos del laboratorio
├── infra/           Dockerfile, docker-compose.yml, .env
├── bin/             start-lab, stop-lab, reset-lab, 90-test-lab, common.sh
└── docs/            troubleshooting
```

Proyecto compose propio (`novatech-lab08b`) y red propia: este lab no puede alcanzar los recursos de ningún otro, y ningún otro puede alcanzar los suyos. **No publica ningún puerto en el host**, porque todo el trabajo ocurre dentro del servidor.
