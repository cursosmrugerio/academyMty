package com.taskflow.dto.auth;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

/**
 * LoginRequest — cuerpo de POST /auth/login (T5). Solo username + password; el service delega en el
 * AuthenticationManager. Credenciales malas -> BadCredentialsException -> 401 vía el advice.
 */
public record LoginRequest(

        @Schema(example = "ana", description = "Usuarios sembrados: ana, luis, admin")
        @NotBlank(message = "El username es obligatorio.")
        String username,

        @Schema(example = "ana123", description = "ana123 / luis123 / admin123")
        @NotBlank(message = "El password es obligatorio.")
        String password
) {
}
