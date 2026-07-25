# Capítulo 1: Arquitectura, fundamentos y ecosistema

**Curso**: Administración de Confluent Apache Kafka (SUNAT)
**Unidad**: 1 - Arquitectura, fundamentos y ecosistema
**Duración estimada de la práctica**: ~30 minutos

---

## Contexto

Este capítulo es **conceptual**: sienta las bases sobre las que se apoyan los 14 laboratorios
del curso. Se cubren la mensajería basada en eventos, la arquitectura de Apache Kafka 4.2 y los
componentes de Confluent Platform 8.2.0 que vas a operar de aquí en adelante.

No hay clúster que levantar todavía. Lo que sí hay —y es condición para todo lo que sigue— es
dejar tu máquina en condiciones de correr los labs sin sorpresas.

---

## ¿Qué vas a aprender?

- Qué problema resuelve la mensajería basada en eventos y cuándo conviene
- La arquitectura de Kafka 4.2: brokers, tópicos, particiones, réplicas y el rol de KRaft
- Qué aporta cada componente de Confluent Platform 8.2.0 (Schema Registry, REST Proxy,
  ksqlDB, Kafka Connect) y en qué lab del curso lo vas a usar
- Cómo verificar que tu entorno de trabajo está listo

---

## Práctica: Validación del entorno (~30 min)

El curso trae un **botón único de validación** que audita tu plataforma y, si quieres, ejecuta
el harness completo de los 14 labs sobre Docker real.

### 1. Verificación rápida (recomendada para arrancar)

Desde la raíz del repositorio:

```bash
./validar-todo.sh --solo-preflight
```

Audita en segundos: que estén `docker`, `docker compose` v2, `bash`, `grep`, `sed` y `awk`, y
que los scripts del curso no usen construcciones que rompan en tu plataforma (macOS con BSD
`sed`/`grep`, o Windows con Git-Bash).

Debe terminar en **`PREFLIGHT OK`**. Los avisos marcados con `!` no son bloqueantes.

### 2. Validación funcional completa (opcional, ~15 min)

```bash
./validar-todo.sh
```

Levanta y derriba los 14 laboratorios en serie contra Docker real y emite un veredicto
cruzado. Es la prueba de fuego del entorno; requiere Docker Desktop corriendo y los puertos
del curso libres.

### 3. Diagnóstico dirigido (si algo falla)

```bash
./scripts/diagnostico/validar-ambiente.sh
```

Revisa lab por lab los prerrequisitos concretos (puertos, imágenes, RAM asignada a Docker) y
deja un reporte en `scripts/diagnostico/logs/`.

---

## Criterio de término

- [ ] `./validar-todo.sh --solo-preflight` termina en `PREFLIGHT OK`
- [ ] Docker Desktop corriendo, con al menos **8 GB de RAM** asignados
- [ ] Puertos `9092-9095`, `8081`, `8082`, `8088`, `8090` y `5432` libres en tu máquina
- [ ] Sabes explicar, con tus palabras, qué rol cumple KRaft y por qué el curso no usa ZooKeeper

---

## Prerrequisitos

| Requisito | Mínimo |
|-----------|--------|
| Docker Desktop | v4.x |
| RAM Docker | 8 GB (los labs multi-broker lo exigen) |
| Disco libre | 15 GB |
| Shell | bash (macOS/Linux) o Git-Bash (Windows) |

---

## Qué sigue

| Capítulo | Contenido | Labs |
|---|---|---|
| **Capítulo 2** | KRaft: metadatos, quórum y resiliencia | 01 · 02 |
| **Capítulo 3** | Configuración del clúster, tópicos y rendimiento | 03 · 04 · 05 · 06 · 07 · 08 |
| **Capítulo 4** | Clientes, REST Proxy y Schema Registry | 09 · 10 · 11 |
| **Capítulo 5** | ksqlDB, Kafka Connect y capstone de seguridad | 12 · 13 · 14 |

---

> **¿Te atascaste?** Si el preflight marca un bloqueante, córrelo con
> `./scripts/diagnostico/validar-ambiente.sh` para ubicar la causa exacta antes de seguir.

*Capítulo 1 - Curso de Administración de Confluent Apache Kafka (SUNAT)*
