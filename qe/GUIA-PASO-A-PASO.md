# Guía paso a paso — los tres días de QE

**Miércoles 9, jueves 10 y viernes 11 de septiembre.** Automatización de pruebas con Selenium
sobre TaskFlow.

Esta guía es para **seguirla mientras trabajas**, un paso cada vez. No hace falta que sepas nada de
Selenium ni de Maven: cada paso te dice qué vas a hacer, qué escribir, y **qué tiene que salir en
pantalla si funcionó**.

> Si buscas sólo los comandos, sin explicaciones, están en
> **[`COMO-TRABAJAS.md`](COMO-TRABAJAS.md)**. Esta guía usa exactamente esos mismos comandos.

---

## Cómo leer esta guía

Cada paso tiene siempre las mismas cuatro partes:

> **Qué vas a hacer** — para qué sirve el paso, en una frase.
> **Escribe esto** — el comando exacto. Cópialo tal cual.
> **✅ Qué debes ver** — cómo se ve el éxito. Si ves esto, sigue al paso siguiente.
> **❌ Si ves otra cosa** — qué significa y cómo se arregla.

Y los tres ambientes van **siempre** marcados:

| | |
|---|---|
| 🪟 | **Windows** |
| 🍎 | **macOS** |
| 🐧 | **Linux** — probado en Ubuntu 24.04 y 22.04. En otras distribuciones cambia el gestor de paquetes (`dnf`, `pacman`), no los comandos del curso |

Cuando un paso no lleva marca, es porque **es idéntico en los tres**.

Los números que salen en pantalla —segundos, cantidad de objetos, el código de un commit— cambian
de una computadora a otra. Cuando esta guía muestra uno, es **un ejemplo**; lo que tiene que
coincidir es el texto que lo rodea.

---

## 📅 Qué se hace cuándo

| Cuándo | Pasos | Qué se entrega |
|---|---|---|
| **Lunes 7 o martes 8, en casa** | **0 a 8** — es el prework | Tarea **🔧 Comprobación de ambiente y repositorio — antes del miércoles** (Semana 5). Cierra el **martes 8, 23:59** |
| **Miércoles 9** | 9 y 10 | — |
| **Jueves 10** | 11 y 12 | — |
| **Viernes 11** | 13 y 14 | **Integrador Semana 5**. Cierra el **viernes 11, 17:00** |

Los pasos 1 a 8 **se hacen antes del miércoles** por dos razones: crear tu repositorio en GitHub
(Paso 5) es lo que más se atasca, y las descargas son unos 320 MB —en tu casa caben; veinte personas
a la vez en el wifi del aula, no—. Si llegas el miércoles sin haberlos hecho, hazlos entonces **y
avisa al instructor**.

---

## Paso 0 · Comprueba tu computadora (lunes o martes)

**Qué vas a hacer:** ejecutar un comprobador que mira si tienes lo que hace falta — **JDK 21**,
**Maven 3.9.x**, **Git** y **Google Chrome**— y te dice qué falta. No instala ni cambia nada.

Abre tu terminal (🪟 **Git Bash** · 🍎 **Terminal** · 🐧 **Terminal** — el Paso 1 explica cuál es cuál)
y **escribe esto**, que es igual en los tres ambientes:

```bash
curl -fsSL -o comprobar-ambiente.sh https://raw.githubusercontent.com/cursosmrugerio/academyMty/main/qe/comprobar-ambiente.sh
bash comprobar-ambiente.sh
```

**✅ Qué debes ver:** una lista de líneas `[ OK ]` y, tres líneas antes del final, ésta:

```
  RESULTADO: LISTO PARA EL MIERCOLES
```

Guarda toda la salida: es la primera de las dos cosas que se entregan el martes (ver después del Paso 8).

**❌ Si alguna línea dice `[FALTA]`:** te falta esa pieza. Se instala con la **Guía de ambiente —
Día 0** de Moodle (curso → sección **Recursos**): cada línea `[FALTA]` te dice el capítulo. Un
resumen de lo que más falta:

