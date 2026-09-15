# Checklist de revisión de un cambio hecho por el agente

Se recorre **en orden**, en PowerShell 7, desde la raíz de tu repo `taskflow-copilot-<tu-usuario>`, en la rama
de la feature, en una pestaña donde ya corriste `[Console]::OutputEncoding = [Text.UTF8Encoding]::new()`.
Ningún punto depende de lo que el agente diga: cada uno es un comando y lo que tiene que salir. Cada punto que
falle tiene su follow-up en MP-4 de la guía del Día 2; los que pasan no llevan ninguno.

Los comandos están escritos para `GET /tasks/overdue`, comparando contra `main`. Para `GET /tasks/unassigned`
(MP-7 de la guía) cambian cuatro cosas: la base (`feature/overdue` en lugar de `main`), el método de la mutación
(`-Metodo sinResponsable`), los patrones del punto 5 (`SIN_ASIGNAR|POR_FECHA` y `getAssigneeId\(\) == null` en
lugar de `isBefore|isAfter`) y no se guarda en `checklist-overdue.txt`.

Los casos reales salen de cuatro corridas con la misma spec de `overdue`: el 12-sep en Mac con `gpt-5-mini` y
con `claude-sonnet-5`, y el ensayo del Día 2 con `gpt-5-mini` en Mac y en Windows.

---

## 0. Congela lo que hizo el agente

```powershell
git status --short
git add src
git commit -m "wip: GET /tasks/overdue tal como lo dejo el agente"
New-Item -ItemType Directory evidencia\dia2 -Force | Out-Null
```

**Qué debe salir:** `git status --short` lista solo archivos `M` de `src/` (y la línea de `evidencia`, que es
tuya). Un `??` dentro de `src` es un archivo que el agente creó sin que la spec lo pida: hallazgo del punto 1.

**Por qué `git add src` y no `git add -A`:** `evidencia` se llena durante el día y entra al repo al final, en
`main`. Con `-A` se colaría en la feature y en el pull request.

---

## 1. Alcance: ¿tocó solo lo que dice la spec?

```powershell
git diff --stat main | Tee-Object evidencia\dia2\checklist-overdue.txt
```

**Qué debe salir:** la spec y los cuatro archivos de su sección «Restricciones», nada más. Salida real (Windows):

```text
 specs/overdue.md                                   | 42 ++++++++++++++++++++++
 .../com/taskflow/controller/TaskController.java    |  8 +++++
 .../java/com/taskflow/service/TaskService.java     | 11 ++++++
 .../com/taskflow/slice/TaskControllerTest.java     | 14 ++++++++
 .../java/com/taskflow/unit/TaskServiceTest.java    | 23 ++++++++++++
 5 files changed, 98 insertions(+)
```

Git abrevia las rutas con `...` según el ancho de la terminal. Los números cambian; **la lista de archivos no**.

**Si sale otra cosa:** un archivo de más (`SecurityConfig.java`, `pom.xml`, `application.yml`…) es un hallazgo
aunque la suite pase. Deshazlo en la sesión de la CLI con `/rewind` → el turno de tu prompt → **Conversation +
files**, y repite el prompt diciendo qué archivo no se toca.

---

## 2. Tests que ya existían: ¿los cambió?

```powershell
git diff --numstat main -- src/test | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
git diff main -- src/test | Select-String '^-[^-]'
git diff main -- src/test | Select-String '@Disabled'
```

**Qué debe salir:** en `--numstat`, tres columnas (agregadas, **borradas**, archivo) con `0` en la del medio; los
dos `Select-String`, nada. Una línea cambiada cuenta como una borrada más una agregada.

```text
14      0       src/test/java/com/taskflow/slice/TaskControllerTest.java
23      0       src/test/java/com/taskflow/unit/TaskServiceTest.java
```

