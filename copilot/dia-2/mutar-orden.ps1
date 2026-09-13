#Requires -Version 7.0
<#
.SYNOPSIS
  Mutación manual: quita el orden de un método de TaskService, corre TaskServiceTest y deja el archivo
  exactamente como estaba.

.DESCRIPTION
  Un test «de orden» solo vigila el orden si se pone rojo cuando alguien quita el orden. Este script lo
  comprueba sin depender de lo que diga el agente:

    1. Lee src\main\java\com\taskflow\service\TaskService.java y lo guarda en memoria.
    2. Busca el método pedido (List<Task> vencidas() o List<Task> sinResponsable()) y, DENTRO de ese
       método, el primer .sorted(TaskOrders.POR_FECHA) (o .sorted(POR_FECHA) con import estático). Lo
       cambia por el comentario /*MUTANTE*/.
    3. Corre mvn test "-Dtest=TaskServiceTest" (incluye las clases @Nested) y deja pasar solo el resumen.
    4. En un bloque finally escribe de vuelta los bytes originales del archivo y compara su hash con el
       de antes.

  Qué imprime:
    MUTANTE: …                 la mutación entró
    [ERROR] Tests run: …       resumen de Maven (lo que esperas es BUILD FAILURE)
    RESTAURADO: …              el archivo volvió a su contenido original
    SIN MUTAR: …               no se pudo mutar: el método no existe o no usa TaskOrders.POR_FECHA.
                               Eso ya es un hallazgo del checklist (puntos 1 o 5): no hay nada que correr.

  Si cortas el script con Ctrl+C mientras corre Maven, comprueba después que no quedó el mutante:
  Select-String -Path src\main\java\com\taskflow\service\TaskService.java -SimpleMatch '/*MUTANTE*/'
  no tiene que imprimir nada.

  Por qué no se deshace con git restore: si el agente dejó cambios sin commitear en TaskService.java
  (por ejemplo después de un follow-up), git restore se los llevaría también.

  Códigos de salida: 0 mutó, corrió Maven y restauró · 1 no pudo restaurar · 2 no estás en la raíz del
  repo · 3 SIN MUTAR.

.PARAMETER Metodo
  vencidas (GET /tasks/overdue) o sinResponsable (GET /tasks/unassigned).

.EXAMPLE
  cd $HOME\taskflow-copilot-<tu-usuario>
  & $HOME\academyMty\copilot\dia-2\mutar-orden.ps1 -Metodo vencidas

.EXAMPLE
  & $HOME\academyMty\copilot\dia-2\mutar-orden.ps1 -Metodo vencidas | Tee-Object -Append evidencia\dia2\checklist-overdue.txt
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('vencidas', 'sinResponsable', IgnoreCase = $false)]
    [string]$Metodo
)

$ErrorActionPreference = 'Stop'

$archivo = 'src\main\java\com\taskflow\service\TaskService.java'
if (-not (Test-Path -LiteralPath $archivo)) {
    Write-Output "ERROR: no encuentro $archivo. Ejecuta el script desde la raíz de tu repo (donde está pom.xml)."
    exit 2
}
$ruta = (Resolve-Path -LiteralPath $archivo).Path

# Bytes y hash originales: lo que se restaura es exactamente esto.
$bytes = [System.IO.File]::ReadAllBytes($ruta)
$hash = (Get-FileHash -LiteralPath $ruta).Hash
$original = Get-Content -LiteralPath $ruta -Raw

# El método va desde su firma hasta el siguiente 'public ' (el siguiente método) o el final del archivo.
$firma = "List<Task> $Metodo()"
$inicio = $original.IndexOf($firma)
if ($inicio -lt 0) {
    Write-Output "SIN MUTAR: TaskService.java no tiene '$firma'. El agente no siguió la spec (punto 1 del checklist)."
    exit 3
}
$fin = $original.IndexOf('public ', $inicio + $firma.Length)
if ($fin -lt 0) { $fin = $original.Length }

$orden = [regex]::Match($original.Substring($inicio, $fin - $inicio), '\.sorted\(\s*(TaskOrders\.)?POR_FECHA\s*\)')
if (-not $orden.Success) {
    Write-Output "SIN MUTAR: $Metodo() no ordena con TaskOrders.POR_FECHA. El agente no reutilizó el orden (punto 5 del checklist)."
    exit 3
}
$corte = $inicio + $orden.Index
$mutado = $original.Substring(0, $corte) + '/*MUTANTE*/' + $original.Substring($corte + $orden.Length)

try {
    Set-Content -LiteralPath $ruta -Value $mutado -NoNewline
    Write-Output "MUTANTE: quitado $($orden.Value) de $Metodo()"
    # Solo el resumen de Maven. Los WARNING de Java y el aviso de Mockito van por stderr: se ven, no son fallos.
    mvn test "-Dtest=TaskServiceTest" | Select-String -CaseSensitive 'Tests run:.*Skipped: \d+$|BUILD'
}
finally {
    [System.IO.File]::WriteAllBytes($ruta, $bytes)
}

if ((Get-FileHash -LiteralPath $ruta).Hash -eq $hash) {
    Write-Output 'RESTAURADO: TaskService.java quedó exactamente como estaba.'
    exit 0
}
Write-Output 'ERROR: TaskService.java no quedó igual que antes. Revisa con git diff.'
exit 1