| Falta | 🪟 Windows | 🍎 macOS | 🐧 Linux (Ubuntu / Debian) |
|---|---|---|---|
| JDK 21 | instalador de [adoptium.net](https://adoptium.net) (Temurin 21) | `brew install --cask temurin@21` | repo de Adoptium — **ver abajo** |
| Maven 3.9.x | `.zip` de maven.apache.org y `bin\` al PATH (Día 0, cap. 3) | `brew install maven` | **no uses `apt install maven`** — ver abajo |
| Git | git-scm.com | `git --version` lo instala si no está | `sudo apt install git` |
| Google Chrome | google.com/chrome | google.com/chrome | el `.deb` de google.com/chrome — ver abajo |

🐧 **Linux, en detalle** (medido en Ubuntu 24.04 y 22.04):

- **JDK 21.** El Día 0 dice «el paquete `temurin-21-jdk` del repo de Adoptium». Son estos cuatro
  comandos —los de adoptium.net → *Installation* → Linux—:

  ```bash
  sudo apt install -y wget apt-transport-https gpg
  wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/adoptium.gpg
  echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
  sudo apt update && sudo apt install -y temurin-21-jdk
  ```

  No hace falta definir `JAVA_HOME`: `mvn` encuentra este JDK solo.

- **Maven: el de `apt` no sirve.** Ubuntu 24.04 instala Maven **3.8.7** y Ubuntu 22.04 Maven
  **3.6.3**, y con los dos el proyecto del curso falla al compilar con
  `Source option 5 is no longer supported`. Instálalo como en Windows —descomprimir y poner `bin/`
  en el PATH—:

  ```bash
  cd ~
  curl -fsSL -o maven.tar.gz https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz
  tar -xzf maven.tar.gz && rm maven.tar.gz
  echo 'export PATH=$HOME/apache-maven-3.9.16/bin:$PATH' >> ~/.bashrc
  ```

  Cierra la terminal y abre otra: `mvn -version` tiene que decir `Apache Maven 3.9.16`. Si ya tenías
  el de `apt`, no hace falta quitarlo: el tuyo va antes en el PATH y gana. *(Si usas `zsh`, la
  línea va en `~/.zshrc`.)*

- **Google Chrome.** Sólo existe para **x86_64**. Descarga el `.deb` e instálalo con `apt`, que
  resuelve solo sus dependencias:

  ```bash
  cd ~
  curl -fsSL -o google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y ./google-chrome-stable_current_amd64.deb
  ```

- **Si `uname -m` dice `aarch64`** (Raspberry Pi, Mac con Asahi, Chromebook ARM): no hay Google
  Chrome para esa arquitectura y Selenium tampoco encuentra un `chromedriver` que funcione ahí
  (comprobado: descarga el de x86_64 y muere con código 133). **Avisa al instructor antes del
  miércoles.**

**❌ Si dice `curl: no se reconoce como un comando` o `bash: no se reconoce`:** 🪟 estás en
PowerShell o en el Símbolo del sistema. Ve al Paso 1.

**❌ 🐧 Si dice `curl: command not found`:** `sudo apt install curl`, y repite.

**❌ 🐧 Si al instalar Chrome `apt` dice `pkgProblemResolver::Resolve generated breaks` y nombra a
`libasound2`:** le falta la librería de audio, que un escritorio normal ya trae. Escribe
`sudo apt install -y libasound2t64` y repite el `sudo apt install ./google-chrome-stable_current_amd64.deb`.

---

# 🗓️ ANTES DEL MIÉRCOLES — pasos 1 a 8 (el prework del martes)

Con esto montas tu proyecto, lo publicas en GitHub, arrancas la aplicación que vas a probar y dejas
hechas las descargas. **El miércoles la clase empieza en el Paso 9**, con esto ya hecho.

---

## Paso 1 · Abre la terminal correcta

**Qué vas a hacer:** abrir el programa donde vas a escribir todos los comandos de los tres días.
Elegir el equivocado es el motivo número uno por el que un comando "no funciona".

🪟 **Windows — abre Git Bash.** *No PowerShell. No Símbolo del sistema.*
Menú Inicio → escribe `Git Bash` → Enter.
*(Ya lo tienes: viene dentro de Git for Windows.)*

🍎 **macOS — abre Terminal.** Cmd + Espacio → escribe `Terminal` → Enter.

🐧 **Linux — abre Terminal.** Ctrl + Alt + T en Ubuntu y en la mayoría de los escritorios, o
búscala como `Terminal` en el menú de aplicaciones. Sirve cualquiera: lo que importa es que dentro
corra `bash` o `zsh`, y eso lo traen todas las distribuciones.

**Escribe esto** para comprobar que estás donde toca:

```bash
uname -s
```

**✅ Qué debes ver**

| | Sale esto |
|---|---|
| 🪟 Git Bash | `MINGW64_NT-10.0-26200` — el número cambia según tu Windows |
| 🍎 macOS | `Darwin` |
| 🐧 Linux | `Linux` |

**❌ Si ves esto:**

```
El término 'uname' no se reconoce como nombre de un cmdlet, función,
archivo de script o programa ejecutable.
```

Estás en **PowerShell**. Y si ves `"uname" no se reconoce como un comando interno o externo`,
estás en el **Símbolo del sistema**. En los dos casos: ciérralo y abre **Git Bash**. No sigas: los
comandos de esta guía no funcionan ahí, y algunos **fallan sin avisar**.

---

## Paso 2 · Descarga el material del curso

**Qué vas a hacer:** traerte a tu computadora el repositorio del curso. De aquí **sólo vas a
leer**: tu trabajo va en otro sitio.

**Escribe esto:**

```bash
cd ~
git clone https://github.com/cursosmrugerio/academyMty.git
```

**✅ Qué debes ver** (entre 5 y 10 segundos). Termina así —los números cambian cada semana—:

```
Cloning into 'academyMty'...
remote: Enumerating objects: 1648, done.
...
Receiving objects: 100% (1648/1648), 17.50 MiB | 9.17 MiB/s, done.
Resolving deltas: 100% (478/478), done.
```

🪟 En Windows sale además una última línea `Updating files: 100% (730/730), done.` En 🍎 y 🐧 no
sale, y es normal.

**❌ Si dice `fatal: destination path 'academyMty' already exists`:** ya lo tenías descargado. No
pasa nada, pero actualízalo:

```bash
cd ~/academyMty && git pull && cd ~
```

---

## Paso 3 · Crea TU proyecto

**Qué vas a hacer:** copiar el andamiaje del miércoles a una carpeta **tuya**. Ese es el proyecto
que crece los tres días y el que entregas al final de la semana.

> ⚠️ Cambia `<tu-usuario>` por tu usuario de GitHub, **sin los símbolos `<` `>`**.
> Si tu usuario es `anagarcia`, la carpeta se llama `taskflow-qa-anagarcia`.

**Escribe esto:**

```bash
cp -R academyMty/qe/dia-1/taskflow-qa taskflow-qa-<tu-usuario>
cd taskflow-qa-<tu-usuario>
ls src/test/java/com/taskflow/qa/tests/
```

**✅ Qué debes ver:** dos nombres, y nada más.

```
LocalizacionTest.java  SmokeTest.java
```

**❌ 🪟 Si dice `"cp" no se reconoce como un comando interno o externo`:** estás en el Símbolo del
sistema. Vuelve al **Paso 1**.

**❌ 🪟 Si en vez de dos nombres sale una tabla con `Directorio:`, `Mode` y `LastWriteTime`:** estás
en PowerShell, donde `cp` y `ls` existen pero se comportan distinto — y los comandos del jueves y
del viernes ahí **no funcionan**. Vuelve al **Paso 1**.

---

## Paso 4 · Conviértelo en un repositorio de git

**Qué vas a hacer:** empezar a llevar historial de tu trabajo. Sin esto no puedes entregar.

**Escribe esto:**

```bash
git init -b main
git add -A
git commit -m "Andamiaje del miercoles"
```

**✅ Qué debes ver:**

```
[main (root-commit) 0e5afb5] Andamiaje del miercoles
 6 files changed, 315 insertions(+)
```

El código de siete letras es distinto en cada computadora. Lo que importa es **`6 files changed`**:
el `pom.xml`, el `README.md`, los tres `.java` y un `.gitignore` que deja fuera `target/` y los
archivos de tu editor.

**❌ Si dice `Please tell me who you are`:** git no sabe tu nombre todavía. Ponlo una sola vez —
sirve para siempre — y repite el `git commit`:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@correo.com"
```

**❌ 🐧 Si dice `error: unknown switch 'b'`:** tu git es anterior a 2.28 (pasa en Ubuntu 20.04).
Escribe `git init` y después `git branch -M main`, y sigue con el `git add`.

---

## Paso 5 · Crea tu repositorio en GitHub y súbelo

**Qué vas a hacer:** publicar tu proyecto. **Éste es el paso que más suele atascarse**, y no por
tu culpa: depende de tu cuenta, de la verificación en dos pasos y de los permisos. Por eso se hace
en casa. Si se complica, avisa en el canal de atascos y sigue con el Paso 6 mientras tanto.

1. Entra a **github.com** → botón **New** (repositorio nuevo).
2. Nombre: **`taskflow-qa-<tu-usuario>`**, el mismo que tu carpeta.
3. **Déjalo vacío**: sin README, sin `.gitignore`, sin licencia.
4. Botón **Create repository**.

🐧 **Linux — el token no se guarda solo.** En Windows lo guarda Git Credential Manager y en macOS
el Keychain; en Linux git no trae nada, y te va a pedir usuario y token **en cada push**. Para que
lo recuerde, una sola vez, antes del primer push:

```bash
git config --global credential.helper store
```

*(Lo guarda en texto plano en `~/.git-credentials`. Si compartes la computadora, usa
`'cache --timeout=28800'` en vez de `store`: lo recuerda ocho horas y lo olvida.)*

**Escribe esto** (con tu usuario en los dos sitios):

```bash
git remote add origin https://github.com/<tu-usuario>/taskflow-qa-<tu-usuario>.git
git push -u origin main
```

**✅ Qué debes ver:** una línea que acaba en `branch 'main' set up to track 'origin/main'`. Y si
recargas la página de GitHub, ahí están tus archivos.

**❌ Si te pide usuario y contraseña y la rechaza:** GitHub ya no acepta la contraseña de la
cuenta. Hay que usar un **token** (PAT). Está explicado en el capítulo *Git + cuenta de GitHub* de
la Guía de ambiente — Día 0, en Moodle.

**❌ Si dice `remote: Repository not found`:** la URL no coincide con el repositorio que creaste
—revisa los dos `<tu-usuario>`— o todavía no lo has creado. Corrígela con
`git remote set-url origin https://github.com/<tu-usuario>/taskflow-qa-<tu-usuario>.git` y repite el push.

---

## Paso 6 · Arranca TaskFlow (la aplicación que vas a probar)

**Qué vas a hacer:** poner en marcha la web contra la que van a correr tus tests.

> 🔴 **Importante: abre una SEGUNDA terminal para esto.**
> Este comando **no termina nunca** — se queda ocupando la ventana mientras la aplicación está
> encendida. Si lo lanzas en la terminal donde estás trabajando, te quedas sin ella.
> Deja esta segunda terminal abierta y olvídate: es tu "servidor".

Cómo abrir la segunda: 🪟 Menú Inicio → Git Bash otra vez (otra ventana) · 🍎 Cmd + T (otra pestaña
de Terminal) · 🐧 Ctrl + Shift + T (otra pestaña) o Ctrl + Alt + T (otra ventana).

En esa **segunda** terminal:

```bash
cd ~/academyMty/taskflow-api
mvn spring-boot:run -Dspring-boot.run.profiles=h2
```

**✅ Qué debes ver** — la primera vez tarda **un minuto y medio** porque se descarga medio internet;
las siguientes, unos 15 segundos. Al final:

```
Tomcat started on port 8080 (http) with context path '/'
Started TaskflowApiApplication in 7.9 seconds
```

Los segundos varían (1.5 en una laptop rápida, 8 en otra). Y ahí se queda. **Es correcto que no
vuelva el cursor.**

**❌ Si dice `Port 8080 was already in use`:** tienes otra cosa ocupando ese puerto. Ciérrala, o
arranca TaskFlow en otro puerto (ver *Cuando algo se rompe*, al final).

**❌ Si en esta terminal empiezan a salir bloques de SQL que empiezan por `Hibernate: create table`:**
arrancaste **sin el perfil `h2`** (sin él salen 23 bloques así; con él, ninguno). La aplicación
funciona igual, pero guarda los datos en un archivo dentro de `taskflow-api/data/` y **no se limpia
al reiniciar**, y en el curso queremos que sí se limpie. Pulsa Ctrl + C y repite el comando completo,
incluida la parte `-Dspring-boot.run.profiles=h2`.

---

## Paso 7 · Compruébalo con tus ojos

**Qué vas a hacer:** ver la aplicación funcionando antes de automatizar nada. **Nunca automatices
algo que no has visto a mano.**

1. Abre **Google Chrome**.
2. Ve a **http://localhost:8080/**

**✅ Qué debes ver:** la pantalla de **inicio de sesión de TaskFlow**. Entra con:

| Usuario | Contraseña |
|---|---|
| `ana` | `ana123` |

Y fíjate en el **título de la pestaña** de Chrome: lo vas a necesitar en el Paso 9.

**❌ Si Chrome dice «No se puede acceder a este sitio web» y abajo `ERR_CONNECTION_REFUSED`:** TaskFlow no
está arriba. Mira la segunda terminal: o sigue arrancando —espera a `Started TaskflowApiApplication`—
o se murió con un error; léelo, casi siempre es el puerto 8080 ocupado (Paso 6).

---

## Paso 8 · Lanza los tests por primera vez

**Qué vas a hacer:** comprobar que Maven, Java y el proyecto se entienden. De paso se descargan las
librerías de Selenium (unos 40 MB), y eso conviene tenerlo hecho antes de empezar a escribir.

Vuelve a **tu primera terminal** (la del proyecto, no la del servidor):

```bash
cd ~/taskflow-qa-<tu-usuario>
mvn test
```

**✅ Qué debes ver** (entre 25 y 35 segundos la primera vez):

```
Tests run: 11, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

> ⚠️ **Ojo con este verde: no significa lo que parece.**
> Los 11 tests **están vacíos** — sólo tienen comentarios `// TODO`, porque escribirlos es tu
> trabajo del miércoles. Pasan porque no hacen nada.
> **Chrome todavía no se ha abierto ni una vez.** Eso ocurre en el paso siguiente.

**❌ Si dice `mvn: command not found`:** Maven no está instalado, o está sólo dentro de IntelliJ
(que aquí no cuenta). Capítulo *Maven* de la Guía de ambiente — Día 0, o 🐧 el bloque de Linux del
Paso 0.

**❌ 🐧 Si dice `Source option 5 is no longer supported`:** tu Maven es el de `apt` (3.8 o 3.6).
Instala el 3.9.16 como dice el Paso 0 y abre una terminal nueva.

---

### 📬 Lo que entregas el martes

En la tarea **🔧 Comprobación de ambiente y repositorio — antes del miércoles** (sección Semana 5 de
Moodle), en «Texto en línea», **dos cosas**:

1. La salida completa del comprobador del **Paso 0**, copiada tal cual.
2. El enlace a tu repositorio del **Paso 5**, del estilo `https://github.com/tu-usuario/taskflow-qa-tu-usuario`.

**Cierra el martes 8 a las 23:59.** Si algo no te salió, entrega igual lo que tengas y di dónde te
atascaste: eso es lo que hace falta saber el martes por la noche, cuando todavía da tiempo a
resolverlo.

---

# 🗓️ MIÉRCOLES — día 1 de QE

Hoy escribes tu primer test de verdad y resuelves los ocho objetivos de localización. Antes de
nada: la terminal correcta (Paso 1), situada en tu proyecto, y TaskFlow arriba en la segunda
terminal (Paso 6) — hoy tarda unos 15 segundos, no un minuto y medio.

---

## Paso 9 · Tu primer test de verdad — que Chrome se abra

**Qué vas a hacer:** resolver los tres primeros `TODO` de `SmokeTest.java`. **Éste es el paso que
de verdad valida tu ambiente**, porque es el primero que abre un navegador.

Abre el proyecto en tu editor. En **IntelliJ**: File → Open → la carpeta `taskflow-qa-<tu-usuario>`
→ Open, acepta el aviso de confianza (*Trust Project*) y espera a que termine de indexar (la barra
de abajo). Después abre `src/test/java/com/taskflow/qa/tests/SmokeTest.java` y completa:

- **TODO 1** — crear el driver de Chrome: `driver = new ChromeDriver();`
  **Y arriba, junto a los otros `import`:** `import org.openqa.selenium.chrome.ChromeDriver;`
  Sin esa línea no compila (`cannot find symbol`). IntelliJ la añade sola si aceptas su sugerencia
  (Alt + Enter sobre `ChromeDriver`).
  *(No hace falta `System.setProperty` ni WebDriverManager: Selenium Manager resuelve el driver solo.)*
- **TODO 2** — cerrarlo: `if (driver != null) driver.quit();`
- **TODO 3** — `driver.get(Paginas.LOGIN);` y después `assertEquals("...", driver.getTitle());` con
  el título que viste en la pestaña de Chrome en el Paso 7. **No es «TaskFlow»**: míralo antes de
  escribirlo.

**Escribe esto** (con TaskFlow arrancado en la otra terminal):

```bash
mvn test -Dtest=SmokeTest
```

**✅ Qué debes ver:** una ventana de **Chrome que se abre sola**, carga TaskFlow, y se cierra. Y en
la terminal:

```
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

La primera vez tarda entre 10 y 15 segundos: Selenium descarga solo el `chromedriver` (unos 22 MB)
y lo deja en 🪟 `C:\Users\<tú>\.cache\selenium\chromedriver\win64\` · 🍎 `~/.cache/selenium/chromedriver/mac-arm64/`
· 🐧 `~/.cache/selenium/chromedriver/linux64/`. **No lo instales a mano.**

> 🪟 **Windows — la primera vez saldrá esta ventana:**
>
> ```
> Seguridad de Windows
> ¿Quieres permitir que las redes públicas y privadas accedan a esta aplicación?
> Firewall de Windows bloqueó algunas características de OpenJDK Platform binary
> ```
>
> Es normal. Pulsa **Permitir acceso**. Y si no la pulsas, tampoco pasa nada: se cierra sola y los
> tests funcionan igual. **Sólo aparece una vez.**

> 🍎 🐧 **macOS y Linux:** normalmente no sale nada. Si macOS pregunta si `java` puede aceptar
> conexiones entrantes, es su firewall, que viene apagado pero puede estar encendido: pulsa **Permitir**.

> **Vas a ver también una ADVERTENCIA amarilla:**
> `ADVERTENCIA: Unable to find CDP implementation matching 152`
> Ese número es **tu versión de Chrome**, y si tu sistema está en inglés la línea empieza por
> `WARNING:`. **No es un error** y no afecta a nada de este curso.

**❌ Si dice `cannot find symbol` señalando `ChromeDriver`:** falta el `import` del TODO 1.

**❌ Si dice `SessionNotCreatedException` o `Could not start a new session`:** Chrome no arrancó.
Comprueba que Google Chrome abre a mano (Paso 7). 🐧 Si `uname -m` dice `aarch64`, es lo esperado:
ver Paso 0.

---

## Paso 10 · Los ocho objetivos del día

**Qué vas a hacer:** el ejercicio de verdad del miércoles. Ya tienes el camino abierto; ahora
`LocalizacionTest.java`, ocho localizadores, cada uno con su test en verde. Y al terminar, **los TODO 4 y 5 de `SmokeTest.java`**: son los otros dos smoke
tests, y la guía del día en Moodle pide **los tres** en verde — hoy pasan porque están vacíos, no
porque estén hechos.

**La regla de oro:** ningún localizador se escribe sin haberlo probado antes en la consola de
DevTools de Chrome con `$$("...")`. Si devuelve **uno**, sirve. Si devuelve cero o siete, todavía no.

Y por cada objetivo rellena una fila de la tabla del `README.md` de tu proyecto: **qué estrategia
usaste y por qué esa y no otra**. Sin esa tabla, la entrega no cuenta.

El detalle de cada objetivo y las reglas de la casa están en Moodle: **Día 3 · QE → Guía del día**.

Guarda tu trabajo al terminar:

```bash
git add -A
git commit -m "Objetivos del miercoles"
git push
```

**✅ Qué debes ver:** el `push` termina con una línea `main -> main`, y el commit aparece en
la página de tu repositorio en GitHub. 🪟 En Windows salen antes unos avisos
`warning: ... LF will be replaced by CRLF`: son normales, sigue.

**❌ Si un objetivo falla con `NoSuchElementException`:** ese localizador devuelve cero en DevTools.
Vuelve a la regla de oro: pruébalo con `$$("...")` antes de tocar el Java. **❌ Si el `push` pide
usuario y contraseña:** es el token del Paso 5 (🐧 en Linux, sin `credential.helper`, lo pide cada vez).

---

# 🗓️ JUEVES — día 2 de QE

Hoy tu proyecto **crece**: se le añaden 5 archivos nuevos. **No empieces de cero** — si lo haces,
el viernes no te va a salir el ejercicio con el que abre el día.

---

### 🌅 Al empezar el jueves (y el viernes igual)

La laptop se apagó desde ayer. Antes del primer comando, tres cosas:

1. La terminal correcta (Paso 1), situada en tu proyecto: `cd ~/taskflow-qa-<tu-usuario>`.
2. TaskFlow arriba en la **segunda** terminal (Paso 6). Hoy tarda unos 15 segundos.
3. Chrome en http://localhost:8080/ mostrando el login (Paso 7).

Si te saltas la 2, **todos** los tests fallan con `NoSuchElementException` o
`ERR_CONNECTION_REFUSED`, y no es culpa de tu código.

---

## Paso 11 · Trae las novedades y añade los 5 archivos

**Qué vas a hacer:** actualizar el material del curso y copiar a tu proyecto los archivos del día 2.

Desde tu proyecto (`~/taskflow-qa-<tu-usuario>`):

```bash
git -C ../academyMty pull

D=../academyMty/qe/dia-2/taskflow-qa/src/test/java/com/taskflow/qa
cp $D/tests/EsperasTest.java \
   $D/tests/InteraccionTest.java \
   $D/tests/NavegacionPorClickTest.java \
   $D/tests/XPathTest.java   src/test/java/com/taskflow/qa/tests/
cp $D/utils/Sesion.java      src/test/java/com/taskflow/qa/utils/
```

**✅ Qué debes ver:** nada. Estos comandos, cuando funcionan, **no dicen nada**. Compruébalo así:

```bash
ls src/test/java/com/taskflow/qa/tests/
```

Tienen que aparecer **6 archivos**: los 2 del miércoles más los 4 nuevos.

**❌ Si dice `No such file or directory`:** no estás dentro de tu proyecto, o `academyMty` no está
al lado. Comprueba con `pwd` — debe terminar en `taskflow-qa-<tu-usuario>`.

---

## Paso 12 · Comprueba que todo sigue compilando

**Qué vas a hacer:** asegurarte de que lo nuevo convive con lo que escribiste ayer. **Antes de
tocar nada.**

```bash
mvn test-compile
```

**✅ Qué debes ver** (unos 7 segundos):

```
BUILD SUCCESS
```

Y tu trabajo del miércoles **sigue intacto**: los archivos de hoy son todos nuevos, ninguno pisa
lo tuyo.

**❌ Si sale `BUILD FAILURE`:** lee el primer error, no el último. Casi siempre falta un archivo
del paso anterior.

El trabajo de hoy —XPath, interacción y los cinco casos de espera— está en Moodle: **Día 4 · QE →
Guía del día**. Antes de entregar, esto no debe listar nada:

```bash
grep -rn 'Thread.sleep' src/test/java
```

*(En Moodle aparece con `-rc`: ahí todas las líneas deben terminar en `:0`.)*

---

# 🗓️ VIERNES — día 3 de QE

Hoy tu proyecto se convierte en un framework. Se añaden 11 archivos. Y antes de nada, lo mismo que
ayer: terminal correcta, TaskFlow arriba, Chrome mostrando el login.

---

## Paso 13 · Trae las novedades y añade los 11 archivos

**Qué vas a hacer:** copiar a tu proyecto las piezas del framework: 5 page objects, 2 tests, 3
utilidades y un `config.properties`.

Desde tu proyecto (`~/taskflow-qa-<tu-usuario>`):

```bash
git -C ../academyMty pull

E=../academyMty/qe/dia-3/taskflow-qa/src/test
mkdir -p src/test/java/com/taskflow/qa/pages src/test/resources
cp $E/java/com/taskflow/qa/pages/*.java          src/test/java/com/taskflow/qa/pages/
cp $E/java/com/taskflow/qa/tests/BaseTest.java \
   $E/java/com/taskflow/qa/tests/LoginTest.java  src/test/java/com/taskflow/qa/tests/
cp $E/java/com/taskflow/qa/utils/Config.java \
   $E/java/com/taskflow/qa/utils/DriverFactory.java \
   $E/java/com/taskflow/qa/utils/CapturaAlFallo.java  src/test/java/com/taskflow/qa/utils/
cp $E/resources/config.properties                src/test/resources/
```

**✅ Compruébalo:**

```bash
mvn test-compile
```

Tiene que decir `BUILD SUCCESS` (unos 8 segundos). Y la carpeta `pages/`, que hasta hoy no existía
en tu proyecto, ahora tiene 5 archivos.

**❌ Si dice `No such file or directory`:** igual que ayer: `pwd` debe terminar en
`taskflow-qa-<tu-usuario>`. **❌ Si sale `BUILD FAILURE`:** lee el primer error; casi siempre
falta uno de los archivos de arriba.

---

## Paso 14 · La pregunta con la que abre el día

**Qué vas a hacer:** contar en cuántos archivos tendrías que entrar si mañana renombran un solo
elemento de la página. Este número es la razón de ser de todo el día.

```bash
grep -rc 'data-testid' src/test/java | sort -t: -k2 -rn
```

**✅ Qué debes ver:** una lista ordenada. En un proyecto que llegó al viernes arrastrando los tres
días, hay **apariciones repartidas en unos 5 archivos**:

```
src/test/java/com/taskflow/qa/tests/LocalizacionTest.java:4
src/test/java/com/taskflow/qa/tests/NavegacionPorClickTest.java:3
src/test/java/com/taskflow/qa/tests/XPathTest.java:2
src/test/java/com/taskflow/qa/tests/InteraccionTest.java:1
src/test/java/com/taskflow/qa/pages/ProyectosPage.java:1
...
```

**La pregunta es:** si mañana renombran `btn-login`, ¿cuántos archivos abres? Ésa es exactamente la
respuesta, y ése es el problema que resuelve el **Page Object Model**.

**❌ Si sólo aparece un archivo con apariciones:** empezaste de cero hoy en vez de arrastrar los
tres días, y el ejercicio pierde el sentido. Vuelve al Paso 11 y rehaz jueves y viernes sobre tu
proyecto del miércoles.

El trabajo de hoy está en Moodle: **Día 5 · QE → Guía del día**. Dos cosas que vas a necesitar:

- **Correr la suite en headless** (la guía del día lo pide en los dos modos): cuando hayas resuelto
  el TODO 1 de `DriverFactory.java`, es `mvn test -Dheadless=true`. Sin tocar `config.properties`.
- `-DbaseUrl=...` sigue funcionando en el framework: la propiedad de la línea de comandos gana a
  `config.properties`.

---

# 🔧 Cuando algo se rompe

Mensajes que vas a ver, con su traducción. **Los cuatro primeros son normales: no son errores.**

| Lo que ves | Qué significa | Qué haces |
|---|---|---|
| `ADVERTENCIA: Unable to find CDP implementation matching <nº>` (o `WARNING:` en inglés) | Selenium no trae el módulo de DevTools para tu versión de Chrome. Nada del curso lo usa | **Nada.** Sigue |
| 🪟 Ventana del firewall pidiendo permiso para *OpenJDK Platform binary* | Java abre un puerto local por primera vez | **Permitir acceso.** Sale una sola vez |
| El primer `mvn test` tarda medio minuto o más | Se está descargando Selenium (~40 MB). Sólo la primera vez | Espera |
| `BUILD SUCCESS` con 11 tests y Chrome sin abrirse | Los tests del andamiaje están vacíos: es lo esperado antes de escribirlos | Sigue al Paso 9 |
| `mvn: command not found` | Maven no está en tu terminal. El de IntelliJ no cuenta | Guía de ambiente — Día 0, capítulo *Maven*; 🐧 Paso 0 |
| 🐧 `Source option 5 is no longer supported` | Tu Maven es el 3.8 o 3.6 de `apt`, que no entiende el `pom.xml` del curso | Maven 3.9.16 del `.tar.gz` (Paso 0) |
| 🪟 `"cp" no se reconoce como un comando interno o externo` (o `grep`, `uname`) | Estás en el Símbolo del sistema | Abre **Git Bash** (Paso 1) |
| 🪟 `ls` muestra una tabla con `Directorio:` y `Mode`; `grep` o `$D` no funcionan | Estás en PowerShell | Abre **Git Bash** (Paso 1) |
| `cannot find symbol` sobre `ChromeDriver` | Falta `import org.openqa.selenium.chrome.ChromeDriver;` | Añádelo (Paso 9) |
| `Port 8080 was already in use` | Otra cosa ocupa el puerto | Ciérrala, o arranca TaskFlow en otro: `mvn spring-boot:run -Dspring-boot.run.profiles=h2 -Dspring-boot.run.arguments=--server.port=9090` y lanza los tests con `mvn test -DbaseUrl=http://localhost:9090` |
| Bloques `Hibernate: create table ...` en la terminal del servidor | Arrancaste el SUT sin el perfil `h2`: los datos van a un archivo y no se limpian al reiniciar | Ctrl + C y repite el Paso 6 con el comando completo |
| Chrome dice `ERR_CONNECTION_REFUSED` en `localhost:8080` | El SUT no está arriba | Mira la segunda terminal; vuelve al Paso 6 |
| Todos los tests fallan con `NoSuchElementException` | Probablemente el SUT no está arriba | Abre `http://localhost:8080/` a mano. Si no carga, vuelve al Paso 6 |
| `SessionNotCreatedException` · `Could not start a new session` | Chrome no arrancó | Comprueba que Chrome abre a mano. 🐧 En `aarch64` no hay Chrome: Paso 0 |
| 🐧 `error: unknown switch 'b'` en `git init -b main` | git anterior a 2.28 | `git init` y luego `git branch -M main` (Paso 4) |
| `driver.get(...)` lanza `InvalidArgumentException` | Usaste `getDomAttribute("href")`, que devuelve la ruta tal cual está escrita en el HTML (relativa) | Usa `getAttribute("href")`, que la devuelve completa |

---

# ⏱️ Cuánto debe tardar cada cosa

Medido con buena conexión: 🪟 en una laptop Windows 11 sin nada instalado previamente, 🐧 en un
Ubuntu 24.04 limpio (en contenedor, sin escritorio). **Si tardas bastante más, pregunta: algo va
mal.**

| Paso | 🪟 Windows, primera vez | 🐧 Linux, primera vez |
|---|---|---|
| 2 · `git clone` | ~10 s | ~5 s |
| 3-4 · Crear tu proyecto y el commit | ~2 s | ~2 s |
| 6 · Arrancar TaskFlow en frío | **~90 s** (después, ~15 s) | **~60-90 s** (después, ~5-15 s) |
| 8 · Primer `mvn test` | ~35 s | ~25 s |
| 9 · Primer test con Chrome | ~15 s | ~10 s |
| 11-12 · Jueves completo | ~7 s | ~5 s |
| 13-14 · Viernes completo | ~8 s | ~5 s |

🍎 En macOS los tiempos son del mismo orden que en Linux.

---

## Qué se entrega

**El martes 8 (23:59):** las dos cosas del bloque *Lo que entregas el martes*, en la tarea
**🔧 Comprobación de ambiente y repositorio**.

**El viernes 11 (17:00):** el enlace a tu repositorio `taskflow-qa-<tu-usuario>`, en la tarea
**Integrador Semana 5 — AWS desplegado y framework POM en verde**. Un solo repositorio con los tres
días dentro — no tres proyectos sueltos. *(La misma tarea recoge también la evidencia de AWS del
lunes y el martes.)*

Y no olvides la **tabla de justificación** del `README.md`: qué localizador usaste en cada objetivo
y por qué ése y no otro.
