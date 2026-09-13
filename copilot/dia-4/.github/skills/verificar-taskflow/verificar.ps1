#Requires -Version 7
<#
.SYNOPSIS
  Verifica TaskFlow API de punta a punta contra la semilla del perfil h2, y la apaga siempre.

.DESCRIPTION
  1. Empaqueta el jar con Maven, sin tests (mvn -q package -DskipTests).
  2. Arranca el jar en segundo plano (Start-Process) con el perfil h2, escuchando solo en 127.0.0.1.
  3. Espera a que GET /info responda y a que termine la semilla (login de ana y GET /tasks/9): reintenta
     cada 2 s hasta -EsperaMaxSeg, no duerme un tiempo fijo.
  4. Compara siete respuestas con los valores de la semilla.
  5. Apaga la app en el bloque finally, pase lo que pase, y comprueba que el puerto ya no responde.

  Imprime una línea [OK] o [FALLA] por comprobación. Termina con código 0 si todo pasó y 1 si no.
  Los mensajes que imprime van sin acentos a propósito: cuando la salida pasa por una tubería
  (Tee-Object, la terminal del agente) Windows la decodifica con otra página de códigos y una «ó» sale
  como «�» (medido en la Windows de ensayo el 13-sep).
  Los logs quedan en target/verificar-<puerto>-*.log (target/ no se versiona).

.PARAMETER Puerto
  Puerto donde arranca la app. 8080 por defecto.

.PARAMETER EsperaMaxSeg
  Cuántos segundos esperar, en total, a que /info responda y a que termine la semilla (login de ana y
  GET /tasks/9) antes de rendirse. 120 por defecto; en una laptop lenta, 300.

.EXAMPLE
  pwsh -NoProfile -File .github/skills/verificar-taskflow/verificar.ps1
#>
param(
    [int]$Puerto = 8080,
    [int]$EsperaMaxSeg = 120
)

$ErrorActionPreference = 'Stop'

# La raíz del repositorio está tres carpetas arriba de este script:
# <raíz>/.github/skills/verificar-taskflow/verificar.ps1
$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
# 127.0.0.1 y no localhost: en Windows localhost puede resolver primero a ::1 (IPv6) y la app
# solo escucha en IPv4 127.0.0.1 (ver --server.address abajo).
$base = "http://127.0.0.1:$Puerto"
$logApp = Join-Path $raiz 'target' "verificar-$Puerto-app.log"
$logErr = Join-Path $raiz 'target' "verificar-$Puerto-app-err.log"
$logBuild = Join-Path $raiz 'target' "verificar-$Puerto-build.log"

# ---------------------------------------------------------------------------------------------
# Valores esperados. Salen de src/main/java/com/taskflow/config/DataSeeder.java (perfil h2, la base
# se crea vacía y se siembra en cada arranque; las fechas son relativas a hoy):
#   proyecto 1: tareas 1-5  -> TODO 1,4,5 · IN_PROGRESS 3 · DONE 2 (fecha pasada, pero DONE: no vence)
#   proyecto 2: tareas 6-9  -> TODO 6 · IN_PROGRESS 7 (vencida ayer), 9 · DONE 8
#   proyecto 3: sin tareas
#   nombres: 1 «Plataforma TaskFlow», 2 «App Móvil», 3 «Migración Legacy»
#   sin responsable: tareas 4 y 6
# ---------------------------------------------------------------------------------------------
$nombres = @{ 1 = 'Plataforma TaskFlow'; 2 = 'App Móvil'; 3 = 'Migración Legacy' }
$esperado = @{
    overdue    = '7'
    unassigned = '4,6'
    summary1   = 'projectId=1 totalTasks=5 TODO=3 IN_PROGRESS=1 DONE=1 overdue=0'
    summary2   = 'projectId=2 totalTasks=4 TODO=1 IN_PROGRESS=2 DONE=1 overdue=1'
    summary3   = 'projectId=3 totalTasks=0 TODO=0 IN_PROGRESS=0 DONE=0 overdue=0'
}

$script:fallas = 0
$script:oks = 0