**Caso real (Mac, follow-up):** tras un prompt que pedía «borra los comentarios que afirman algo no
verificado», `--numstat` pasó a `21  17  …TaskServiceTest.java`: el agente borró el Javadoc de 17 líneas que la
clase ya tenía. Suite verde. Por eso los follow-ups de la guía dicen «solo en las líneas que agregaste en esta
rama». Esa frase no protege lo que agregó el propio agente: en el recorrido del 13-sep, un prompt que pedía las
tres correcciones a la vez borró sus tres comentarios verdaderos con `--numstat` en `0`. Por eso, un follow-up por
punto que falló.

**Si sale otra cosa:** `/rewind` → el turno que lo hizo → **Conversation + files**, y repite con la restricción.

---

## 3. Comentarios: ¿afirman algo que nadie verificó?

```powershell
git diff main -- src | Select-String -NoEmphasis '^\+\s*(//|/\*|\*)' | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
```

**Qué debe salir:** todas las líneas de comentario agregadas. Pregunta para cada una: *¿da una razón, y es verdad?*
Un Javadoc que repite lo que hace el método está bien; una razón tiene que ser comprobable. El patrón solo ve los
comentarios que empiezan la línea: los que van al final de una línea de código (`… // primero`) se leen en
`git diff main -- src`.

| Corrida | Comentario | Qué pasa en realidad |
|---|---|---|
| 12-sep, gpt-5-mini | «No debe ser capturado por GET /tasks/{id} (por eso está declarado ANTES en el controlador que el mapping por id)» | Spring elige la ruta literal antes que la plantilla **sin importar el orden**. Medido: con el método debajo de `getTaskPorId`, los 11 tests de `TaskControllerTest` siguieron en verde |
| 12-sep, claude-sonnet-5 | «Se declara ANTES que GET /tasks/{id} para que Spring la resuelva como ruta literal» | el mismo error con otro modelo; los dos repiten la frase ambigua de la spec |
| Día 2, Mac | `// marcar dueDate vencida (ayer)` encima de `vencida.setAssigneeId(1L);` | la línea asigna responsable, no fecha, y la variable se reemplaza en la siguiente: código muerto |
| Día 2, Windows | `// Crear dos tareas vencidas: una con dueDate más antigua (debe salir primera)` en el slice | «debe salir primera» porque así la puso el mock, no porque el controlador ordene |

---

## 4. Tests: ¿prueban lo que dicen?

**La mutación.** Rompe a propósito lo que el test dice vigilar y mira si se pone rojo. El script del lab lo hace
sin tocar nada más y deja el archivo como estaba (también si pulsas Ctrl+C a medio Maven):

```powershell
& $HOME\academyMty\copilot\dia-2\mutar-orden.ps1 -Metodo vencidas | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
```

**Qué debe salir** (medido en Windows; con `unassigned` ya hecho son `Tests run: 10`):

```text
MUTANTE: quitado .sorted(TaskOrders.POR_FECHA) de vencidas()
[ERROR] Tests run: 8, Failures: 1, Errors: 0, Skipped: 0
[INFO] BUILD FAILURE
RESTAURADO: TaskService.java quedó exactamente como estaba.
```

Si sale `SIN MUTAR: …`, el método no existe o no ordena con `TaskOrders.POR_FECHA` (acepta también `.sorted(POR_FECHA)`
con import estático): ya es un hallazgo (puntos 1 o 5) y va al follow-up de la mutación de MP-4. Si cortaste el script
con Ctrl+C, comprueba que `Select-String -Path src\main\java\com\taskflow\service\TaskService.java -SimpleMatch
'/*MUTANTE*/'` no imprime nada (ensayado: restauró aun con la sesión cortada). No deshagas una mutación a mano con `git restore`: si el agente tiene cambios sin commitear
en ese archivo, se van también (pasó en el ensayo).

