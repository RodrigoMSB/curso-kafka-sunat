# Lab 14 · Capstone: seguridad

## ¿Cómo se demuestra que una puerta está cerrada?

> **Este es el último laboratorio del curso, y el único que se aprueba
> fallando.** Los cinco comandos del recorrido incluyen dos que **tienen que dar
> error**, y si alguno de los dos funcionara, el clúster estaría roto.

**Duración.** Si lo repites tú solo, el recorrido de los 4 pasos tomó **24
segundos medidos**, en 5 comandos. El `bin/start-lab.sh` tarda **19 segundos**
más, y en esos 19 genera la PKI completa, levanta tres brokers con TLS y SASL,
crea los tópicos y escribe las ACLs. En clase toma 20 minutos.
**Antes de empezar:** el clúster tiene que estar arriba (`bin/start-lab.sh`) con
sus 3 brokers escuchando **SASL_SSL** en los puertos 9092, 9093 y 9094.

🔴 **Toda la criptografía de este laboratorio ya está hecha cuando llegas.** No
vas a generar un certificado, ni armar un almacén de claves, ni editar un
*listener*. Eso ocupaba la mitad del recorrido viejo y está en *Para profundizar
A*, porque **no es lo que hay que aprender aquí.**

---

## 1 · EL PROBLEMA

La conversación sobre seguridad en un clúster suele terminar en una demostración
que no demuestra nada.

Alguien conecta un cliente, produce un mensaje, lo consume, y dice: *«listo,
está seguro»*. Y todos asienten, porque funcionó.

**Pero que funcione no prueba nada sobre la seguridad.** Un clúster
completamente abierto también deja producir y consumir. La demostración es
idéntica en los dos casos. **Lo único que distingue a un clúster seguro de uno
abierto es lo que el seguro NO deja hacer**, y eso no se ve haciendo las cosas
que sí funcionan.

Y hay una segunda mitad, que es donde de verdad se pierde la gente. Cuando por
fin alguien hace la prueba negativa, la hace **una sola vez**: intenta conectar
sin credenciales, ve que falla, y da el tema por cerrado.

Eso deja fuera la mitad del problema, y es la mitad cara. Porque una cosa es
**quién eres** y otra muy distinta es **qué puedes tocar**. En SUNAT esa
diferencia tiene nombre y apellido: el sistema de un área tiene credenciales
perfectamente válidas —es un sistema de la casa, tiene que poder entrar— y aun
así **no debe poder leer los datos de otra área**.

Un clúster que confunde esas dos cosas deja entrar a todos los que tienen llave,
y una vez dentro, todos pueden todo.

---

## 2 · LA METÁFORA

Durante todo el curso Kafka es **un restaurante**. Vale la pena repasar el
reparto completo, porque hoy es el último día.

| En el restaurante | En Kafka |
|---|---|
| El mozo que toma y entrega los pedidos | El **broker** |
| Un tipo de comanda (cocina fría, cocina caliente, barra) | El **tópico** |
| Los sectores en que está dividido el salón | Las **particiones** |
| Las libretas de respaldo que copian cada comanda | Las **réplicas** |
| El pincho donde se van clavando las comandas del turno | El **segmento** |
| El equipo que se reparte los sectores del salón | El **grupo de consumidores** |

Las piezas de hoy son dos, y la gracia está en no confundirlas:

| En el restaurante | En Kafka |
|---|---|
| **La puerta de servicio con cerradura**: si no tienes llave, no entras — y desde fuera ni siquiera oyes lo que pasa dentro | La **autenticación** (SASL sobre TLS) |
| **La lista pegada en la cocina** que dice qué puede tocar cada uno de los que ya entraron | La **autorización** (las ACL) |

Y ahora el ejemplo que hay que tener en la cabeza todo el laboratorio:

Hay un proveedor que **tiene llave** de la puerta de servicio. Entra todos los
días, deja la mercadería en el depósito, y se va. Es de la casa: la llave es
suya y está bien que la tenga.

**Y no puede entrar a la caja.** No porque le falte la llave de la puerta —esa la
tiene— sino porque la lista de la cocina no lo nombra para eso.

> 🍽 **Tener llave y tener permiso son dos cosas distintas, y hacen falta las
> dos.**

