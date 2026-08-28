package com.taskflow.config;

import com.taskflow.security.JwtAuthenticationFilter;
import jakarta.servlet.DispatcherType;
import java.util.List;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * SecurityConfig — la configuración de seguridad del día. Reemplaza CADA default de
 * spring-boot-starter-security:
 *   - la SecurityFilterChain por defecto -> nuestra chain con lambda DSL (moderna: el
 *     WebSecurityConfigurerAdapter MURIÓ en Spring Security 6, los tutoriales viejos no compilan);
 *   - el usuario en memoria -> la tabla users (vía JpaUserDetailsService);
 *   - Basic Auth -> JWT stateless (nuestro JwtAuthenticationFilter).
 *
 * @EnableMethodSecurity habilita @PreAuthorize (la regla de owner en el DELETE de proyectos).
 * Decisión canónica: reglas por URL para lo GRUESO (aquí) + UN @PreAuthorize para lo DATA-DRIVEN.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    /**
     * La SecurityFilterChain. ORDEN de los matchers: de lo específico a lo general, y
     * anyRequest().authenticated() SIEMPRE al final (declararlo antes de un permitAll ->
     * IllegalStateException y la app NI ARRANCA — punto de dolor 1).
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // CSRF deshabilitado: protege apps con SESIÓN/cookies (un atacante forja requests que
                // viajan con tu cookie). Con token en header no hay cookie que forjar. En una app
                // server-side con sesión NO se deshabilita.
                .csrf(csrf -> csrf.disable())
                // CORS ANTES que todo lo demas: sin esto, un frontend servido en otro origen
                // (localhost:5173, :3000, :4200...) ni siquiera llega. El navegador manda primero
                // un OPTIONS de preflight, ese OPTIONS no lleva token, cae en
                // anyRequest().authenticated() -> 401, y el navegador cancela la peticion real.
                // El sintoma que ve quien programa el front es un error de CORS que no menciona
                // autenticacion por ningun lado. Con .cors(), Spring Security atiende el preflight
                // ANTES de la cadena de autenticacion.
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .authorizeHttpRequests(auth -> auth
                        // ERROR primero, y no es un detalle: cuando Spring no encuentra un handler
                        // responde 404 y REENVIA a /error. Ese reenvio vuelve a pasar por esta cadena,
                        // /error no estaba permitido, y el resultado era un 401 "No autenticado" para
                        // CUALQUIER ruta mal escrita. Quien se equivocaba en una letra de la URL se
                        // ponia a arreglar su login, que no era el problema. Permitiendo el dispatch
                        // de ERROR, el codigo real (404) llega intacto al cliente.
                        .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                        // Público: login/registro y las herramientas de doc/consola.
                        .requestMatchers("/auth/**").permitAll()
                        // /info: metadatos del servicio (nombre + versión) — PÚBLICO para el smoke
                        // test de un despliegue (curl http://<host>:8080/info). Sin esta línea
                        // heredaría anyRequest().authenticated() -> 401 sin token, y el smoke test
                        // no podría distinguir "no desplegado" de "desplegado y pidiendo login".
                        .requestMatchers("/info").permitAll()
                        .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/h2-console/**").permitAll()
                        // Todo lo demás exige autenticación (sin token -> 401).
                        .anyRequest().authenticated())
                // Stateless: el servidor no guarda sesión; cada request se autoexplica con su token.
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // Sin este entry point, el anónimo recibiría 403; lo forzamos a 401 JSON (la tabla
                // canónica 401 vs 403 depende de esto).
                .exceptionHandling(eh -> eh
                        .authenticationEntryPoint(restAuthenticationEntryPoint())
                        .accessDeniedHandler(restAccessDeniedHandler()))
                // La consola H2 se pinta en un <frame>: permitir same-origin para que no salga en blanco.
                .headers(h -> h.frameOptions(f -> f.sameOrigin()))
                // Nuestro filtro JWT ANTES del de user/password: si hay Bearer válido, ya deja autenticado.
                // (El httpBasic de la mañana FUE andamiaje: aquí ya no está.)
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /**
     * CORS para los frontends del curso. Origen abierto A PROPOSITO: cada alumno sirve el suyo en
     * el puerto que le toque (Vite 5173, CRA 3000, Angular 4200...) y mantener una lista seria
     * pelearse con ella cada clase.
     *
     * allowCredentials queda en FALSE, y por eso "*" es admisible: el token viaja en la cabecera
     * Authorization, no en una cookie. Si algun dia se pasara a cookies, "*" dejaria de estar
     * permitido por la propia especificacion y habria que enumerar los origenes.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOriginPatterns(List.of("*"));
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("*"));
        cfg.setAllowCredentials(false);
        cfg.setMaxAge(3600L);   // el navegador cachea el preflight una hora
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cfg);
        return source;
    }

    /** BCrypt: salt automático + factor de costo. El mismo password da hashes DISTINTOS -> matches(). */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * AuthenticationManager PROVISTO (MP-5): se lee, no se memoriza. Spring lo arma a partir de los
     * beans presentes (nuestro UserDetailsService + PasswordEncoder) en un DaoAuthenticationProvider.
     * Lo usa AuthService.login para verificar credenciales.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * Entry point PROVISTO: responde 401 JSON cuando un request SIN autenticación toca un endpoint
     * protegido. "No sé quién eres" -> 401 (autenticación), distinto del 403 (autorización).
     */
    @Bean
    public AuthenticationEntryPoint restAuthenticationEntryPoint() {
        return (request, response, authException) -> {
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"status\":401,\"message\":\"No autenticado: falta un token válido.\"}");
        };
    }

    /**
     * Access denied handler PROVISTO: 403 JSON cuando un usuario AUTENTICADO no tiene permiso
     * (la regla @PreAuthorize del owner al borrar un proyecto ajeno). Distinto del 401.
     */
    @Bean
    public AccessDeniedHandler restAccessDeniedHandler() {
        return (request, response, ex) -> {
            response.setStatus(HttpStatus.FORBIDDEN.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write("{\"status\":403,\"message\":\"Sin permiso para esta operación.\"}");
        };
    }
}
