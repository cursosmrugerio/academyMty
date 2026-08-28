package com.taskflow.dto;

import com.taskflow.model.Priority;
import jakarta.validation.constraints.NotBlank;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/**
 * TaskRequest — el CONTRATO de ENTRADA para crear (POST) y reemplazar (PUT) una tarea. Es un record:
 * inmutable, constructor canónico, y Jackson lo entiende nativo (los records de S1D2 pagan aquí).
 *
 * Qué NO viaja aquí y por qué (decisiones de API fijadas por la spec):
 *   - 'id':        lo asigna el repositorio; el cliente no lo elige (si no, mass assignment).
 *   - 'status':    una tarea NACE en TODO; solo cambia por PATCH /tasks/{id}/status.
 *   - 'projectId': viene del PATH al crear (POST /projects/{projectId}/tasks); una tarea no se muda
 *                  de proyecto por PUT.
 * El DTO define EXACTAMENTE lo que el cliente puede tocar. La entidad Task nunca cruza el controller.
 *
 * Validación EN LA FRONTERA (AM-2): solo migran las reglas de FORMA. 'title' 3-120 pasa del
 * constructor de S1D2 a @NotBlank + @Size; 'priority' es obligatoria. Las reglas de CONTEXTO/ESTADO
 * NO migran: "dueDate no en el pasado" es solo AL CREAR (vive en Task.crear) y "no DONE sin assignee"
 * es de transición (vive en setStatus) — por eso 'dueDate' y 'assigneeId' van SIN anotaciones. La
 * doble validación del título (aquí y en el constructor) es defensa en profundidad, no redundancia.
 */
public record TaskRequest(

        @Schema(example = "Maquetar la portada")
        @NotBlank(message = "El título es obligatorio.")
        @Size(min = 3, max = 120, message = "El título debe tener entre 3 y 120 caracteres.")
        String title,

        @Schema(example = "Primera version, solo desktop")
        String description,

        @Schema(example = "HIGH")
        @NotNull(message = "La prioridad es obligatoria.")
        Priority priority,

        @Schema(example = "2", description = "id del responsable; null = sin asignar")
        Long assigneeId,

        @Schema(example = "2030-12-31", description = "Formato yyyy-MM-dd. Al CREAR no puede ser pasada")
        LocalDate dueDate
) {
}
