# Lab 13 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado.** Este guion está recortado a ese techo
**botando bloques enteros**, no acortando párrafos: lo que quedó, quedó
completo. De las 26 actividades del recorrido viejo quedan **cuatro pasos**.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 13 OPERATIVO» | 15 min antes |
| Estado correcto | `bin/90-test-lab.sh` → 🔴 **2 verificaciones OK, no 3** | 10 min antes |
| Ningún conector creado | `curl -s http://localhost:8083/connectors` devuelve `[]` | 10 min antes |
| El tópico de la demo **no** existe | `kafka-cli/list-topics.sh` **sin** `novatech.lab09.pedidos` | 10 min antes |
| PostgreSQL con sus 5 filas | `docker exec postgres psql -U novatech -d novatech_orders -c "SELECT count(*) FROM pedidos;"` → `5` | 10 min antes |
| El comando largo, copiado | Ten a mano el `kafka-console-consumer` del Paso 3 en un archivo de texto | 5 min antes |

🔴 **Ojo con la segunda fila, que es al revés de lo que uno espera.** El
validador da **2 OK** cuando el lab está listo para dictar, y **3 OK** cuando ya
está usado. Su tercera verificación es «el conector está creado», y el conector
**no tiene que estar creado**: crearlo es el Paso 2 de la clase.

🔴 **Este lab arranca más lento que los demás.** Kafka Connect instala el plugin
JDBC al arrancar. Deja 15 minutos, no 10.

**Si el conector ya existe** (porque ensayaste), bórralo y vuelve a levantar:

```bash
curl -s -X DELETE http://localhost:8083/connectors/novatech-source-pedidos
bin/start-lab.sh
```

**No basta con borrar el conector.** El tópico `novatech.lab09.pedidos` seguiría
existiendo, y el Paso 1 —«este tópico no existe»— es la mitad de la
demostración. `start-lab.sh` borra los volúmenes y lo deja como debe estar.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 6 |
| 2 · El antes y la instrucción | minuto 6 | `list-topics`, `count(*)`, el JSON, `create-source`, `status` | 6 |
| 3 · El tópico que apareció solo | minuto 12 | `list-topics`, `get-offsets`, los 5 mensajes | 5 |
| 4 · La fila nueva y el cierre | minuto 17 | `insertar-pedido`, `get-offsets`, el mensaje | 3 |
| **Total de dictado** | | | **20** |

**El bloque frágil es el 2.** Es el que junta más contenido: el estado inicial,
el JSON campo por campo, y los dos `state` del `status`. Si algo se estira, es
ahí. 🔴 **Y si hay que recortar dentro del bloque 2, se recorta la tabla del
JSON a cuatro campos** —`table.whitelist`, `mode`, `topic.prefix` y
`poll.interval.ms`— que son los que el resto del laboratorio usa.

🔴 **El margen es cero.** No hay bloque de reserva. Si te pasas, lo que **no**
se puede botar es el Bloque 4: es el único que demuestra que el conector **sigue
mirando**, y sin él la clase se lleva la idea de que Connect hizo una carga
inicial y se acabó.

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **12 s** | 🟢 **Medido**, corrida completa del recorrido, ejecutando los 11 comandos **extraídos de la guía**, 26-ago-2026 | Lo que le toma a la máquina. Es el número que le sirve al alumno que repite el lab en su casa |
| **Espera del conector** | **9 s** de un total de 21 | 🟢 **Medido**, misma corrida: dos tramos. 🔴 **No son estables**: entre corridas fueron de **1 s a 8 s** cada uno | Son las dos pasadas del `poll.interval.ms`. 🔴 **Es tiempo de reloj que hay que llenar hablando**, y el guion lo usa para preguntar. **No prometas un número a la sala**: promete «unos segundos» |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda.** El techo de 20 minutos aplica a este |

🟡 **La estimación de dictado sigue siendo una estimación.** Sale de repartir
los cuatro bloques por cantidad de contenido, con el Bloque 1 calcado del Lab 05,
que ya se dictó. **Nada de esto está cronometrado contra una clase real.** El
primer dictado es el que lo convierte en dato: si te pasas de 20 minutos, eso es
un hallazgo que hay que reportar, con el bloque que se te fue.

La modalidad es **demostrativa**: tú ejecutas en pantalla y explicas mientras.

🔴 **Los comandos de Connect y los dos consumidores son largos.** Tenlos copiados
en un archivo de texto antes de entrar a clase y pégalos. **No los escribas a
mano delante de la sala.**

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| Verificar Connect y listar los plugins (Actividades 1 y 2) | Guía, *Para profundizar A* |
| Los offsets internos del conector (Actividad 7) | Guía, *Para profundizar B* |
| **El Sink completo** — las 8 actividades del camino de vuelta | Guía, *Para profundizar C* |
| El mensaje malformado y el connector caído | Guía, *Para profundizar D* |
| La inserción masiva de 10 pedidos | Guía, *Para profundizar E* |
| El desafío de flujo completo (6 retos) | Guía, *Para profundizar C* y *E* |

