# Lab 08 · Guion de dictado

> Para el relator. El alumno no lee esto.
>
> **Qué trae:** el reparto de los 20 minutos, qué decir en cada bloque, las
> predicciones que se le piden a la clase y qué hacer si algo sale distinto.

🔴 **El techo es 20 minutos de dictado**, como en los labs 05, 06 y 07. Este
guion cabe en 20 y trae el orden de recorte si te pasas.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba, 3 brokers | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 08 OPERATIVO» | 10 min antes |
| Los 3 brokers sanos | `bin/90-test-lab.sh` en verde | 10 min antes |
| RAM de Docker | 🔴 **8 GB.** En el pico corren cuatro brokers | El día antes |
| 🔴 **Volumen de datos en el tópico** | Ver abajo | 5 min antes |
| El broker 4 **no** está arriba | `kafka-cli/list-brokers.sh` muestra 3 | 5 min antes |

### 🔴 El volumen, que decide si el Paso 3 se ve o no

**Produce datos antes de que entre la clase:**

```bash
kafka-cli/produce-sample.sh novatech.lab08.pedidos 150000
```

Con el tópico como lo deja `start-lab.sh` —5 000 mensajes, ~1 MB— **la
reasignación tarda 3 segundos** y termina antes de que alcances a mostrar nada.
No se ve una sola partición `in progress`, no se ve el throttle puesto, y el
Paso 3 se queda sin laboratorio.

Con ~150 MB en el tópico y el throttle en 8 MB/s la copia toma **22 segundos** y
**se puede narrar mientras ocurre**. Medido.

⚠ **Y no te pases de volumen.** Con ~400 MB y el throttle en 3 MB/s la misma
copia tardó **136 segundos** en la máquina de grabación: se come el bloque. El
reloj lo mandan el volumen y el throttle juntos, no uno de los dos.

🔴 **El tópico tiene que haberse creado con 3 brokers.** Si lo recreas con el
broker 4 ya arriba, Kafka lo reparte entre los cuatro desde el principio, no
queda nada que mover y el Paso 3 se queda sin objeto. `bin/reset-lab.sh` deja
esto bien.

🔴 **Si repetiste el lab antes, asegúrate de que el broker 4 no quedó arriba y de
que el tópico no quedó ya repartido entre los cuatro.** Si quedó, `bin/reset-lab.sh`.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 4 |
| 2 · La foto y el tráfico | minuto 4 | `describe-topic`, y el productor arrancando | 3 |
| 3 · Entra el broker 4, y no pasa nada | minuto 7 | `add-broker`, `list-brokers`, `describe-topic` otra vez | 4 |
| 4 · Reasignar, y las dos cosas que deja | minuto 11 | La reasignación y el análisis. **Aquí está el lab** | 7 |
| 5 · Cierre | minuto 18 | Nada. Se habla | 2 |
| **Total de dictado** | | | **20** |

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo |
|---|---|---|
| **Ejecución pura** | **33 s** | 🟢 **Medido**: 11 s el broker 4, 22 s la reasignación, 23-ago-2026 |
| **Espera** | **~22 s** | 🟢 La copia del Paso 3. **Es la única, y hay que narrarla** |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido. 🔴 Es el que manda |

🔴 **Los 22 segundos de copia son el único hueco del lab, y es un hueco bueno:**
es literalmente la operación que estás enseñando, ocurriendo. No lo llenes con
otra cosa — narra el contador de particiones pendientes bajando.

🟡 **La estimación de dictado es una estimación.** El primer dictado la
convierte en dato.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| **La configuración dinámica de brokers** | Guía, *Para profundizar D* |
| Aplicar el plan de vuelta | Guía, *Para profundizar A* |
| Limpiar throttles a mano | Guía, *Para profundizar B* |
| Drenar el broker 4 y apagarlo | Guía, *Para profundizar C* |
| El ciclo completo con tráfico | Guía, *Para profundizar E* |

🔴 **La configuración dinámica se bota entera y a propósito.** El **Lab 03 ya la
dictó completa** —el drift entre el archivo y lo efectivo, la validación del
doble, los `synonyms`—. Repetirla aquí gasta minutos en algo que la clase ya vio.
Si alguien pregunta, la respuesta es «eso es el Lab 03, y está en la guía».

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 4 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «Viene el Cyber. El equipo decide sumar un cuarto broker al clúster para
> aguantar el pico. Levantan el servidor, lo unen al clúster, confirman que
> aparece en la lista. Se van tranquilos.
>
> Y no pasa nada. El tráfico sigue repartido entre los tres de siempre. El
> servidor nuevo está encendido, sano, costando plata, y **vacío**.
>
> ¿Cuánto tiempo puede estar así? **Para siempre**, si nadie se lo ordena.»

