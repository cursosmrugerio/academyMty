package com.taskflow.qa.utils;

import java.io.IOException;
import java.io.InputStream;
import java.time.Duration;
import java.util.Properties;

/**
 * La configuracion sale del codigo.
 *
 * Orden de precedencia: propiedad de sistema (-DbaseUrl=...) primero, y si no,
 * lo que diga config.properties. Asi el valor por defecto esta versionado y
 * cualquiera puede cambiarlo sin tocar una linea de Java.
 *
 * Es exactamente la leccion del lunes en AWS: de H2 a RDS cambiando variables,
 * sin recompilar. Aqui es un .properties en vez de variables de entorno; la
 * idea es la misma.
 */
public final class Config {

    private static final Properties PROPS = cargar();

    private Config() { }

    private static Properties cargar() {
        Properties p = new Properties();
        try (InputStream in = Config.class.getResourceAsStream("/config.properties")) {
            if (in != null) p.load(in);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer config.properties", e);
        }
        return p;
    }

    private static String valor(String clave) {
        return System.getProperty(clave, PROPS.getProperty(clave));
    }

    public static String baseUrl()       { return valor("baseUrl"); }
    public static boolean headless()     { return Boolean.parseBoolean(valor("headless")); }
    public static Duration timeout()     { return Duration.ofSeconds(Long.parseLong(valor("timeoutSegundos"))); }
}