🔴 **El Sink es la baja grande y hay que nombrarla en clase, no esconderla.** Se
dice en una frase al cerrar el Bloque 4:

> «Lo que vieron hoy es el camino de ida: de la base a Kafka. El de vuelta —de
> Kafka a otra base— es otro JSON igual de corto y está en la guía, funcionando,
> con sus salidas. Es exactamente el mismo mecanismo al revés.»

🔴 **Nada de eso se explica a medias.** O va completo, o no va y se manda a leer.

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 6 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «El sistema que le importa a SUNAT no es Kafka. Es la base de datos que ya
> estaba. La que lleva veinte años funcionando, la que tiene los datos de
> verdad, la que nadie va a reemplazar este año ni el que viene.
>
> Y el encargo siempre llega igual: *necesitamos que lo que entra ahí también
> llegue a Kafka*.
>
> La respuesta obvia es escribir un programa. Un proceso que se conecte a la
> base, consulte cada tanto qué hay de nuevo, y publique lo que encuentre. Suena
> a un par de días. Y lo es, **la primera versión**.»

**Y ahora la lista, que es lo que convence:**

> «Lo que no suena a un par de días es lo que aparece después. ¿Cómo sabe qué
> filas ya publicó, si el proceso se reinicia? ¿Y si se cae a la mitad de una
> tanda? ¿Y si la base no responde: reintenta, se rinde, avisa? ¿Y si hay que
> correr dos copias para el volumen, cómo se reparten sin duplicar? ¿Quién lo
> monitorea?
>
> Ese programa deja de ser un script y se convierte en un sistema. Y cuando
> mañana el encargo se repita con otra base, o con un archivo, o con una API,
> hay que volver a escribirlo entero.
>
> Y lo más caro: **ese programa hay que mantenerlo.** Tiene dueño, tiene
> despliegue, y tiene un día en que la persona que lo escribió ya no trabaja
> aquí.»

### La metáfora, redactada

> «Volvamos al restaurante. Pero hoy la pieza nueva no es del restaurante: es
> del local que había antes.
>
> En la entrada hay un **libro de reservas**, escrito a mano. Existe desde antes
> que las comandas, y nadie lo va a jubilar. Eso es la base de datos.
>
> Y lo que se contrata no es un programador. Se contrata un **ayudante**, y se
> le da una instrucción escrita en un papel: *mira ese libro cada cinco
> segundos, y toda línea nueva la copias a una comanda*.
>
> El ayudante no piensa. No decide qué copiar, no interpreta, no corrige. Mira
> el libro, ve que hay líneas más abajo de donde tiene el dedo, las copia, y
> mueve el dedo. Y vuelve a mirar a los cinco segundos.»

**Cierra el bloque con la regla:**

> 🍽 «Al ayudante no se le programa. Se le escribe la instrucción y se le
> entrega.»

🔴 **Y planta la limitación ahora, porque el Paso 4 la va a dejar servida:**

> «Guarden una cosa del dedo, que la vamos a necesitar al final: **el dedo solo
> avanza.** Si alguien vuelve atrás y corrige una línea que el ayudante ya
> copió, el ayudante nunca se entera. Su dedo ya pasó por ahí.»

### Errores probables de este bloque

| Qué pasa | Qué hacer |
|---|---|
| «¿Esto no es lo mismo que un *trigger* de la base?» | Buena pregunta. Un *trigger* corre dentro de la base y la carga; esto consulta desde afuera y la base no se entera. Y un *trigger* hay que escribirlo, mantenerlo y versionarlo: volvimos al problema |
| «¿Y si quiero capturar los `UPDATE`?» | 🔴 **No la resuelvas ahora: prométela.** Es la regla 3 del cierre y la respuesta es Debezium |

---

## Bloque 2 · minuto 6 · El antes y la instrucción — 6 min

### Paso 1 · El antes

```bash
kafka-cli/list-topics.sh
```

**Cómo leerlo en voz alta:**

> «Cuatro tópicos. Y quiero que se fijen en algo que **no** está:
> `novatech.lab09.pedidos`. Ese nombre no existe en este clúster. Acuérdense.
>
> Los tres que empiezan con guion bajo son de Connect, y son tópicos de Kafka.
> Connect no tiene base de datos: guarda sus conectores, su avance y su estado
> en el propio clúster. Por eso, si el contenedor se cae y vuelve, retoma donde
> iba.»

```bash
docker exec postgres psql -U novatech -d novatech_orders -c "SELECT count(*) FROM pedidos;"
```

