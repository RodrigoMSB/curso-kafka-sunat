# Lab 09 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado.** Este guion está recortado a ese techo
**botando bloques enteros**, no acortando párrafos.

🔴 **Y hay una decisión de fondo que conviene tener presente todo el rato: este
laboratorio es de desarrollo y la audiencia es de administración.** No se
escribe código. Se recorre un archivo para que lo reconozcan el día que les
llegue uno. De las 12 actividades del recorrido viejo quedan **cuatro pasos**, y
tres de ellos son leer.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| **Maven instalado** | `mvn -v` responde | 🔴 **El día antes** |
| Dependencias ya descargadas | `cd cliente-java && mvn -q compile` termina sin descargar nada | El día antes |
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 09 OPERATIVO» | 10 min antes |
| Estado correcto | `bin/90-test-lab.sh` → 4 verificaciones OK | 10 min antes |
| El tópico **vacío** | `docker exec kafka-broker-1 kafka-get-offsets --bootstrap-server kafka-broker-1:29092 --topic novatech.lab09.pedidos --time -1` → los tres a `:0` | 10 min antes |

🔴 **La primera fila es la única que puede arruinar la clase, y es la única que
no se arregla en el momento.** Maven es lo único de este laboratorio que no vive
en Docker. **Medido:** con el repositorio local vacío, `mvn compile` descarga
**16 MB en 25 archivos y tarda 4 segundos** con buena red. En una red lenta eso
son minutos, delante de la sala. **Compílalo el día antes**, aunque sea una vez,
y el `.m2` queda caliente.

**Si el tópico ya tiene mensajes** (porque ensayaste), vuelve a levantar el lab:
`bin/start-lab.sh`. El Paso 3 muestra `offset 0` y ese cero es parte de la
demostración.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 6 |
| 2 · Los flags, y dónde quedaron | minuto 6 | El comando del Lab 06, y `ProductorApp.java` | 7 |
| 3 · Correrlo | minuto 13 | `mvn ... ProductorApp` | 3 |
| 4 · Leerlo con la consola, y el matiz del grupo | minuto 16 | `kafka-console-consumer`, y la tabla de las cuatro corridas | 4 |
| **Total de dictado** | | | **20** |

**El bloque frágil es el 2**, que es el corazón: la tabla flag → línea. Si algo
se estira, es ahí. 🔴 **Y si hay que recortar dentro del bloque 2, se recortan
las dos filas de los serializers** —se dicen en una frase— pero **las cuatro
primeras filas van completas**, porque son la afirmación del laboratorio.

🔴 **El margen es cero.** Si te pasas, lo que se bota es la **tabla de las
cuatro corridas** del Bloque 4 —el matiz del `--from-beginning`— y se menciona
en una frase remitiendo a la guía. Es lo único de este guion que se puede leer
después sin perderse nada.

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **8 s** | 🟢 **Medido**, los tres comandos del recorrido contra el clúster real, 26-ago-2026 | Lo que le toma a la máquina |
| **Espera** | **0 s** | 🟢 Medido. Este lab no tiene ninguna espera de broker. 🔴 **Salvo la primera compilación**: 4 s y 16 MB con el repositorio vacío, y eso puede ser minutos en una red mala | No hay hueco de reloj que llenar hablando |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda** |

🟡 **La estimación de dictado sigue siendo una estimación.** **Nada de esto está
cronometrado contra una clase real.** Si te pasas de 20 minutos, es un hallazgo
que hay que reportar, con el bloque que se te fue.

La modalidad es **demostrativa**: tú ejecutas en pantalla y explicas mientras.

🔴 **Ten el archivo `ProductorApp.java` abierto en el editor, con letra grande,
antes de empezar.** El Bloque 2 es leer código en proyector y el `cat` en una
terminal de 80 columnas no se lee.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| Compilar como actividad propia | Se hace dentro del Paso 3, en el mismo comando |
| El consumidor Java, y correr tres instancias | Guía, *Para profundizar A* y *D* |
| Los serializers y romper el contrato | Guía, *Para profundizar B* |
| **Toda la variante Spring y el endpoint REST** | Guía, *Para profundizar C* |
| El desafío de interoperabilidad | Guía, *Para profundizar E* |