De ahí sale lo único que hay que ver hoy en pantalla: **al que no tiene llave y
al que tiene llave pero no permiso les pasan cosas distintas**, y se distinguen
mirando el error.

---

## 3 · CÓMO LO RESUELVE

Tres piezas, y las tres ya están montadas.

> 🔐 **TLS**
> Cifra la conversación entre el cliente y el broker, y le permite al cliente
> comprobar que el broker es quien dice ser. Es el sobre cerrado: **sin él, un
> usuario y una contraseña viajarían a la vista de cualquiera.**

> 🎫 **SASL**
> El mecanismo con el que el cliente se presenta. Aquí es `PLAIN`: usuario y
> contraseña. 🔴 **Se llama `PLAIN` y no significa que vaya en claro**: va dentro
> del TLS. El nombre confunde a todo el mundo la primera vez.

> 📜 **ACL** (*Access Control List*)
> Las reglas de qué principal puede hacer qué operación sobre qué recurso. Se
> guardan **en el propio clúster**, no en un archivo de configuración, y se
> consultan en cada petición.

Y los tres personajes del laboratorio, que el `start-lab.sh` ya creó:

| Usuario | Tiene llave | Qué le deja la lista |
|---|---|---|
| `admin` | Sí | **Todo.** Es *super user*: las ACL ni se le miran |
| `app1` | Sí | Leer y escribir en **los dos** tópicos |
| `app2` | Sí | Leer **solo** el tópico público |

🔴 **`app2` es el personaje central de este laboratorio.** Tiene credenciales
válidas y correctas. No es un intruso, no es un atacante, no tiene la contraseña
mal. Es el proveedor con llave. Y es el que va a chocar contra la lista.

---

## 4 · LA AFIRMACIÓN

Todo lo que sigue existe para demostrar una sola frase:

> ▎ **La seguridad se demuestra con lo que rechaza, no con lo que permite.**

Cuatro partes, y las cuatro se ven en pantalla:

- **rechaza a quien no tiene llave** — un cliente sin credenciales ni siquiera
  llega a hablar con el clúster;
- **y también a quien tiene llave y no permiso** — `app2` entra al clúster sin
  problema y aun así no lee el tópico;
- **y esas dos cosas se distinguen mirando el error**, que es lo que hay que
  saber hacer a las tres de la mañana;
- **pero deja pasar lo que corresponde** — la misma `app2`, sobre el otro
  tópico, lee sin problema. Una puerta que no deja pasar a nadie no es una
  puerta: es una pared.

---

## 5 · LOS PASOS

### Paso 1 · Las reglas, escritas

**Se explica.**

Antes de probar nada, hay que leer las reglas. Están en el clúster y se
consultan.

> 👤 **Principal**
> El nombre con el que el clúster conoce a quien se conecta. Aquí son
> `User:app1` y `User:app2`, que salen del usuario con el que se autenticaron.

**Se ejecuta.**

```bash
kafka-cli/list-acls.sh
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/list-acls.sh` | Envoltorio del curso. Por dentro llama a `kafka-acls --list` con las credenciales de `admin`, porque **consultar las reglas también requiere permiso** |

**Qué sale.**

```
Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=novatech.lab12.publico, patternType=LITERAL)`:
	(principal=User:app1, host=*, operation=CREATE, permissionType=ALLOW)
	(principal=User:app2, host=*, operation=READ, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=READ, permissionType=ALLOW)
	(principal=User:app2, host=*, operation=DESCRIBE, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=DESCRIBE, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=WRITE, permissionType=ALLOW)
Current ACLs for resource `ResourcePattern(resourceType=GROUP, name=*, patternType=LITERAL)`:
	(principal=User:app2, host=*, operation=READ, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=READ, permissionType=ALLOW)
Current ACLs for resource `ResourcePattern(resourceType=TOPIC, name=novatech.lab12.confidencial, patternType=LITERAL)`:
	(principal=User:app1, host=*, operation=CREATE, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=READ, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=DESCRIBE, permissionType=ALLOW)
	(principal=User:app1, host=*, operation=WRITE, permissionType=ALLOW)
