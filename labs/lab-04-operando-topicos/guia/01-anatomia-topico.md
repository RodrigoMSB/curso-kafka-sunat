# Parte 1: Anatomía de un tópico

## Objetivo

Entender qué hay realmente "dentro" de un tópico Kafka: particiones, líderes, ISR, configuraciones efectivas, segmentos en disco.

## Contexto

Los Labs anteriores trabajaron con tópicos como cajas negras: produces, consumes, listo. En este lab te vuelves su DBA: vas a inspeccionar, configurar y modificar tópicos.

---

## Actividad 1: Inventario inicial

Lista los tópicos existentes en tu clúster:

```bash
kafka-cli/list-topics.sh
```

Y ahora con los tópicos internos visibles:

```bash
kafka-cli/list-topics.sh --internal
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cuántos tópicos visibles aparecen sin `--internal`? | |
| ¿Cuántos aparecen con `--internal`? | |
| ¿Qué tópicos internos detectas? (ej: `__consumer_offsets`) | |
| ¿Para qué crees que sirve `__consumer_offsets`? | |

---

## Actividad 2: Anatomía completa

Describe el tópico GPS que viene del Lab 01:

```bash
kafka-cli/describe-topic.sh novatech.fleet.gps
```

La salida tiene **2 secciones**:
1. **Particiones, líderes y réplicas** (estructura)
2. **Configuraciones efectivas** (parámetros)

### Anota la estructura

| Atributo | Valor |
|----------|-------|
| Número de particiones | |
| Replication factor | |
| Líder de la partición 0 | |
| ISR de la partición 0 | |
| ¿Hay réplicas fuera de sincronía (Out-of-Sync)? | |

### Anota 5 configuraciones efectivas que te llamen la atención

| Config | Valor | ¿Es DEFAULT, DYNAMIC o STATIC? |
|--------|-------|--------------------------------|
| | | |
| | | |
| | | |
| | | |
| | | |

> **Pista**: el campo `ConfigSource` indica de dónde viene cada config:
> - `DEFAULT_CONFIG`: valor por defecto del broker
> - `STATIC_BROKER_CONFIG`: definido en `server.properties` del broker
> - `DYNAMIC_TOPIC_CONFIG`: override aplicado al tópico vía `--alter`

---

## Actividad 3: Inspección visual con Kafbat UI

Abre **http://localhost:8090** > **Topics** > `novatech.fleet.gps` > pestaña **Settings**.

Compara la información visual con la salida CLI de la Actividad 2.

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La UI muestra la misma información? | |
| ¿Ves alguna config en la UI que no salió por CLI? | |
| ¿Qué te resulta más cómodo: CLI o UI? ¿Por qué? | |

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Inventario de tópicos | Listaste con y sin internos |
| Estructura de particiones | Vista líder, ISR y réplicas |
| Jerarquía de configs | DEFAULT vs STATIC vs DYNAMIC |
| CLI vs UI | Comparaste ambas vistas |

---

## Siguiente paso

Continúa con [Parte 2: Tópicos con personalidad](02-topicos-con-personalidad.md).