Y la frase que sostiene el laboratorio:

> «Agregar capacidad y **usar** capacidad son dos operaciones distintas. Y la
> segunda mueve gigabytes por la red mientras sus clientes están conectados.»

### La metáfora, ya redactada

> «Seguimos en el restaurante. El mozo es el broker, el tipo de comanda es el
> tópico, los sectores del salón son las particiones.
>
> Hoy **entra un mozo nuevo a mitad de servicio**. Ponerle el uniforme y
> presentarlo es una cosa. Que le toque atender mesas es otra: alguien tiene que
> repartirle sectores, y eso significa que un mozo que ya venía atendiendo la
> mesa 7 **se la pasa al nuevo, con el cliente ahí sentado a mitad del plato**.
>
> Eso se puede hacer sin cerrar el restaurante. Pero hay dos papelitos que nadie
> anota: **quién atendía qué antes de la movida** —por si hay que volver atrás— y
> **la orden de ir despacio** que le diste a la cocina y que después hay que
> levantar.»

🔴 **Deja esa última frase colgando.** Es el Bloque 4 entero.

### 🔮 Predicción para la clase

> «Voy a levantar un cuarto broker y unirlo al clúster, con el tópico ya
> funcionando. Levanten la mano los que creen que va a empezar a recibir mensajes
> solo.»

Van a levantar la mano varios. **Guarda ese número**, porque el Bloque 3 lo
contradice en pantalla.

---

## Bloque 2 · minuto 4 · La foto y el tráfico — 3 min

**En pantalla:**

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

### Qué decir

> «Seis particiones, factor de replicación tres. Eso son **dieciocho réplicas**
> repartidas entre tres servidores.
>
> Miren la columna `Replicas`. ¿Qué números aparecen? Uno, dos y tres. Nada más.
> Esta es la foto de **antes**, y es contra la que vamos a comparar todo.»

Explica las tres columnas —`Replicas`, `Leader`, `Isr`— sin detenerte: la que
importa hoy es `Replicas`.

### Y ahora el tráfico, que no es decorativo

```bash
kafka-cli/produce-sample.sh novatech.lab08.pedidos 300000
```

> «Esto se queda corriendo toda la clase. Y no es adorno: la frase que vamos a
> demostrar es *sin detener nada*. **Si no hay nada corriendo, no hay nada que no
> detener.** Al final vamos a volver a esta terminal a ver qué sintió.»

🔴 **Déjalo en una terminal visible, o en una pestaña que puedas recuperar.** El
Bloque 4 termina ahí.

---

## Bloque 3 · minuto 7 · Entra el broker 4, y no pasa nada — 4 min

```bash
kafka-cli/add-broker.sh
kafka-cli/list-brokers.sh
```

Tarda **11 segundos**. Mientras arranca, recuérdales la predicción.

### Lo que hay que señalar, y son dos cosas

**Una · el quórum no se tocó.**

```
CurrentVoters:     [{"id": 1, ...}, {"id": 2, ...}, {"id": 3, ...}]
CurrentObservers:  [{"id": 4, ...}]
```

> «Fíjense: los *voters* siguen siendo uno, dos y tres. El broker cuatro entró
> como **observer**. Aporta disco y CPU, pero **no vota**.
>
> El quórum de controladores se dimensiona una vez —tres o cinco— y **se deja
> quieto**. Escalar brokers y escalar el quórum son decisiones distintas.
> Mezclarlas es un clásico.»

**Dos · el golpe del bloque.**

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

**No lo comentes. Deja que lo lean.**

> «¿Cuántos cuatros ven en la columna `Replicas`?»

*(Ninguno.)*

> «El servidor está encendido. Está sano. Está unido al clúster. Está en la
> factura. Y **no está haciendo absolutamente nada**.
>
> Los que levantaron la mano hace tres minutos: esto es lo que pasa de verdad.
> **Agregar capacidad no mueve datos.**»

🔴 **Este es el momento más barato de toda la clase y el que más se recuerda.**
No lo apures.

---

## Bloque 4 · minuto 11 · Reasignar, y las dos cosas que deja — 7 min

🔴 **Este bloque es el laboratorio.** Los tres anteriores fueron la excusa para
llegar aquí.

🔴 **Y el objetivo no es que la reasignación funcione.** Va a funcionar. El
objetivo son **las dos cosas que el comando te deja puestas** y que no se ven si
no las buscas.

### Se ejecuta

```bash
kafka-cli/reassign-partitions.sh novatech.lab08.pedidos 1,2,3,4 8000000
```

Antes de que arranque la copia, nombra las tres fases:

> «`--generate` propone y no toca nada. `--execute` copia de verdad. `--verify`
> pregunta cómo va y **limpia**. Están separadas a propósito: entre proponer y
> ejecutar hay un hueco para que un humano lea lo que va a pasar.»

