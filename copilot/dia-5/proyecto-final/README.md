# Proyecto final · Semana 6

Material del proyecto final del viernes 18 de septiembre. La guía que lo recorre paso a paso es la
del Día 5 (§8 · PF-1 a PF-7); esta carpeta solo tiene los archivos que copias. `verificar.ps1` en Windows, con
los días 2 a 4 completos: 14/14, 16/16 y 12/12.

| Carpeta | Qué hay | A dónde va en tu repo |
|---|---|---|
| `specs/` | Las tres especificaciones del menú: `search.md`, `assignee.md`, `progress.md`. Eliges **una** | `specs/<feature>.md` |
| `verificar/` | Los casos REST de cada feature para el script del jueves: `casos-search.ps1`, `casos-assignee.ps1`, `casos-progress.ps1` | `.github/skills/verificar-taskflow/casos-<feature>.ps1` |

La plantilla del documento que entregas está un nivel arriba: `../semana6-README.md` → `semana6/README.md`.

## El menú

| Feature | Qué pide | Archivos que toca | Medido en el ensayo (12-sep, `gpt-5-mini`) |
|---|---|---|---|
| `search` | `GET /tasks/search?q=`: buscar por título, 400 si `q` falta, orden alfabético | `TaskService`, `TaskController` + 2 clases de test nuevas | 23.7 créditos, 15 min (Windows), 4 métodos de test, 14/14 en `verificar.ps1` |
| `assignee` | `PATCH /tasks/{id}/assignee`: cambiar el responsable; 404, 422 si la tarea está `DONE`, 400 si el cuerpo no sirve | DTO nuevo, `TaskService`, `TaskController` + 2 clases de test nuevas | 11.0 créditos, 3 min 40 s (Mac), 6 métodos de test, 16/16 en `verificar.ps1` |
| `progress` | `GET /reports/progress`: % de tareas `DONE` por proyecto, con redondeo y proyectos vacíos | DTO nuevo, `ProjectMapper`, `ProjectService`, controller nuevo + 2 clases de test nuevas | 13.8 créditos, 5 min 16 s (Mac), 2 métodos de test, 12/12 en `verificar.ps1` |
