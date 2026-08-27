# Lab 10 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado.** De las 8 actividades del recorrido
viejo quedan **cuatro pasos**, y el REST Proxy —que ocupaba dos guías enteras—
queda reducido a **un solo comando dentro del Paso 3**, que además sirve para
otra cosa.

🔴 **Este es el único laboratorio del curso que se dicta con el navegador en
pantalla.** Eso cambia dos cosas: hay que tenerlo preparado antes, y hay que
resistir la tentación de pasear por la interfaz. **Cada clic de este guion tiene
al lado el comando que produce el mismo dato.** Si un clic no tiene comando, no
va.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 10 OPERATIVO» | 10 min antes |
| Estado correcto | `bin/90-test-lab.sh` → 4 verificaciones OK | 10 min antes |
| El tópico con sus **3** mensajes | `docker exec kafka-broker-1 kafka-get-offsets --bootstrap-server kafka-broker-1:29092 --topic novatech.lab10.pedidos --time -1` → dos en `:0` y una en `:3` | 10 min antes |
| **El navegador abierto en http://localhost:8090** | Carga el Dashboard con el clúster en verde | 🔴 **5 min antes, y déjalo abierto** |
| Sin grupo `fiscalizacion` | `docker exec kafka-broker-1 kafka-consumer-groups --bootstrap-server kafka-broker-1:29092 --list` no lo muestra | 10 min antes |

🔴 **El puerto es el 8090.** Por dentro el contenedor escucha en el 8080 y el
compose lo publica en el 8090. Si escribes 8080 delante de la sala no hay nadie,
y es un minuto perdido en el peor momento.

🔴 **Los tres mensajes los siembra el propio `start-lab.sh`** por HTTP, con
`rest-cli/rest-produce.sh`. Si ves cero, el arranque no terminó bien.

**Si el grupo `fiscalizacion` ya existe** (porque ensayaste), el Paso 3 no va a
mostrar lag y te quedas sin demostración. Vuelve a levantar el lab:
`bin/start-lab.sh`.

**Prepara también la ventana:** navegador y terminal **lado a lado**, no en
pestañas. Todo el Bloque 3 es comparar una con otra, y alternar con Alt+Tab
mata la comparación.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 5 |
| 2 · Qué hay que mirar, y el tablero | minuto 5 | `--describe`, `get-offsets`, y el recorrido por Kafbat | 7 |
| 3 · El lag, por los dos lados | minuto 12 | El grupo, el POST HTTP, `--describe --group`, y la pantalla de Consumers | 5 |
| 4 · Se cae el tablero | minuto 17 | `docker stop kafbat-ui` y las tres comprobaciones | 3 |
| **Total de dictado** | | | **20** |

**El bloque frágil es el 2**, y por un motivo distinto al de los otros labs:
**es el único donde el ritmo no lo pones tú, lo pone la interfaz.** Cada clic
tarda, cada pantalla invita a explorar, y siempre hay alguien que pregunta por un
botón que no viene al caso.

🔴 **La regla del Bloque 2: no hay un solo clic sin su comando al lado.** Si
alguien pregunta por una pantalla que no está en la tabla, la respuesta es
«existe, está en la guía, hoy no la vemos».

🔴 **El margen es cero.** Si te pasas, lo que se bota es el **recorrido de
Brokers y de Messages** del Bloque 2 —dos filas de la tabla— y se va directo a
Partitions, que es la que se compara con el `--describe`. **Lo que no se puede
botar es el Bloque 4**: es el único que demuestra la mitad incómoda de la
afirmación, y sin él el laboratorio se convierte en publicidad de una interfaz.

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **13 s** | 🟢 **Medido**, los 11 comandos del recorrido extraídos de la guía, contra el clúster real, 26-ago-2026 | Lo que le toma a la máquina. 🔴 **Es el reloj menos útil de este lab**: aquí el tiempo se va en el navegador, y eso no se cronometra en segundos |
| **Espera** | **4 s** | 🟢 **Medido**: lo que tarda `kafbat-ui` en volver a responder tras el `docker start` del Bloque 4 | Es la única espera del lab, y cae al final |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda** |

🟡 **La estimación de dictado sigue siendo una estimación**, y en este lab es la
más floja de las seis, porque el navegador es impredecible. **Nada de esto está
cronometrado contra una clase real.** Si te pasas, repórtalo con el bloque que
se te fue.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| Los endpoints del REST Proxy, uno por uno (2 guías enteras) | Guía, *Para profundizar A* |
| **El ciclo completo de consumo por HTTP** (crear, suscribir, poll, borrar) | Guía, *Para profundizar B* |
| El desafío del socio que solo hace `curl` | Guía, *Para profundizar C* |
| La interoperabilidad HTTP ↔ cliente nativo | Guía, *Para profundizar D* |
| La API del propio Kafbat | Guía, *Para profundizar E* |

