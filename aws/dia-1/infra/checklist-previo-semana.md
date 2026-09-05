# Checklist previo — antes del lunes 7 de septiembre

> Esto **no** se hace el lunes por la mañana. Se hace antes.

## Cuenta AWS (al menos 3 días antes)

- [ ] Cuenta creada y **verificada** (tarjeta y teléfono confirmados).
      Una cuenta recién nacida puede quedar en *pending verification* y **no dejarte lanzar una EC2**.
- [ ] En el registro elegiste el **plan gratuito** («Free account plan»), no el de pago.
- [ ] Puedes entrar a la consola y ves el panel principal.
- [ ] Región puesta en **`us-east-1`** (si tu cuenta es de la *experiencia nueva* —entras por `settings.aws.com` y ves un proyecto «Proof of Concept»— tu región es **`us-east-2` Ohio** y no puedes cambiarla: anótalo, todo el curso lo haces ahí).

## Prework del domingo (20 min)

- [ ] `git clone https://github.com/cursosmrugerio/academyMty.git`
- [ ] `cd academyMty/taskflow-api && mvn package`
- [ ] `java -jar target/taskflow-api-3.0.0.jar`
- [ ] `http://localhost:8080/swagger-ui/index.html` abre
- [ ] Login con `ana` / `ana123` devuelve un token
- [ ] Con el token pegado en **Authorize**, `GET /tasks` responde  ← es `/tasks`, **sin `/api`**

> Si algo de esto está rojo, dilo en el canal de atascos **el domingo**.
> Quien llegue el lunes sin esto verde no puede empezar el bloque de las 11:15.

## Herramientas

- [ ] JDK 21 y Maven funcionando (`java -version`, `mvn -v`)
- [ ] Un cliente SSH:
      - macOS / Linux: ya lo tienes
      - Windows: OpenSSH en PowerShell, o **EC2 Instance Connect** desde la consola (no necesita nada instalado)
