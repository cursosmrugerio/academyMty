# academyMty — Ejercicios de clase

Código que trabajamos en vivo durante las sesiones de Java de la **Academia Monterrey**.

Cada proyecto es un proyecto de Eclipse independiente. Dentro de cada uno, los paquetes
`com.curso.v0`, `v1`, `v2`, `v3` son **versiones sucesivas del mismo ejemplo**: v0 es el punto
de partida y cada versión siguiente cambia una sola cosa para que se vea el efecto. Conviene
leerlos en ese orden.

Varias líneas están **comentadas a propósito**: son los casos que no compilan o que truenan en
ejecución. Descoméntalas y observa el error — ese es el ejercicio.

---

## `Inicio` — Objetos, polimorfismo y casting

| Paquete | Archivo | Tema |
|---|---|---|
| `v0` | `Principal` | Qué imprime realmente `System.out.println(objeto)`. **No es la dirección de memoria.** |
| `v1` | `Principal` | Sobrescribir `hashCode()` y `equals()` y ver cómo cambia lo anterior. |
| `v1` | `Principal2` | Polimorfismo: una referencia `Ave` apuntando a `Pinguino`, `Aguila`, `Perico`. |
| `v2` | `Principal` | El padre aporta `volarAve()`; para llegar a `volarPerico()` hace falta un cast. |
| `v2` | `Principal2` | `String` es inmutable: `concat()` no modifica, devuelve otro objeto. |
| `v3` | `Principal` | Jerarquía de 3 niveles: **upcast**, **downcast**, `instanceof` y `ClassCastException`. |

## `static_java` — Instancia vs. clase

| Paquete | Tema |
|---|---|
| `v0` | Método de instancia (`new Principal().transforma(...)`) contra método de clase (`static`). |
| `v1` | `contador` como atributo de instancia: cada `Pato` lleva el suyo, los tres imprimen `1`. |
| `v2` | `contador` como `static`: se comparte entre todos, los tres imprimen `3`. |
| `v3` | Encapsulamiento: `private static` + `getContador()` estático. |

## `final_java` — La palabra `final`

| Paquete | Tema |
|---|---|
| `v0` | `final` sobre un primitivo, sobre un mutable (`StringBuilder`) y sobre un inmutable (`String`). La clave: **`final` congela la referencia, no el contenido.** |
| `v1` | `final class Ave` — una clase final no se puede heredar (descomenta `Pato extends Ave`). |
| `v2` | Ahora `final` va en los **métodos**, no en la clase: `Pato` sí puede heredar, pero no puede sobrescribir `volarAve()`. Y el `static final volar()` marca la diferencia entre **sobrescribir** y **ocultar** (`HIDDEN`): un método de clase no se sobrescribe. |

## `stringStringBuilder` — String vs. StringBuilder

| Paquete | Archivo | Tema |
|---|---|---|
| `v0` | `Principal` | Concatenar `String` dentro de un ciclo de 1,000,000 de iteraciones. Ojo al tiempo. |
| `v0` | `Principal1` | El mismo ciclo con `StringBuilder.append()`. Compara. |
| `v0` | `Principal2` | `String` sobrescribe `equals()` → `true`. `StringBuilder` **no** → `false`. |
| `v1` | `Principal` | `equals()` propio en `Pato`, comparando con `==`. ¿Por qué funciona aquí y cuándo dejaría de hacerlo? |

## `paso_parametros` — Qué le pasa a un argumento al entrar a un método

| Paquete | Tema |
|---|---|
| `v0` | Se pasan un `int`, un `String` y un `StringBuilder` al mismo método. Uno de los tres vuelve cambiado al `main`. **Java siempre pasa por valor** — lo que se copia es la referencia, no el objeto: por eso `sb.append()` sí se ve fuera y `x = x + 10` no. |

Dentro del método, `cadena` sigue valiendo `Hello`: `concat()` devuelve **otro** `String` y por eso hay que
retornarlo. Las dos líneas comentadas están ahí para comprobarlo.

### El diagrama de la clase

![Paso de parámetros: dos marcos de pila y los objetos del heap](paso_parametros/doc/paso-parametros-stack-heap.jpeg)

Cómo se lee, elemento por elemento:

