# Lab 12 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado**, y este es el laboratorio que más holgura
tiene de los seis: de las 7 actividades del recorrido viejo quedan **tres pasos**
y **cuatro comandos**. La SPEC dice que es el que más se puede recortar si el
tiempo aprieta, y así está construido: **si te quedan diez minutos, el Bloque 3
solo ya vale la sesión.**

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 12 OPERATIVO» | 🔴 **20 min antes** |
| Estado correcto | `bin/90-test-lab.sh` → 3 verificaciones OK | 15 min antes |
| 🔴 **Los datos sembrados** | Los cuatro comandos de abajo. **66 segundos medidos** | 🔴 **15 min antes** |
| Hay 30 pedidos | `docker exec kafka-broker-1 kafka-get-offsets --bootstrap-server kafka-broker-1:29092 --topic novatech.lab10.pedidos --time -1` suma 30 | 10 min antes |
| El stream **no** existe | `curl -s -X POST http://localhost:8088/ksql -H "Content-Type: application/vnd.ksql.v1+json" -d '{"ksql":"SHOW STREAMS;"}'` no muestra `PEDIDOS_STREAM` | 10 min antes |
| **Dos terminales abiertas** | Lado a lado, no en pestañas | 5 min antes |

🔴 **La tercera fila es la que arruina la clase si se olvida, y el `start-lab.sh`
no la hace.** Sin datos no hay nada que consultar y el Paso 2 sale vacío:

```bash
schema-cli/register-schema.sh novatech.lab10.pedidos-value infra/schemas/pedido.avsc
schema-cli/register-schema.sh novatech.lab10.clientes-value infra/schemas/cliente.avsc
kafka-cli/produce-flood-pedidos.sh 30
kafka-cli/produce-clientes-seed.sh
```

**Medido: 66 segundos.** La mayor parte se va en los 30 pedidos, porque cada uno
arranca una JVM dentro del contenedor. **No lo hagas delante de la sala.**

🔴 **Este lab arranca lento**: ksqlDB tarda entre 60 y 90 segundos en estar
disponible, después de los brokers y del Schema Registry. Deja 20 minutos.

**Si `PEDIDOS_STREAM` ya existe** (porque ensayaste), el Paso 1 va a devolver un
error `40001` en vez de `Stream created`. No rompe la clase —la guía lo
contempla— pero si quieres la salida limpia, bórralo antes:

```bash
curl -s -X POST http://localhost:8088/ksql -H "Content-Type: application/vnd.ksql.v1+json" \
    -d '{"ksql":"DROP STREAM pedidos_stream;"}'
```

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 6 |
| 2 · Forma de tabla, y lo que ya pasó | minuto 6 | `CREATE STREAM`, y el `SELECT` cinco veces | 6 |
| 3 · **Lo que todavía no pasó** | minuto 12 | Las dos terminales. Es el laboratorio | 6 |
| 4 · Cierre y las cinco reglas | minuto 18 | Nada | 2 |
| **Total de dictado** | | | **20** |

🔴 **A diferencia de los otros cinco labs, aquí sí hay holgura.** El Bloque 2 se
puede comprimir a tres minutos saltando el experimento de las cinco corridas, y
el Bloque 1 se puede acortar a cuatro. **Lo que no se toca es el Bloque 3**: es
el único que demuestra la afirmación, y es la única cosa que asombra de ksqlDB.

**Si vas muy apretado de tiempo en la sesión** —porque el lab anterior se
alargó— este es el lab que se recorta. Bloque 1 en tres minutos, Bloque 3
entero, y a otra cosa: **con nueve minutos se dicta lo esencial.**

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **9 s** | 🟢 **Medido**: los 17 s del recorrido menos los 8 de espera del Bloque 3 | Lo que le toma a la máquina |
| **Espera** | **8 s** | 🟢 **Medido**, y 🔴 **es a propósito.** No es un tiempo muerto: **es la demostración.** El Bloque 3 consiste en no hacer nada y mirar una consulta que no imprime | Es el hueco donde va la pregunta a la sala |
| **Siembra de datos** | **66 s** | 🟢 Medido | 🔴 **Fuera de clase.** Va en el *Antes de la clase* |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda** |

