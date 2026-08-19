# Ejemplos de respuesta

Aquí tienes las seis preguntas de reflexión **respondidas de verdad**, con el nivel de profundidad que se espera.

## Cómo usar esto

🔴 **Estos ejemplos son de un caso distinto al tuyo.** Los números, los nombres de tópicos y las decisiones son de otra implementación de NovaTech. **Si los copias tal cual, tu expediente va a contradecir tus propias evidencias** y eso se nota de inmediato.

**Úsalos para ver:**
- Qué tan larga tiene que ser una respuesta
- Qué estructura sigue: primero la decisión, después el porqué, y al final la evidencia que la respalda
- Cómo se conecta una afirmación con una salida concreta

**Y después escribe la tuya, con tus números.**

---
---

## Pregunta 1

> ¿Qué enfoque usarías para dimensionar el quórum de controladores de NovaTech y por qué?

### Ejemplo de respuesta

Para NovaTech definí un quórum de **tres controladores** en modo combinado, donde cada nodo cumple simultáneamente el rol de broker y de controlador.

El razonamiento parte de cómo KRaft toma decisiones: el quórum necesita **mayoría simple** para elegir líder y confirmar cambios en el registro de metadatos. Con tres controladores, la mayoría es dos, lo que significa que **el clúster tolera la pérdida de un nodo y sigue operando**. Con dos nodos caídos quedaría uno solo, que no puede formar mayoría, y el clúster perdería la capacidad de tomar decisiones aunque los brokers siguieran atendiendo lecturas.

Descarté explícitamente los números pares. **Con cuatro controladores la mayoría sigue siendo tres**, o sea que se paga un servidor adicional sin ganar un punto de tolerancia. El siguiente escalón real es cinco, que tolera dos caídas, y lo consideré innecesario para el volumen actual de NovaTech: agrega latencia en cada decisión de metadatos porque hay que coordinar con más nodos, y el costo operacional no se justifica mientras la empresa no opere en más de un datacenter.

Sobre el modo combinado: para el tamaño actual es la opción correcta, ya que separar controladores dedicados agrega tres servidores que estarían subutilizados. **Documenté como criterio de migración** que si el clúster supera los diez brokers o si la carga de metadatos empieza a competir con el tráfico de datos, corresponde separar los roles.

Mi evidencia del dimensionamiento está en `evidencias/hito-2/quorum-inicial.txt`, donde `CurrentVoters` muestra los tres controladores registrados con sus endpoints.

---
---

## Pregunta 2

> ¿Qué afirmaciones del resultado obtenido respaldan que tu clúster tolera la caída de un nodo?

### Ejemplo de respuesta

Tres observaciones concretas, todas contrastables en las evidencias.

**Primera: hubo elección de un líder nuevo sin intervención humana.** Antes de la caída, `quorum-inicial.txt` muestra `LeaderId: 1`. Después de detener ese nodo, `quorum-tras-caida.txt` muestra `LeaderId: 2`. Nadie ejecutó un comando de failover: los dos nodos sobrevivientes formaron mayoría y resolvieron la sucesión en segundos.

**Segunda: el contador de elecciones lo confirma.** El campo `LeaderEpoch` pasó de 1 a 2. Ese número se incrementa únicamente cuando hay un relevo de mando, así que su cambio es la prueba de que la elección ocurrió y no de que el sistema simplemente reportó otro valor.

**Tercera, y la que más me interesa: el clúster supo que perdió un nodo sin dejar de operar.** En `topico-antes.txt` la columna `Isr` del tópico muestra los tres brokers. En `topico-tras-caida.txt` esa misma columna muestra dos, mientras `Replicas` sigue mostrando tres. **Esa diferencia es exactamente el estado que quiero ver en una caída**: el sistema reconoce que una réplica no está al día, mantiene el registro de que debería estarlo, y sigue aceptando escrituras con las dos que quedan.

Agrego una observación sobre el margen. La configuración `min.insync.replicas=2` significa que con dos réplicas sincronizadas estamos **justo en el mínimo**. El clúster funciona, pero sin holgura: una segunda caída detendría las escrituras. Por eso en el runbook establecí que la recuperación de un nodo caído es una tarea del mismo día y no puede quedar pendiente para el siguiente turno.

Finalmente, la reincorporación también quedó demostrada. En `quorum-recuperado.txt` los tres nodos aparecen con `Lag` en cero, lo que indica que el nodo devuelto se puso al día por sí solo. Y el `LeaderEpoch` **no** volvió a subir, lo que confirma algo importante: en Kafka el nodo que regresa no reclama el liderazgo mientras el actual esté sano.

---
---

## Pregunta 3

