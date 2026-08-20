# Lab 06 · SALIDAS — la corrida real

> Transcripción literal de un arnés que ejecuta el recorrido completo contra el
> clúster de tres brokers. Los `[t=NNNs]` son segundos desde el inicio.
>
> **Los consumidores de este lab no terminan solos**, así que el arnés los
> lanza en segundo plano, les pone `client.id` para poder distinguirlos, y les
> manda **SIGINT** — que es exactamente lo que hace `Ctrl+C`.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total** | **189 s** |
| De eso, esperas de rebalanceo | ~95 s (20–30 s tras cada cambio de miembros) |

## Los controles, y lo que dieron

| Control | Esperado | Salió |
|---|---|---|
| Particiones de `cons-A` estando solo | 3 | **3** |
| Suma de mensajes entre `cons-A` y `cons-B` | 6 | **6** |
| Mensajes duplicados entre los dos | 0 | **0** |
| Miembros tras el `Ctrl+C` sobre `cons-B` | 1 | **1** |
| Particiones de `cons-A` tras el rebalanceo | 3 | **3** |
| Miembros con 4 consumidores | 4 | **4** |
| Miembros **ociosos** (`#PARTITIONS` = 0) | 1 | **1** |
| Mensajes que recibió el grupo `reportes` | 9 | **9** |

## Lo que va a ser distinto en tu máquina

| Valor | Por qué cambia |
|---|---|
| `TopicId` y los sufijos de `CONSUMER-ID` | Se generan en cada corrida |
| **Cuál** consumidor se queda con dos particiones | El asignador reparte por orden de llegada |
| **Cuál** de los cuatro queda ocioso | Puede ser cualquiera. Lo que no cambia es que sea **exactamente uno** |
| El reparto de mensajes (aquí 4 y 2) | Depende del hash de las claves. **6–0 es posible y no es un fallo** |

## Lo que **no** debería cambiar

- `PartitionCount: 3` en `novatech.validacion`.
- Que un consumidor solo se quede con **las tres** particiones.
- Que la **suma** sea 6 y los **duplicados** 0.
- Que tras el `Ctrl+C` quede **un** miembro con **tres** particiones.
- Que con 4 consumidores haya **exactamente un** `#PARTITIONS` en `0`.
- Que el grupo `reportes` reciba **los 9** y que `validacion` **no cambie**.

---

## Transcripción

```

===== [t=002s] FASE 0 · el topico de 3 particiones =====
Created topic novatech.validacion.
Topic: novatech.validacion	TopicId: jCAkZpmIS3--SOVAZe97GQ	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: novatech.validacion	Partition: 0	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
	Topic: novatech.validacion	Partition: 1	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: novatech.validacion	Partition: 2	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 

===== [t=011s] FASE 1 · UN consumidor (cons-A) =====

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          0               0               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 1          0               0               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 2          0               0               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
--- control · particiones de cons-A (debe ser 3): 3 ---

===== [t=032s] FASE 2 · se suma cons-B al MISMO grupo =====

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          0               0               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 1          0               0               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 2          0               0               0               cons-B-ecd3cc96-2e7b-42a5-8928-5760f1d16d6c /172.26.0.4     cons-B

--- se producen 6 comprobantes CON CLAVE ---
--- cons-A recibio 4 ---
    A  Partition:1|RUC-20100066601|comprobante_1
    A  Partition:0|RUC-20100066602|comprobante_2
    A  Partition:1|RUC-20100066603|comprobante_3
    A  Partition:0|RUC-20100066605|comprobante_5
--- cons-B recibio 2 ---
    B  Partition:2|RUC-20100066604|comprobante_4
    B  Partition:2|RUC-20100066606|comprobante_6
--- SUMA 6 (deben ser 6) ---
--- control duplicados (debe ser 0): 0 ---

===== [t=079s] FASE 3 · Ctrl+C sobre cons-B (SIGINT real) =====

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          2               2               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 1          2               2               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 2          2               2               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
--- control · miembros ahora: 1 (debe ser 1) ---
--- control · particiones de cons-A: 3 (debe ser 3) ---
--- se producen 3 mas (7,8,9) ---
--- cons-A tenia 4, ahora tiene 7 ---
    A  Partition:1|RUC-20100066601|comprobante_1
    A  Partition:0|RUC-20100066602|comprobante_2
    A  Partition:1|RUC-20100066603|comprobante_3
    A  Partition:0|RUC-20100066605|comprobante_5
    A  Partition:0|RUC-20100066607|comprobante_7
    A  Partition:1|RUC-20100066608|comprobante_8
    A  Partition:0|RUC-20100066609|comprobante_9

===== [t=127s] FASE 4 · el techo · CUATRO consumidores sobre TRES particiones =====

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          4               4               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 1          3               3               0               cons-B-fa50017e-0d15-4d17-b609-a02bb91c44d7 /172.26.0.4     cons-B
validacion      novatech.validacion 2          2               2               0               cons-C-f22ef424-fa6b-4b4b-aec0-92d6723ca1bb /172.26.0.4     cons-C
--- MIEMBROS ---

GROUP           CONSUMER-ID                                 HOST            CLIENT-ID       #PARTITIONS     
validacion      cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A          1               
validacion      cons-B-fa50017e-0d15-4d17-b609-a02bb91c44d7 /172.26.0.4     cons-B          1               
validacion      cons-D-eb9b8358-75cb-49c1-9027-d06cf5e0113a /172.26.0.4     cons-D          0               
validacion      cons-C-f22ef424-fa6b-4b4b-aec0-92d6723ca1bb /172.26.0.4     cons-C          1               
--- control · miembros: 4 (deben ser 4) ---
--- control · OCIOSOS (0 particiones): 1 (debe ser 1) ---

===== [t=162s] FASE 5 · otro grupo lee TODO de nuevo =====
--- el grupo 'reportes' recibio 9 (deben ser 9) ---
    Z  Partition:1|RUC-20100066601|comprobante_1
    Z  Partition:1|RUC-20100066603|comprobante_3
    Z  Partition:1|RUC-20100066608|comprobante_8
    Z  Partition:0|RUC-20100066602|comprobante_2
    Z  Partition:0|RUC-20100066605|comprobante_5
    Z  Partition:0|RUC-20100066607|comprobante_7
    Z  Partition:0|RUC-20100066609|comprobante_9
    Z  Partition:2|RUC-20100066604|comprobante_4
    Z  Partition:2|RUC-20100066606|comprobante_6
--- y 'validacion' sigue igual: ---

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          4               4               0               cons-A-be99f7b9-4c28-4db0-8b7a-32cb74d5d04d /172.26.0.4     cons-A
validacion      novatech.validacion 1          3               3               0               cons-B-fa50017e-0d15-4d17-b609-a02bb91c44d7 /172.26.0.4     cons-B
validacion      novatech.validacion 2          2               2               0               cons-C-f22ef424-fa6b-4b4b-aec0-92d6723ca1bb /172.26.0.4     cons-C

===== [t=186s] LIMPIEZA =====
FIN t=189s
```
