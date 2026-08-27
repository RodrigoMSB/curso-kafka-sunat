# Lab 11 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado.** Este guion está recortado a ese techo
**botando bloques enteros**, no acortando párrafos: lo que quedó, quedó
completo.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 11 OPERATIVO» | 10 min antes |
| Estado correcto | `bin/90-test-lab.sh` → 🔴 **2 verificaciones OK, no 3** | 10 min antes |
| Schema Registry responde | `curl -s http://localhost:8081/subjects` devuelve `[]` | 10 min antes |
| Kafbat UI responde | http://localhost:8090 abre | 5 min antes |

🔴 **Ojo con la segunda fila, que es al revés de lo que uno espera.** El
validador da **2 OK** cuando el lab está listo para dictar, y **3 OK** cuando ya
está usado. Su tercera verificación es «el subject está registrado», y el
subject **no tiene que estar registrado**: registrarlo es el Paso 1 de la clase.

**Si `curl -s http://localhost:8081/subjects` no devuelve `[]`** (porque
ensayaste), 🔴 **no basta con borrar el subject.** Está medido:

| Lo que haces | Qué sale al registrar después |
|---|---|
| `DELETE /subjects/<subject>` (borrado suave) | `version: 2` — el contador **no** se reinicia |
| `DELETE ...?permanent=true` | `version: 1`, pero `id: 3` — el `id` global nunca se reutiliza |
| `bin/start-lab.sh` | `version: 1` **e** `id: 1` |

**Vuelve a levantar el lab.** Es lo único que devuelve la salida que la guía
promete, porque borra los volúmenes y con ellos el tópico `_schemas`, que es
donde vive el contador.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 6 |
| 2 · El contrato y el rechazo | minuto 6 | `cat`, `register` v1, `diff`, `check`, `register` v3 | 7 |
| 3 · No hay puerta trasera | minuto 13 | El productor, dos veces, y la cuenta de mensajes | 4 |
| 4 · El cambio que sí pasa y el cierre | minuto 17 | `diff` v2, `check`, `register`, `versions` | 3 |
| **Total de dictado** | | | **20** |

**El bloque frágil es el 2.** Es el que junta más contenido: el contrato, los
dos números de la salida, la predicción de la sala y la lectura del mensaje de
error. Si algo se estira, es ahí.

🔴 **El margen es cero.** No hay bloque de reserva. Si te pasas, lo que se bota
es el Bloque 4 completo —y entonces hay que decir en voz alta, sin ejecutarlo,
que el cambio con `default` sí entra— porque terminar en el Bloque 3 deja a la
sala con la idea falsa de que con Schema Registry no se pueden agregar campos.

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **7 s** | 🟢 **Medido**, corrida completa del recorrido recortado (los 4 pasos, 12 comandos), 26-ago-2026 | Lo que le toma a la máquina. Es el número que le sirve al alumno que repite el lab en su casa |
| **Espera** | **0 s** | 🟢 Medido. 🔴 **Este lab no tiene ninguna espera.** No hay ronda del broker, ni *poll*, ni compactación asíncrona. Todo es síncrono contra la API del Registry | No hay hueco de reloj que llenar hablando. A diferencia del Lab 05, aquí el tiempo lo pones tú entero |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda.** El techo de 20 minutos aplica a este |

🟡 **La estimación de dictado sigue siendo una estimación.** Sale de repartir
los cuatro bloques por cantidad de contenido, con el Bloque 1 calcado del Lab
05, que ya se dictó. **Nada de esto está cronometrado contra una clase real.**
El primer dictado es el que lo convierte en dato: si te pasas de 20 minutos, eso
es un hallazgo que hay que reportar, con el bloque que se te fue.

La modalidad es **demostrativa**: tú ejecutas en pantalla y explicas mientras.