> ¿Cómo comprobarías que la configuración de retención y replicación cumple los objetivos de durabilidad?

### Ejemplo de respuesta

Separé la comprobación en dos partes, porque retención y replicación protegen contra riesgos distintos: la replicación protege contra la pérdida de un servidor, y la retención define por cuánto tiempo el dato sigue disponible.

**Sobre la replicación**, la verificación es que `Replicas` e `Isr` coincidan en estado normal. En `evidencias/hito-3/topico-retencion-infinita.txt` el tópico de auditoría muestra las tres réplicas sincronizadas. Además configuré `min.insync.replicas=2`, lo que hace que Kafka **rechace una escritura** si no hay al menos dos copias que puedan confirmarla. Esa configuración es la que convierte la replicación en una garantía de durabilidad y no solo en una copia de respaldo: sin ella, el clúster aceptaría escrituras que viven en un solo disco.

**Sobre la retención**, no me bastó con leer la configuración: la comprobé viéndola actuar. Creé un tópico con `retention.ms=60000` y `segment.ms=10000`, produje cien mensajes, y medí los offsets disponibles dos veces con dos minutos de diferencia. Las salidas están en `retencion-antes.txt` y `retencion-despues.txt`, y muestran que los mensajes dejaron de estar disponibles sin que nadie los borrara.

Esa prueba me dejó una conclusión operacional que documenté: **una retención mal configurada no genera ningún error.** Kafka hace exactamente lo que se le pidió, en silencio. Por eso la retención de cada tópico quedó definida en la tabla de diseño con su justificación de negocio, y no como un valor por defecto heredado.

Para los tópicos de NovaTech apliqué tres criterios distintos. Las posiciones GPS tienen retención de una hora, porque el volumen es alto y el dato pierde valor de inmediato. Los eventos de auditoría tienen retención infinita, porque su vigencia la determina una obligación legal y no un criterio técnico. El estado de vehículos usa compactación en lugar de retención por tiempo, porque ahí solo interesa el último valor conocido de cada unidad.

---
---

## Pregunta 4

> ¿Qué aspectos seleccionarías para demostrar que el ajuste de rendimiento tuvo efecto?

### Ejemplo de respuesta

El criterio central que apliqué es que **una sola medición no demuestra nada**. Un número aislado de throughput no dice si el sistema está bien o mal configurado: solo dice cuánto rindió esa vez. Por eso toda mi evidencia de rendimiento es comparativa.

**El método fue cambiar un parámetro a la vez.** Medí el estado base, modifiqué un único valor, y volví a medir con la misma carga y las mismas condiciones. Si hubiera cambiado tres parámetros y el rendimiento mejorara, no tendría forma de saber cuál de los tres sirvió, ni si alguno de ellos en realidad empeoró las cosas y quedó compensado por otro.

**Los aspectos que seleccioné para comparar son tres**, y cada uno responde una pregunta distinta:

El **throughput**, en mensajes por segundo y en megabytes por segundo, responde cuánto volumen aguanta la plataforma. Es la métrica más visible pero también la que más engaña por sí sola.

La **latencia en percentiles**, no en promedio. El promedio esconde los casos malos: un sistema con latencia promedio de cinco milisegundos puede tener un percentil 99 de dos segundos, y esos son justamente los casos que un usuario nota. Reporté el p50, el p95 y el p99.

La **estabilidad de la medición**, o sea si el resultado se repite. Corrí cada configuración más de una vez, porque una mejora que aparece en una corrida y desaparece en la siguiente no es una mejora sino ruido.

En cuanto a qué parámetro ajusté, trabajé sobre el tamaño de lote del productor. El razonamiento es que agrupar más mensajes por envío reduce la cantidad de viajes de red, lo que mejora el throughput a costa de agregar una latencia mínima de espera. Esa es exactamente la clase de intercambio que hay que declarar: **el ajuste no mejoró todo, mejoró una cosa a cambio de otra**, y esa decisión depende de si el tópico prioriza volumen o inmediatez.

Las dos mediciones están en `evidencias/hito-3/` y en el expediente incluí la tabla comparativa con las cifras exactas.

---
---

## Pregunta 5

> ¿Cómo determinarías que las políticas de seguridad aplicadas protegen efectivamente la plataforma?

### Ejemplo de respuesta

La seguridad no se demuestra mostrando que un usuario autorizado puede trabajar. **Se demuestra mostrando que uno no autorizado no puede.** Por eso mi evidencia central de este hito son dos pruebas negativas, no las positivas.

