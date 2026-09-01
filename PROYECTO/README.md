# Proyecto final · Administración integral del clúster de NovaTech Logistics

Esta carpeta tiene todo lo que necesitas para armar tu entrega. **Nada de esto reemplaza tu trabajo**, pero sí te ahorra el tiempo de averiguar qué formato usar, dónde va cada cosa y con qué comando se obtiene cada evidencia.

---

## Qué tienes que entregar

Dos archivos:

| Archivo | Qué es |
|---|---|
| **Expediente técnico en PDF** | El documento donde explicas tu trabajo, hito por hito, y respondes las seis preguntas de reflexión |
| **Archivo ZIP** | Tus archivos de configuración y las evidencias de ejecución |

**Aprobar requiere 11 puntos de 20.**

---

## Qué hay en esta carpeta

```
PROYECTO/
├── README.md                    ← estás aquí
├── PLANTILLA-EXPEDIENTE.md      ← el documento ya estructurado: rellenas y exportas a PDF
├── GUIA-DE-EVIDENCIAS.md        ← qué evidencia sirve para cada hito y con qué comando se saca
├── EJEMPLOS-DE-RESPUESTA.md     ← respuestas desarrolladas de ejemplo, para que veas el nivel esperado
├── CHECKLIST.md                 ← la última revisión antes de mandar
└── entrega/                     ← esto es lo que comprimes en el ZIP
    ├── configuracion/
    │   ├── hito-2-kraft/
    │   ├── hito-3-multibroker/
    │   └── hito-4-seguridad/
    └── evidencias/
        ├── hito-1/
        ├── hito-2/
        ├── hito-3/
        └── hito-4/
```

---

## Cómo trabajar

**1. Lee la `GUIA-DE-EVIDENCIAS.md` antes de empezar.** Te dice exactamente qué demuestra cada punto de la rúbrica y con qué comando se obtiene. Si sigues esa guía, no vas a entregar una captura que no prueba nada.

**2. Ve guardando las evidencias mientras haces los laboratorios**, no al final. Cada vez que un comando te dé una salida importante, guárdala en la carpeta del hito que corresponde. Recuperar eso después cuesta el triple.

**3. Copia tus archivos de configuración a `entrega/configuracion/`.** Cada carpeta tiene su propio `LEEME.md` diciéndote qué va ahí.

**4. Rellena la `PLANTILLA-EXPEDIENTE.md`.** Ya tiene todas las secciones en el orden que se evalúa. Los `[…]` son los lugares donde escribes tú.

**5. Mira los `EJEMPLOS-DE-RESPUESTA.md`** cuando no sepas qué profundidad se espera. Están desarrollados, pero son de un caso distinto al tuyo: **te muestran la forma, no la respuesta.**

**6. Pasa el `CHECKLIST.md`** antes de mandar nada.

---

## Sobre los archivos de configuración

Durante el curso, algunos laboratorios los construyes tú y otros se demuestran en pantalla. **Las dos cosas valen para el proyecto**, siempre que lo declares.

Si el archivo lo armaste tú, dilo. Si lo tomaste de la carpeta `soluciones/` del laboratorio, dilo también. **Lo que se evalúa es que entiendas qué hace cada línea**, no quién la escribió primero.

En cada carpeta de `entrega/configuracion/` hay un `LEEME.md` con un espacio para declararlo.

---

## Cómo nombrar las evidencias

La `GUIA-DE-EVIDENCIAS.md` propone un nombre para cada archivo y la plantilla del expediente los cita con ese mismo nombre. **Si sigues esos nombres, no tienes que decidir nada.**

Los nombres son una sugerencia, no un formato obligatorio. Si prefieres otros, cámbialos también en el expediente para que sigan coincidiendo. Sirve cualquier nombre que diga qué es y de dónde salió.

```
quorum-inicial.txt
quorum-tras-caida.txt
topico-retencion-corta.txt
acls.txt
```

**Nada de `captura1.png` ni `imagen final.jpg`.** Quien evalúa tiene que poder abrir el ZIP y entender qué es cada archivo sin abrirlo.

---

## Cómo guardar la salida de un comando

Dos formas, las dos válidas:

**Copiar y pegar en un archivo de texto** — sirve para salidas cortas y es lo más limpio:

```bash
<tu-comando> > evidencia.txt
```

**Captura de pantalla** — sirve cuando el color o el formato importan, o cuando la salida está en una interfaz web.

**Consejo:** para las salidas de comandos, el texto es mejor que la captura. Se puede leer, buscar y no se ve borroso.

---

## Si te pierdes

- **No sabes qué evidencia sirve** → `GUIA-DE-EVIDENCIAS.md`
- **No sabes cuánto escribir** → `EJEMPLOS-DE-RESPUESTA.md`
- **No sabes si te falta algo** → `CHECKLIST.md`
- **Perdiste una evidencia** → todos los laboratorios se pueden repetir. Levanta el lab de nuevo y vuelve a correr el comando.
