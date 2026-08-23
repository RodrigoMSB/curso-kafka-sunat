# Lab 06 · SALIDAS — la corrida real

> Transcripción literal de un arnés que ejecuta el recorrido de clase —los
> cuatro pasos— contra el clúster de tres brokers. Los `[t=NNNs]` son segundos
> desde el inicio.
>
> **Los consumidores de este lab no terminan solos**, así que el arnés los
> lanza en segundo plano, les pone `client.id` para poder distinguirlos, y al
> final les manda **SIGINT** — que es exactamente lo que hace `Ctrl+C`.

## Los números de esta corrida

| | |
|---|---|
| **Ejecución total** | **96 s** |
| De eso, esperas de rebalanceo | **~70 s** (20–30 s tras cada cambio de miembros) |

## Los controles, y lo que dieron

| Control | Esperado | Salió |
|---|---|---|
| Particiones de `cons-A` estando solo | 3 | **3** |
| Particiones de `cons-A` con `cons-B` dentro | 2 | **2** |
| Particiones de `cons-B` | 1 | **1** |
| Suma de mensajes entre `cons-A` y `cons-B` | 6 | **6** |
| Mensajes duplicados entre los dos | 0 | **0** |
| Mensajes que recibió el grupo `reportes` | 6 | **6** |
| `LAG` de `validacion` después de que `reportes` leyera todo | 0 | **0** |

## Lo que va a ser distinto en tu máquina

| Valor | Por qué cambia |
|---|---|
| `TopicId` y los sufijos de `CONSUMER-ID` | Se generan en cada corrida |
| **Cuál** consumidor se queda con dos particiones | El asignador reparte por orden de llegada |
| El reparto de mensajes (aquí 4 y 2) | Depende del hash de las claves. **6–0 es posible y no es un fallo** |
| El orden en que `reportes` lista las particiones | El consumidor recorre una partición y después otra, sin orden garantizado entre ellas |

## Lo que **no** debería cambiar

- `PartitionCount: 3` en `novatech.validacion`.
- Que un consumidor solo se quede con **las tres** particiones.
- Que al entrar el segundo, ninguna partición aparezca **dos veces**.
- Que la **suma** sea 6 y los **duplicados** 0.
- Que el grupo `reportes` reciba **los 6** y que `validacion` **no cambie** ni un offset.

---

## Transcripción

```

===== [t=000s] PASO 1 · el topico de tres sectores =====
Created topic novatech.validacion.
Topic: novatech.validacion	TopicId: ZMXGBOSATgyJA16QCDwHkw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2

===== [t=002s] PASO 2 · un cocinero solo (cons-A) =====

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          0               0               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A
validacion      novatech.validacion 1          0               0               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A
validacion      novatech.validacion 2          0               0               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A

===== [t=024s] PASO 3 · entra el segundo cocinero (cons-B) =====

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          0               0               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A
validacion      novatech.validacion 1          0               0               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A
validacion      novatech.validacion 2          0               0               0               cons-B-da5ac6b7-bda9-4331-9b5d-083345c5a647 /172.27.0.4     cons-B
--- se escriben los 6 comprobantes ---
Warning: --property is deprecated and will be removed in a future version. Use --reader-property instead.
Warning: --property is deprecated and will be removed in a future version. Use --reader-property instead.
Warning: --property is deprecated and will be removed in a future version. Use --reader-property instead.
Warning: --property is deprecated and will be removed in a future version. Use --reader-property instead.
Warning: --property is deprecated and will be removed in a future version. Use --reader-property instead.
Warning: --property is deprecated and will be removed in a future version. Use --reader-property instead.
--- terminal A (cons-A) ---
Option --consumer-property is deprecated and will be removed in a future version. Use --command-property instead.
Option --property is deprecated and will be removed in a future version. Use --formatter-property instead.
Partition:1|RUC-20100066601|comprobante_1
Partition:0|RUC-20100066602|comprobante_2
Partition:1|RUC-20100066603|comprobante_3
Partition:0|RUC-20100066605|comprobante_5
--- terminal B (cons-B) ---
Option --consumer-property is deprecated and will be removed in a future version. Use --command-property instead.
Option --property is deprecated and will be removed in a future version. Use --formatter-property instead.
Partition:2|RUC-20100066604|comprobante_4
Partition:2|RUC-20100066606|comprobante_6

===== [t=072s] PASO 4 · otra brigada (cons-Z, grupo reportes) =====
--- terminal Z (cons-Z, grupo reportes) ---
Option --consumer-property is deprecated and will be removed in a future version. Use --command-property instead.
Option --property is deprecated and will be removed in a future version. Use --formatter-property instead.
Partition:2|RUC-20100066604|comprobante_4
Partition:2|RUC-20100066606|comprobante_6
Partition:0|RUC-20100066602|comprobante_2
Partition:0|RUC-20100066605|comprobante_5
Partition:1|RUC-20100066601|comprobante_1
Partition:1|RUC-20100066603|comprobante_3
--- y el grupo validacion, que no se movio ---

GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                 HOST            CLIENT-ID
validacion      novatech.validacion 0          2               2               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A
validacion      novatech.validacion 1          2               2               0               cons-A-d20687de-61a5-4c6a-a35f-312a72502706 /172.27.0.4     cons-A
validacion      novatech.validacion 2          2               2               0               cons-B-da5ac6b7-bda9-4331-9b5d-083345c5a647 /172.27.0.4     cons-B

===== [t=094s] LIMPIEZA =====

===== [t=096s] FIN =====
```

---

## Nota sobre la línea base

El arnés arranca **matando todo consumidor vivo dentro del contenedor**,
borrando el tópico y borrando los dos grupos, y **aborta si algo de eso no
quedó limpio**. Sin esa línea base, un consumidor zombi de una corrida anterior
sigue en el grupo, se lleva una partición, y el reparto que ves no es el que
crees.

```bash
docker exec kafka-broker-1 sh -c 'ps -ef | grep -c "[C]onsoleConsumer"'
docker exec kafka-broker-1 sh -c 'pkill -9 -f ConsoleConsumer'
```

⚠️ **`pkill -f "console-consumer"` NO funciona.** Esa cadena no aparece en la
línea de comandos del proceso: hay que buscar `ConsoleConsumer`, que es la
clase Java.

> Las líneas `Warning: --property is deprecated` y `Option --consumer-property
> is deprecated` de la transcripción son de Kafka 8.x avisando de un cambio de
> nombre de los flags. **Los flags funcionan** — las salidas de arriba lo
> demuestran.

---

## Lo que salió del recorrido y dónde quedó

Este laboratorio tenía seis pasos y hoy tiene cuatro. Lo que salió no se perdió:
está en la sección **7 · PARA PROFUNDIZAR** de la guía, con su comando y su
salida real.

| Salió del recorrido | Dónde está |
|---|---|
| El rebalanceo al matar un consumidor | *Para profundizar A* |
| El techo · cuatro cocineros, tres sectores | *Para profundizar B* |
