package com.taskflow.qa.pages;

import com.taskflow.qa.utils.Config;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.util.List;

/**
 * Lo que comparten todas las paginas.
 *
 * AQUI VIVE LA ESPERA, una vez, para todo el framework.
 *
 * REGLA DE ORO, y se cumple en TODO el paquete pages/:
 *   un page object devuelve DATOS o devuelve OTRO PAGE OBJECT.
 *   Nunca un WebElement.
 */
public abstract class BasePage {

    protected final WebDriver driver;
    protected final WebDriverWait wait;

    protected BasePage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Config.timeout());
    }

    // ---- Estos dos van HECHOS: son el patron a imitar ----

    protected void click(By localizador) {
        wait.until(ExpectedConditions.elementToBeClickable(localizador)).click();
    }

    protected void escribir(By localizador, String texto) {
        WebElement campo = wait.until(ExpectedConditions.visibilityOfElementLocated(localizador));
        campo.clear();          // sendKeys CONCATENA: sin esto se escribe encima
        campo.sendKeys(texto);
    }

    // ---- Estos los escribes tu ----

    protected String textoDe(By localizador) {
        // TODO: esperar a que sea visible y devolver su texto.
        throw new UnsupportedOperationException("TODO");
    }

    protected boolean estaVisible(By localizador) {
        // TODO: devolver true si aparece a tiempo, false si no.
        //       PISTA: si no aparece, wait.until lanza TimeoutException. Y aqui
        //       "no apareció" es una RESPUESTA valida, no un fallo del test.
        throw new UnsupportedOperationException("TODO");
    }

    protected List<String> textosDe(By localizador) {
        // TODO: los textos de TODOS los que casen. ¿Que metodo del driver
        //       devuelve una lista y no lanza excepcion si no hay ninguno?
        throw new UnsupportedOperationException("TODO");
    }

    protected void esperarSinSpinner() {
        // TODO: esperar a que el spinner de TaskFlow DESAPAREZCA.
        //       Hace falta antes de pulsar nada en una pagina recien cargada:
        //       elementToBeClickable NO mira si hay algo ENCIMA.
        throw new UnsupportedOperationException("TODO");
    }

    protected void esperarTextoEn(By localizador, String texto) {
        // TODO
        throw new UnsupportedOperationException("TODO");
    }

    protected void irA(String ruta) {
        driver.get(Config.baseUrl() + ruta);
    }
}
