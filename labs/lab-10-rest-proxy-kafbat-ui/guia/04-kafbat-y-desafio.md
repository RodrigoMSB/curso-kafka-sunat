# Parte 4: Explorar en Kafbat y desafío

## Objetivo

Ver visualmente en Kafbat UI los mensajes que entraron por HTTP, y comprobar que HTTP y clientes nativos conviven sobre el mismo tópico.

## Contexto

Todo lo que produjiste por HTTP es Kafka normal y corriente: cualquier consumidor —HTTP o nativo— lo ve. Kafbat te lo muestra sin que tengas que adivinar.

---

## Actividad 1: Ver los mensajes en Kafbat

Abre `http://localhost:8090`, entra al clúster `novatech-cluster`, busca el tópico `novatech.lab10.pedidos` y mira sus mensajes.

### Anota

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿Ves los pedidos que produjiste por HTTP? | |
| ¿Kafbat distingue si un mensaje entró por HTTP o por un cliente nativo? | |

---

## Actividad 2: Interoperabilidad HTTP ↔ nativo

Produce un mensaje **por HTTP** y consúmelo **con un cliente nativo** desde dentro de un broker:

```bash
# Producir por HTTP
rest-cli/rest-produce.sh novatech.lab10.pedidos '{"pedido":9999,"origen":"http"}'

# Consumir con el cliente nativo (CLI dentro del broker)
docker exec kafka-broker-1 kafka-console-consumer \
  --bootstrap-server kafka-broker-1:29092 \
  --topic novatech.lab10.pedidos --from-beginning --max-messages 10
```

### Pregunta

| Pregunta | Tu respuesta |
|----------|-------------|
| ¿El cliente nativo vio el mensaje que entró por HTTP? | |
| ¿Qué te dice esto sobre dónde vive realmente el mensaje? | |

---

## Desafío

Un partner solo puede hacer `curl`. Diséñale una mini-secuencia (3–4 comandos curl) que: liste tópicos, produzca 2 pedidos, cree un consumer, lea los pedidos y limpie la instancia. Documenta los comandos exactos en el reporte.

---

## Conclusiones

| Concepto | Lo aprendiste haciendo... |
|----------|---------------------------|
| REST Proxy como puente HTTP↔Kafka | Listaste tópicos y produjiste con `curl` |
| Producción sin estado | Un POST y el mensaje quedó en Kafka |
| Consumo con estado | Hiciste el ciclo crear→suscribir→poll→borrar |
| Interoperabilidad | Un mensaje HTTP lo leyó un cliente nativo |
| Exploración visual | Viste los mensajes en Kafbat UI |
