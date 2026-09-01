# Guía de evidencias

Para cada hito: **qué se evalúa, qué evidencia lo demuestra, y con qué comando exacto se obtiene.**

Si sigues esta guía no vas a entregar una captura que no prueba nada, que es el error más común.

---

## Regla general

Una evidencia sirve cuando **muestra un antes y un después**, o cuando **muestra un estado que solo puede existir si hiciste bien el trabajo**.

Una captura del clúster corriendo no prueba casi nada: cualquiera levanta un `docker compose up`. Una captura del quórum eligiendo un líder nuevo después de matar al anterior **sí prueba** que construiste algo resiliente.

---

## Sobre los nombres que ves en los comandos

Los comandos de esta guía están escritos sobre los laboratorios del curso, porque es el clúster que ya tienes armado. Por eso aparecen nombres concretos. **Todos son de ejemplo.**

**Los nombres de tópico son de muestra.** Los tuyos son los que definiste en el hito 1 y anotaste en la tabla 2.4 del expediente. Si copias los del ejemplo, tu expediente va a hablar de unos tópicos y tus evidencias van a mostrar otros. Eso se nota de inmediato.

**Los `cd` apuntan a la carpeta de un laboratorio.** Si desplegaste tu propio clúster en otra carpeta, párate ahí. Y ajusta lo que va después del `>`, porque esa ruta es relativa a donde estés parado.

**Los nombres de archivo de evidencia son una sugerencia.** Puedes usar otros. Lo obligatorio es que el nombre diga qué es y que el expediente lo cite igual.

Cuando veas algo `<entre-ángulos>`, es un valor que pones tú.

Una última cosa sobre los scripts de los laboratorios. Cuando los corres en la terminal te explican el comando de Kafka que hay detrás y cómo se lee la salida. Cuando los corres con `>` para guardar la evidencia, esa explicación no aparece y solo queda lo que devolvió Kafka. **Si quieres entender lo que estás guardando, córrelo primero sin el `>`.**

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

Ejemplo sobre el laboratorio 02, que ya trae el script armado.

```bash
cd Capitulo_2/lab-02-validacion-quorum-resiliencia
bin/check-quorum.sh > ../../PROYECTO/entrega/evidencias/hito-2/quorum-inicial.txt
```

Si desplegaste tu propio clúster, esos dos comandos hacen lo mismo desde cualquier carpeta. Son los que el script corre por dentro.

```bash
docker exec <tu-broker> kafka-metadata-quorum \
    --bootstrap-server <tu-broker>:<tu-puerto> describe --status
docker exec <tu-broker> kafka-metadata-quorum \
    --bootstrap-server <tu-broker>:<tu-puerto> describe --replication
```

**Qué demuestra:** que los tres nodos se reconocen entre sí, que hay un líder electo y que los tres están al día.

**Qué mirar en la salida:** `LeaderId`, `CurrentVoters` con los tres, y el `Lag` en cero.

### Evidencia 2 · El estado antes de la caída

Elige uno de **tus** tópicos, el que más te importe conservar.

```bash
docker exec <tu-broker> kafka-topics \
    --bootstrap-server <tu-broker>:<tu-puerto> \
    --describe --topic <tu-topico> > <ruta-a-tu-entrega>/evidencias/hito-2/topico-antes.txt
```

En los laboratorios del curso el broker se llama `kafka-broker-1` y escucha en el puerto `29092`. En tu propio despliegue son los que hayas configurado tú.

**Qué demuestra:** que el tópico tiene sus réplicas completas. Fíjate en la columna `Isr`.

### Evidencia 3 · La caída

```bash
docker stop <el-broker-que-elegiste>
```

Guarda también qué apagaste y por qué elegiste ese nodo.

### Evidencia 4 · El quórum después de la caída

Ojo con el broker que consultas. Tiene que ser uno que siga en pie, no el que acabas de detener.

```bash
docker exec <otro-broker-vivo> kafka-metadata-quorum \
    --bootstrap-server <otro-broker-vivo>:<su-puerto> \
    describe --status > <ruta-a-tu-entrega>/evidencias/hito-2/quorum-tras-caida.txt
```

**Qué demuestra:** el líder cambió, el `LeaderEpoch` subió, y el clúster sigue operando. **Esta es la evidencia más importante del hito.**

### Evidencia 5 · El tópico con el ISR incompleto

```bash
docker exec <otro-broker-vivo> kafka-topics \
    --bootstrap-server <otro-broker-vivo>:<su-puerto> \
    --describe --topic <tu-topico> > <ruta-a-tu-entrega>/evidencias/hito-2/topico-tras-caida.txt
```

Tiene que ser **el mismo tópico** de la evidencia 2. Si comparas tópicos distintos, la comparación no vale.

**Qué demuestra:** `Replicas` sigue con tres números y `Isr` bajó a dos. **Esa diferencia es la prueba de que el sistema sabe que perdió un nodo y sigue funcionando igual.**

### Evidencia 6 · La recuperación

```bash
docker start <el-broker-que-detuviste>
```

Espera veinte segundos y vuelve a correr el comando de la evidencia 1, guardando la salida como `quorum-recuperado.txt`.

**Qué demuestra:** el nodo se reincorporó solo y volvió a estar al día.

### El error típico

Entregar solo la foto final con todo funcionando. **Sin el antes y el después, no demuestras nada.**

---
---

# Hito 3 · Configuración y rendimiento · 5 puntos

> **Se evalúa:** operación multi-broker, tópicos bien configurados, conectividad resuelta y ajuste con evidencia.

