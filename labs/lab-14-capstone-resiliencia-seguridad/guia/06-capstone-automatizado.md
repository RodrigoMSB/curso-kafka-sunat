# Parte 6: Capstone automatizado

## Objetivo

Ejecutar, de una sola corrida, el flujo integrador completo: clúster seguro + producción autenticada + fallo + recuperación + verificación sin pérdida. Y entender que la automatización es lo que harías en un runbook de producción.

## Contexto

Hiciste cada pieza a mano en las Partes 1-5. Ahora las encadenamos en un solo script orquestador, `bin/run-capstone.sh`, que corre los 8 pasos automáticamente. Es la prueba de fuego de NovaTech: "demuéstrame en una corrida que el clúster es seguro y resiliente".

---

## Actividad 1: Correr el capstone automatizado

Con el clúster levantado (`bin/start-lab.sh` ya ejecutado):

```bash
bin/run-capstone.sh
```

El script imprime 8 pasos:
1. Estado inicial seguro (TLS+SASL+ACL, RF=3, min.ISR=2)
2. Produce 10 pedidos autenticados (acks=all)
3. Tumba kafka-broker-3
4. Estado tras el fallo (nuevo líder, ISR=2)
5. Produce 10 pedidos más, con el broker caído
6. Recupera kafka-broker-3
7. Verifica el total (20 mensajes, sin pérdida)
8. Estado recuperado (ISR=3)

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El total final fue 20 mensajes? | |
| ¿En qué paso se ve la elección de nuevo líder? | |
| ¿En qué paso se demuestra que no hubo downtime? | |

---

## Actividad 2: Hacerlo tú (modo manual)

El script es la versión automática. La versión manual es seguir las Partes 1-5 a mano, en este orden:
1. Seguridad arriba (TLS+SASL+ACL ya quedan con `start-lab.sh`).
2. Producir autenticado (Parte 2/3).
3. Simular fallo (Parte 5, Actividad 3).
4. Producir durante el fallo (Parte 5, Actividad 4).
5. Recuperar y verificar (Parte 5, Actividad 5).

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Qué ventaja tiene tener este flujo automatizado como runbook? | |
| ¿Qué pasos añadirías para un escenario de DR real (otro sitio)? | |

---

## Conclusiones del capstone

| Capacidad | Demostrada con... |
|-----------|-------------------|
| Cifrado en tránsito (TLS) | Listeners SASL_SSL, certificados propios |
| Autenticación (SASL/PLAIN) | Usuarios admin/app1/app2 |
| Autorización (ACLs) | app2 no puede leer confidencial |
| Durabilidad (min.ISR) | acks=all con 2 réplicas in-sync |
| Resiliencia (failover) | Nuevo líder y producción sin downtime |
| Recuperación | Reintegración del broker, ISR de vuelta a 3, cero pérdida |

Con esto cierras el curso: un clúster Kafka **seguro y resiliente**, operado de punta a punta.
