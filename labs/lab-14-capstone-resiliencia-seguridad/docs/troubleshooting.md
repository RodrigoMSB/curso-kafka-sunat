# Troubleshooting — Lab 12

## Síntoma 1: `bin/start-lab.sh` falla en el paso `[1/6] generando certificados`

**Causa típica**: `openssl` no está en el PATH del host, Docker no está corriendo, o `infra/certs/` tiene archivos viejos con permisos no escribibles.

**Diagnóstico**:
```bash
which openssl              # debe estar disponible (Git Bash, macOS, Linux lo traen)
docker ps                  # debe responder; Docker Desktop encendido
ls -la infra/certs/
```

**Solución**:
```bash
bin/reset-lab.sh           # limpia infra/certs/
bin/generate-certs.sh      # genera de nuevo
```

Notas:
- `keytool` ya NO se requiere en el host. `bin/generate-certs.sh` lo ejecuta dentro de un contenedor `eclipse-temurin:21-jdk` que se descarga automáticamente la primera vez (~450 MB).
- Si `docker pull eclipse-temurin:21-jdk` falla, revisar conectividad a Docker Hub o configurar un mirror corporativo.

---

## Síntoma 2: brokers se quedan en `starting` y nunca pasan a `healthy`

**Causa A**: el cert no carga porque el password no coincide.

**Diagnóstico**:
```bash
docker logs kafka-broker-1 2>&1 | grep -iE 'ssl|keystore' | head -20
```

Buscar mensajes como `Keystore was tampered with, or password was incorrect`.

**Solución**:
```bash
bin/reset-lab.sh
bin/generate-certs.sh
bin/start-lab.sh
```

Verificar que `TLS_KEYSTORE_PASSWORD` (en `infra/.env`) coincide con el usado en `generate-certs.sh` (default: `changeit`).

**Causa B**: el JAAS server file no se montó.

**Diagnóstico**:
```bash
docker exec kafka-broker-1 cat /etc/kafka/jaas/kafka_server_jaas.conf
```

Si no existe → revisar `volumes:` en docker-compose.

---

## Síntoma 3: cualquier cliente falla con `SaslAuthenticationException`

**Causa A**: el cliente no está usando las properties correctas.

**Diagnóstico**: revisar el comando del script. Debe incluir `--command-config /etc/kafka/client-properties/<user>.properties`.

**Causa B**: `KAFKA_OPTS` heredado contamina el entorno (Java agent, JAAS global).

**Solución**: todos los scripts del lab usan `docker exec -e KAFKA_OPTS=` para limpiar la variable. Si modificas un script, mantén ese flag.

**Causa C**: la password en el JAAS server no coincide con la del cliente.

**Diagnóstico**:
```bash
docker exec kafka-broker-1 cat /etc/kafka/jaas/kafka_server_jaas.conf
cat infra/client-properties/app1.properties
```

Verificar que el `user_app1="..."` del JAAS matchea con el `password="..."` del client properties.

---

## Síntoma 4: `TopicAuthorizationException` cuando esperabas que funcionara

**Causa**: las ACLs no se cargaron.

**Diagnóstico**:
```bash
kafka-cli/list-acls.sh
```

Si la lista está vacía:
```bash
docker exec -e KAFKA_OPTS= cli-client /etc/kafka/scripts/init-lab12-acls.sh
```

**Si init-lab12-acls.sh falla**: revisar que `cli-client` tenga acceso a las properties del admin:
```bash
docker exec cli-client ls -la /etc/kafka/client-properties/
```

---

## Síntoma 5: `app2` PUDO leer el confidencial cuando no debía

**Causa**: el alumno está usando las properties de `app1` o `admin` por error.

**Diagnóstico**:
```bash
grep username= infra/client-properties/app2.properties
```

Debe decir `username="app2"`.

**Causa secundaria**: `allow.everyone.if.no.acl.found` está en `true` por error.

**Diagnóstico**:
```bash
docker exec kafka-broker-1 env | grep ALLOW_EVERYONE
```

Debe ser `false`.

---

## Síntoma 6: el comando produce/consume cuelga sin error

**Causa típica**: timeout esperando metadata. Probablemente el endpoint identification falla.

**Diagnóstico**: en las properties debe estar:
```properties
ssl.endpoint.identification.algorithm=
```

(Vacío). Si dice `https`, el cliente intenta verificar que el hostname (`localhost`) coincida con el CN del cert (`kafka-broker-1`) y falla.

---

## Síntoma 7: `min.insync.replicas` no respeta lo configurado

**Causa**: el topic se creó antes de levantar todos los brokers.

**Diagnóstico**:
```bash
docker exec -e KAFKA_OPTS= cli-client kafka-topics \
  --bootstrap-server kafka-broker-1:9092 \
  --command-config /etc/kafka/client-properties/admin.properties \
  --describe --topic novatech.lab12.publico
```

Verifica que `Replicas: 1,2,3` y `Configs: min.insync.replicas=2`.

**Solución**:
```bash
bin/reset-lab.sh
bin/start-lab.sh
```

---

## Síntoma 8: `docker stop kafka-broker-3` y los otros brokers también caen

**Causa**: si Docker Desktop tiene poca RAM, al detener un broker el OOM killer arrastra otros.

**Diagnóstico**:
```bash
docker stats --no-stream
```

**Solución**: subir RAM de Docker Desktop a 8GB+ (Settings → Resources). Hacer experimento con un solo broker detenido y revivirlo antes del siguiente.

---

## Síntoma 9: Kafbat UI no se conecta al cluster

**Causa**: Kafbat está configurado para el listener INTERNAL (PLAINTEXT). Si tocaste la config y le pusiste el listener EXTERNAL (SASL_SSL), necesitas darle credenciales.

**Diagnóstico**:
```bash
docker logs kafbat-ui 2>&1 | tail -30
```

**Solución por defecto del lab**: Kafbat usa `KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka-broker-1:29092` (listener INTERNAL). No tocar a menos que sepas lo que haces.

---

## Síntoma 10: capstone — los containers de Lab 09/10/11 no responden

**Causa**: muchos stacks levantados, OOM o saturación de CPU.

**Diagnóstico**:
```bash
docker stats --no-stream
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

**Solución**:
- Apaga el stack que no estés usando en ese paso del capstone.
- Sube recursos de Docker Desktop.
- Si nada de eso es opción, simula el flujo dentro de un solo lab (ver `guia/06-capstone-evaluacion-final.md`, sección "Nota").

---

## Síntoma 11: `bin/reset-lab.sh` no borra `infra/certs/`

**Causa**: shell sin permisos de escritura, o archivos en uso por containers running.

**Solución**:
```bash
docker compose -f infra/docker-compose.yml down -v
rm -rf infra/certs/*
touch infra/certs/.gitkeep
bin/start-lab.sh
```

---

*Troubleshooting — Lab 12*
