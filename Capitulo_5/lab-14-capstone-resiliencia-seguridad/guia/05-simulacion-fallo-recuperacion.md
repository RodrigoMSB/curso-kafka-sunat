# Parte 5: Simulación de fallo y recuperación

## Objetivo

Provocar la caída de un broker sobre el clúster seguro y comprobar, de punta a punta, que el servicio sobrevive (nuevo líder, ISR=2) y que no se pierde ni un mensaje.

## Contexto

El clúster tiene 3 brokers, el tópico `novatech.lab12.confidencial` con RF=3 y `min.insync.replicas=2`. Eso significa: cada partición vive en los 3 brokers, y una escritura con `acks=all` se confirma cuando al menos 2 réplicas la tienen. Vamos a tumbar un broker y ver qué aguanta.

> Importante: en este lab los 3 brokers son también los 3 controllers (KRaft). Tumbar **uno** mantiene el quórum (2 de 3) y el ISR (2 ≥ min.ISR). Tumbar **dos** perdería el quórum del plano de control — por eso un clúster de 3 nodos tolera la pérdida de **uno**, no de dos.

---

## Actividad 1: Foto inicial (líderes e ISR)

```bash
kafka-cli/describe-confidencial.sh
```

Cada partición muestra `Leader`, `Replicas` y `Isr`. Con los 3 brokers vivos, el ISR de cada partición tiene 3 entradas.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué broker es líder de la partición 0? | |
| ¿Cuántas réplicas hay en el ISR de cada partición? | |

---

## Actividad 2: Producir antes del fallo

```bash
kafka-cli/produce-confidencial.sh "pedido-pre-fallo-1"
kafka-cli/produce-confidencial.sh "pedido-pre-fallo-2"
```

(Se producen autenticados como `app1`, sobre el canal SASL_SSL.)

---

## Actividad 3: Simular el fallo

Tumba un broker:

```bash
kafka-cli/simulate-failure.sh 3
```

Vuelve a mirar el estado:

```bash
kafka-cli/describe-confidencial.sh
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Las particiones que lideraba el broker 3 tienen un líder nuevo? | |
| ¿Cuántas réplicas quedan ahora en el ISR? | |
| ¿El clúster sigue respondiendo a comandos? | |

---

## Actividad 4: Producir DURANTE el fallo

```bash
kafka-cli/produce-confidencial.sh "pedido-durante-fallo-1"
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La producción funcionó con un broker caído? ¿Por qué? | |
| ¿Qué pasaría con `acks=all` si el ISR bajara de 2? | |

---

## Actividad 5: Recuperar y verificar sin pérdida

```bash
kafka-cli/recover-broker.sh 3
# espera unos segundos a que se reintegre
kafka-cli/describe-confidencial.sh
kafka-cli/verify-no-loss.sh
```

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| Al volver el broker 3, ¿el ISR regresó a 3? | |
| ¿El conteo de mensajes incluye los de antes Y los de durante el fallo? | |
| ¿Se perdió algún mensaje? | |

---

## Siguiente paso

Continúa con [Parte 6: Capstone automatizado](06-capstone-automatizado.md).
