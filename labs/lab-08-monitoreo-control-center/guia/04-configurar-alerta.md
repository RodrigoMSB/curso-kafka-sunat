# Parte 4: Configurar una alerta nativa en Control Center

## Objetivo

Crear un **trigger** en Control Center Legacy 7.9 que se dispare cuando el clúster tenga particiones con réplicas fuera de sincronía, simular el escenario tumbando un broker, y observar la alerta dispararse.

## Contexto

Control Center Legacy tiene **alertas nativas** (NO requiere Alertmanager externo). Las alertas se configuran como "Triggers" en la UI:
- Una **regla** que vigila una métrica
- Una **acción** que se ejecuta cuando la regla se dispara (email, webhook genérico)

Esto es lo que separa un sistema "operable" de uno "vigilado".

---

## Actividad 1: Crear el trigger desde la UI

Abre **http://localhost:9021** > **Alerts** (en algunas versiones aparece como "Alert History").

Click en **+ New trigger** o equivalente.

Configurar:
- **Name**: `under_replicated_partitions_high`
- **Cluster**: el clúster del lab (debería estar pre-seleccionado)
- **Trigger condition**:
  - Metric: `Under-replicated partitions`
  - Component type: Cluster
  - Operator: `>`
  - Value: `0`
  - For (duration): `30 seconds`
- **Severity**: `WARNING`

Guarda el trigger.

---

## Actividad 2: Asociar una acción al trigger

Ahora vincula el trigger a una acción.

En la misma pestaña Alerts:
- Crea una **Action** llamada `webhook-dummy` (con URL ficticia, p.ej. http://localhost:5001/webhook)
- Asocia esta action al trigger creado en Actividad 1

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La UI permitió crear el trigger? | |
| ¿Qué otras métricas pre-definidas pudiste elegir? | |
| ¿Qué tipos de actions están disponibles? (email, webhook, otro) | |

> **Nota pedagógica**: la URL del webhook es ficticia (`localhost:5001` no existe). En producción real, aquí iría un servicio que reciba la notificación: Slack webhook, PagerDuty, etc.

---

## Actividad 3: Disparar la alerta tumbando un broker

Asegúrate de que hay carga corriendo. Si no, lánzala en otra terminal:

```bash
kafka-cli/produce-flood.sh 600 100
```

En otra terminal, tumba el broker 2:

```bash
kafka-cli/trigger-broker-down.sh 2
```

**Mira el reloj**: en 30-90 segundos deberías ver la alerta disparada en CC.

| Métrica | Valor |
|---------|-------|
| Hora de tumbar el broker | |
| Hora en que apareció el trigger en CC | |
| Tiempo total (segundos) | |

---

## Actividad 4: Verificar la alerta en CC

En **http://localhost:9021** > Alerts:

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Aparece el trigger marcado como "active"/"firing"? | |
| ¿Qué información del evento muestra? | |
| ¿Aparece un registro en "Alert History"? | |

---

## Actividad 5: Resolver la alerta (revivir el broker)

```bash
docker compose -f infra/docker-compose.yml --env-file infra/.env up -d kafka-broker-2
```

Espera 30-90 segundos.

| Métrica | Valor |
|---------|-------|
| Hora de revivir el broker | |
| Hora en que la alerta se resolvió | |
| Tiempo de resolución (segundos) | |

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿La alerta cambió a "resolved" automáticamente? | |
| ¿Quedó registro en Alert History de ambos eventos (trigger + resolución)? | |

---

## Reflexión

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué la alerta tarda 30-90s en aparecer (no es instantánea)? | |
| ¿Qué pasaría si pusieras "duration: 1 second"? | |
| En producción, ¿cómo decidirías qué duración usar? | |
| ¿Qué otra métrica te gustaría alertar? | |

> **Pista respuestas**: las alertas tienen duración para evitar **false positives** (caídas momentáneas). 1 segundo causaría flapping (alertas constantes encendiendo/apagando). En producción se usa 5-15 minutos para alertas no críticas, 30s-2min para críticas.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| Crear triggers en UI | Configuraste una alerta desde Control Center |
| Pipeline de alertas | Métricas → Trigger → Action → Notificación |
| Tiempo de detección | 30-90s en este lab; configurable |
| Resolución automática | Cuando la condición vuelve a normal |

---

## Siguiente paso

Continúa con [Desafío 5: Kafbat vs Control Center](05-desafio-kafbat-vs-c3.md).
