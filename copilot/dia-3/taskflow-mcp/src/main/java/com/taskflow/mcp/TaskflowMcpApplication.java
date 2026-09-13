package com.taskflow.mcp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Arranque del servidor MCP.
 *
 * No abre ningún puerto: con spring.ai.mcp.server.stdio=true (application.properties) el starter de
 * Spring AI se queda leyendo peticiones JSON-RPC por la entrada estándar y contestando por la salida
 * estándar. Quien lo arranca es Copilot CLI, como proceso hijo, con el comando que registraste en
 * «copilot mcp add taskflow '--' java -jar ...» (en PowerShell, el -- va entre comillas). Cuando cierras la
 * sesión de Copilot, el proceso termina.
 *
 * Las herramientas no se registran aquí: el starter busca los métodos anotados con @McpTool en los
 * beans de Spring (ver TaskflowTools) y los publica en la respuesta a «tools/list».
 */
@SpringBootApplication
public class TaskflowMcpApplication {

    public static void main(String[] args) {
        SpringApplication.run(TaskflowMcpApplication.class, args);
    }
}
