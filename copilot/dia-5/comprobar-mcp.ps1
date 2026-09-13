#Requires -Version 7
<#
.SYNOPSIS
  Comprueba, sin abrir VS Code, que cada servidor de .vscode/mcp.json arranca y responde.

.DESCRIPTION
  Hace con cada servidor lo mismo que hará VS Code cuando lo arranque, pero desde la terminal:
    1. Lee .vscode/mcp.json y comprueba que es JSON válido y que usa la clave "servers"
       (la de VS Code; la CLI usa "mcpServers" en otro archivo).
    2. Servidores "stdio" (taskflow, playwright): busca el comando en el PATH, comprueba que existe el
       .jar si lo hay, lo arranca en la carpeta del repo con sus variables "env" y le manda por la
       entrada estándar los mensajes MCP "initialize" y "tools/list".
    3. Servidores "http" (aws-knowledge): manda "initialize" y "tools/list" a la URL.
    4. Imprime [OK] o [FALLA] por servidor, con el nombre que se anunció y sus herramientas.

  No gasta créditos: aquí no participa ningún modelo, solo los servidores.
  No necesita la API arrancada: listar herramientas no llama a TaskFlow (llamar a una sí).

  Termina con código 0 si todos respondieron y 1 si no.

.PARAMETER Archivo
  Ruta del mcp.json. Por defecto .vscode/mcp.json en la carpeta actual (la raíz de tu repo).

.PARAMETER EsperaMaxSeg
  Cuántos segundos esperar la respuesta de cada servidor. La primera vez, npx descarga
  @playwright/mcp y tarda más: 120 por defecto.

.EXAMPLE
  cd $HOME\taskflow-copilot-<tu-usuario>
  pwsh -NoProfile -File $HOME\academyMty\copilot\dia-5\comprobar-mcp.ps1
#>
param(
    [string]$Archivo = '.vscode/mcp.json',
    [int]$EsperaMaxSeg = 120
)

$ErrorActionPreference = 'Stop'
$raiz = (Get-Location).Path
$script:fallas = 0

function Ok([string]$texto)    { Write-Host "[OK]    $texto" -ForegroundColor Green }
function Falla([string]$texto) { Write-Host "[FALLA] $texto" -ForegroundColor Red; $script:fallas++ }

# Los tres mensajes MCP que manda cualquier cliente al conectarse. La versión de protocolo es una que
# todos los servidores del curso aceptan; si el servidor prefiere otra, la negocia en su respuesta.
$msgInitialize = @{
    jsonrpc = '2.0'; id = 1; method = 'initialize'
    params  = @{ protocolVersion = '2025-06-18'; capabilities = @{}; clientInfo = @{ name = 'comprobar-mcp'; version = '1.0.0' } }
} | ConvertTo-Json -Depth 5 -Compress
$msgInitialized = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
$msgToolsList = '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

# Lee líneas de la salida del proceso hasta encontrar la respuesta JSON-RPC con ese id.
# Las líneas que no son JSON (avisos de npx, por ejemplo) se ignoran; si no llega a tiempo, $null.
function EsperarRespuesta($proceso, [int]$id, [datetime]$limite) {
    while ((Get-Date) -lt $limite) {
        $restante = [int][math]::Max(1, ($limite - (Get-Date)).TotalMilliseconds)
        $tarea = $proceso.StandardOutput.ReadLineAsync()
        if (-not $tarea.Wait($restante)) { return $null }
        $linea = $tarea.Result
        if ($null -eq $linea) { return $null }            # el proceso cerró su salida: murió
        try { $json = $linea | ConvertFrom-Json -Depth 20 } catch { continue }
        if ($json.id -eq $id) { return $json }
    }
    return $null
}

