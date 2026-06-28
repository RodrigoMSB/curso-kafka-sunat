# Parte 2: Mi primer broker solitario

## Objetivo

Construir desde cero un `docker-compose.yml` que levante **un solo broker Kafka** en modo KRaft. Aprender a generar el CLUSTER_ID, formatear el storage y validar que el broker responde.

## Contexto

Vas a crear el archivo desde una plantilla con TODOs. La idea es que entiendas **cada variable**, no que copies y pegues.

---

## Actividad 1: Generar tu CLUSTER_ID

Cada clúster Kafka tiene un identificador único. Genera el tuyo:

```bash
kafka-cli/generate-cluster-id.sh
```

Verás algo como:
```
    abc123XyZ_FAKE_id_def456
```

**Cópialo y guárdalo**. Lo vas a usar en el siguiente paso.

> **Pregunta**: ¿qué pasa si dos brokers del mismo clúster tienen CLUSTER_IDs distintos? (lo experimentarás después)

---

## Actividad 2: Crear tu docker-compose.yml

Copia la plantilla a tu carpeta de trabajo:

```bash
cp plantillas/docker-compose-1-broker.template.yml mi-cluster/docker-compose.yml
```

Abre `mi-cluster/docker-compose.yml` en tu editor y **completa todos los `{{TODO_*}}`**:

### Tabla de pistas

| TODO | Pista | Valor sugerido |
|------|-------|---------------|
| `{{TODO_VERSION}}` | La versión de la imagen | `8.2.0` |
| `{{TODO_HOST_PORT}}` | Puerto que expones a tu Mac | `9092` |
| `{{TODO_NODE_ID}}` | Identificador único | `1` |
| `{{TODO_ROLES}}` | Roles del nodo | `broker,controller` |
| `{{TODO_QUORUM_VOTERS}}` | Lista de voters | `1@kafka-broker:39092` |
| `{{TODO_LISTENERS}}` | Endpoints donde escucha | `PLAINTEXT://kafka-broker:29092,CONTROLLER://kafka-broker:39092,EXTERNAL://0.0.0.0:9092` |
| `{{TODO_ADV_LISTENERS}}` | Cómo se anuncia a clientes | `PLAINTEXT://kafka-broker:29092,EXTERNAL://localhost:9092` |
| `{{TODO_PROTOCOL_MAP}}` | Mapa de listener → protocolo | `PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT` |
| `{{TODO_CTRL_NAMES}}` | Nombre del listener de control | `CONTROLLER` |
| `{{TODO_INTER_BROKER}}` | Listener entre brokers | `PLAINTEXT` |
| `{{TODO_CLUSTER_ID}}` | El CLUSTER_ID que generaste | `<el tuyo>` |
| `{{TODO_RF_OFFSETS}}` | Replication factor del tópico interno de offsets. Con 1 broker no puede ser mayor a 1 | `1` |
| `{{TODO_RF_TXN}}` | Lo mismo para transactions | `1` |
| `{{TODO_RF_DEFAULT}}` | Replication factor por defecto | `1` |

---

## Actividad 3: Levantar el broker

```bash
cd mi-cluster
docker compose up -d
```

Espera ~10 segundos, luego verifica:

```bash
docker ps
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El contenedor está en estado `running`? | |
| Si NO, ¿qué dice `docker logs kafka-broker`? | |

> **Si ves error tipo `Cluster ID is required`**: significa que el broker no encontró meta.properties. La imagen Confluent normalmente formatea solo la primera vez si pasas CLUSTER_ID por env, pero si falla, ejecuta:
>
> ```bash
> docker exec kafka-broker kafka-storage format \
>     --cluster-id <TU_CLUSTER_ID> \
>     --config /etc/kafka/kafka.properties \
>     --ignore-formatted
> docker compose restart
> ```

---

## Actividad 4: Validar que el broker está vivo

Desde la raíz del lab:

```bash
docker exec kafka-broker kafka-broker-api-versions \
    --bootstrap-server kafka-broker:29092
```

Si ves un listado largo de APIs y versiones, **tu broker está vivo**. 🎉

---

## Actividad 5: Crear un tópico de prueba

```bash
docker exec kafka-broker kafka-topics \
    --bootstrap-server kafka-broker:29092 \
    --create --topic test-solitario \
    --partitions 1 --replication-factor 1
```

```bash
docker exec kafka-broker kafka-topics \
    --bootstrap-server kafka-broker:29092 \
    --list
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos tópicos aparecen? | |
| ¿Qué pasaría si intentas crear el tópico con `--replication-factor 3` en este clúster de 1 solo broker? Pruébalo. | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| CLUSTER_ID | Lo generaste y lo usaste como identidad del clúster |
| docker-compose para Kafka KRaft | Completaste la plantilla con tus propias manos |
| Storage formatting | Vista la primera vez que se levanta |
| Replication factor mínimo | Probaste a poner 3 con 1 broker |

---

## Siguiente paso

Detén tu broker antes de continuar (vamos a expandirlo a 3):

```bash
cd mi-cluster
docker compose down -v
```

Luego, [Parte 3: Creciendo a tres brokers](03-creciendo-a-tres-brokers.md).
