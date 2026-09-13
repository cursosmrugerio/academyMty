#Requires -Version 7.0
<#
.SYNOPSIS
  Comprueba que lo que cita docs\ARQUITECTURA.md existe de verdad en tu repositorio.

.DESCRIPTION
  Un modelo de lenguaje escribe con la misma seguridad lo que leyó y lo que se imaginó. Este script
  no le cree a nadie: lee el Markdown, saca cada nombre que parece clase, método, endpoint o archivo,
  y lo busca en tu repo. No usa IA ni internet: su resultado no depende de lo que conteste el modelo.

  Qué revisa, y dónde:
    - El código en línea (`así` o ``así``) y <code>así</code>.
    - Los enlaces [texto](ruta) y las definiciones [ref]: ruta que no son http.
    - En el texto normal, sin backticks: nombres con sufijo de clase (TaskCacheService, ProjectDto),
      llamadas como vencidas() o TaskService.archivar(id), y endpoints (DELETE /tasks/{id}), también en tablas.
    - Dentro de los bloques de código (``` o ~~~): nombres de archivo, nombres con sufijo de clase,
      llamadas variable.metodo( y Clase.metodo( sobre clases del proyecto, y las carpetas de un árbol
      (├── service/). Cada bloque se lista en «Sin verificar».
  Los endpoints (GET /tasks/{id}, GET /tasks/7) se comparan con los @GetMapping, @PostMapping... de los controllers.
  Los comentarios del código y del pom/yml NO cuentan como prueba de que algo existe.

  Cada nombre sale con una etiqueta:
    [OK]         existe: la clase tiene su .java, la ruta está en el disco (con las mismas mayúsculas),
                 el método está declarado en esa clase o el endpoint lo declara un controller.
    [NO EXISTE]  no está en el proyecto, o está atribuido a la clase equivocada, o el endpoint existe
                 con otro verbo. Es lo que hay que corregir.
    [REVISA]     lo decides tú leyendo: un método que la clase hereda (TaskRepository.save viene de
                 Spring Data), un nombre que solo sale en comentarios (la cabecera Location), o un
                 miembro de una librería que el código nunca escribe.
    [EXTERNA]    no es un archivo del proyecto, pero el código sí la usa: una clase de Spring, de Java o
                 de una librería (OncePerRequestFilter).
  Lo que no sabe comprobar (comandos, códigos HTTP, constantes en MAYÚSCULAS, patrones con *) no lo
  descarta en silencio: lo lista al final como «Sin verificar» para que lo leas tú.

  Códigos de salida: 0 si no hay ningún NO EXISTE · 1 si hay alguno · 2 si falta el repo o el archivo ·
  3 si no encontró nada que comprobar o un bloque de código no se cierra (no se da por bueno).

.PARAMETER Archivo
  El Markdown a revisar. Por defecto, docs\ARQUITECTURA.md.

.PARAMETER Repo
  La raíz del repositorio (la carpeta que tiene pom.xml y src). Por defecto, la carpeta actual.

.EXAMPLE
  cd $HOME\taskflow-copilot-<tu-usuario>
  & $HOME\academyMty\copilot\dia-1\verificar-arquitectura.ps1

.EXAMPLE
  & $HOME\academyMty\copilot\dia-1\verificar-arquitectura.ps1 | Tee-Object evidencia\dia1\verificador.txt
#>
param(
    [string]$Archivo = 'docs\ARQUITECTURA.md',
    [string]$Repo = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

# =============================================================================================
# 1. Comprobaciones de entrada: si faltan, no tiene sentido seguir.
# =============================================================================================
# ProviderPath (y no Path): abierto desde una carpeta de red o \\wsl.localhost\..., Path trae el
# prefijo «Microsoft.PowerShell.Core\FileSystem::» y los recortes de ruta de abajo fallarían.
$Repo = (Resolve-Path -LiteralPath $Repo).ProviderPath
# Sin barra final: con -Repo C:\...\repo\ (lo que deja el tabulador) el filtro de .git/target/data fallaba.
if ($Repo.Length -gt 3) { $Repo = $Repo.TrimEnd('\', '/') }
if (-not (Test-Path -LiteralPath (Join-Path $Repo 'src') -PathType Container)) {
    Write-Output "ERROR: en $Repo no hay carpeta src. Ejecuta el script desde la raíz de tu repo (donde está pom.xml)."
    exit 2
}
$rutaMd = if ([System.IO.Path]::IsPathRooted($Archivo)) { $Archivo } else { Join-Path $Repo $Archivo }
if (-not (Test-Path -LiteralPath $rutaMd -PathType Leaf)) {
    Write-Output "ERROR: no existe $rutaMd. ¿Ya lo escribió el agente? Compruébalo con: Test-Path $Archivo"
    exit 2
}
$rutaMd = (Resolve-Path -LiteralPath $rutaMd).ProviderPath

# =============================================================================================
# 2. Índice del repositorio. Se lee UNA vez.
#    Se ignoran .git, target y data: los generan Git, Maven y H2; no son código del proyecto.
# =============================================================================================
# target y data solo en la RAÍZ: un paquete com.taskflow.data no es la carpeta de H2 y no se debe esconder.
$ignorar = '^[\\/](target|data)([\\/]|$)|[\\/](\.git|node_modules)([\\/]|$)'
$archivos = Get-ChildItem -LiteralPath $Repo -Recurse -File -Force |
    Where-Object { $_.FullName.Substring($Repo.Length) -notmatch $ignorar }

# Ruta relativa a la raíz del repo, para imprimir corto. Si está fuera del repo, se deja completa.
function Relativa([string]$ruta) {
    if ($ruta.StartsWith($Repo, [System.StringComparison]::OrdinalIgnoreCase)) { return $ruta.Substring($Repo.Length).TrimStart('\', '/') }
    return $ruta
}

# $porNombre: nombre de archivo -> rutas (distingue mayúsculas, como Java).
# $rutasRepo: TODAS las rutas del repo (archivos y carpetas) con '/'. Se usa en vez de Test-Path porque
# Test-Path en Windows no distingue mayúsculas (task.java daba OK) y deja salir del repo (..\..\Windows).
$porNombre = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
$rutasRepo = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$rutasRepoCI = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)
# Nombres de carpeta (último tramo), para los árboles de directorios del documento.
$carpetas = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($a in $archivos) {
    if (-not $porNombre.ContainsKey($a.Name)) { $porNombre[$a.Name] = [System.Collections.Generic.List[string]]::new() }
    $rel = Relativa $a.FullName
    $porNombre[$a.Name].Add($rel)
    $p = $rel -replace '\\', '/'
    $esArchivo = $true
    while ($p) {
        if (-not $esArchivo) { [void]$carpetas.Add($p.Substring($p.LastIndexOf('/') + 1)) }
        $esArchivo = $false
        if (-not $rutasRepo.Add($p)) { break }
        $rutasRepoCI[$p] = $p
        $i = $p.LastIndexOf('/')
        $p = if ($i -gt 0) { $p.Substring(0, $i) } else { '' }
    }
}

# Texto de los fuentes (src y pom.xml; docs\ no, porque el Markdown no puede ser prueba de sí mismo).
# Para cada archivo se guardan dos versiones:
#   Texto  = tal cual;
#   Codigo = sin comentarios (y en .java, sin el contenido de las cadenas). Que un comentario diga
#            «vencidas primero» no demuestra que exista un método vencidas(), ni que el yml mencione
#            «Flyway» demuestra que el proyecto use Flyway.
# En Java un solo patrón reconoce primero las cadenas: la cadena "/auth/**" contiene «/*» y, si no,
# parecería el inicio de un comentario y se tragaría código de verdad.
$extTexto = '\.(java|ya?ml|xml|properties|sql|html|js|css|json|txt)$'
$cadenasYComentarios = '("""[\s\S]*?"""|"(?:\\.|[^"\\\r\n])*"|''(?:\\.|[^''\\\r\n])+'')|(/\*[\s\S]*?\*/|//[^\r\n]*)'
$fuentes = foreach ($a in $archivos) {
    $rel = Relativa $a.FullName
    if (($rel -match '^src[\\/]' -and $a.Name -match $extTexto) -or $rel -eq 'pom.xml') {
        $texto = [string](Get-Content -LiteralPath $a.FullName -Raw)
        $codigo = switch -Regex ($a.Name) {
            '\.java$'       { $texto -replace $cadenasYComentarios, { if ($_.Groups[1].Success) { '""' } else { ' ' } }; break }
            '\.(js|css)$'   { $texto -replace $cadenasYComentarios, { if ($_.Groups[1].Success) { $_.Value } else { ' ' } }; break }
            '\.(ya?ml)$'    { $texto -replace '(?m)(^|\s)#.*$', ' '; break }
            '\.properties$' { $texto -replace '(?m)^\s*[#!].*$', ' '; break }
            '\.(xml|html)$' { $texto -replace '<!--[\s\S]*?-->', ' ' -replace '<description>[\s\S]*?</description>', ' '; break }
            '\.sql$'        { $texto -replace '(?m)--.*$', ' '; break }
            default         { $texto }
        }
        # CodigoCad = sin comentarios pero CON cadenas: hasRole('ADMIN') o @projectSecurity solo viven dentro
        #        de "@PreAuthorize(...)", y eso es código que Spring ejecuta, no un comentario.
        $codigoCad = if ($a.Name -like '*.java') { $texto -replace $cadenasYComentarios, { if ($_.Groups[1].Success) { $_.Value } else { ' ' } } } else { $codigo }
        [pscustomobject]@{ Rel = $rel; Nombre = $a.Name; Codigo = $codigo; CodigoCad = $codigoCad; Texto = $texto }
    }
}
# Todo el Java sin comentarios en una sola cadena: filtro rápido antes de recorrer archivo por archivo.
$javaTodo = (@($fuentes | Where-Object Nombre -like '*.java' | ForEach-Object Codigo)) -join "`n"

# Endpoints que declaran los controllers: @GetMapping("/tasks/{id}"), más el @RequestMapping("/auth")
# de la clase. Las variables de ruta se normalizan a {} para comparar /tasks/{id} con /tasks/{taskId}.
function NormalizarEndpoint([string]$e) {
    # /tasks/:id (notación de Express) es la misma ruta que /tasks/{id}.
    # Y los marcadores de un ejemplo: /tasks/<id>, /tasks/$id, /tasks/${id}, /tasks/$($t.id), /tasks/{{taskId}}
    #        (Postman). Antes «DELETE /tasks/<id>» salía NO EXISTE. Solo ocupan un tramo entero: /tasks/<id>/archive sigue sin existir.
    $e = $e -replace '\?.*$', '' -replace '\{\{[^}/]*\}\}', '{}' -replace '(?<=/)(?:<[\w-]*>?|\$\{[\w.-]*\}|\$\([^)/]*\)|\$\w+)(?=/|$)', '{}'
    $e = ($e -replace '\{[^}]*\}', '{}' -replace '(?<=/):\w+', '{}').TrimEnd('/')
    if (-not $e.StartsWith('/')) { $e = '/' + $e }
    return $e
}
# Un ejemplo con id concreto (GET /tasks/7) es la ruta declarada /tasks/{id}.
function RutaCoincide([string]$doc, [string]$decl) {
    if ($doc -ceq $decl) { return $true }
    $a = $doc.Split('/'); $b = $decl.Split('/')
    if ($a.Count -ne $b.Count) { return $false }
    for ($i = 0; $i -lt $a.Count; $i++) {
        if ($a[$i] -ceq $b[$i]) { continue }
        if ($b[$i] -eq '{}' -and $a[$i] -match '^(\d+|[0-9a-fA-F-]{32,36})$') { continue }
        return $false
    }
    return $true
}
$endpoints = [System.Collections.Generic.List[object]]::new()
foreach ($f in @($fuentes | Where-Object Nombre -like '*.java')) {
    $sc = $f.CodigoCad
    $mClase = [regex]::Match($sc, '\b(class|interface|record)\s+\w+')
    if (-not $mClase.Success) { continue }
    $base = ''
    $mb = [regex]::Match($sc.Substring(0, $mClase.Index), '@RequestMapping\s*\(\s*(?:(?:value|path)\s*=\s*)?\{?\s*"([^"]*)"')
    if ($mb.Success) { $base = $mb.Groups[1].Value }
    foreach ($m in [regex]::Matches($sc.Substring($mClase.Index), '@(Get|Post|Put|Patch|Delete|Request)Mapping\b\s*(\((?:[^()"]|"[^"]*"|\([^()]*\))*\))?')) {
        $argMap = $m.Groups[2].Value
        $verbo = if ($m.Groups[1].Value -eq 'Request') { $v = [regex]::Match($argMap, 'RequestMethod\.(\w+)'); if ($v.Success) { $v.Groups[1].Value } else { '*' } } else { $m.Groups[1].Value.ToUpper() }
        $rutas = @([regex]::Matches(($argMap -replace '\b(produces|consumes|params|headers|name)\s*=\s*(\{[^}]*\}|"[^"]*")', ''), '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value })
        if ($rutas.Count -eq 0) { $rutas = @('') }
        foreach ($r in $rutas) { $endpoints.Add([pscustomobject]@{ Verbo = $verbo; Ruta = (NormalizarEndpoint ($base + $r)); Rel = $f.Rel }) }
    }
}

# =============================================================================================
# 3. Sacar los candidatos del Markdown, con su número de línea y de dónde salieron.
# =============================================================================================
$candidatos = [System.Collections.Generic.List[object]]::new()
$avisos = [System.Collections.Generic.List[string]]::new()
function Cand([string]$texto, [int]$linea, [string]$origen = 'backtick') {
    $candidatos.Add([pscustomobject]@{ Texto = $texto; Linea = $linea; Origen = $origen })
}
# Nombres con sufijo típico de clase: se buscan también dentro de los bloques y en el texto normal.
$sufijos = '(?:Service|Controller|Repository|Mapper|Config|Configuration|Filter|Exception|Request|Response|Dto|DTO|Entity|Handler|Advice|Security|Test|Tests|IT|Application|Seeder|Provider|Manager|Utils?|Helper|Factory|Listener|Interceptor|Validator|Converter|Adapter|Impl|Orders)'
$reClaseSufijo = "\b[A-Z][A-Za-z0-9]*[a-z][A-Za-z0-9]*$sufijos\b"

$lineas = @(Get-Content -LiteralPath $rutaMd)
# Documento envuelto entero en ```markdown ... ``` (pasa al copiar una respuesta del chat): se avisa
# y se revisa como si esas dos líneas no estuvieran.
$ini = 0; $fin = $lineas.Count - 1
while ($ini -le $fin -and -not $lineas[$ini].Trim()) { $ini++ }
while ($fin -ge $ini -and -not $lineas[$fin].Trim()) { $fin-- }
$envuelto = ($ini -lt $fin -and $lineas[$ini] -match '^\s*(`{3,}|~{3,})\s*(markdown|md)\s*$' -and $lineas[$fin] -match '^\s*(`{3,}|~{3,})\s*$')
if ($envuelto) { $avisos.Add("El archivo viene envuelto en un bloque ``````markdown (líneas $($ini + 1) y $($fin + 1)): quítale esas dos líneas; se revisó como si no estuvieran.") }

$cerca = $null; $arbolGenerado = $null
for ($k = 0; $k -lt $lineas.Count; $k++) {
    $linea = $lineas[$k]; $n = $k + 1
    if ($envuelto -and ($k -eq $ini -or $k -eq $fin)) { continue }
    # Un bloque lo cierra solo una cerca del MISMO carácter, al menos igual de larga y sin texto después
    # (como CommonMark). «```mvn test``` y sigue» es código en línea, no una cerca.
    $esCerca = $false
    if ($linea -match '^\s*(`{3,}|~{3,})\s*(.*)$') {
        $marca = $Matches[1]; $resto = $Matches[2].Trim()
        $esCerca = -not ($marca[0] -eq [char]'`' -and $resto.Contains('`'))
        $info = ($resto -split '\s+')[0]
    }
    if ($esCerca) {
        if (-not $cerca) { $cerca = @{ Char = $marca[0]; Largo = $marca.Length; Info = $info; Desde = $n }; $arbolGenerado = $null; continue }
        if ($marca[0] -eq $cerca.Char -and $marca.Length -ge $cerca.Largo -and -not $info) {
            $candidatos.Add([pscustomobject]@{ Texto = "bloque $($cerca.Char)$($cerca.Char)$($cerca.Char)$($cerca.Info) (l. $($cerca.Desde)-$n)"; Linea = $cerca.Desde; Origen = 'bloque' })
            $cerca = $null; continue
        }
    }
    if ($cerca) {
        # Lo que cuelga de target/ en un árbol (classes/, surefire-reports/, site/jacoco/) lo genera
        #        Maven: no está indexado y antes salía NO EXISTE. Se salta hasta la siguiente rama del mismo nivel o menos.
        $mArbol = [regex]::Match($linea, '^([\s│|]*)(├─+|└─+|\|--|\+--|`--)\s*(\S*)')
        $sangria = [regex]::Match($linea, '^[\s│|]*').Length
        if ($null -ne $arbolGenerado) {
            if ($sangria -ge $linea.Length -or $sangria -gt $arbolGenerado) { continue }   # vacía o «│», o más adentro
            $arbolGenerado = $null
        }
        #        Solo target (data/ de H2 no tiene subcarpetas: un «data/cache/» en un árbol sigue revisándose) y solo si
        #        el repo no tiene una carpeta indexada que se llame así.
        if ($mArbol.Success -and $mArbol.Groups[3].Value -match '^(?:\./)?target(/|$)' -and -not $carpetas.Contains('target')) { $arbolGenerado = $mArbol.Groups[1].Length }
        # Dentro de un bloque: archivos, clases con sufijo y variable.metodo( de clases del proyecto.
        # Sin las URL: en «curl http://localhost:8080/v3/api-docs.yaml», api-docs.yaml no es un archivo del repo.
        $sinUrl = $linea -replace '\b[a-zA-Z][\w+.-]*://\S+', ' ' -replace '(?<![\w/.-])(localhost|127\.0\.0\.1)(:\d+)?/\S*', ' '
        # Lo que cuelga de target\ o data\ se toma ENTERO: de «target/site/jacoco/jacoco.xml» solo salía
        #        jacoco.xml, que no está en el disco (NO EXISTE), y el 5.11 no podía ver que era de la carpeta de Maven.
        foreach ($m in [regex]::Matches($sinUrl, '((?<![\w.-])(?:\.[\\/])?(?:target|data)(?:[\\/][\w.-]+)+\.(?:java|ya?ml|xml|properties|sql|html|js|css|json|md)(?![\w(])|src[\\/][\w./\\-]+|(?<![@\w])[\w.-]+\.(java|ya?ml|xml|properties|sql|html|js|css|json|md)(?![\w(]))')) { Cand $m.Value $n 'enbloque' }
        foreach ($m in [regex]::Matches($linea, $reClaseSufijo)) { Cand $m.Value $n 'enbloque' }
        foreach ($m in [regex]::Matches($linea, '\b([a-z]\w*)\.([a-z]\w*)\s*\(')) {
            $cap = $m.Groups[1].Value.Substring(0, 1).ToUpper() + $m.Groups[1].Value.Substring(1)
            if ($porNombre.ContainsKey("$cap.java")) { Cand "$($m.Groups[1].Value).$($m.Groups[2].Value)()" $n 'enbloque' }
        }
        # Llamadas estáticas a clases del proyecto: TaskMapper.aEntidad(...) inventado pasaba en silencio.
        foreach ($m in [regex]::Matches($linea, '(?<![.\w])([A-Z]\w*)\.([a-z]\w*)\s*\(')) {
            if ($porNombre.ContainsKey("$($m.Groups[1].Value).java")) { Cand "$($m.Groups[1].Value).$($m.Groups[2].Value)()" $n 'enbloque' }
        }
        # Árbol de carpetas: «├── util/» inventada pasaba en silencio si no llevaba archivos debajo.
        # También con un solo guion (├─ util/), que dibujan muchos generadores: antes pasaba en silencio.
        if ($linea -match '^[\s│|]*(├─+|└─+|\|--|\+--|`--)\s*([^\s#]+/)') {
            $segs = @($Matches[2].TrimEnd('/') -split '/' | Where-Object { $_ -ne '.' })
            # «├── target/classes/»: nada de lo que cuelga de target se busca.
            if ($segs.Count -gt 0 -and $segs[0] -ceq 'target' -and -not $carpetas.Contains('target')) { $segs = @() }
            foreach ($seg in $segs) { if ($seg -match '^[\w.-]+$') { Cand "DIR|$seg" $n 'arbol' } }
        }
        continue
    }
    # Fila de tabla con el verbo en su propia celda: | `POST` | `/tasks` | -> se comprueba «POST /tasks».
    $verboFila = $null
    if ($linea.TrimStart().StartsWith('|')) {
        $vs = @(($linea.Trim().Trim('|') -split '\|') | ForEach-Object { $_.Trim().Trim('`').Trim() } | Where-Object { [regex]::IsMatch($_, '^(GET|POST|PUT|PATCH|DELETE)$') })
        if ($vs.Count -eq 1) { $verboFila = $vs[0] }
    }
    # Código en línea con uno o más backticks.
    foreach ($m in [regex]::Matches($linea, '(?<!`)(`+)(?!`)(.+?)(?<!`)\1(?!`)')) {
        $txt = $m.Groups[2].Value
        if ($txt.Length -ge 2 -and $txt.StartsWith(' ') -and $txt.EndsWith(' ')) { $txt = $txt.Substring(1, $txt.Length - 2) }
        if ($verboFila) {
            if ($txt -ceq $verboFila) { continue }
            if ([regex]::IsMatch($txt, '^/\S*$')) { $txt = "$verboFila $txt" }
        }
        Cand $txt $n
    }
    # Enlaces (también con título o <...>), definiciones de referencia y <code>.
    foreach ($m in [regex]::Matches($linea, '\]\(\s*<?([^)\s>]+)>?(?:\s+("[^"]*"|''[^'']*''))?\s*\)')) {
        if ($m.Groups[1].Value -notmatch '^(https?:|mailto:|#)') { Cand $m.Groups[1].Value $n 'enlace' }
    }
    if ($linea -match '^\s{0,3}\[[^\]]+\]:\s*<?([^\s>]+)>?' -and $Matches[1] -notmatch '^(https?:|mailto:|#)') { Cand $Matches[1] $n 'enlace' }
    foreach ($m in [regex]::Matches($linea, '<code>([^<]+)</code>')) { Cand $m.Groups[1].Value $n }
    # Texto normal (sin lo anterior): clases con sufijo y llamadas, aunque no vayan entre backticks.
    $prosa = $linea -replace '(?<!`)(`+)(?!`).+?(?<!`)\1(?!`)', ' ' -replace '\]\([^)]*\)', '] ' -replace '<code>[^<]*</code>', ' '
    # También con argumentos: «TaskService.archivarTarea(id)» o «Task.archivar(id)» en una frase.
    foreach ($m in [regex]::Matches($prosa, "(?:$reClaseSufijo)(?:\.[a-z]\w*\([^()\r\n]*\))?|\b[A-Z][a-z]\w*\.[a-z]\w*\([^()\r\n]*\)|\b[a-z]\w*\.[a-z]\w*\([^()\r\n]*\)|\b[a-z]\w*[A-Z]\w*\([^()\r\n]*\)|\b[a-z]\w*\(\)")) { Cand $m.Value $n 'prosa' }
    # Endpoints en el texto normal y en tablas sin backticks: «DELETE /tasks/{id}/archive» pasaba en silencio.
    foreach ($m in [regex]::Matches($prosa, '(?<![\w/-])(GET|POST|PUT|PATCH|DELETE)(?:\s+|\s*\|\s*)(/[^\s|`)\]>,;»"''”]*)')) { Cand "$($m.Groups[1].Value) $($m.Groups[2].Value)" $n 'prosa' }
    if ($verboFila) { foreach ($m in [regex]::Matches($prosa, '\|\s*(/[^\s|`]*)\s*(?=\|)')) { Cand "$verboFila $($m.Groups[1].Value)" $n 'prosa' } }
}
if ($cerca) {
    $avisos.Add("El bloque que abre en la línea $($cerca.Desde) (``$(([string]$cerca.Char) * $cerca.Largo)$($cerca.Info)``) nunca se cierra: lo que sigue no se revisó como texto.")
}

# =============================================================================================
# 4. Funciones de búsqueda.
# =============================================================================================
# Archivos .java de src que se llaman exactamente <Clase>.java.
function ArchivosDeClase([string]$clase) {
    $nombre = "$clase.java"
    if ($porNombre.ContainsKey($nombre)) { return @($porNombre[$nombre] | Where-Object { $_ -match '^src[\\/]' }) }
    return @()
}

# Fuentes donde aparece <nombre> como palabra completa. Sin -Crudo, sin contar comentarios. Con
# -Llamada, seguido de «(». En el pom.xml se busca sin distinguir mayúsculas (junit, testcontainers).
function DondeAparece([string]$nombre, [switch]$Llamada, [switch]$Crudo, [switch]$Cadenas) {
    $patron = '\b' + [regex]::Escape($nombre) + '\b' + $(if ($Llamada) { '\s*\(' } else { '' })
    @($fuentes | Where-Object {
        $donde = if ($Crudo) { $_.Texto } elseif ($Cadenas) { $_.CodigoCad } else { $_.Codigo }
        if ($_.Rel -eq 'pom.xml') { $donde -imatch $patron } else { $donde -cmatch $patron }
    } | ForEach-Object Rel)
}

# Archivos .java de src que DECLARAN <nombre> como método (o campo/variable) propio: «List<Task>
# findByStatus(» sí; «repo.findByStatus(», «return crear(» o un @Override no. Sirve para distinguir lo que
# una clase hereda de una librería (TaskRepository.save) de lo que es propio de OTRA clase del proyecto.
function Declaraciones([string]$nombre, [bool]$Llamada) {
    $patron = '(?<=(?:[\w\]]|[^-]>)\s+)(?<!\b(?:return|new|throw|else|case|yield|assert|await|package|import)\s+)\b' +
              [regex]::Escape($nombre) + $(if ($Llamada) { '\s*\(' } else { '\s*[;=,)]' })
    foreach ($f in @($fuentes | Where-Object { $_.Nombre -like '*.java' })) {
        foreach ($m in [regex]::Matches($f.Codigo, $patron)) {
            $ini = $f.Codigo.LastIndexOfAny([char[]]';{}', [Math]::Max($m.Index - 1, 0)) + 1
            if ($f.Codigo.Substring($ini, $m.Index - $ini) -cnotmatch '@Override\b') { $f.Rel; break }
        }
    }
}

# ¿El código usa OTRA clase con el mismo nombre (de una librería) con ese miembro? JpaUserDetailsService
# escribe org.springframework.security.core.userdetails.User.builder(): no es com.taskflow.model.User.
function UsoAjeno([string]$clase, [string]$miembro) {
    $c = [regex]::Escape($clase); $mi = [regex]::Escape($miembro)
    # Filtro rápido sobre todo el Java junto: casi nunca hay otra clase homónima, y recorrer archivo por archivo cuesta.
    if ($javaTodo -cnotmatch ('(?<!\w)' + $c + '\s*(?:\.|::)\s*' + $mi + '\b')) { return $null }
    foreach ($f in @($fuentes | Where-Object Nombre -like '*.java')) {
        foreach ($m in [regex]::Matches($f.Codigo, '(?<![\w.])((?:[a-z_]\w*\.)+)' + $c + '\s*(?:\.|::)\s*' + $mi + '\b')) {
            if (-not $m.Groups[1].Value.StartsWith('com.taskflow.')) { return "$($m.Groups[1].Value)$clase.$miembro en $($f.Rel)" }
        }
        $imp = [regex]::Match($f.Codigo, '\bimport\s+(?!com\.taskflow\.)((?:[a-z_]\w*\.)+)' + $c + '\s*;')
        if ($imp.Success -and [regex]::IsMatch($f.Codigo, '(?<![\w.])' + $c + '\s*(?:\.|::)\s*' + $mi + '\b')) {
            return "$($imp.Groups[1].Value)$clase.$miembro en $($f.Rel)"
        }
    }
    return $null
}

# Una clase que no es del proyecto: EXTERNA si el código la usa; REVISA si solo sale en comentarios o
# textos; NO EXISTE si no sale en ningún lado. Devuelve $true si quedó EXTERNA.
function ClaseAjena([string]$clase, [string]$tipo, [string]$nombre, [int]$linea) {
    $donde = @(DondeAparece $clase)
    if ($donde.Count -gt 0) {
        Anotar 'EXTERNA' $tipo $nombre $linea "$clase no es archivo del proyecto; el código la usa en $($donde.Count) archivo(s), p. ej. $($donde[0])"
        return $true
    }
    # Nombre de una librería que se escribe distinto a su paquete: Hamcrest -> import org.hamcrest...
    $lib = @(if ($javaTodo -imatch ('\b' + [regex]::Escape($clase) + '\.')) { $fuentes | Where-Object { $_.Nombre -like '*.java' -and $_.Codigo -imatch ('\bimport\s+(?:static\s+)?(?!com\.taskflow\.)(?:\w+\.)*' + [regex]::Escape($clase) + '\.') } | ForEach-Object Rel })
    if ($lib.Count -gt 0) {
        Anotar 'EXTERNA' $tipo $nombre $linea "$clase es el nombre de una librería: el código importa su paquete ($($clase.ToLower())), p. ej. $($lib[0])"
        return $true
    }
    $crudo = @(DondeAparece $clase -Crudo)
    if ($crudo.Count -gt 0) {
        Anotar 'REVISA' $tipo $nombre $linea "$clase no se usa en el código; solo sale en comentarios o textos, p. ej. $($crudo[0])"
    } else {
        Anotar 'NO EXISTE' $tipo $nombre $linea "no hay $clase.java y el nombre no sale en src ni en pom.xml"
    }
    return $false
}

# Busca una ruta en el índice. Acepta: desde la raíz (src/main/...), desde las carpetas de fuentes de
# Maven (com/taskflow/model/Task.java), rutas parciales reales (service/TaskService.java), solo el nombre
# (pom.xml), enlaces relativos al Markdown (../src/...), y quita #L42, :42 y, en enlaces, #ancla o ?x.
# Devuelve @{Ruta} si existe, @{Mayus} si solo existe con otras mayúsculas, o $null.
function BuscarRuta([string]$ruta, [bool]$Enlace) {
    $r = $ruta -replace '\\', '/'
    $r = $r -replace '#L\d+(-L?\d+)?$', '' -replace ':\d+(-\d+)?$', ''
    if ($Enlace) { $r = $r -replace '[#?].*$', '' }
    if (-not $r) { return $null }
    $prueba = [System.Collections.Generic.List[string]]::new()
    if ($r -match '^[A-Za-z]:/') {
        # Absoluta: vale solo si está dentro de este repo.
        $abs = $r -replace '/', '\'
        if ($abs.StartsWith($Repo + '\', [System.StringComparison]::OrdinalIgnoreCase)) { $prueba.Add(($abs.Substring($Repo.Length + 1) -replace '\\', '/')) } else { return $null }
    } else {
        # Enlaces y rutas con ../ se resuelven desde la carpeta del Markdown (docs\), como hace GitHub.
        if ($Enlace -or $r.StartsWith('../')) {
            $abs = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Split-Path -Parent $rutaMd), ($r -replace '/', '\')))
            if ($abs.StartsWith($Repo + '\', [System.StringComparison]::OrdinalIgnoreCase)) { $prueba.Add(($abs.Substring($Repo.Length + 1) -replace '\\', '/').TrimEnd('/')) }
        }
        $limpia = ($r -replace '^(\./)+', '' -replace '^/', '').TrimEnd('/')
        if ($limpia -and -not $limpia.StartsWith('../')) {
            foreach ($base in '', 'src/main/java/', 'src/test/java/', 'src/main/resources/', 'src/test/resources/') { $prueba.Add($base + $limpia) }
        }
    }
    foreach ($x in $prueba) { if ($rutasRepo.Contains($x)) { return @{ Ruta = $x } } }
    $limpia = ($r -replace '^(\./)+', '' -replace '^/', '').TrimEnd('/')
    if ($limpia -and -not $limpia.StartsWith('../') -and ($limpia -match '/' -or $r.EndsWith('/'))) {
        foreach ($x in $rutasRepo) { if ($x.EndsWith('/' + $limpia, [System.StringComparison]::Ordinal)) { return @{ Ruta = $x } } }
    }
    if ($limpia -notmatch '/' -and $porNombre.ContainsKey($limpia)) { return @{ Ruta = $porNombre[$limpia][0] } }
    foreach ($x in $prueba) { if ($rutasRepoCI.ContainsKey($x)) { return @{ Ruta = $null; Mayus = $rutasRepoCI[$x] } } }
    return $null
}

# Dirección web que no es un archivo del repo pero que src/main nombra en su código (no en comentarios):
# /swagger-ui/index.html por "/swagger-ui/**", /favicon.ico o /swagger-ui.html tal cual. NO vale si el primer
# tramo es una carpeta de los estáticos DEL PROYECTO (/js/app.js): ahí el archivo tendría que estar en el disco.
function RutaWeb([string]$t) {
    $r = $t -replace '[?#].*$', ''
    if (-not [regex]::IsMatch($r, '^/[\w.-]')) { return @() }
    $mSeg = [regex]::Match($r, '^/([\w-]+)/')
    if ($mSeg.Success) {
        $seg = $mSeg.Groups[1].Value
        foreach ($d in 'src/main/resources/static/', 'src/main/resources/public/', 'src/main/resources/resources/', 'src/main/resources/META-INF/resources/', 'src/main/webapp/') {
            if ($rutasRepo.Contains($d + $seg)) { return @() }
        }
        $patron = '"/' + [regex]::Escape($seg) + '[/*"]'
    } elseif ([regex]::IsMatch($r, '^/[\w.-]+$')) {
        $patron = '"' + [regex]::Escape($r) + '"'
    } else { return @() }
    @($fuentes | Where-Object { $_.Rel -match '^src[\\/]main[\\/]' -and $_.CodigoCad -cmatch $patron } | ForEach-Object Rel)
}

# Un bean de SpEL (@projectSecurity.esOwner): tiene que existir la clase ProjectSecurity o un bean con ese nombre.
function RevisarBean([string]$bean, [int]$linea) {
    $clave = "bean|$bean"
    if ($vistos.ContainsKey($clave)) { return }
    $vistos[$clave] = $true
    $cap = $bean.Substring(0, 1).ToUpper() + $bean.Substring(1)
    if (@(ArchivosDeClase $cap).Count -gt 0) { return }   # el miembro ya se revisa en esa clase
    $b = [regex]::Escape($bean)
    $patron = '@(Component|Service|Repository|Controller|RestController|Configuration)\s*\(\s*(value\s*=\s*)?"' + $b + '"|@Bean\s*\([^)]*"' + $b + '"|@Bean\b[^;{]*?\b' + $b + '\s*\('
    $donde = @($fuentes | Where-Object { $_.Nombre -like '*.java' -and $_.CodigoCad -cmatch $patron } | ForEach-Object Rel)
    if ($donde.Count -gt 0) { Anotar 'OK' 'bean' "@$bean" $linea "declarado en $($donde[0])" }
    else { Anotar 'NO EXISTE' 'bean' "@$bean" $linea "ningún bean se llama $bean (no hay $cap.java ni un @Bean/@Component con ese nombre)" }
}

# Carpeta citada en un árbol de directorios.
function RevisarCarpeta([string]$nombre, [int]$linea) {
    if ($nombre -in 'target', 'data', 'node_modules', '.git') { return }
    $clave = "dir|$nombre"
    if ($vistos.ContainsKey($clave)) { return }
    $vistos[$clave] = $true
    if ($carpetas.Contains($nombre)) { Anotar 'OK' 'carpeta' "$nombre/" $linea 'hay una carpeta con ese nombre' }
    else { Anotar 'NO EXISTE' 'carpeta' "$nombre/" $linea "sale en un árbol de carpetas, pero ninguna carpeta del repo se llama $nombre" }
}

# La ruta de un @GetMapping("...")/@RequestMapping("...") citado tiene que coincidir con un controller.
function RevisarMapping([string]$anot, [string]$ruta, [int]$linea) {
    $ep = NormalizarEndpoint $ruta
    $clave = "mapping|$anot $ep"
    if ($vistos.ContainsKey($clave)) { return }
    $vistos[$clave] = $true
    $nombre = "@${anot}Mapping(""$ruta"")"
    $v = $anot.ToUpper()
    if ($ep -eq '/') {
        $hay = @($endpoints | Where-Object { $v -eq 'REQUEST' -or $_.Verbo -eq $v -or $_.Verbo -eq '*' })   # @GetMapping("") o ("/"): la ruta es la de la clase
    } elseif ($v -eq 'REQUEST') {
        $hay = @($endpoints | Where-Object { $_.Ruta -ceq $ep -or $_.Ruta.StartsWith($ep + '/') -or $_.Ruta.EndsWith($ep) })
    } else {
        $hay = @($endpoints | Where-Object { ($_.Verbo -eq $v -or $_.Verbo -eq '*') -and ($_.Ruta -ceq $ep -or $_.Ruta.EndsWith($ep)) })
    }
    if ($hay.Count -gt 0) { Anotar 'OK' 'endpoint' $nombre $linea "$($hay[0].Verbo) $($hay[0].Ruta) en $($hay[0].Rel)" }
    else { Anotar 'NO EXISTE' 'endpoint' $nombre $linea 'ningún controller declara esa ruta con ese verbo (ni como ruta completa, ni como prefijo de clase, ni como final de una ruta)' }
}

# =============================================================================================
# 5. Clasificar cada candidato.
# =============================================================================================
$pascal = '^[A-Z][A-Za-z0-9_]*[a-z][A-Za-z0-9_]*$'          # TaskService, JwtAuthenticationFilter, JUnit
# Primera palabra de las clases del proyecto (Task, Project, Jwt...): sirve para decidir en el texto normal.
$prefijos = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($k in $porNombre.Keys) { if ($k -cmatch '^([A-Z][a-z0-9]+)\w*\.java$') { [void]$prefijos.Add($Matches[1]) } }
$resultados = [System.Collections.Generic.List[object]]::new()
$sinVerificar = [System.Collections.Generic.List[object]]::new()
# «Ya visto», distinguiendo mayúsculas: con @{} JWTService se saltaba si antes había salido JwtService.
$vistos = [System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)
# Clases que bajaron a REVISA por salir en una mención débil; si luego salen entre backticks, suben.
$degradados = [System.Collections.Hashtable]::new([System.StringComparer]::Ordinal)

function Anotar($estado, $tipo, $nombre, $linea, $detalle) {
    $resultados.Add([pscustomobject]@{ Estado = $estado; Tipo = $tipo; Nombre = $nombre; Linea = $linea; Detalle = $detalle })
}

# Fuerza de una mención: '' = entre backticks (o sacada de ahí, como el tipo de un argumento);
# 'fuera' = texto normal o bloque de código; 'cadena' = pieza de «A -> B -> C» o «A/B».
function Debilidad($c) {
    if ($c.Origen -in 'prosa', 'enbloque') { return 'fuera' }
    if ($c.Origen -eq 'cadena') { return 'cadena' }
    if ($c.Origen -eq 'extra' -and $c.Debil) { return $c.Debil }
    return ''
}
function Extra([string]$texto, $padre) {
    $cola.Enqueue([pscustomobject]@{ Texto = $texto; Linea = $padre.Linea; Origen = 'extra'; Debil = (Debilidad $padre) })
}

function RevisarClase([string]$clase, [int]$linea, [string]$debil = '') {
    $clave = "clase|$clase"
    if ($vistos.ContainsKey($clave)) {
        if (-not $debil -and $degradados.ContainsKey($clase)) {
            $r = $degradados[$clase]; $degradados.Remove($clase)
            $r.Estado = 'NO EXISTE'; $r.Linea = $linea; $r.Detalle = "no hay $clase.java y el nombre no sale en src ni en pom.xml"
        }
        return
    }
    $vistos[$clave] = $true
    $propios = @(ArchivosDeClase $clase)
    if ($propios.Count -gt 0) { Anotar 'OK' 'clase' $clase $linea $propios[0]; return }
    [void](ClaseAjena $clase 'clase' $clase $linea)
    # Fuera de backticks hay menos certeza: un nombre ajeno que no sale en ningún lado (NullPointerException
    # en una frase) queda en REVISA; si empieza como una clase del proyecto (TaskCacheService) es NO EXISTE.
    # Antes bastaba con no venir de 'backtick': el tipo de un argumento (createTask(CreateTaskDto)) o
    #        @WebMvcTest(NotificationController.class) bajaban a REVISA aunque estuvieran entre backticks.
    $ultimo = $resultados[$resultados.Count - 1]
    if ($debil -and $ultimo.Estado -eq 'NO EXISTE' -and -not $prefijos.Contains([regex]::Match($clase, '^[A-Z][a-z0-9]+').Value)) {
        $ultimo.Estado = 'REVISA'
        $ultimo.Detalle = if ($debil -eq 'cadena') { 'sale como pieza de una cadena (A -> B, A/B) y no está en el proyecto (¿clase inventada, de una librería o un nombre informal?)' } else { 'sale fuera de backticks y no está en el proyecto (¿clase inventada o de una librería que el código no usa?)' }
        $degradados[$clase] = $ultimo
    }
}

function RevisarAnotacion([string]$anot, [int]$linea) {
    $clave = "anot|$anot"
    if ($vistos.ContainsKey($clave)) { return }
    $vistos[$clave] = $true
    $donde = @($fuentes | Where-Object { $_.Nombre -like '*.java' -and $_.Codigo -cmatch ('@' + [regex]::Escape($anot) + '\b') } | ForEach-Object Rel)
    if ($donde.Count -gt 0) { Anotar 'OK' 'anotación' "@$anot" $linea "se usa en $($donde.Count) archivo(s), p. ej. $($donde[0])"; return }
    $crudo = @($fuentes | Where-Object { $_.Nombre -like '*.java' -and $_.Texto -cmatch ('@' + [regex]::Escape($anot) + '\b') } | ForEach-Object Rel)
    if ($crudo.Count -gt 0) { Anotar 'REVISA' 'anotación' "@$anot" $linea "no se usa; solo sale en comentarios, p. ej. $($crudo[0])" }
    else { Anotar 'NO EXISTE' 'anotación' "@$anot" $linea 'no aparece en ningún archivo de src, ni en comentarios' }
}

function RevisarMiembro([string]$clase, [string]$miembro, [bool]$esLlamada, [int]$linea, [string]$variable = '') {
    $clave = "miembro|$clase.$miembro"
    if ($vistos.ContainsKey($clave)) { return }
    $vistos[$clave] = $true
    $nombre = "$clase.$miembro"
    $propios = @(ArchivosDeClase $clase)
    if ($propios.Count -eq 0) {
        if (ClaseAjena $clase 'miembro' $nombre $linea) {
            # La clase externa se usa, pero ¿y el miembro? Se exige Clase.miembro o variable.miembro en el código.
            $var = $clase.Substring(0, 1).ToLower() + $clase.Substring(1)
            $patron = '\b(' + [regex]::Escape($clase) + '|' + [regex]::Escape($var) + ')\s*(\.|::)\s*' + [regex]::Escape($miembro) + '\b'
            if (@($fuentes | Where-Object { $_.Codigo -cmatch $patron }).Count -eq 0) {
                $resultados[$resultados.Count - 1].Estado = 'REVISA'
                $resultados[$resultados.Count - 1].Detalle = "$clase sí se usa, pero el código nunca escribe ${clase}.${miembro}; compruébalo en la documentación de la librería"
            }
        }
        return
    }
    $codigoPropio = (@($fuentes | Where-Object { $propios -contains $_.Rel } | ForEach-Object Codigo)) -join "`n"
    # Declarado (o llamado sin nada delante) en su propia clase. «repository.findAll()» o
    # «TaskMapper::aResponse» dentro de TaskController.java son de OTRA clase: no cuentan.
    $patron = '(?<![.:])\b' + [regex]::Escape($miembro) + '\b' + $(if ($esLlamada) { '\s*\(' } else { '' })
    if ($codigoPropio -cmatch $patron) { Anotar 'OK' 'miembro' $nombre $linea $propios[0]; return }
    # Miembros que no se escriben: componentes de un record, métodos de un enum y de Object.
    $cab = [regex]::Match($codigoPropio, '\b(class|interface|record|enum)\s+' + [regex]::Escape($clase) + '\b([^{]*)\{')
    $decl = $cab.Groups[1].Value; $resto = $cab.Groups[2].Value
    if ($decl -eq 'record' -and $resto -cmatch ('\b' + [regex]::Escape($miembro) + '\s*[,)]')) { Anotar 'OK' 'miembro' $nombre $linea "$($propios[0]) (componente del record)"; return }
    $implicitos = @('toString', 'equals', 'hashCode', 'getClass')
    if ($decl -eq 'enum') { $implicitos += 'values', 'valueOf', 'name', 'ordinal', 'compareTo' }
    if ($implicitos -ccontains $miembro) { Anotar 'OK' 'miembro' $nombre $linea "$($propios[0]) (implícito de $(if ($decl) { $decl } else { 'Object' }))"; return }
    # Otra clase con el mismo nombre, de una librería, que sí lo tiene (User.builder() de Spring Security).
    $ajeno = UsoAjeno $clase $miembro
    if ($ajeno) { Anotar 'REVISA' 'miembro' $nombre $linea "$($propios[0]) no lo tiene, pero el código usa otra $clase (de una librería) que sí: $ajeno"; return }
    # Vino de «variable.metodo()» (user.getAuthorities()) y el código lo escribe TAL CUAL: la variable no es
    #         de esa clase (en JwtService, user es un UserDetails). Citar el código literal no es un invento.
    if ($variable) {
        $literal = '(?<![\w.])' + [regex]::Escape($variable) + '\s*\.\s*' + [regex]::Escape($miembro) + '\b'
        $dondeLit = @(if ($javaTodo -cmatch $literal) { $fuentes | Where-Object { $_.Nombre -like '*.java' -and $_.Codigo -cmatch $literal } | ForEach-Object Rel })
        if ($dondeLit.Count -gt 0) { Anotar 'OK' 'nombre' "$variable.$miembro" $linea "aparece tal cual en $($dondeLit[0]) ($clase no lo declara: lo hereda, o ahí $variable es de otro tipo)"; return }
    }
    # Heredado solo si la clase de verdad hereda (extends/implements). Si no, está en la clase equivocada.
    $hereda = $resto -cmatch '\b(extends|implements)\b'
    $otros = @(DondeAparece $miembro -Llamada:$esLlamada)
    if ($hereda -and $otros.Count -gt 0) {
        # Heredar de algo no basta: Task implements Comparable y ProjectRepository extends JpaRepository,
        #        pero getOwnerId() o findByStatus() no vienen de ahí. Primero, ¿lo declara un padre DEL PROYECTO?
        $sinGen = $resto
        while ($sinGen -match '<[^<>]*>') { $sinGen = $sinGen -replace '<[^<>]*>', '' }
        foreach ($padre in @([regex]::Matches($sinGen, '(?<![.\w])[A-Z]\w*') | ForEach-Object Value)) {
            $archPadre = @(ArchivosDeClase $padre)
            if ($archPadre.Count -gt 0 -and $padre -cne $clase) {
                $codPadre = (@($fuentes | Where-Object { $archPadre -contains $_.Rel } | ForEach-Object Codigo)) -join "`n"
                if ($codPadre -cmatch $patron) { Anotar 'OK' 'miembro' $nombre $linea "heredado de $padre ($($archPadre[0]))"; return }
            }
        }
        # Después: si otra clase del proyecto lo DECLARA como propio (sin @Override), no es herencia de la librería.
        $declOtros = @(Declaraciones $miembro $esLlamada | Where-Object { $propios -notcontains $_ })
        if ($declOtros.Count -gt 0) {
            Anotar 'NO EXISTE' 'miembro' $nombre $linea "$clase no lo declara y no lo hereda: es propio de $($declOtros[0]) (lo que hereda, $($resto.Trim()), no lo trae)"
            return
        }
        Anotar 'REVISA' 'miembro' $nombre $linea "no está escrito en $($propios[0]), que hereda ($($resto.Trim())); el nombre aparece en $($otros[0])"
    } elseif ($otros.Count -gt 0) {
        Anotar 'NO EXISTE' 'miembro' $nombre $linea "$clase no lo declara ni hereda de nadie; $miembro está en otro archivo, p. ej. $($otros[0])"
    } elseif ($hereda -and (($resto -cmatch '\b(Jpa|Crud|ListCrud|PagingAndSorting|ListPagingAndSorting)Repository\b' -and
                             $miembro -cin 'save', 'saveAll', 'saveAndFlush', 'saveAllAndFlush', 'findById', 'existsById', 'findAll', 'findAllById', 'count', 'deleteById', 'delete', 'deleteAllById', 'deleteAll', 'flush', 'deleteAllInBatch', 'deleteAllByIdInBatch', 'getReferenceById') -or
                            ($resto -cmatch '\bextends\s+(?:\w+\.)*(?:Runtime)?Exception\b' -and
                             $miembro -cin 'getMessage', 'getCause', 'getLocalizedMessage', 'getStackTrace', 'printStackTrace', 'getSuppressed', 'addSuppressed', 'initCause'))) {
        # Métodos que la librería SÍ da aunque el código no los llame (UserRepository.existsById). Lista cerrada:
        #         un findByLoQueSea inventado sigue siendo NO EXISTE, porque las derived queries hay que declararlas.
        Anotar 'REVISA' 'miembro' $nombre $linea "no está escrito en $($propios[0]) y el código no lo llama, pero lo trae lo que hereda ($($resto.Trim()))"
    } else {
        Anotar 'NO EXISTE' 'miembro' $nombre $linea "ni $($propios[0]) ni ningún otro archivo tiene $miembro"
    }
}

# Se recorre con una cola porque algunos candidatos generan otros (eslabones de una cadena, argumentos).
$cola = [System.Collections.Generic.Queue[object]]::new($candidatos)
while ($cola.Count -gt 0) {
    $c = $cola.Dequeue()
    if ($c.Origen -eq 'bloque') { $sinVerificar.Add($c); continue }
    if ($c.Texto.StartsWith('DIR|')) { RevisarCarpeta $c.Texto.Substring(4) $c.Linea; continue }
    if ($c.Texto.StartsWith('BEAN|')) { RevisarBean $c.Texto.Substring(5) $c.Linea; continue }
    if ($c.Texto.StartsWith('MAPPING|')) { $pm = $c.Texto.Split('|', 3); RevisarMapping $pm[1] $pm[2] $c.Linea; continue }
    $t = $c.Texto.Trim().TrimEnd('.', ',', ';', ':')
    if (-not $t) { continue }

    # 5.1 Lo que va dentro de una llamada también se revisa: eslabones (anyRequest().permitAll()), tipos
    #     de los argumentos (createTask(CreateTaskDto)) y el bean de un SpEL (@projectSecurity.esDueno(#id)).
    #     Lo que sale de aquí hereda la fuerza de su origen (entre backticks = fuerte).
    if ($c.Origen -ne 'extra') {
        $extra = [System.Collections.Generic.List[string]]::new()
        foreach ($m in [regex]::Matches($t, '\)\s*\.\s*([A-Za-z_]\w*)\s*\(')) { $extra.Add("$($m.Groups[1].Value)()") }
        $sinCad = $t -replace '"[^"]*"', '""'
        $ip = $sinCad.IndexOf('(')
        if ($ip -ge 0) {
            foreach ($m in [regex]::Matches($sinCad.Substring($ip), '(?<![.\w])[A-Z][A-Za-z0-9_]*[a-z][A-Za-z0-9_]*\b')) { $extra.Add($m.Value) }
            # Llamadas anidadas en los argumentos: TaskMapper.aResponse(taskService.crearYGuardar(request)).
            #         Solo cuando abajo se van a borrar los argumentos; si no, el 5.4 ya ve cada llamada.
            if ($t -match '^[\w.#:$]+\(.*\)$') {
                foreach ($m in [regex]::Matches($sinCad.Substring($ip + 1), '(?<!\w)(?:([A-Za-z_]*[a-z]\w*)\s*\.\s*)?([a-z]\w*)\s*\(')) {
                    if ($m.Groups[2].Value -cmatch '^(if|for|while|switch|catch|return|new|synchronized|super|this)$') { continue }
                    $extra.Add($(if ($m.Groups[1].Success) { "$($m.Groups[1].Value).$($m.Groups[2].Value)()" } else { "$($m.Groups[2].Value)()" }))
                }
            }
        }
        foreach ($m in [regex]::Matches($t, '@([a-z]\w*)\.([A-Za-z_]\w*)\s*\(')) {
            $extra.Add("$($m.Groups[1].Value).$($m.Groups[2].Value)()")
            $extra.Add("BEAN|$($m.Groups[1].Value)")
        }
        # La ruta de un @GetMapping("/tasks/overdue") o @RequestMapping("/api/tasks") y los archivos de
        #         @Sql("/sql/escenario.sql") o classpath:... no se comprobaban: solo el nombre de la anotación.
        foreach ($m in [regex]::Matches($t, '@(Get|Post|Put|Patch|Delete|Request)Mapping\s*\(\s*(?:(?:value|path)\s*=\s*)?\{?\s*"([^"]*)"')) {
            $extra.Add("MAPPING|$($m.Groups[1].Value)|$($m.Groups[2].Value)")
        }
        if ($t.StartsWith('@')) {
            foreach ($m in [regex]::Matches($t, '"(?:classpath\*?:)?(/?[\w./-]+\.(?:sql|ya?ml|properties|json|xml|html|js|css))"')) { $extra.Add($m.Groups[1].Value) }
        }
        foreach ($e in $extra) { Extra $e $c }
    }

    # Los argumentos de una llamada no importan para lo que sigue: TaskService.crear(request, id) -> TaskService.crear()
    if ($t -match '^[\w.#:$]+\(.*\)$') { $t = $t -replace '\(.*\)$', '()' }

    # 5.2 Endpoints, con o sin verbo: POST /projects/{projectId}/tasks, /tasks/{id}, GET /tasks?status=DONE
    # También con la variable de la URL base delante: {{baseUrl}}/tasks/1 (la colección de Postman del repo),
    #        $base/tasks o ${BASE_URL}/tasks. Antes era una «ruta» que no estaba en el disco: NO EXISTE.
    if ($t -cmatch '^(?:(GET|POST|PUT|PATCH|DELETE)\s+)?(?:\{\{\w+\}\}|\$\{\w+\}|\$\w+)?(/[^\s*]*)$' -and $t -notmatch '^/?src/' -and $Matches[2] -notmatch '\.\w+$') {
        $verbo = $Matches[1]; $crudo = $Matches[2] -replace '\?.*$', ''; $ep = NormalizarEndpoint $crudo
        $clave = "endpoint|$verbo $ep"
        if ($vistos.ContainsKey($clave)) { continue }
        $vistos[$clave] = $true
        $mismos = @($endpoints | Where-Object { RutaCoincide $ep $_.Ruta })
        $conVerbo = @($mismos | Where-Object { -not $verbo -or $_.Verbo -eq $verbo -or $_.Verbo -eq '*' })
        if ($conVerbo.Count -gt 0) { Anotar 'OK' 'endpoint' $t $c.Linea "$($conVerbo[0].Verbo) $(if ($conVerbo[0].Ruta -cne $ep) { "$($conVerbo[0].Ruta) " })en $($conVerbo[0].Rel)" }
        elseif ($mismos.Count -gt 0) { Anotar 'NO EXISTE' 'endpoint' $t $c.Linea "esa ruta existe, pero con $((@($mismos.Verbo) | Sort-Object -Unique) -join ', ') ($($mismos[0].Rel))" }
        else {
            $reRuta = ((($crudo -replace '(?<=/):(\w+)', '{$1}').TrimEnd('/') -split '(\{[^}]*\})') | ForEach-Object { if ($_ -like '{*}') { '\{[^}]*\}' } else { [regex]::Escape($_) } }) -join ''
            # Anclada al inicio de la ruta: sin eso, POST /login «salía» dentro de "/auth/login" y GET /users
            #         dentro de "projects/tasks/users", y un endpoint inventado quedaba en REVISA.
            $reTextual = if ($reRuta) { '(?<![\w.~/{}-])' + $reRuta + '(?![\w-])' } else { '["'']/["'']' }
            #         Y la ruta relativa de un @PostMapping("/login") no cuenta: es el FINAL de POST /auth/login.
            $finales = @($endpoints | Where-Object { $_.Ruta.EndsWith($ep) -and $_.Ruta -cne $ep -and (-not $verbo -or $_.Verbo -eq $verbo -or $_.Verbo -eq '*') })
            if ($finales.Count -gt 0) {
                Anotar 'NO EXISTE' 'endpoint' $t $c.Linea "la ruta completa es $($finales[0].Verbo) $($finales[0].Ruta) ($($finales[0].Rel)): le falta el prefijo del @RequestMapping de la clase"
                continue
            }
            $textual = @($fuentes | Where-Object { ($_.Texto -replace '@(Get|Post|Put|Patch|Delete|Request)Mapping\s*\([^)]*\)', ' ') -cmatch $reTextual } | ForEach-Object Rel)
            if ($textual.Count -gt 0) { Anotar 'REVISA' 'endpoint' $t $c.Linea "ningún controller la declara; la ruta sale en $($textual[0]) (¿regla de seguridad, consola, recurso estático?)" }
            else { Anotar 'NO EXISTE' 'endpoint' $t $c.Linea 'ningún @GetMapping/@PostMapping/... de src declara esa ruta, y no sale en ningún archivo' }
        }
        continue
    }

    # 5.3 Esquemas y hosts (localhost:8080/h2-console, jdbc:postgresql://...) no son rutas del repo.
    if ($t -cmatch '^[A-Za-z][A-Za-z0-9+.-]+:(?!:)(?!\d+(-\d+)?$)' -and $t -notmatch '^[A-Za-z]:[\\/]') { $sinVerificar.Add($c); continue }

    # 5.4 Con espacios, URL o comodines: comandos (mvn -q test), cabeceras, patrones (src/test/java/...).
    #     Si parece Java (firma, anotaciones, genérico con espacio) se revisan sus piezas en vez de soltarlo.
    if ($t -match '\s' -or $t -match '^https?:' -or $t -match '\*|\.\.\.|…') {
        $pareceJava = $t -cmatch '^(public|private|protected|static|final|abstract|class|interface|record|enum|new|return|throw)\b' -or
                      $t -match '(^|\s)@[A-Za-z]' -or $t -cmatch '<[A-Z?]' -or $t -match '\w\('
        # Los puntos suspensivos de «@Cacheable(...)» o «new TaskOwnershipException(...)» no son un comodín:
        #         antes mandaban todo a «Sin verificar» y la anotación o la clase inventada no se revisaban.
        if ($pareceJava -and $t -notmatch '\*') {
            $sinCad = ($t -replace '\.\.\.|…', '') -replace '"[^"]*"', '""'
            foreach ($m in [regex]::Matches($sinCad, '@([A-Za-z]\w*)')) { RevisarAnotacion $m.Groups[1].Value $c.Linea }
            foreach ($m in [regex]::Matches(($sinCad -replace '@[A-Za-z]\w*', ' '), '(?<![.\w])[A-Z][A-Za-z0-9_]*[a-z][A-Za-z0-9_]*\b')) { RevisarClase $m.Value $c.Linea (Debilidad $c) }
            # Con su receptor: «return taskService.findAll();» se exige en TaskService (antes: findAll() suelto, OK).
            foreach ($m in [regex]::Matches($sinCad, '(?<!\w)(?:([A-Za-z_]*[a-z]\w*)\s*\.\s*)?([a-z]\w*)\s*\(')) {
                if ($m.Groups[2].Value -cmatch '^(if|for|while|switch|catch|return|new|synchronized|super|this|throw)$') { continue }
                $recv = $m.Groups[1].Value
                Extra $(if ($recv -and $recv -cnotmatch '^(this|super)$') { "$recv.$($m.Groups[2].Value)()" } else { "$($m.Groups[2].Value)()" }) $c
            }
            continue
        }
        if (-not $pareceJava -and $c.Origen -ne 'extra') {
            # «TaskController -> TaskArchiver -> TaskRepository»: cada pieza se revisa (como mención débil).
            $piezas = @($t -split '\s*(?:-->|->|→|=>|⇒)\s*')
            if ($piezas.Count -gt 1 -and @($piezas | Where-Object { -not [regex]::IsMatch($_, '^[\w.#:<>]+(\(\))?$') }).Count -eq 0) {
                foreach ($p in $piezas) { $cola.Enqueue([pscustomobject]@{ Texto = $p; Linea = $c.Linea; Origen = 'cadena' }) }
                continue
            }
            # En un comando («mvn -Dtest=TaskControllerIT test») las clases con sufijo y los archivos sí se revisan.
            $sinUrl = $t -replace '\b[a-zA-Z][\w+.-]*://\S+', ' ' -replace '(?<![\w/.-])(localhost|127\.0\.0\.1)(:\d+)?/\S*', ' '
            #         Sin banderas (-DskipTests no es la clase DskipTests) ni comodines (*IT.java no es IT.java).
            foreach ($m in [regex]::Matches($sinUrl, '(?<![-*])' + $reClaseSufijo)) { Extra $m.Value $c }
            # Con su carpeta: «Get-Content src/main/resources/application-prod.yml» no se revisaba (la barra
            #         bloqueaba el nombre) y «.\target\surefire-reports\TEST-x.xml» se revisaba como TEST-x.xml (NO EXISTE).
            #         Si el primer tramo no es una carpeta del repo (mvn -f taskflow-api/pom.xml, la carpeta del propio repo),
            #         se revisa solo el nombre, como antes: si no, pom.xml salía NO EXISTE.
            foreach ($m in [regex]::Matches($sinUrl, '(?<![\w/\\.@*-])(?:\.{1,2}[\\/])?(?:[\w.-]+[\\/])+[\w.-]+\.(java|ya?ml|xml|properties|sql|json)(?![\w(])|(?<![\w/.@*-])[\w.-]+\.(java|ya?ml|xml|properties|sql|json)(?![\w(])')) {
                $v = $m.Value
                $primero = (($v -replace '\\', '/') -replace '^(\.{1,2}/)+', '').Split('/')[0]
                if ($v -match '[\\/]' -and -not ($carpetas.Contains($primero) -or $primero -in 'target', 'data')) { $v = $v -replace '^.*[\\/]', '' }
                Extra $v $c
            }
        }
        $sinVerificar.Add($c); continue
    }

    # 5.5 Rutas que empiezan por / y no son archivos (las que el 5.2 no tomó, como /auth/**).
    if ($t -match '^/' -and $t -notmatch '^/?src/' -and $t -notmatch '\.\w+$') { $sinVerificar.Add($c); continue }

    # 5.6 Anotaciones: @Valid, @PreAuthorize("..."), @org.springframework.stereotype.Service
    if ($t -match '^@((?:[a-z]\w*\.)*)([A-Za-z]\w*)') { RevisarAnotacion $Matches[2] $c.Linea; continue }

    # 5.7 Archivo real sin extensión conocida (Dockerfile, .gitattributes).
    if ($t -notmatch '[\\/]' -and $porNombre.ContainsKey($t) -and $t -notmatch '\.java$') {
        $clave = "ruta|$t"
        if (-not $vistos.ContainsKey($clave)) { $vistos[$clave] = $true; Anotar 'OK' 'ruta' $t $c.Linea $porNombre[$t][0] }
        continue
    }

    # 5.8 Nombre completo de un miembro del proyecto: com.taskflow.service.TaskService.crear
    #     También con # (estilo Javadoc): com.taskflow.service.JpaUserDetailsService#loadUserByUsername
    if ($t -cmatch '^com\.taskflow\.(?:[a-z_]\w*\.)*([A-Z]\w*)[.#]([A-Za-z_]\w*)(\(\))?$') {
        RevisarMiembro $Matches[1] $Matches[2] ([bool]$Matches[3]) $c.Linea; continue
    }

    # 5.9 Paquete o nombre completo de una clase del proyecto: com.taskflow.service, com.taskflow.model.Task
    if ($t -match '^com\.taskflow(\.[A-Za-z_]\w*)*$') {
        $partes = $t.Split('.')
        $ruta = ($partes -join '/') + $(if ($partes[-1] -cmatch $pascal) { '.java' } else { '' })
        $clave = "ruta|$ruta"
        if ($vistos.ContainsKey($clave)) { continue }
        $vistos[$clave] = $true
        $enc = BuscarRuta $ruta $false
        if ($enc -and $enc.Ruta) { Anotar 'OK' 'paquete' $t $c.Linea ($enc.Ruta -replace '/', '\') } else { Anotar 'NO EXISTE' 'paquete' $t $c.Linea "no hay $ruta en src" }
        continue
    }

    # 5.10 Nombre completo de otra librería: org.springframework.security.web.SecurityFilterChain
    if ($t -cmatch '^[a-z]\w*(\.[a-z_]\w*)+\.([A-Z]\w*)$') {
        $simple = $Matches[2]
        $clave = "fqn|$t"
        if ($vistos.ContainsKey($clave)) { continue }
        $vistos[$clave] = $true
        if (@(DondeAparece $t).Count -gt 0) { Anotar 'EXTERNA' 'clase' $t $c.Linea "el código la importa o la nombra: $(@(DondeAparece $t)[0])" }
        elseif (@(DondeAparece $simple).Count -gt 0) { Anotar 'REVISA' 'clase' $t $c.Linea "el código usa $simple, pero no con ese paquete" }
        elseif (@(DondeAparece $t -Crudo).Count -gt 0) { Anotar 'REVISA' 'clase' $t $c.Linea 'solo sale en comentarios o textos' }
        else { Anotar 'NO EXISTE' 'clase' $t $c.Linea 'ni ese nombre completo ni la clase salen en src ni en pom.xml' }
        continue
    }

    # 5.11 Rutas y archivos: llevan / o \, o terminan en una extensión conocida (pom.xml, Task.java).
    if ($t -match '[\\/]' -or $t -match '^[\w.-]+\.(java|ya?ml|xml|properties|sql|html|js|css|json|md|ps1)([#:?].*)?$') {
        # «ana/ana123», «TODO/IN_PROGRESS/DONE», «TaskRequest/TaskResponse», «H2/PostgreSQL» no son rutas:
        #         sin punto, sin barra al inicio o al final, y ningún tramo se llama como una carpeta del repo
        #         (domain/model sigue siendo ruta: model existe; y si no está en el disco, NO EXISTE).
        if ($c.Origen -notin 'enlace', 'cadena' -and [regex]::IsMatch($t, '^[\w-]+(/[\w-]+)+$') -and
            @($t.Split('/') | Where-Object { $carpetas.Contains($_) }).Count -eq 0) {
            foreach ($p in $t.Split('/')) { $cola.Enqueue([pscustomobject]@{ Texto = $p; Linea = $c.Linea; Origen = 'cadena' }) }
            continue
        }
        # «Node.js», «Vue.js»: nombres de tecnologías, no archivos (salía NO EXISTE en «no necesita Node.js»).
        #         Lista CERRADA a propósito: lo que no esté aquí se sigue buscando en el disco.
        #         Solo si NO está en el disco (un static/js/Chart.js real sigue saliendo OK).
        $tecnologia = $c.Origen -ne 'enlace' -and $t -cmatch '^(Node|Vue|React|Angular|Next|Nuxt|Nest|Express|Alpine|Chart|Three|Ember|Backbone|Deno|Moment|Day|Socket|Ext|Knockout|Svelte|Solid|Preact|Handlebars|Mustache)\.js$'
        $clave = "ruta|$($t -replace '\\', '/')"
        if ($vistos.ContainsKey($clave)) { continue }
        $vistos[$clave] = $true
        $enc = BuscarRuta $t ($c.Origen -eq 'enlace')
        if ($enc -and $enc.Ruta) { Anotar 'OK' 'ruta' $t $c.Linea ($enc.Ruta -replace '/', '\') }
        elseif ($tecnologia) { if ($c.Origen -ne 'enbloque') { $sinVerificar.Add($c) } }
        elseif ($enc -and $enc.Mayus) { Anotar 'NO EXISTE' 'ruta' $t $c.Linea "en el disco se escribe $($enc.Mayus -replace '/', '\') (Java y Git distinguen mayúsculas)" }
        elseif (($web = @(RutaWeb $t)).Count -gt 0) {
            # Una dirección web con archivo (/swagger-ui/index.html): no está en el repo, pero la configuración
            # de src/main nombra esa ruta ("/swagger-ui/**"): la sirve Spring o una librería.
            Anotar 'REVISA' 'ruta' $t $c.Linea "no es un archivo del repo, pero la ruta sale en $($web[0]) (¿página que sirve una librería?)"
        }
        elseif (($gen = [regex]::Match(($t -replace '\\', '/'), '^(?:\./)?(target|data)/')).Success -and
                (($gen.Groups[1].Value -eq 'target' -and $rutasRepo.Contains('pom.xml')) -or
                 ($gen.Groups[1].Value -eq 'data' -and @($fuentes | Where-Object { $_.Rel -match '^src[\\/]main[\\/]' -and $_.Codigo -cmatch '(?<![\w-])data/' }).Count -gt 0))) {
            # target\ (Maven) y data\ (H2 en archivo) no se indexan: no es que no exista, es que no se mira.
            Anotar 'REVISA' 'ruta' $t $c.Linea "está en $($gen.Groups[1].Value)\, que $(if ($gen.Groups[1].Value -eq 'target') { 'genera Maven al compilar' } else { 'crea H2 al arrancar (application.yml)' }): el script no revisa esa carpeta"
        }
        else { Anotar 'NO EXISTE' 'ruta' $t $c.Linea 'no está en el disco' }
        continue
    }

    # 5.12 Clase.miembro: Task.estaVencida(), ReportService.SIN_ASIGNAR, Clase#metodo, Clase::metodo, Clase$Anidada.
    if ($t -cmatch '^([A-Z][A-Za-z0-9_]*)(\.|#|::|\$)([A-Za-z_]\w*)(\(\))?$') {
        RevisarMiembro $Matches[1] $Matches[3] ([bool]$Matches[4]) $c.Linea
        continue
    }

    # 5.13 Clase sola o dentro de un genérico: TaskController, List<TaskResponse>, ResponseEntity<Void>.
    if ($t -match '^[A-Za-z0-9_<>,\[\]?]+$' -and $t -cmatch '[A-Z]') {
        $clases = @([regex]::Matches($t, '[A-Za-z_]\w*') | ForEach-Object Value | Where-Object { $_ -cmatch $pascal })
        if ($clases.Count -gt 0) { foreach ($cl in $clases) { RevisarClase $cl $c.Linea (Debilidad $c) }; continue }
    }
    # Genérico seguido de llamada: Optional<TaskDto>.orElseThrow()
    if ($t -cmatch '^[A-Za-z0-9_<>,\[\]?]+>\.([a-z]\w*)\(\)$') {
        # Se guarda YA: el Where-Object de abajo hace -cmatch y pisa $Matches; el método encolado quedaba
        #         en «()» y se descartaba, así que Optional<Task>.orElseThrowInventado() no se revisaba.
        $metodoGen = $Matches[1]
        foreach ($cl in @([regex]::Matches($t.Substring(0, $t.LastIndexOf('>') + 1), '[A-Za-z_]\w*') | ForEach-Object Value | Where-Object { $_ -cmatch $pascal })) { RevisarClase $cl $c.Linea (Debilidad $c) }
        Extra "$metodoGen()" $c
        continue
    }

    # 5.14 variable.metodo(): si la variable nombra una clase del proyecto (taskService -> TaskService),
    #      el método se exige en ESA clase.
    if ($t -cmatch '^([a-z]\w*)\.([A-Za-z_]\w*)(\(\))?$') {
        $var = $Matches[1]; $mm = $Matches[2]; $ll = [bool]$Matches[3]
        $cap = $var.Substring(0, 1).ToUpper() + $var.Substring(1)
        if (@(ArchivosDeClase $cap).Count -gt 0) { RevisarMiembro $cap $mm $ll $c.Linea $var; continue }
    }
    # 5.15 Métodos o campos sueltos: estaVencida(), vencidas(), isTokenValid, dueDate. Una palabra suelta en
    #      minúsculas y sin paréntesis (role, sub, test) no se revisa: sería ruido.
    $miembro = if ($t -cmatch '^(?:[a-z]\w*\.)?([A-Za-z_]\w*)(\(\))?$') { $Matches[1] } else { $null }
    if ($miembro -and ($t.EndsWith('()') -or ($t -notmatch '\.' -and $miembro -cmatch '^[a-z].*[A-Z]'))) {
        $esLlamada = $t.EndsWith('()')
        $clave = "suelto|$t"
        if ($vistos.ContainsKey($clave)) { continue }
        $vistos[$clave] = $true
        $donde = @(DondeAparece $miembro -Llamada:$esLlamada)
        if ($donde.Count -gt 0) { Anotar 'OK' 'nombre' $t $c.Linea "aparece en $($donde.Count) archivo(s), p. ej. $($donde[0])" }
        elseif (($enCad = @(DondeAparece $miembro -Llamada:$esLlamada -Cadenas)).Count -gt 0) {
            # hasRole('ADMIN') y @projectSecurity solo están dentro de "@PreAuthorize(...)": código que Spring evalúa.
            Anotar 'OK' 'nombre' $t $c.Linea "aparece dentro de una cadena del código (p. ej. una expresión de @PreAuthorize o @Value) en $($enCad[0])"
        }
        else { Anotar 'NO EXISTE' 'nombre' $t $c.Linea 'no aparece en ningún archivo de src' }
        continue
    }

    # 5.16 Todo lo demás (DONE, 401, HS256, Bearer <token>...): se declara, no se descarta. Lo que salió del
    #      texto normal o de un bloque y no se pudo clasificar no se lista: sería ruido de palabras comunes.
    if ($c.Origen -in 'prosa', 'enbloque', 'arbol' -or ($c.Origen -eq 'extra' -and ($c.Debil -or $t -notmatch '\w'))) { continue }
    $sinVerificar.Add($c)
}

# =============================================================================================
# 6. Informe. Todo va por Write-Output para que Tee-Object lo pueda guardar en un archivo.
# =============================================================================================
Write-Output "Verificando $(Relativa $rutaMd) contra $Repo"
Write-Output ''
foreach ($r in $resultados) {
    Write-Output ('{0,-12} línea {1,-4} {2,-9} {3}  ->  {4}' -f "[$($r.Estado)]", $r.Linea, $r.Tipo, $r.Nombre, $r.Detalle)
}

$unicosSin = @($sinVerificar | Group-Object { $_.Texto.Trim() } -CaseSensitive | ForEach-Object { "``$($_.Name)`` (l. $($_.Group[0].Linea))" })
if ($unicosSin.Count -gt 0) {
    Write-Output ''
    Write-Output "Sin verificar ($($unicosSin.Count)): el script no sabe comprobarlos; léelos tú:"
    Write-Output ('  ' + ($unicosSin -join ', '))
}

foreach ($a in $avisos) { Write-Output ''; Write-Output "AVISO: $a" }

$noExiste = @($resultados | Where-Object Estado -eq 'NO EXISTE')
if ($noExiste.Count -gt 0) {
    Write-Output ''
    Write-Output 'Lo que NO EXISTE (corrígelo con el agente):'
    foreach ($r in $noExiste) { Write-Output "  línea $($r.Linea): $($r.Nombre)" }
}

$cuenta = { param($e) @($resultados | Where-Object Estado -eq $e).Count }
Write-Output ''
Write-Output ("Resumen: {0} OK · {1} REVISA · {2} EXTERNA · {3} NO EXISTE · {4} sin verificar" -f `
    (& $cuenta 'OK'), (& $cuenta 'REVISA'), (& $cuenta 'EXTERNA'), $noExiste.Count, $unicosSin.Count)

# Un documento vacío, sin nada comprobable o con un bloque sin cerrar NO se da por bueno.
if ($noExiste.Count -gt 0) { exit 1 }
if ($resultados.Count -eq 0) { Write-Output ''; Write-Output 'NO SE DA POR BUENO: no encontré ningún nombre que comprobar (¿documento vacío o sin backticks?).'; exit 3 }
if ($cerca) { Write-Output ''; Write-Output 'NO SE DA POR BUENO: hay un bloque de código sin cerrar (ver AVISO).'; exit 3 }
exit 0
