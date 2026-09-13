# Proyecto final · Semana 6 · GitHub Copilot

> Plantilla del documento del proyecto final. Se copia a `semana6/README.md` de tu repo
> `taskflow-copilot-<tu-usuario>` y se llena **con datos de tu repo**: cada sección dice de dónde
> sale cada valor. Borra las líneas que empiezan con `>` cuando termines.

**Alumno:** `<tu nombre completo>` · **Usuario de GitHub:** `<tu-usuario>`

## 1. Qué construí

> Marca **una** fila con `x` y borra las otras dos.

| | Feature | Especificación |
|---|---|---|
| [ ] | `GET /tasks/search?q=` — buscar tareas por título | [`specs/search.md`](../specs/search.md) |
| [ ] | `PATCH /tasks/{id}/assignee` — cambiar el responsable | [`specs/assignee.md`](../specs/assignee.md) |
| [ ] | `GET /reports/progress` — avance por proyecto | [`specs/progress.md`](../specs/progress.md) |

## 2. El pull request

- **URL del PR (mergeado):** `<pega la URL, por ejemplo https://github.com/<tu-usuario>/taskflow-copilot-<tu-usuario>/pull/5>`
- **Commit del merge en `main`:** `<pega la línea que imprime git log --oneline -1 --merges main>`
- **Comentarios de Copilot code review:** `<número de comentarios que dejó Copilot en el PR>`

## 3. Cómo lo hice

> Una fila por paso. La columna «Evidencia» apunta a un archivo de esta carpeta o a un comando que
> cualquiera puede repetir.

| Paso | Qué hice | Evidencia |
|---|---|---|
| Rama y spec | `git switch -c feature/<feature>` y copié la spec a `specs/` | `git log --oneline main..feature/<feature>` (antes del merge) |
| Implementación | `copilot -p "/crear-endpoint-taskflow …"` con `gpt-5-mini` | `semana6/sesion-implementacion.md` (tiene la línea `Skill "crear-endpoint-taskflow" loaded successfully`) |
| Revisión | agente `revisor` sobre `semana6/proyecto-final.diff` | `semana6/revision.md` (termina con `Veredicto:`) |
| Tests | `mvn test` en verde | `<pega el total de la línea Tests run del PF-7>` |
| Comprobación REST | `verificar.ps1` con `casos-<feature>.ps1` | sección 5 de este documento |
| Code review | Copilot en el PR | la pestaña *Files changed* del PR |

## 4. Qué hizo el agente y qué corregí yo

> Una fila por cada cosa que **no** quedó como la pedía la spec o la checklist: la encontró el
> revisor, Copilot code review, un test, `verificar.ps1` o tú leyendo el diff. Si el agente la
> corrigió con un prompt tuyo, dilo; si la corregiste a mano, también. Los hallazgos **falsos**
> (el revisor o Copilot pidieron algo que no hacía falta) también van: en «Qué hizo mal» escribe lo que
> pidieron y en «Cómo quedó» cómo comprobaste que era falso.

| # | Qué hizo mal el agente (archivo) | Quién lo detectó | Cómo quedó corregido |
|---|---|---|---|
| 1 | `<ejemplo: usó @MockBean en vez de @MockitoBean — ProgresoProyectosControllerTest.java>` | `<revisor / Copilot review / test / yo>` | `<prompt de corrección o cambio a mano, y commit>` |

**Lo que el agente hizo bien a la primera** (una o dos líneas): `<qué archivos o casos no tuviste que tocar>`

## 5. Comprobaciones REST

> Pega completa la salida de
> `pwsh -NoProfile -File .github/skills/verificar-taskflow/verificar.ps1` en la rama `main` después
> del merge (la última línea es `RESULTADO:`).

```text
<pega aquí la salida>
```

## 6. Créditos de la semana

> **De dónde sale cada número.** El total del mes: `https://github.com/settings/billing`, en el
> resumen por producto, el de Copilot (con **View details** ves el detalle). Los del proyecto final:
> la línea `AI Credits` que imprime cada `copilot -p` al terminar.

| Qué | AI credits |
|---|---|
| Usados en septiembre según github.com (incluye semanas anteriores si usaste Copilot antes) | `<número>` |
| Implementación con la skill (`AI Credits` del PF-2) | `<número>` |
| Revisión del `revisor` (`AI Credits` del PF-3) | `<número>` |
| Correcciones del PF-4 y del PF-6, si hubo (`AI Credits`) | `<número o 0>` |
