#!/usr/bin/env bash
# Hook: AfterInstall — los files del appspec ya están copiados; dejar la máquina lista.
# Ayer esto era el "chown" del jar y arrancar a mano con nohup.
set -euo pipefail

# El jar y el directorio de trabajo tienen que pertenecer al usuario que corre el servicio
# (User=ec2-user en la unit): la base H2 se escribe en ./data, relativo a WorkingDirectory,
# y sin permiso de escritura la app arranca y muere al primer acceso a datos.
mkdir -p /opt/taskflow
chown -R ec2-user:ec2-user /opt/taskflow

# La unit acaba de aterrizar en /etc/systemd/system: systemd NO la ve hasta que se le dice
# que relea sus archivos.
systemctl daemon-reload
# enable: que el servicio arranque solo si la instancia se reinicia. No lo arranca ahora:
# eso es ApplicationStart.
systemctl enable taskflow

echo "permisos aplicados y unit registrada"
