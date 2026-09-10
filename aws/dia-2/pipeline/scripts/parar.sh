#!/usr/bin/env bash
# Hook: ApplicationStop — para el servicio ANTES de que CodeDeploy sobrescriba el jar.
# Ayer esto era "kill <PID>".
#
# set -e: si un comando falla, el script termina con error (y CodeDeploy marca el hook en rojo).
# set -u: usar una variable sin definir es error. set -o pipefail: un fallo dentro de un pipe cuenta.
set -euo pipefail

# El "|| true" no es pereza: si el servicio todavía no existe (segundo despliegue tras un
# fallo) o ya estaba parado, "systemctl stop" devuelve error y, con "set -e", tumbaría el
# despliegue entero antes de empezar. Con "|| true" el error se ignora y seguimos.
systemctl stop taskflow || true

echo "taskflow parado (o no estaba corriendo)"
