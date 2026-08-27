#!/bin/bash
# ============================================================
# Lab 05 · soluciones/crear-topicos.sh
# ============================================================
# El script de aprovisionamiento resuelto: los tres valores que practica/PASOS.md
# te pide decidir en el Paso 3, ya puestos y justificados.
#
# Los comentarios de este archivo NO explican qué hace cada línea — eso se lee
# solo. Explican POR QUÉ está puesta, que es lo que no se puede deducir del
# código y lo que te va a hacer falta el día que tengas que decidir estos
# mismos valores en el clúster de SUNAT.
#
# Uso:
#   bash soluciones/crear-topicos.sh
# ============================================================

set -uo pipefail

# POR QUÉ una ruta calculada y no una relativa:
# el alumno puede invocar el script desde la raíz del lab, desde dentro de
# soluciones/, o desde cualquier otro sitio. "$(dirname "$0")/.." resuelve
# siempre al directorio del lab, sin depender de dónde estaba parado el shell.
DIR_LAB="$(cd "$(dirname "$0")/.." && pwd)"

# ── PARTICIONES = 1 ──────────────────────────────────────────
# POR QUÉ 1 y no 3 o 6:
# no es por ahorrar recursos. Es la única forma de que el experimento sea
# legible. El productor de consola usa el particionador "sticky": cuando los
# mensajes no llevan clave, se pega a UNA partición durante toda la sesión y
# en la siguiente sesión elige otra. Con 3 particiones, la primera ráfaga cae
# entera en una y la segunda ráfaga —la que tiene que cerrar el segmento— cae
# en OTRA. Resultado: el segmento que contiene los datos nunca rota, nunca se
# cierra, y nunca se borra nada.
#
# Esto se midió: con 3 particiones el borrado tardó 265 s y dejó una partición
# sin tocar. Con 1 partición tardó 128 s y borró todo lo vencido.
# Con una sola partición hay un solo segmento activo y las dos ráfagas caen
# obligatoriamente en el mismo sitio.
PARTICIONES=1

# ── RETENTION_MS = 60000 ─────────────────────────────────────
# POR QUÉ 60 segundos:
# es el plazo más corto que sigue siendo honesto. Más corto no aporta —el
# broker solo revisa cada 5 minutos de todos modos (log.retention.check.
# interval.ms=300000), así que bajar de 60 s no adelanta el borrado ni un
# segundo. Más largo obligaría a esperar en clase sin ganar nada.
#
# OJO con el valor especial: retention.ms=-1 significa "para siempre", NO
# "cero". Un dedo de más en ese signo convierte un tópico efímero en uno que
# nunca se limpia y llena el disco del broker.
RETENTION_MS=60000

# ── SEGMENT_MS = 10000 ───────────────────────────────────────
# POR QUÉ 10 segundos, y POR QUÉ tiene que ser menor que RETENTION_MS:
# Kafka nunca borra el segmento activo. Para que haya algo que botar, el
# segmento tiene que cerrarse primero. Si segment.ms fuera mayor o igual que
# retention.ms, cuando el segmento por fin se cerrara sus mensajes recién
# empezarían a contar el plazo, y el borrado se iría al doble de tiempo.
#
# Con el valor de fábrica (604800000 = 7 días) este laboratorio no mostraría
# absolutamente nada, y esa es justamente la trampa que la guía desarma: la
# gente configura retention.ms, deja segment.ms de fábrica, y concluye que
# "la retención de Kafka no funciona".
#
# OJO: segment.ms no es un temporizador. El segmento se cierra en la próxima
# ESCRITURA posterior a los 10 s, no a los 10 s. En un tópico sin tráfico
# nuevo no rota nunca. Por eso la guía pide una segunda ráfaga.
SEGMENT_MS=10000

# ── TOPICO ───────────────────────────────────────────────────
# POR QUÉ este nombre y no "test" o "prueba":
# el prefijo del lab hace obvio de dónde salió y quién lo puede borrar. En un
# clúster compartido, un tópico llamado "test" es un tópico que nadie se
# atreve a tocar porque nadie sabe de quién es.
TOPICO="novatech.lab05.efimero"

# ── REPLICAS = 3 ─────────────────────────────────────────────
# POR QUÉ 3 en un tópico desechable:
# porque el clúster tiene min.insync.replicas=2 puesto a nivel de broker. Con
# menos de 3 réplicas, perder un broker dejaría este tópico sin poder aceptar
# escrituras, y el laboratorio se caería por una razón que no tiene nada que
# ver con lo que está enseñando.
REPLICAS=3

# ============================================================
# Creación
# ============================================================
echo "  Creando ${TOPICO}"
echo "    particiones:   ${PARTICIONES}"
echo "    réplicas:      ${REPLICAS}"
echo "    retention.ms:  ${RETENTION_MS}"
echo "    segment.ms:    ${SEGMENT_MS}"
echo ""

# POR QUÉ se llama al envoltorio del curso y no a kafka-topics directo:
# create-topic.sh resuelve solo cuál de los tres brokers está vivo y con qué
# puerto interno hablarle. Llamar a kafka-topics a mano obligaría a fijar
# "kafka-broker-1" aquí, y el script se rompería en cuanto ese broker se
# apague — que es exactamente lo que pasa en el Lab 02 y en el Lab 14.
"${DIR_LAB}/kafka-cli/create-topic.sh" "$TOPICO" \
    --partitions "$PARTICIONES" \
    --rf "$REPLICAS" \
    --config "retention.ms=${RETENTION_MS}" \
    --config "segment.ms=${SEGMENT_MS}"