function Informar([string]$nombre, [string]$obtenido, [string]$esperadoTexto) {
    if ($obtenido -eq $esperadoTexto) {
        Write-Host "[OK]    $nombre" -ForegroundColor Green
        $script:oks++
    } else {
        Write-Host "[FALLA] $nombre" -ForegroundColor Red
        Write-Host "        esperaba: $esperadoTexto"
        Write-Host "        obtuve:   $obtenido"
        $script:fallas++
    }
}

# Una petición GET que nunca lanza por códigos 4xx/5xx: devuelve el código y el cuerpo ya convertido.
function Pedir([string]$ruta, [hashtable]$cabeceras = @{}) {
    try {
        $cuerpo = Invoke-RestMethod -Uri "$base$ruta" -Headers $cabeceras -TimeoutSec 10 `
            -SkipHttpErrorCheck -StatusCodeVariable codigo
        return [pscustomobject]@{ Codigo = [int]$codigo; Cuerpo = $cuerpo }
    } catch {
        return [pscustomobject]@{ Codigo = 0; Cuerpo = $_.Exception.Message }
    }
}

function TextoResumen($s) {
    "projectId=$($s.projectId) totalTasks=$($s.totalTasks) TODO=$($s.byStatus.TODO) " +
    "IN_PROGRESS=$($s.byStatus.IN_PROGRESS) DONE=$($s.byStatus.DONE) overdue=$($s.overdue)"
}

Write-Host "Repositorio: $raiz"
Write-Host "URL de la app: $base"

# 0. Si ya hay algo respondiendo en ese puerto, el script probaría esa app y no la tuya.
$previa = Pedir '/info'
if ($previa.Codigo -ne 0) {
    Write-Host "[FALLA] Ya hay una app respondiendo en el puerto $Puerto. Detenla (Ctrl+C en su terminal) y vuelve a correr el script." -ForegroundColor Red
    exit 1
}

# 1. Empaquetar. Si no compila, no hay nada que arrancar.
Write-Host "Empaquetando con Maven (mvn -q package -DskipTests), tarda unos segundos..."
New-Item -ItemType Directory -Force -Path (Join-Path $raiz 'target') | Out-Null
Push-Location $raiz
try {
    & mvn -q package -DskipTests *> $logBuild
    $codigoBuild = $LASTEXITCODE
} finally {
    Pop-Location
}
if ($codigoBuild -ne 0) {
    Write-Host "[FALLA] mvn package no compilo (exit $codigoBuild). Final de $($logBuild):" -ForegroundColor Red
    Get-Content $logBuild -Tail 20
    exit 1
}
$jar = Get-ChildItem (Join-Path $raiz 'target') -Filter 'taskflow-api-*.jar' | Select-Object -First 1
if (-not $jar) {
    Write-Host "[FALLA] No hay target/taskflow-api-*.jar tras empaquetar." -ForegroundColor Red
    exit 1
}

$app = $null
try {
    # 2. Arrancar en segundo plano. Un solo proceso java: se puede apagar sin dejar hijos vivos.
    #    --server.address=127.0.0.1: la app escucha solo en esta máquina, no en la red.
    #    java de JAVA_HOME si existe (el JDK 21 del curso); si no, el primero del PATH.
    $java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin' ($IsWindows ? 'java.exe' : 'java') } else { (Get-Command java).Source }
    #    Ruta RELATIVA al jar: Start-Process junta los argumentos con espacios y sin comillas, así que una
    #    ruta absoluta con espacios (C:\Users\Juan Perez\...) llegaría partida a java.
    $argumentos = @('-jar', (Join-Path 'target' $jar.Name), '--spring.profiles.active=h2', "--server.port=$Puerto", '--server.address=127.0.0.1')
    $app = Start-Process -FilePath $java -ArgumentList $argumentos -WorkingDirectory $raiz `
        -RedirectStandardOutput $logApp -RedirectStandardError $logErr -NoNewWindow -PassThru
    Write-Host "App arrancando (PID $($app.Id)). Esperando a que /info responda..."

    # 3. Esperar a /info reintentando.
    $inicio = Get-Date
    $lista = $false
    while (((Get-Date) - $inicio).TotalSeconds -lt $EsperaMaxSeg) {
        if ($app.HasExited) { break }
        if ((Pedir '/info').Codigo -eq 200) { $lista = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $lista) {
        $motivo = if ($app.HasExited) { "se detuvo al arrancar (exit $($app.ExitCode))" } else { "no contesta /info tras $EsperaMaxSeg s" }
        Write-Host "[FALLA] La app $motivo. Final de $($logApp):" -ForegroundColor Red
        Get-Content $logApp -Tail 20
        $script:fallas++
    } else {
        Write-Host ("App lista en {0:N0} s." -f ((Get-Date) - $inicio).TotalSeconds)

        # 4. Esperar a que termine la semilla. Spring Boot abre el puerto ANTES de correr DataSeeder
        #    (un CommandLineRunner): /info ya responde pero ana todavía no existe y el login da 401.
        #    Medido en la Windows de ensayo el 13-sep. Se reintenta el login y luego se espera a la
        #    última tarea que siembra (la 9); no se duerme un tiempo fijo.
        $auth = $null
        while (((Get-Date) - $inicio).TotalSeconds -lt $EsperaMaxSeg) {
            try {
                # AuthResponse es {"token": "..."}.
                $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' `
                    -Body '{"username":"ana","password":"ana123"}' -TimeoutSec 10
                $auth = @{ Authorization = "Bearer $($login.token)" }
                if ((Pedir '/tasks/9' $auth).Codigo -eq 200) { break }
            } catch { }
            $auth = $null
            Start-Sleep -Seconds 2
        }
        if (-not $auth) { throw "La semilla no termino tras $EsperaMaxSeg s (login de ana o GET /tasks/9 sin 200)" }

        $r = Pedir '/tasks/overdue' $auth
        Informar 'GET /tasks/overdue devuelve solo la tarea 7' "HTTP $($r.Codigo) ids=$((@($r.Cuerpo) | ForEach-Object { $_.id }) -join ',')" "HTTP 200 ids=$($esperado.overdue)"

        $r = Pedir '/tasks/unassigned' $auth
        Informar 'GET /tasks/unassigned devuelve las tareas 4 y 6' "HTTP $($r.Codigo) ids=$((@($r.Cuerpo) | ForEach-Object { $_.id } | Sort-Object) -join ',')" "HTTP 200 ids=$($esperado.unassigned)"

        foreach ($id in 1, 2, 3) {
            $r = Pedir "/projects/$id/summary" $auth
            # projectName se compara aparte y se imprime como True/False: la salida va sin acentos.
            $texto = if ($r.Codigo -eq 200) { (TextoResumen $r.Cuerpo) + " projectNameOk=$($r.Cuerpo.projectName -eq $nombres[$id])" } else { '' }
            Informar "GET /projects/$id/summary" "HTTP $($r.Codigo) $texto" "HTTP 200 $($esperado["summary$id"]) projectNameOk=True"
        }

        $r = Pedir '/projects/99/summary' $auth
        Informar 'GET /projects/99/summary responde 404' "HTTP $($r.Codigo)" 'HTTP 404'

        $r = Pedir '/projects/1/summary'
        Informar 'GET /projects/1/summary sin token responde 401' "HTTP $($r.Codigo)" 'HTTP 401'
    }
}
catch {
    Write-Host "[FALLA] Error inesperado: $($_.Exception.Message)" -ForegroundColor Red
    $script:fallas++
}
finally {
    # 5. Apagar SIEMPRE, también si algo falló arriba o si pulsaste Ctrl+C.
    if ($app -and -not $app.HasExited) {
        $app.Kill($true)                 # $true = el proceso y todos sus hijos
        $null = $app.WaitForExit(20000)
    }
    if ($app) { Write-Host "App detenida (PID $($app.Id))." }
}

$despues = Pedir '/info'
Informar "App apagada: el puerto $Puerto ya no responde" "HTTP $($despues.Codigo)" 'HTTP 0'

$total = $script:oks + $script:fallas
if ($script:fallas -eq 0) {
    Write-Host "RESULTADO: $($script:oks)/$total OK" -ForegroundColor Green
    exit 0
}
Write-Host "RESULTADO: $($script:fallas) de $total con FALLA. Logs de la app: $logApp" -ForegroundColor Red
exit 1