| En el dibujo | En el código |
|---|---|
| Los **dos post-its** | Dos marcos de pila distintos: `main()` y `transforma()`. Cada uno con sus propias variables. |
| **Dos cajas `int x`** | `x = x + 10` cambia la de `transforma` (pasa a 20). La de `main` sigue en 10 y ni se entera. |
| Las **nubes** | El heap. `cadena` y `sb` no guardan el objeto: guardan **a dónde apuntar**. Eso es lo que se copia al llamar al método. |
| Los **dos `sb` a la misma nube** | Una sola nube `"Hola Mundo"`, dos referencias. Por eso `sb.append()` sí se ve desde `main`. |
| `"Hello World"` es una nube **aparte** | `concat()` no tocó `"Hello"`: creó otro objeto. Por eso hay que **retornarlo** — si no, se pierde. |
| `"Hello"` sin ninguna flecha | Ya nadie la apunta: es basura para el recolector. |

Ese es el resumen en una frase: **Java siempre pasa por valor.** Lo que se copia es la referencia,
nunca el objeto — y por eso puedes *modificar* lo que hay al otro lado, pero no puedes *cambiar a
dónde apunta* la variable del que te llamó.

## Pruebas unitarias — `demoTestJunit`, `demoTestJunit2`, `mockitoWithout`, `mockito`

Cuatro proyectos en ese orden: primero cómo se escribe un test, después por qué a veces no se
puede escribir sin ayuda.

| Proyecto | Qué trae | Cómo se corre |
|---|---|---|
| `demoTestJunit` | 9 tests de JUnit 5 sueltos: `assertEquals`, `assertAll`, `assertThrows` y el `assertTrue` con mensaje diferido. | Solo Eclipse (`Run As → JUnit Test`). No tiene build fuera del IDE. |
| `demoTestJunit2` | `Calculator` probado con `@BeforeEach` y `@RepeatedTest(3)`: 5 métodos escritos → **7 tests ejecutados**. | Eclipse o `mvn test`. |
| `mockitoWithout` | `ServiceCalculoImpuesto` delegando en la implementación **real** de `ICalculoComplejo`. Sin tests: solo un `main` que imprime. | `Run As → Java Application`. |
| `mockito` | El mismo servicio cuando esa implementación **no existe**. 12 tests en 5 clases. | Eclipse o `./mvnw test`. |

**`mockitoWithout` y `mockito` son el mismo código y hay que verlos juntos**, en ese orden.
Ejecuta el `main` de los dos:

| | Resultado |
|---|---|
| `mockitoWithout` | imprime `3.4236650365470685E7` — la implementación existe. |
| `mockito` | `NullPointerException` — solo tenemos la interfaz. |

En el segundo, la implementación la escribe un tercero y en producción la inyecta el framework
(el `//@Autowired` que está en el código). Sin nadie que rellene ese hueco, el servicio no
arranca. Ese contraste es la pregunta que Mockito responde — y aun así `./mvnw test` da 12 en
verde, porque el servicio sí se puede probar entero.

Las cinco clases de `mockito/src/test/java` toman una idea cada una:

| Clase | Idea |
|---|---|
| `SinElTerceroTest` | Se prueba el servicio aunque nadie haya escrito el cálculo. Y un mock sin entrenar no falla: **devuelve `0.0`**. |
| `ArgumentosTest` | Si el resultado es del tercero, lo tuyo es la **llamada**: `verify` y `ArgumentCaptor` sobre los seis primitivos. |
| `InyeccionTest` | `@Mock` + `@InjectMocks`: Mockito hace en el test lo que `@Autowired` hará en producción. |
| `FallosDelTerceroTest` | `thenThrow`, negativos y `NaN` — escenarios imposibles de provocar con la implementación real. |
| `TrampaDeMatchersTest` | Mezclar matchers con valores crudos revienta. Con seis parámetros es casi inevitable. |

Para el tratamiento completo del tema —315 tests, cinco guías y scripts que demuestran midiendo—
está la carpeta [`testing/`](testing/). Estos cuatro son la versión que se escribió en clase.

## `taskflow-api` — todo junto, como en un trabajo real

