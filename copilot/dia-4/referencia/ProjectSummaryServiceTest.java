package com.taskflow.unit;

import com.taskflow.dto.ProjectSummaryResponse;
import com.taskflow.exception.TaskValidationException;
import com.taskflow.model.Priority;
import com.taskflow.model.Project;
import com.taskflow.model.Task;
import com.taskflow.model.TaskStatus;
import com.taskflow.repository.ProjectRepository;
import com.taskflow.repository.TaskRepository;
import com.taskflow.repository.UserRepository;
import com.taskflow.service.ProjectService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

/** Unit de ProjectService.resumen (versión de referencia del Día 4): sin Spring, tareas reales. */
@ExtendWith(MockitoExtension.class)
class ProjectSummaryServiceTest {

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ProjectService service;

    private final Project appMovil = new Project(2L, "App Móvil", "d", 2L, null);

    @Test
    void resumen_cuentaPorEstadoYVencidas() throws TaskValidationException {
        LocalDate ayer = LocalDate.now().minusDays(1);
        when(taskRepository.findByProjectId(2L)).thenReturn(List.of(
                tarea(6L, TaskStatus.TODO, LocalDate.now().plusDays(10)),
                tarea(7L, TaskStatus.IN_PROGRESS, ayer),          // vencida
                tarea(8L, TaskStatus.DONE, ayer.minusDays(4)),    // fecha pasada pero DONE: NO vence
                tarea(9L, TaskStatus.IN_PROGRESS, null)));        // sin fecha: NO vence

        // Contado a mano: TODO 1, IN_PROGRESS 2, DONE 1; vencida solo la 7 (igual que el proyecto 2 de la semilla)
        assertEquals(new ProjectSummaryResponse(2L, "App Móvil", 4,
                        Map.of(TaskStatus.TODO, 1L, TaskStatus.IN_PROGRESS, 2L, TaskStatus.DONE, 1L), 1),
                service.resumen(appMovil));
    }

    @Test
    void resumen_proyectoSinTareas_todoEnCeroYLasTresClaves() {
        Project legacy = new Project(3L, "Migración Legacy", "d", 1L, null);
        when(taskRepository.findByProjectId(3L)).thenReturn(List.of());

        assertEquals(new ProjectSummaryResponse(3L, "Migración Legacy", 0,
                        Map.of(TaskStatus.TODO, 0L, TaskStatus.IN_PROGRESS, 0L, TaskStatus.DONE, 0L), 0),
                service.resumen(legacy));
    }

    private Task tarea(Long id, TaskStatus estado, LocalDate fecha) throws TaskValidationException {
        return new Task(id, "Tarea " + id, "d", estado, Priority.MED, 2L, 1L, fecha);
    }
}
