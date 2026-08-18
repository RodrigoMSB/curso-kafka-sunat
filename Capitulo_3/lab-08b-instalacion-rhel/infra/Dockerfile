# ============================================================
# NovaTech Logistics - Lab 08b: Kafka sobre RHEL 9, sin Docker adelante
# ============================================================
# Este lab no usa la imagen cp-kafka de los otros 13 labs. Instala Kafka
# como lo instala SUNAT en sus servidores: repositorio, clave GPG y yum.
# Lo que el alumno ve adentro es un RHEL 9 con un paquete, un servicio y
# un archivo de configuracion de verdad.

# ── Por que UBI 9 y no "rhel:9" ──
# RHEL pide suscripcion para yum. UBI (Universal Base Image) es la imagen
# oficial de Red Hat, libre y sin suscripcion, y NO es un derivado: adentro
# dice "Red Hat Enterprise Linux release 9.8 (Plow)". La alternativa habria
# sido Rocky o Alma, que son binario-compatibles pero no son RHEL.
FROM registry.access.redhat.com/ubi9/ubi:9.8

# ── Por que la version va pinchada ──
# El repositorio de Confluent sirve la rama 8.2 completa, y hoy su ultima
# version es mas nueva que la 8.2.0. Sin el pin, este lab instalaria una
# version distinta a la de los otros 13 labs y las salidas dejarian de
# calzar: el alumno compararia un `kafka-topics --describe` de aqui contra
# el del lab 01 y verian diferencias que no tienen nada que ver con la
# leccion. El pin es lo que sostiene la promesa del lab.
ARG CONFLUENT_VERSION=8.2.0
ARG CONFLUENT_REPO=8.2

# ── El repositorio de Confluent, igual que en un servidor real ──
# Es exactamente lo que documenta Confluent para RHEL: importar la clave
# GPG y declarar el repositorio. gpgcheck=1 no es decorativo: sin el, yum
# instalaria cualquier cosa que responda en esa URL.
RUN rpm --import "https://packages.confluent.io/rpm/${CONFLUENT_REPO}/archive.key" && \
    printf '%s\n' \
      '[Confluent]' \
      'name=Confluent repository' \
      "baseurl=https://packages.confluent.io/rpm/${CONFLUENT_REPO}" \
      'gpgcheck=1' \
      "gpgkey=https://packages.confluent.io/rpm/${CONFLUENT_REPO}/archive.key" \
      'enabled=1' \
      > /etc/yum.repos.d/confluent.repo

# ── Que paquete y por que este ──
# Confluent publica varios. En produccion SUNAT instala `confluent-platform`,
# que arrastra Schema Registry, ksqlDB, Connect y Control Center: 2,4 GB
# instalados para un lab de un solo broker. `confluent-kafka` es el broker
# Apache empaquetado por Confluent, licencia Apache 2.0, y trae exactamente
# los mismos 40 comandos `kafka-*` que la imagen cp-kafka de los otros labs.
# Esa igualdad es el punto entero del lab: los comandos no cambian, cambia
# el envase. La guia declara esta diferencia al alumno; no se la esconde.
#
# procps-ng, vim-minimal, less y hostname no vienen en UBI y el lab los
# necesita: `ps` para ver el proceso, `vi` para editar la configuracion a
# mano, `less` para paginar el journal, `hostname` para que el broker se
# identifique.
RUN dnf -y install \
        java-21-openjdk-headless \
        "confluent-kafka-${CONFLUENT_VERSION}" \
        procps-ng \
        vim-minimal \
        less \
        hostname && \
    dnf clean all

# ── Donde viven los datos y los logs ──
# El paquete crea el usuario cp-kafka:confluent pero no estos directorios.
# Se crean aqui, con su duenio correcto, porque el volumen de Docker hereda
# el propietario del directorio de la imagen la primera vez que se monta.
# Si se crearan despues, el volumen quedaria de root y el servicio -- que
# corre como cp-kafka, no como root -- no podria escribir.
RUN mkdir -p /var/lib/kafka/data /var/log/kafka && \
    chown -R cp-kafka:confluent /var/lib/kafka /var/log/kafka

# systemd necesita recibir SIGRTMIN+3 para apagarse ordenado. Con el SIGTERM
# por omision el contenedor se mata a los 10 segundos y el broker no cierra
# sus archivos.
STOPSIGNAL SIGRTMIN+3

# El contenedor arranca systemd, no Kafka. Kafka lo enciende el alumno con
# systemctl, que es de lo que trata este lab.
CMD ["/sbin/init"]
