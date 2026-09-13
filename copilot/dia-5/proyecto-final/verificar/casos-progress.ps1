#Requires -Version 7
<#
.SYNOPSIS
  Casos REST de GET /reports/progress para el script del jueves, verificar.ps1.

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
      . (Join-Path $PSScriptRoot 'casos-progress.ps1')

  El paso 3 MODIFICA datos (pasa la tarea 1 a DONE): por eso se carga al final de verificar.ps1.
  Valores esperados: specs/progress.md, sección «Resultado esperado con la semilla».
#>

# Una línea por proyecto, "1:5/1/20" — el porcentaje se escribe con formato invariante (punto decimal)
# para que la comparación no dependa de si Windows está configurado con coma decimal.
function TextoProgreso($cuerpo) {
    (@($cuerpo) | Where-Object { $_ } | ForEach-Object {
        '{0}:{1}/{2}/{3}' -f $_.projectId, $_.totalTasks, $_.doneTasks, ([double]$_.percentDone).ToString([cultureinfo]::InvariantCulture)
    }) -join ' '
}

# 1. Los tres proyectos, en orden de id, con el 3 (sin tareas) en 0 y no en NaN.
$r = Pedir '/reports/progress' $auth
Informar 'GET /reports/progress devuelve los 3 proyectos con la semilla' "HTTP $($r.Codigo) $(TextoProgreso $r.Cuerpo)" 'HTTP 200 1:5/1/20 2:4/1/25 3:0/0/0'

# 2. El nombre del proyecto viaja en la respuesta.
$r1 = @($r.Cuerpo) | Where-Object { $_.projectId -eq 1 }
Informar 'El proyecto 1 se llama «Plataforma TaskFlow»' "$($r1.projectName)" 'Plataforma TaskFlow'

# 3. Terminar la tarea 1 (tiene responsable, así que el PATCH pasa) sube el proyecto 1 a 2 de 5 = 40.
$cambio = Invoke-RestMethod -Method Patch -Uri "$base/tasks/1/status" -Headers $auth -ContentType 'application/json' `
    -Body '{"status": "DONE"}' -SkipHttpErrorCheck -StatusCodeVariable codigoCambio
$r = Pedir '/reports/progress' $auth
$p1 = @($r.Cuerpo) | Where-Object { $_.projectId -eq 1 }
Informar 'Tras pasar la tarea 1 a DONE, el proyecto 1 queda en 2/5 = 40' "PATCH $codigoCambio · HTTP $($r.Codigo) $(TextoProgreso $p1)" 'PATCH 200 · HTTP 200 1:5/2/40'

# 4. Sin token: 401.
$r = Pedir '/reports/progress'
Informar 'GET /reports/progress sin token responde 401' "HTTP $($r.Codigo)" 'HTTP 401'
