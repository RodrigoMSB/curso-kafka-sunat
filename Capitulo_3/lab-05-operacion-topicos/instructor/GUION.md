# Lab 05 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado.** Tres sesiones de 180 minutos para once
laboratorios dan 45 minutos por lab, y en esos 45 entra también la demostración
de apertura, las preguntas y el cambio de un lab a otro. Este guion está
recortado a ese techo **botando bloques enteros**, no acortando párrafos: lo que
quedó, quedó completo.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH OPERATIVO» | 10 min antes |
| Los 3 brokers sanos | `bin/90-test-lab.sh` → 4 verificaciones OK | 10 min antes |
| El tópico de la demo **no** existe | `kafka-cli/list-topics.sh` no muestra `novatech.lab05.efimero` | 10 min antes |
| Kafbat UI responde | http://localhost:8090 abre | 5 min antes |

**Si el tópico de la demo ya existe** (porque ensayaste), bórralo antes de
entrar a clase:

```bash
kafka-cli/delete-topic.sh novatech.lab05.efimero
```

🔴 **El tópico tiene que arrancar sin existir.** Si arrancas con un tópico que
ya tiene 60 segundos de antigüedad, el borrado puede ocurrir en el Bloque 2 y te
quedas sin demostración.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 6 |
| 2 · Crear, describir y llenar | minuto 6 | `create-topic`, `describe`, 100 mensajes y la doble tanda | 10 |
| 3 · La espera y el número que cambia | minuto 16 | `kafka-get-offsets --time -2` cada minuto, hasta que el 0 salte | 4 |
| 4 · Cierre y las cinco reglas | — | Nada. Se dicta **dentro** de la espera del Bloque 3 | (4) |
| **Total de dictado** | | | **20** |

**De dónde salen esos dos números que cambiaron.**

- El **Bloque 2 son 10 y no 8** porque absorbió la lectura de la línea
  `Configs`, que antes vivía en el bloque de `novatech.fleet.gps` que se botó.
  🔴 **Es el número más frágil de esta tabla**: es el bloque más largo y el que
  más contenido junta.
- El **Bloque 3 son 4 y no 6** porque su duración no la pone la explicación:
  la pone la ronda del broker, y esa está **medida**. En la última corrida
  fueron 193 s (3,2 min) y el rango medido va de 106 s a 260 s. Si te toca el
  extremo largo, el laboratorio se va a **20,3 minutos**.

El Bloque 4 no suma minutos propios: ocupa el hueco de la espera del Bloque 3,
que es tiempo de reloj que de todas formas hay que llenar. Ese es el único
solapamiento de este guion.

### Los tres relojes

Tres duraciones distintas, y conviene no confundirlas:

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **217 s** | 🟢 **Medido**, corrida completa del recorrido recortado (los 5 pasos), 22-ago-2026 | Lo que le toma a la máquina. Es el número que le sirve al alumno que repite el lab en su casa |
| **Espera del broker** | **193 s** de esos 217 | 🟢 **Medido**, misma corrida. En corridas anteriores fueron **260 s**, **212 s** y **106 s** | No es tiempo muerto: es el hueco donde entran el cierre y las preguntas |
| *(los otros 4 pasos)* | *24 s* | 🟢 Medido | 9 comandos. La máquina no es el cuello de botella |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda.** El techo de 20 minutos aplica a este |

🟡 **La estimación de dictado sigue siendo una estimación.** Sale de tres
cosas: los minutos que cada bloque ya tenía asignados antes del recorte, el
ajuste del Bloque 2 por el contenido que absorbió, y el Bloque 3 puesto en la
espera **medida** del broker. El Bloque 4 no suma porque se dicta dentro de esa
espera. **Nada de esto está cronometrado contra una clase real.** El primer
dictado es el que lo convierte en dato: si te pasas de 20 minutos, eso es un
hallazgo que hay que reportar, con el bloque que se te fue.

🔴 **El margen es cero.** No hay bloque de reserva: si algo se estira, lo que se
bota es el Bloque 1 completo —el problema y la metáfora— y se entra directo al
comando. Es la peor de las salidas posibles, y por eso está escrita aquí y no en
el momento.

La modalidad es **demostrativa**: tú ejecutas en pantalla y explicas mientras.
Por eso el techo no lo pone la máquina —24 segundos de comandos más una espera
que se llena hablando— sino lo que tarda la explicación.