```

**Cómo se lee.** Cada línea es una regla: **quién**, desde **dónde**, **qué
operación**, y si se permite o se niega.

🔴 **Y ahora la parte importante, que es lo que NO está.** Mira el último bloque,
el de `novatech.lab12.confidencial`, y cuenta los principales:

| Recurso | Aparece `app1` | Aparece `app2` |
|---|---|---|
| `novatech.lab12.publico` | Sí, con 4 operaciones | **Sí**, con READ y DESCRIBE |
| `novatech.lab12.confidencial` | Sí, con 4 operaciones | 🔴 **No aparece. Ni una línea.** |

**Esa ausencia es toda la autorización de este laboratorio.** No hay una regla
que diga «a `app2` se le niega el confidencial». Hay algo más fuerte:
**no hay ninguna regla sobre `app2` en ese tópico, y en Kafka lo que no está
explícitamente permitido está denegado.**

También fíjate en el bloque del medio: `resourceType=GROUP`. Leer un tópico no
basta: **hay que tener permiso sobre el grupo de consumidores también.** Es el
permiso que más se olvida al configurar un cliente nuevo.

---

### Paso 2 · El que no tiene llave

**Se explica.**

Primera prueba negativa. Vamos a pedirle al clúster la cosa más inocente que
existe —la lista de tópicos— **sin presentar ninguna credencial**.

🔴 **Predice antes de ejecutar:** ¿qué va a contestar el clúster? ¿«No
autorizado»? ¿«Usuario o contraseña incorrectos»? ¿Otra cosa?

**Se ejecuta.**

```bash
kafka-cli/attempt-no-auth.sh
```

| Parte del comando | Para qué está |
|---|---|
| `kafka-cli/attempt-no-auth.sh` | Envoltorio del curso. Corre `kafka-topics --bootstrap-server kafka-broker-1:9092 --list` dentro del contenedor `cli-client` |
| **el flag que no está** | 🔴 **Lo que importa de este comando es lo que le falta.** No lleva `--command-config`, así que el cliente se presenta sin usuario, sin contraseña y sin certificado |

**Qué sale.**

```
[...] ERROR org.apache.kafka.common.errors.TimeoutException: The AdminClient thread has exited. Call: listTopics
[...] ERROR Uncaught exception in thread 'kafka-admin-client-thread | adminclient-1':
java.lang.OutOfMemoryError: Java heap space
	at java.base/java.nio.HeapByteBuffer.<init>(Unknown Source)
	at org.apache.kafka.common.memory.MemoryPool$1.tryAllocate(MemoryPool.java:30)
	at org.apache.kafka.common.network.NetworkReceive.readFrom(NetworkReceive.java:103)
