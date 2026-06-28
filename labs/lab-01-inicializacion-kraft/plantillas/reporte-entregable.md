# Reporte del Lab 03: Construye tu propio clúster KRaft

## Datos del alumno

| Campo | Valor |
|-------|-------|
| Nombre | |
| Fecha | |
| Sección | |

---

## Parte 1: Anatomía de la imagen Confluent

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué binarios CLI encuentras en `/usr/bin/` que empiecen por `kafka-`? Lista 5. | |
| ¿En qué directorio están los archivos de configuración de ejemplo? | |
| ¿Cuál es el contenido aproximado del archivo `server.properties` de ejemplo? | |
| ¿Qué versión de Java trae la imagen? (pista: `java -version`) | |

---

## Parte 2: Mi primer broker solitario

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuál fue el CLUSTER_ID que generaste? | |
| ¿Qué pasó cuando intentaste levantar el broker SIN haber formateado el storage? | |
| ¿Qué hace exactamente `kafka-storage format`? | |
| ¿Por qué el `replication.factor` debe ser 1 con un solo broker? | |
| ¿Qué comando usaste para verificar que el broker está vivo? | |

---

## Parte 3: Creciendo a 3 brokers

### Configuración del quorum

Pega aquí el valor exacto de `KAFKA_CONTROLLER_QUORUM_VOTERS`:

```
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué los 3 brokers deben compartir el mismo CLUSTER_ID? | |
| ¿Por qué cada broker tiene un puerto CONTROLLER distinto (39092/39093/39094)? | |
| ¿Cuál de los 3 brokers fue elegido como Active Controller? | |
| ¿En base a qué criterio crees que se eligió? | |

---

## Parte 4: Chequeo de salud KRaft

### Salida de `bin/check-quorum.sh`

Pega aquí (resumido):

```
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos voters muestra el quorum? | |
| ¿Cuál es el LeaderId actual? | |
| ¿Qué significa "Lag"? ¿Qué pasaría si fuera muy alto? | |
| ¿Para qué sirve `--replication` en este comando? | |

---

## Parte 5: Desafío - Listeners separados (opcional)

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué pasaría si los 3 listeners (PLAINTEXT, CONTROLLER, EXTERNAL) compartieran el mismo puerto? | |
| ¿Por qué `EXTERNAL` se anuncia con `localhost` y no con `kafka-broker-1`? | |
| ¿Qué problema operacional resuelve tener `INTER_BROKER_LISTENER_NAME` distinto al CONTROLLER? | |

---

## Conclusiones generales

Resume en 3-5 frases lo que aprendiste construyendo tu propio clúster KRaft:

```


```

---

*Lab 03 - Curso de Administración de Apache Kafka con Confluent Platform*
