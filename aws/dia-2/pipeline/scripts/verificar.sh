#!/usr/bin/env bash
# Hook: ValidateService
set -uo pipefail

# ¿Contra qué endpoint compruebas que la app está viva?
# PISTA: tiene que ser uno PÚBLICO. Si eliges uno protegido te va a devolver
# 401 y vas a creer que el despliegue falló.
URL="TODO"

# La aplicación tarda unos segundos en levantar. Comprobar a los 0 segundos
# es el mismo error que mirar el DOM antes de que cargue la página.
# NO lo resuelvas durmiendo un rato fijo: REINTENTA.
for intento in $(seq 1 TODO); do

  # TRAMPA: curl ya imprime 000 cuando no conecta. Si además le pones un
  # "|| echo 000", los dos se concatenan y sale "000000". Ojo con eso.
  codigo=TODO

  if [ "$codigo" = "TODO" ]; then
    echo "OK: $URL respondió en el intento $intento"
    exit 0
  fi
  echo "intento $intento: $URL devolvió '$codigo' — espero"
  TODO
done

echo "ERROR: $URL no respondió a tiempo"
# TODO: antes de rendirte, imprime las últimas líneas del servicio.
#       ¿Con qué comando se leen los logs de una unit de systemd?
TODO
exit 1