🔴 **El consumo por HTTP es la baja grande y hay que nombrarla**, porque su
asimetría con producir es lo más instructivo del recorrido viejo. Una frase al
cerrar el Bloque 3:

> «Producir por HTTP fue un POST y ya está. **Consumir por HTTP es un ciclo de
> cuatro pasos**: crear una instancia, suscribirla, hacer poll dos veces, y
> borrarla. ¿Por qué la diferencia? Porque producir no necesita memoria y
> consumir sí: Kafka tiene que recordar por dónde vas, y HTTP no recuerda nada
> entre llamadas. Está en la guía, completo y funcionando.»

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 5 min

**En pantalla no hay nada.** Ni terminal ni navegador.

### Qué decir

> «Llevan cinco laboratorios leyendo tablas de texto separadas por tabuladores.
> Es lento, es incómodo, y hay algo que no han podido hacer ni una vez: **mirar
> el clúster entero a la vez.**
>
> Cuando alguien pregunta *¿cómo va todo?*, no hay un comando que conteste eso.
> Hay que preguntar tópico por tópico, grupo por grupo, y armar el cuadro en la
> cabeza. Con cuatro tópicos se puede. Con doscientos, no.
>
> Y ahí aparece la solución obvia, y la trampa que trae puesta.»

**La solución y la trampa, seguidas:**

> «La solución obvia es una interfaz web que lo dibuje. Existe, la vamos a usar
> hoy, y es buenísima.
>
> La trampa es que el equipo se acostumbre a que el clúster **es** lo que se ve
> en esa pantalla. Y entonces llega el día en que hay un incidente a las tres de
> la mañana, y alguien entra por SSH a un servidor donde no hay navegador, ni
> túnel, ni la interfaz levantada — y no sabe qué escribir.»

### La metáfora, redactada

> «En el restaurante, esto es **el pizarrón del salón**. El tablero donde el jefe
> de turno ve de un vistazo qué sectores están cubiertos y cuál se está
> atrasando.
>
> Y lo importante del pizarrón: **no atiende mesas.** No cocina, no lleva platos,
> no cobra. Lo único que hace es decirte a qué mesa correr. Un jefe de turno que
> mira el pizarrón y entiende que la mesa 12 lleva veinte minutos esperando es un
> buen jefe de turno. Uno que se queda mirando el pizarrón, no.»

**Cierra el bloque con la regla, y anuncia el final:**

> 🍽 «Si se borra el pizarrón, el restaurante sigue funcionando exactamente
> igual. Lo único que se perdió es su forma cómoda de mirarlo.
>
> **Al final de esta clase voy a apagar el pizarrón delante de ustedes**, para
> que vean que eso es literal.»

### Errores probables de este bloque

| Qué pasa | Qué hacer |
|---|---|
| «¿Entonces la interfaz no sirve?» | 🔴 **Atajarlo de inmediato.** «Sirve, y mucho. El Bloque 3 les va a mostrar una cosa que hace claramente mejor que la consola. Lo que no hay que hacer es confundirla con el clúster» |
| Alguien nombra otras interfaces | Conduktor, AKHQ, Control Center de Confluent. «Todas hacen lo mismo: son clientes que preguntan y dibujan. Lo de hoy aplica igual a todas» |

---

## Bloque 2 · minuto 5 · Qué hay que mirar, y el tablero — 7 min

### Primero la consola, y esto no es opcional

🔴 **Nunca abras el navegador primero.** Si la sala ve la pantalla bonita antes
que los números, el resto del bloque no tiene sentido.

```bash
docker exec kafka-broker-1 kafka-topics \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --topic novatech.lab10.pedidos
```

