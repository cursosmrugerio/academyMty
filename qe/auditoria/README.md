# auditoría — el material contra el SUT, en rojo o verde

> ⚠ **Herramienta del instructor, y contiene SOLUCIONES.** Aquí dentro están, ya escritos y
> funcionando, el XPath del eje `parent::`, el testid del toast, el `Select` del filtro y el
> script que siembra la sesión. Si eres alumno y lo abres antes del viernes, te estás quitando
> los ejercicios a ti mismo.

Esto **no prueba TaskFlow**. Prueba que lo que las guías y el andamiaje **afirman** sobre
TaskFlow siga siendo cierto.

Nació de un caso concreto: la guía del jueves mandaba buscar en la página de registro «algo que
contenga `egistr`», y ahí no hay nada — el enlace del login dice «Regístrate», con una `í` en
medio de ese trozo. El ejercicio no se podía resolver, y nadie lo había notado leyendo, porque
leyendo se comprueba lo que uno sospecha, no lo que hay.

## Cómo se corre

```bash
cd taskflow-api && mvn spring-boot:run -Dspring-boot.run.profiles=h2   # en una terminal
cd qe/auditoria  && mvn test                                          # en otra
```

Si el SUT no está arriba, falla en una línea diciéndotelo. Otros interruptores:

```bash
mvn test -DbaseUrl=http://otro:9090     # auditar otro despliegue
mvn test -Dheadless=false               # verlo con tus ojos
```

## Qué imprime

Un libro mayor, **una línea por afirmación**, con el origen citado para que un rojo se pueda ir a
arreglar al archivo o al capítulo exacto:

```
FAMILIA   ORIGEN            AFIRMACION                                 ESPERADO  OBTENIDO
texto     LocalizacionTest#5  partialLinkText 'egistr' devuelve CERO      0         0        OK
texto     XPathTest#…         contains(text(),'Crear Cuenta') -> h2+btn   2         2        OK
compor    guia d5 c5          project-list YA visible antes del render    true      true     OK
...
TOTAL 38 afirmaciones · 38 cumplen · 0 FALLAN
```

Agregados no, ledger sí: un «37 de 38» no le sirve a nadie a las ocho de la mañana.

## Cuándo se corre

- **Antes de cada cohorte**, y desde luego antes del miércoles de la semana de QE.
- **Cada vez que alguien toque `taskflow-api/src/main/resources/static/`.** La UI es la superficie
  de contrato de tres días de ejercicios: renombrar un `data-testid` rompe guía y andamiaje a la vez.

## Cómo se añade una afirmación

Una línea. `check(familia, origen, qué afirma, esperado, cómo se mide)`:

```java
check("texto", "guia d4 c3", "//button[text()='Entrar']", 1,
        () -> x("//button[text()='Entrar']"));
```

El `origen` no es decorativo: es la dirección a la que va el que tenga que arreglarlo.

## Lo que esto NO decide

Rojo y verde solo alcanzan a lo ejecutable. Sigue haciendo falta un humano para:

- si el alumno trabaja en **un** repo propio o en `qe/dia-N` (guías y Moodle se contradicen);
- si el cierre del integrador el viernes a las 17:00 es sensato;
- si la **cobertura** de estas afirmaciones es la correcta — las eligió alguien, y ese es el
  residuo irreducible. Para los `data-testid` la enumeración sí es completa: se sacan de la UI y
  se contrastan contra el material, así que ninguno pasa por no haberlo mirado. Para la familia
  «por texto», todavía no.