Son cuatro cosas distintas y cada una necesita su evidencia.

### Evidencia 1 · Los tópicos con sus políticas

Aquí van **tus tres tópicos**, los que definiste en el hito 1 y anotaste en la tabla 2.4 del expediente. No los del laboratorio 05.

#### Primero, cómo se le pone la política a un tópico

La política no se configura aparte. Va en el flag `--config` al crear el tópico, y el flag se puede repetir tantas veces como configuraciones quieras fijar.

```bash
docker exec <tu-broker> kafka-topics \
    --bootstrap-server <tu-broker>:<tu-puerto> --create \
    --topic <tu-topico> --partitions 6 --replication-factor 3 \
    --config retention.ms=3600000
```

Estas son las tres políticas que pide el proyecto.

| Lo que necesitas | El flag |
|---|---|
| Retención corta | `--config retention.ms=3600000` (una hora) |
| Retención infinita | `--config retention.ms=-1` (no se borra nunca) |
| Compactado | `--config cleanup.policy=compact` (solo el último valor por clave) |

**Ojo con el `-1`.** Significa «para siempre», no «cero». Un dedo de más en ese signo convierte un tópico efímero en uno que nunca se limpia.

**Si ya creaste el tópico sin el flag, no hace falta borrarlo.** La configuración se cambia en caliente, sin reiniciar nada y sin tocar los mensajes que ya tiene.

```bash
docker exec <tu-broker> kafka-configs \
    --bootstrap-server <tu-broker>:<tu-puerto> --alter \
    --entity-type topics --entity-name <tu-topico> \
    --add-config retention.ms=3600000
```

#### Después, la evidencia

Un `describe` por tópico, uno por política.

```bash
docker exec <tu-broker> kafka-topics --bootstrap-server <tu-broker>:<tu-puerto> \
    --describe --topic <tu-topico-de-retencion-corta> > <ruta-a-tu-entrega>/evidencias/hito-3/topico-retencion-corta.txt
docker exec <tu-broker> kafka-topics --bootstrap-server <tu-broker>:<tu-puerto> \
    --describe --topic <tu-topico-de-retencion-infinita> > <ruta-a-tu-entrega>/evidencias/hito-3/topico-retencion-infinita.txt
docker exec <tu-broker> kafka-topics --bootstrap-server <tu-broker>:<tu-puerto> \
    --describe --topic <tu-topico-compactado> > <ruta-a-tu-entrega>/evidencias/hito-3/topico-compactado.txt
```

**Si estás trabajando dentro del laboratorio 05**, tienes envoltorios que hacen lo mismo y además te explican la salida. `kafka-cli/create-topic.sh <topico> --config K=V` para crear, `kafka-cli/alter-topic-config.sh <topico> --add K=V` para cambiar en caliente, y `kafka-cli/describe-topic.sh <topico>` para la evidencia. Existen solo dentro de la carpeta del lab.

**Qué demuestra:** que configuraste tópicos distintos para necesidades distintas. **Fíjate en la línea `Configs` de cada uno**, que ahí está la diferencia.

### Evidencia 2 · La conectividad resuelta

Ejemplo sobre el laboratorio 04. Con tu propio despliegue, cambia el nombre del contenedor y la ruta de salida.

```bash
cd Capitulo_3/lab-04-multibroker-advertised-listeners
docker exec kafka-broker-1 bash -c 'grep listeners /etc/kafka/kafka.properties' > ../../PROYECTO/entrega/evidencias/hito-3/listeners.txt
```

**Qué demuestra:** que entiendes la diferencia entre las puertas que el broker abre y la dirección que le publica a cada tipo de cliente.

**Vale mucho más si además entregas:** una prueba de conexión que falla con el listener equivocado y otra que funciona con el correcto. Eso demuestra que entendiste el problema, no solo que copiaste la configuración.

### Evidencia 3 · La retención funcionando

Sirve cualquier tópico con retención corta. Puede ser el tuyo o el efímero del laboratorio 05, que se llama `novatech.lab05.efimero`.

```bash
docker exec <tu-broker> kafka-get-offsets \
    --bootstrap-server <tu-broker>:<tu-puerto> \
    --topic <tu-topico-de-retencion-corta>
```

**Corre esto dos veces**, con dos minutos de diferencia, y guarda las dos salidas como `retencion-antes.txt` y `retencion-despues.txt`.

**Qué demuestra:** que la política de retención no es teoría — Kafka borró mensajes solo, porque tú se lo dijiste.

### Evidencia 4 · El ajuste de rendimiento

El laboratorio 07 trae las herramientas de medición listas. También puedes medir contra tu propio clúster.

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

Las evidencias de este hito están escritas sobre el laboratorio 14, que trae los scripts hechos. Si montaste tu propio clúster con seguridad, cambia las rutas y los nombres por los tuyos.

### Evidencia 1 · El material criptográfico existe

```bash
cd Capitulo_5/lab-14-capstone-resiliencia-seguridad
ls -la infra/certs/ > ../../PROYECTO/entrega/evidencias/hito-4/pki-generada.txt
```

Con tu propio despliegue, es un `ls -la` sobre la carpeta donde guardaste los certificados.

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

Con tu propio despliegue, el comando por dentro es `kafka-acls --bootstrap-server <tu-broker>:<tu-puerto> --list --command-config <tu-properties-de-admin>`.

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
docker exec <tu-broker> kafka-topics \
    --bootstrap-server <tu-broker>:<tu-puerto> \
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
