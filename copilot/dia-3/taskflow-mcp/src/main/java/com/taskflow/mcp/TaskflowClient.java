package com.taskflow.mcp;

import java.util.List;
import java.util.function.Supplier;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

/**
 * El único lugar que habla HTTP con la API de TaskFlow.
 *
 * Cada operación hace primero login (POST /auth/login) y usa el token en la cabecera Authorization.
 * Pedir un token por llamada es menos eficiente que guardarlo, pero nunca falla por un token caducado
 * (duran una hora) y el código se lee de un tirón. Para un servidor que usa una persona, basta.
 *
 * Las mismas peticiones que harías tú en PowerShell:
 *   $t = (Invoke-RestMethod -Method Post http://localhost:8080/auth/login -ContentType 'application/json' -Body '{"username":"ana","password":"ana123"}').token
 *   Invoke-RestMethod http://localhost:8080/tasks -Headers @{ Authorization = "Bearer $t" }
 */
@Component
public class TaskflowClient {

    /** Cuerpo de POST /auth/login. */
    record LoginRequest(String username, String password) {
    }

    /** Respuesta de POST /auth/login: la API solo devuelve el campo "token". */
    record AuthResponse(String token) {
    }

    private final RestClient rest;
    private final String baseUrl;
    private final String usuario;
    private final String password;

    /**
     * Spring inyecta un RestClient.Builder ya configurado con Jackson y los tres valores de
     * application.properties (que a su vez vienen de TASKFLOW_URL, TASKFLOW_USER y TASKFLOW_PASSWORD).
     */
    public TaskflowClient(RestClient.Builder builder,
                          @Value("${taskflow.url}") String baseUrl,
                          @Value("${taskflow.user}") String usuario,
                          @Value("${taskflow.password}") String password) {
        this.rest = builder.baseUrl(baseUrl).build();
        this.baseUrl = baseUrl;
        this.usuario = usuario;
        this.password = password;
    }

    /** GET /tasks: todas las tareas de todos los proyectos. */
    public List<Tarea> tareas() {
        String token = login();
        return llamar("pedir GET /tasks", () -> rest.get()
                .uri("/tasks")
                .header("Authorization", "Bearer " + token)
                .retrieve()
                .body(new ParameterizedTypeReference<List<Tarea>>() { }));
    }

    /** GET /projects: todos los proyectos. */
    public List<Proyecto> proyectos() {
        String token = login();
        return llamar("pedir GET /projects", () -> rest.get()
                .uri("/projects")
                .header("Authorization", "Bearer " + token)
                .retrieve()
                .body(new ParameterizedTypeReference<List<Proyecto>>() { }));
    }

    /** POST /projects/{projectId}/tasks: crea la tarea y devuelve lo que respondió la API (con su id). */
    public Tarea crearTarea(long projectId, NuevaTarea nueva) {
        String token = login();
        return llamar("crear la tarea con POST /projects/" + projectId + "/tasks", () -> rest.post()
                .uri("/projects/{projectId}/tasks", projectId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .body(nueva)
                .retrieve()
                .body(Tarea.class));
    }

    /** POST /auth/login con el usuario configurado; devuelve el token JWT. */
    private String login() {
        try {
            AuthResponse respuesta = rest.post()
                    .uri("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(new LoginRequest(usuario, password))
                    .retrieve()
                    .body(AuthResponse.class);
            return respuesta.token();
        } catch (HttpStatusCodeException e) {
            throw new TaskflowException("TaskFlow rechazó el login del usuario '" + usuario + "' con "
                    + e.getStatusCode().value() + ". Revisa TASKFLOW_USER y TASKFLOW_PASSWORD.",
                    "HTTP " + e.getStatusCode().value() + " en POST /auth/login");
        } catch (ResourceAccessException e) {
            throw sinConexion(e);
        }
    }

    /**
     * Ejecuta una petición y traduce los dos fallos típicos a un mensaje útil:
     * la API no está arrancada, o la API respondió con un error (400, 404, 422...).
     */
    private <T> T llamar(String que, Supplier<T> peticion) {
        try {
            return peticion.get();
        } catch (HttpStatusCodeException e) {
            throw new TaskflowException("TaskFlow respondió " + e.getStatusCode().value() + " al " + que + ".",
                    e.getResponseBodyAsString());
        } catch (ResourceAccessException e) {
            throw sinConexion(e);
        }
    }

    private TaskflowException sinConexion(ResourceAccessException e) {
        return new TaskflowException("No pude conectar con TaskFlow en " + baseUrl
                + ". ¿Está arrancada la API? En la carpeta del repo: "
                + "mvn spring-boot:run \"-Dspring-boot.run.profiles=h2\"",
                e.getMostSpecificCause().toString());
    }
}
