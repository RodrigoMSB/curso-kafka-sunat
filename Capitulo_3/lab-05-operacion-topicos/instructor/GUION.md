# Lab 05 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

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
ya tiene 60 segundos de antigüedad, el borrado puede ocurrir en el Paso 4 y te
quedas sin demostración.

---

## Presupuesto de tiempo

| Bloque | Minutos | Qué lo hace largo |
|---|---|---|
| 1 · El problema y la metáfora | 6 | Se habla, no se ejecuta |
| 2 · Pasos 1 y 2 · leer un tópico | 8 | La salida es larga y hay que enseñar a recortarla |
| 3 · Pasos 3 a 5 · fabricar y llenar | 8 | Tres comandos cortos |
| 4 · Paso 6 · la espera | **5–7** | 🔴 No depende de ti. Ver abajo |
| 5 · Paso 7 · compactación | 4–5 | Se habla; solo se ejecuta la condición previa |
| 6 · Paso 8 · `--alter` en caliente | 5 | Dos comandos y una comparación |
| 7 · Cierre y las cinco reglas | 4 | Se habla |
| **Total de clase** | **~37** | 🟡 estimado |

### Los tres relojes

Este lab tiene tres duraciones distintas y conviene no confundirlas:

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **256 s** | 🟢 **Medido**, corrida completa de los 8 pasos (`soluciones/SALIDAS.md`) | Lo que le toma a la máquina. Es el número que le sirve al alumno que repite el lab en su casa |
| **Espera del broker** | **212 s** de esos 256 | 🟢 **Medido**, misma corrida. En otra corrida fueron **106 s** | No es tiempo muerto: es el hueco donde se abren preguntas. Ver el bloque 4 |
| *(los otros 7 pasos)* | *44 s* | 🟢 Medido | 11 comandos. La máquina no es el cuello de botella |
| **Dictado** | **~37 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda.** El límite de 40 minutos aplica a este |

🟡 **La estimación de dictado es una estimación.** Sale de suponer que explicar
lleva del orden de tres veces lo que lleva ejecutar, más los bloques que son
solo palabra (1 y 5). **No está cronometrada contra una clase real.** El primer
dictado es el que la convierte en dato: si te pasas de 40 minutos, eso es un
hallazgo que hay que reportar, no un problema del alumno.

🔴 **El margen quedó en 3 minutos estimados sobre un techo de 40.** Es poco. Si
en el primer dictado ves que se va, lo primero que se recorta es el Paso 7: la
compactación se enuncia y se manda a leer, sin ejecutar la condición previa —
eso devuelve unos 4 minutos. **El Paso 8 no se recorta**, y el bloque 6 dice por
qué.

La modalidad es **demostrativa**: tú ejecutas en pantalla y explicas mientras.
Por eso el techo no lo pone la máquina —44 segundos de comandos más una espera
que se llena con preguntas— sino lo que tarda la explicación.

**El bloque 4 es el que hay que administrar.** El broker revisa la retención
cada 5 minutos y no hay forma de apurarlo desde el tópico. Ese hueco **no se
llena con silencio**: es el momento de dar el Paso 7 (compactación) y las cinco
reglas del cierre, volviendo a consultar el offset cada minuto delante de la
clase. Que el número no cambie durante cuatro minutos **es parte de la
demostración**, no un problema técnico.

---

## Bloque 1 · El problema y la metáfora — 6 min

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

## Bloque 2 · Pasos 1 y 2 · leer un tópico — 8 min

### 🔮 Predicción antes de ejecutar

> «Voy a describir un tópico que ya está creado. ¿Cuántas configuraciones creen
> que me va a mostrar?»

### Se ejecuta

```bash
kafka-cli/describe-topic.sh novatech.fleet.gps
```

### Cómo leerlo en voz alta

Lee **solo la primera línea**, en este orden, señalando en pantalla:

> «`PartitionCount: 6` — el tópico está cortado en seis pedazos. Ese número nos
> va a perseguir el Lab 06, porque es el que decide cuántos consumidores pueden
> trabajar en paralelo.
>
> `ReplicationFactor: 3` — de cada pedazo hay tres copias, en tres servidores
> distintos.
>
> Y ahora miren esto: `Configs: min.insync.replicas=2`. **Una sola.** ¿Este
> tópico tiene una sola configuración?»

Deja que contesten. La respuesta correcta es que no:

> «Tiene más de treinta. Aquí solo aparece lo que está **cambiado respecto de
> la fábrica**. Todo lo que no aparece está en su valor por defecto, y está ahí,
> decidiendo cosas, sin que nadie lo haya escrito. Esa línea casi vacía es la
> trampa: se lee como *este tópico no tiene configuración*, y lo que dice es
> *este tópico tiene un solo valor distinto del de fábrica*.»

Después baja a la línea de la partición 0 y define **réplica** e **ISR**. Si
alguien pregunta por `Elr` / `LastKnownElr`: son campos de Kafka 4.x para
escenarios de pérdida severos, **en este lab salen siempre vacíos**, y no vale
la pena gastar tiempo ahí.

### El Paso 2

