# Tu Clúster - Espacio de Trabajo

## ¿Qué va aquí?

**Aquí construirás los archivos de tu clúster Kafka desde cero**, siguiendo las guías paso a paso.

Al final del laboratorio, esta carpeta deberá contener:

- `docker-compose.yml` (con los 3 brokers configurados)
- `.env` (con las variables de entorno como CLUSTER_ID, puertos, etc.)
- (cualquier otro archivo que decidas crear)

## ¿De dónde saco los archivos iniciales?

- En `../plantillas/` hay esqueletos comentados con TODOs que debes completar
- En `../soluciones/` están las soluciones de referencia (NO consultes hasta haber intentado)

## ¿Cómo trabajo aquí?

```bash
# Estás en lab-03-construye-tu-cluster/
cd mi-cluster

# Crear o editar tus archivos:
nano docker-compose.yml
nano .env

# Levantar TU clúster desde aquí:
docker compose up -d

# Detener:
docker compose down
```

## ¿Y si la cago?

```bash
# Desde la raíz del lab:
bin/reset-mi-cluster.sh
```

Esto detiene los contenedores, borra los volúmenes y limpia el storage. Quedas listo para empezar de nuevo.
