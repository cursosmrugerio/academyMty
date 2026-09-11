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

## Las cuatro ideas del día, explicadas

**1. ¿Cuántos comandos ejecutaste a mano ayer? ¿Y hoy?**

Ayer, unos quince: empaquetar, `scp`, entrar por SSH, instalar Java, `chown`, `nohup`, abrir el
navegador, y otra vez desde el `scp` cada vez que cambiabas algo. Hoy, **uno**: `git push`. Todo lo
demás está escrito en `buildspec.yml`, `appspec.yml` y los cuatro scripts, y lo ejecutan CodeBuild y
el agente de CodeDeploy en el mismo orden cada vez. Eso es un pipeline: los mismos comandos, pero
versionados y sin depender de que alguien se acuerde del orden.

**2. El `nohup … &` de ayer y el `systemctl start` de hoy hacen lo mismo. ¿Cuál es la diferencia real?**

Los dos arrancan el jar. La diferencia está en lo que pasa **después**. Con `nohup`, si el proceso
muere o la máquina se reinicia, nadie lo levanta: hay que entrar por SSH y repetirlo. Con systemd,
`Restart=always` lo relanza a los 5 segundos si muere, `enable` lo arranca solo al reiniciar la
instancia, y `journalctl -u taskflow` guarda los logs con fecha. `nohup` es un parche para una
sesión; `systemd` es cómo un servidor corre servicios.

**3. ¿Por qué el `appspec.yml` tiene que ir DENTRO del artefacto y no basta con tenerlo en el repositorio?**

Porque CodeDeploy **no mira tu repositorio**: recibe el zip que CodeBuild dejó en S3 y lo desempaqueta
en la EC2. Lo único que sabe hacer con ese zip es leer un `appspec.yml` en su raíz para saber qué
copiar y qué scripts correr. Si `buildspec.yml` no lo lista en `artifacts.files`, el zip llega sin
instrucciones y el despliegue falla antes de empezar. Por eso `artifacts.files` lleva el jar, el
`appspec.yml`, la unit y la carpeta `scripts/`: los cuatro viajan juntos.

**4. `ApplicationStop` se salta en el primer despliegue. ¿Por qué? ¿Qué implica para el segundo?**

Porque `ApplicationStop` se ejecuta con el `appspec.yml` y los scripts de la **revisión anterior**,
la que está ya instalada en la máquina, para parar lo viejo antes de instalar lo nuevo. En el primer
despliegue no hay revisión anterior, así que no hay nada que ejecutar y el agente lo salta. A partir
del segundo sí corre, y ahí importan dos cosas: el `|| true` de `parar.sh`, porque si el servicio no
existe `systemctl stop` daría error y tumbaría el despliegue; y que si rompes ese hook, el siguiente
despliegue falla **antes de bajar tu arreglo**, porque sigue usando la revisión rota. Por eso el
ejercicio de romper algo a propósito (4.2) se hace con `AfterInstall`, no con `ApplicationStop`.
