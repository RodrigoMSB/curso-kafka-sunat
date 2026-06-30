# Parte 4: Quitar un broker (drenaje) y desafío

## Objetivo

Sacar de servicio un broker sin perder datos: primero drenar sus particiones, luego apagarlo.

## Contexto

Pasó el pico. NovaTech quiere devolver el broker 4 para ahorrar costos. **Apagarlo en seco perdería las réplicas que tiene**: primero hay que mover sus particiones a los brokers que se quedan.

---

## Actividad 1: Drenar el broker 4

Mueve todas las particiones del tópico de vuelta a los brokers 1, 2 y 3:

```bash
kafka-cli/drain-broker.sh novatech.lab08.pedidos 1,2,3
```

Verifica que el broker 4 ya no tiene particiones:

```bash
kafka-cli/describe-topic.sh novatech.lab08.pedidos
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El broker 4 quedó sin particiones asignadas? | |
| ¿Por qué hay que drenar ANTES de apagar? | |

---

## Actividad 2: Apagar el broker 4

Ya drenado, se puede detener sin riesgo:

```bash
docker compose -f infra/docker-compose.yml --profile scale stop kafka-broker-4
```

Confirma que el clúster sigue sano con 3 brokers:

```bash
kafka-cli/list-brokers.sh
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El clúster sigue operativo con 3 brokers? | |
| ¿El quórum de controladores se vio afectado? ¿Por qué no? | |

---

## Desafío

NovaTech quiere una prueba de fuego. Con productores corriendo en segundo plano (`produce-sample.sh` con un número grande), ejecuta un ciclo completo:

1. Agrega el broker 4.
2. Reasigna a los 4 brokers.
3. Cambia `num.replica.fetchers=2` en caliente en el broker 4.
4. Drena el broker 4 y apágalo.

Documenta en el reporte: ¿hubo alguna pérdida de mensajes o error de producción en todo el ciclo? ¿Cuál fue el paso más lento?

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Tipos de configuración | Clasificaste read-only vs dinámica con `describe-broker-config` |
| Reconfiguración en caliente | Cambiaste configs per-broker y cluster-wide sin reiniciar |
| Escalado horizontal | Agregaste el broker 4 y reasignaste particiones |
| Drenaje seguro | Moviste réplicas antes de apagar el broker |
| Estabilidad del quórum | Viste que el quórum (1,2,3) no se toca al escalar brokers |
