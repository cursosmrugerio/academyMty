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

Y los dos ambientes van **siempre** marcados:

| | |
|---|---|
| 🪟 | **Windows** |
| 🍎 | **macOS y Linux** |

Cuando un paso no lleva marca, es porque **es idéntico en los dos**.

---

## Paso 0 · Antes del miércoles (esto se hace el lunes o el martes)

**Qué vas a hacer:** comprobar que tu computadora tiene lo que hace falta. Si esto no está
resuelto antes, el miércoles se te va la mañana instalando y te pierdes la clase.

1. Entra a Moodle → curso **Academia Backend · QE · GitHub Copilot** → sección **Recursos**.
2. Abre **🧰 Guía de ambiente — Día 0 (instalación)**.
3. Ve al capítulo **11 · Comprobación ejecutable — antes del miércoles**.
4. Sigue lo que dice: son dos líneas.
5. Pega la salida en la tarea **🔧 Comprobación de ambiente**, en la sección Semana 5.
   **Fecha límite: martes 8 de septiembre, 23:59.**

Necesitas **JDK 21**, **Maven 3.9.x**, **Git** y **Google Chrome**. Si te falta algo, cada capítulo
de esa misma guía te dice cómo instalarlo.

---

# 🗓️ MIÉRCOLES — día 1 de QE

Hoy montas tu proyecto, arrancas la aplicación que vas a probar, y escribes tu primer test.

---

## Paso 1 · Abre la terminal correcta

**Qué vas a hacer:** abrir el programa donde vas a escribir todos los comandos de los tres días.
Elegir el equivocado es el motivo número uno por el que un comando "no funciona".

🪟 **Windows — abre Git Bash.** *No PowerShell. No Símbolo del sistema.*
Menú Inicio → escribe `Git Bash` → Enter.
*(Ya lo tienes: viene dentro de Git for Windows.)*

🍎 **macOS — abre Terminal.** Cmd + Espacio → escribe `Terminal` → Enter.
**Linux** — tu terminal de siempre.

**Escribe esto** para comprobar que estás donde toca:

```bash
uname -s
```

**✅ Qué debes ver**

| | Sale esto |
|---|---|
| 🪟 Git Bash | `MINGW64_NT-10.0-26200` — el número cambia según tu Windows |
| 🍎 macOS | `Darwin` |
| Linux | `Linux` |

**❌ Si ves esto:**

```
El término 'uname' no se reconoce como nombre de un cmdlet, función,
archivo de script o programa ejecutable.
```

Estás en **PowerShell**. Ciérralo y abre **Git Bash**. No sigas: los comandos de esta guía no
funcionan ahí, y algunos **fallan sin avisar**.

---

## Paso 2 · Descarga el material del curso

**Qué vas a hacer:** traerte a tu computadora el repositorio del curso. De aquí **sólo vas a
leer**: tu trabajo va en otro sitio.

**Escribe esto:**

```bash
cd ~
git clone https://github.com/cursosmrugerio/academyMty.git
```

**✅ Qué debes ver** (tarda unos 10 segundos):

```
Cloning into 'academyMty'...
Updating files: 100% (728/728), done.
```

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

**✅ Qué debes ver:**

```
LocalizacionTest.java  SmokeTest.java
```

**❌ Si dice `cp: command not found`:** estás en PowerShell o en el Símbolo del sistema. Vuelve al
**Paso 1**.

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
[main (root-commit) 68a788b] Andamiaje del miercoles
 5 files changed, ...
```

**❌ Si dice `Please tell me who you are`:** git no sabe tu nombre todavía. Ponlo una sola vez —
sirve para siempre — y repite el `git commit`:

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@correo.com"
```

---

## Paso 5 · Crea tu repositorio en GitHub y súbelo

**Qué vas a hacer:** publicar tu proyecto. **Éste es el paso que más suele atascarse**, y no por
tu culpa: depende de tu cuenta, de la verificación en dos pasos y de los permisos. Si se complica,
avisa pronto y sigue con el Paso 6 mientras tanto.