```

**Cómo se lee.** 🔴 **Esa salida asusta, y es la respuesta correcta.** Sale igual
en las tres corridas medidas. Vale la pena entenderla porque es la firma exacta
de este error y la vas a reconocer en producción:

| Lo que dice | Qué significa de verdad |
|---|---|
| `OutOfMemoryError: Java heap space` | El cliente habló en claro contra un puerto que solo entiende TLS. Lo que le contestó el broker fue el **saludo de TLS**, que el cliente interpretó como si fuera un mensaje de Kafka. Leyó los primeros bytes como «longitud del mensaje», le salió un número gigantesco, e intentó reservar esa memoria |
| `TimeoutException: The AdminClient thread has exited` | Y como el hilo murió, la petición nunca se contestó |

🔴 **Fíjate en lo que el clúster NO dijo:** no dijo «no autorizado», ni «usuario
incorrecto», ni «el tópico no existe». **No dijo nada.** Desde fuera de la
puerta no se oye nada de lo que pasa dentro: el cliente no sabe si el clúster
existe, qué tópicos tiene, ni siquiera si hay alguien al otro lado.

**Eso es autenticación.** No es que te digan que no: es que no hay conversación.

---

### Paso 3 · El que tiene llave pero no permiso

**Se explica.**

Segunda prueba negativa, y es **la que este laboratorio existe para dejar.**

Ahora `app2` va a intentar leer el tópico confidencial. `app2` **tiene
credenciales válidas**: son las que usa todos los días para su trabajo, y en el
Paso 4 vas a verlas funcionar.

🔴 **Predice antes de ejecutar:** ¿el error va a parecerse al del Paso 2?

**Se ejecuta.**

```bash
kafka-cli/consume-confidencial-app2.sh
```

| Parte del comando | Para qué está |
|---|---|
| `--consumer.config .../app2.properties` | 🔴 **Aquí sí hay credenciales**, y son buenas. El archivo trae `security.protocol=SASL_SSL`, el usuario `app2`, su contraseña y el almacén de confianza |
| `--topic novatech.lab12.confidencial` | El tópico sobre el que `app2` no aparece en ninguna regla |
| `--timeout-ms 5000` | Cuánto espera sin recibir antes de rendirse. Sin esto quedaría colgado |

**Qué sale.**

```
[...] WARN [Consumer clientId=console-consumer, groupId=console-consumer-9154] The metadata response from the cluster reported a recoverable issue with correlation id 2 : {novatech.lab12.confidencial=TOPIC_AUTHORIZATION_FAILED}
[...] ERROR [Consumer clientId=console-consumer, groupId=console-consumer-9154] Topic authorization failed for topics [novatech.lab12.confidencial]
[...] ERROR Error processing message, terminating consumer process:
org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [novatech.lab12.confidencial]
Processed a total of 0 messages
```

**Cómo se lee.** Compara esta salida con la del Paso 2, línea por línea. **No se
parecen en nada, y ahí está la lección entera:**

| | Paso 2 · sin credenciales | Paso 3 · `app2` |
|---|---|---|
| ¿Hubo conversación? | **No.** El cliente murió sin respuesta | **Sí.** El clúster contestó |
| ¿El clúster dijo por qué? | No dijo nada | **Sí:** `TOPIC_AUTHORIZATION_FAILED` |
| ¿Nombró el recurso? | No sabía ni que existía | **Sí:** `[novatech.lab12.confidencial]` |
| Qué error salió | `OutOfMemoryError` | `TopicAuthorizationException` |
| Qué falló | La **autenticación** | La **autorización** |

🔴 **`app2` entró al clúster.** Se autenticó bien, negoció TLS, pidió los
metadatos y el clúster se los negó **por nombre**. Eso solo puede pasar si el
clúster sabe quién es: **para negarle algo a alguien, primero hay que saber
quién es alguien.**

**Y la frase que hay que decir en voz alta, porque es lo que se llevan del
curso:**

> **Autenticar es saber quién eres. Autorizar es saber qué puedes tocar. Son dos
> compuertas distintas, en ese orden, y hacen falta las dos.**

---

### Paso 4 · La misma llave, otra puerta

**Se explica.**

Si el laboratorio terminara en el Paso 3, quedaría una duda razonable: *«¿y cómo
sé que las credenciales de `app2` sirven para algo? A lo mejor están mal.»*

Es una buena objeción, y se contesta con **el mismo comando, cambiando solo el
tópico.**

**Se ejecuta.**

```bash
kafka-cli/consume-publico.sh
```

**Qué sale.**

```
Comprobante publico de la clase
[...] ERROR Error processing message, terminating consumer process:
org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
```

**Cómo se lee.** 🔴 **Y aquí hay una trampa de lectura que hay que atajar: esta
salida también trae la palabra `ERROR`, y sin embargo funcionó.**

Ese `TimeoutException` del final no es un fallo: es el `--timeout-ms 5000`
cumpliéndose porque, después de leer el mensaje, no llegó nada más. **Sale en
los cuatro comandos de este laboratorio, en los que funcionan y en los que no.**

> 🔴 **La regla de lectura de este laboratorio:** no mires la palabra `ERROR`.
> Mira **cuál** es el error, y mira **la última línea**.

| Última línea | Qué pasó |
|---|---|
| `Processed a total of 0 messages` | No leyó nada |
| `Processed a total of 1 messages` | **Leyó** |

Y la comparación que cierra el argumento:

| Comando | Usuario | Tópico | Última línea |
|---|---|---|---|
| Paso 3 | `app2` | confidencial | `Processed a total of 0 messages` |
| Paso 4 | `app2` | **publico** | `Processed a total of 1 messages` |

**Mismas credenciales. Mismo comando. Distinto tópico. Distinto resultado.**
🔴 **Eso prueba que lo que falló en el Paso 3 no era la llave: era el permiso.**

Y para cerrar del todo, el que sí puede leerlo:

```bash
kafka-cli/consume-confidencial-admin.sh
```

```
Comprobante confidencial de la clase
[...] org.apache.kafka.common.errors.TimeoutException
Processed a total of 1 messages
```

**Cómo se lee.** El mismo tópico que le negaron a `app2`, leído sin problema por
`admin`. Y `admin` **no aparece en ninguna ACL**: es *super user*, una llave
maestra configurada en el broker, a la que las reglas ni se le consultan.

🔴 **Ese es el motivo de que en producción el super user deba ser de muy pocas
manos**, y de que nadie deba usarlo para el día a día. Es el único principal del
clúster para el que la lista de la cocina no existe.

---

## 6 · QUÉ QUEDÓ

**Lo que quedó demostrado en pantalla, con su evidencia:**

| Lo que se afirmó | Cómo se vio |
|---|---|
| Las reglas están escritas y se consultan | El `list-acls`, con `app2` ausente del confidencial |
| Sin llave no hay conversación | `OutOfMemoryError` + `TimeoutException`, 3 de 3 corridas |
| Con llave y sin permiso, el clúster dice que no **y dice por qué** | `TOPIC_AUTHORIZATION_FAILED`, nombrando el tópico |
| Y son dos fallos distintos | Dos errores que no se parecen en nada |
| La llave sirve, en la puerta que le toca | `app2` sobre público: `Processed a total of 1 messages` |
| El super user pasa por encima de todo | `admin` sobre confidencial: 1 mensaje |

**Las cinco reglas que se llevan a SUNAT:**

1. 🔴 **Una demostración de seguridad que solo muestra lo que funciona no
   demuestra nada.** Un clúster abierto da exactamente la misma demostración.
   Pide siempre la prueba negativa.

2. 🔴 **Y pide las dos pruebas negativas.** Sin credenciales, y **con
   credenciales válidas sobre algo que no le toca**. La segunda es la que casi
   nunca se hace, y es la que protege los datos entre áreas.

3. 🔴 **Los dos fallos se distinguen mirando el error.** Un cliente que muere sin
   respuesta es autenticación. Un `TopicAuthorizationException` que nombra el
   recurso es autorización — y significa que el cliente **sí entró**.

4. 🔴 **En Kafka, lo que no está explícitamente permitido está denegado.** La
   protección del tópico confidencial no es una regla que niega: es la **ausencia**
   de una regla que permita.

5. 🔴 **El super user no tiene ACL, y por eso es el mayor riesgo del clúster.**
   Debe ser de pocas manos, no debe usarse para operación diaria, y su
   contraseña merece el mismo cuidado que la de un administrador de base de
   datos.

**La pregunta que vale para la sala:** de los sistemas que hoy se conectan a tus
clústeres, ¿cuántos usan credenciales de super user porque «era más fácil», y
qué pasaría si uno de ellos tuviera un error de programación?

---

## 7 · PARA PROFUNDIZAR

Todo lo que sigue estaba en el recorrido de clase y salió por tiempo. Cada
bloque trae su comando completo, pero **no está desarrollado**.

### A · La PKI, que el `start-lab.sh` hizo por ti

Generar la autoridad certificadora, firmar los certificados de los tres brokers,
armar los almacenes de claves y de confianza, y configurar los *listeners*: todo
eso ocupaba la mitad del recorrido viejo y lo hace un script en **19 segundos
medidos**.

```bash
cat bin/generate-certs.sh
cat infra/client-properties/app2.properties
```

**Lo que hay que mirar** en `app2.properties`, que son cinco líneas y explican
todo el Paso 3:

```
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="app2" password="app2-secret";
ssl.truststore.location=/etc/kafka/secrets/kafka.truststore.jks
ssl.truststore.password=changeit
```

🔴 **`sasl.mechanism=PLAIN` no significa que la contraseña viaje en claro.**
Significa que el mecanismo de presentación es usuario y contraseña, y va **dentro
del túnel TLS** que establece `security.protocol=SASL_SSL`. Si dijera
`SASL_PLAINTEXT`, entonces sí iría a la vista.

**La pregunta que vale:** ¿dónde está guardada la contraseña de `app2` en este
laboratorio, y por qué eso no sería aceptable en producción?

### B · Escribir una ACL nueva, y verla surtir efecto

La forma de comprobar que entendiste el Paso 3 es arreglarlo:

```bash
MSYS_NO_PATHCONV=1 docker exec cli-client kafka-acls \
    --bootstrap-server kafka-broker-1:9092 \
    --command-config /etc/kafka/client-properties/admin.properties \
    --add --allow-principal User:app2 \
    --operation READ --operation DESCRIBE \
    --topic novatech.lab12.confidencial

