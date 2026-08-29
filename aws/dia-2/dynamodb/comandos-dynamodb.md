# DynamoDB — comandos del día (completa los TODO)

> Todo esto se puede hacer también desde la consola web. La CLI es la vía preferida
> porque deja rastro y se puede pegar en el entregable.

## 1. Crear la tabla

```bash
aws dynamodb create-table \
  --table-name taskflow-eventos \
  --attribute-definitions \
      AttributeName=taskId,AttributeType=S \
      AttributeName=fechaHora,AttributeType=S \
  --key-schema \
      AttributeName=taskId,KeyType=TODO \
      AttributeName=fechaHora,KeyType=TODO \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

> `HASH` es la *partition key* y `RANGE` la *sort key*. ¿Cuál va en cada sitio, y por qué?
>
> TODO

## 2. Insertar un evento

```bash
aws dynamodb put-item --table-name taskflow-eventos --item '{
  "taskId":    {"S": "T-001"},
  "fechaHora": {"S": "2026-09-08T09:15:00Z"},
  "tipo":      {"S": "CREADA"},
  "autor":     {"S": "ana"}
}'
```

Mete los cinco de `eventos.json`.

## 3. Recuperar UNO por su clave completa

```bash
aws dynamodb get-item --table-name taskflow-eventos \
  --key '{"taskId":{"S":"T-001"},"fechaHora":{"S":"2026-09-08T09:15:00Z"}}'
```

> ¿Qué pasa si le das solo el `taskId`? Pruébalo.
>
> TODO

## 4. `query` — todos los eventos de una tarea

```bash
aws dynamodb query --table-name taskflow-eventos \
  --key-condition-expression "taskId = :t" \
  --expression-attribute-values '{":t":{"S":"T-001"}}' \
  --return-consumed-capacity TOTAL
```

Capacidad consumida: `TODO`

## 5. `scan` — todos los eventos COMPLETADA

```bash
aws dynamodb scan --table-name taskflow-eventos \
  --filter-expression "tipo = :x" \
  --expression-attribute-values '{":x":{"S":"COMPLETADA"}}' \
  --return-consumed-capacity TOTAL
```

Capacidad consumida: `TODO`

## La pregunta del bloque

Con cinco elementos los dos números se parecen. **¿Y con cinco millones?**

> TODO — explica qué hace `query` y qué hace `scan`, y por qué el filtro
> del `scan` no te ahorra nada de lo que cuesta.

## Limpieza

```bash
aws dynamodb delete-table --table-name taskflow-eventos
```
