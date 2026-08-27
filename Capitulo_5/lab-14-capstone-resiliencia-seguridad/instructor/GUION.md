# Lab 14 · Guion de dictado

> **Para el relator, no para el alumno.** Este archivo tiene qué decir, qué
> preguntar antes de cada comando, qué va a salir en pantalla y qué se hace
> cuando algo no sale.

🔴 **El techo es 20 minutos de dictado.** De las 20 actividades del recorrido
viejo quedan **cuatro pasos** y **cinco comandos**. Toda la PKI —que ocupaba dos
guías— la hace el `start-lab.sh` en 19 segundos y el alumno la ve hecha.

🔴 **Y una cosa que no se puede perder de vista al dictarlo: este es el último
laboratorio del curso.** El cierre del Bloque 4 no cierra el lab: cierra las
catorce sesiones.

---

## Antes de la clase

| Cosa | Cómo se comprueba | Cuándo |
|---|---|---|
| 🔴 **Ningún otro lab levantado** | `docker ps -a --format '{{.Names}}\t{{.Label "com.docker.compose.project"}}' \| grep novatech-lab` no devuelve nada | 🔴 **20 min antes** |
| Clúster arriba | `bin/start-lab.sh` termina con «CLÚSTER NOVATECH LAB 12 OPERATIVO (con seguridad)» | 15 min antes |
| Estado correcto | `bin/90-test-lab.sh` → 4 verificaciones OK | 10 min antes |
| Hay mensajes que leer | `kafka-cli/produce-publico.sh "Comprobante publico de la clase"` y `kafka-cli/produce-confidencial.sh "Comprobante confidencial de la clase"` | 10 min antes |
| `app2` **sin** ACL en el confidencial | `kafka-cli/list-acls.sh` no muestra `User:app2` bajo `novatech.lab12.confidencial` | 10 min antes |

🔴 **La primera fila es la que más cuesta y la que más se olvida.** El
`start-lab.sh` de este lab **no bota contenedores de otros labs** —lo dice su
propia ficha, y es deliberado— así que si vienes de dictar el Lab 12, sus
contenedores siguen ocupando los nombres `kafka-broker-1/2/3` y `kafbat-ui`.
**Medido: `stop-lab.sh` del 12 seguido de `start-lab.sh` del 14 falla** con
`Conflict. The container name "/kafka-broker-3" is already in use`.

**La forma de bajar el lab anterior de verdad**, desde su carpeta `infra/`:

```bash
docker compose --env-file .env -p novatech-lab12 down -v --remove-orphans
```

**Si el `app2` ya tiene ACL sobre el confidencial** (porque ensayaste *Para
profundizar B* y no la borraste), el Paso 3 no falla y **te quedas sin la mitad
del laboratorio**. Bórrala, o vuelve a levantar el lab.

---

## Presupuesto de tiempo — 20 minutos

| Bloque | Arranca en | Qué se muestra en pantalla | Min |
|---|---|---|---|
| 1 · El problema y la metáfora | minuto 0 | Nada. Se habla | 5 |
| 2 · Las reglas escritas | minuto 5 | `list-acls`, y la casilla vacía | 4 |
| 3 · **Las dos pruebas negativas** | minuto 9 | `attempt-no-auth`, `consume-confidencial-app2`, y la comparación | 7 |
| 4 · La compuerta también dice sí, y el cierre del curso | minuto 16 | `consume-publico`, `consume-confidencial-admin` | 4 |
| **Total de dictado** | | | **20** |

**El bloque frágil es el 3**, y es también el que no se puede tocar: **es la
razón de ser del laboratorio.** Si algo se estira, sale del Bloque 2 —la lectura
de las ACL se puede hacer en dos minutos señalando solo la casilla vacía— o del
Bloque 1.

🔴 **Lo que no se bota nunca:** la **comparación** entre el Paso 2 y el Paso 3.
No basta con correr los dos comandos: hay que ponerlos lado a lado y decir en voz
alta en qué se diferencian. **Ese es el laboratorio.** Correrlos sin compararlos
es dejar la clase con «dos cosas fallaron», que es justo la confusión que este
lab existe para deshacer.

### Los tres relojes

| Reloj | Cuánto | Cómo se obtuvo | Para qué sirve |
|---|---|---|---|
| **Ejecución pura** | **24 s** | 🟢 **Medido**, los 5 comandos del recorrido extraídos de la guía, 27-ago-2026 | Lo que le toma a la máquina |
| **Arranque** | **19 s** | 🟢 **Medido**, y en ellos genera la PKI completa, levanta 3 brokers con TLS y SASL, crea tópicos y escribe ACLs | 🔴 **Fuera de clase**, pero conviene saber el número: es la respuesta a «¿cuánto cuesta montar esto?» |
| **Dictado** | **20 min** | 🟡 **Estimado**, no medido | 🔴 **Es el que manda** |

