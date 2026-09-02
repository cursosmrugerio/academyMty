#!/usr/bin/env bash
# Comprobador de ambiente - Semana 5 (QE / Selenium)
# Funciona igual en Git Bash (Windows) y en Terminal (macOS / Linux).
# No instala ni cambia nada: solo mira y reporta.

FALTAN=0

ok()   { printf '  [ OK ]  %-18s %s\n' "$1" "$2"; }
mal()  { printf '  [FALTA] %-18s %s\n' "$1" "$2"; FALTAN=$((FALTAN+1)); }
aviso(){ printf '  [ OJO ] %-18s %s\n' "$1" "$2"; }

echo "==================================================================="
echo " COMPROBACION DE AMBIENTE - Semana 5 (QE / Selenium)"
echo "==================================================================="
echo "  fecha    : $(date '+%Y-%m-%d %H:%M')"
echo "  sistema  : $(uname -s) $(uname -m)"
case "$(uname -s)" in
  MINGW*|MSYS*) echo "  terminal : Git Bash sobre Windows   -> correcto" ;;
  Darwin)       echo "  terminal : Terminal de macOS        -> correcto" ;;
  Linux)        echo "  terminal : Terminal de Linux        -> correcto" ;;
  *)            echo "  terminal : desconocida ($(uname -s))" ;;
esac
echo "-------------------------------------------------------------------"

# --- 1. JDK 21 -----------------------------------------------------------
if command -v java >/dev/null 2>&1; then
  JV=$(java -version 2>&1 | head -1)
  case "$JV" in
    *'"21'*) ok "JDK 21" "$JV" ;;
    *)       mal "JDK 21" "hay Java pero NO es 21 -> $JV" ;;
  esac
else
  mal "JDK 21" "no se encontro 'java'. Instala Temurin 21 (Dia 0, cap. 1)"
fi

# --- 2. javac (JDK, no solo JRE) ----------------------------------------
if command -v javac >/dev/null 2>&1; then
  ok "javac" "$(javac -version 2>&1 | head -1)"
else
  mal "javac" "tienes JRE pero no JDK. Reinstala el JDK completo"
fi

# --- 3. Maven EN LA TERMINAL (el de IntelliJ no sirve aqui) -------------
if command -v mvn >/dev/null 2>&1; then
  MV=$(mvn -version 2>&1 | head -1)
  MJ=$(mvn -version 2>&1 | grep -i '^Java version' | head -1)
  case "$MV" in
    *'Apache Maven 3.9'*) ok "Maven 3.9.x" "$MV" ;;
    *)                    aviso "Maven" "version distinta de 3.9.x -> $MV" ;;
  esac
  case "$MJ" in
    *' 21'*) ok "Maven usa Java 21" "$MJ" ;;
    '')      aviso "Maven/Java" "no se pudo leer la version de Java de Maven" ;;
    *)       mal "Maven usa Java 21" "Maven corre sobre otro Java -> $MJ" ;;
  esac
else
  mal "Maven" "no se encontro 'mvn' EN LA TERMINAL. El Maven que trae"
  echo  "                         IntelliJ no cuenta: la semana 5 se ejecuta desde aqui."
fi

# --- 4. Git --------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
  ok "Git" "$(git --version)"
  GN=$(git config --get user.name 2>/dev/null)
  GE=$(git config --get user.email 2>/dev/null)
  if [ -n "$GN" ] && [ -n "$GE" ]; then
    ok "Identidad Git" "$GN <$GE>"
  elif [ -z "$GN" ] && [ -z "$GE" ]; then
    mal "Identidad Git" "sin configurar: el primer commit va a fallar"
  elif [ -z "$GN" ]; then
    mal "Identidad Git" "falta user.name (email si esta: $GE)"
  else
    mal "Identidad Git" "falta user.email (nombre si esta: $GN)"
  fi
else
  mal "Git" "no se encontro 'git'"
fi

# --- 5. Google Chrome ----------------------------------------------------
CHROME=""
case "$(uname -s)" in
  MINGW*|MSYS*)
    for p in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
             "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"; do
      [ -f "$p" ] && CHROME="$p" && break
    done
    if [ -n "$CHROME" ]; then
      CV=$(powershell -NoProfile -Command "(Get-Item 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe').VersionInfo.ProductVersion" 2>/dev/null | tr -d '\r')
      ok "Google Chrome" "${CV:-instalado}"
    else
      mal "Google Chrome" "no encontrado en Archivos de programa"
    fi ;;
  Darwin)
    if [ -d "/Applications/Google Chrome.app" ]; then
      CV=$(defaults read "/Applications/Google Chrome.app/Contents/Info" CFBundleShortVersionString 2>/dev/null)
      ok "Google Chrome" "${CV:-instalado}"
    else
      mal "Google Chrome" "no esta en /Applications"
    fi ;;
  *)
    if command -v google-chrome >/dev/null 2>&1; then ok "Google Chrome" "$(google-chrome --version)"
    else mal "Google Chrome" "no se encontro 'google-chrome'"; fi ;;
esac

# --- 6. Puerto 8080 ------------------------------------------------------
if command -v curl >/dev/null 2>&1; then
  if curl -s -o /dev/null --max-time 3 http://localhost:8080/ 2>/dev/null; then
    aviso "Puerto 8080" "OCUPADO: ya hay algo escuchando. Cierralo antes del miercoles"
  else
    ok "Puerto 8080" "libre"
  fi
else
  aviso "Puerto 8080" "sin 'curl' no se pudo comprobar"
fi

echo "-------------------------------------------------------------------"
if [ "$FALTAN" -eq 0 ]; then
  echo "  RESULTADO: LISTO PARA EL MIERCOLES"
else
  echo "  RESULTADO: TE FALTAN $FALTAN COSA(S) - revisa las lineas [FALTA]"
  echo "             Todas se resuelven con la Guia de ambiente - Dia 0 de Moodle."
fi
echo "==================================================================="
echo "  Copia TODO este texto y pegalo en la tarea de Moodle."