> «Cinco filas en la base. Cero mensajes en Kafka. **Ese es el antes.** Dejemos
> los dos números a la vista.»

### Paso 2 · La instrucción

```bash
cat infra/connect/jdbc-source-pedidos.json
```

🔴 **LA PREDICCIÓN. Detente aquí.**

**Qué preguntarle a la sala, con estas palabras:**

> «Esta es la instrucción entera. Quince líneas de JSON. Léanla un segundo y
> díganme: **en ninguna parte de este archivo dice cómo se va a llamar el
> tópico. ¿De dónde va a salir el nombre?**»

**Deja que lo busquen.** La respuesta es `topic.prefix` + el nombre de la tabla,
y encontrarla es lo que hace que el Paso 3 tenga gracia.

Después recorre los campos. **Si vas apretado de tiempo, solo estos cuatro:**
`table.whitelist`, `mode`, `topic.prefix` y `poll.interval.ms`.

> «Y guarden `poll.interval.ms`: cinco segundos. Es cada cuánto el ayudante
> vuelve a mirar el libro. **Cuando dentro de un rato inserte una fila y no
> aparezca al instante, no está roto**: está en medio de sus cinco segundos.»

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/json" \
    --data @infra/connect/jdbc-source-pedidos.json \
    http://localhost:8083/connectors \
  | fold -s -w 88
```

> «Un `POST` con `curl`. **Esto es todo lo que hay**: Kafka Connect no tiene
> archivo de configuración que editar ni servicio que reiniciar. Es una API REST
> y punto.
>
> Miren la última línea: **HTTP 201, Created.** El conector quedó. Y miren lo que
> devuelve: `tasks` viene **vacío**. Todavía no hay ayudante.»

```bash
curl -s http://localhost:8083/connectors/novatech-source-pedidos/status \
  | tr ',' '\n'
```

**Cómo leerlo en voz alta:**

> «Ahora sí. Y aquí hay algo que se confunde muchísimo en producción: **hay dos
> `state`, y no son el mismo.** Uno dice si la instrucción está aceptada. El
> otro dice si el ayudante está trabajando.
>
> Los dos tienen que decir `RUNNING`. Un conector en `RUNNING` con su task en
> `FAILED` es el caso que más caro sale: se ve verde por encima y no se está
> copiando nada.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `404 No status found` | 🔴 **Medido y normal.** El estado se publica un instante después de aceptar la instrucción | **Vuelve a correr el mismo comando.** En la corrida medida ya respondía al segundo intento. Dilo en voz alta: es la vida real |
| `tasks[0].state: FAILED` | PostgreSQL no responde, o credenciales | El mismo `curl` del `status` trae el `trace`. Mira su `Caused by` |
| El `create` devuelve `409` | El conector ya existe de un ensayo | `curl -s -X DELETE http://localhost:8083/connectors/novatech-source-pedidos` y repite. En el descanso, `bin/start-lab.sh` |

---

## Bloque 3 · minuto 12 · El tópico que apareció solo — 5 min

```bash
kafka-cli/list-topics.sh
```

**Cómo leerlo en voz alta:**

> «Ahí está: `novatech.lab09.pedidos`. **Nadie ejecutó un comando de creación de
> tópicos.** Lo creó el conector, y el nombre salió de donde ustedes lo
> encontraron: el prefijo más el nombre de la tabla.»

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos --time -1
```

```
novatech.lab09.pedidos:0:5
```

> «Y no apareció vacío. Tópico, partición cero, offset **cinco**. Cinco
> mensajes — exactamente las cinco filas que contamos hace tres minutos. El
> ayudante entró, encontró el libro con cinco líneas y el dedo en cero, y las
> copió todas.»

**El comando largo.** *(Tenlo copiado. No lo escribas a mano delante de la
sala.)*

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --from-beginning --max-messages 5
```

**Cómo leerlo en voz alta:**

> «Un JSON por línea, y sus campos son las columnas de la tabla. **Nadie definió
> ese formato**: lo dedujo el conector mirando el esquema de PostgreSQL.»

🔴 **Y ahora anticípate a la pregunta, porque alguien la va a hacer:**

> «`monto` sale como `"ExLQ"`. **No está corrupto.** Esa columna es un
> `NUMERIC(10,2)` de SQL, un decimal exacto, y JSON no tiene decimal exacto:
> solo tiene coma flotante, que redondea. Antes que entregarles un importe
> redondeado, el conector les entrega los bytes originales.
>
> Es incómodo, y es la respuesta correcta. En un sistema tributario, un céntimo
> perdido por redondeo es un problema de verdad.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| El tópico no aparece | No pasaron aún los 5 s del primer `poll` | Espera y repite. Es el reloj del lab, no un fallo |
| El consumidor no termina | Se perdió el `--max-messages` | Ctrl+C. 🔴 Sin ese flag un consumidor **espera para siempre** |
| Offset menor que 5 | El `poll` está a mitad de camino | Repite `get-offsets`. Si se queda corto, mira el `status` del conector |