| Corrida | Con el orden quitado | Por qué |
|---|---|---|
| Día 2, Mac, versión del agente | `Tests run: 8, Failures: 0` y `BUILD SUCCESS` | `vencidas_devuelveSoloVencidasYOrdenadas` tenía **una** tarea vencida: con un elemento, cualquier orden es correcto |
| Día 2, Mac, después del follow-up | `expected: <5> but was: <1>` y `BUILD FAILURE` | cinco tareas, dos vencidas, entregadas en orden inverso |
| Día 2, Windows, versión del agente | `Tests run: 8, Failures: 1` y `BUILD FAILURE` | el agente sí entregó las vencidas desordenadas |
| Versión de referencia | `expected: <[5, 1]> but was: <[1, 5]>` y `BUILD FAILURE` | ídem |

**El slice.** En `TaskControllerTest` la lista la escribe el mock: un test que comprueba el segundo elemento está
comprobando el orden del mock, no el del servicio.

```powershell
git diff main -- src/test/java/com/taskflow/slice | Select-String -NoEmphasis '^\+.*\$\[1\]' | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
```

**Qué debe salir:** nada (el `^\+` limita la búsqueda a líneas agregadas). Casos reales que encuentra:
claude-sonnet-5 el 12-sep, Windows en el Día 2 (`getOverdue_retorna200YListaOrdenada`) y el recorrido del 13-sep
(`getOverdue_retorna200YListaEnOrden`, con `$[0].title` y `$[1].title`). **No** encuentra la variante
de gpt-5-mini del 12-sep (`getOverdueTasks_retorna200YListaEnOrden`): dos tareas en el mock y solo `$[0]`; esa se ve
leyendo el nombre del test y el `thenReturn`. En Windows, una versión anterior del follow-up (en
cinco líneas) le quitó «Ordenada» al nombre pero dejó los `$[1]`; en una línea se resolvió a la primera (en el ensayo,
dentro de un prompt con tres correcciones; el 13-sep, con el follow-up de solo este punto, que tocó solo este archivo). Lo que sí vale en el slice: que la ruta llega al
método nuevo (200, no el `400` de `/tasks/{id}`) y que el JSON trae los campos del `TaskResponse`.

---

## 5. Convenciones de `.github/copilot-instructions.md` y de la spec

```powershell
git diff main -- src/main | Select-String 'estaVencida|POR_FECHA' | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
git diff main -- src/main | Select-String 'isBefore|isAfter|Comparator\.|@Autowired|public List<Task> get'
```

**Qué debe salir:** el primero, `.filter(Task::estaVencida)` y `.sorted(TaskOrders.POR_FECHA)` (y quizá un Javadoc
que los nombre). El segundo, nada: ni la regla de fecha a mano, ni un comparador nuevo, ni inyección por campo, ni
un controlador que devuelva la entidad.

---

## 6. La suite completa

```powershell
mvn test | Select-String -CaseSensitive 'Tests run:.*Skipped: \d+$|BUILD' | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
(git diff main -- src/test | Select-String '^\+\s*@Test').Count
```

**Qué debe salir:** `Failures: 0, Errors: 0, Skipped: 0`, `BUILD SUCCESS`, y el total igual a 67 más el número de la
segunda línea. Medido en Windows: `Tests run: 69` y `2`, en 2 min 48 s.

Entre la salida aparecen líneas `WARNING:` de Java sobre agentes dinámicos, un aviso de Mockito
(*self-attaching*) y `OpenJDK 64-Bit Server VM warning: Sharing is only supported…`. Van por la salida de error,
no pasan por `Select-String` y **no son fallos**. Sin `-CaseSensitive`, `BUILD` también encuentra
`Building taskflow-api`.

---

## Cuando los seis pasan

Si hubo correcciones, commitéalas:

```powershell
git add src
git commit -m "fix: correcciones del checklist en GET /tasks/overdue"
```

Después de cada corrección, **vuelve a pasar los puntos 2, 3, 4 y 6**: una corrección puede romper lo que antes
estaba bien (en el ensayo, la primera rompió el punto 2).