### Lo que se botó de este guion

| Bloque botado | Minutos que devolvió | Dónde quedó |
|---|---|---|
| Describir `novatech.fleet.gps` y la cuenta de los 7 + 7 días | 8 | Guía, *Para profundizar G* |
| El Paso 7 · compactación ejecutada | 4–5 | Se menciona en **una frase** en el Bloque 3. El comando queda en *Para profundizar B* |
| El Paso 8 · `--alter` de configuración en caliente | 5 | Guía, *Para profundizar C* |

🔴 **Nada de eso se explica a medias.** O va completo, o no va y se manda a leer.

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 6 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «Voy a empezar con un caso que no es de Kafka. Es un lunes cualquiera en
> fiscalización. Se abre el tablero y los comprobantes del jueves no están. No
> hay un DELETE en ningún log. Nadie tocó nada. Y el equipo de plataforma dice
> que el clúster estuvo arriba todo el fin de semana, y tiene razón.
>
> La sala se va a pasar la mañana preguntando *quién los borró*. Y esa pregunta
> no se puede contestar, porque está mal hecha. La pregunta era otra: *cuánto
> tiempo dijimos que había que guardarlos*.
>
> Si se llevan una sola cosa de hoy, que sea esta: **Kafka no es una base de
> datos.** En una base de datos, lo que insertaste está hasta que alguien lo
> borre. En Kafka es al revés. Lo que escribiste se va solo. La única razón por
> la que todavía está ahí es que el plazo que ustedes configuraron no venció.»

### La metáfora, ya redactada

> «Seguimos en el restaurante. El mozo es el broker, el tipo de comanda es el
> tópico, los sectores del salón son las particiones, las libretas de respaldo
> son las réplicas, los que marcaron tarjeta son el ISR.
>
> Hoy se suma una pieza: **el espiche.** Ese pincho donde el mozo va clavando
> las comandas del turno. En Kafka se llama **segmento**.
>
> Y lo que importa del espiche es cómo se limpia. Cuando el turno termina, el
> mozo no va sacando comanda por comanda del pincho. Baja el espiche entero,
> pone uno nuevo, y sigue. Y cuando llega la orden de limpiar lo viejo, lo que
> se bota es el espiche completo.
>
> Anoten esa frase: **Kafka no borra mensajes. Bota espiches enteros.** Todo lo
> raro que van a ver hoy sale de ahí.»

### 🔮 Predicción para la clase

> «Antes de tocar nada. Si yo le pongo a un tópico "guarda un minuto" y le
> escribo cien mensajes, ¿en cuánto tiempo desaparecen? Levanten la mano los
> que dicen un minuto.»

Casi toda la sala va a decir un minuto. **Guarda ese número.** Al final del
laboratorio vale la pena volver a él: no fue un minuto, fueron dos, y por dos
razones distintas que ninguno de ellos podía saber.

---

## Bloque 2 · minuto 6 · Crear, describir y llenar — 10 min

**En pantalla:** `create-topic.sh`, `describe-topic.sh`, 100 mensajes, los dos
extremos del offset, y la segunda tanda que cierra el espiche.

### 🔮 Predicción antes de ejecutar

> «Voy a crear un tópico con retención de sesenta segundos y espiche de diez.
> Le voy a escribir cien mensajes. ¿Alguien quiere apostar cuántos van a quedar
> vivos dentro de dos minutos?»

### Se ejecuta

```bash
kafka-cli/create-topic.sh novatech.lab05.efimero \
    --partitions 1 --rf 3 \
    --config retention.ms=60000 --config segment.ms=10000
```

🔴 **Explica el `--partitions 1` o te lo van a preguntar mal después.** No es
por ahorrar. Es porque el productor de consola, cuando los mensajes no llevan
clave, se pega a una sola partición por sesión y en la sesión siguiente elige
otra. Con tres particiones, la segunda ráfaga —la que tiene que cerrar el
espiche— cae en una partición distinta de la primera, el espiche con los datos
nunca rota, y **la demostración no muestra nada**.

Esto está medido: con 3 particiones el borrado tardó 265 s y dejó una partición
intacta. Con 1 partición tardó 128 s y se llevó todo lo vencido.

### Describir, y leer la línea `Configs`

```bash
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -2
```

