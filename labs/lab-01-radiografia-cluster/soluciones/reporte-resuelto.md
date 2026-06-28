# Lab 01 — Reporte resuelto (solución de referencia)

> **⚠ Importante**: estas son las soluciones de referencia del lab.
> Antes de consultarlas, intenta resolver cada actividad por tu cuenta.
> El aprendizaje real está en pelearte con el problema. Estas respuestas
> son para validar tu trabajo o destrabarte después de intentarlo.
>
> Algunos valores específicos (IDs, timestamps, números de partición
> que actúan como líder) pueden variar entre ejecuciones — lo importante
> es la consistencia conceptual.

## Datos del alumno

| Campo | Valor |
|-------|-------|
| **Nombre** | [Solución de referencia] |
| **Fecha** | [Fecha de ejecución] |
| **Sección** | N/A |

---

## Sección 1: Componentes del clúster

| Componente | Imagen Docker | Puerto externo | Rol / Función |
|-----------|--------------|----------------|---------------|
| kafka-broker-1 | confluentinc/cp-kafka:8.2.0 | 9092 | Broker y controlador KRaft (almacena datos, participa en quorum) |
| kafka-broker-2 | confluentinc/cp-kafka:8.2.0 | 9093 | Broker y controlador KRaft (almacena datos, participa en quorum) |
| kafka-broker-3 | confluentinc/cp-kafka:8.2.0 | 9094 | Broker y controlador KRaft (almacena datos, participa en quorum) |
| kafbat-ui | ghcr.io/kafbat/kafka-ui | 8090 | Interfaz web open-source para visualizar el clúster (brokers, tópicos, mensajes) |
| gps-producer | confluentinc/cp-kafka:8.2.0 | N/A | Productor que genera datos GPS simulados de la flota NovaTech |

### Controlador KRaft

| Dato | Valor |
|------|-------|
| Leader ID | Varía (1, 2 o 3) - El primer broker que completa la elección |
| Votantes | 1, 2, 3 (los tres brokers participan en el quorum) |
| Epoch actual | Depende de cuántas elecciones han ocurrido (generalmente 1 en un inicio limpio) |

---

## Sección 2: Distribución de particiones

> Los líderes y réplicas varían según la ejecución. Ejemplo típico:

| Partición | Broker líder | Réplicas | ISR | ¿Todas sincronizadas? |
|-----------|-------------|----------|-----|----------------------|
| 0 | 1 | 1,2,3 | 1,2,3 | Sí |
| 1 | 2 | 2,3,1 | 2,3,1 | Sí |
| 2 | 3 | 3,1,2 | 3,1,2 | Sí |
| 3 | 1 | 1,3,2 | 1,3,2 | Sí |
| 4 | 2 | 2,1,3 | 2,1,3 | Sí |
| 5 | 3 | 3,2,1 | 3,2,1 | Sí |

### Análisis de distribución

- ¿Los líderes están balanceados? **Sí, Kafka distribuye los líderes equitativamente entre los brokers disponibles**
- Particiones por broker (ejemplo):
  - Broker 1: 2 particiones líder
  - Broker 2: 2 particiones líder
  - Broker 3: 2 particiones líder

---

## Sección 3: Tolerancia a fallos

### Estado ANTES de la caída

(Mismos valores que la Sección 2 - todas las particiones con 3 réplicas en ISR)

### Estado DESPUÉS de la caída (Broker 2 detenido)

> Los valores son ilustrativos. Lo clave es que:
> - Las particiones que lideraba el Broker 2 ahora son lideradas por otro broker
> - El ISR de todas las particiones se reduce a 2 (los brokers que siguen activos)

| Partición | Líder | ISR |
|-----------|-------|-----|
| 0 | 1 | 1,3 |
| 1 | 3 (era 2) | 3,1 |
| 2 | 3 | 3,1 |
| 3 | 1 | 1,3 |
| 4 | 1 (era 2) | 1,3 |
| 5 | 3 | 3,1 |

Controlador activo: Si era el 2, cambia a 1 o 3. Si no era el 2, permanece igual.

### Estado DESPUÉS de la recuperación

- Las ISR vuelven a incluir al Broker 2 (tres brokers en cada ISR)
- El Broker 2 **generalmente no recupera el liderazgo automáticamente** (depende de la configuración `auto.leader.rebalance.enable`)
- El quorum vuelve a tener 3 votantes activos

### Observaciones

- ¿El productor GPS siguió funcionando? **Sí, el productor se reconectó a los brokers disponibles**
- ¿Se perdieron mensajes? **No, con `min.insync.replicas=2` y 2 brokers activos, el productor pudo seguir escribiendo**
- ¿El broker recuperado volvió a ser líder? **Generalmente no de inmediato, pero sí vuelve al ISR**
- Tiempo de resincronización: **Generalmente entre 10-30 segundos para el volumen de datos de este lab**

---

## Sección 4: Conclusiones

### ¿Qué aprendí sobre la arquitectura de Kafka?

> Kafka distribuye los datos de un tópico en múltiples particiones, y cada partición se replica en varios brokers. Este diseño permite tanto el paralelismo (múltiples particiones) como la durabilidad (múltiples réplicas). El modo KRaft elimina la dependencia de ZooKeeper, usando un quorum integrado para la gestión de metadatos.

### ¿Qué aprendí sobre la tolerancia a fallos?

> Kafka puede tolerar la caída de un broker sin pérdida de datos ni interrupción del servicio, siempre que haya suficientes réplicas sincronizadas (ISR). La elección de nuevos líderes es automática y rápida. El broker recuperado se resincroniza automáticamente.

### ¿Qué rol juegan las réplicas ISR?

> Las réplicas ISR (In-Sync Replicas) son copias de una partición que están completamente sincronizadas con el líder. Cuando el líder cae, solo una réplica ISR puede ser elegida como nuevo líder, garantizando que no se pierdan datos confirmados. El parámetro `min.insync.replicas` controla cuántas réplicas deben confirmar una escritura.

---

## Sección 5: Desafío extra

### Reto 1: Volumen de datos

| Dato | Valor |
|------|-------|
| Bytes totales | Varía según el tiempo de ejecución (~varios KB por minuto) |
| Comando | `docker exec kafka-broker-1 kafka-log-dirs --bootstrap-server kafka-broker-1:29092 --describe --topic-list novatech.fleet.gps` |

### Reto 2: Distribución de datos

| Dato | Valor |
|------|-------|
| Diferencia entre particiones | Debería ser relativamente uniforme |
| Hipótesis | El productor no especifica clave de partición, por lo que Kafka usa el particionador sticky por defecto, que distribuye de manera aproximadamente uniforme, aunque puede haber ligeras variaciones por el batching |

### Reto 3: Kafbat UI

| Dato | Valor |
|------|-------|
| Brokers visibles | 3 (broker-1, broker-2, broker-3) |
| Controlador KRaft | Varía (1, 2 o 3, el primero electo) |
| Particiones del tópico GPS | 6 |
| Throughput | ~0.5 mensajes/segundo (1 mensaje cada 2 segundos) |
| Consumer group `lab01-explorer` | Aparece si el alumno ya consumió mensajes |

---

*Solución de referencia - Lab 01*
