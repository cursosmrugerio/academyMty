package com.taskflow.config;

import com.taskflow.controller.InfoController;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

/**
 * OpenApiConfig — lo que hace aparecer el botón «Authorize» en Swagger UI.
 *
 * EL PROBLEMA QUE RESUELVE: la API entera va con JWT, pero el documento OpenAPI no lo declaraba.
 * springdoc describía las rutas y los cuerpos, y ni una palabra de cómo autenticarse. Resultado
 * práctico: Swagger UI se abría SIN botón «Authorize», así que probar cualquier endpoint
 * protegido desde ahí devolvía 401 y no había forma de arreglarlo desde la propia página. Había
 * que sacar el token con POST /auth/login y pegarlo a mano, petición por petición.
 *
 * Dos anotaciones, dos trabajos distintos:
 *
 *   @SecurityScheme  DECLARA el mecanismo: HTTP Bearer con formato JWT. Es lo que dibuja el botón
 *                    y hace que Swagger añada el header Authorization a cada petición.
 *   security = ...   dentro de @OpenAPIDefinition, EXIGE ese esquema en TODAS las operaciones.
 *                    Sin esta línea el botón existe pero ninguna operación lo pide, y Swagger no
 *                    manda el header: el botón queda de adorno.
 *
 * Y como la exigencia es global, los tres endpoints PÚBLICOS (/auth/register, /auth/login e /info)
 * se salen de ella con @SecurityRequirements vacío, cada uno en su controlador. Si no, el
 * documento diría que hace falta token para pedir el token: una mentira circular, y además la que
 * más confunde a quien abre Swagger por primera vez.
 *
 * LA URL DE SERVIDOR, Y POR QUÉ ES RELATIVA: si no se declara `servers`, springdoc la GENERA a
 * partir de la petición que sirvió el documento. Detrás de un proxy que termina TLS (CloudFront,
 * delante de esta API desde el 31-ago-2026) eso produce «http://ec2-...compute-1.amazonaws.com»:
 * el esquema y el puerto del ORIGEN, no los que ve el navegador. Consecuencia MEDIDA: el Swagger
 * se abre por HTTPS pero cada «Try it out» dispara a HTTP, el navegador lo bloquea por mixed
 * content, y los botones quedan de adorno. Con url = "/" la dirección se resuelve contra la página
 * que sirve el Swagger, así que funciona sin tocar nada en los tres sitios donde vive esta API: el
 * localhost:8080 de cada alumno, la IP pública por HTTP, y el dominio HTTPS de CloudFront.
 *
 * NOTA: esto es documentación, no seguridad. Quien decide qué se protege es SecurityConfig; aquí
 * solo se DESCRIBE esa decisión. Si las dos divergen, la que manda es SecurityConfig y este
 * archivo pasa a estar mintiendo.
 */
@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "TaskFlow API",
                // La MISMA constante que responde GET /info: un número, un solo sitio.
                version = InfoController.VERSION,
                description = """
                        API REST de gestión de tareas por proyecto para Nodo Digital, una agencia \
                        de ~15 personas. Autenticación con JWT: primero POST /auth/login, y el \
                        token que devuelve se pega en «Authorize» (arriba a la derecha). \
                        Usuarios sembrados: ana/ana123, luis/luis123 y admin/admin123."""),
        servers = @Server(url = "/", description = "La API, relativa a donde se sirva esta página"),
        security = @SecurityRequirement(name = OpenApiConfig.ESQUEMA_JWT))
@SecurityScheme(
        name = OpenApiConfig.ESQUEMA_JWT,
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT",
        in = SecuritySchemeIn.HEADER,
        description = "Pega SOLO el token que devuelve POST /auth/login. Swagger le antepone "
                + "«Bearer » por su cuenta: si lo escribes tú, el header sale con el prefijo "
                + "duplicado y todo responde 401.")
public class OpenApiConfig {

    /** Nombre del esquema. Vive en una constante porque se referencia desde varias anotaciones y
     *  un typo aquí no da error de compilación: da un botón que no funciona. */
    public static final String ESQUEMA_JWT = "bearer-jwt";
}
