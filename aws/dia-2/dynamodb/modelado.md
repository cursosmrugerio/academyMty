# Modelado por patrones de acceso — explicado

> En SQL modelas las entidades y después consultas como quieras.
> En DynamoDB va al revés: **enumeras primero lo que vas a preguntar** y la tabla sale de ahí.
> Aquí están los cuatro patrones de TaskFlow ya resueltos: léelos contra la tabla que acabas de crear.

## Los cuatro patrones de TaskFlow

| # | «Necesito…» | ¿Se puede con una tabla `taskflow-eventos`? | Clave que lo sirve |
|---|---|---|---|
| 1 | el historial completo de una tarea, en orden cronológico | **Sí** | `query` con `taskId = :t`. La sort key `fechaHora` **ya lo devuelve ordenado**: no hay que ordenar nada después |
| 2 | el último evento de una tarea | **Sí** | el mismo `query` con `--no-scan-index-forward --max-items 1`: lee la partición al revés y para en el primero. **No lee el resto** |
| 3 | los eventos de una tarea a partir de una fecha | **Sí** | `query` con `taskId = :t AND fechaHora >= :desde`. Es exactamente para lo que existe la sort key |
| 4 | todas las tareas que **completó luis** este mes | **NO** | ninguna. `autor` y `tipo` no son parte de la clave |

## Las tres preguntas, respondidas

**1. Uno de los cuatro no cabe. ¿Cuál, y por qué?**

El **4**. DynamoDB solo sabe buscar por **clave**. `autor` y `tipo` son atributos normales: para
encontrarlos habría que leer la tabla entera con `scan` y filtrar después. El filtro se aplica
**después de leer**, así que no ahorra nada: pagas por recorrer todo.

Esta es la diferencia con MongoDB, que ya conoces: en Mongo pones un índice sobre `autor` y consultas
por ahí sin más. En DynamoDB, un patrón que no estaba previsto **no aparece solo**.

**2. ¿Qué harías con ese patrón?**

Un **índice secundario global (GSI)** con `autor` como partition key y `fechaHora` como sort key. Es
una proyección de la misma tabla con otra clave, y cuesta almacenamiento y escrituras aparte. Hoy no
se construye: lo que importa es saber **que ese es el sitio donde entra**, y que añadirlo después de
tener millones de elementos no es gratis.

La lección de fondo: en DynamoDB, **un patrón de acceso que no anticipaste se paga**. En una base
relacional se resuelve con un `WHERE` y quizá un índice. Por eso DynamoDB es excelente cuando sabes
exactamente qué vas a preguntar, y mala compañía cuando estás explorando.

**3. Si `taskId` fuera siempre el mismo valor —por ejemplo `"EVENTO"` como partition key para todo—
la tabla seguiría funcionando en clase. ¿Qué pasaría en producción?**

En clase, con cinco elementos, nada: funcionaría igual. En producción sería una **hot partition**: la
partition key decide en qué servidor físico vive el dato, así que *toda* la carga de escritura y
lectura caería sobre una sola partición mientras el resto del clúster está ocioso. Empezarías a ver
throttling con la tabla «vacía» y sin entender por qué.

Es el fallo clásico de quien llega del mundo relacional y elige la partition key como si fuera una
clave primaria cualquiera. **No es un identificador: es una decisión de reparto de carga.**
