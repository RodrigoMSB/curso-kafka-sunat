# Guía 04 — Tour por Confluent Cloud

## Importante (leer)

A diferencia de las guías anteriores, esta NO requiere que ejecutes
comandos. Es un **tour visual** del servicio gestionado de Confluent.

**¿Por qué no hacemos un ejercicio práctico?**

Confluent Cloud requiere agregar tarjeta de crédito personal (incluso
para el free tier de $400 USD). En contexto corporativo, pedir esto a
cada alumno genera fricciones reales. Por eso el instructor mostrará
el flujo completo en clase usando su propia cuenta.

Si después del curso quieres explorarlo personalmente, las URLs y pasos
están documentados al final de esta guía.

## Tour del flujo

### Paso 1 — Signup

[Captura 1: pantalla de signup en https://www.confluent.io/confluent-cloud/tryfree/]

Notar:
- $400 USD de crédito gratis los primeros 30 días
- Requiere tarjeta de crédito (no la cobra hasta agotar el crédito)
- Alternativa: signup vía Google Cloud Marketplace ofrece $400 SIN tarjeta
  (pero requiere cuenta GCP)

### Paso 2 — Crear cluster

[Captura 2: selección de tipo de clúster]

Tipos disponibles:
- **Basic**: gratis dentro del free tier, ideal para aprender
- **Standard**: producción ligera ($X/hora)
- **Dedicated**: clústeres pre-aprovisionados (más caro)
- **Enterprise**: máximas garantías de SLA

### Paso 3 — Configurar región y nombre

[Captura 3: formulario de creación]

### Paso 4 — Cluster operativo

[Captura 4: dashboard del cluster recién creado]

Notar:
- URL bootstrap servers (formato `pkc-XXXXX.us-east-1.aws.confluent.cloud:9092`)
- Endpoint de Schema Registry incluido
- Métricas en tiempo real (similares a Control Center)

### Paso 5 — Conectar Confluent CLI

```bash
confluent login
confluent kafka cluster list
confluent kafka cluster use <cluster-id>
confluent api-key create --resource <cluster-id>
```

[Captura 5: API keys generadas]

### Paso 6 — Producir desde CLI local

```bash
confluent kafka topic create novatech.cloud.demo
confluent kafka topic produce novatech.cloud.demo --parse-key
> "key1":"valor desde CLI local hacia cloud"
```

[Captura 6: mensaje producido apareciendo en cloud]

## Comparativa Cloud vs Local

| Aspecto | Local (Docker) | Confluent Cloud |
|---------|---------------|-----------------|
| Costo | Gratis (luz/hardware) | Pay per use ($) |
| Setup | docker-compose up | 2 clicks en UI |
| Mantenimiento | Yo mismo | Confluent |
| Disponibilidad | Mi máquina | 99.99% SLA |
| Latencia | <1ms | 10-50ms (red) |
| Escalabilidad | Limitada por hardware | Elástica |
| Casos de uso ideales | Dev, aprendizaje | Producción, MVPs |

## Para explorar después del curso

URLs y pasos:

1. https://www.confluent.io/confluent-cloud/tryfree/ — signup directo
2. https://cloud.google.com/marketplace/product/confluent-cloud — signup sin tarjeta vía GCP
3. https://docs.confluent.io/confluent-cli/current/install.html — instalar Confluent CLI

Ejercicio sugerido: replicar lo que vimos en el tour, conectar tu Lab 11
local a un cluster cloud, producir desde CLI local hacia Cloud.