🔴 **Spring es la baja grande y hay que nombrarla, no esconderla.** Una frase al
cerrar el Bloque 4:

> «Existe una versión de esto con Spring, que es como lo van a escribir de
> verdad los desarrolladores. Cambia la forma, no el fondo: las mismas
> propiedades, en un archivo `.yml` en vez de en el `.java`. **Y para ustedes eso
> es lo único que importa: cuando el programa es Spring, el archivo que hay que
> pedir es el `application.yml`.** Está en la guía, funcionando.»

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 6 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «Un martes les llega un correo de desarrollo: *el servicio de comprobantes no
> está publicando en Kafka, ¿pueden revisar el clúster?*
>
> Revisan el clúster. Los tres brokers arriba. El tópico existe, con sus
> particiones y sus réplicas al día. No hay nada que revisar: **el clúster está
> perfecto.**
>
> Y aquí la conversación se puede ir por dos caminos.
>
> El primero: contestan *por aquí está todo bien* y devuelven el correo. Dos días
> después el problema sigue, con más gente copiada, y nadie ha mirado el único
> lugar donde puede estar.
>
> El segundo: piden el archivo. Lo abren. Son cincuenta líneas y **cuarenta y
> cinco no les importan.** Las que importan son cuatro, y las reconocen porque
> son exactamente las mismas cosas que ustedes escribieron con guiones en el Lab
> 06. Encuentran que el `bootstrap.servers` apunta a un puerto que desde la
> máquina del desarrollador no existe, y contestan eso.
>
> **La diferencia entre los dos caminos no es saber Java.** Es haber visto una
> vez que un cliente de Kafka no tiene nada nuevo adentro.»

**Y la segunda mitad, que es la que lo hace importante:**

> «Y hay algo peor: **el broker no puede ayudarlos a distinguir.** Para él, un
> cliente Java y una consola son el mismo cliente. No hay un log que diga *este
> mensaje vino de una aplicación*. Si el mensaje no llegó, el broker no tiene
> nada que contarles.»

### La metáfora, redactada

> «Volvamos al restaurante. Y hoy, por primera vez en el curso, **no se suma
> ninguna pieza nueva.** Eso es justamente la lección.
>
> Hasta ahora, cuando querían meter una comanda, la escribían ustedes, a mano,
> en el talonario. Eso era `kafka-console-producer`.
>
> Un cliente Java es **la misma comanda, escrita por una caja registradora** en
> vez de por una mano. La caja tiene que saber lo mismo que sabía la mano: a qué
> mozo entregarla, de qué tipo es, y si lleva número de mesa. Ni más ni menos.
>
> Y lo importante: **el mozo no sabe si la comanda la escribió una mano o una
> máquina, y no tiene forma de saberlo.** Le llega, la clava en el espiche, y
> sigue.»

### Errores probables de este bloque

| Qué pasa | Qué hacer |
|---|---|
| «¿Vamos a programar?» | 🔴 **Aclararlo de entrada, en el minuto uno.** «No. Hoy no se escribe una línea. Vamos a leer un archivo, porque algún día les va a llegar uno» |
| Alguien pregunta por otros lenguajes | «Hay clientes de Kafka en Python, Go, C#, Node. **Los cinco tienen exactamente estas mismas propiedades, con el mismo nombre.** Lo que aprenden hoy sirve para todos» |

---

## Bloque 2 · minuto 6 · Los flags, y dónde quedaron — 7 min

**Este es el bloque central.** Aquí está el laboratorio.

### Primero, el comando del Lab 06

Muéstralo en pantalla. **No lo ejecutes**, es de otro tópico.

