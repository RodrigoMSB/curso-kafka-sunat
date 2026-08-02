#!/bin/bash
# ============================================================
# verify-storage.sh · ficha didáctica sobre kafka-storage info
# ============================================================
# Familia LEE. Solo consulta, no toca nada. Es de los primeros comandos
# que el alumno corre en su vida, en la sesión 1 del curso.
#
# Tiene un camino alternativo: si kafka-storage info falla, se cae a
# listar el directorio de datos. La ficha muestra SIEMPRE el comando que
# se ejecutó de verdad, no el primero de los dos, y dice cuando cayó.
#
# La ficha se dibuja solo en una terminal. Al tuberiar sale nada más que
# lo que devolvió la herramienta.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

flag_desc() {
    case "$1" in
        info) echo "solo consulta, no toca nada" ;;
        -c)   echo "el archivo de configuración del broker, de donde saca dónde vive el log" ;;
        -la)  echo "listado largo, para ver permisos y tamaños" ;;
        *)    flag_desc_comun "$1" ;;
    esac
}

# ── Lectura de la salida de kafka-storage info ───────────────
# El formato es un par de líneas sueltas y un bloque "Found metadata:"
# con pares clave=valor entre llaves.
v_meta() {
    printf '%s\n' "$2" | sed -n "s/.*[{,] *$1=\([^,}]*\).*/\1/p" | head -1
}

v_directorio() {
    printf '%s\n' "$1" | sed -n 's/^ *\(\/[^ ]*\) *$/\1/p' | head -1
}

# Es salida válida de kafka-storage info solo si trae el bloque de
# metadata con un cluster.id. Sin eso no hay nada que diagnosticar y se
# declara así, nunca se estima.
v_es_info() {
    printf '%s\n' "$1" | grep -q 'cluster.id='
}

# ── Encabezado de la ficha ───────────────────────────────────
# $2 vale 1 cuando se ejecutó el camino alternativo.
ficha_encabezado() {
    local contenedor="$1" cayo="$2"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Preguntarle al broker ${contenedor} si su almacenamiento está formateado y con qué identidad de clúster quedó"

    ficha_medio 'COMANDO REAL'
    if [ "$cayo" -eq 1 ]; then
        # Se muestra el que corrió de verdad. Mostrar el primero sería
        # mentirle al alumno sobre de dónde salió lo que está leyendo.
        ficha_comando "docker exec ${contenedor} ls -la /var/lib/kafka/data"
    else
        ficha_comando "kafka-storage info -c /etc/kafka/kafka.properties"
    fi

    ficha_medio 'DESGLOSE'
    if [ "$cayo" -eq 1 ]; then
        ficha_flag 'ls'  '-la' '-la'
        ficha_flag '/var/lib/kafka/data' '' ''
    else
        ficha_flag 'info' '' ''
        ficha_flag '-c'   '/etc/kafka/kafka.properties' '-c'
    fi

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    if [ "$cayo" -eq 1 ]; then
        ficha_campo 'meta.properties'      'el archivo que guarda la identidad. Si está, hubo formateo'
        ficha_campo '__cluster_metadata-0' 'el log de metadatos de KRaft. Acá vive el estado del clúster'
        ficha_campo '.lock'                'el broker vivo marca el directorio como suyo'
    else
        ficha_campo 'Found log directory' 'dónde guarda los datos este broker'
        ficha_campo 'cluster.id'          'la identidad del clúster. Los tres brokers llevan la misma'
        ficha_campo 'node.id'             'quién es este broker dentro del clúster'
        ficha_campo 'directory.id'        'identifica este directorio de datos en particular'
        ficha_campo 'version'             'la versión del formato de metadatos en disco'
    fi

    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${contenedor}"
    ficha_nota 'En su servidor, kafka-storage está en el PATH y no hace falta docker.'
    echo ''
}

