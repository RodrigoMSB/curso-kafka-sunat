# Lab 14 · PASOS

> El recorrido en seco. Aquí están los comandos en orden y los huecos que tú
> rellenas mientras corren. **La explicación de por qué hace cada cosa está en
> la guía** — `guia/01-seguridad-y-lo-que-rechaza.md`. Este archivo es para
> tener a mano en la terminal, no para reemplazarla.

**Antes de empezar:** `bin/start-lab.sh` terminado (tarda **19 segundos
medidos**, y en ellos genera la PKI entera), con los 3 brokers escuchando
SASL_SSL en 9092, 9093 y 9094.

**Cuánto toma:** **24 segundos medidos**, en 5 comandos.

🔴 **Dos de los cinco comandos tienen que fallar.** Si alguno de esos dos
funcionara, el clúster estaría roto. Ve anotando *qué* error sale, no *si* sale
error.

---

## Paso 1 · Las reglas, escritas

```bash
kafka-cli/list-acls.sh
```

Rellena la tabla leyendo la salida. 🔴 **Fíjate sobre todo en las casillas
vacías:**

| Recurso | ¿Aparece `app1`? | ¿Aparece `app2`? |
|---|---|---|
| `novatech.lab12.publico` | | |
| `novatech.lab12.confidencial` | | |
| `GROUP` (el recurso `*`) | | |

| Pregunta | Tu respuesta |
|---|---|
| ¿Hay alguna regla que **niegue** algo a `app2`? | |
| Entonces, ¿qué protege al tópico confidencial de `app2`? | |
| ¿Para qué crees que sirve el bloque de `GROUP`? | |

---

## Paso 2 · El que no tiene llave

🔴 **Predice antes de ejecutar:**

| Predicción | Tu respuesta |
|---|---|
| ¿Qué mensaje crees que va a devolver el clúster? | |

```bash
kafka-cli/attempt-no-auth.sh
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué excepción salió? | |
| ¿Dijo el clúster «no autorizado»? | |
| ¿Nombró algún tópico? | |
| ¿Llegó a haber conversación con el clúster? | |

**La pregunta del paso:** el error habla de memoria (`OutOfMemoryError`), no de
credenciales. ¿Qué le pasó realmente al cliente? *(Pista: ¿qué le contesta un
puerto que solo entiende TLS a alguien que le habla en claro?)*

---

## Paso 3 · El que tiene llave pero no permiso

🔴 **Predice antes de ejecutar:**

| Predicción | Tu respuesta |
|---|---|
| ¿El error se va a parecer al del Paso 2? | |

```bash
kafka-cli/consume-confidencial-app2.sh
```

| Hueco | Lo que salió |
|---|---|
| ¿Qué excepción salió? | |
| ¿Nombró el tópico? | |
| Última línea (`Processed a total of ___ messages`) | |

**Ahora compara los dos pasos, que es el ejercicio central del laboratorio:**

| | Paso 2 · sin credenciales | Paso 3 · `app2` |
|---|---|---|
| ¿Hubo conversación? | | |
| ¿El clúster dijo por qué? | | |
| ¿Nombró el recurso? | | |
| Qué error salió | | |
| **Qué falló: autenticación o autorización** | | |

**La pregunta del paso:** en el Paso 3 el clúster le negó algo a `app2` **por
nombre**. ¿Qué tuvo que saber el clúster antes de poder negárselo?

---

## Paso 4 · La misma llave, otra puerta

```bash
kafka-cli/consume-publico.sh
```

| Hueco | Lo que salió |
|---|---|
| ¿Apareció algún mensaje? | |
| ¿Aparece la palabra `ERROR` en la salida? | |
| Última línea (`Processed a total of ___ messages`) | |

🔴 **Ojo con esta salida: trae `ERROR` y sin embargo funcionó.** Ese
`TimeoutException` del final es el `--timeout-ms` cumpliéndose. Sale en los
cuatro comandos del lab, en los que funcionan y en los que no.

> **La regla de lectura de este laboratorio:** no mires la palabra `ERROR`. Mira
> **cuál** es el error, y mira **la última línea**.

Y el último:

```bash
kafka-cli/consume-confidencial-admin.sh
```

| Hueco | Lo que salió |
|---|---|
| Última línea | |
| ¿Aparece `admin` en alguna ACL del Paso 1? | |
| Entonces, ¿por qué pudo leer? | |

**La tabla que cierra el laboratorio.** Rellénala con las últimas líneas:

| Usuario | Tópico | `Processed a total of ___` |
|---|---|---|
| `app2` | confidencial | |
| `app2` | **publico** | |
| `admin` | confidencial | |

**La pregunta del paso:** las dos primeras filas usan **las mismas
credenciales** y **el mismo comando**. ¿Qué prueba eso sobre lo que falló en el
Paso 3?

---

## Cierre · Las tres preguntas del laboratorio

**1 · Un proveedor te dice que su clúster «es seguro» y te lo demuestra
produciendo y consumiendo un mensaje. ¿Qué dos pruebas le pides tú?**

**2 · Te llega un ticket: «la aplicación no puede leer el tópico». ¿Cómo
distingues, mirando solo el error, si el problema es la credencial o el
permiso? ¿Y por qué eso cambia a quién le pasas el ticket?**

**3 · En tu clúster de producción, ¿cuántos sistemas se conectan con el usuario
super user, y qué pasaría si uno de ellos tuviera un error de programación?**

---

> **Lo que sigue** — la PKI que el `start-lab.sh` generó, escribir una ACL a
> mano y verla surtir efecto sin reiniciar nada, el drill de failover con un
> broker caído y el capstone automatizado están listados en la sección
> **PARA PROFUNDIZAR** de la guía, con su comando completo y su salida medida.
