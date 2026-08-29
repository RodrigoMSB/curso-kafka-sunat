# REPASO

Ejercicios cortos para volver sobre un concepto, sin tener que rehacer un laboratorio entero.

Cada repaso trata **un solo concepto**, se hace en unos cinco minutos y levanta su propio clúster. No necesitas tener nada arriba ni haber hecho el laboratorio donde el tema aparece por primera vez.

## En qué se diferencia de un laboratorio

Un laboratorio te enseña a operar. Tiene su caso, sus catorce pasos y su clúster completo, y te toma cuarenta y cinco minutos.

Un repaso te devuelve una idea. Levanta lo mínimo que hace falta para verla, te muestra tres salidas y te explica qué dice cada una.

Si ya hiciste el laboratorio y algo se te desdibujó, este es el lugar. Si nunca lo hiciste, también sirve, porque no da por sabido nada del curso.

## Repasos disponibles

| Repaso | Concepto | Dura |
|---|---|---|
| [01-quorum](01-quorum/) | Por qué tres controladores aguantan perder uno y no dos | 5 min |

## Cómo se usa cualquiera de ellos

```bash
cd REPASO/01-quorum
bash bin/start.sh
```

Sigue el `README.md` de la carpeta, y al terminar bájalo.

```bash
bash bin/stop.sh
```

## Dos cosas que valen para todos

**No chocan con los laboratorios.** Cada repaso usa su propio nombre de proyecto y puertos fuera del rango del curso, así que puedes repasar con un laboratorio levantado y ninguno se lleva al otro por delante.

**No dejan residuos.** El `stop.sh` borra los contenedores, los volúmenes y la red del repaso, y te muestra las tres cuentas en cero.
