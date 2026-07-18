# ADR-001 — Sustitución de Landoop por kafbat-ui

## Estado
Aceptada — 2026-06-27

## Contexto
El temario SUNAT (Unidad 4) nombra "Landoop" para la inspección visual de tópicos
en el ítem "REST Proxy y Landoop".

## Problema
- kafka-topics-ui (Landoop) está descontinuado; usa APIs V2 del REST Proxy y no
  soporta Kafka 4.x.
- lensesio/fast-data-dev recibió soporte KRaft en la línea 3.9.x, pero es un
  entorno todo-en-uno con broker propio en Kafka 3.9, incompatible con la
  arquitectura multi-broker sobre Confluent Platform 8.2.0 del curso.
- provectus/kafka-ui está abandonado desde septiembre 2023, con CVE-2023-52251
  (ejecución remota de código).

## Decisión
Usar kafbat-ui (imagen ghcr.io/kafbat/kafka-ui), sucesor oficial activo del
proyecto provectus, mantenido por los contribuidores originales y con releases
vigentes en 2026 bajo licencia Apache 2.0. Ya está presente en el curso de 28h
(lab-08 y script de diagnóstico), por lo que no introduce tooling nuevo.
El REST Proxy se mantiene: es el Confluent REST Proxy incluido en CP 8.2.0.

## Consecuencias
- El material entrega kafbat-ui aunque el ítem del temario diga "Landoop".
- Se documenta en el material instructor que kafbat-ui es el sucesor moderno.
- No se modifica el temario vendido ni se escala a Netec.

## Nota técnica
Con KRaft 4.x, kafbat-ui muestra la versión del clúster como "1.0-UNKNOWN"
(porque desapareció inter.broker.protocol.version). Es cosmético, sin impacto
funcional.
