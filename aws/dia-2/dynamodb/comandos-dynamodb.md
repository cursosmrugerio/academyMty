# DynamoDB — comandos del día, explicados

> Todo esto se puede hacer también desde la consola web. La CLI es la vía preferida
> porque deja rastro y se puede pegar en el entregable. Los comandos van completos: se copian,
> se ejecutan y se compara el resultado con lo que dice cada bloque.

## 1. Crear la tabla

```bash
aws dynamodb create-table \
  --table-name taskflow-eventos \
  --attribute-definitions \
      AttributeName=taskId,AttributeType=S \
      AttributeName=fechaHora,AttributeType=S \
  --key-schema \
      AttributeName=taskId,KeyType=HASH \
      AttributeName=fechaHora,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```

> Sin `--region`: la tabla se crea en la región que configuraste con `aws configure`
> (`us-east-1`, o `us-east-2` Ohio si tu cuenta es de la experiencia nueva: ahí `us-east-1` está bloqueado).

> **Por qué `taskId` es `HASH` y `fechaHora` es `RANGE`, y no al revés.** `HASH` es la *partition key*:
> decide **en qué servidor vive el dato**, y todo lo que comparte ese valor queda junto. `RANGE` es la
> *sort key*: **ordena lo que hay dentro de esa partición**. Lo que vas a preguntar es «dame los
> eventos de la tarea T-001, en orden», así que la tarea agrupa (`taskId` = HASH) y la fecha ordena
> (`fechaHora` = RANGE). Al revés, cada fecha sería su propia partición y los eventos de una tarea
> quedarían repartidos por todo el clúster: para leerlos habría que recorrer la tabla entera.

## 2. Insertar un evento

```bash
aws dynamodb put-item --table-name taskflow-eventos --item '{
  "taskId":    {"S": "T-001"},
  "fechaHora": {"S": "2026-09-08T09:15:00Z"},
  "tipo":      {"S": "CREADA"},
  "autor":     {"S": "ana"}
}'
```

Los cinco de `eventos.json`, ya traducidos al formato de la CLI (cada valor lleva su tipo, `{"S": …}`;
el campo `detalle` se omite cuando en el JSON está vacío). Uno por línea, se pegan tal cual:

```bash
aws dynamodb put-item --table-name taskflow-eventos --item '{"taskId":{"S":"T-001"},"fechaHora":{"S":"2026-09-08T09:15:00Z"},"tipo":{"S":"CREADA"},"autor":{"S":"ana"},"detalle":{"S":"Maquetar la pantalla de proyectos"}}'
aws dynamodb put-item --table-name taskflow-eventos --item '{"taskId":{"S":"T-001"},"fechaHora":{"S":"2026-09-08T10:02:00Z"},"tipo":{"S":"ASIGNADA"},"autor":{"S":"admin"},"detalle":{"S":"asignada a luis"}}'
aws dynamodb put-item --table-name taskflow-eventos --item '{"taskId":{"S":"T-001"},"fechaHora":{"S":"2026-09-08T11:40:00Z"},"tipo":{"S":"EN_PROGRESO"},"autor":{"S":"luis"}}'
aws dynamodb put-item --table-name taskflow-eventos --item '{"taskId":{"S":"T-002"},"fechaHora":{"S":"2026-09-08T09:30:00Z"},"tipo":{"S":"CREADA"},"autor":{"S":"luis"},"detalle":{"S":"Revisar el contrato de la API"}}'
aws dynamodb put-item --table-name taskflow-eventos --item '{"taskId":{"S":"T-002"},"fechaHora":{"S":"2026-09-08T16:05:00Z"},"tipo":{"S":"COMPLETADA"},"autor":{"S":"luis"}}'
```

`put-item` no imprime nada cuando va bien. Comprobación: `aws dynamodb scan --table-name taskflow-eventos --select COUNT` → `"Count": 5`.

## 3. Recuperar UNO por su clave completa

```bash
aws dynamodb get-item --table-name taskflow-eventos \
  --key '{"taskId":{"S":"T-001"},"fechaHora":{"S":"2026-09-08T09:15:00Z"}}'
```

Devuelve el evento `CREADA` de ana. **Si le das solo el `taskId`** (`--key '{"taskId":{"S":"T-001"}}'`)
falla con `ValidationException: The provided key element does not match the schema`. Con clave
compuesta, `get-item` exige **las dos partes**: identifica *un elemento exacto*, no un conjunto. Para
pedir un conjunto está `query`. Pruébalo: ver el error con tus ojos vale más que leerlo.

## 4. `query` — todos los eventos de una tarea

```bash
aws dynamodb query --table-name taskflow-eventos \
  --key-condition-expression "taskId = :t" \
  --expression-attribute-values '{":t":{"S":"T-001"}}' \
  --return-consumed-capacity TOTAL
```

Resultado esperado (medido el 4-sep y el 10-sep): `Count: 3`, `ScannedCount: 3`, y al final
`ConsumedCapacity.CapacityUnits: 0.5`. Leyó **solo la partición** de T-001 y devolvió sus tres eventos
ya ordenados por `fechaHora`.

## 5. `scan` — todos los eventos COMPLETADA

```bash
aws dynamodb scan --table-name taskflow-eventos \
  --filter-expression "tipo = :x" \
  --expression-attribute-values '{":x":{"S":"COMPLETADA"}}' \
  --return-consumed-capacity TOTAL
```

Resultado esperado: `Count: 1`, `ScannedCount: 5`, `CapacityUnits: 2.0`. Devolvió **un** elemento
pero leyó **los cinco**: `ScannedCount` es lo que pagaste.

## La lección del bloque

Con cinco elementos, 0.5 contra 2.0 parece poca cosa. **Con cinco millones**, el `query` sigue
costando lo de una partición y el `scan` cuesta los cinco millones.

| | `query` | `scan` |
|---|---|---|
| Qué lee | **solo la partición** de ese `taskId` | **la tabla entera** |
| Cuándo filtra | al leer, por clave | **después de leer** |
| Coste con 5 M de elementos | el de esa partición | el de los 5 millones |

> **El filtro de un `scan` no te ahorra lo que cuesta.** DynamoDB lee todo, lo cobra todo, y
> después descarta lo que no casa. Un `scan` con filtro no es «un query un poco más lento»:
> es leer la tabla completa y tirar el 99 %. Por eso en DynamoDB `scan` es una herramienta de
> mantenimiento y de exportación, no de consulta. Si tu aplicación necesita un `scan` para
> funcionar, el modelado está mal.

## Limpieza

```bash
aws dynamodb delete-table --table-name taskflow-eventos
```