function ProbarStdio([string]$nombre, $servidor) {
    # ${workspaceFolder} es la carpeta que abriste en VS Code: aquí, la carpeta actual.
    $argumentos = @($servidor.args | ForEach-Object { $_.Replace('${workspaceFolder}', $raiz) })

    $comando = Get-Command $servidor.command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $comando) {
        Falla "$nombre (stdio): no encuentro «$($servidor.command)» en el PATH. Instálalo, cierra y abre la terminal, y repite."
        return
    }
    $iJar = [array]::IndexOf($argumentos, '-jar')
    if ($iJar -ge 0 -and -not (Test-Path $argumentos[$iJar + 1])) {
        Falla "$nombre (stdio): no existe $($argumentos[$iJar + 1]). Empaquétalo: cd taskflow-mcp; mvn -q package -DskipTests; cd .."
        return
    }

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    # npx es un npx.cmd: los .cmd se ejecutan a través de cmd.exe (VS Code hace lo mismo en Windows).
    if ($comando.Source -match '\.(cmd|bat)$') {
        $psi.FileName = $env:ComSpec
        foreach ($a in @('/d', '/c', $comando.Source)) { $psi.ArgumentList.Add($a) }
    } else {
        $psi.FileName = $comando.Source
    }
    foreach ($a in $argumentos) { $psi.ArgumentList.Add($a) }
    if ($servidor.env) { foreach ($k in $servidor.env.Keys) { $psi.Environment[$k] = [string]$servidor.env[$k] } }
    $psi.WorkingDirectory = $raiz
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proceso = [System.Diagnostics.Process]::Start($psi)
    $errores = $proceso.StandardError.ReadToEndAsync()     # se drena aparte para que no se bloquee
    try {
        $limite = (Get-Date).AddSeconds($EsperaMaxSeg)
        $proceso.StandardInput.WriteLine($msgInitialize)
        $proceso.StandardInput.Flush()
        $init = EsperarRespuesta $proceso 1 $limite
        if (-not $init -or -not $init.result) {
            Start-Sleep -Milliseconds 300
            $detalle = if ($proceso.HasExited) { "el proceso terminó con código $($proceso.ExitCode)" } else { "no respondió initialize en $EsperaMaxSeg s" }
            Falla "$nombre (stdio): $detalle. Comando: $($comando.Source) $($argumentos -join ' ')"
            return
        }
        $proceso.StandardInput.WriteLine($msgInitialized)
        $proceso.StandardInput.WriteLine($msgToolsList)
        $proceso.StandardInput.Flush()
        $lista = EsperarRespuesta $proceso 2 $limite
        $herramientas = @($lista.result.tools | ForEach-Object { $_.name })
        Ok "$nombre (stdio): $($servidor.command) → $($init.result.serverInfo.name) $($init.result.serverInfo.version), $($herramientas.Count) herramientas: $($herramientas -join ', ')"
    } finally {
        if (-not $proceso.HasExited) { $proceso.Kill($true); $null = $proceso.WaitForExit(10000) }
    }
}

# Un servidor HTTP de MCP puede contestar JSON normal o un flujo SSE ("data: {...}"): se aceptan los dos.
function LeerJsonRpc([string]$texto) {
    $lineasData = @($texto -split "`n" | Where-Object { $_ -like 'data:*' } | ForEach-Object { $_.Substring(5).Trim() })
    $candidato = if ($lineasData.Count -gt 0) { $lineasData[-1] } else { $texto }
    return $candidato | ConvertFrom-Json -Depth 20
}

function ProbarHttp([string]$nombre, $servidor) {
    $cabeceras = @{ Accept = 'application/json, text/event-stream' }
    try {
        $r = Invoke-WebRequest -Method Post -Uri $servidor.url -Headers $cabeceras -ContentType 'application/json' `
            -Body $msgInitialize -TimeoutSec $EsperaMaxSeg
        $init = LeerJsonRpc ([string]$r.Content)
        $sesion = $r.Headers['Mcp-Session-Id']
        if ($sesion) { $cabeceras['Mcp-Session-Id'] = [string]$sesion }
        $cabeceras['MCP-Protocol-Version'] = [string]$init.result.protocolVersion
        $null = Invoke-WebRequest -Method Post -Uri $servidor.url -Headers $cabeceras -ContentType 'application/json' `
            -Body $msgInitialized -TimeoutSec $EsperaMaxSeg -SkipHttpErrorCheck
        $t = Invoke-WebRequest -Method Post -Uri $servidor.url -Headers $cabeceras -ContentType 'application/json' `
            -Body $msgToolsList -TimeoutSec $EsperaMaxSeg
        $herramientas = @((LeerJsonRpc ([string]$t.Content)).result.tools | ForEach-Object { $_.name })
        Ok "$nombre (http): $($servidor.url) → $($init.result.serverInfo.name), $($herramientas.Count) herramientas: $($herramientas -join ', ')"
    } catch {
        Falla "$nombre (http): $($servidor.url) no respondió como servidor MCP: $($_.Exception.Message)"
    }
}

# --- 1. El archivo -----------------------------------------------------------------------------------
if (-not (Test-Path $Archivo)) {
    Falla "No existe $Archivo en $raiz. ¿Estás en la raíz de tu repo? ¿Copiaste el archivo?"
    exit 1
}
try {
    $config = Get-Content $Archivo -Raw | ConvertFrom-Json -AsHashtable -Depth 20
} catch {
    Falla "$Archivo no es JSON válido: $($_.Exception.Message)"
    exit 1
}
if (-not $config.ContainsKey('servers')) {
    $pista = if ($config.ContainsKey('mcpServers')) { ' Tiene «mcpServers»: esa es la clave de la CLI, no la de VS Code.' } else { '' }
    Falla "$Archivo no tiene la clave «servers».$pista"
    exit 1
}
Ok "$Archivo es JSON válido y define $($config.servers.Count) servidores: $($config.servers.Keys -join ', ')"

# --- 2. Cada servidor ----------------------------------------------------------------------------------
foreach ($nombre in $config.servers.Keys) {
    $servidor = $config.servers[$nombre]
    switch ($servidor.type) {
        'stdio' { ProbarStdio $nombre $servidor }
        'http'  { ProbarHttp  $nombre $servidor }
        default { Falla "${nombre}: tipo «$($servidor.type)» desconocido (VS Code acepta stdio, http y sse)." }
    }
}

if ($script:fallas -eq 0) {
    Write-Host 'RESULTADO: todos los servidores respondieron' -ForegroundColor Green
    exit 0
}
Write-Host "RESULTADO: $($script:fallas) con FALLA" -ForegroundColor Red
exit 1
