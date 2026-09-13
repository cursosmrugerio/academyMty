package com.taskflow.mcp;

/**
 * Un fallo al hablar con TaskFlow, con un mensaje escrito para quien lo va a leer: el agente.
 *
 * Cuando una herramienta lanza una excepción, el servidor MCP no se cae: devuelve un resultado marcado
 * como error (isError: true) con DOS líneas de texto, el mensaje de la excepción y el de su causa raíz.
 * El modelo lo lee y te lo cuenta. Por eso:
 *   - el mensaje dice qué pasó y qué hacer, no un «Connection refused» a secas;
 *   - la causa lleva el detalle técnico (el código HTTP, el cuerpo del error de la API). Sin causa, el
 *     servidor repetiría el mensaje dos veces.
 */
public class TaskflowException extends RuntimeException {

    public TaskflowException(String mensaje, String detalleTecnico) {
        super(mensaje, new RuntimeException("Detalle técnico: " + detalleTecnico));
    }
}