El resto del repositorio aísla **un** concepto por carpeta. Este proyecto hace lo contrario: es
la API REST completa de **TaskFlow**, con todo funcionando a la vez.

| Capa | Qué hay |
|---|---|
| Web | Controladores REST, DTOs como `record`, validación con Jakarta, Swagger UI |
| Seguridad | Login con **JWT**, filtro propio, roles, y la distinción `401` (no sé quién eres) vs `403` (sé quién eres y no puedes) |
| Dominio | Las reglas de negocio viven en la **entidad**, no en el servicio: `Task.crear` y `Task.setStatus` |
| Errores | Un `@RestControllerAdvice` traduce cada excepción a su código HTTP: `400`, `403`, `404`, `422` |
| Datos | JPA/Hibernate sobre **H2** en local y **Postgres** en Docker — el mismo código, sin tocar una línea |
| Pruebas | 67 tests en tres niveles + gate de cobertura del 70% (`mvn verify`) |
| Entrega | `Dockerfile` multi-etapa y `docker compose` que levanta API + Postgres |

Lo interesante de leerlo no es que funcione: es **por qué cada regla está donde está**. Cada una
nació de un problema concreto del cliente, y eso se cuenta en su
[`README`](taskflow-api/README.md).

**Para levantarlo no instalas nada**: ni JDK, ni Maven, ni Postgres. Basta con Docker Desktop
actual — el que trae Compose v2, que se comprueba con `docker compose version`.

```bash
cd taskflow-api
docker compose up --build
```

Eso levanta la API **y** su base de datos PostgreSQL, ya sembrada. Abre
`http://localhost:8080/swagger-ui/index.html` y entra con `ana` / `ana123`. La guía completa
—qué acabas de levantar, cómo comprobarlo, cómo pararlo y qué hacer si el puerto está
ocupado— está en su [`README`](taskflow-api/README.md).

---

## `aws/` y `qe/` — la semana 5, y por qué están aquí

Estas dos carpetas no son ejercicios de clase resueltos como el resto del repositorio: son
**andamiaje con `// TODO` que completas tú** durante la semana del 7 al 11 de septiembre.

| Carpeta | Días | Qué es |
|---|---|---|
| [`aws/`](aws/) | lunes y martes | Desplegar `taskflow-api` en AWS: primero a mano sobre una EC2, después con un pipeline que lo hace solo |
| [`qe/`](qe/) | miércoles a viernes | Automatizar pruebas contra `taskflow-api` con Selenium y Page Object Model |

**Viven en este repositorio a propósito**, y no en uno aparte: las dos semanas giran alrededor de
`taskflow-api/`, que está justo al lado. El lunes lo empaquetas y lo despliegas; el viernes le
escribes las pruebas. Tener el sujeto y sus herramientas en el mismo clone significa **un solo
`git clone` para toda la semana**.

Cada carpeta tiene su propio README con el reparto por día y cómo arrancar. **Las soluciones no
están aquí**, y no es un olvido: el ejercicio es escribirlas.

La única excepción es [`qe/auditoria/`](qe/auditoria/), que no es material de clase sino la
herramienta del instructor: comprueba contra el SUT vivo que cada cosa que las guías afirman
sobre TaskFlow siga siendo cierta. Trae localizadores resueltos, y su README lo avisa.

---

## Cómo abrirlo en Eclipse

1. Clona el repositorio:
   ```bash
   git clone https://github.com/cursosmrugerio/academyMty.git
   ```
2. En Eclipse: **File → Import… → General → Existing Projects into Workspace**.
3. Selecciona la carpeta `academyMty` y marca **Search for nested projects**.
4. Marca los proyectos que vayas a usar.

Solo se versiona el código fuente. Las clases compiladas —`bin/` en los proyectos de Eclipse,
`target/` en los de Maven— las genera el IDE al importar, por eso no están en el repositorio.

`demoTestJunit2`, `mockito` y `taskflow-api` son proyectos **Maven**: al importarlos, Eclipse
descarga sus dependencias, así que la primera vez hace falta conexión. `taskflow-api` se trae
Spring Boot entero, así que esa primera vez tarda bastante más que los otros dos. Si un proyecto
aparece con errores, **clic derecho → Maven → Update Project** (`Alt`+`F5`).