🔴 **Los seis comandos del Registry son `curl` de cuatro líneas.** Tenlos
copiados en un archivo de texto antes de entrar a clase y pégalos. **No los
escribas a mano delante de la sala**: el escape de comillas del `sed` es fácil
de equivocar y el error que devuelve —`HTTP 400`— no dice qué te faltó.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| El estado inicial (`list-subjects` vacío) como actividad propia | Guía, *Para profundizar A* |
| Producir y consumir Avro con los envoltorios, y los 6 pedidos | Guía, *Para profundizar B* |
| La carga masiva y el seed de clientes | Guía, *Para profundizar C* |
| Los modos FORWARD, FULL y NONE | Guía, *Para profundizar D* |
| La inspección en Kafbat UI | Guía, *Para profundizar G* |

🔴 **Nada de eso se explica a medias.** O va completo, o no va y se manda a leer.

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 6 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «Un martes, un desarrollador del equipo de fulfillment agrega un campo al
> pedido. Necesita guardar el medio de pago. Agregar un campo es la cosa más
> inocente que se le puede hacer a un registro. Lo prueba, funciona, lo sube. El
> productor no falla. El tópico sigue recibiendo. Los tableros siguen dibujando.
>
> El jueves, analytics corre el reproceso del mes para el cierre. Y el proceso
> se cae. No en el primer mensaje: se cae en el mensaje cuarenta mil y algo, que
> es donde el histórico viejo se junta con lo que se escribió desde el martes.
>
> Nadie rompió nada a propósito. El del martes agregó un campo. El de analytics
> no tocó una línea. Y el cierre no salió.
>
> El problema es que entre esos dos equipos no había nada. Un tópico de Kafka
> acepta lo que le pongan: para el broker son bytes, y no los mira. El acuerdo
> existía —los dos equipos lo tenían clarísimo— pero existía en la cabeza de la
> gente y en un correo de hace ocho meses. **Un acuerdo que no está en ninguna
> parte ejecutable no es un contrato: es una costumbre.**»

**Y ahora la segunda mitad, que es la que lo hace caro:**

> «En una base de datos, un INSERT que viola el esquema falla ahí mismo, delante
> del que lo escribió, con su nombre en el log. En Kafka el que escribe se va a
> su casa tranquilo y el que se cae es otro, dos días después.»

### La metáfora, redactada

> «Volvamos al restaurante. Hasta hoy, en este curso, el salón y la cocina se
> entendían porque sí. Nadie había escrito nunca en qué casilla va cada cosa de
> la comanda. Funciona porque el local es chico y todos se conocen.
>
> Ahora imaginen que alguien del salón manda a imprimir un talonario nuevo. Le
> agrega una casilla, «número de tarjeta», y la deja obligatoria. Los mozos
> empiezan a usarlo esa misma tarde. Nadie le avisó a la cocina, porque para el
> salón no cambió nada: la comanda tiene una casilla más y punto.
>
> Y la cocina, que viene con retraso, sigue sacando comandas del pincho del
> turno anterior. Comandas del talonario **viejo**. Y el cocinero, que ya
> aprendió el formato nuevo, llega a la casilla «número de tarjeta» y no está.
> No está en blanco: **no existe**. Y nadie le dijo nunca qué hacer cuando no
> está.
>
> La cocina se detiene. Y no se detuvo por culpa de la comanda que tiene en la
> mano, que está perfecta. Se detuvo por culpa de un talonario que se cambió sin
> preguntar.»

**Cierra el bloque con la regla, escrita en la pizarra si hay:**

> 🍽 «El talonario no se cambia sin preguntarle a la cocina si va a poder seguir
> leyendo lo que ya está escrito.»
>
> «Eso es todo lo que hace Schema Registry. Vamos a verlo decir que no.»

### Errores probables de este bloque

| Qué pasa | Qué hacer |
|---|---|
| Alguien pregunta «¿pero el broker no valida?» | 🔴 **Es la mejor pregunta del lab.** Contesta que no, y que por eso el Bloque 3 existe. No la resuelvas ahora: prométela |
| La sala se va a JSON Schema / Protobuf | «Los tres funcionan. Avro es el estándar del ecosistema Confluent y es el que van a encontrar. La regla de compatibilidad es la misma» |

---

## Bloque 2 · minuto 6 · El contrato y el rechazo — 7 min

**Este es el bloque central.** Aquí está el laboratorio.