🟡 **La estimación de dictado sigue siendo una estimación.** **Nada de esto está
cronometrado contra una clase real.** Si te pasas, repórtalo con el bloque que se
te fue.

La modalidad es **demostrativa**, con **dos terminales lado a lado** en el
Bloque 3.

🔴 **Los cuatro comandos son `curl` largos con JSON adentro. Tenlos copiados en
un archivo de texto antes de entrar a clase.** El escape de las comillas simples
—`'"'"'`— es fácil de romper al teclear.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| La preparación de datos como actividad | Guía, *Para profundizar A*. Se hace antes de clase |
| El cliente interactivo `ksql-shell.sh` | Guía, *Para profundizar B* |
| **STREAM contra TABLE** y su `PRIMARY KEY` | Guía, *Para profundizar C* |
| El `WHERE` | Guía, *Para profundizar D* |
| Agregaciones y el JOIN | Guía, *Para profundizar E* |
| El desafío de streaming SQL | Guía, *Para profundizar F* |

🔴 **STREAM contra TABLE es la baja grande.** Ocupaba la mitad del recorrido
viejo, y se bota porque **no es lo que asombra**: es una distinción de modelado
que se entiende leyendo. Una frase al cerrar el Bloque 3:

> «Hay una segunda mitad de ksqlDB que hoy no vemos: además de `STREAM`, que son
> eventos, existe `TABLE`, que es el último valor de cada clave. Está en la guía
> con sus comandos **y con una trampa medida que vale la pena leer**: consultar
> una tabla con `EMIT CHANGES` no te da el último valor, te da todos los cambios.
> **La diferencia que importa no es stream contra tabla: es push contra pull.**»

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 6 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «El equipo de analítica pide algo razonable: *queremos saber cuántos
> comprobantes por minuto están entrando*.
>
> Y la respuesta que reciben siempre tiene la misma forma: **mañana.** Porque el
> camino es que los datos se copien a algún sitio durante la noche, que un
> proceso los agregue, y que a la mañana siguiente haya un informe.
>
> Ese informe **siempre habla del pasado.** Es correcto, es útil, y llega tarde
> para todo lo que importa en el momento: una carga anómala, un pico de rechazos,
> alguien que empezó a hacer algo raro hace veinte minutos.»

**Y la alternativa, que es peor de lo que parece:**

> «*Que escriban una aplicación que consuma el tópico y vaya calculando.* Ustedes
> ya vieron en el Lab 09 lo que es un consumidor: veinte líneas para conectarse,
> y todo lo demás hay que escribirlo. Para **una** pregunta. Y la siguiente
> pregunta es otra aplicación.
>
> Y hay algo peor todavía: **la gente que tiene las preguntas no escribe
> aplicaciones.** El analista que sabe qué preguntar sabe SQL, no Java. Cada vez
> que la respuesta exige un desarrollador, la pregunta se pospone o no se hace.»

### La metáfora, redactada

> «Volvamos al restaurante. Y hoy la pieza nueva no es un objeto: **es una forma
> distinta de preguntar.**
>
> Hasta ahora, cuando alguien quería saber cuántas comandas hubo, **bajaba al
> depósito a contar.** Preguntaba una vez y subía con un número. Y ese número, en
> el momento de subir, ya está viejo: mientras contaba entraron comandas nuevas.
> Si quiere saber cómo va ahora, tiene que volver a bajar. Eso es una consulta de
> toda la vida, sobre una base de datos.
>
> Lo de hoy es otra persona: **la que se planta en el paso con una libreta** y va
> anotando cada comanda que cruza, mientras cruza. No baja a ningún lado. Se
> queda ahí, y cada comanda que pasa es una respuesta más a la misma pregunta que
> hizo al principio.»

**Cierra con la regla, y anuncia el final:**