**Mientras corre** —son unos 22 segundos— narra el contador bajando:

```
copiando... 5 de 6 partición(es) pendiente(s)
copiando... 3 de 6 partición(es) pendiente(s)
copiando... 1 de 6 partición(es) pendiente(s)
```

> «Eso que están viendo es la copia. Gigabytes moviéndose entre servidores
> mientras el productor de la otra terminal sigue escribiendo.»

### Lectura uno · el broker 4 ya trabaja

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

> «Ahora sí. El cuatro aparece en cuatro de las seis particiones. Y en la
> partición uno **es el líder**: no está guardando una copia, está atendiendo.»

### Lectura dos · 🔴 el plan de vuelta, que se va con el scroll

**Sube en la terminal** hasta la primera línea del `--execute`.

```
Current partition replica assignment
{"version":1,"partitions":[... "partition":0,"replicas":[3,1,2] ...]}

Save this to use as the --reassignment-json-file option during rollback
```

> «Esto salió hace veinte segundos y nadie lo miró. Es **la foto de cómo estaba
> todo antes**, en el formato exacto que el comando acepta. Kafka se los está
> diciendo con todas las letras: *guárdenlo para el rollback*.
>
> Y es **lo único** que les permite deshacer esta operación.»

Y ahora el escenario, que es lo que lo hace real:

> «¿Por qué querría deshacerla? Porque el plan lo propuso un algoritmo que **no
> sabe nada de ustedes**. No sabe qué particiones son las calientes, no sabe en
> qué rack está cada servidor, no sabe que el broker tres tiene los discos
> viejos. El plan puede dejarles las tres réplicas de la partición más caliente
> en el mismo rack.
>
> Si eso pasa y no guardaron ese JSON, la vuelta atrás es reconstruirlo **a
> mano, partición por partición, desde una foto que ya no existe**.»

En este lab el script lo guarda solo:

```
Plan de VUELTA guardado en /tmp/lab08-rollback-novatech.lab08.pedidos.json
```

> «En el servidor de SUNAT no hay quien se los guarde. Se copia y se pega en un
> archivo **antes** de ejecutar, y en una operación de verdad se manda por correo
> al equipo antes de tocar nada.»

### Lectura tres · 🔴 los frenos que quedan puestos

La otra línea que nadie leyó:

```
Warning: You must run --verify periodically, until the reassignment completes, to ensure the throttle is removed.
The inter-broker throttle limit was set to 8000000 B/s
```

> «Le pusimos un techo de ocho megas por segundo a la copia, para que no se coma
> el ancho de banda de los clientes. Eso está **bien hecho**.
>
> Pero ese techo no es un parámetro del comando que se va cuando el comando
> termina. Son **configuraciones que Kafka escribió en el clúster**, en los cuatro
> brokers y en el tópico. Y se quedan ahí.»

Muéstralo:

```bash
kafka-cli/describe-broker-config.sh 1 | grep throttled
```

> «¿Quién las quita? El `--verify`. Y **solo cuando todas las particiones
> terminaron**.»

🔴 **Y aquí va el golpe del bloque:**

> «Si ustedes corren `--verify` cuando todavía queda una partición copiando, la
> salida dice `still in progress`, **no limpia nada**, y **devuelve éxito**.
> Nadie les avisa.
>
> Un script que corre `--verify` una sola vez y se da por satisfecho deja el
> clúster con un límite de replicación puesto **para siempre**. Seis meses
> después alguien investiga por qué la replicación va lenta y encuentra un
> `throttled.rate` que nadie recuerda haber puesto.»

Y el remate, que es la regla:

> «`--verify` se corre **en bucle** hasta que ninguna diga `in progress`. Y
> después se **comprueba** que los throttles se fueron. No se asume: se
> comprueba.»

⚠ **Si alguien pregunta si Kafka pone los throttles solo:** no. Solo si tú pasas
`--throttle`. Lo que engaña es que el `--verify` imprime `Clearing ... throttles`
**siempre**, haya o no. Está medido en `soluciones/SALIDAS.md`.

### Lectura cuatro · «sin detener nada» no es «sin que nadie lo note»

**Vuelve a la terminal del productor.**

> «¿Se cortó el servicio? Miren.»

```
300000 records sent, ... 36.77 ms avg latency, 4025.00 ms max latency,
6 ms 50th, 10 ms 95th, 1235 ms 99th, 3927 ms 99.9th.
```

> «Trescientos mil de trescientos mil. **Cero pérdidas.** La afirmación del
> laboratorio se cumple.
>
> Pero busquen en el log y van a encontrar esto:»

```
WARN ... Error: NOT_LEADER_OR_FOLLOWER, retrying (2147483646 attempts left)
```