**La primera prueba negativa es de autenticación.** Un cliente sin credenciales intenta conectarse al clúster y **la conexión no llega a establecerse**. La salida está en `evidencias/hito-4/rechazo-sin-credenciales.txt`. Lo que se rechaza aquí es la identidad: el clúster no sabe quién es ese cliente y no lo deja entrar.

**La segunda prueba negativa es de autorización, y es distinta.** Un cliente **con credenciales válidas** —o sea, alguien que el clúster reconoce perfectamente— intenta leer un tópico para el que no tiene permiso, y es rechazado. La salida está en `rechazo-sin-permiso.txt`. Aquí el cliente sí entró al clúster; lo que falló es que quiso hacer algo que su rol no contempla.

**Esa distinción es la que quiero dejar demostrada**, porque es la que más se confunde: autenticación responde *quién eres*, autorización responde *qué puedes hacer*. Un sistema puede tener una y no la otra, y en ese caso está mal protegido aunque parezca seguro.

Sobre el cifrado, la evidencia es que la conexión del cliente autorizado funciona **sobre TLS** y no en texto plano. El listener seguro exige `SASL_SSL`, así que una conexión que funciona por ese puerto está necesariamente cifrada y autenticada.

Sobre las ACLs, entregué el listado completo en `acls.txt`. Y hay un principio de Kafka que apliqué deliberadamente y que conviene explicitar: **lo que no está permitido está denegado.** Un tópico sin reglas no lo puede leer nadie salvo el super usuario. Eso significa que las ACLs no son un filtro que se agrega sobre un sistema abierto, sino la definición completa de quién puede operar.

La limitación que declaro con honestidad: probé el rechazo de dos escenarios concretos, no de todos los posibles. Una verificación exhaustiva requeriría una matriz de cada principal contra cada operación sobre cada recurso, y eso excede el alcance de este proyecto. Lo dejé anotado en el runbook como tarea de una auditoría de seguridad formal.

---
---

## Pregunta 6

> ¿Cómo valorarías la preparación de NovaTech ante un desastre a partir de tu plan de recuperación?

### Ejemplo de respuesta

Mi valoración es que **NovaTech está preparada para la pérdida de un nodo y no está preparada para la pérdida del sitio completo**, y considero importante decirlo así en lugar de presentar el plan como una solución total.

**Lo que sí está cubierto y está probado.** La caída de un broker está resuelta y no es teoría: ejecuté el drill completo —tumbar un nodo con tráfico activo, verificar que no se perdieron mensajes, y recuperarlo— y las evidencias están en `evidencias/hito-4/sin-perdida.txt`. El clúster mantiene el servicio, elige un líder nuevo sin intervención y el nodo devuelto se reincorpora por sí solo. **Ese es el escenario más frecuente en operación real y está resuelto.**

**Lo que no está cubierto.** Los tres nodos viven en el mismo sitio, así que un corte de energía, una falla de red del datacenter o un incendio dejan la plataforma completa fuera de servicio. La replicación protege contra la pérdida de un servidor, no contra la pérdida del lugar donde están los tres.

**Las dos cifras que debe definir el negocio, no yo.** Un plan de recuperación necesita un objetivo de tiempo de recuperación —cuánto puede estar caída la plataforma— y un objetivo de punto de recuperación —cuántos datos es aceptable perder—. **Esas dos cifras no son decisiones técnicas.** Las tiene que fijar quien conoce el costo de que NovaTech deje de operar una hora, y mientras no existan, cualquier plan de recuperación está incompleto por definición.

**Lo que recomiendo como siguiente paso**, en orden de prioridad. Primero, definir esas dos cifras con la dirección. Segundo, evaluar la replicación hacia un segundo sitio, que es lo único que resuelve la pérdida del datacenter. Y tercero, algo que no cuesta infraestructura: **repetir el drill periódicamente.** Un plan de recuperación que se probó una vez y quedó documentado se degrada, porque el clúster cambia y el plan no. Propuse que el drill se ejecute cada trimestre y que su resultado quede registrado.

Cierro con la observación que considero más importante de todo el hito: **la preparación ante desastres no se mide por la calidad del documento, sino por la última vez que se probó.** Mi plan vale porque lo ejecuté, y valdrá menos cada mes que pase sin volver a hacerlo.

---
---

# Lo que estos ejemplos tienen en común

Si te fijas, las seis respuestas siguen la misma estructura:

1. **La decisión, dicha de frente** en la primera línea
2. **El razonamiento**, incluyendo qué se descartó y por qué
3. **La evidencia que lo respalda**, nombrando el archivo concreto
4. **Una limitación o consecuencia operacional**, dicha con honestidad

Ese cuarto punto es el que más suma. **Una respuesta que reconoce lo que no cubre demuestra más criterio que una que asegura que todo está resuelto.**
