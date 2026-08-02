# Preguntas abiertas

Cosas que salieron trabajando y que no se resolvieron en el momento, con
dónde corresponde retomarlas. No son bugs conocidos: son cosas que no
entendemos todavía y que pueden ser material de clase.

---

## `min.insync.replicas` del broker sobre un tópico que ya existe

**Dónde retomarla:** Lab 05, que es donde se enseña configuración de tópicos.
Esta distinción es exactamente la lección de ese lab.

**Qué pasó.** Al intentar sabotear el e2e del Lab 01 se puso
`KAFKA_MIN_INSYNC_REPLICAS: 2` en un clúster de **un solo broker**, con los
tópicos en RF=1. Con `acks=all`, el productor debería haber fallado con
`NOT_ENOUGH_REPLICAS`. No falló: el e2e quedó en verde y las 3 marcas se
produjeron y se consumieron.

**Hipótesis del PO**, sin verificar: el `min.insync.replicas` del broker es un
**default para tópicos nuevos** y no se aplica retroactivamente. Un tópico
que ya existía conserva el valor con el que nació, así que cambiar el default
del broker no lo afecta.

**Por qué importa para el alumno.** Si es cierto, es una trampa clásica de
operación: un administrador sube `min.insync.replicas` en el broker esperando
endurecer todo el clúster, y los tópicos que ya existían siguen exactamente
igual. La diferencia entre **default del broker** y **configuración efectiva
del tópico** es justo lo que `kafka-configs --describe --all` muestra y lo que
el Lab 05 enseña a leer.

**Cómo verificarla.** Sobre un clúster de un broker, comparar
`kafka-configs --entity-type topics --entity-name X --describe --all` en un
tópico creado antes del cambio y en uno creado después, y ver de dónde sale
el valor en cada caso (`DEFAULT_CONFIG` contra `STATIC_BROKER_CONFIG` o
`DYNAMIC_TOPIC_CONFIG`).
