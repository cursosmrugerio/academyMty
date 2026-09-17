# ⚠ Llaves de PRÁCTICA — no son un secreto real

`private.pem` y `public.pem` son un par RSA **generado para este ejercicio de clase**
(firma de JWT con Spring Security). Están en el repo a propósito, para que el proyecto
arranque al clonarlo sin pasos previos.

**No protegen nada.** No se usan en ningún sistema desplegado y pueden regenerarse en
cualquier momento:

```bash
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out private.pem
openssl rsa -pubout -in private.pem -out public.pem
```

La privada debe empezar con `-----BEGIN PRIVATE KEY-----` (PKCS#8). Si dice
`BEGIN RSA PRIVATE KEY` es PKCS#1 y Spring no la lee.

---

## Lo que NO debes copiar de aquí

Commitear una llave privada es correcto **solo** porque es desechable y didáctica.
En un proyecto real:

- Las llaves van fuera del repo (variable de entorno, un gestor de secretos, o
  generadas en el despliegue), y `*.pem` entra al `.gitignore`.
- **Borrar la llave en un commit posterior no la quita:** sigue descargable desde el
  commit donde entró. Git guarda el historial completo.
- Si una llave real se te escapa a un repo, lo único que resuelve es **rotarla**.
  Limpiar el repo es secundario — cualquiera pudo clonarlo sin dejar rastro.
