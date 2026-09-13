---
name: verificar-taskflow
description: Verifica TaskFlow API de punta a punta con la app arrancada de verdad - empaqueta, arranca con el perfil h2 en segundo plano, hace login y comprueba GET /tasks/overdue, GET /tasks/unassigned y GET /projects/{id}/summary contra los datos de la semilla, y apaga la app al final. Úsala cuando pidan verificar, probar contra la app corriendo, hacer un smoke test o comprobar que los endpoints responden lo esperado antes de un PR.
---

# Verificar TaskFlow API contra la app arrancada

Los tests con mocks no prueban que la app arranque, que la seguridad deje pasar la ruta ni que la
base de datos devuelva lo que esperas. Esta skill lo comprueba con la app real y la semilla del
perfil `h2`, usando el script `verificar.ps1` de esta misma carpeta.

## Cómo se usa

1. **No arranques la app a mano** y no uses `mvn spring-boot:run`: el script la empaqueta, la
   arranca, la prueba y la apaga él solo.
2. Desde la raíz del repositorio, ejecuta **exactamente**:

   ```powershell
   pwsh -NoProfile -File .github/skills/verificar-taskflow/verificar.ps1
   ```

   Tarda de 30 segundos a 3 minutos (empaquetar + arrancar; medido: 52 s solo y 1 min 59 s dentro de una
   sesión del agente en Windows). Espera a que termine: la última línea
   empieza por `RESULTADO:`.
3. Si el puerto 8080 está ocupado por otra copia de la app, el script se detiene con un `[FALLA]` que
   lo dice. Pide a la persona que la apague; no mates procesos por tu cuenta.

## Cómo leer el resultado

Una línea por comprobación, `[OK]` o `[FALLA]`; debajo de cada `[FALLA]` salen `esperaba:` y `obtuve:`.

| Si falla… | Lo más probable |
|---|---|
| todo lo que va después de «Esperando a que /info responda» | la app no arrancó: el script imprime las últimas líneas del log (`target/verificar-8080-app.log`) |
| `mvn package no compilo (exit 1)` | el código no compila: el script imprime el final del log de Maven |
| `/projects/{id}/summary` con `HTTP 404` en los proyectos 1, 2 y 3 | el endpoint no existe todavía (la ruta no está mapeada) |
| `/projects/{id}/summary` con `HTTP 200` y números distintos, o `projectNameOk=False` | la lógica del conteo, el nombre del proyecto o los nombres de los campos no son los de la especificación |
| `sin token responde 401` con otro código | se tocó `SecurityConfig` |
| `Error inesperado: La semilla no termino tras 120 s` | el login de `ana` o `GET /tasks/9` no dieron 200: si se tocó `SecurityConfig`, el login o `DataSeeder`, es eso; si no, la máquina va lenta y se repite con `-EsperaMaxSeg 300` |

## Qué respondes

Copia las líneas `[OK]`/`[FALLA]` y la línea `RESULTADO:` tal cual salieron. Si hubo `[FALLA]`, di
cuál y la causa probable según la tabla, **sin cambiar código** salvo que te lo pidan.