> «Vamos a buscar el plazo que este tópico tiene puesto. Como no aparecía en la
> línea de resumen, ya sabemos que está en su valor de fábrica. Pero está.»

```bash
kafka-cli/describe-topic.sh novatech.fleet.gps | grep -E "^  (retention.ms|segment.ms|cleanup.policy)="
```

Sale:

```
  cleanup.policy=delete sensitive=false synonyms={DEFAULT_CONFIG:log.cleanup.policy=delete}
  retention.ms=604800000 sensitive=false synonyms={}
  segment.ms=604800000 sensitive=false synonyms={}
```

**El momento del bloque.** Haz la cuenta en voz alta:

> «604 800 000 milisegundos. Dividido mil, son segundos. Dividido sesenta, entre
> sesenta, entre veinticuatro: **siete días**. Perfecto, retención de siete días.
>
> Ahora miren la línea de abajo. `segment.ms`, el espiche, **también siete
> días**. Entonces: el espiche se cierra a los siete días, y el plazo de
> siete días **empieza a contar cuando el espiche se cierra**.
>
> ¿Cuánto puede llegar a vivir un mensaje en un tópico que dice "siete días"?»

Espera. Alguien va a decir catorce.

> «Catorce. Y nadie mintió. Ese tópico dice siete días y cumple lo que dice. Lo
> que pasa es que "siete días" no se cuenta desde donde ustedes creían.»

### ⚠ Errores probables en este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `describe-topic.sh` no devuelve nada y dice que no hay brokers | El clúster no terminó de arrancar | `bin/90-test-lab.sh` y esperar |
| El `grep` no devuelve nada en Git Bash | Comillas cambiadas por el editor / copiado desde el PDF | Que lo escriban a mano; las comillas tienen que ser rectas |
| Alguien pregunta por `synonyms={}` vacío | Ese valor viene de `log.retention.hours` del broker, que no tiene sinónimo directo | Contestar en una frase y seguir; se retoma en *Para profundizar C* |

---

## Bloque 3 · Pasos 3 a 5 · fabricar y llenar — 8 min

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

### Verificación, y el retorno del Paso 1

```bash
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -2
```

```
Topic: novatech.lab05.efimero	TopicId: ...	PartitionCount: 1	ReplicationFactor: 3	Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
```

> «Miren la línea `Configs`. Hace diez minutos traía un valor. Ahora trae tres.
> ¿Por qué? Porque ahora sí hay tres cosas cambiadas respecto de la fábrica. La
> línea no cambió de comportamiento: siempre mostró lo mismo.»

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

### El Paso 5, que es el que todo el mundo se salta

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
| El tópico ya existía | Ensayo previo sin limpiar | `kafka-cli/delete-topic.sh novatech.lab05.efimero` y rehacer el Paso 3 |

---

## Bloque 4 · Paso 6 · la espera — 5 a 7 min

🔴 **Este es el bloque que hay que administrar.** El borrado va a ocurrir en
algún momento dentro de los próximos cinco minutos, no antes, y no se puede
apurar. Lo medido de punta a punta, desde crear el tópico hasta ver el número
cambiar, fueron **128 segundos** en una corrida y algo más en otras.

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

🔴 **Este hueco se llena con preguntas, no con silencio.** Es el mejor momento
de todo el laboratorio para abrir la sala: la demostración está armada, el
resultado todavía no llegó, y la clase está esperando un número. Di literalmente
**«mientras esperamos, pregunten»**, y si nadie arranca, tira tú la primera:

> «¿Alguien tiene hoy un tópico en producción y sabe de memoria qué retención
> tiene puesta?»

Consulta el offset **delante de la clase, cada minuto**, sin comentarlo mucho:

```bash
docker exec kafka-broker-1 kafka-get-offsets \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --time -2
```

Que salga `:0:0` cuatro veces seguidas **es parte de la demostración**. Entre
consulta y consulta, adelanta el Bloque 5 (el Paso 7 y las cinco reglas).

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
| **Pasaron 6 minutos y sigue en `:0:0`** | Casi siempre: no hay un segundo `.log`. El espiche no rotó | Volver al Paso 5, escribir 5 mensajes, esperar la ronda siguiente |
| El número saltó a `:0:105` en vez de `:0:100` | La ronda llegó tarde y también los 5 mensajes de la segunda ráfaga pasaron los 60 s | **No es un fallo, es mejor**: se fue todo. `latest − earliest = 0` |
| Un alumno lo vio y otro no | Cada uno tiene su propio clúster y su propia ronda | Normal. Que comparen a qué hora les cambió |
| Alguien pregunta si se puede forzar el borrado | Sí, bajando `log.retention.check.interval.ms`, pero es config **de broker** y exige reinicio | Contestarlo así, y no tocar el compose en clase |

---

## Bloque 5 · Paso 7 · compactación — 4 a 5 min

Este bloque se dicta **intercalado con la espera del Bloque 4**.

### Compactación, en dos frases y sin fingir que se ve

