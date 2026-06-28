# Parte 3: Tolerancia a fallos

## Objetivo

Simular la caída de un broker y observar cómo Kafka redistribuye automáticamente los líderes de particiones y mantiene la disponibilidad del clúster. Luego, recuperar el broker y observar el proceso de resincronización.

## Contexto

Son las 3 AM y recibes una alerta: **uno de los servidores del clúster NovaTech ha dejado de responder**. Antes de entrar en pánico, necesitas entender qué pasa con los datos y la disponibilidad del sistema.

---

## Paso 1: Documentar el estado actual

Antes de simular la caída, documenta el estado actual del clúster.

Ejecuta:

```bash
bin/explore-cluster.sh
```

### Registra el estado ANTES de la caída

| Elemento | Valor actual |
|----------|-------------|
| Controlador activo (Leader ID) | |
| Líder de Partición 0 | |
| Líder de Partición 1 | |
| Líder de Partición 2 | |
| Líder de Partición 3 | |
| Líder de Partición 4 | |
| Líder de Partición 5 | |
| ISR de todas las particiones | |
| Número de votantes en el quorum | |

---

## Paso 2: Simular la caída del Broker 2

Ejecuta el siguiente comando:

```bash
bin/kill-broker.sh 2
```

El script mostrará automáticamente el estado antes y después de la caída. Observa con atención los cambios.

> **Importante**: Mientras el broker está caído, abre otra terminal y observa si el productor GPS sigue funcionando:
> ```bash
> docker logs -f gps-producer
> ```

---

## Paso 3: Analizar el impacto

### Registra el estado DESPUÉS de la caída

| Elemento | Valor después de la caída |
|----------|--------------------------|
| Controlador activo (Leader ID) | |
| Líder de Partición 0 | |
| Líder de Partición 1 | |
| Líder de Partición 2 | |
| Líder de Partición 3 | |
| Líder de Partición 4 | |
| Líder de Partición 5 | |
| ISR de las particiones | |
| Número de votantes en el quorum | |

### Preguntas de análisis

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Cambió el controlador activo? | |
| ¿Qué pasó con las particiones que tenían al Broker 2 como líder? | |
| ¿Quién asumió el liderazgo de esas particiones? | |
| ¿El productor GPS siguió enviando mensajes? | |
| ¿Se perdieron mensajes durante la caída? | |
| ¿Cuántos brokers quedan en el ISR de cada partición? | |
| ¿El clúster sigue operativo con 2 de 3 brokers? | |

---

## Paso 4: Recuperar el broker

Ejecuta:

```bash
bin/revive-broker.sh 2
```

Espera a que el script confirme que el broker está operativo.

---

## Paso 5: Verificar la recuperación

### Registra el estado DESPUÉS de la recuperación

| Elemento | Valor después de la recuperación |
|----------|--------------------------------|
| Controlador activo (Leader ID) | |
| Líder de Partición 0 | |
| Líder de Partición 1 | |
| Líder de Partición 2 | |
| Líder de Partición 3 | |
| Líder de Partición 4 | |
| Líder de Partición 5 | |
| ISR de las particiones | |
| Número de votantes en el quorum | |

### Preguntas de recuperación

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El Broker 2 volvió a ser líder de alguna partición? | |
| ¿Todas las réplicas están de nuevo en ISR? | |
| ¿Cuánto tiempo tardó aproximadamente la resincronización? | |
| ¿Se perdió algún dato durante todo el proceso? | |

---

## Conclusión

Escribe un párrafo explicando lo que aprendiste sobre la resiliencia de Kafka:

> _Tu conclusión aquí..._
>
> Considera: ¿Por qué Kafka pudo seguir operando? ¿Qué rol juegan las réplicas ISR?
> ¿Qué habría pasado si hubieran caído 2 de 3 brokers simultáneamente?

---

## Siguiente paso

Si te queda tiempo, continúa con la [Parte 4: Desafío extra](04-desafio-extra.md).
