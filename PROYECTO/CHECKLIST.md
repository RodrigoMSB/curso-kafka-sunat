# Checklist de entrega

Revisa esto **antes** de mandar nada. Cinco minutos aquí te ahorran una corrección.

---

## Los dos archivos

- [ ] Tengo el **expediente en PDF** (no en Word, no en Markdown: en PDF)
- [ ] Tengo el **ZIP** con la carpeta `entrega/` completa
- [ ] Los dos archivos llevan mi nombre: `Apellido-Nombre-expediente.pdf` y `Apellido-Nombre-entrega.zip`

## El expediente

- [ ] Tiene mi nombre completo en la portada
- [ ] Están las **cuatro secciones de hitos**, ninguna vacía
- [ ] Están las **seis preguntas de reflexión** respondidas
- [ ] Borré el recuadro de instrucciones de la plantilla
- [ ] No quedó ningún `[…]` sin rellenar
- [ ] El resumen ejecutivo está escrito (es lo primero que se lee y lo último que se escribe)

## Las evidencias

- [ ] **Hito 1** — el diagrama de topología y la justificación del dimensionamiento
- [ ] **Hito 2** — el quórum **antes** y **después** de la caída
- [ ] **Hito 3** — los tópicos con sus `Configs` distintas, y una comparación de rendimiento
- [ ] **Hito 4** — las ACLs cargadas y **al menos una prueba negativa**
- [ ] Cada archivo tiene un nombre que dice qué es
- [ ] Cada evidencia está mencionada en el expediente, no solo suelta en el ZIP

## Los archivos de configuración

- [ ] Copié mis `docker-compose.yml` a `entrega/configuracion/`
- [ ] Llené el `LEEME.md` de cada carpeta declarando el origen
- [ ] **No incluí llaves privadas ni contraseñas** en texto plano

## La prueba final

Ábrete el ZIP como si fueras quien lo va a evaluar y pregúntate:

- [ ] ¿Se entiende qué es cada archivo **sin abrirlo**?
- [ ] ¿El expediente **explica** las evidencias, o solo las pega?
- [ ] Si alguien lee solo mi expediente sin abrir el ZIP, **¿entiende qué construí?**

---

## Los cuatro errores que más se repiten

**1. Entregar la foto final sin el antes.**
Una captura del clúster funcionando no demuestra resiliencia. La demostración es el contraste.

**2. Pegar una salida sin explicarla.**
Quien evalúa no tiene que adivinar qué campo miraste. Di qué línea importa y por qué.

**3. Una sola medición de rendimiento.**
Un número solo no dice si está bien o mal. Rendimiento es siempre comparación.

**4. Mostrar solo lo que funciona en seguridad.**
La seguridad se demuestra con lo que rechaza. Sin una prueba negativa, el hito 4 queda a medias.
