#!/bin/bash
# ============================================================
# format-storage.sh · ficha didáctica sobre kafka-storage format
# ============================================================
# Familia CREA, y el único de esta tanda que ESCRIBE en el disco del
# broker. Por eso la ficha se imprime ANTES de ejecutar: el aviso no
# sirve de nada si el alumno lo lee cuando el comando ya corrió.
#
# Tercer eslabón de la cadena. generate-cluster-id inventa la identidad,
# este la graba en el disco, verify-storage la confirma. Los tres usan
# las mismas palabras a propósito.
#
# Se corre una vez por broker, tres por lab, cuatro labs: doce veces en
# las tres primeras sesiones. El bloque final es corto y solo trae lo
# que cambia entre una corrida y la siguiente.
#
# Portabilidad exigida, macOS bash 3.2 y Git Bash. Sin declare -A,
# sin mapfile, sin grep -P, sin sed -i, sin jq.

set -euo pipefail

DIR_LAB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR_LAB/bin/common.sh"

flag_desc() {
    case "$1" in
        format)             echo "graba la identidad en el disco del broker y prepara el directorio de metadatos" ;;
        --cluster-id)       echo "la identidad que generaste antes. La misma en los tres brokers" ;;
        --config)           echo "de dónde saca en qué directorio escribir" ;;
        --ignore-formatted) echo "si ya estaba formateado, no lo vuelve a hacer y no falla" ;;
        *)                  flag_desc_comun "$1" ;;
    esac
}

# Kafka abre con una línea "Bootstrap metadata:" de 700 caracteres que
# lista los feature levels internos. No la explica nadie y tapa la única
# línea que importa. Se saca, y se avisa que se sacó.
f_legible() {
    printf '%s\n' "$1" | grep -v '^Bootstrap metadata:'
}

f_tenia_bootstrap() {
    printf '%s\n' "$1" | grep -q '^Bootstrap metadata:'
}

# ── Encabezado, con el aviso ANTES de ejecutar ───────────────
ficha_encabezado() {
    local contenedor="$1" cid="$2"

    ficha_abrir 'QUÉ VAMOS A HACER'
    ficha_texto "Grabar la identidad ${cid} en el disco de ${contenedor}"

    ficha_medio 'COMANDO REAL'
    ficha_comando "kafka-storage format --cluster-id ${cid} \\"
    ficha_comando '    --config /etc/kafka/kafka.properties --ignore-formatted'

    ficha_medio 'ESTO ESCRIBE EN EL DISCO'
    ficha_warn "format inicializa el directorio de metadatos de ${contenedor}. Es el único comando de esta sesión que no solo consulta."
    ficha_texto '--ignore-formatted te cubre las espaldas. Si el broker ya estaba formateado no toca nada, y si le pasas otra identidad se niega en vez de pisar la que había.'

    ficha_medio 'DESGLOSE'
    ficha_flag 'format'             ''     ''
    ficha_flag '--cluster-id'       "$cid" ''
    ficha_flag '--config'           '/etc/kafka/kafka.properties' ''
    ficha_flag '--ignore-formatted' ''     ''

    ficha_medio 'CÓMO SE LEE LA SALIDA'
    ficha_campo 'Formatting metadata directory' 'lo hizo ahora, el disco estaba vacío'
    ficha_campo 'already formatted'             'ya estaba hecho. No pasó nada y está bien'
    ficha_campo 'Invalid cluster.id'            'le pasaste una identidad distinta de la que ya tenía'

    ficha_cerrar
    ficha_nota "En el lab corre dentro del contenedor con docker exec ${contenedor}"
    ficha_nota 'En tu servidor, kafka-storage está en el PATH y no hace falta docker.'
    echo ''
}

# ── Resultado ────────────────────────────────────────────────
# Corto a propósito. Solo lo que cambia entre las doce corridas: qué
# broker y con qué identidad quedó. El alumno ya leyó el resto arriba.
resultado() {
    local salida="$1" contenedor="$2" cid="$3" rc="$4"

    ficha_abrir 'RESULTADO'

    if [ "$rc" -ne 0 ]; then
        local leido
        leido=$(printf '%s\n' "$salida" | sed -n 's/.*but read \([A-Za-z0-9_-]*\).*/\1/p' | head -1)
        if [ -n "$leido" ]; then
            ficha_warn "${contenedor} no se formateó. Ya tenía grabada la identidad ${leido}, que no es la que le pasaste."
            ficha_texto 'Kafka se negó a pisarla. Si de verdad querés empezar de cero, hay que borrar el volumen de datos primero.'
        else
            ficha_warn "${contenedor} no se formateó. Lo que devolvió Kafka está acá arriba."
        fi
        ficha_cerrar
        return 0
    fi

    case "$salida" in
        *'already formatted'*)
            ficha_texto "${contenedor} ya estaba formateado. No se tocó nada."
            ;;
        *)
            ficha_texto "${contenedor} quedó grabado con la identidad ${cid}."
            ;;
    esac
    ficha_causa '  Confirmalo' "bin/verify-storage.sh ${contenedor}"

    ficha_cerrar
}

# ── Programa principal ───────────────────────────────────────
main() {
    if [ $# -ne 2 ]; then
        echo "Uso: $0 <NOMBRE_CONTAINER> <CLUSTER_ID>" >&2
        echo "Ejemplo: $0 kafka-broker-1 MkU3OEVBNTcwNTJENDM2Qk" >&2
        exit 1
    fi
    local contenedor="$1" cid="$2"

    ficha_init_color

    if ! docker ps --filter "name=^${contenedor}$" --format '{{.Names}}' \
        | grep -q "^${contenedor}$"; then
        echo "[ERROR] El contenedor '${contenedor}' no está corriendo." >&2
        echo "  Pista: levanta tu clúster primero con 'docker compose up -d'." >&2
        exit 1
    fi

    # La ficha se imprime ANTES de correr el comando, al revés que en los
    # wrappers que solo consultan. Un aviso que llega después de escribir
    # en el disco no es un aviso.
    if ficha_activa; then
        ficha_encabezado "$contenedor" "$cid"
    fi

    local salida='' rc=0
    salida=$(docker exec "$contenedor" kafka-storage format \
        --cluster-id "$cid" \
        --config /etc/kafka/kafka.properties \
        --ignore-formatted 2>&1) || rc=$?

    if ! ficha_activa; then
        printf '%s\n' "$salida"
        exit "$rc"
    fi

    ficha_cruda 'Esto devolvió Kafka' "$(f_legible "$salida")"
    if f_tenia_bootstrap "$salida"; then
        ficha_nota_salida 'Se omite la línea Bootstrap metadata, que lista los feature levels'
        ficha_nota_salida 'internos. Para verla, corre el comando de arriba a mano.'
    fi
    echo ''
    resultado "$salida" "$contenedor" "$cid" "$rc"
    exit "$rc"
}

# El bloque principal no corre si el archivo se importa. Se usa para
# revisar el formato sin depender de un clúster vivo.
if [ "${FICHA_SOLO_FUNCIONES:-}" != "1" ]; then
    main "$@"
fi
