package com.taskflow.mcp;

import java.time.LocalDate;

/**
 * El cuerpo de POST /projects/{projectId}/tasks (TaskRequest de taskflow-api).
 *
 * assigneeId siempre viaja null: la herramienta crea tareas sin responsable, y así el agente no puede
 * asignarle trabajo a nadie por su cuenta.
 */
public record NuevaTarea(
        String title,
        String description,
        Prioridad priority,
        Long assigneeId,
        LocalDate dueDate
) {
}