### Paso 1 · Escribir el contrato

**Qué decir antes de ejecutar:**

> «Este es el pedido tal como lo conocen hoy los tres equipos. Antes de
> firmarlo, mírenlo.»

```bash
cat infra/schemas/pedido.avsc
```

**Cómo leerlo en voz alta:**

> «Seis campos, cada uno con su tipo. Y quiero que se fijen en algo que **no**
> está: ninguno tiene la palabra `default`. Los seis son obligatorios. Guarden
> eso, porque es la mitad de la explicación de lo que viene.»

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\": \"$(tr -d '\n' < infra/schemas/pedido.avsc | sed 's/"/\\"/g')\"}" \
    http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions
```

**Qué esperar:**

```
{"id":1,"version":1,"guid":"...","schemaType":"AVRO","schema":"..."}
HTTP 200
```

**Cómo leerlo en voz alta:**

> «Dos números, y no son el mismo número. El `version` es la versión dentro de
> este contrato: es el que le importa a la gente. El `id` es el identificador
> global del Registry, único en todo el clúster. Hoy coinciden porque es el
> primer schema del laboratorio; con veinte tópicos no coinciden nunca.
>
> Y el `id` es la pieza que hace que Avro pese tan poco: cada mensaje que se
> escriba desde ahora no lleva el schema adentro. Lleva **ese número**, en
> cuatro bytes.»

### Paso 2 · El cambio que parece inocente

```bash
diff infra/schemas/pedido.avsc infra/schemas/pedido-v3-incompatible.avsc
```

🔴 **LA PREDICCIÓN. Detente aquí. Este es el momento del laboratorio.**

**Qué preguntarle a la sala, con estas palabras:**

> «Un campo nuevo, al final. No renombra nada, no borra nada, no cambia ningún
> tipo. Es el cambio más seguro que existe. **Levanten la mano los que creen que
> va a entrar.**»

**Lo esperable es que la mayoría levante la mano.** Eso es bueno: es el
desarrollador del martes, y son ellos. No lo corrijas todavía.

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\": \"$(tr -d '\n' < infra/schemas/pedido-v3-incompatible.avsc | sed 's/"/\\"/g')\"}" \
    http://localhost:8081/compatibility/subjects/novatech.lab10.pedidos-value/versions/latest
```

```
{"is_compatible":false}
HTTP 200
```

> «Una sola palabra. Y fíjense que este comando **no registró nada**: solo
> preguntó. Este es el comando que va en el *pipeline* de integración continua,
> no en la consola.»

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\": \"$(tr -d '\n' < infra/schemas/pedido-v3-incompatible.avsc | sed 's/"/\\"/g')\"}" \
    http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions \
  | fold -s -w 88
```

**Qué esperar:** una pared de texto doblada a 88 columnas, con
`"error_code":40901` al principio y **`HTTP 409`** en la última línea.

**Cómo leerla en voz alta.** 🔴 **No la resumas. Léela.** Hay cuatro datos
adentro y cada uno vale:

> «`READER_FIELD_MISSING_DEFAULT_VALUE`. Traducido: *al que lee le falta un
> campo y no tiene qué poner en su lugar*. Es el cocinero, exacto.
>
> Y no dice «hay una incompatibilidad»: **nombra al culpable.** `The field
> 'tarjeta_credito' has no default value and is missing in the old schema`. Dos
> condiciones, no una: no tiene default, **y** no está en el schema viejo.
>
> `oldSchemaVersion: 1` — contra qué versión comparó.
>
> Y abajo del todo, **HTTP 409**. Cuatro-cero-nueve es *conflicto*, no *error de
> formato*. El schema está perfectamente bien escrito: choca con algo que ya
> existe.
>
> Y la última, que es la que más importa: `compatibility: BACKWARD`. **Con qué
> regla juzgó.** Esto no es una ley universal. Es una política que alguien
> configuró, y el mismo cambio bajo otro modo tendría otro veredicto.»

**Y el cierre del bloque, que es la lección:**

> «El desarrollador del martes **no habría llegado al jueves**. Su despliegue se
> cae el martes, en su propia pantalla, con el nombre del campo que lo rompió.
> Eso es todo lo que compra Schema Registry: adelantar el error al momento y a
> la persona que lo puede arreglar.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `version: 2` en el Paso 1 | El subject ya existía de un ensayo | No se arregla en vivo. Sigue: los números cambian, la demostración no. Y vuelve a levantar el lab en el descanso |
| `is_compatible: true` en el Paso 2 | El modo del subject no es BACKWARD | `curl -s -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"compatibility":"BACKWARD"}' http://localhost:8081/config/novatech.lab10.pedidos-value` |
| `HTTP 400` al registrar | Se rompió el escape de comillas al copiar el comando | El `sed 's/"/\\"/g'` es el pedazo frágil. Vuelve a pegar el comando completo. **Medido:** sin ese `sed`, el Registry contesta exactamente `HTTP 400` |
| `Connection refused` en :8081 | El Registry tarda más que los brokers | `docker logs schema-registry \| tail -20`. Espera. Suele ser 30-60 s |

