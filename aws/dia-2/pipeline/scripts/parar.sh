#!/usr/bin/env bash
# Hook: ApplicationStop
set -euo pipefail

# TODO: parar el servicio.
#
# TRAMPA: si el servicio todavía no existe —o ya estaba parado— el comando
# devuelve error y, con "set -e", tumba el despliegue entero antes de empezar.
# ¿Cómo lo evitas?
TODO