1. Entra a **github.com** → botón **New** (repositorio nuevo).
2. Nombre: **`taskflow-qa-<tu-usuario>`**, el mismo que tu carpeta.
3. **Déjalo vacío**: sin README, sin `.gitignore`, sin licencia.
4. Botón **Create repository**.

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

---

## Paso 6 · Arranca TaskFlow (la aplicación que vas a probar)

**Qué vas a hacer:** poner en marcha la web contra la que van a correr tus tests.

> 🔴 **Importante: abre una SEGUNDA terminal para esto.**
> Este comando **no termina nunca** — se queda ocupando la ventana mientras la aplicación está
> encendida. Si lo lanzas en la terminal donde estás trabajando, te quedas sin ella.
> Deja esta segunda terminal abierta y olvídate: es tu "servidor".

En la **segunda** terminal (🪟 otra ventana de Git Bash · 🍎 otra pestaña de Terminal):

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

Y ahí se queda. **Es correcto que no vuelva el cursor.**

**❌ Si dice `Port 8080 was already in use`:** tienes otra cosa ocupando ese puerto. Ciérrala, o
dile a tus tests que usen otra dirección (ver *Cuando algo se rompe*, al final).

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

**❌ Si sale una página de Swagger** (una lista de endpoints de API) en vez del login: arrancaste
sin el perfil `h2`. Vuelve al Paso 6 y copia el comando completo, incluida la parte
`-Dspring-boot.run.profiles=h2`.

---

## Paso 8 · Lanza los tests por primera vez

**Qué vas a hacer:** comprobar que Maven, Java y el proyecto se entienden. De paso se descargan las
librerías de Selenium (unos 40 MB), y eso conviene tenerlo hecho antes de empezar a escribir.

Vuelve a **tu primera terminal** (la del proyecto, no la del servidor):

```bash
cd ~/taskflow-qa-<tu-usuario>
mvn test
```

**✅ Qué debes ver** (unos 35 segundos la primera vez):

```
Tests run: 11, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

> ⚠️ **Ojo con este verde: no significa lo que parece.**
> Los 11 tests **están vacíos** — sólo tienen comentarios `// TODO`, porque escribirlos es tu
> trabajo de hoy. Pasan porque no hacen nada.
> **Chrome todavía no se ha abierto ni una vez.** Eso ocurre en el paso siguiente.

**❌ Si dice `mvn: command not found`:** Maven no está instalado, o está sólo dentro de IntelliJ
(que aquí no cuenta). Capítulo *Maven* de la Guía de ambiente — Día 0.

---

## Paso 9 · Tu primer test de verdad — que Chrome se abra

**Qué vas a hacer:** resolver los tres primeros `TODO` de `SmokeTest.java`. **Éste es el paso que
de verdad valida tu ambiente**, porque es el primero que abre un navegador.

Abre `src/test/java/com/taskflow/qa/tests/SmokeTest.java` en tu editor y completa:

- **TODO 1** — crear el driver de Chrome: `driver = new ChromeDriver();`
  *(No hace falta `System.setProperty` ni WebDriverManager: Selenium Manager resuelve el driver solo.)*
- **TODO 2** — cerrarlo: `if (driver != null) driver.quit();`
- **TODO 3** — ir a `Paginas.LOGIN` y comprobar el título de la página.
  *Antes de escribirlo, mira a mano qué título tiene: está en la pestaña de Chrome.*

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

La primera vez tarda unos 15 segundos: Selenium descarga solo el `chromedriver` (unos 23 MB). No
lo instales a mano.

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

> **Vas a ver también una ADVERTENCIA amarilla:**
> `ADVERTENCIA: Unable to find CDP implementation matching 152`
> Ese número es **tu versión de Chrome**. **No es un error** y no afecta a nada de este curso.

---

## Paso 10 · Los ocho objetivos del día

Ya tienes el camino abierto. Ahora el ejercicio de verdad: `LocalizacionTest.java`, ocho
localizadores.

**La regla de oro:** ningún localizador se escribe sin haberlo probado antes en la consola de
DevTools de Chrome con `$$("...")`. Si devuelve **uno**, sirve. Si devuelve cero o siete, todavía no.

