package com.taskflow.qa.utils;

/**
 * El unico sitio donde vive una URL en todo el proyecto.
 *
 * Si manana el SUT cambia de puerto, se toca AQUI y en ningun otro archivo.
 * Es la misma idea que el config.properties del viernes, en pequeno.
 */
public final class Paginas {

    private Paginas() { }

    /** Se puede sobreescribir con -DbaseUrl=... sin tocar codigo. */
    public static final String BASE =
            System.getProperty("baseUrl", "http://localhost:8080");

    public static final String LOGIN     = BASE + "/";
    public static final String REGISTRO  = BASE + "/register.html";
    public static final String PROYECTOS = BASE + "/projects.html";
    public static final String AYUDA     = BASE + "/help.html";
}