kafka-cli/consume-confidencial-app2.sh
```

**Salida real del `--add`:**

```
Adding ACLs for resource `ResourcePattern(resourceType=TOPIC, name=novatech.lab12.confidencial, patternType=LITERAL)`:
 	(principal=User:app2, host=*, operation=DESCRIBE, permissionType=ALLOW)
	(principal=User:app2, host=*, operation=READ, permissionType=ALLOW)
```

**Y del consumidor, que en el Paso 3 daba cero:**

```
Comprobante confidencial de la clase
Processed a total of 1 messages
```

**Lo que hay que mirar:** el comando que fallaba en el Paso 3 ahora funciona,
**sin reiniciar nada y sin tocar un archivo**. Las ACL viven en el clúster y se
consultan en cada petición.

> ⚠️ **El envoltorio te va a seguir diciendo `[Resultado esperado] error tipo
> 'Not authorized'`.** Es un texto fijo del script, escrito para el caso del
> Paso 3, y ahora está mintiendo. **Mira la última línea**, que es la que cuenta:
> `Processed a total of 1 messages`.

🔴 **Y después bórrala**, o el laboratorio deja de demostrar lo que dice:

```bash
MSYS_NO_PATHCONV=1 docker exec cli-client kafka-acls \
    --bootstrap-server kafka-broker-1:9092 \
    --command-config /etc/kafka/client-properties/admin.properties \
    --remove --allow-principal User:app2 \
    --operation READ --operation DESCRIBE \
    --topic novatech.lab12.confidencial --force