🟡 **La estimación de dictado sigue siendo una estimación.** **Nada de esto está
cronometrado contra una clase real.** Si te pasas, repórtalo con el bloque que se
te fue.

La modalidad es **demostrativa**. 🔴 **Y aquí hay una decisión de puesta en
escena que importa: deja las salidas de los Pasos 2 y 3 visibles a la vez**, en
dos mitades de pantalla o desplazando hacia atrás. El Bloque 3 se dicta
comparando, y si la salida del Paso 2 ya se fue de la pantalla, la comparación
se pierde.

### Lo que se botó de este guion

| Bloque botado | Dónde quedó |
|---|---|
| **Generar la PKI paso a paso** (2 guías enteras) | Guía, *Para profundizar A*. Lo hace el `start-lab.sh` |
| Armar los almacenes de claves y configurar los *listeners* | Guía, *Para profundizar A* |
| Escribir ACLs a mano | Guía, *Para profundizar B* |
| `min.insync.replicas` | Guía, *Para profundizar C*, dentro del drill |
| **El drill de failover** | Guía, *Para profundizar C* |
| El capstone automatizado | Guía, *Para profundizar D* |

🔴 **El drill de failover es la baja grande, y la SPEC lo puso como «si sobra
tiempo».** Si terminas el Bloque 4 en el minuto 16 y la sala está despierta,
**córrelo**: son cuatro comandos y demuestra que con RF 3 y
`min.insync.replicas=2` el clúster sigue aceptando escrituras con un broker
caído. Si no da el tiempo, una frase:

> «Hay una segunda mitad de este capstone que hoy no vemos: qué pasa con los
> datos cuando se cae un broker. Está en la guía, con los comandos y el
> `verify-no-loss` que comprueba que no se perdió nada. **El resumen es que con
> factor de replicación 3 y `min.insync.replicas` en 2, el clúster sigue
> escribiendo con un broker menos** — que es exactamente lo que configuraron
> ustedes en el Lab 05.»

---

## Bloque 1 · minuto 0 · El problema y la metáfora — 5 min

**En pantalla no hay nada.** Este bloque es solo palabra.

### Qué decir

> «La conversación sobre seguridad en un clúster suele terminar en una
> demostración que no demuestra nada.
>
> Alguien conecta un cliente, produce un mensaje, lo consume, y dice: *listo,
> está seguro*. Y todos asienten, porque funcionó.
>
> **Pero que funcione no prueba nada.** Un clúster completamente abierto también
> deja producir y consumir. **La demostración es idéntica en los dos casos.** Lo
> único que distingue a un clúster seguro de uno abierto es lo que el seguro
> **no** deja hacer.»

**Y la segunda mitad, que es donde se pierde la gente:**

> «Y cuando por fin alguien hace la prueba negativa, la hace **una sola vez**:
> intenta conectar sin credenciales, ve que falla, y da el tema por cerrado.
>
> Eso deja fuera la mitad cara del problema. Porque una cosa es **quién eres** y
> otra muy distinta es **qué puedes tocar**. En SUNAT esa diferencia tiene nombre
> y apellido: el sistema de un área tiene credenciales perfectamente válidas
> —es un sistema de la casa, tiene que poder entrar— **y aun así no debe poder
> leer los datos de otra área.**»

### La metáfora, redactada

> «En el restaurante son dos cosas distintas, y hoy es el día de no
> confundirlas.
>
> Una es **la puerta de servicio con cerradura.** Si no tienes llave, no entras
> — y desde fuera ni siquiera oyes lo que pasa dentro.
>
> La otra es **la lista pegada en la cocina** que dice qué puede tocar cada uno
> de los que ya entraron.
>
> Y el ejemplo que quiero que se lleven: hay un **proveedor que tiene llave**.
> Entra todos los días, deja la mercadería, se va. Es de la casa, y la llave es
> suya.
>
> **Y no puede entrar a la caja.** No porque le falte la llave de la puerta —esa
> la tiene— sino porque **la lista no lo nombra para eso.**»

**Cierra con la regla y anuncia el final:**

> 🍽 «Tener llave y tener permiso son dos cosas distintas, y hacen falta las dos.
>
> Hoy vamos a correr cinco comandos, y **dos de ellos tienen que fallar.** Si
> alguno de esos dos funcionara, el clúster estaría roto. Vamos a mirar **qué**
> error da cada uno, porque no es el mismo, y esa diferencia es todo lo que hay
> que llevarse de esta sesión.»

### Errores probables de este bloque