> «Esta salida ya la saben leer, es la del Lab 05. Hoy la vamos a usar de otra
> manera: **como la respuesta correcta.** Tres particiones, factor de replicación
> tres, y las tres con sus tres réplicas al día. Anótenlo.»

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1
```

🔴 **Detente aquí. Esto es más interesante de lo que parece.**

> «Tres mensajes, y **los tres en la misma partición.** Las otras dos, vacías.
>
> No es un error: se escribieron sin clave, y un productor sin clave se pega a
> una partición durante su tanda. Lo vimos en el Lab 05.
>
> **Y ahora la pregunta:** en un tópico de doscientas particiones, ¿cómo se
> enterarían ustedes de que ciento noventa están vacías, con este comando?»

*(Deja el silencio. La respuesta es «sumando a ojo doscientas líneas», y es la
razón de que el tablero exista.)*

### Ahora sí, el navegador

**Cambia a la ventana del navegador, que ya está abierta en el 8090.**

Recorre **solo** estas cinco cosas, y **di el comando equivalente en cada una**:

| Clic | Qué señalar | Qué decir |
|---|---|---|
| **Dashboard** | El clúster en verde, 3 brokers | «Esto es el `90-test-lab`, dibujado» |
| **Topics** → el tópico | Partitions 3, RF 3 | «Primera línea del `--describe`» |
| Pestaña **Partitions** | Leader y réplicas de cada una | «Las tres líneas `Partition:` del `--describe`» |
| La columna de mensajes | 🔴 **Dos en cero y una con tres** | «Y **ahí está** lo que les preguntaba hace un minuto» |
| Pestaña **Messages** | Los tres pedidos en JSON | «Los mismos que leería un `console-consumer`» |

**Y el cierre del bloque, que es media afirmación:**

> «Los números son los mismos. **No hay un solo dato en esta pantalla que no
> hayan podido sacar de la línea de comandos**, porque el tablero es un cliente
> de Kafka igual que la consola: le pregunta a los brokers y dibuja lo que le
> contestan.
>
> Pero miren la columna de mensajes. Ese desbalance, en la consola, eran tres
> líneas que había que sumar a ojo. Aquí es una barra torcida. **Con tres
> particiones da igual. Con doscientas, es la única forma práctica.**»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| El navegador no carga | Estás en el 8080 | 🔴 **Es el 8090.** Por eso se abre antes de clase |
| El Dashboard aparece vacío | Kafbat arrancó antes que los brokers | Recarga. Si sigue, `docker restart kafbat-ui` y sigue hablando: vuelve en 4 s medidos |
| La sala se dispersa en la interfaz | Es lo esperable | 🔴 «Existe, está en la guía, hoy no la vemos». Sin excepciones, o se va el bloque |
| Los números no coinciden | Alguien produjo antes | Compara igual: lo que importa es que las **dos vistas** digan lo mismo, no cuál sea el número |

---

## Bloque 3 · minuto 12 · El lag, por los dos lados — 5 min

**Qué decir para abrir:**

> «Vamos a fabricar el problema más común de operación de Kafka: un consumidor
> que se quedó atrás.»

```bash
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos \
    --group fiscalizacion --from-beginning --max-messages 3
```

> «Un grupo llamado `fiscalizacion` leyó los tres que había y se fue. Al irse
> dejó su marca: **por dónde iba.**»

Y ahora el REST Proxy, que en este guion es un comando y no un bloque:

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST \
    -H "Content-Type: application/vnd.kafka.json.v2+json" \
    --data '{"records":[{"value":{"pedido":2001}},{"value":{"pedido":2002}},{"value":{"pedido":2003}},{"value":{"pedido":2004}},{"value":{"pedido":2005}}]}' \
    http://localhost:8082/topics/novatech.lab10.pedidos
```

**Los dos minutos de REST Proxy, mientras sale la respuesta:**

> «Esto es el REST Proxy, y es la segunda pieza de hoy. En el restaurante es
> **la ventanilla de la calle**: por donde un repartidor de afuera deja un pedido
> sin entrar al local ni conocer a nadie.
>
> Existe para el sistema que **no puede** tener un cliente de Kafka: un lenguaje
> sin biblioteca decente, un sistema antiguo, o un socio detrás de un cortafuegos
> que solo deja pasar HTTP.
>
> 🔴 **Y la advertencia, que es lo que un administrador tiene que contestar:** es
> un intermediario más. Cada mensaje pasa por él, así que es un punto que se
> satura, que se cae, y que hay que dimensionar y vigilar. **Si el sistema puede
> usar un cliente nativo, debe usarlo.** Esto es para cuando no puede.»

**Y señala la respuesta:**

> «Una entrada por mensaje, con la partición y el offset donde quedó. **Es el
> mismo dato que el broker le contestó al programa Java de ayer**, por HTTP. Y
> fíjense en el `error: null` de cada una: **un POST puede devolver 200 y traer
> errores adentro**, si alguno de la tanda falló. Eso se mira mensaje por
> mensaje, no por el código.»

### El lag, por consola y por pantalla

```bash
docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group fiscalizacion
```

