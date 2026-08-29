# Checklist de limpieza — martes

**Todo lo de ayer, más lo de hoy.**

- [ ] **CodePipeline** → borrar el pipeline ⚠ *un pipeline V1 activo cuesta $1/mes*
- [ ] **CodeBuild** → borrar el proyecto de build
- [ ] **CodeDeploy** → borrar el deployment group y la aplicación
- [ ] **DynamoDB** → borrar la tabla `taskflow-eventos`
- [ ] **EC2** → Terminate instance
- [ ] **S3** → vaciar y borrar el bucket de artefactos
- [ ] **IAM** → borrar los roles creados hoy
- [ ] **EC2 → Key pairs** → borrar `taskflow-key` y el `.pem` local
- [ ] **Budgets → NO TOCAR**

## Verificación cruzada

Mi consola la revisó: `_______________________`

> Fin de los dos días de AWS. Mañana no se crea nada en la nube:
> mañana empieza automatización de pruebas, y corre todo en tu laptop.
