#!/usr/bin/env bash
# Hook: ApplicationStart — arrancar el servicio. Ayer esto era "nohup java -jar … &".
set -euo pipefail

# Una línea: systemd lee taskflow.service (WorkingDirectory, User, ExecStart) y lanza la app.
# Si falla, el motivo está en: journalctl -u taskflow -n 40
systemctl start taskflow

echo "taskflow arrancado"