```
Topic: novatech.lab05.efimero	TopicId: dBn0wnH_SIKGYMgNDgfgwA	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
	Topic: novatech.lab05.efimero	Partition: 0	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr:
```

Lee la primera línea en este orden, señalando en pantalla:

> «`PartitionCount: 1` — un solo pedazo, porque lo pedí así. Ese número es el
> que decide cuántos consumidores pueden trabajar en paralelo, y nos va a
> perseguir todo el Lab 06.
>
> `ReplicationFactor: 3` — de ese pedazo hay tres copias, en tres servidores
> distintos. Aguanto perder uno.
>
> Y ahora la línea que importa hoy: `Configs`. Trae tres valores. ¿Este tópico
> tiene tres configuraciones?»

Deja que contesten. La respuesta correcta es que no:

> «Tiene más de treinta. Aquí solo aparece lo que está **cambiado respecto de
> la fábrica**, y da la casualidad de que yo cambié tres cosas hace diez
> segundos. Todo lo que no aparece está en su valor por defecto, y está ahí,
> decidiendo cosas, sin que nadie lo haya escrito. Esa línea es la trampa: en un
> tópico que nadie tocó se lee casi vacía, y se entiende como *este tópico no
> tiene configuración*. Lo que dice es *este tópico no tiene ningún valor
> distinto del de fábrica*.»

Baja a la segunda línea y define **réplica** e **ISR** ahí mismo:

> «`Replicas: 2,3,1` son las tres libretas de respaldo: en qué brokers vive este
> pedazo. `Isr: 2,3,1` son las que están **al día** en este momento. Mismos tres
> números: ninguna se quedó atrás.»

Si alguien pregunta por `Elr` / `LastKnownElr`: son campos de Kafka 4.x para
escenarios de pérdida severos, **en este lab salen siempre vacíos**, y no vale
la pena gastar tiempo ahí.

### Llenar y contar

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 100
```

Antes de mostrar los offsets, **enseña la cuenta**:

> «En Kafka no hay `SELECT COUNT(*)`. Se pregunta por los dos extremos:
> `--time -1` es hasta dónde escribimos, `--time -2` es desde dónde todavía se
> puede leer. Los mensajes vivos son la resta.»

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -1
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

```
novatech.lab05.efimero:0:100
novatech.lab05.efimero:0:0
```

> «Cien menos cero: cien mensajes vivos. **Anoten ese cero.** Todo el
> laboratorio se juega en que ese cero deje de ser cero. Y va a ser el único
> aviso que tengan.»

### La doble tanda, que es el paso que todo el mundo se salta

> «Ahora viene el paso que se salta el noventa por ciento de la gente que
> intenta esto en su casa, y por saltárselo concluye que la retención de Kafka
> no funciona.
>
> `segment.ms=10000` **no** es un temporizador que cierre el espiche a los diez
> segundos. Significa: *la próxima vez que llegue un mensaje, si el espiche
> tiene más de diez segundos, ciérralo*. Kafka no rota espiches en un tópico
> donde no está pasando nada, y tiene sentido: cerrar cuesta disco, y no se
> gasta disco en un tópico que nadie usa.
>
> O sea: si escribo cien mensajes y me voy a esperar, **no se borra nada
> nunca**. Los cien quedan en el espiche activo y el espiche activo no se bota.
> Necesito escribir algo más.»

Espera ~15 segundos delante de la clase y escribe cinco más:

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 5
```

```bash
MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 \
    ls /var/lib/kafka/data/novatech.lab05.efimero-0
```

```
00000000000000000000.index
00000000000000000000.log
00000000000000000000.timeindex
00000000000000000100.index
00000000000000000100.log
00000000000000000100.snapshot
00000000000000000100.timeindex
leader-epoch-checkpoint
partition.metadata
```

> «Dos archivos `.log`. Ese es el espiche viejo, cerrado, y el nuevo. El nombre
> del archivo es el offset del primer mensaje que tiene adentro: el cero
> arranca en cero, el otro arranca en cien. **Ahí adentro están los cien
> comprobantes, y ese archivo ya tiene el reloj corriendo.**»

🔴 **Menciona `MSYS_NO_PATHCONV=1` en voz alta.** Los alumnos están en Git Bash.
Sin esa variable, Git Bash convierte `/var/lib/...` en una ruta de Windows antes
de que Docker la vea y el comando falla con un error que no se parece en nada a
la causa.