| Qué pasa | Qué hacer |
|---|---|
| «¿No basta con la contraseña?» | 🔴 **Es la pregunta que abre el lab.** «Con la contraseña sabes quién es. No sabes qué le dejas tocar. En diez minutos van a ver a un usuario con la contraseña correcta chocar contra una pared» |
| Preguntan por Kerberos, OAuth, mTLS | «Son otros mecanismos de la **primera** compuerta. La segunda —las ACL— es la misma con todos» |

---

## Bloque 2 · minuto 5 · Las reglas escritas — 4 min

```bash
kafka-cli/list-acls.sh
```

**Cómo leerlo en voz alta.** No leas las trece líneas. **Señala tres cosas:**

> «Cada línea es una regla: quién, desde dónde, qué operación, y si se permite.
>
> Miren el primer bloque, el del tópico **público**: están `app1` y `app2`.
>
> Miren el tercero, el del **confidencial**: está `app1`… y se acabó.»

🔴 **LA PREGUNTA. Detente aquí.**

> «**¿Dónde está la regla que le prohíbe a `app2` leer el confidencial?**»

*(Deja el silencio. La respuesta es que no existe, y casi nunca sale a la
primera.)*

> «No hay ninguna. Y no hace falta, porque **en Kafka lo que no está
> explícitamente permitido está denegado.** Lo que protege ese tópico no es una
> regla que niega: es **la ausencia** de una regla que permita.»

**Y la tercera cosa, que es la que más se olvida en producción:**

> «El bloque del medio dice `resourceType=GROUP`. **Leer un tópico no basta:
> hace falta permiso sobre el grupo de consumidores también.** Es el permiso que
> más se olvida al dar de alta un cliente nuevo, y produce un error que parece
> del tópico y no lo es.»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Aparece `User:app2` bajo el confidencial | Quedó del ensayo de *Para profundizar B* | 🔴 **Bórrala ahora o pierdes el Bloque 3.** El comando `--remove` está en la guía |
| La salida no cabe en pantalla | Son 13 líneas | Reduce la fuente antes de clase, o señala con el cursor |

---

## Bloque 3 · minuto 9 · Las dos pruebas negativas — 7 min

🔴 **Este es el laboratorio. Y se dicta comparando, no ejecutando.**

### Prueba 1 · El que no tiene llave

**Pide la predicción antes:**

> «Voy a pedirle al clúster la cosa más inocente que existe, la lista de
> tópicos, **sin ninguna credencial.** ¿Qué me va a contestar? ¿*No autorizado*?
> ¿*Contraseña incorrecta*?»

```bash
kafka-cli/attempt-no-auth.sh
```

⚠️ **Anticipa la salida antes de que salga, o pierdes a la sala:**

> «Va a salir algo feo, con la palabra `OutOfMemoryError`. **Es la respuesta
> correcta**, y ahora les explico por qué.»

**Cómo leerlo en voz alta:**

> «El cliente habló en claro contra un puerto que solo entiende TLS. Lo que le
> contestó el broker fue el **saludo de TLS**, y el cliente lo interpretó como si
> fuera un mensaje de Kafka: leyó los primeros bytes como *longitud del mensaje*,
> le salió un número gigantesco, e intentó reservar esa memoria. Por eso muere
> de memoria y no de permisos.
>
> **Y ahora fíjense en lo que el clúster NO dijo.** No dijo *no autorizado*. No
> dijo *usuario incorrecto*. No dijo *ese tópico no existe*. **No dijo nada.**
> Desde fuera de la puerta no se oye nada de lo que pasa dentro.
>
> **Eso es autenticación: no es que te digan que no, es que no hay
> conversación.**»

### Prueba 2 · El que tiene llave pero no permiso

**Pide la segunda predicción:**

> «Ahora `app2`. Y quiero que quede claro: **`app2` tiene credenciales válidas y
> correctas.** No es un intruso ni tiene la contraseña mal. Es el proveedor con
> llave. **¿El error se va a parecer al anterior?**»

```bash
kafka-cli/consume-confidencial-app2.sh
```

**Cómo leerlo en voz alta:**

> «`TOPIC_AUTHORIZATION_FAILED`. `Not authorized to access topics:
> [novatech.lab12.confidencial]`. Y al final, `Processed a total of 0 messages`.»

🔴 **Y AHORA LA COMPARACIÓN, que es el minuto más importante del laboratorio.**
Con las dos salidas a la vista:

| | Sin credenciales | `app2` |
|---|---|---|
| ¿Hubo conversación? | **No** | **Sí** |
| ¿Dijo por qué? | No dijo nada | `TOPIC_AUTHORIZATION_FAILED` |
| ¿Nombró el recurso? | No sabía ni que existía | **Sí, por nombre** |
| Qué error | `OutOfMemoryError` | `TopicAuthorizationException` |
| Qué falló | **Autenticación** | **Autorización** |

**Y la frase que hay que decir despacio, porque es lo que se llevan del curso:**

