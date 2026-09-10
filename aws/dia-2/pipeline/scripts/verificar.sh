#!/usr/bin/env bash
# Hook: ValidateService — comprobar que la app responde. Ayer esto era "abrir el navegador
# a ver si respondía". Si este script sale con error (exit 1), el despliegue queda en rojo.
#
# Sin "-e" a propósito: curl va a fallar en los primeros intentos y eso es normal aquí.
set -uo pipefail

# GET /info es público (permitAll en SecurityConfig): no hace falta token. Por eso sirve de
# health check y por eso NO se usa /tasks, que daría 401 y haría creer que el despliegue falló.
# El HOST es localhost: este script corre DENTRO de la EC2. La IP pública cambia cada vez que
# relanzas la instancia, y este archivo va versionado en tu repo.
URL="http://localhost:8080/info"

# La aplicación tarda unos segundos en levantar. Comprobar a los 0 segundos es el mismo error
# que mirar el DOM antes de que cargue la página: no se resuelve durmiendo un rato fijo, se
# resuelve REINTENTANDO. 30 intentos × 2 s = hasta 60 s de margen.
for intento in $(seq 1 30); do
  # -s silencioso, -o /dev/null descarta el cuerpo, -w imprime solo el código HTTP,
  # --max-time 5 no se queda colgado. OJO: curl YA imprime 000 cuando no conecta; si además
  # pones "|| echo 000" se concatenan y sale "000000". Con "|| true" solo se traga el código
  # de salida y el valor queda limpio.
  codigo=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL" || true)
  if [ "$codigo" = "200" ]; then
    echo "OK: $URL respondió 200 en el intento $intento"
    exit 0
  fi
  echo "intento $intento: $URL devolvió '$codigo' — espero 2 s"
  sleep 2
done

echo "ERROR: $URL no respondió 200 en 60 segundos"
# Antes de rendirse, deja en el log de CodeDeploy las últimas líneas del servicio: es lo que
# verías con journalctl por SSH, sin tener que entrar.
echo "--- últimas líneas del servicio ---"
journalctl -u taskflow -n 40 --no-pager || true
exit 1