### ⚠ Errores probables en este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| **Solo hay un `.log`** | El espiche no rotó: pasaron menos de 10 s, o la segunda ráfaga no llegó | Esperar 10 s, volver a escribir 5 mensajes, mirar de nuevo. 🔴 **No sigas sin esto** |
| `ls` falla con «no such file or directory» y una ruta con `C:/Program Files/Git` | Falta `MSYS_NO_PATHCONV=1` | Reponerla. Es exactamente el error que la variable evita |
| `Created topic` viene con un `WARNING` sobre puntos y guiones bajos | Kafka avisa que el nombre puede chocar en sus métricas | Ignorarlo, el tópico se creó. Vale la pena decirlo para que nadie crea que falló |
| El tópico ya existía | Ensayo previo sin limpiar | `kafka-cli/delete-topic.sh novatech.lab05.efimero` y rehacer la creación |
| `describe-topic.sh` no devuelve nada y dice que no hay brokers | El clúster no terminó de arrancar | `bin/90-test-lab.sh` y esperar |

---

## Bloque 3 · minuto 16 · La espera y el número que cambia — 4 min

**En pantalla:** el mismo `kafka-get-offsets --time -2`, repetido cada minuto,
hasta que el `0` deje de ser `0`.

🔴 **Este es el bloque que hay que administrar.** El borrado va a ocurrir en
algún momento dentro de los próximos cinco minutos, no antes, y no se puede
apurar. Lo medido de punta a punta, desde crear el tópico hasta ver el número
cambiar, fueron **217 segundos** en la última corrida medida y **242** en otra.

### Qué decir mientras no pasa nada

> «Están las tres condiciones puestas: el espiche está cerrado, sus mensajes
> tienen más de sesenta segundos, y la política es *borrar*. Falta una cuarta
> que no depende de mí: **que el broker se moleste en mirar**.
>
> Hay un parámetro que se llama `log.retention.check.interval.ms` y por defecto
> son cinco minutos. Kafka no borra cuando vence el plazo. Borra en la próxima
> ronda.
>
> Y quiero que se queden con esto, porque es la mitad de lo que vinimos a
> demostrar: **no solo no avisa. Ni siquiera está mirando todo el tiempo.**»

**La compactación, en una sola frase y sin ejecutarla:**

> «Y para que no se lo lleven incompleto: la política que estamos viendo se
> llama `delete`, y existe otra que se llama `compact`, que no mira el reloj —
> mira la clave de cada mensaje y **guarda solo el último valor de cada clave**.
> No la vamos a correr hoy: el compactador trabaja en segundo plano y no pasa en
> los minutos que nos quedan. Está en la guía, en *Para profundizar B*, con el
> comando listo.»

🔴 **Es una frase, y sigues.** Si te enredas explicando compactación, este bloque
se come el cierre y el lab se pasa de 20 minutos.

🔴 **El resto del hueco se llena con el Bloque 4 y con preguntas, no con
silencio.** Es el mejor momento de todo el laboratorio para abrir la sala: la
demostración está armada, el resultado todavía no llegó, y la clase está
esperando un número. Di literalmente **«mientras esperamos, pregunten»**, y si
nadie arranca, tira tú la primera:

> «¿Alguien tiene hoy un tópico en producción y sabe de memoria qué retención
> tiene puesta?»

Consulta el offset **delante de la clase, cada minuto**, sin comentarlo mucho:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

Que salga `:0:0` cuatro veces seguidas **es parte de la demostración**. Entre
consulta y consulta, dicta el Bloque 4.

### Cuando el número cambia

```
novatech.lab05.efimero:0:100
```

Párate ahí. Es el momento del laboratorio:

> «Ese cero ahora es cien. Los cien primeros comprobantes ya no existen.
>
> Nadie ejecutó un comando de borrado. No hay una alerta. No hay una entrada en
> un log de auditoría. No hay una métrica que haya saltado. **El único rastro de
> que se fueron cien mensajes es que un número que valía cero ahora vale cien.**
>
> Y ahora vuelvan a la apuesta del principio: dijeron un minuto. No fue un
> minuto. Fueron dos, por dos razones distintas: el espiche no se cerró hasta
> que escribimos de nuevo, y el broker no miró hasta que le tocó la ronda.»

Y el disco:

```bash
MSYS_NO_PATHCONV=1 docker exec kafka-broker-1 \
    ls /var/lib/kafka/data/novatech.lab05.efimero-0
```

