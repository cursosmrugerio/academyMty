package com.taskflow.mcp;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.Test;

/**
 * Las herramientas con un TaskflowClient de mentira (una subclase que no hace HTTP) y un reloj fijo.
 */
class TaskflowToolsTest {

    private static final LocalDate HOY = LocalDate.of(2026, 9, 16);
    private static final Clock RELOJ = Clock.fixed(HOY.atStartOfDay(ZoneId.systemDefault()).toInstant(),
            ZoneId.systemDefault());

    /** Cliente falso: devuelve tareas fijas y guarda lo que le pidieron crear. */
    static class ClienteFalso extends TaskflowClient {
        final List<NuevaTarea> creadas = new ArrayList<>();

        ClienteFalso() {
            super(org.springframework.web.client.RestClient.builder(), "http://no-se-usa", "ana", "ana123");
        }

        @Override
        public List<Tarea> tareas() {
            return List.of(
                    new Tarea(2L, "Configurar Spring Boot", null, "DONE", "MED", 1L, 1L, HOY.minusDays(2)),
                    new Tarea(7L, "Corregir bug de fechas", null, "IN_PROGRESS", "LOW", 2L, 2L, HOY.minusDays(1)),
                    new Tarea(9L, "Documentar la API con Swagger", null, "IN_PROGRESS", "MED", 2L, 2L, null));
        }

        @Override
        public Tarea crearTarea(long projectId, NuevaTarea nueva) {
            creadas.add(nueva);
            return new Tarea(10L, nueva.title(), nueva.description(), "TODO", nueva.priority().name(),
                    projectId, null, nueva.dueDate());
        }
    }

    @Test
    void listarTareasVencidasDevuelveSoloLasVencidasDeHoy() {
        TaskflowTools tools = new TaskflowTools(new ClienteFalso(), RELOJ);

        assertThat(tools.listarTareasVencidas()).extracting(Tarea::id).containsExactly(7L);
    }

    @Test
    void crearTareaConvierteLaFechaYNoAsignaResponsable() {
        ClienteFalso cliente = new ClienteFalso();
        TaskflowTools tools = new TaskflowTools(cliente, RELOJ);

        Tarea creada = tools.crearTarea(1, "Revisar accesibilidad", "", Prioridad.HIGH, "2026-09-30");

        assertThat(creada.projectId()).isEqualTo(1L);
        assertThat(cliente.creadas).singleElement().satisfies(n -> {
            assertThat(n.dueDate()).isEqualTo(LocalDate.of(2026, 9, 30));
            assertThat(n.assigneeId()).isNull();
        });
    }

    @Test
    void crearTareaConFechaMalEscritaNoLlamaALaApi() {
        ClienteFalso cliente = new ClienteFalso();
        TaskflowTools tools = new TaskflowTools(cliente, RELOJ);

        assertThatThrownBy(() -> tools.crearTarea(1, "Revisar accesibilidad", null, Prioridad.HIGH, "30/09/2026"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("yyyy-MM-dd");
        assertThat(cliente.creadas).isEmpty();
    }
}
