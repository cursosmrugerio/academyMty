---
name: limpieza-aws
description: Checklist de limpieza de AWS de la Semana 5 (EC2, Elastic IP, EBS, key pairs, security groups, RDS, S3, DynamoDB, CodePipeline, CodeBuild, CodeDeploy, CloudFront, roles de IAM y access keys de taskflow-admin) convertido en una auditoría de solo lectura con el servidor MCP de AWS. Úsala cuando pidan revisar si quedó algo vivo o que cueste en la cuenta de AWS, auditar la limpieza o comprobar que la cuenta está limpia.
---

# Auditoría de limpieza de AWS (Semana 5)

En la Semana 5 cada día terminaba con un checklist de limpieza que se revisaba **mirando la consola**.
Esta skill hace la misma revisión **leyendo la cuenta por API**, sin tocar nada, con el script
[auditoria.py](auditoria.py) de esta carpeta.

## Cómo se hace

1. Lee el archivo `auditoria.py` de esta carpeta **completo**.
2. Llama **una sola vez** a la herramienta `aws___run_script` del servidor `aws-ro` pasándole el
   contenido del archivo **tal cual** en el parámetro `code`. No lo resumas, no lo reescribas y no le
   agregues llamadas de escritura.
3. Revisa `api_calls` en la respuesta: cada lectura dice `success` o `error`.
4. Arma el informe con `return_value`, con el formato de la sección siguiente.

El script revisa `us-east-1` y `us-east-2` (las dos regiones que usó el curso) y los servicios
globales una vez. Tarda unos 20 segundos.

## Qué significa cada resultado

| Lo que devuelve | Qué dices |
|---|---|
| una lista con elementos | **recursos vivos**: una fila por elemento en la tabla |
| `[]` | ese servicio está limpio en esa región |
| `NO SE PUEDE LEER: la cuenta bloquea esta región (SCP)…` | la cuenta de la experiencia nueva solo habilita su región; si la persona nunca usó esa región, no hay nada ahí. **No** es un error de la auditoría |
| `NO SE PUEDE LEER: …` con otro texto | error de lectura: cópialo tal cual en «Errores de lectura» |

## Qué cuesta si se queda (para la columna «¿Cuesta si se queda?»)

| Recurso | ¿Cuesta? |
|---|---|
| EC2 instancia `running` o `stopped` | **Sí**: la `running` cobra por hora; la `stopped` sigue cobrando su disco EBS |
| EBS volumen (`available` = suelto) | **Sí**, por GB al mes |
| Elastic IP | **Sí** (toda IP pública IPv4 cobra por hora) |
| RDS instancia | **Sí**, por hora |
| S3 bucket con objetos | **Sí**, por GB (poco, pero cuenta) |
| DynamoDB tabla on-demand vacía | Casi nada, pero se borra igual |
| CodePipeline pipeline | **Sí**: un pipeline V1 activo cuesta 1 USD al mes |
| CodeBuild proyecto, CodeDeploy aplicación | No mientras no se ejecuten, pero se borran igual |
| CloudFront distribución | Por tráfico; se deshabilita y se borra |
| Key pair, security group, rol de IAM | No cuestan; son riesgo de seguridad y desorden: se borran |
| Access key `Active` de `taskflow-admin` | No cuesta; **es el riesgo más grave** (una llave de administrador viva) |

Dos cosas que el script **no** revisa, y que la persona mira a mano en la consola:
- **CodePipeline → Settings → Connections** (`github-taskflow`): `ViewOnlyAccess` no permite listarlas;
  no cuestan.
- **Budgets: NO TOCAR.** El presupuesto se queda de vigía.

## Formato del informe

1. Tabla `| Servicio | Región | Recurso | Estado | ¿Cuesta si se queda? |`, una fila por recurso vivo.
2. `Servicios limpios:` la lista de servicios con `[]`, agrupados por región.
3. `Regiones bloqueadas por la cuenta:` las que dieron SCP (o «ninguna»).
4. `Errores de lectura:` los demás `NO SE PUEDE LEER` (o «ninguno»).
5. `Revisar a mano: Connections de CodePipeline · Budgets NO TOCAR`.
6. Última línea: `Veredicto: CUENTA LIMPIA` si no hay recursos vivos, o `Veredicto: QUEDAN N RECURSOS`.

No borres nada ni ofrezcas hacerlo: para cada recurso vivo, di en qué pantalla de la consola se borra
(por ejemplo «EC2 → Instances → Instance state → Terminate»).
