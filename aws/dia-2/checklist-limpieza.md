# Checklist de limpieza — jueves

**Todo lo de ayer, más lo de hoy.**

- [ ] **CodePipeline** → borrar el pipeline ⚠ *un pipeline V1 activo cuesta $1/mes*
- [ ] **CodeBuild** → borrar el proyecto de build
- [ ] **CodeDeploy** → borrar el deployment group y la aplicación
- [ ] **DynamoDB** → borrar la tabla `taskflow-eventos`
- [ ] **EC2** → Terminate instance
- [ ] **S3** → vaciar y borrar el bucket de artefactos (y el `codepipeline-<región>-…` si CodePipeline creó uno)
- [ ] **IAM** → borrar los roles creados hoy
- [ ] **IAM → IAM users → `taskflow-admin` → Security credentials → Access keys** → Deactivate → Delete
- [ ] **CodePipeline → Settings → Connections** → `github-taskflow` (y cualquier *Pending* con el mismo nombre)
- [ ] **EC2 → Key pairs** → borrar `taskflow-key` y el `.pem` local
- [ ] **Budgets → NO TOCAR**

## Verificación cruzada

Mi consola la revisó: `_______________________`

> Fin de los dos días de AWS. Mañana es día de trabajo en proyectos:
> si vuelves a levantar algo en la nube, la regla es la misma. Se destruye al cierre.
