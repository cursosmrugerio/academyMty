# Comandos del día — completa los TODO

> Copia este archivo a tu repo y ve rellenándolo con **tus** valores.
> Al final del día es tu bitácora: la que te va a servir mañana para escribir el `appspec.yml`.

## 1. Empaquetar (en tu laptop)

```bash
cd academyMty/taskflow-api
mvn -q -DskipTests package
ls -lh target/*.jar          # tamaño: TODO
shasum -a 256 target/taskflow-api-*.jar
# hash en la laptop: TODO
```

## 2. Conectar

```bash
chmod 400 taskflow-key.pem
ssh -i taskflow-key.pem ec2-user@TODO
```

Windows, si SSH falla:
```
TODO — apunta cuál de las dos vías te funcionó:
  (a) icacls, o (b) EC2 Instance Connect desde la consola
```

## 3. Java en la EC2

```bash
sudo dnf install -y java-21-amazon-corretto-headless
java -version                # salida: TODO
```

## 4. El jar viaja

```bash
scp -i TODO/taskflow-key.pem target/taskflow-api-*.jar ec2-user@TODO:~/taskflow-api.jar   # TODO = ruta a tu .pem (fuera del repo)
# tardó: TODO
sha256sum ~/taskflow-api.jar            # en la EC2 no existe shasum
# hash en la EC2: TODO
# ¿coinciden? TODO
```

## 5. Arranque con H2 (mañana)

```bash
nohup java -jar taskflow-api.jar > app.log 2>&1 &
tail -f app.log
```

URL de mi Swagger público: `TODO`

## 6. Arranque contra RDS (tarde)

```bash
ps aux | grep java          # el de la mañana sigue vivo: PID = TODO
kill TODO
nohup java -jar taskflow-api.jar \
  --spring.profiles.active=docker \
  --DB_HOST=TODO --DB_PORT=5432 --DB_NAME=taskflow \
  --DB_USER=taskflow --DB_PASSWORD='TODO' \
  --JWT_SECRET='TODO' \
  > app.log 2>&1 &
```

> ⚠ El `JWT_SECRET` son **64 caracteres nuevos**, no el de desarrollo que viene en el repo.
> Y no lo pegues en ningún archivo que vayas a commitear.

## 7. Diagnóstico

```bash
grep -n "Caused by" app.log | head -3   # ← la causa real está en la PRIMERA cadena (el último dice "Dialect": es consecuencia)
grep -n "already in use" app.log        # ← si sale, no es la red: el proceso de la mañana sigue vivo (kill)
ps aux | grep java
curl -s localhost:8080/swagger-ui/index.html | head -3
```

Mi error fue: `TODO`
Lo arreglé: `TODO`

## 8. Cuántos comandos ejecuté hoy a mano

> TODO — cuéntalos. Mañana los va a ejecutar un pipeline.