> «Esto lo escribieron ustedes hace dos sesiones. Cuatro decisiones:
> a qué clúster, a qué tópico, si lleva clave, y cómo separarla. Guárdenlas.»

### Ahora el archivo

**Cambia a la ventana del editor, con `ProductorApp.java` abierto.**

> «Cincuenta y tres líneas. Vamos a leer cinco.»

🔴 **LA PREDICCIÓN. Detente aquí. Este es el momento del laboratorio.**

**Qué preguntarle a la sala, con estas palabras:**

> «Antes de que yo diga nada: **busquen sus cuatro flags en esta pantalla.**
> ¿Dónde quedó el `--bootstrap-server`? ¿Dónde el `--topic`? ¿Dónde el que
> decía que el mensaje lleva clave?»

**Deja que los busquen.** Que lo encuentren ellos es todo el laboratorio; que se
lo digas tú no sirve de nada.

Después recorre la tabla de la guía. **Las cuatro primeras filas, completas.**

**Y la fila que más enseña, que es la del flag que no existe:**

> «Fíjense en `--property key.separator=:`. **En Java no está, y no puede
> estar.** En la consola, la clave y el valor viajaban pegados en una línea de
> texto y había que partirla con dos puntos. En Java son **dos parámetros
> distintos** del mismo objeto. No hay nada que separar.
>
> Ese flag no era de Kafka. Era una muleta de la consola.»

**Cierra el bloque con la pregunta del `bootstrap`:**

> «Última cosa, y es la que más van a usar: este archivo dice
> `localhost:9092,9093,9094`. La consola dice `kafka-broker-1:29092`. **¿Por qué
> no son el mismo?**»

*(Porque la consola corre dentro de la red de Docker y el programa corre fuera.
Es exactamente la clase de error que van a diagnosticar.)*

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| No se lee en proyector | Estás usando `cat` en una terminal de 80 columnas | Ten el editor abierto **desde antes**, con letra grande |
| La sala se va a discutir Java | El detalle del `try-with-resources`, los genéricos… | 🔴 Cortar: «eso es sintaxis de Java y no cambia nada de Kafka. Vuelvan a las cinco líneas» |
| «¿Y `acks=all` qué era?» | Vino del Lab 07 | Es la confirmación del broker. **Y es la razón de que el Paso 3 imprima la partición y el offset**: sin `acks` no habría a quién preguntarle |

---

## Bloque 3 · minuto 13 · Correrlo — 3 min

```bash
cd cliente-java
mvn -q compile exec:java \
    -Dexec.mainClass="com.novatech.kafka.ProductorApp" \
    -Dexec.args="5"
```

⚠️ **Anticipa el ruido antes de que salga**, o vas a perder treinta segundos
explicándolo:

> «Van a ver tres líneas que empiezan con `SLF4J`. **Son ruido y salen
> siempre.** Es la biblioteca de logs de Java diciendo que no encontró con qué
> escribir. No es un error.»

**Qué esperar:**

```
Enviado a novatech.lab09.pedidos [particion 2, offset 0]
...
Total de pedidos enviados: 5
```

**Cómo leerlo en voz alta:**

> «`particion 2, offset 0`. **Eso no lo adivinó el programa: se lo dijo el
> broker.** El programa mandó el mensaje y esperó la confirmación, y en la
> confirmación viene dónde quedó. Eso pasa por una sola línea del archivo: el
> `acks=all`.
>
> Y el reparto entre particiones lo decide la **clave**, que en este programa es
> un identificador único por pedido. **A ustedes les van a salir otros números.**
> En dos corridas medidas salió `2,2,2,2,0` y `2,2,1,1,1`.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `mvn: command not found` | 🔴 **Maven no está** | **No hay arreglo en vivo.** Salta al Bloque 4 usando `kafka-console-producer` para poner mensajes, y explica el Paso 3 leyendo la salida que está en la guía, diciendo que es una salida medida y no una corrida en vivo |
| Se queda descargando | `.m2` frío | Es la razón de compilar el día antes. Habla mientras: son 16 MB |
| `Connection refused` | El clúster no está, o el puerto | `bin/90-test-lab.sh`. 🔴 **Y es la ocasión perfecta**: acaba de pasar en vivo lo del Bloque 1 |
| `offset` distinto de 0 | El tópico ya tenía mensajes | No se arregla en vivo. Dilo y sigue: lo que importa es que el broker contestó |