> «`cleanup.policy` tiene dos valores y hoy usamos uno. `delete` bota el espiche
> cuando vence el plazo: es lo que acaban de ver. El otro es `compact`, y no
> mira el reloj: mira la **clave** de cada mensaje y deja solo el último de cada
> clave, para siempre.
>
> En el restaurante: en vez de botar el espiche, se lo repasa y de cada mesa se
> deja únicamente la última comanda. La cuenta final, no el historial.
>
> La diferencia práctica es qué pregunta contesta cada uno. `delete` contesta
> *¿cuándo pasó?* — sirve para eventos: un comprobante emitido, un pago.
> `compact` contesta *¿cómo está ahora?* — sirve para estados: el saldo actual,
> el último domicilio fiscal declarado.
>
> Y una advertencia: un tópico compactado **no se achica con el tiempo**. Se
> achica cuando repites la clave. Si tienen un millón de claves distintas, se
> quedan con un millón de mensajes para siempre.»

### Lo único que sí se ejecuta: la condición previa

🔴 **No intentes mostrar la compactación en clase. No va a correr.** El
compactador trabaja en segundo plano cada cierto tiempo y no pasa en el minuto y
medio de este bloque. Lo que sí se demuestra —y es lo que importa— es que **los
mensajes llevan clave**, la condición sin la cual nunca compactaría.

```bash
kafka-cli/produce-bulk.sh novatech.lab05.efimero 6 --key-pattern NVT
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab05.efimero --from-beginning --max-messages 6 \
    --timeout-ms 12000 --property print.key=true --property key.separator='|'
```

> «A la izquierda de la barra está la clave, a la derecha el valor. Las claves
> llegaron. Si en vez de `NVT-1` vieran `null`, este tópico **no compactaría
> nunca**, porque no habría por qué agrupar. Y eso es lo que quiero que sepan
> revisar el día que un tópico compactado no se achique: lo primero que se mira
> no es el compactador, es si las claves están puestas.»

**Di en voz alta que el resultado no se ve hoy.** Un alumno que se queda
creyendo que vio compactación va a repetirlo mal.

### ⚠ Errores probables en este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Sale `null` en vez de `NVT-1` | Se te fue el `--key-pattern` | Repetir el produce con el flag |
| `produce-bulk.sh` se cuelga sin decir nada | El tópico no existe (un reset en el medio) | Ctrl+C y recrear. La creación automática está **desactivada** a propósito y el productor reintenta en silencio |
| `Warning: --property is deprecated` | Kafka 8.x avisa del cambio de nombre del flag | Ignorarlo. **El flag funciona** — verificado midiendo las claves que llegan |

---

## Bloque 6 · Paso 8 · `--alter` en caliente — 5 min

🔴 **Este bloque no se recorta.** Es lo único del laboratorio que muestra que un
tópico **se administra después de creado**, y el laboratorio se llama
«Operación de tópicos». Sin esto se enseña a crear y a esperar, no a operar.

### Qué decir

> «Todo lo que hicimos hasta ahora fue crear y esperar. Falta lo que ustedes van
> a hacer todas las semanas: cambiarle la configuración a un tópico que ya está
> en producción, con gente escribiendo y leyendo, sin reiniciar nada.
>
> Y esto ya lo hicieron: en el **Lab 03** cambiamos la configuración de un
> broker en caliente. Aquí es la de un tópico. En Kafka casi todo se cambia en
> caliente, y la pregunta operativa nunca es *¿se puede?* sino ***¿desde cuándo
> aplica?***»

### Se ejecuta

```bash
kafka-cli/alter-topic-config.sh novatech.lab05.efimero --add retention.ms=3600000
kafka-cli/describe-topic.sh novatech.lab05.efimero | head -1
```

Pon las dos líneas `Configs` una encima de la otra:

```
antes    Configs: min.insync.replicas=2,retention.ms=60000,segment.ms=10000
después  Configs: min.insync.replicas=2,retention.ms=3600000,segment.ms=10000
```

> «Cambió un número. No hubo reinicio, no hubo corte, y ni un productor ni un
> consumidor se enteró.
>
> Y la parte que importa para SUNAT: **subir la retención hoy no rescata lo que
> ya se fue.** Los cien comprobantes del Paso 6 no vuelven. Solo cambia el plazo
> de los que todavía están vivos. El día que alguien pida *guardemos más*, esa
> es la primera frase que hay que decirle.»

---

## Bloque 7 · Cierre — 4 min

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

El clúster queda arriba para el Lab 06.

---

## Si el tiempo se acorta

Recorta en este orden. **Los pasos 3 a 6 no se recortan**: son la demostración.

1. El Paso 7 (compactación) → se enuncia en dos frases y se manda a leer.
2. El Paso 1 → describir el tópico sin desglosar cada campo de partición.
3. Las cinco reglas → dejar la 1, la 3 y la 4.

## Si sobra tiempo

**Para profundizar A** (los cuatro perfiles de tópico) es lo que mejor engancha,
porque cada perfil es una discusión de negocio. **C** (cambio en caliente) es el
segundo mejor, pero **léelo antes**: la sorpresa no es que aparezca
`DYNAMIC_TOPIC_CONFIG` —ya estaba desde que el tópico se creó con `--config`—
sino que el `--delete` devuelve el valor al del **broker**, no a cero. Es el
error que se comete en producción.