> 🍽 «La pregunta se hace una vez y sigue contestando.
>
> Y lo que vamos a ver hoy, que es lo único que asombra de esto: **el del paso
> puede plantarse antes de que exista la comanda.** Puede hacer la pregunta
> cuando todavía no hay nada que contestar, y esperar. **Eso es lo que ninguna
> base de datos puede hacer.**»

### Errores probables de este bloque

| Qué pasa | Qué hacer |
|---|---|
| «¿Esto reemplaza a nuestra base de datos?» | 🔴 **No, y es importante.** «ksqlDB no guarda sus datos: los tópicos siguen siendo los dueños. Es un traductor de SQL, no un almacén» |
| «¿Y esto es SQL de verdad?» | «Es SQL de verdad con dos palabras más. Lo van a ver en tres minutos» |

---

## Bloque 2 · minuto 6 · Forma de tabla, y lo que ya pasó — 6 min

### Paso 1 · El `CREATE STREAM`

Muestra el comando y **detente en lo que no hace**:

> «Esto declara que el tópico de pedidos se puede leer como una tabla de seis
> columnas. Y quiero que se fijen en lo que **no** pasa: no se copia un mensaje,
> no se crea un tópico, no se mueve un byte. **Lo único que queda es una
> declaración.**»

**Qué esperar:**

```
"commandStatus":{"status":"SUCCESS"
"message":"Stream created"
```

### Paso 2 · El `SELECT` aburrido, y la sorpresa que trae

> «Ahora el SQL. Este primero es aburrido a propósito: pregunta por lo que ya
> está escrito, que es lo que haría cualquier base de datos.»

Muestra las tres filas. Y después:

🔴 **EL EXPERIMENTO. Corre el mismo comando cinco veces seguidas, en vivo.**

**Qué preguntar antes de la segunda corrida:**

> «Los datos no han cambiado. Voy a correr exactamente el mismo comando otra vez.
> **¿Van a salir las mismas tres filas?**»

*(Casi todo el mundo dice que sí. Córrelo.)*

**Lo que salió, medido:**

```
corrida 1:  25   5   7
corrida 2:   9   7   5
corrida 3:   3   5  12
corrida 4:   5  19  28
corrida 5:   5  19  28
```

**Cómo leerlo en voz alta:**

> «El mismo `SELECT`, sobre datos que no cambiaron, devuelve filas distintas cada
> vez. En una base de datos eso sería un fallo grave. **Aquí es el
> comportamiento correcto**, y la razón la saben desde el Lab 05: este tópico
> tiene **doce particiones**, y el orden solo está garantizado dentro de cada
> una, nunca entre ellas.
>
> ksqlDB lee las doce a la vez, y el `LIMIT 3` se queda con las tres primeras que
> lleguen. **Un flujo no tiene un orden global, así que no hay `SELECT` que pueda
> dárselo.** Si alguien les pide un informe que dependa del orden entre
> particiones, está mal planteado, y este es el momento de decirlo.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| `error_code: 40001`, `already exists` | El stream quedó de un ensayo | No rompe nada: sigue al Paso 2. Es lo que dice la guía |
| El `SELECT` no devuelve filas | No se sembraron los datos | 🔴 **No hay arreglo rápido: son 66 segundos.** Por eso está en el *Antes de la clase* |
| Las cinco corridas dan lo mismo | Puede pasar, y no invalida nada | Corre dos o tres más. En la medición, las corridas 4 y 5 coincidieron entre sí |
| `HTTP 415` | Se perdió el `Content-Type` al copiar | Vuelve a pegar el comando completo |

---

## Bloque 3 · minuto 12 · Lo que todavía no pasó — 6 min

🔴 **Este es el laboratorio. Todo lo anterior era preparación.**

**Qué decir para abrir, y pedir la predicción:**

> «Voy a lanzar la **misma consulta**, cambiando una sola palabra: `earliest`
> por `latest`. Con eso ignora los treinta pedidos que ya están y solo mira lo
> que llegue de ahora en adelante.
>
> Y el tópico está quieto. **Prediganme: ¿qué va a imprimir? ¿Va a dar error, va
> a terminar, o se va a quedar ahí?**»