---

## Bloque 4 · minuto 16 · Leerlo con la consola — 4 min

**Qué decir para abrir:**

> «Si un cliente Java fuera *otra cosa*, haría falta un consumidor Java para
> leerlo. Vamos a usar el mismo comando de consola del Lab 06, **sin cambiarle
> nada.**»

```bash
cd ..
docker exec kafka-broker-1 kafka-console-consumer \
    --bootstrap-server kafka-broker-1:29092 \
    --topic novatech.lab09.pedidos \
    --from-beginning --max-messages 5 \
    --formatter-property print.key=true
```

**Cómo leerlo en voz alta:**

> «Eso es todo. **No existe un `kafka-console-consumer --java`.** No hace falta.
>
> A la izquierda del tabulador está la clave, que la puso el programa. A la
> derecha, el JSON. Y ojo con esto: **que se vea como JSON legible es una
> decisión del programa, no de Kafka.** Para Kafka son bytes. El JSON lo eligió
> el serializador, y el que lea tiene que saberlo. Guárdenlo, porque el Lab 11
> empieza justo ahí.»

### El matiz del `--from-beginning` — la tabla de las cuatro corridas

**Alguien va a decir** que la consola tiene `--from-beginning` y el Java tiene
`auto.offset.reset=earliest`, y que no son lo mismo. **Sí lo son.**

Muestra la tabla de la guía:

| Qué se corrió | 1ª vez | 2ª vez |
|---|---|---|
| Consola **sin** `--group` | 8 | **8** |
| Consola **con** `--group` | 8 | **0** |
| Consumidor Java | 8 | **0** |

> «Lo que engaña es el grupo. El consumidor de consola, cuando no le dan
> `--group`, **se inventa uno nuevo en cada arranque.** Ese grupo nunca leyó
> nada, no tiene offsets, y `earliest` lo manda al principio. Por eso parece que
> `--from-beginning` siempre lee todo.
>
> En cuanto le ponen un grupo de verdad —que es lo que hace cualquier programa—
> se comporta igual que el Java.»

🔴 **Y el cierre, que es lo que se llevan:**

> «Esto no es trivia. Es la causa número uno de *el consumidor dejó de leer* en
> producción. El grupo ya tenía offsets y nadie los miró. **Y se diagnostica con
> el `--describe --group` del Lab 06, no tocando el clúster.**»

### El cierre — las cinco reglas para SUNAT

**Dilas. No las leas, dilas:**

> 1. «Un cliente Kafka no es una capa sobre Kafka: es Kafka. El broker no
>    distingue una consola de una aplicación.
> 2. Cuando un programa *no conecta*, el primer archivo que se abre es el de las
>    propiedades, y la primera línea es `bootstrap.servers`.
> 3. `bootstrap.servers` depende de **desde dónde** corre el programa.
> 4. El serializador y el deserializador son dos piezas que nadie obliga a
>    coincidir. El que se cae es el que lee, dos días después. Eso lo cierra el
>    Lab 11.
> 5. Un consumidor con grupo no vuelve a leer lo que ya leyó, por más `earliest`
>    que tenga.»

**Y la frase de Spring**, la de arriba, que no se puede olvidar.

**Y la pregunta con la que se van:**

> «De los incidentes de Kafka que su equipo atendió el último año: ¿cuántos
> terminaron siendo del clúster, y cuántos de la configuración de un cliente?»

---

**Siguiente:** Lab 10 — *¿y a las tres de la mañana?*
