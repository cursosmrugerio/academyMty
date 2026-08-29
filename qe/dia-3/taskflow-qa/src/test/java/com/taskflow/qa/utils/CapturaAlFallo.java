package com.taskflow.qa.utils;

import org.junit.jupiter.api.extension.ExtensionContext;
import org.junit.jupiter.api.extension.TestWatcher;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Guarda una captura cuando un test se pone rojo.
 *
 * Es el primer entregable de la semana que sirve para depurar de verdad: cuando
 * la suite falle en un servidor donde nadie esta mirando, la captura es lo unico
 * que va a haber. Un NoSuchElementException sin imagen no dice si la pagina no
 * cargo, si la sesion expiro, o si simplemente cambio el boton.
 */
public class CapturaAlFallo implements TestWatcher {

    private static final Path CARPETA = Path.of("target", "capturas");
    private static final DateTimeFormatter SELLO =
            DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");

    @Override
    public void testFailed(ExtensionContext contexto, Throwable causa) {
        WebDriver driver = DriverFactory.actual();
        if (!(driver instanceof TakesScreenshot camara)) {
            return;   // sin driver vivo no hay nada que capturar
        }
        try {
            Files.createDirectories(CARPETA);
            String nombre = contexto.getRequiredTestClass().getSimpleName()
                    + "." + contexto.getRequiredTestMethod().getName()
                    + "-" + LocalDateTime.now().format(SELLO) + ".png";
            Path destino = CARPETA.resolve(nombre);
            Files.write(destino, camara.getScreenshotAs(OutputType.BYTES));
            System.out.println("[captura] " + destino.toAbsolutePath());
        } catch (Exception e) {
            // Que fallar la captura NUNCA tape el fallo real del test.
            System.err.println("[captura] no se pudo guardar: " + e.getMessage());
        }
    }
}
