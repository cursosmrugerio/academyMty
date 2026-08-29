# Topología AWS — <TU NOMBRE>

> Complétalo con **tus** identificadores reales. Es parte del entregable de hoy.
> El endpoint del RDS va **ofuscado**: `taskflow-db.xxxxxx.us-east-1.rds.amazonaws.com`

## El dibujo

```
  navegador
      │
      │  :8080
      ▼
  ┌─────────────────────────────────┐
  │ SG: TODO                        │   subnet pública
  │ EC2: TODO   ·  java -jar        │   AZ: TODO
  │ IP pública: TODO                │
  └───────────────┬─────────────────┘
                  │  :5432
                  ▼
  ┌─────────────────────────────────┐
  │ SG: TODO                        │   sin IP pública
  │ RDS: TODO   ·  PostgreSQL 16    │
  │ endpoint: TODO (ofuscado)       │
  └─────────────────────────────────┘
```

## Inventario

| Recurso | Identificador | Región |
|---|---|---|
| Instancia EC2 | `TODO` | `us-east-1` |
| IP pública | `TODO` | |
| Security group de la EC2 | `TODO` | |
| Instancia RDS | `TODO` | |
| Security group del RDS | `TODO` | |
| Bucket S3 | `TODO` | |
| Presupuesto | `taskflow-5usd` | global |

## Las reglas de red que puse

| Security group | Puerto | Origen | Por qué |
|---|---|---|---|
| `TODO` (EC2) | 22 | `TODO` | TODO |
| `TODO` (EC2) | 8080 | `TODO` | TODO |
| `TODO` (RDS) | 5432 | `TODO` | TODO |

## Tabla A — mi diagnóstico de red

Rellena la fila del error que te tocó de verdad, con el texto literal del log.

| El error dice | Significa | Cómo lo arreglé |
|---|---|---|
| `TODO` | `TODO` | `TODO` |

## Las dos preguntas del DoD

**1. ¿Por qué el RDS no tiene IP pública?**

> TODO

**2. ¿Qué habría pasado si dejaba el SSH abierto a `0.0.0.0/0`?**

> TODO
