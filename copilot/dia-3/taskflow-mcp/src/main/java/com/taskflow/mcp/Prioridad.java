package com.taskflow.mcp;

/**
 * Las prioridades que acepta la API (enum Priority de taskflow-api).
 *
 * Que el parámetro de crear_tarea sea un enum y no un String tiene un efecto directo sobre el agente:
 * el esquema JSON de la herramienta publica "enum": ["LOW", "MED", "HIGH"], así que el modelo ve los
 * únicos valores válidos antes de llamar, en vez de adivinar "ALTA" o "High".
 */
public enum Prioridad {
    LOW,
    MED,
    HIGH
}