> «**Hubo errores.** Cuando el liderazgo se mueve, el productor le sigue
> escribiendo al broker viejo unos milisegundos y se come un error. Lo que pasa
> es que es un error **retriable** y el cliente lo reintenta solo. Por eso no se
> perdió nada.
>
> *Sin downtime* no significa *sin errores*. Significa **errores que el cliente
> sabe resolver**. Y eso solo es verdad si sus clientes tienen reintentos
> configurados.»

Y el cierre, que engancha con el Lab 07:

> «Ahora miren las latencias. La mitad de los mensajes salieron en seis
> milisegundos. El noventa y cinco por ciento, en diez. No pasó nada.
>
> Y ahora el p99: **mil doscientos treinta y cinco milisegundos.** De diez
> milisegundos a más de un segundo, entre el 95 y el 99. Y el peor mensaje tardó
> **cuatro segundos**.
>
> Es la misma lección de la semana pasada, aplicada a una operación en vez de a
> un benchmark: **el promedio dice que no pasó nada y el percentil dice que sí.**
> Si su tablero muestra promedios, esta operación se ve perfecta.»

### 🔴 Si en tu clase algo sale distinto

| Lo que te salió | Qué decir |
|---|---|
| La reasignación termina al instante | No produjiste volumen antes de clase. Dilo, y muestra la salida de `SALIDAS.md` para la parte del throttle |
| El productor no muestra ningún `NOT_LEADER_OR_FOLLOWER` | Ningún liderazgo se movió en esa corrida. **Es normal.** «Aquí no tocó, pero puede tocar: por eso los reintentos no son opcionales» |
| El p99 sale parecido al p95 | Máquina descargada o poco volumen. Usa el número de `SALIDAS.md` y dilo: «en la corrida grabada el p99 dio 1 235 ms» |
| `--verify` termina en el primer intento | La copia fue muy rápida. El punto del throttle se explica igual: muéstralo con `describe-broker-config.sh` |
| Se acabó la RAM y muere un broker | Cuatro brokers piden 8 GB | **Dilo y sigue con la teoría.** `bin/95-recuperar-lab.sh` te deja un estado usable |

---

## Bloque 5 · minuto 18 · Cierre — 2 min

### Las reglas

Léelas de la guía, sección **6 · QUÉ QUEDÓ**. La que hay que subrayar es la
**cuarta**, porque es la que se olvida:

> «*Sin downtime* se afirma con percentiles, no con promedios. No se perdió un
> mensaje, y el p95 ni se enteró. El p99 pasó de milisegundos a más de un
> segundo. Las dos cosas son verdad, y la segunda es la que el usuario nota.»

### La pregunta con la que se van

> «La próxima vez que alguien diga *agregamos un servidor al clúster*, ¿cuáles
> son las preguntas?»

*(¿Le movieron carga? ¿Guardaron el plan de vuelta? ¿Comprobaron que no quedó
nada encendido?)*

### 🔴 La frase que hay que decir en voz alta

> «Y una cosa, que es la que se llevan de este laboratorio:
>
> **Toda operación en caliente deja dos rastros: una forma de deshacerla, y algo
> encendido que hay que apagar.** Si no saben cuáles son los dos, no terminaron
> la operación — solo dejaron de mirarla.»

El clúster queda arriba para el Lab 08b.

---

## Si el tiempo se acorta

Este guion **es** el recorte, y no hay bloque de reserva. Si aun así te vas de
20 minutos, se bota en este orden y **se reporta**:

1. El Bloque 5 se reduce a la pregunta final y a la frase del cierre.
   Devuelve ~1,5 min.
2. La explicación del quórum en el Bloque 3 se enuncia en una frase —«el 4 entra
   como observer y no vota»— sin desarrollar. Devuelve ~1 min.
3. La lectura cuatro —los percentiles del productor— se enuncia mostrando el
   resumen y diciendo la última frase, sin desarrollar el `NOT_LEADER_OR_FOLLOWER`.
   Devuelve ~1,5 min. **Es lo último que se toca.**

🔴 **Los bloques 2 y 3, y las lecturas dos y tres del Bloque 4, no se recortan.**
El Bloque 3 es el golpe del lab y las lecturas dos y tres son las dos piezas que
esta guía existe para traer.

## Si sobra tiempo

Lo que más rinde es **aplicar el plan de vuelta en vivo** (*Para profundizar A*):
son dos comandos, tarda lo mismo que la ida, y deja clarísimo que deshacer es
otra operación completa y no un botón. La comparación réplica por réplica está
en `soluciones/SALIDAS.md`.

Después de eso, drenar el broker 4 y apagarlo (*Para profundizar C*) cierra el
ciclo y refuerza que el quórum nunca se enteró de nada.
