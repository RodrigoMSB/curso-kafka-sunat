# Lab 14 — Reporte resuelto (solución de referencia)

> Líderes/ISR y offsets exactos dependen de la corrida; aquí van los conceptos y resultados esperados.

## Parte 1: TLS y certificados
- **¿Quién firmó el cert de broker-1?** La **CA interna de NovaTech** (`NovaTech-CA-Lab14`), creada por `generate-certs.sh`. Los clientes solo necesitan confiar en esa CA (truststore) para validar a cualquier broker.
- **¿Qué SANs tiene?** Los nombres por los que se contacta al broker: `kafka-broker-1` (red interna) y `localhost` (clientes del host). Si el SAN no calza con el hostname usado, el handshake TLS falla por verificación de identidad.
- **Issuer / Subject / expira:** Issuer = la CA (`NovaTech-CA-Lab14`); Subject = el broker (CN `kafka-broker-1`); la fecha de expiración es la validez fijada en `generate-certs.sh` (depende de la corrida).
- **Entries del keystore:** la entrada del broker (par clave privada + certificado) bajo el alias del broker (visible con `keytool -list`). El **truststore** guarda la CA.
- **Listeners / SASL_SSL / inter-broker:** EXTERNAL (**SASL_SSL**, clientes), INTERNAL (PLAINTEXT, inter-broker + UI en la red), CONTROLLER (quórum). El de clientes usa SASL_SSL; el inter-broker es el INTERNAL.
- **¿Por qué no mTLS aquí?** TLS cifra el canal y autentica al **servidor**; la autenticación del **cliente** la hace SASL (no un cert de cliente). mTLS exigiría un cert por cliente; se optó por SASL/PLAIN sobre TLS por simplicidad didáctica.
- **¿Si la CA expira?** Todos los certs firmados por ella dejan de validar → los clientes rechazan el handshake TLS de todos los brokers. Por eso la rotación de la CA es crítica.
- **¿Quién rota los certs en producción?** Una PKI corporativa (Vault, cert-manager, ADCS), no a mano, con rotación automatizada antes del vencimiento.

## Parte 2: SASL y autenticación
- **¿Cuántos usuarios?** **Tres**: `admin`, `app1`, `app2` (en el JAAS del broker).
- **¿Passwords?** En **texto plano** en el JAAS (`infra/jaas/`): `admin-secret`, `app1-secret`, `app2-secret`. Ese es el punto pedagógico: SASL/**PLAIN** guarda credenciales en texto → **nunca** sin TLS por encima; en producción se prefiere SCRAM.
- **¿user_app3 + reinicio?** `app3` pasa a poder **autenticarse** (el JAAS estático se lee al arranque → agregar usuarios con PLAIN exige reinicio, otra limitación vs SCRAM). Autenticarse no lo autoriza: sin ACLs y con `allow.everyone.if.no.acl.found=false`, se le deniega todo.
- **¿Por qué `User:ANONYMOUS` en super.users?** El listener interno (PLAINTEXT) no autentica → el tráfico inter-broker/UI llega como `User:ANONYMOUS`; ponerlo en super.users evita que las ACLs bloqueen la operación interna del clúster.
- **¿Sacar `User:admin` de super.users?** admin quedaría sujeto a ACLs como cualquiera → perdería acceso salvo lo explícitamente permitido.
- **¿Funcionó app1 al público?** Sí (app1 tiene ACL de producción sobre el público).
- **¿Error sin credenciales / por qué falla?** Falla de **autenticación** SASL (no autenticado); ni siquiera llega a la autorización.
- **¿PLAIN sin TLS es seguro?** No: las credenciales viajan en claro. Por eso SASL_SSL (PLAIN sobre TLS).
- **¿SCRAM mejor que PLAIN?** SCRAM usa hash con salt (challenge-response), no envía la password, y los usuarios se gestionan dinámicamente con `kafka-configs` (sin reinicio).
- **¿Cuándo Kerberos?** En entornos con Active Directory/GSSAPI ya desplegado (SSO corporativo).

## Parte 3: ACLs y autorización
ACLs que carga `init-lab12-acls.sh` (verbatim):

| Principal | Recurso (topic) | Operaciones | Group |
|-----------|-----------------|-------------|-------|
| `User:app1` | `novatech.lab12.publico` | producer + consumer (Read/Write/Describe) | `*` |
| `User:app1` | `novatech.lab12.confidencial` | producer + consumer (Read/Write/Describe) | `*` |
| `User:app2` | `novatech.lab12.publico` | consumer (Read/Describe) | `*` |

- **¿Cuántas ACLs / qué principals?** Las de la tabla; principals `User:app1` y `User:app2` (`admin` no necesita ACL: es super.user).
- **¿ACL sobre confidencial para app2?** **No** — por eso se le deniega la lectura.
- **¿app1 pudo producir / admin leer?** Sí: app1 por su ACL; admin por `super.users` (bypassa el authorizer).
- **¿Error de app2 en confidencial / cuándo falló?** `TopicAuthorizationException` («Not authorized to access topics»); falla en la **autorización** de la operación (fetch), **después** del handshake TLS+SASL exitoso — ya estaba autenticado.
- **¿app2 recibió el público / por qué sí?** Sí: hay una ACL explícita `app2 → Read` sobre el público.
- **¿`allow.everyone.if.no.acl.found=true`?** Invertiría el default: todo lo no explícitamente denegado quedaría permitido → app2 podría leer el confidencial. Peligroso.
- **¿Por qué `super.users` es peligroso?** Bypassa **todas** las ACLs; un principal de más ahí = acceso total sin control.

## Parte 4: min.insync.replicas (durabilidad)
- **RF=5 → ¿qué min.ISR?** **3**: tolera la caída de 2 réplicas manteniendo mayoría durable. Regla práctica: `min.ISR = RF - f` (fallos a tolerar con durabilidad); con RF=5/min.ISR=3 sobrevives 2 caídas sin rechazar escrituras.
- **¿`acks=1` con min.ISR=2?** **Nada**: `min.insync.replicas` solo se valida con `acks=all`. Con `acks=1` el líder confirma solo, aunque el ISR esté bajo el mínimo → sin garantía de durabilidad.
- **¿Réplicas en ISR (clúster sano)?** **3** (RF=3, los 3 brokers vivos).
- **¿Funcionó el produce con 2 vivos?** Sí: ISR=2 ≥ min.ISR=2 y `acks=all` → escritura confirmada.
- **¿Error con 1 vivo?** ISR=1 < min.ISR=2 → el productor `acks=all` recibe `NOT_ENOUGH_REPLICAS` (`NotEnoughReplicasException`) y la escritura se **rechaza** (verificado empíricamente en la auditoría).
- **¿Reintenta o falla rápido?** Reintenta hasta `delivery.timeout.ms` (default 120 s) antes de rendirse; con `retries`/timeouts cortos falla rápido.
- **¿Vuelve el ISR a 3?** Sí, al revivir los brokers se reintegran en segundos (según `replica.lag.time.max.ms`).
- **¿RF=5 cuándo?** Datos críticos que deben tolerar 2 fallos simultáneos sin perder durabilidad (a costa de más almacenamiento y red).
- **¿Pierdes 2/3 brokers y vuelven en 5 min?** No: las escrituras confirmadas con `acks=all`/min.ISR=2 estaban en ≥2 réplicas; mientras el ISR estuvo <2, `acks=all` rechazó nuevas escrituras (no aceptó datos poco durables).

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