---

## Bloque 3 · minuto 13 · No hay puerta trasera — 4 min

**Qué decir para abrir:**

> «Aquí siempre aparece la misma objeción, y es buena: *eso pasó porque usaste
> el comando del Registry. Yo escribo con un productor de Kafka, y el broker no
> sabe nada de contratos.*
>
> Es cierto que el broker no sabe nada. El contrato no lo aplica el broker: lo
> aplica la biblioteca del cliente, antes de que el mensaje salga. Vamos a
> verlo.»

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1 \
  | awk -F: '{s+=$3} END {print s" mensajes"}'
```

```
0 mensajes
```

> «Cero. Que quede en pantalla, porque es el número que vamos a mirar tres
> veces.»

**El productor, con el contrato rechazado.** *(Está en la guía, Paso 3. Es el
comando largo; tenlo copiado y pegado antes de clase, no lo escribas a mano.)*

```
org.apache.kafka.common.errors.SerializationException
```

**Cómo leerlo en voz alta:**

> «**Serialization.** No *Authorization*, no *Broker*, no *Timeout*.
> **Serialization.** El mensaje nunca llegó a la red. Se cayó al convertirlo a
> bytes, dentro del proceso del productor, en la máquina del que escribe.
> Porque convertir a Avro incluye ir a preguntarle al Registry, y el Registry
> dijo que no.»

Vuelve a contar:

```
0 mensajes
```

> «Sigue en cero. No entró un mensaje a medias, ni uno corrupto que haya que
> limpiar después. No entró nada.»

🔴 **Y ahora la mitad que hace que esto sea una demostración y no un susto.**
El mismo comando, cambiando **solo el archivo del contrato**:

```

```

> «Nada. Ni una línea. El `grep` no encontró ninguna excepción que mostrar,
> porque no hubo ninguna.»

```
1 mensajes
```

**Cómo cerrar el bloque:**

> «Mismo productor, mismo broker, mismo tópico, mismo mensaje de seis campos. Lo
> único que cambió es con qué contrato dijo que escribía. Uno pasó y el otro no.
>
> Y eso es lo que prueba que la compuerta es una compuerta. Una que rechaza todo
> no sirve de nada. Hay que verla dejar pasar.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Cuarenta líneas de `INFO` antes del error | Se perdió el `-e SCHEMA_REGISTRY_LOG4J_OPTS=...` al copiar | Vuelve a pegar el comando completo. No lo escribas a mano |
| `Warning: --property is deprecated` | Estás usando `--property` en vez de `--reader-property` | Es solo un aviso, el comando funciona igual. La guía usa `--reader-property` para que no salga |
| El contador no da 0 al empezar | Alguien ya produjo en un ensayo | Los números cambian, la demostración no: lo que importa es que **no suba** tras el rechazo. Dilo así |
| Nada sale y tampoco sube el contador | El productor se quedó esperando entrada | Ctrl+C. Faltó el `-i` del `docker exec` o el `echo '...' \|` de adelante |

---

## Bloque 4 · minuto 17 · El cambio que sí pasa — 3 min

**Qué decir para abrir:**

> «Si termináramos aquí, se llevarían una conclusión falsa y peligrosa: *con
> Schema Registry no se pueden agregar campos*. Se pueden. Hay exactamente una
> condición.»

```bash
diff infra/schemas/pedido.avsc infra/schemas/pedido-v2-compatible.avsc
```

**Cómo leerlo en voz alta:**

> «Otra vez una sola línea. Un campo nuevo, al final. La misma forma de cambio
> que el que rechazó hace tres minutos. Y dos diferencias:
>
> `["null", "string"]` — el campo puede ser texto **o** puede ser nulo.
>
> Y `"default": null` — **la pieza que faltaba.** Le dice al lector nuevo qué
> asumir cuando el dato viejo no trae este campo.»

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\": \"$(tr -d '\n' < infra/schemas/pedido-v2-compatible.avsc | sed 's/"/\\"/g')\"}" \
    http://localhost:8081/compatibility/subjects/novatech.lab10.pedidos-value/versions/latest
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"schema\": \"$(tr -d '\n' < infra/schemas/pedido-v2-compatible.avsc | sed 's/"/\\"/g')\"}" \
    http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions \
  | fold -s -w 88
curl -s http://localhost:8081/subjects/novatech.lab10.pedidos-value/versions
```

