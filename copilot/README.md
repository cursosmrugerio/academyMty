# Copilot — Semana 6, del lunes 14 al viernes 18 de septiembre

Los archivos de práctica de la semana de **GitHub Copilot**. La guía de cada día está en Moodle; aquí
está lo que esa guía te manda copiar o ejecutar. **Todo viene completo y explicado**: no hay `TODO`
que rellenar.

| Carpeta | Día | Qué hay dentro |
|---|---|---|
| `dia-1/` | **lunes 14** | `copilot-instructions.md` (las instrucciones del proyecto para Copilot) y `verificar-arquitectura.ps1` (comprueba que existe todo lo que cita `docs/ARQUITECTURA.md`) |
| `dia-2/` | **martes 15** | `specs/` (las especificaciones de `/tasks/overdue` y `/tasks/unassigned`), `checklist-revision.md`, `mutar-orden.ps1` y `referencia/` (la versión de referencia, por si el agente no llega) |
| `dia-3/` | **miércoles 16** | `taskflow-mcp/` (tu servidor MCP en Java) e `issues/summary.md` |
| `dia-4/` | **jueves 17** | `.github/skills/` y `.github/agents/` (tus skills y agentes) y `referencia/` de `GET /projects/{id}/summary` |
| `dia-5/` | **viernes 18** | `.vscode/mcp.json`, `comprobar-mcp.ps1`, `proyecto-final/` (las tres specs y sus casos de prueba) y `semana6-README.md` (la plantilla de tu entrega) |

> La carpeta `dia-4/.github` y `dia-5/.vscode` empiezan por punto: en el Explorador de Windows se ven
> solo con *Ver → Elementos ocultos*. En PowerShell, `Get-ChildItem -Force`.

## Dónde trabajas: tu propio repo

Nada de esta carpeta se edita aquí. El lunes creas **`taskflow-copilot-<tu-usuario>`** (público) con una
copia de [`taskflow-api/`](../taskflow-api/), y cada día copias a ese repo lo que la guía indique.

Antes de copiar nada, actualiza este repositorio:

```powershell
cd $HOME\academyMty
git pull
```

**Windows:** toda la semana en **PowerShell 7** dentro de Windows Terminal. La guía del lunes explica
cómo instalarlo y por qué no sirven Windows PowerShell 5.1 ni Git Bash para esto.