# ── Diagnóstico ──────────────────────────────────────────────
# Todo sale de la salida que devolvió la herramienta. Nada se estima.
diagnostico_storage() {
    local salida="$1" contenedor="$2" cayo="$3"
    local cid nid did dir ver

    ficha_abrir 'DIAGNÓSTICO'

    if [ "$cayo" -eq 1 ]; then
        # Sin kafka-storage info no hay identidad que leer. Se dice qué se
        # pudo ver y qué no, y no se afirma que el formateo esté bien.
        ficha_texto 'kafka-storage info no respondió, así que lo de arriba es el listado del directorio de datos.'
        ficha_vacia
        if printf '%s\n' "$salida" | grep -q 'meta.properties'; then
            ficha_texto 'Está meta.properties, o sea que el formateo ocurrió alguna vez. Lo que no puedo decirte desde acá es con qué cluster.id quedó.'
        else
            ficha_warn 'No aparece meta.properties. Este directorio no está formateado.'
        fi
        ficha_vacia
        ficha_causa '  Ver la identidad' "docker exec ${contenedor} cat /var/lib/kafka/data/meta.properties"
        ficha_cerrar
        return 0
    fi

    cid=$(v_meta 'cluster.id' "$salida")
    nid=$(v_meta 'node.id' "$salida")
    did=$(v_meta 'directory.id' "$salida")
    ver=$(v_meta 'version' "$salida")
    dir=$(v_directorio "$salida")

    ficha_texto "El almacenamiento de ${contenedor} está formateado y en pie."
    if [ -n "$dir" ]; then
        ficha_texto "Guarda sus datos en ${dir}."
    fi
    if [ -n "$nid" ]; then
        ficha_texto "Este broker es el nodo ${nid} del clúster."
    fi
    ficha_vacia
    ficha_texto "La identidad del clúster es ${cid}."
    ficha_texto 'Los tres brokers tienen que tener exactamente esa misma cadena. Si alguno tiene otra, no van a formar quórum entre ellos.'
    if [ -n "$did" ]; then
        ficha_vacia
        ficha_texto "El directory.id ${did} es de este directorio y no del clúster, y por eso es distinto en cada broker. No debe copiarse entre nodos."
    fi
    if [ -n "$ver" ]; then
        ficha_texto "El formato de metadatos en disco es la versión ${ver}."
    fi

    ficha_cerrar
}

diagnostico_sin_contenedor() {
    local contenedor="$1"
    ficha_abrir 'DIAGNÓSTICO'
    ficha_texto "El contenedor ${contenedor} no está corriendo, así que no hay a quién preguntarle."
    ficha_vacia
    ficha_causa '  ¿Qué hay levantado?' 'docker ps -a'
    ficha_causa '  Levantar el clúster'  'docker compose up -d'
    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    if [ $# -lt 1 ]; then
        echo "Uso: $0 <NOMBRE_CONTAINER>" >&2
        echo "Ejemplo: $0 kafka-broker-1" >&2
        exit 1
    fi
    local contenedor="$1"

    ficha_init_color

    if ! docker ps --filter "name=^${contenedor}$" --format '{{.Names}}' \
        | grep -q "^${contenedor}$"; then
        if ! ficha_activa; then
            echo "[ERROR] El contenedor '${contenedor}' no está corriendo." >&2
            exit 1
        fi
        ficha_encabezado "$contenedor" 0
        diagnostico_sin_contenedor "$contenedor"
        exit 1
    fi

    # Se ejecuta ANTES de imprimir. Es la única forma de saber cuál de los
    # dos comandos fue el que corrió, que es el que la ficha debe mostrar.
    local salida='' cayo=0 rc=0
    salida=$(docker exec "$contenedor" kafka-storage info \
        -c /etc/kafka/kafka.properties 2>&1) || rc=$?
    if [ "$rc" -ne 0 ] || ! v_es_info "$salida"; then
        cayo=1
        salida=$(docker exec "$contenedor" ls -la /var/lib/kafka/data 2>&1) || true
    fi

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit 0
    fi

    ficha_encabezado "$contenedor" "$cayo"
    if [ "$cayo" -eq 1 ]; then
        # El ls -la es tabular. Envolverlo desalinea los nombres de archivo.
        ficha_cruda 'Esto devolvió la herramienta' "$salida"
    else
        # kafka-storage info son pares clave=valor en una linea de 114
        # columnas. No hay columnas que romper y sin envolver se sale.
        ficha_cruda_envuelta 'Esto devolvió la herramienta' "$salida"
    fi
    echo ''
    diagnostico_storage "$salida" "$contenedor" "$cayo"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato sin depender de un clúster vivo.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
