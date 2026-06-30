# Lab 14 — Reporte resuelto (solución de referencia)

> Líderes/ISR y offsets exactos dependen de la corrida; aquí van los conceptos y resultados esperados.

## Parte 1-3: Seguridad
- El tráfico de clientes va por el listener EXTERNAL con protocolo **SASL_SSL** (TLS + SASL/PLAIN). El INTERNAL es PLAINTEXT (inter-broker y UI dentro de la red).
- `admin` es super user (`KAFKA_SUPER_USERS`): omite el chequeo de ACLs, puede todo.
- `app2` **no** pudo leer el tópico confidencial: no tiene ACL de lectura sobre él. El authorizer (StandardAuthorizer) lo deniega. Es la autorización funcionando.

## Parte 4: Durabilidad
- Con `acks=all` y `min.insync.replicas=2`, una escritura solo se confirma cuando al menos 2 réplicas in-sync la tienen. Si el ISR cae por debajo de 2, el productor con `acks=all` recibe error (`NotEnoughReplicas`) en vez de aceptar una escritura poco durable.

## Parte 5: Failover y recuperación
- Antes del fallo: cada partición tiene ISR de 3 y un líder distribuido entre los brokers.
- Al tumbar el broker 3: las particiones que lideraba eligen **nuevo líder** entre las réplicas in-sync; el ISR baja a **2**. El clúster sigue operativo (quórum 2/3 intacto).
- La producción **funcionó** durante el fallo porque el ISR (2) sigue cumpliendo `min.insync.replicas=2`. Sin downtime.
- Al recuperar el broker 3, se reintegra y el ISR vuelve a **3**.
- El total de mensajes incluye los producidos antes y durante el fallo: **cero pérdida** (gracias a RF=3 + acks=all + min.ISR=2).

## Parte 6: Capstone automatizado
- Sí, `run-capstone.sh` termina con 20 mensajes (10 antes + 10 durante el fallo).
- El failover sin downtime se evidencia en el paso 5: se producen 10 pedidos **con el broker 3 caído** y se confirman.
- Para un DR real entre sitios: replicación a un clúster en otra región (MirrorMaster/Cluster Linking), RPO/RTO definidos, y failover de clientes a los bootstrap del sitio secundario.

---

*Solución - Lab 14*