> «`has no active members`: nadie está consumiendo ahora. Y en la fila de la
> partición que tiene datos: iba por el 3, el tópico llegó al 8, **lag cinco.**
> Los cinco que acaban de entrar por HTTP y nadie leyó.»

**Cambia al navegador: Consumers → `fiscalizacion`.**

> «Lo mismo. Estado EMPTY, que es el `has no active members`. Y el detalle por
> partición, igual.
>
> **Pero miren esto:** un solo número grande, **Consumer Lag 5.** La consola no
> me lo dio sumado: me dio tres filas y el cinco había que encontrarlo entre
> ceros.
>
> **Aquí está la parte honesta de este laboratorio: el tablero sí hace algo mejor.
> No sabe nada distinto —los números son los mismos— pero te los suma y te los
> pone en la cara.** Con tres particiones da igual. Con doscientas, es la
> diferencia entre ver el problema y no verlo.»

**Y la frase del consumo por HTTP**, la de arriba, antes de pasar al Bloque 4.

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `LAG 0` en todas las filas | El grupo `fiscalizacion` ya existía y estaba al día | No se arregla en vivo. Usa otro nombre de grupo sobre la marcha y repite los dos comandos |
| El POST devuelve `415` | Se perdió el `Content-Type` largo al copiar | Vuelve a pegar. 🔴 Tenlo copiado antes de clase |
| Kafbat no muestra el grupo | Tarda unos segundos en refrescar | Recarga la pantalla. No es un fallo |

---

## Bloque 4 · minuto 17 · Se cae el tablero — 3 min

🔴 **Este es el bloque por el que existe el laboratorio. No lo botes nunca.**

**Qué decir para abrir, y pedir la predicción:**

> «Les prometí al principio que iba a apagar el pizarrón. Antes de hacerlo,
> **prediganme tres cosas**: con la interfaz apagada, ¿siguen estando los ocho
> mensajes? ¿Sigue el lag en cinco? ¿Sigue funcionando la ventanilla de HTTP?»

*(Deja que contesten. Casi siempre hay alguien que duda del tercero.)*

```bash
docker stop kafbat-ui
```

**Recarga el navegador delante de la sala.** No responde.

```bash
curl -sS --max-time 5 http://localhost:8090/
```

```
curl: (7) Failed to connect to localhost port 8090 after 0 ms: Couldn't connect to server
```

> «*Failed to connect*, no un 404 ni un 500. **No hay nadie escuchando en ese
> puerto.** Esto es lo que ve alguien que dice *Kafka está caído*.»

**Y ahora las tres respuestas, con comandos.** Córrelos seguidos, sin comentar
entre uno y otro; el efecto está en verlos pasar:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab10.pedidos --time -1

docker exec kafka-broker-1 kafka-consumer-groups \
    --bootstrap-server kafka-broker-1:29092 \
    --describe --group fiscalizacion

curl -s -o /dev/null -w "REST Proxy: HTTP %{http_code}\n" http://localhost:8082/topics
```

> «Ocho mensajes. Lag cinco. REST Proxy, doscientos.
>
> **No se movió nada.** El clúster no se enteró de que el tablero se cayó,
> porque el tablero nunca fue parte del clúster: era un cliente que preguntaba y
> dibujaba.»

```bash
docker start kafbat-ui
```

> «Y vuelve. **Medido: cuatro segundos.** Recarguen: está todo igual, porque no
> había nada que recuperar. El tablero no guardaba nada.»

### El cierre — las cinco reglas para SUNAT

**Dilas. No las leas, dilas:**

> 1. «El tablero es un cliente, no el clúster. Si muestra algo raro, la primera
>    pregunta es si el raro es el clúster o es el tablero.
> 2. **Un tablero caído no es un clúster caído**, y confundirlos cuesta una
>    madrugada. Se distinguen con un `kafka-get-offsets` desde cualquier broker.
> 3. Lo que se mira en el tablero se arregla en la consola. A las tres de la
>    mañana solo van a tener la segunda.
> 4. REST Proxy es para el sistema que no puede tener un cliente nativo. Si
>    puede, debe.
> 5. **El lag de un grupo es el número que se pone en una alerta.** Los demás se
>    miran cuando ya hay un problema; este avisa antes.»

**Y la pregunta con la que se van:**

> «Si mañana a las tres de la mañana los llaman por Kafka, y solo tienen un SSH
> a un servidor sin navegador: **¿qué tres comandos escriben primero?**»

---

**Siguiente:** Lab 11 — *¿quién autorizó ese campo nuevo?*
