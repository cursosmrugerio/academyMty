package com.taskflow.mcp;

import java.time.LocalDate;

/** Un proyecto tal como lo devuelve GET /projects (ProjectResponse de taskflow-api). */
public record Proyecto(
        Long id,
        String name,
        String description,
        Long ownerId,
        LocalDate createdAt
) {
}
