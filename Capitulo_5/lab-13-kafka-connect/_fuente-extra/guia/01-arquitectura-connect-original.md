# Parte 1: Arquitectura de Kafka Connect

## Objetivo

Entender qué es Kafka Connect, sus componentes (Connectors, Tasks, Workers), y la diferencia entre los modos **standalone** y **distributed**.

## Contexto

Hasta ahora todos los datos los produciste manualmente con `kafka-console-producer` o el `gps-producer` simulado. En la realidad, los datos vienen de **sistemas externos**: bases de datos, APIs, archivos. Escribir código de integración para cada sistema es lento y propenso a errores.

**Kafka Connect** resuelve esto: framework declarativo de integración. Tú declaras "quiero conectar PostgreSQL con Kafka" y Connect hace el resto.

---

## Componentes clave

```
┌───────────────────────────────────────────────────────────────────┐
│                     Arquitectura de Kafka Connect                  │
│                                                                    │
│   [PostgreSQL]                                       [PostgreSQL]  │
│     pedidos                                       pedidos_procesados│
│        ↓                                                  ↑        │
│   [JDBC Source] →→→ [Kafka Connect Worker] →→→ [Tópicos] →→→ [JDBC Sink]│
│                     (cluster distributed)                          │
│                            ↕                                       │
│                     [REST API :8083]                               │
│                            ↑                                       │
│                      [curl / Kafbat UI]                            │
└───────────────────────────────────────────────────────────────────┘
```

- **Connector**: definición declarativa (JSON) de QUÉ conectar
- **Task**: unidad de ejecución paralela. Un connector puede tener N tasks
- **Worker**: proceso JVM que ejecuta tasks. Vive en un contenedor

---

## Modos: Standalone vs Distributed

| Aspecto | Standalone | Distributed |
|---------|-----------|-------------|
| Workers | 1 | Cluster (N workers) |
| Configuración | Archivo properties | REST API |
| Tolerancia a fallos | No (single point of failure) | Sí (rebalanceo automático) |
| Caso de uso | Desarrollo, demos | Producción |
| Estado | En archivos locales | En tópicos `_connect-*` de Kafka |

**Este lab usa modo distributed** (aunque tenemos solo 1 worker, el modo es distributed para que veas cómo se hace en producción).

---

## Actividad 1: Verificar que Connect responde

```bash
curl -s http://localhost:8083/
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué versión de Kafka Connect responde? | |
| ¿Qué `kafka_cluster_id` muestra? | |

---

## Actividad 2: Listar plugins disponibles

```bash
curl -s http://localhost:8083/connector-plugins | python3 -m json.tool
```

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece `JdbcSourceConnector`? | |
| ¿Aparece `JdbcSinkConnector`? | |
| ¿Cuántos plugins en total? | |

---

## Actividad 3: Listar conectores activos (debería estar vacío)

```bash
connect-cli/list-connectors.sh
```

Esperado: `[]` (lista vacía).

---

## Actividad 4: Tópicos internos de Connect

```bash
kafka-cli/list-topics.sh --internal | grep _connect
```

Deberían aparecer: `_connect-configs`, `_connect-offsets`, `_connect-status`.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Para qué sirve cada tópico? | |
| ¿Qué pasa si Connect cae y se reinicia? | |

> **Pista**: estos tópicos son cómo Connect persiste su estado. Al reiniciar, lee de ellos para restablecer connectors y offsets.

---

## Actividad 5: Inspeccionar Kafka Connect en Kafbat UI

Abre **http://localhost:8090** > pestaña **Kafka Connect**.

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece el cluster `connect-novatech`? | |
| ¿Cuántos workers ves? | |
| ¿Qué información ofrece esta pestaña? | |

---

## Conclusiones

| Concepto | Lo aprendiste explorando... |
|----------|----------------------------|
| Connect es declarativo | Defines qué conectar, no cómo |
| Modo distributed | Configuración via REST API |
| Tópicos `_connect-*` | Persistencia automática del estado |
| Plugins | JDBC, S3, MongoDB, Elasticsearch, etc. |

---

## Siguiente paso

Continúa con [Parte 2: Source connector JDBC](02-source-jdbc.md).
