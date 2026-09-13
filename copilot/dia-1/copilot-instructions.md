# Instrucciones de Copilot para TaskFlow API

Este archivo lo lee Copilot en cada sesión que abras dentro de este repositorio. Describe cómo está
hecho el proyecto y qué convenciones seguir. Si una respuesta del agente contradice este archivo, gana
este archivo.

## Idioma

- Responde en **español**.
- Comentarios, Javadoc y mensajes de commit en español. Los nombres de clases y métodos se quedan como
  están en el código (mezcla de inglés y español: `TaskService.cambiarStatus()`, `Task.estaVencida()`).

## Comandos

El proyecto es Maven con Spring Boot 3.5.3 y Java 21. En Windows se usan desde PowerShell.

```powershell
mvn -q test                                             # la suite normal (67 tests al empezar la semana)
mvn -q test "-Dtest=TaskServiceTest"                    # una sola clase de test
mvn spring-boot:run "-Dspring-boot.run.profiles=h2"     # la app con H2 en memoria y datos de ejemplo
mvn -q package -DskipTests                              # solo el jar, sin tests
```

- Con el perfil `h2` la base se crea vacía y `DataSeeder` la llena en cada arranque: usuarios `ana`,
  `luis` y `admin` (contraseñas `ana123`, `luis123`, `admin123`), 3 proyectos y 9 tareas.
- Los tests `*IT.java` usan Testcontainers y **no** corren con `mvn test` salvo `-Ddocker.tests=true`.
  No los actives: esta semana no se usa Docker.

## Arquitectura

- Paquete raíz `com.taskflow`, en capas: `controller` (HTTP) → `service` (casos de uso) → `repository`
  (Spring Data JPA) → `model` (entidades con comportamiento). Los controladores devuelven **DTOs**
  (`dto`), nunca entidades, a través de los mappers manuales de `mapper` (`TaskMapper.aResponse`).
- `Task` guarda sus reglas: `Task.crear(...)` nace en `TODO` y rechaza fechas pasadas; el constructor
  público sirve para rehidratar y sí acepta fechas pasadas; pasar a `DONE` exige responsable.
  `Task.estaVencida()` = tiene fecha, ya pasó y no está `DONE`. **Reutiliza esas reglas, no las copies.**
- Errores: `GlobalExceptionHandler` los convierte en respuestas uniformes. 400 validación, 404 no
  existe, 422 estado inválido, 409 usuario duplicado, 401 sin token o login fallido, 403 sin permiso.
  No agregues un manejador genérico de `Exception`.
- Seguridad: JWT sin estado. Son públicos `/auth/**`, `/info`, Swagger, la consola H2 y los archivos de
  la UI; todo lo demás pide token. Borrar un proyecto solo lo puede su dueño o un `ADMIN`
  (`@PreAuthorize` + `ProjectSecurity`).
- `src/main/resources/static` es una UI sencilla servida por la misma API (login, proyectos, tareas).

## Convenciones

- DTOs como `record` con Bean Validation y `@Valid` en los `@RequestBody`.
- Inyección por constructor. Sin Lombok.
- `POST` que crea → `201 Created` con cabecera `Location`; `DELETE` → `204 No Content`.
- Rutas sin prefijo `/api`: `/tasks`, `/projects`, `/auth/login`, `/info`.
- Tests: `unit` con JUnit 5 y Mockito sin Spring; `slice` con `@WebMvcTest` o `@DataJpaTest`;
  `integration` con `@SpringBootTest` y perfil `test`.

## Reglas para el agente

- **No modifiques tests existentes** para que pasen. Si un test falla, arregla el código o explica por
  qué el test está mal y detente.
- No toques archivos fuera de lo que se te pidió; si crees que hace falta, dilo antes de hacerlo.
- Al terminar un cambio en código Java corre `mvn -q test`. Si termina sin errores, di que la suite pasó;
  no busques cuántos tests fueron (`-q` no lo imprime y buscarlo gasta créditos). Si solo cambiaste
  documentación, no lo corras.
- No hagas `git commit` ni `git push` salvo que te lo pidan.
- No escribas comentarios que expliquen cosas que no verificaste. Si no sabes por qué funciona algo, no
  lo afirmes.
- Nunca escribas secretos (contraseñas, tokens, llaves) en archivos del repositorio.
