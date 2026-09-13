---
name: crear-endpoint-taskflow
description: Crea un endpoint REST nuevo en TaskFlow API (Spring Boot 3.5, Java 21) con las convenciones del proyecto - DTO record, mapper manual, método en el service que ya inyecta el controller reutilizando las reglas del dominio, controller sin prefijo /api, test unitario con Mockito y test slice con @WebMvcTest en clases nuevas, y mvn -q test al final. Úsala siempre que pidan agregar, implementar o exponer un endpoint o una ruta GET/POST/PUT/PATCH/DELETE de TaskFlow, o implementar una especificación o un issue de la API.
---

# Crear un endpoint en TaskFlow API

Esta skill es la receta del equipo para agregar un endpoint. Síguela en orden. Las plantillas de
código completas están en [plantillas.md](plantillas.md), en esta misma carpeta: **léelas antes de
escribir código**.

## 1. Antes de escribir

1. Lee la especificación completa (un archivo de `specs/` o el texto del issue). Si le falta un dato
   que necesitas (la ruta, la forma exacta del JSON, qué pasa si el recurso no existe), **detente y
   pregunta**. No inventes campos.
2. Lee las piezas vecinas antes de crear nada:
   - el controller donde va a vivir la ruta: `ProjectController` para `/projects/...`, `TaskController`
     para `/tasks/...` (en `src/main/java/com/taskflow/controller/`);
   - el service que ese controller **ya inyecta** en su constructor;
   - `mapper/`, `dto/` y `advice/GlobalExceptionHandler.java`.
3. Busca la regla de negocio que ya existe y **reutilízala, no la copies**:
   - `Task.estaVencida()`: tiene fecha, la fecha ya pasó y no está `DONE`;
   - `ReportService.SIN_ASIGNAR` y `ReportService.ES_PENDIENTE` (predicados públicos);
   - `TaskRepository.findByProjectId(id)`, `ProjectRepository.findById(id)`.

## 2. Las piezas, en este orden

| # | Pieza | Dónde | Regla |
|---|---|---|---|
| 1 | DTO de salida | `com.taskflow.dto`, nombre `<Algo>Response` | `record`. Si el endpoint recibe cuerpo, también `<Algo>Request` con Bean Validation (`@NotBlank`, `@Size`, `@NotNull`) |
| 2 | Mapper | la clase del recurso en `com.taskflow.mapper` (`ProjectMapper`, `TaskMapper`) | método `public static`, a mano, sin MapStruct |
| 3 | Service | el service que el controller **ya inyecta** (`ProjectService` para `/projects`, `TaskService` para `/tasks`) | la lógica (contar, filtrar, ordenar), sin nada de HTTP. Recibe la entidad ya encontrada (`Project`) y usa los repositorios que ya tiene |
| 4 | Controller | el controller del recurso | ruta **sin** `/api` (`/projects/{id}/...`), `@PathVariable("id")` con el nombre escrito, `@Operation(summary, description)` en español, `@Valid` en cada `@RequestBody`, devuelve el DTO (nunca la entidad). El 404 se resuelve **como en la ruta vecina** `GET /projects/{id}/tasks`: `projectService.buscarPorId(id).orElseThrow(() -> new ProjectNotFoundException(id))`; el `GlobalExceptionHandler` lo convierte en 404 |
| 5 | Test unitario | clase **nueva** en `src/test/java/com/taskflow/unit/` | `@ExtendWith(MockitoExtension.class)`, `@Mock` de **cada** repositorio del constructor del service, `@InjectMocks` del service, datos `Task` reales con el constructor de rehidratación |
| 6 | Test slice | clase **nueva** en `src/test/java/com/taskflow/slice/` | `@WebMvcTest(<Controller>.class)`, `@AutoConfigureMockMvc(addFilters = false)`, `@MockitoBean` de cada service del controller y `@MockitoBean JwtAuthenticationFilter` |

**No agregues dependencias nuevas al constructor de un controller que ya existe** (un service
nuevo, un repositorio). El slice test que ya existe para ese controller (`ProjectControllerTest`,
`TaskControllerTest`) no las conoce: fallaría al levantar el contexto y la única salida sería
editar un test existente, que está prohibido. Pon el método nuevo en el service que el controller
ya recibe.

## 3. Qué tiene que probar cada test

- **Unit** (la lógica): el caso normal con valores calculados a mano a partir de los datos del test
  (no copiados de lo que devuelve el código) y el caso vacío (proyecto sin tareas) si la
  especificación lo menciona.
- **Slice** (el contrato HTTP): el mock del service devuelve un DTO ya armado y el test comprueba el
  código de estado y **cada campo del JSON** con `jsonPath`; y el 404 con
  `when(projectService.buscarPorId(99L)).thenReturn(Optional.empty())`.
- Un test que solo repite lo que devuelve el mock no prueba nada: la lógica se prueba en el unit.
- Nombres de método en español con guion bajo, como los que ya hay: `getResumen_proyectoInexistente_devuelve404`.

## 4. Reglas que no se negocian

- **No modifiques, borres ni desactives tests existentes.** Los tests nuevos van en clases nuevas.
  Si un test existente falla, arregla el código de producción o explica por qué y detente.
- Solo tocas: el DTO nuevo, el mapper, el service, el controller y los dos tests nuevos. Nada de
  `SecurityConfig`, `pom.xml`, `application*.yml` ni `DataSeeder`: la ruta nueva queda protegida con
  JWT como las demás sin hacer nada.
- Sin Lombok. Sin manejador genérico de `Exception`. Inyección por constructor.
- Comentarios y Javadoc en español y **solo con lo que verificaste**. No expliques por qué Spring
  hace algo si no lo comprobaste (por ejemplo: en Spring MVC el orden en que declaras los métodos
  **no** decide qué ruta gana; una ruta literal gana a `{id}` siempre).

## 5. Al terminar

1. Corre `mvn -q test` desde la raíz del repositorio. Si falla, lee el primer error, corrige el código
   de producción o el test **nuevo** y repite.
2. Responde con: la lista de archivos creados y modificados, y el resultado de `mvn -q test`.
