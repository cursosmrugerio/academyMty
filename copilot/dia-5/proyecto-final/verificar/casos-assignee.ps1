#Requires -Version 7
<#
.SYNOPSIS
  Casos REST de PATCH /tasks/{id}/assignee para el script del jueves, verificar.ps1.

.DESCRIPTION
  Este archivo NO se ejecuta solo. verificar.ps1 lo carga con punto («dot-sourcing») después de sus
  propias comprobaciones, cuando la app ya está arrancada y ya hizo login. Por eso aquí se usan, sin
  declararlas, cuatro cosas que define verificar.ps1:
    $base     la URL de la app (http://127.0.0.1:<puerto>)
    $auth     la cabecera Authorization con el token de ana
    Pedir     GET que devuelve [pscustomobject]@{ Codigo; Cuerpo } sin lanzar en 4xx/5xx
    Informar  imprime [OK] o [FALLA] y lleva la cuenta

  Cómo se conecta (una sola línea en verificar.ps1, justo debajo de la comprobación
  «GET /projects/1/summary sin token responde 401»):
      . (Join-Path $PSScriptRoot 'casos-assignee.ps1')

  Los pasos MODIFICAN datos y van en orden: el 3 depende del 1. Por eso se cargan al final de
  verificar.ps1, después de que el jueves ya comprobó /tasks/unassigned con la semilla intacta.
  Valores esperados: specs/assignee.md, sección «Resultado esperado con la semilla».
#>

# PATCH con cuerpo JSON que, como Pedir, nunca lanza por 4xx/5xx: devuelve el código y el cuerpo.
function Parchear([string]$ruta, [string]$json, [hashtable]$cabeceras = @{}) {
    try {
        $cuerpo = Invoke-RestMethod -Method Patch -Uri "$base$ruta" -Headers $cabeceras -Body $json `
            -ContentType 'application/json' -TimeoutSec 10 -SkipHttpErrorCheck -StatusCodeVariable codigo
        return [pscustomobject]@{ Codigo = [int]$codigo; Cuerpo = $cuerpo }
    } catch {
        return [pscustomobject]@{ Codigo = 0; Cuerpo = $_.Exception.Message }
    }
}

# 1. La tarea 4 no tenía responsable: se le asigna luis (id 2).
$r = Parchear '/tasks/4/assignee' '{"assigneeId": 2}' $auth
Informar 'PATCH /tasks/4/assignee asigna a luis' "HTTP $($r.Codigo) assigneeId=$($r.Cuerpo.assigneeId)" 'HTTP 200 assigneeId=2'

# 2. Se guardó en la base, no solo se respondió.
$r = Pedir '/tasks/4' $auth
Informar 'GET /tasks/4 conserva el responsable nuevo' "HTTP $($r.Codigo) assigneeId=$($r.Cuerpo.assigneeId)" 'HTTP 200 assigneeId=2'

# 3. Con responsable, la regla de Task.setStatus ya deja pasar a DONE (antes del paso 1 era 422).
$r = Parchear '/tasks/4/status' '{"status": "DONE"}' $auth
Informar 'PATCH /tasks/4/status a DONE ahora responde 200' "HTTP $($r.Codigo) status=$($r.Cuerpo.status)" 'HTTP 200 status=DONE'

# 4. Una tarea DONE no se reasigna: 422 con el mensaje de la spec (la 2 es DONE en la semilla).
$r = Parchear '/tasks/2/assignee' '{"assigneeId": 3}' $auth
Informar 'PATCH /tasks/2/assignee (DONE) responde 422' "HTTP $($r.Codigo) $($r.Cuerpo.message)" 'HTTP 422 No se puede reasignar una tarea terminada.'

# 5. Tarea inexistente: 404.
$r = Parchear '/tasks/99/assignee' '{"assigneeId": 2}' $auth
Informar 'PATCH /tasks/99/assignee responde 404' "HTTP $($r.Codigo)" 'HTTP 404'

# 6 y 7. Cuerpo inválido: 400 por Bean Validation, con el campo nombrado en errors.
$r = Parchear '/tasks/6/assignee' '{}' $auth
$nombraCampo = [bool](@($r.Cuerpo.errors) | Where-Object { $_ -like 'assigneeId*' })
Informar 'PATCH /tasks/6/assignee con {} responde 400 y nombra assigneeId' "HTTP $($r.Codigo) nombraCampo=$nombraCampo" 'HTTP 400 nombraCampo=True'

$r = Parchear '/tasks/6/assignee' '{"assigneeId": 0}' $auth
Informar 'PATCH /tasks/6/assignee con 0 responde 400' "HTTP $($r.Codigo)" 'HTTP 400'

# 8. Sin token: 401.
$r = Parchear '/tasks/6/assignee' '{"assigneeId": 2}'
Informar 'PATCH /tasks/6/assignee sin token responde 401' "HTTP $($r.Codigo)" 'HTTP 401'