Si aparecen archivos terminados en `.deleted`, es normal y vale la pena
explicarlo: Kafka primero **renombra** el archivo y lo borra de verdad un minuto
después (`file.delete.delay.ms=60000`). Para los consumidores ya no existe desde
el renombrado.

### ⚠ Errores probables en este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| **Pasaron 6 minutos y sigue en `:0:0`** | Casi siempre: no hay un segundo `.log`. El espiche no rotó | Volver a la doble tanda, escribir 5 mensajes, esperar la ronda siguiente |
| El número saltó a `:0:105` en vez de `:0:100` | La ronda llegó tarde y también los 5 mensajes de la segunda ráfaga pasaron los 60 s | **No es un fallo, es mejor**: se fue todo. `latest − earliest = 0`. Es lo que salió en la última corrida medida |
| Un alumno lo vio y otro no | Cada uno tiene su propio clúster y su propia ronda | Normal. Que comparen a qué hora les cambió |
| Alguien pregunta si se puede forzar el borrado | Sí, bajando `log.retention.check.interval.ms`, pero es config **de broker** y exige reinicio | Contestarlo así, y no tocar el compose en clase |

---

## Bloque 4 · Cierre y las cinco reglas — 4 min

🔴 **Este bloque no tiene minuto propio: se dicta dentro de la espera del Bloque
3**, entre una consulta del offset y la siguiente. Si el número cambia a mitad
de camino, córtalo, muestra el cambio, y retómalo después.

### Las cinco reglas

Léelas de la guía, sección **6 · QUÉ QUEDÓ**. La que hay que subrayar en SUNAT
es la **cuarta**:

> «"¿Cuántos días hay que poder reprocesar un comprobante?" no la contesta el
> equipo de plataforma. La contesta quien responde por el proceso. Plataforma
> solo la escribe en un `--config`. Si esa conversación no ocurrió, alguien está
> tomando la decisión igual — la está tomando el valor de fábrica.»

### Cierre

> «Mañana, cuando un tópico pierda datos que alguien esperaba tener, la primera
> línea que van a ir a mirar es `retention.ms`, y la segunda es `segment.ms`. Y
> ya saben con qué comando.»

### 🔴 La frase que hay que decir en voz alta antes de pasar al Lab 06

> «Y una cosa: **este laboratorio tiene más operaciones que las que vimos hoy.
> Están todas en el repositorio, con la clase grabada.** Cambiarle la
> configuración a un tópico en caliente, la compactación de verdad, subir
> particiones, los cuatro perfiles de tópico. Está en la guía, sección *Para
> profundizar*, con el comando escrito y la salida real.»

Sin esa frase, el alumno que abra la guía después va a creer que se saltó algo.

El clúster queda arriba para el Lab 06.

---

## Si el tiempo se acorta

Ya no hay bloque de reserva: este guion **es** el recorte. Y ojo con una
tentación: **recortar el Bloque 4 no devuelve nada**, porque se dicta dentro de
una espera que ocurre igual. Lo único que devuelve minutos es esto, en este
orden, y **se reporta**:

1. En el Bloque 2, **no bajes a la línea de la partición**: `Replicas` e `Isr`
   ya quedaron nombradas al crear el tópico con `--rf 3`. Devuelve ~1 min y no
   deja ninguna idea a medias.
2. El Bloque 1 se bota completo y se entra directo al `create-topic.sh`.
   Devuelve 6 min y es la peor salida posible: el lab pasa a ser un comando.

**El resto del Bloque 2 y el Bloque 3 no se recortan**: son la demostración
entera.

## Si sobra tiempo

Nada de lo botado se improvisa. Se manda a leer, por nombre:

- **Para profundizar C** (cambio en caliente) es el que más rinde: la sorpresa
  no es que aparezca `DYNAMIC_TOPIC_CONFIG` —ya estaba desde que el tópico se
  creó con `--config`— sino que el `--delete` devuelve el valor al del
  **broker**, no a cero. Es el error que se comete en producción.
- **Para profundizar A** (los cuatro perfiles de tópico) es el segundo, porque
  cada perfil es una discusión de negocio.
- **Para profundizar G** (los 7 + 7 días de `novatech.fleet.gps`) es la versión
  aritmética de lo que la doble tanda ya mostró en vivo.
