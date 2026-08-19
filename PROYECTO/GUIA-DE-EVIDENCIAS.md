# Guía de evidencias

Para cada hito: **qué se evalúa, qué evidencia lo demuestra, y con qué comando exacto se obtiene.**

Si sigues esta guía no vas a entregar una captura que no prueba nada, que es el error más común.

---

## Regla general

Una evidencia sirve cuando **muestra un antes y un después**, o cuando **muestra un estado que solo puede existir si hiciste bien el trabajo**.

Una captura del clúster corriendo no prueba casi nada: cualquiera levanta un `docker compose up`. Una captura del quórum eligiendo un líder nuevo después de matar al anterior **sí prueba** que construiste algo resiliente.

---
---

# Hito 1 · Diseño de la arquitectura · 4 puntos

> **Se evalúa:** coherencia de la topología, elección de componentes y justificación del dimensionamiento.

Este hito es de diseño, no de ejecución. **No necesita salidas de comandos.**

### Qué entregar

| Evidencia | Cómo se hace |
|---|---|
| Un diagrama de la topología | A mano, en PowerPoint, en draw.io, como quieras. Tiene que mostrar los brokers, los controladores, los tópicos principales y los componentes del ecosistema que elegiste |
| Una tabla de dimensionamiento | Cuántos brokers, cuántos controladores, cuántas particiones por tópico, y **el porqué de cada número** |

### Dónde guardarlo

```
entrega/evidencias/hito-1/
    topologia.png
    dimensionamiento.md   (o dentro del expediente, si prefieres)
```

### El error típico

Poner números sin justificarlos. **Tres brokers no es la respuesta: la respuesta es por qué tres.**

---
---

# Hito 2 · Despliegue en KRaft y resiliencia · 4 puntos

> **Se evalúa:** quórum correctamente dimensionado y **demostración** de tolerancia a la caída de un nodo.

La palabra que importa es *demostración*. No basta con decir que tolera: hay que mostrarlo.

### Evidencia 1 · El clúster formado y con quórum

```bash
cd Capitulo_2/lab-02-validacion-quorum-resiliencia
bin/check-quorum.sh > ../../PROYECTO/entrega/evidencias/hito-2/quorum-inicial.txt
```

**Qué demuestra:** que los tres nodos se reconocen entre sí, que hay un líder electo y que los tres están al día.

**Qué mirar en la salida:** `LeaderId`, `CurrentVoters` con los tres, y el `Lag` en cero.

### Evidencia 2 · El estado antes de la caída

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.pedidos > ../../PROYECTO/entrega/evidencias/hito-2/topico-antes.txt
```

**Qué demuestra:** que el tópico tiene sus réplicas completas. Fíjate en la columna `Isr`.

### Evidencia 3 · La caída

```bash
docker stop kafka-broker-1
```

Guarda también qué apagaste y por qué elegiste ese nodo.

### Evidencia 4 · El quórum después de la caída

```bash
docker exec kafka-broker-2 kafka-metadata-quorum \
    --bootstrap-server kafka-broker-2:29093 \
    describe --status > ../../PROYECTO/entrega/evidencias/hito-2/quorum-tras-caida.txt
```

**Qué demuestra:** el líder cambió, el `LeaderEpoch` subió, y el clúster sigue operando. **Esta es la evidencia más importante del hito.**

### Evidencia 5 · El tópico con el ISR incompleto

```bash
docker exec kafka-broker-2 kafka-topics \
    --bootstrap-server kafka-broker-2:29093 \
    --describe --topic novatech.pedidos > ../../PROYECTO/entrega/evidencias/hito-2/topico-tras-caida.txt
```

**Qué demuestra:** `Replicas` sigue con tres números y `Isr` bajó a dos. **Esa diferencia es la prueba de que el sistema sabe que perdió un nodo y sigue funcionando igual.**

### Evidencia 6 · La recuperación

```bash
docker start kafka-broker-1
```

Espera veinte segundos y vuelve a correr el `check-quorum.sh`, guardándolo como `quorum-recuperado.txt`.

**Qué demuestra:** el nodo se reincorporó solo y volvió a estar al día.

### El error típico

Entregar solo la foto final con todo funcionando. **Sin el antes y el después, no demuestras nada.**

---
---

# Hito 3 · Configuración y rendimiento · 5 puntos

> **Se evalúa:** operación multi-broker, tópicos bien configurados, conectividad resuelta y ajuste con evidencia.

Son cuatro cosas distintas y cada una necesita su evidencia.

### Evidencia 1 · Los tópicos con sus políticas

```bash
cd Capitulo_3/lab-05-operacion-topicos
kafka-cli/describe-topic.sh novatech.gps.realtime > ../../PROYECTO/entrega/evidencias/hito-3/topico-retencion-corta.txt
kafka-cli/describe-topic.sh novatech.audit.events > ../../PROYECTO/entrega/evidencias/hito-3/topico-retencion-infinita.txt
kafka-cli/describe-topic.sh novatech.vehicle.state > ../../PROYECTO/entrega/evidencias/hito-3/topico-compactado.txt
```

**Qué demuestra:** que configuraste tópicos distintos para necesidades distintas. **Fíjate en la línea `Configs` de cada uno: ahí está la diferencia.**

### Evidencia 2 · La conectividad resuelta

```bash
cd Capitulo_3/lab-04-multibroker-advertised-listeners
docker exec kafka-broker-1 bash -c 'grep listeners /etc/kafka/kafka.properties' > ../../PROYECTO/entrega/evidencias/hito-3/listeners.txt
```

**Qué demuestra:** que entiendes la diferencia entre las puertas que el broker abre y la dirección que le publica a cada tipo de cliente.

**Vale mucho más si además entregas:** una prueba de conexión que falla con el listener equivocado y otra que funciona con el correcto. Eso demuestra que entendiste el problema, no solo que copiaste la configuración.

### Evidencia 3 · La retención funcionando

Del laboratorio 05, el tópico efímero:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero
```