> «`app2` **entró al clúster.** Se autenticó, negoció TLS, pidió los metadatos y
> el clúster se los negó **por nombre**. Y eso solo puede pasar si el clúster
> sabe quién es. **Para negarle algo a alguien, primero hay que saber quién es
> alguien.**
>
> **Autenticar es saber quién eres. Autorizar es saber qué puedes tocar. Son dos
> compuertas distintas, en ese orden, y hacen falta las dos.**»

### Errores probables de este bloque

| Síntoma | Causa | Qué hacer |
|---|---|---|
| El Paso 3 **funciona** | `app2` tiene ACL de un ensayo | 🔴 **Se te cayó la mitad del lab.** Bórrala en vivo con el `--remove` de *Para profundizar B* y repite. Y aprovéchalo: acabas de demostrar que las ACL surten efecto sin reiniciar |
| Alguien dice que el `OutOfMemory` es un bug | Es razonable pensarlo | «Es feo y es correcto. Es la firma de un cliente en claro contra un puerto TLS, y la van a reconocer en producción» |
| La salida del Paso 2 ya no está en pantalla | Se desplazó | 🔴 Desplaza hacia atrás **antes** de empezar la comparación. Sin las dos a la vista, el bloque no funciona |

---

## Bloque 4 · minuto 16 · La compuerta también dice sí, y el cierre — 4 min

**Qué decir para abrir:**

> «Queda una duda razonable, y alguien la está pensando: *¿y cómo sé que las
> credenciales de `app2` sirven para algo? A lo mejor están mal.* Se contesta con
> el mismo comando, cambiando solo el tópico.»

```bash
kafka-cli/consume-publico.sh
```

⚠️ **Atájalo antes de que pregunten:**

> «Fíjense: **esta salida también trae la palabra `ERROR`, y sin embargo
> funcionó.** Ese `TimeoutException` del final es el tiempo de espera
> cumpliéndose porque no llegó nada más. **Sale en los cuatro comandos de hoy,
> en los que funcionan y en los que no.**
>
> **La regla de lectura: no miren la palabra ERROR. Miren cuál es el error, y
> miren la última línea.** `Processed a total of 1 messages`.»

**Y la comparación que cierra:**

> «Paso 3: `app2`, confidencial, **cero** mensajes. Paso 4: `app2`, público,
> **un** mensaje. **Mismas credenciales, mismo comando, distinto tópico.** Eso
> prueba que lo que falló antes no era la llave: era el permiso.»

```bash
kafka-cli/consume-confidencial-admin.sh
```

> «Y el mismo tópico que le negaron a `app2`, leído sin problema por `admin`. Y
> `admin` **no aparece en ninguna ACL** — vuelvan al Bloque 2 y búsquenlo. Es
> *super user*: una llave maestra del broker a la que las reglas ni se le
> consultan.
>
> **Por eso el super user tiene que ser de muy pocas manos**, y nadie debería
> usarlo para el día a día.»

### El cierre — las cinco reglas para SUNAT

> 1. «Una demostración de seguridad que solo muestra lo que funciona no demuestra
>    nada. **Pidan siempre la prueba negativa.**
> 2. **Y pidan las dos.** Sin credenciales, y con credenciales válidas sobre algo
>    que no le toca. La segunda casi nunca se hace, y es la que protege los datos
>    entre áreas.
> 3. Los dos fallos se distinguen mirando el error. Un cliente que muere sin
>    respuesta es autenticación. Un `TopicAuthorizationException` que nombra el
>    recurso es autorización, y significa que el cliente **sí entró**.
> 4. En Kafka, lo que no está explícitamente permitido está denegado.
> 5. El super user no tiene ACL, y por eso es el mayor riesgo del clúster.»

**Y la frase del drill de failover**, si no dio el tiempo de correrlo.

### 🔴 El cierre del curso

**Este es el último bloque de las catorce sesiones. Vale la pena cerrarlo como
tal, y no con «bueno, hasta aquí llegamos».**

> «Y con esto se cierran los catorce laboratorios. Si tuviera que resumirlos en
> una sola línea, sería esta: **Kafka no te avisa.**
>
> No les avisó cuando borró por retención en el Lab 05. No les avisó cuando un
> contrato iba a romper a un consumidor, hasta que pusieron el Registry en el 11.
> No les avisa cuando un consumidor se queda atrás, ni cuando alguien lee lo que
> no debía.
>
> **Todo eso se ve. Pero hay que ir a mirarlo.** Y ahora saben con qué comando.»

**Y la pregunta con la que se van del curso:**

> «De los sistemas que hoy se conectan a sus clústeres: ¿cuántos usan
> credenciales de super user porque *era más fácil*, y qué pasaría si uno de
> ellos tuviera un error de programación?»

---

**Fin del curso.**
