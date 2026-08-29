# taskflow-qa — día 2

Hoy los elementos ya no están todos ahí desde el principio.

## Antes de correr nada

```bash
git pull                 # en academyMty: trae el arreglo del 401 y la UI ya incluida
cd taskflow-api && mvn spring-boot:run -Dspring-boot.run.profiles=h2   # se siembra sola
mvn test                 # desde taskflow-qa, en otra terminal
```

## La tabla de esperas — es parte del entregable

| # | Qué esperaste | `ExpectedCondition` | Por qué esa y no otra |
|---|---|---|---|
| 1 | la lista de proyectos | `TODO` | TODO |
| 2 | que el spinner se fuera | `TODO` | TODO |
| 3 | que el botón fuera pulsable | `TODO` | TODO |
| 4 | el toast de éxito | `TODO` | TODO |
| 5 | la fila nueva en la lista | `TODO` | TODO |

## Las decisiones que hay que dejar escritas

**1. Implicit wait: desactivado. ¿Por qué?**

> TODO — y escríbelo bien, para que dentro de seis meses se sepa que fue una decisión y no un olvido.

**2. `presence` contra `visibility`: ¿cuándo cada una?**

> TODO

**3. ¿Por qué el nombre del proyecto lleva un UUID?**

> TODO

## Antes de entregar

```bash
grep -rc "Thread.sleep" src/     # tiene que dar 0
```

Y corre la suite **dos veces seguidas** sin tocar nada. Si la segunda falla, tienes un test
que depende de datos — y eso es tan flaky como un `sleep`.

## Nota sobre la navegación

En estos tests se llega a cada página **por URL**, no haciendo click en los enlaces.
No es un rodeo: aquí lo que se prueba es XPath y la interacción, **no el viaje entre páginas**.

Lee `NavegacionPorClickTest` entero: no está para navegar, sino para enseñarte
**cómo se diagnostica un click que no hace nada**.
