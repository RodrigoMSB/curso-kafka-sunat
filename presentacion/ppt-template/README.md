# Plantilla corporativa Netec

`plantilla-netec.pptx` — plantilla base para construir las PPT del curso.
Las presentaciones (`presentacion/ppt/capN-*.pptx`) se construyen **sobre esta plantilla**
para heredar sus master slides, layouts, tipografías y logos corporativos.

## Origen y limpieza

Extraída de `curso-strimzi-COMPLETO.pptx` (la misma plantilla Netec de Lucy, usada en el
curso Strimzi): se conservaron **masters, layouts, tema y media (logos)** y se eliminaron
las 128 diapositivas de contenido de Strimzi, sus notas y las referencias huérfanas.
Metadata saneada: **autor = Rodrigo Silva** (el original decía otra persona); sin contenido
de otro curso. El deck Strimzi original NO se versiona aquí (vive en su propio repo).

## Layouts disponibles (27)

Portada del curso · Propiedad intelectual · Descripción del curso · Objetivos del curso ·
Prerrequisitos del curso · Audiencia del curso · Temario del curso · Presentación del grupo ·
Portada del capítulo · Nombre del tema · Nombre del tema 2 · Contenido - General ·
Contenido - Imagen 1/2/3/4 · Contenido - Comparativo · Contenido - En blanco ·
Contenido - Código 100 · Contenido - Código 50, Descripción 50 · Contenido2 - Código 50, Descripción 50 ·
Contenido - 2 códigos verticales · Resumen del capítulo · Descripción de la práctica ·
Solución de la práctica · Referencias bibliográficas del capítulo · Final de la presentación

Verificada: 0 diapositivas, zip sin duplicados, round-trip (agregar slide desde layout) OK.
`python-pptx` (1.0.2) disponible para el vertido guion → PPT.

## Cómo se usa

`Presentation("presentacion/ppt-template/plantilla-netec.pptx")` como base; por cada slide del
guion se hace `add_slide(layout_adecuado)` y se pueblan placeholders (cuerpo) y notas del orador.