---

## Bloque 4 · minuto 17 · La fila nueva y el cierre — 3 min

**Qué decir para abrir:**

> «Todo lo anterior se podría explicar como *hizo una carga inicial y se acabó*.
> Esto es lo que demuestra que el ayudante **sigue mirando**.
>
> Voy a escribir un `INSERT` en SQL. En Kafka no voy a tocar nada.»

```bash
kafka-cli/insertar-pedido.sh 2001 "Pedido de la clase" 5 25000.00
```

> «`RETURNING id` devolvió 6. Es la línea nueva del libro, a la que el dedo del
> ayudante todavía no llegó.»

🔴 **Aquí hay 5 segundos de reloj muerto. Llénalos preguntando:**

> «Mientras esperamos: **¿cuánto creen que va a tardar? ¿Y de qué depende?**»

*(La respuesta es `poll.interval.ms`, y quien la diga entendió el laboratorio.)*

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos --time -1
```

```
novatech.lab09.pedidos:0:6
```

**Cómo leerlo en voz alta:**

> «Pasó de cinco a seis. **Ese seis es todo el laboratorio en un número.** Nadie
> ejecutó un productor. Nadie escribió código. Se escribió una fila en una base
> de datos y apareció un mensaje en Kafka.»

*(Medido: entre **1 y 8 segundos** desde el `INSERT`, según la corrida. Depende
de en qué punto de sus cinco segundos estaba el ayudante cuando insertaste. 🔴
**Por eso no anuncies un número antes de ejecutarlo.**)*

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --partition 0 --offset 5 --max-messages 1
```

> «`producto: Pedido de la clase`. **Es el texto que escribí en el `INSERT`**,
> dentro de un mensaje de Kafka, sin haber tocado Kafka.»

### El cierre — las reglas para SUNAT

**Dilas. No las leas de la guía, dilas:**

> 1. «Un conector no es un programa: es un JSON. No tiene despliegue, ni
>    repositorio propio, ni versiones que compilar.
> 2. Hay dos `state` y hay que mirar los dos. Uno verde y el otro rojo es el
>    caso caro.
> 3. **`mode: incrementing` copia altas, no la tabla.** Los `UPDATE` y los
>    `DELETE` son invisibles — es el dedo que solo avanza, del que hablamos al
>    principio. Si el caso los necesita, la respuesta es Debezium, y hay que
>    decirlo **antes** de prometer nada.
> 4. La latencia la ponen ustedes, con `poll.interval.ms`. Bajarlo acerca el
>    dato y carga la base; subirlo la alivia y aleja el dato. No hay valor
>    correcto: hay una decisión.
> 5. Un `NUMERIC` de SQL no cabe en JSON. El base64 no es un error: es el
>    conector negándose a redondearles un importe.»

**Y la frase del Sink, que no se puede olvidar:**

> «Lo que vieron hoy es el camino de ida: de la base a Kafka. El de vuelta —de
> Kafka a otra base— es otro JSON igual de corto, y está en la guía funcionando,
> con sus salidas. Es el mismo mecanismo al revés.»

**Y la pregunta con la que se van:**

> «De las integraciones que su equipo mantiene hoy con código propio: ¿cuántas
> son *leer una tabla y publicar lo nuevo*, y quién las mantiene cuando esa
> persona no está?»

---

## Nota · los envoltorios de `connect-cli/` y `python3`

**El recorrido de este guion no depende de `python3`.** Los comandos de Connect
son `curl`, y `curl` viene con Git Bash. **Medido:** el `POST` con
`--data @archivo` devolvió `HTTP 201` sin Python de por medio.

Eso es deliberado: los cinco envoltorios de `connect-cli/` usan `python3` para
formatear la salida, y **Git Bash para Windows no trae Python**. Si en la VM de
Netec no está, los cinco mueren antes de imprimir —por el `set -euo pipefail`— y
el laboratorio seguiría funcionando igual.

**Aun así, compruébalo antes de la clase**, porque si está, los envoltorios
formatean la salida mucho mejor que el `tr ',' '\n'` del recorrido:

```bash
python3 --version
connect-cli/list-connectors.sh
```

**Y hay una ganancia pedagógica en el `curl` que conviene decir en voz alta:**

> «Fíjense en que aquí no hay ninguna herramienta de Kafka. Esto es `curl`
> contra una API REST. Kafka Connect no se configura de ninguna otra manera: no
> hay un archivo, no hay una consola. Todo lo que hicimos hoy lo puede hacer su
> *pipeline* de despliegue con la misma llamada.»

---

**Siguiente:** Lab 14 — *la seguridad no se demuestra con lo que permite.*
