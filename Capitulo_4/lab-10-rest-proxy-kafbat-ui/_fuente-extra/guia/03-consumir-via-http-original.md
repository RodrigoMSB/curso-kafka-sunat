# Parte 3: Consumir vía HTTP

## Objetivo

Leer mensajes por HTTP y entender por qué consumir es **con estado**, a diferencia de producir.

## Contexto

Producir era un POST y ya. Consumir es distinto: Kafka necesita recordar **por dónde vas** (offsets). Por eso el REST Proxy te hace crear una **instancia de consumer** en el servidor, suscribirte, hacer poll, y al final borrarla. Es un ciclo de vida, no un GET suelto.

```
crear instancia → suscribir → poll (×2) → borrar instancia
```

---

## Actividad 1: El ciclo completo, automatizado

El script hace todo el ciclo:

```bash
rest-cli/rest-consume.sh novatech.lab10.pedidos
```

Observa la salida: crea la instancia, se suscribe, hace dos polls (el primero suele venir vacío porque inicializa la suscripción; el segundo trae los mensajes), y borra la instancia.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué trajo el primer poll? ¿Y el segundo? | |
| ¿Aparecen los mensajes que produjiste en la Parte 2? | |

---

## Actividad 2: Entender el porqué del estado

Piensa en la diferencia entre los dos polls y el ciclo de vida.

### Preguntas

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Por qué el primer poll suele venir vacío? | |
| ¿Qué pasaría si no borraras la instancia del consumer al terminar? | |
| ¿Por qué producir no necesita instancia pero consumir sí? | |

---

## Siguiente paso

Continúa con [Parte 4: Explorar en Kafbat y desafío](04-kafbat-y-desafio.md).
