# Parte 2: Mapeo arquitectónico

## Objetivo

Crear un diagrama visual de la arquitectura del clúster NovaTech, identificando cada componente y las relaciones entre ellos. Este ejercicio te ayudará a consolidar tu comprensión de cómo se distribuyen los datos en un clúster Kafka.

## Contexto

Tu jefe de equipo te ha pedido que documentes la arquitectura actual del clúster antes de la próxima reunión de revisión. Necesita un diagrama claro que cualquier miembro del equipo pueda entender.

---

## Instrucciones

### Opción A: Usar draw.io (recomendado)

1. Abre el archivo `plantillas/diagrama-cluster-blanco.drawio` en [diagrams.net](https://app.diagrams.net/) (puedes abrirlo localmente o arrastrarlo al navegador)

2. El diagrama tiene elementos pre-posicionados que debes completar. Usa la información que recopilaste en la Parte 1.

### Opción B: En papel

Si no puedes usar draw.io, dibuja el diagrama en papel y toma una foto para incluirla en tu reporte.

---

## Elementos que debe incluir tu diagrama

Completa el diagrama con la siguiente información:

### 1. Brokers y controlador

- Identifica los 3 brokers por su `node.id` (1, 2, 3)
- Marca cuál es el **controlador activo** del quorum KRaft (usa el resultado de `check-quorum.sh`)
- Indica el puerto externo de cada broker

### 2. Tópico y particiones

- Dibuja el tópico `novatech.fleet.gps` con sus **6 particiones** (P0 a P5)
- Asigna cada partición al broker que es su **líder** actual (usa los datos de `describe-topics.sh`)

### 3. Réplicas

- Para cada partición, marca dónde están las **réplicas seguidoras**
- Usa la información de ISR (In-Sync Replicas) para verificar que todas están sincronizadas
- Leyenda de colores:
  - **Verde**: Partición líder
  - **Azul**: Réplica ISR (sincronizada)
  - **Rojo**: Réplica fuera de sincronización (no debería haber ninguna en este momento)

### 4. Productor

- Dibuja el productor GPS (`gps-producer`)
- Muestra con flechas hacia qué particiones envía datos
- **Nota sobre partitioner**: el productor no especifica clave, así que Kafka usa el partitioner por defecto. Desde Kafka 2.4 (KIP-480) el default es **StickyPartitioner**, NO round-robin: el cliente "se pega" a una partición hasta llenar el batch o que venza `linger.ms`, y recién ahí cambia. Como nuestro productor envía 1 evento cada ~2 segundos (rate bajo), no llena batches y se queda mucho tiempo en una sola partición. Por eso al inspeccionar el topic con `kafka-log-dirs` vas a ver una partición con casi todos los datos y las demás con 0 — no es un bug, es StickyPartitioner. Para que se distribuya entre particiones se necesitaría: (a) usar una clave de partición, o (b) generar volumen suficiente para llenar batches.

### 5. Consumidor

- Dibuja el grupo de consumidores `lab01-explorer`
- Muestra qué particiones tiene asignadas

### 6. Kafbat UI

- Incluye Kafbat UI como un componente de visualización que se conecta a los brokers para mostrar tópicos, particiones, mensajes y consumer groups

---

## Ejemplo de distribución

Tu diagrama debería verse similar a este esquema (los líderes pueden variar):

```
┌─────────────────────────────────────────────────────────┐
│                   Clúster NovaTech                       │
│                                                          │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│  │ Broker 1 │    │ Broker 2 │    │ Broker 3 │           │
│  │ :9092    │    │ :9093    │    │ :9094    │           │
│  │          │    │          │    │  ★ ctrl  │           │
│  │ P0(L)    │    │ P0(R)    │    │ P0(R)    │           │
│  │ P1(R)    │    │ P1(L)    │    │ P1(R)    │           │
│  │ P2(R)    │    │ P2(R)    │    │ P2(L)    │           │
│  │ P3(L)    │    │ P3(R)    │    │ P3(R)    │           │
│  │ P4(R)    │    │ P4(L)    │    │ P4(R)    │           │
│  │ P5(R)    │    │ P5(R)    │    │ P5(L)    │           │
│  └──────────┘    └──────────┘    └──────────┘           │
│       ▲               ▲               ▲                  │
│       │               │               │                  │
│  ┌────┴───────────────┴───────────────┴────┐            │
│  │          gps-producer (round-robin)      │            │
│  └──────────────────────────────────────────┘            │
│                                                          │
│  L = Líder    R = Réplica ISR    ★ = Controlador        │
└─────────────────────────────────────────────────────────┘
```

> **Nota**: La distribución de líderes en tu clúster puede ser diferente a este ejemplo. Usa los datos reales que observaste.

---

## Preguntas de reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Los líderes están distribuidos equitativamente entre los brokers? | |
| ¿Qué ventaja tiene tener réplicas en diferentes brokers? | |
| ¿Qué pasaría con las particiones si el broker controlador cayera? | |

---

## Siguiente paso

Continúa con la [Parte 3: Tolerancia a fallos](03-tolerancia-fallos.md).