**Corre esto dos veces**, con dos minutos de diferencia, y guarda las dos salidas como `retencion-antes.txt` y `retencion-despues.txt`.

**Qué demuestra:** que la política de retención no es teoría — Kafka borró mensajes solo, porque tú se lo dijiste.

### Evidencia 4 · El ajuste de rendimiento

```bash
cd Capitulo_3/lab-07-pruebas-rendimiento
```

Corre una prueba de rendimiento, cambia **un** parámetro, y corre la misma prueba de nuevo. Guarda las dos salidas.

**Qué demuestra:** que el ajuste tuvo efecto medible. **Un solo parámetro a la vez** — si cambias tres cosas y mejora, no sabes cuál sirvió.

**Si este laboratorio se hizo en modalidad demostrada:** puedes usar las salidas de la sesión, indicándolo, y complementar con tu análisis de qué parámetro moverías y por qué.

### El error típico

Entregar una sola medición. **Rendimiento sin comparación no es evidencia**: un número solo no dice si está bien o mal.

---
---

# Hito 4 · Seguridad, alta disponibilidad y operación · 5 puntos

> **Se evalúa:** cifrado, autenticación y autorización aplicados, esquema de alta disponibilidad y plan de recuperación.

### Evidencia 1 · El material criptográfico existe

```bash
cd Capitulo_5/lab-14-capstone-resiliencia-seguridad
ls -la infra/certs/ > ../../PROYECTO/entrega/evidencias/hito-4/pki-generada.txt
```

**Qué demuestra:** que la infraestructura de certificados está creada. **No entregues el contenido de las llaves privadas**, solo el listado.

### Evidencia 2 · La conexión segura funciona

```bash
kafka-cli/describe-confidencial.sh > ../../PROYECTO/entrega/evidencias/hito-4/conexion-sasl-ssl.txt
```

**Qué demuestra:** que un usuario autenticado por SASL sobre TLS puede operar.

### Evidencia 3 · Las ACLs cargadas

```bash
kafka-cli/list-acls.sh > ../../PROYECTO/entrega/evidencias/hito-4/acls.txt
```

**Qué demuestra:** que definiste quién puede hacer qué. **Esta es la evidencia central del hito.**

### Evidencia 4 · La prueba negativa · vale doble

Aquí está lo que separa una entrega buena de una excelente. **Demuestra que la seguridad rechaza lo que tiene que rechazar:**

```bash
kafka-cli/attempt-no-auth.sh > ../../PROYECTO/entrega/evidencias/hito-4/rechazo-sin-credenciales.txt
kafka-cli/consume-confidencial-app2.sh > ../../PROYECTO/entrega/evidencias/hito-4/rechazo-sin-permiso.txt
```

**Qué demuestra, y es fino:** son dos rechazos distintos. En el primero el cliente **ni siquiera se conecta** porque no tiene credenciales — eso es autenticación. En el segundo el cliente **entra al clúster sin problema** pero no puede leer el tópico — eso es autorización.

**Si explicas esa diferencia en el expediente, demuestras que entendiste seguridad de verdad y no solo que copiaste configuración.**

### Evidencia 5 · La alta disponibilidad configurada

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic <tu-topico-critico>
```

**Qué mirar:** la línea `Configs` tiene que mostrar `min.insync.replicas`. Y en el expediente explica qué valor de `acks` usarías en el productor y por qué.

### Evidencia 6 · El drill de recuperación

Del capstone: tumba un broker, verifica que no se perdieron mensajes, recupéralo.

```bash
kafka-cli/simulate-failure.sh
kafka-cli/verify-no-loss.sh > ../../PROYECTO/entrega/evidencias/hito-4/sin-perdida.txt
kafka-cli/recover-broker.sh
```

**Qué demuestra:** que tu plan de recuperación no es un documento, es algo que probaste.

### El error típico

Entregar solo lo que funciona. **La seguridad se demuestra con lo que rechaza**, no con lo que permite.

---
---

# Resumen · la evidencia mínima por hito

| Hito | Evidencia mínima que no puede faltar |
|---|---|
| 1 | El diagrama de topología y la justificación del dimensionamiento |
| 2 | El quórum **antes** y **después** de la caída |
| 3 | Los tres tópicos con sus `Configs` distintas, y una comparación de rendimiento |
| 4 | Las ACLs cargadas y **al menos una prueba negativa** |

Si te falta alguna de esas cuatro, el hito no se puede evaluar completo.