*(Deja que contesten. La palabra que buscas es «esperar», y casi nunca sale a la
primera.)*

**Lanza la consulta en la terminal A.** Sale la cabecera, y después nada.

> «Ahí está. La cabecera —ya sabe qué columnas va a devolver— y **nada más.** No
> falló, no terminó, no está colgada. **Está esperando.** El dato por el que
> pregunté todavía no existe.»

🔴 **AQUÍ ESTÁN LOS OCHO SEGUNDOS DE ESPERA. No los llenes con relleno: llénalos
con la pregunta que cierra el laboratorio.**

> «Mientras esperamos, quiero que piensen una cosa: **¿en qué momento se escribió
> esa consulta?** Hace ocho segundos. **¿Y cuándo va a existir el dato que la
> conteste?** Todavía no lo sé, porque no lo he producido.»

**Cambia a la terminal B y produce, en voz alta:**

```bash
kafka-cli/produce-pedido-avro.sh 777 1001 "Pedido en vivo" 1 99999.99 pendiente
```

> «Un pedido. Este comando **no sabe nada de ksqlDB**, ni de que hay una consulta
> esperando. Escribe en el tópico y se va.»

**Vuelve a la terminal A.** La fila está ahí.

**Cómo cerrar, con las tres marcas de tiempo de la corrida medida:**

> «Miren las horas. La pregunta se hizo a las **48**. A las **56**, ocho segundos
> después, seguía sin nada que decir. Y a las **57** —un segundo después de que
> el dato naciera— lo contestó.
>
> **Nadie volvió a preguntar.** El `SELECT` se escribió una sola vez, ocho
> segundos antes de que existiera la fila que lo contestó.
>
> Eso es lo que ninguna base de datos puede hacer, y es la única razón por la que
> ksqlDB existe.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| La consulta imprime filas viejas al arrancar | Se quedó `earliest` en vez de `latest` | 🔴 **Arruina la demostración.** Ctrl+C y vuelve a lanzarla. Ten el comando copiado |
| No aparece nada tras producir | El pedido falló en la terminal B | Mira la terminal B: si el envoltorio no dijo «✓», el problema está ahí |
| Aparece pero tarda mucho | Normal | En la medición fue **1 segundo**. Si tarda más, dilo y sigue: lo que importa es que llegó sola |
| `The server encountered an internal error` | 🔴 **ksqlDB sin brokers.** Medido | No es del CLI ni del renderizado: mira `docker ps`. Le pasa a cualquiera cuyo clúster no terminó de levantar |

---

## Bloque 4 · minuto 18 · Cierre — 2 min

**Las cinco reglas. Dilas, no las leas:**

> 1. «ksqlDB no es una base de datos. No guarda sus datos: los tópicos siguen
>    siendo los dueños.
> 2. `EMIT CHANGES` es la diferencia entre preguntar y quedarse preguntando.
> 3. **`auto.offset.reset` decide qué ven, y es el error más frecuente.** Una
>    consulta que *no devuelve nada* casi siempre está en `latest` sobre un
>    tópico quieto. **No está rota: está esperando.**
> 4. Un flujo no tiene orden global. Lo acaban de ver cinco veces.
> 5. **El SQL no elimina el trabajo, lo mueve.** Una consulta que corre para
>    siempre es una aplicación que corre para siempre: consume memoria, se cae, y
>    hay que vigilarla. Lo que ksqlDB ahorra es **escribirla**, no operarla.»

**Y la frase de STREAM contra TABLE**, la de arriba.

**Y la pregunta con la que se van:**

> «De los informes que su área entrega hoy al día siguiente: ¿cuáles cambiarían
> de valor si la respuesta llegara en el momento, y cuáles no cambiarían nada?»

---

**Siguiente:** Lab 14 — *la seguridad no se demuestra con lo que permite.*
