# Especificación — `GET /tasks/unassigned`

## Qué

Un endpoint que lista las tareas sin responsable de todos los proyectos, para repartirlas.

## Reglas

1. Una tarea está sin responsable si `assigneeId` es `null`. La regla ya existe como predicado:
   `ReportService.SIN_ASIGNAR`. Úsalo; no escribas otra vez `t.getAssigneeId() == null`.
2. Entran tareas en cualquier estado (`TODO`, `IN_PROGRESS` o `DONE`): la regla es solo el responsable.
3. Orden: por `dueDate` ascendente, con las que no tienen fecha al final. Es exactamente
   `TaskOrders.POR_FECHA`: úsalo.
4. Respuesta: `200` con una lista de `TaskResponse` (vía `TaskMapper.aResponse`). Si no hay tareas sin
   responsable, `200` con `[]`.
5. Seguridad: igual que el resto de `/tasks` (sin token → `401`). No cambies `SecurityConfig`.

## Dónde

- Método nuevo en `TaskService`: `public List<Task> sinResponsable()`. No lo confundas con
  `ReportService.sinAsignar()`, que devuelve un conteo (`long`) y no se toca.
- Endpoint nuevo en `TaskController`: `@GetMapping("/tasks/unassigned")`, junto a `GET /tasks/overdue`.
  Spring elige la ruta literal `/tasks/unassigned` antes que la plantilla `/tasks/{id}` sin importar
  en qué orden estén declarados los métodos: **no escribas comentarios sobre el orden de declaración**.

## Tests que deben existir al terminar

- Unit en `TaskServiceTest`, dentro de un `@Nested` llamado `SinResponsable`:
  - con el repositorio devolviendo, **en este orden**, una tarea sin responsable con fecha en 10 días,
    una con responsable, una sin responsable sin fecha y una sin responsable con fecha en 2 días,
    `sinResponsable()` devuelve exactamente las tres sin responsable en el orden: la de 2 días, la de
    10 días y la sin fecha. Compara los ids en orden (`assertEquals(List.of(...), ids)`).
    Este test tiene que **fallar** si alguien quita el `.sorted(...)` del servicio.
  - con el repositorio devolviendo solo tareas con responsable, devuelve una lista vacía.
- Slice en `TaskControllerTest`: `GET /tasks/unassigned` responde `200` y el JSON trae el `id` y el
  `assigneeId` (`null`) de lo que devuelve `taskService.sinResponsable()`. **No pruebes el orden en el
  slice**: ahí la lista la inventa el mock, así que el orden solo se prueba en el unit.

## Resultado esperado con la semilla

Con la app arrancada con el perfil `h2`, `GET /tasks/unassigned` devuelve dos tareas, en este orden:
la `4` («Escribir tests MockMvc», vence en 7 días) y la `6` («Publicar en la tienda», vence en 10 días).

## Restricciones

- No modifiques ningún test existente.
- No toques archivos fuera de `TaskService.java`, `TaskController.java`, `TaskServiceTest.java` y
  `TaskControllerTest.java`.
- No escribas comentarios que afirmen algo que no verificaste.
- Al terminar, `mvn -q test` tiene que pasar completo.