Y por cada objetivo rellena una fila de la tabla del `README.md` de tu proyecto: **qué estrategia
usaste y por qué esa y no otra**. Sin esa tabla, la entrega no cuenta.

Guarda tu trabajo al terminar:

```bash
git add -A
git commit -m "Objetivos del miercoles"
git push
```

---

# 🗓️ JUEVES — día 2 de QE

Hoy tu proyecto **crece**: se le añaden 5 archivos nuevos. **No empieces de cero** — si lo haces,
el viernes no te va a salir el ejercicio con el que abre el día.

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

---

# 🗓️ VIERNES — día 3 de QE

Hoy tu proyecto se convierte en un framework. Se añaden 11 archivos.

---

## Paso 13 · Trae las novedades y añade los 11 archivos

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

Tiene que decir `BUILD SUCCESS` (unos 8 segundos). Y la carpeta `pages/`, que nació vacía el
miércoles, ahora tiene 5 archivos.

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

---

# 🔧 Cuando algo se rompe

Mensajes que vas a ver, con su traducción. **Los cuatro primeros son normales: no son errores.**

| Lo que ves | Qué significa | Qué haces |
|---|---|---|
| `ADVERTENCIA: Unable to find CDP implementation matching <nº>` | Selenium no trae el módulo de DevTools para tu versión de Chrome. Nada del curso lo usa | **Nada.** Sigue |
| 🪟 Ventana del firewall pidiendo permiso para *OpenJDK Platform binary* | Java abre un puerto local por primera vez | **Permitir acceso.** Sale una sola vez |
| El primer `mvn test` tarda un minuto o más | Se está descargando Selenium (~40 MB). Sólo la primera vez | Espera |
| `BUILD SUCCESS` con 11 tests y Chrome sin abrirse | Los tests del andamiaje están vacíos: es lo esperado antes de escribirlos | Sigue al Paso 9 |
| `mvn: command not found` | Maven no está en tu terminal. El de IntelliJ no cuenta | Guía de ambiente — Día 0, capítulo *Maven* |
| `cp: command not found` · `grep: command not found` | 🪟 Estás en PowerShell o en el Símbolo del sistema | Abre **Git Bash** (Paso 1) |
| `Port 8080 was already in use` | Otra cosa ocupa el puerto | Ciérrala, o lanza los tests con `mvn test -DbaseUrl=http://localhost:9090` y arranca el SUT en ese puerto |
| Sale **Swagger** en vez del login | Arrancaste el SUT sin el perfil `h2` | Repite el Paso 6 con el comando completo |
| Todos los tests fallan con `NoSuchElementException` | Probablemente el SUT no está arriba | Abre `http://localhost:8080/` a mano. Si no carga, vuelve al Paso 6 |
| `driver.get(...)` lanza `InvalidArgumentException` | Usaste `getDomAttribute("href")`, que devuelve la ruta tal cual está escrita en el HTML (relativa) | Usa `getAttribute("href")`, que la devuelve completa |

---

# ⏱️ Cuánto debe tardar cada cosa

Medido en una laptop Windows 11 sin nada instalado previamente, con buena conexión. **Si tardas
bastante más, pregunta: algo va mal.**

| Paso | Primera vez |
|---|---|
| 2 · `git clone` | ~10 s |
| 3-4 · Crear tu proyecto y el commit | ~2 s |
| 6 · Arrancar TaskFlow en frío | **~90 s** (después, ~15 s) |
| 8 · Primer `mvn test` | ~35 s |
| 9 · Primer test con Chrome | ~15 s |
| 11-12 · Jueves completo | ~7 s |
| 13-14 · Viernes completo | ~8 s |

---

## Qué se entrega

**El enlace a tu repositorio** `taskflow-qa-<tu-usuario>`, en el integrador de la semana. Un solo
repositorio con los tres días dentro — no tres proyectos sueltos.

Y no olvides la **tabla de justificación** del `README.md`: qué localizador usaste en cada objetivo
y por qué ése y no otro.
