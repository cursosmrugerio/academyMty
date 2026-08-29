# AWS — Semana 5, lunes y martes

El andamiaje de los dos días de AWS. **No es material para leer: es lo que completas tú.**

| Carpeta | Día | Qué hay dentro |
|---|---|---|
| `dia-1/` | **lunes 7-sep** | `infra/` con la receta de la EC2, la topología y los dos checklists; `plan-b/` con el quiz de decisiones |
| `dia-2/` | **martes 8-sep** | `pipeline/` con `buildspec.yml`, `appspec.yml`, los hooks y `taskflow.service`; `dynamodb/` con los comandos y el ejercicio de modelado |

## Lo que se despliega es el proyecto de al lado

Los dos días giran alrededor de **`taskflow-api/`**, en este mismo repo. El lunes lo empaquetas
con `mvn package` y subes el jar a una EC2 a mano; el martes eso lo hace un pipeline y tú no
ejecutas ni un comando.

Por eso los labs viven aquí y no en otro repositorio: **el sujeto y sus herramientas, juntos.**

## Antes del lunes

Lee `dia-1/infra/checklist-previo-semana.md`. Lo importante tiene fecha: la **cuenta de AWS
verificada, con el plan gratuito elegido en el registro, creada al menos 3 días antes**. Una cuenta
recién nacida se queda en *pending verification* y no te deja lanzar una EC2 — y eso no se arregla
el lunes por la mañana.
