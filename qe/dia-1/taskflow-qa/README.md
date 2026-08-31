# taskflow-qa — <TU USUARIO>

Suite de automatización sobre TaskFlow. Crece los tres días: hoy encuentra elementos,
mañana los usa y los espera, el viernes se convierte en un framework.

> **Esta carpeta no es tu proyecto: es el andamiaje de hoy.** Tu proyecto lo creas a partir de
> ella, en un repositorio tuyo, y es el mismo los tres días.
> Cómo, en **[`qe/COMO-TRABAJAS.md`](../../COMO-TRABAJAS.md)** — hazlo antes de escribir la
> primera línea.

## Cómo se corre

```bash
mvn test                                  # contra http://localhost:8080
mvn test -DbaseUrl=http://otro:9090       # contra otro sitio, sin tocar código
```

**El SUT tiene que estar arriba antes.** Si `mvn test` falla con `NoSuchElementException` en todo,
lo primero que se comprueba es abrir la URL a mano en el navegador.

## Estructura

```
src/test/java/com/taskflow/qa/
├── tests/     lo que se prueba (y las aserciones)
├── pages/     vacío hoy — se llena el viernes
└── utils/     Paginas.java: el único sitio donde vive una URL
```

`pages/` nace vacía **a propósito**. Vas a entender para qué sirve cuando te duela no tenerla.

## La tabla de justificación — es parte del entregable

Por cada objetivo, qué estrategia elegiste y **por qué esa y no otra**.
Sin esta tabla, la suite es copiar selectores y no cuenta como entregada.

| # | Objetivo | Localizador que usé | Por qué esa estrategia |
|---|---|---|---|
| 1 | El campo de usuario | `TODO` | TODO |
| 2 | El botón de entrar | `TODO` | TODO |
| 3 | El campo de contraseña es de tipo password | `TODO` | TODO |
| 4 | El contenedor de errores | `TODO` | TODO |
| 5 | El enlace de registro | `TODO` | TODO |
| 6 | Los dos campos de texto | `TODO` | TODO |
| 7 | El botón es hijo directo del formulario | `TODO` | TODO |
| 8 | Un elemento que no existe | `TODO` | TODO |

## Las dos preguntas del día

**1. ¿Por qué `id` gana a XPath en la jerarquía?**

> TODO

**2. ¿Qué hace frágil a un localizador? Da un ejemplo de uno tuyo que lo sea, y cómo lo mejorarías.**

> TODO

## Reglas de la casa

- **Ningún localizador se escribe sin haberlo validado antes en DevTools** con `$$("...")`.
- **Cero `Thread.sleep`.** Hoy ni hace falta; a partir de mañana está prohibido y se comprueba con `grep`.
- Ninguna URL escrita a mano en un test: todas salen de `utils/Paginas`.