```

**El `--remove` con `--force` no imprime nada**, y eso es lo correcto: el
`--force` es justamente lo que salta la pregunta de confirmación. Compruébalo
volviendo a correr el consumidor, que tiene que dar cero otra vez:

```
org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [novatech.lab12.confidencial]
Processed a total of 0 messages
```

🔴 **Ese ida y vuelta —cero, uno, cero— es lo que convierte esto en una
demostración.** Una compuerta que solo sabe decir que no es una pared; una que
solo sabe decir que sí no es una compuerta.

### C · El drill de failover

La otra mitad del capstone: qué pasa con los datos cuando se cae un broker.

```bash
kafka-cli/describe-confidencial.sh
kafka-cli/produce-confidencial.sh "pedido-pre-fallo-1"
kafka-cli/simulate-failure.sh 3
kafka-cli/describe-confidencial.sh
kafka-cli/produce-confidencial.sh "pedido-durante-fallo-1"
kafka-cli/recover-broker.sh 3
kafka-cli/describe-confidencial.sh
kafka-cli/verify-no-loss.sh
```

**Lo que hay que mirar:** el `describe` antes, durante y después. Con RF 3 y
`min.insync.replicas=2`, el clúster **sigue aceptando escrituras con un broker
caído**, y al volver, el broker se pone al día solo. El `verify-no-loss.sh`
comprueba que no se perdió ningún mensaje.

**La pregunta que vale:** ¿qué pasaría con `min.insync.replicas=3` sobre RF 3
cuando se cae un broker? *(Y compárala con lo que viste en el Lab 05.)*

### D · El capstone automatizado

```bash
bin/run-capstone.sh
```

Corre el laboratorio entero de punta a punta y deja un informe. Es la forma de
comprobar el clúster después de tocarlo.

### E · Los recorridos viejos, completos

Las seis guías originales quedaron en `_fuente-extra/guia/`: TLS y certificados,
SASL, ACL, `min.insync.replicas`, la simulación de fallo y el capstone. Ahí está
todo lo que este recorrido comprimió, con sus actividades y sus preguntas.

### F · El reporte del lab

`plantillas/reporte-entregable.md`, con las respuestas de referencia en
`soluciones/reporte-resuelto.md`.

---

## Cierre

Este es el último laboratorio del curso.

```bash
bin/stop-lab.sh
```

**Lo que te llevas de los catorce**, si hay que resumirlo en una línea: **Kafka
no te avisa.** No te avisa cuando borra por retención, ni cuando un contrato
cambia, ni cuando un consumidor se queda atrás, ni cuando alguien lee lo que no
debía. Todo eso se ve, pero hay que ir a mirarlo — y ahora sabes con qué comando.
