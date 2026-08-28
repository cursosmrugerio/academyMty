package com.taskflow.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * ProjectRequest — el contrato de entrada para crear (POST) y reemplazar (PUT) un proyecto.
 *
 * Qué NO viaja aquí: 'id' (lo asigna el repositorio), 'ownerId' (hoy se fija al usuario semilla en
 * el service; en D5 saldrá del JWT) y 'createdAt' (lo pone el service al crear). El cliente solo
 * elige nombre y descripción.
 *
 * La regla 'name' 3-80 es NUEVA de la API (no viene de S1, donde Project no validaba el nombre):
 * @NotBlank + @Size, mensajes en español. Mismo patrón que TaskRequest.
 */
public record ProjectRequest(

        @Schema(example = "Rediseño del sitio")
        @NotBlank(message = "El nombre es obligatorio.")
        @Size(min = 3, max = 80, message = "El nombre debe tener entre 3 y 80 caracteres.")
        String name,

        @Schema(example = "Landing nueva para el cliente")
        String description
) {
}
