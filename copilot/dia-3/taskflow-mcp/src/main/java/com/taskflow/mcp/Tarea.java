package com.taskflow.mcp;

import java.time.LocalDate;

/**
 * Una tarea tal como la devuelve la API de TaskFlow (TaskResponse de taskflow-api).
 *
 * Los nombres de los componentes son EXACTAMENTE los campos del JSON ("title", "dueDate"...): Jackson
 * convierte el JSON en este record campo por campo, y si un nombre no coincide ese valor llega null.
 *
 * status y priority llegan como texto ("IN_PROGRESS", "HIGH"); se dejan como String a propósito para
 * que este proyecto no dependa de las clases de taskflow-api.
 */
public record Tarea(
        Long id,
        String title,
        String description,
        String status,
        String priority,
        Long projectId,
        Long assigneeId,
        LocalDate dueDate
) {
}
