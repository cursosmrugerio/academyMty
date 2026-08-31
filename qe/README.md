# QE — Semana 5, de miércoles a viernes

El andamiaje de los tres días de automatización de pruebas. Cada carpeta es un proyecto Maven que
**ya compila** y trae los `// TODO` que completas tú.

| Carpeta | Día | Tema |
|---|---|---|
| `dia-1/` | **miércoles 9-sep** | Fundamentos, arquitectura de Selenium y localizadores CSS |
| `dia-2/` | **jueves 10-sep** | XPath, interacción con elementos y **esperas** |
| `dia-3/` | **viernes 11-sep** | Page Object Model |

> Ojo con la numeración: son los días **1, 2 y 3 de QE**, que caen en el **3.º, 4.º y 5.º de la
> semana**. Si tu guía habla del jueves, tu carpeta es `dia-2/`.

## Antes de abrir nada: dónde vive tu código

Estas tres carpetas **no son tres proyectos que se hacen por separado**. Son las piezas nuevas
que se añaden cada día **al mismo proyecto**, y ese proyecto es tuyo y vive en **tu** repositorio,
no en este. Aquí solo se lee.

👉 **[`COMO-TRABAJAS.md`](COMO-TRABAJAS.md)** — los comandos exactos de cada día. Léelo el
miércoles antes que nada; si el jueves empiezas de cero, el viernes no te va a salir el ejercicio
con el que abre el día.

## El sujeto de prueba está en este mismo repo

Se automatiza **`taskflow-api/`**, que además ya trae la UI dentro. Arráncalo así y ya tienes
todo — no hay que copiar nada ni sembrar datos:

```bash
cd taskflow-api
mvn spring-boot:run -Dspring-boot.run.profiles=h2
```

`http://localhost:8080/` muestra el login. Usuario **`ana`**, contraseña **`ana123`**. La base es
en memoria y se puebla sola en cada arranque, así que si enredas los datos basta con reiniciar.

## Las soluciones no están aquí

Y no es un olvido: el ejercicio es escribirlas. Se revisan en clase.

**Con una excepción, y va avisada.** [`auditoria/`](auditoria/) no es material de clase: es la
herramienta con la que se comprueba que lo que las guías afirman sobre TaskFlow siga siendo
cierto —que cada localizador que nombran encuentre algo— y para eso tiene que traerlos ya
resueltos. Su README lo avisa en la primera línea. Si eres alumno, no la abras hasta el viernes.

Existe porque hizo falta: la guía del jueves mandaba buscar en la página de registro «algo que
contenga `egistr`», y ahí no había nada. Leyendo no se vio; ejecutando, sí.
