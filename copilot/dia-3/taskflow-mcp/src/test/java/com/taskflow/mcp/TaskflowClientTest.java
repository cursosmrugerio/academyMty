package com.taskflow.mcp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withException;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.net.ConnectException;
import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

/**
 * TaskflowClient contra un servidor HTTP FALSO (MockRestServiceServer): comprueba qué peticiones manda
 * y cómo lee las respuestas, sin arrancar la API. Si alguien cambia la URL, el cuerpo del login o el
 * nombre de un campo, estos tests fallan.
 */
class TaskflowClientTest {

    private static final String URL = "http://localhost:8080";

    private MockRestServiceServer servidor;
    private TaskflowClient client;

    @BeforeEach
    void preparar() {
        RestClient.Builder builder = RestClient.builder();
        servidor = MockRestServiceServer.bindTo(builder).build();
        client = new TaskflowClient(builder, URL, "ana", "ana123");
    }

    private void esperaLogin() {
        servidor.expect(requestTo(URL + "/auth/login"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().json("{\"username\":\"ana\",\"password\":\"ana123\"}"))
                .andRespond(withSuccess("{\"token\":\"token-de-prueba\"}", MediaType.APPLICATION_JSON));
    }

    @Test
    void tareasHaceLoginYMandaElToken() {
        esperaLogin();
        servidor.expect(requestTo(URL + "/tasks"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Authorization", "Bearer token-de-prueba"))
                .andRespond(withSuccess("""
                        [{"id":7,"title":"Corregir bug de fechas","description":"Zona horaria en el cliente",
                          "status":"IN_PROGRESS","priority":"LOW","projectId":2,"assigneeId":2,"dueDate":"2026-09-15"}]
                        """, MediaType.APPLICATION_JSON));

        List<Tarea> tareas = client.tareas();

        servidor.verify();
        assertThat(tareas).singleElement().satisfies(t -> {
            assertThat(t.id()).isEqualTo(7L);
            assertThat(t.status()).isEqualTo("IN_PROGRESS");
            assertThat(t.dueDate()).isEqualTo(LocalDate.of(2026, 9, 15));
        });
    }

    @Test
    void crearTareaMandaElCuerpoQueEsperaLaApi() {
        esperaLogin();
        servidor.expect(requestTo(URL + "/projects/1/tasks"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer token-de-prueba"))
                .andExpect(content().json("""
                        {"title":"Probar el servidor MCP","description":"desde un test","priority":"HIGH",
                         "assigneeId":null,"dueDate":"2030-01-15"}
                        """))
                .andRespond(withStatus(HttpStatus.CREATED).contentType(MediaType.APPLICATION_JSON).body("""
                        {"id":10,"title":"Probar el servidor MCP","description":"desde un test","status":"TODO",
                         "priority":"HIGH","projectId":1,"assigneeId":null,"dueDate":"2030-01-15"}
                        """));

        Tarea creada = client.crearTarea(1, new NuevaTarea("Probar el servidor MCP", "desde un test",
                Prioridad.HIGH, null, LocalDate.of(2030, 1, 15)));

        servidor.verify();
        assertThat(creada.id()).isEqualTo(10L);
        assertThat(creada.status()).isEqualTo("TODO");
    }

    @Test
    void loginRechazadoExplicaQueRevisar() {
        servidor.expect(requestTo(URL + "/auth/login"))
                .andRespond(withStatus(HttpStatus.UNAUTHORIZED));

        assertThatThrownBy(() -> client.proyectos())
                .isInstanceOf(TaskflowException.class)
                .hasMessageContaining("401")
                .hasMessageContaining("TASKFLOW_USER");
    }

    @Test
    void apiApagadaDiceComoArrancarla() {
        servidor.expect(requestTo(URL + "/auth/login"))
                .andRespond(withException(new ConnectException("Connection refused")));

        assertThatThrownBy(() -> client.tareas())
                .isInstanceOf(TaskflowException.class)
                .hasMessageContaining("No pude conectar con TaskFlow en " + URL)
                .hasMessageContaining("spring-boot:run");
    }

    @Test
    void errorDeLaApiLlegaConSuMensaje() {
        esperaLogin();
        servidor.expect(requestTo(URL + "/projects/99/tasks"))
                .andRespond(withStatus(HttpStatus.NOT_FOUND).contentType(MediaType.APPLICATION_JSON)
                        .body("{\"status\":404,\"message\":\"No existe el proyecto 99\",\"errors\":[]}"));

        assertThatThrownBy(() -> client.crearTarea(99, new NuevaTarea("Tarea huérfana", null, Prioridad.LOW, null, null)))
                .isInstanceOf(TaskflowException.class)
                .hasMessageContaining("404")
                .cause().hasMessageContaining("No existe el proyecto 99");
    }
}
