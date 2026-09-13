package com.taskflow.mcp;

import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

import org.springframework.ai.mcp.annotation.McpTool;
import org.springframework.ai.mcp.annotation.McpToolParam;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Las tres herramientas que este servidor le ofrece al agente.
 *
 * Cada método con @McpTool se publica como una herramienta:
 *   - name        el nombre que ve el modelo y el que usas en --allow-tool / --deny-tool:
 *                 taskflow(listar_tareas_vencidas).
 *   - description lo ÚNICO que el modelo sabe de la herramienta para decidir si la usa y cómo.
 *                 Una descripción vaga produce llamadas equivocadas: escríbela como para un compañero nuevo.
 *   - @McpToolParam  cada parámetro, con su descripción; Spring AI genera el esquema JSON a partir del tipo.
 *   - annotations    pistas para el cliente: readOnlyHint=true dice «esta no cambia nada».
 *                 Son pistas, no candados: la seguridad real es qué hace el código de abajo.
 *
 * Lo que devuelve cada método se convierte a JSON y es lo que el modelo lee como resultado.
 */
@Component
public class TaskflowTools {

    private final TaskflowClient client;
    private final Clock reloj;

    /** El constructor que usa Spring: el reloj del sistema. */
    @Autowired
    public TaskflowTools(TaskflowClient client) {
        this(client, Clock.systemDefaultZone());
    }

    /** El constructor de los tests: un reloj fijo para que «hoy» sea siempre el mismo día. */
    TaskflowTools(TaskflowClient client, Clock reloj) {
        this.client = client;
        this.reloj = reloj;
    }

    @McpTool(name = "listar_tareas_vencidas",
            description = "Lista las tareas de TaskFlow que están vencidas: tienen fecha límite (dueDate) anterior "
                    + "a hoy y su estado (status) no es DONE. Incluye tareas de todos los proyectos. "
                    + "Devuelve id, title, description, status, priority, projectId, assigneeId y dueDate. "
                    + "Solo lectura: no modifica nada.",
            annotations = @McpTool.McpAnnotations(readOnlyHint = true, destructiveHint = false,
                    idempotentHint = true, openWorldHint = false))
    public List<Tarea> listarTareasVencidas() {
        return Vencidas.filtrar(client.tareas(), LocalDate.now(reloj));
    }

    @McpTool(name = "listar_proyectos",
            description = "Lista los proyectos de TaskFlow con su id, name, description, ownerId y createdAt. "
                    + "Úsala para averiguar el id de un proyecto a partir de su nombre. Solo lectura.",
            annotations = @McpTool.McpAnnotations(readOnlyHint = true, destructiveHint = false,
                    idempotentHint = true, openWorldHint = false))
    public List<Proyecto> listarProyectos() {
        return client.proyectos();
    }

    @McpTool(name = "crear_tarea",
            description = "Crea una tarea nueva, sin responsable y en estado TODO, dentro de un proyecto de TaskFlow. "
                    + "Devuelve la tarea creada con el id que le asignó la API. "
                    + "Si no sabes el projectId, llama antes a listar_proyectos.",
            annotations = @McpTool.McpAnnotations(readOnlyHint = false, destructiveHint = false,
                    idempotentHint = false, openWorldHint = false))
    public Tarea crearTarea(
            @McpToolParam(description = "id numérico del proyecto donde se crea la tarea", required = true)
            long projectId,
            @McpToolParam(description = "título de la tarea, de 3 a 120 caracteres", required = true)
            String title,
            @McpToolParam(description = "descripción libre; puede ir vacía", required = false)
            String description,
            @McpToolParam(description = "prioridad: LOW, MED o HIGH", required = true)
            Prioridad priority,
            @McpToolParam(description = "fecha límite con formato yyyy-MM-dd (por ejemplo 2026-09-30); "
                    + "no puede ser anterior a hoy; vacía = sin fecha", required = false)
            String dueDate) {
        NuevaTarea nueva = new NuevaTarea(title, description, priority, null, fecha(dueDate));
        return client.crearTarea(projectId, nueva);
    }

    /** "2026-09-30" -> LocalDate; vacío o null -> sin fecha; cualquier otro formato -> error con ejemplo. */
    private static LocalDate fecha(String texto) {
        if (texto == null || texto.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(texto.trim());
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException(
                    "dueDate debe tener el formato yyyy-MM-dd (por ejemplo 2026-09-30); recibí: " + texto, e);
        }
    }
}
