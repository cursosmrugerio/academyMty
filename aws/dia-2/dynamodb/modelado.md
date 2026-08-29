# Modelado por patrones de acceso — en parejas, sin tocar la consola

> En SQL modelas las entidades y después consultas como quieras.
> En DynamoDB va al revés: **enumeras primero lo que vas a preguntar** y la tabla sale de ahí.

## Los cuatro patrones de TaskFlow

| # | «Necesito…» | ¿Se puede con una tabla `taskflow-eventos`? | Clave que lo sirve |
|---|---|---|---|
| 1 | el historial completo de una tarea, en orden cronológico | TODO | TODO |
| 2 | el último evento de una tarea | TODO | TODO |
| 3 | los eventos de una tarea a partir de una fecha | TODO | TODO |
| 4 | todas las tareas que **completó luis** este mes | TODO | TODO |

## Las tres preguntas

**1. Uno de los cuatro no cabe. ¿Cuál, y por qué?**

> TODO

**2. ¿Qué harías con ese patrón? Nombra la salida (no hace falta construirla).**

> TODO

**3. Si `taskId` fuera siempre el mismo valor —por ejemplo, si usaras `"EVENTO"` como
partition key para todo— la tabla seguiría funcionando en clase. ¿Qué pasaría en producción?**

> TODO
