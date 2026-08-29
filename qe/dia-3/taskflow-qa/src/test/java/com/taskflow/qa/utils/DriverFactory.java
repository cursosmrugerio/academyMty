package com.taskflow.qa.utils;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;

/**
 * Un solo sitio donde se crea y se destruye el navegador.
 */
public final class DriverFactory {

    // El ThreadLocal no es adorno: permite que CapturaAlFallo encuentre el driver
    // del test que acaba de romperse sin que nadie se lo pase a mano.
    private static final ThreadLocal<WebDriver> DRIVER = new ThreadLocal<>();

    private DriverFactory() { }

    public static WebDriver crear() {
        // TODO 1: crear ChromeOptions y anadir --headless=new SOLO si Config.headless()
        //
        // TODO 2: fijar --window-size=1400,1000 SIEMPRE, no solo en headless.
        //         ¿Por que siempre? Corre la suite en los dos modos sin esta linea
        //         y lo vas a descubrir por las malas.
        //
        // TODO 3: crear el driver, GUARDARLO en el ThreadLocal, y devolverlo.
        throw new UnsupportedOperationException("TODO: DriverFactory.crear()");
    }

    /** Lo usa la captura al fallo. Devuelve null si no hay driver vivo. */
    public static WebDriver actual() {
        return DRIVER.get();
    }

    public static void cerrar() {
        // TODO 4: cerrar el driver si existe.
        //         Y ojo: hay que hacer DRIVER.remove(). Si no, el ThreadLocal se
        //         queda con un driver muerto y el siguiente test hereda basura.
        throw new UnsupportedOperationException("TODO: DriverFactory.cerrar()");
    }
}
