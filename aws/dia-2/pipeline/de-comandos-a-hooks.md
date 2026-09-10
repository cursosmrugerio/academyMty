# De los comandos de ayer a los hooks de hoy

> Abre tu `comandos-ec2.md` del miércoles al lado. **Cada comando que ejecutaste a mano
> es una línea de un hook.** Esa es toda la idea del día.

| Ayer lo hiciste así (a mano) | Hoy vive en… | Hook |
|---|---|---|
| `mvn -q -DskipTests package` | `buildspec.yml` → `phases.build` | — (lo corre CodeBuild, no CodeDeploy) |
| `scp … taskflow-api.jar ec2-user@IP:~` | `appspec.yml` → `files` (source → destination) | — (la copia la hace el agente antes de `AfterInstall`) |
| *(no lo hiciste: matabas el proceso con `kill`)* | `scripts/parar.sh` → `systemctl stop taskflow \|\| true` | `ApplicationStop` |
| `chown` / permisos del jar | `scripts/permisos.sh` → `chown -R ec2-user …` + `daemon-reload` + `enable` | `AfterInstall` |
| `nohup java -jar … &` | `scripts/arrancar.sh` → `systemctl start taskflow` (y `taskflow.service` con el `ExecStart`) | `ApplicationStart` |
| abrir el navegador a ver si respondía | `scripts/verificar.sh` → `curl` a `/info` con reintentos | `ValidateService` |

## Preguntas (estas sí las respondes tú; van al entregable)

**1. ¿Cuántos comandos ejecutaste a mano ayer? ¿Y hoy?**

> TODO

**2. El `nohup … &` de ayer y el `systemctl start` de hoy hacen lo mismo. ¿Cuál es la diferencia real?**

> TODO

**3. ¿Por qué el `appspec.yml` tiene que ir DENTRO del artefacto y no basta con tenerlo en el repositorio?**

> TODO

**4. `ApplicationStop` se salta en el primer despliegue. ¿Por qué? ¿Qué implica para el segundo?**

> TODO
