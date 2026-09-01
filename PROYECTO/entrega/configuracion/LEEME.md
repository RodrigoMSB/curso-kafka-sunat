# El clúster del proyecto

En esta carpeta está el `docker-compose.yml` con el que levantas el clúster de
tu proyecto final. **Cópialo, levántalo y ya está.** No tienes que editar nada.

---

## Qué levanta

**Tres brokers en KRaft, en modo combinado.** Cada nodo es broker y controlador
a la vez, así que el quórum son esos mismos tres. Es el dimensionamiento que el
hito 2 te pide demostrar.

| | |
|---|---|
| Brokers | `proyecto-broker-1`, `proyecto-broker-2`, `proyecto-broker-3` |
| Puertos desde tu máquina | `9192`, `9193`, `9194` |
| Puertos dentro de la red del clúster | `29192`, `29193`, `29194` |
| Identidad del clúster | ya viene puesta |
| Factor de replicación por defecto | 3 |
| `min.insync.replicas` | 2 |

**La identidad del clúster ya está en el archivo.** Generarla es la lección del
laboratorio 01 y aquí no toca repetirla. Si quieres contar en tu expediente cómo
se genera, el comando es `kafka-storage random-uuid`.

---

## Cómo se levanta

Desde esta carpeta.

```bash
docker compose up -d --wait
```

El `--wait` es la parte útil. Sin él el comando vuelve enseguida y los brokers
todavía están arrancando, así que el primer comando que corras falla y parece
que algo está roto. Con `--wait` el prompt vuelve cuando los tres están
respondiendo de verdad.

**Comprueba que el quórum se formó.**

```bash
docker exec proyecto-broker-1 kafka-metadata-quorum \
    --bootstrap-server proyecto-broker-1:29192 describe --status
```

Tienen que salir los tres en `CurrentVoters` y un `LeaderId` con número. Esa
salida es, tal cual, la evidencia 1 del hito 2.

---

## Cómo se baja

```bash
docker compose down
```

**Tus datos no se borran.** Quedan en los volúmenes de Docker y vuelven a estar
ahí la próxima vez que lo levantes, con la misma identidad de clúster y los
mismos tópicos.

**Si quieres empezar de cero**, y solo entonces:

```bash
docker compose down -v
```

Ese `-v` sí borra los volúmenes. Los tópicos que hayas creado y los mensajes que
tengan se pierden. **Si ya recolectaste evidencias, guárdalas antes.**

---

## Convive con los laboratorios

Puedes tener un laboratorio del curso levantado y este clúster al mismo tiempo.
**No se pisan.** Probado levantando los dos a la vez y bajando cada uno con el
otro arriba.

Está resuelto en tres frentes.

**Los puertos.** Los quince laboratorios usan `8081`, `8082`, `8083`, `8088`,
`8090`, `9092`, `9093`, `9094`, `9095`, `15432`, `19092`, `19093` y `19094`. El
proyecto usa `9192`, `9193` y `9194`, que no están en esa lista. La regla para
acordarse es que los del proyecto llevan un uno en las centenas.

**Los nombres de contenedor.** Los labs usan `kafka-broker-1` y compañía. El
proyecto usa `proyecto-broker-1` y compañía. Ningún nombre se repite, así que
nunca vas a ver el `Conflict: container name already in use`.

**El nombre de proyecto de compose.** Los labs se llaman `novatech-lab05`,
`novatech-lab12` y así. Cuando arrancas un laboratorio, su script limpia los
contenedores de **otros labs** para que no se acumulen, y busca justamente los
que empiezan por `novatech-lab`. Este clúster se llama `novatech-proyecto`, que
no empieza por ahí. **Por eso arrancar un lab no se lleva tu proyecto por
delante.**

---

## Declara el origen

Esto es material de apoyo que te damos armado. **Dilo en tu expediente**, en la
sección 8, y no pierdas puntos por algo que no los quita.

Marca lo que corresponda:

- [ ] Lo usé tal cual
- [ ] Partí de este archivo y le hice cambios propios
- [ ] Armé el mío desde la plantilla del laboratorio 02

**Si le hiciste cambios, dilos aquí:**

[…]

**Y si le hiciste cambios, este archivo es el que va en tu ZIP**, no el que
te dimos. Lo que se evalúa es que entiendas qué hace cada línea.

---

## Las otras tres carpetas

`hito-2-kraft/`, `hito-3-multibroker/` y `hito-4-seguridad/` están para los
archivos de configuración que armes tú. **Si usaste este clúster tal cual para
los hitos 2 y 3, no tienes que copiar nada ahí**: basta con este archivo y la
declaración de arriba. El hito 4 sí pide configuración propia, porque la
seguridad la montas tú.
