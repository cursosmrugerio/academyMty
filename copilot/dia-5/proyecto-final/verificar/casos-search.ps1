#Requires -Version 7
<#
.SYNOPSIS
  Casos REST de GET /tasks/search para el script del jueves, verificar.ps1.

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
      . (Join-Path $PSScriptRoot 'casos-search.ps1')

  Valores esperados: specs/search.md, sección «Resultado esperado con la semilla».
#>

# Convierte la lista de tareas de una respuesta en "9,5". @(...) porque una lista de un solo elemento
# llega como objeto suelto, y una lista vacía llega como $null.
function IdsDe($cuerpo) {
    (@($cuerpo) | Where-Object { $_ } | ForEach-Object { $_.id }) -join ','
}

# 1. Coincidencia sin distinguir mayúsculas, en orden alfabético por título:
#    9 «Documentar la API con Swagger» va antes que 5 «Optimizar consultas de la API».
$r = Pedir '/tasks/search?q=api' $auth
Informar 'GET /tasks/search?q=api devuelve 9 y 5, en ese orden' "HTTP $($r.Codigo) ids=$(IdsDe $r.Cuerpo)" 'HTTP 200 ids=9,5'

$r = Pedir '/tasks/search?q=API' $auth
Informar 'GET /tasks/search?q=API devuelve lo mismo (no distingue mayúsculas)' "HTTP $($r.Codigo) ids=$(IdsDe $r.Cuerpo)" 'HTTP 200 ids=9,5'

# 2. Sin coincidencias: 200 con lista vacía, no 404.
$r = Pedir '/tasks/search?q=zzz' $auth
Informar 'GET /tasks/search?q=zzz devuelve 200 con []' "HTTP $($r.Codigo) ids=$(IdsDe $r.Cuerpo)" 'HTTP 200 ids='

# 3. q vacío (dos espacios codificados) y q ausente: 400 con el ErrorResponse uniforme.
$mensaje = "El parámetro 'q' es obligatorio."
$r = Pedir '/tasks/search?q=%20%20' $auth
Informar 'GET /tasks/search?q=(espacios) responde 400 con el mensaje de la spec' "HTTP $($r.Codigo) $($r.Cuerpo.message)" "HTTP 400 $mensaje"

$r = Pedir '/tasks/search' $auth
Informar 'GET /tasks/search sin q responde 400 con el mensaje de la spec' "HTTP $($r.Codigo) $($r.Cuerpo.message)" "HTTP 400 $mensaje"

# 4. Sin token: 401, como el resto de /tasks.
$r = Pedir '/tasks/search?q=api'
Informar 'GET /tasks/search sin token responde 401' "HTTP $($r.Codigo)" 'HTTP 401'
