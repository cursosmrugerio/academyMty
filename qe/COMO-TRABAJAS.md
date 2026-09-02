# Dónde vive tu código

> ⌨️ **Antes de teclear nada — qué terminal usar.**
> 🪟 **Windows: abre Git Bash**, no PowerShell ni el Símbolo del sistema. Los comandos de aquí abajo
> sólo funcionan ahí, y algunos —como `mkdir -p`— **fallan sin dar ningún error**.
> 🍎 **macOS: Terminal.** 🐧 **Linux: Terminal** (Ctrl + Alt + T).
> Compruébalo con `uname -s`: debe decir `MINGW64_...`, `Darwin` o `Linux`.
>
> 📘 **¿Primera vez?** Esta página es el resumen de comandos. Si prefieres que te lleven de la mano
> paso a paso, con qué debe salir en pantalla en cada momento, usa
> **[`GUIA-PASO-A-PASO.md`](GUIA-PASO-A-PASO.md)** — son los mismos comandos, explicados.

**Este repositorio trae el andamiaje. Tu trabajo vive en un repositorio TUYO, y es UNO SOLO que
crece los tres días.**

`qe/dia-1`, `qe/dia-2` y `qe/dia-3` no son tres proyectos que se hacen por separado: son las
piezas nuevas que se añaden **cada día al mismo proyecto**. Si el jueves empiezas de cero en
`qe/dia-2`, el viernes te vas a encontrar sin lo del miércoles — y el día entero está montado
sobre medir lo que escribiste esos dos días.

```
academyMty/                     ← lo clonas, y solo LEES de aquí
└── qe/dia-1  dia-2  dia-3      ← el andamiaje del día

taskflow-qa-<tu-usuario>/       ← TU repositorio. Aquí escribes, commiteas y entregas
```

El integrador de la semana pide **el enlace a tu repositorio**. Ese es este segundo.

---

## Miércoles — se crea, una sola vez

```bash
git clone https://github.com/cursosmrugerio/academyMty.git
cp -R academyMty/qe/dia-1/taskflow-qa taskflow-qa-<tu-usuario>
cd taskflow-qa-<tu-usuario>

git init -b main
git add -A
git commit -m "Andamiaje del miércoles"
```

Crea el repositorio **vacío** en GitHub con ese mismo nombre y conéctalo:

```bash
git remote add origin https://github.com/<tu-usuario>/taskflow-qa-<tu-usuario>.git
git push -u origin main
```

A partir de aquí, todo lo haces dentro de `taskflow-qa-<tu-usuario>`.

## Jueves — se añaden 5 archivos

```bash
git -C ../academyMty pull

D=../academyMty/qe/dia-2/taskflow-qa/src/test/java/com/taskflow/qa
cp $D/tests/EsperasTest.java \
   $D/tests/InteraccionTest.java \
   $D/tests/NavegacionPorClickTest.java \
   $D/tests/XPathTest.java   src/test/java/com/taskflow/qa/tests/
cp $D/utils/Sesion.java      src/test/java/com/taskflow/qa/utils/

mvn test-compile      # tiene que compilar antes de tocar nada
```

## Viernes — se añaden 11

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

mvn test-compile
```

---

## Tres cosas que quitan miedo

**El `pom.xml` no cambia en los tres días.** Es byte a byte el mismo. Se copia el miércoles y no
se vuelve a tocar.

**Nada de lo que copias pisa lo que ya escribiste.** Cada día trae archivos *nuevos*: 5 el jueves
y 11 el viernes, y ninguno existe ya en tu proyecto. `Paginas.java` es idéntico en `dia-1` y
`dia-2`, por eso arriba no se vuelve a copiar: el tuyo se queda como esté.

**Compila en cada paso.** Está comprobado ejecutándolo, no suponiéndolo: partiendo de `dia-1`,
añadiendo los 5 del jueves y los 11 del viernes, `mvn test-compile` pasa las tres veces.

## Y por eso el viernes funciona

El día 5 abre con esto:

```bash
grep -rc 'data-testid' src/test/java | sort -t: -k2 -rn
```

La pregunta es «si hoy renombran `btn-login`, ¿cuántos archivos abro?». En un proyecto que llegó
al viernes arrastrando los tres días, la respuesta son **5 archivos** —medido: 11 apariciones
repartidas en 5 archivos—, y ese número es el que justifica el Page Object Model.

Esos 5 salen **del andamiaje solo**: no dependen de cuánto hayas escrito tú. Escribir tests que no
usen `data-testid` —el driver, un `quit()`, comprobar un título— no sube la cuenta.

Si empezaste el viernes de cero, la respuesta es 1, no duele nada, y el día no tiene sentido.