```
{"is_compatible":true}
HTTP 200
{"id":2,"version":2,...}
HTTP 200
[1,2]
```

> «Las dos versiones siguen ahí, y tienen que seguir. El mensaje que escribimos
> hace un minuto lleva pegado el `id` 1. Si la v1 desapareciera, ese mensaje
> quedaría ilegible para siempre. **El Registry no es un archivo de
> configuración que se sobrescribe: es un registro histórico**, y por eso vive
> en un tópico de Kafka y no en un archivo.»

### El cierre — las reglas para SUNAT

**Dilas. No las leas de la guía, dilas:**

> 1. «Un tópico sin subject registrado no tiene contrato. No importa cuánta
>    documentación exista.
> 2. Todo campo que se agregue lleva `default`. Es la única diferencia entre el
>    schema que rechazó y el que aceptó.
> 3. `check-compatibility` va en el *pipeline*, no en la consola. Preguntar
>    antes de desplegar cuesta un segundo; descubrirlo el jueves cuesta el
>    cierre del mes.
> 4. El modo de compatibilidad es una decisión, no un valor de fábrica. El
>    propio error decía `BACKWARD`. Alguien lo eligió. En SUNAT ese alguien
>    tiene que tener nombre.
> 5. Las versiones viejas no se borran.»

**Y la pregunta con la que se van:**

> «De los tópicos que su equipo tiene hoy en producción: ¿cuántos tienen subject
> registrado, y quién decidió su modo de compatibilidad?»

---

## Nota · los envoltorios de `schema-cli/` y `python3`

**El recorrido de este guion no depende de `python3`.** Los seis comandos del
Registry son `curl`, y `curl` viene con Git Bash.

Eso es deliberado: los cuatro envoltorios de `schema-cli/` usan `python3` para
escapar el schema y para formatear la salida, y **Git Bash para Windows no trae
Python**. Si en la VM de Netec no está, los cuatro mueren antes de llegar al
`curl` —por el `set -euo pipefail`— y el laboratorio seguiría funcionando igual.

**Aun así, compruébalo antes de la clase**, porque si está, los envoltorios son
más cómodos y la salida se lee mejor:

```bash
python3 --version
schema-cli/list-subjects.sh
```

**Y hay una ganancia pedagógica en el `curl` que conviene decir en voz alta:**

> «Fíjense en que aquí no hay ninguna herramienta de Kafka. Esto es `curl`
> contra una API REST. Schema Registry no es magia: es un servicio HTTP, y todo
> lo que hicimos hoy se puede hacer desde cualquier cosa que sepa hablar HTTP —
> su *pipeline*, su tablero, un script de dos líneas.»

---

**Siguiente:** Lab 12 — *¿se puede hacer un `SELECT` sobre algo que todavía está
llegando?*
