package com.taskflow.qa.tests;

import com.taskflow.qa.utils.Paginas;
import com.taskflow.qa.utils.Sesion;
import org.junit.jupiter.api.*;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.*;

/**
 * EL METODO DE DIAGNOSTICO CUANDO UN CLICK NO HACE NADA.
 *
 * Este test nacio de un caso real: durante dos dias, el click nativo sobre el
 * enlace "Abrir" no navegaba. Se probaron y descartaron, midiendo, el overlay,
 * el re-render, target="_blank" y la desalineacion driver/navegador.
 *
 * La causa aparecio el 29-ago-2026 y no estaba en el enlace: entrar PULSANDO el
 * formulario de login deja el documento sin foco, y Chrome no entrega input
 * sintetico a un documento sin foco. A partir de ahi no llegaba NINGUN click, en
 * ninguna pagina, y no se recuperaba con refresh ni con driver.get. Sembrando la
 * sesion (ver utils/Sesion), el click funciona.
 *
 * El test se conserva —y ahora PASA— porque lo que ensena no es el bug: son los
 * cuatro pasos con los que se acorrala un click que no hace nada. Ese orden es
 * lo que evita perder dos dias, y el orden importa: se descarta lo barato antes
 * de sospechar de lo caro.
 */
class NavegacionPorClickTest {

    private WebDriver driver;
    private WebDriverWait wait;

    @BeforeEach
    void abrirNavegador() {
        driver = new ChromeDriver();
        wait = new WebDriverWait(driver, Duration.ofSeconds(15));
        entrar();
    }

    @AfterEach
    void cerrarNavegador() {
        if (driver != null) driver.quit();
    }

    @Test
    @DisplayName("Diagnostico completo de un click que no hace nada")
    void diagnosticoDelClickQueNoNavega() {
        WebElement enlace = wait.until(ExpectedConditions.presenceOfElementLocated(
                By.cssSelector("[data-testid^='link-project-']")));

        // --- Paso 1: ¿existe y se ve? ---
        assertTrue(enlace.isDisplayed(), "si esto falla, el problema es otro");

        // --- Paso 2: ¿hay algo ENCIMA? ---
        // Esta es la pregunta que elementToBeClickable NO responde, y la que
        // explica la mayoria de los clicks que "no hacen nada".
        wait.until(ExpectedConditions.invisibilityOfElementLocated(
                By.cssSelector("[data-testid='spinner']")));
        String receptor = (String) ((JavascriptExecutor) driver).executeScript(
                "var r = arguments[0].getBoundingClientRect();"
              + "var e = document.elementFromPoint(r.left + r.width/2, r.top + r.height/2);"
              + "return e ? (e.dataset.testid || e.tagName) : 'nada';", enlace);
        assertTrue(receptor.startsWith("link-project-"),
                "Si aqui saliera 'spinner' o el testid de un modal, el problema seria un OVERLAY. "
              + "Sale el propio enlace: " + receptor);

        // --- Paso 3: ¿como se ENTRO a la sesion? ---
        // La pregunta que faltaba, y la que resolvio el caso. Entrar pulsando el
        // formulario de login dejaba el documento sin foco, y a partir de ahi no
        // llegaba ningun click: ni error, ni evento. Por eso este test entra
        // sembrando la sesion (ver utils/Sesion).
        //
        // Se IMPRIME, no se asevera: document.hasFocus() es un CORRELATO, no la
        // causa. En headless es false y los clicks funcionan igual, y forzarlo con
        // window.focus() lo pone en true sin arreglar nada. Aseverar un correlato
        // es fabricar un test flaky —y este lo fue, hasta que se midio.
        System.out.println("   [diagnostico] document.hasFocus() = "
                + ((JavascriptExecutor) driver).executeScript("return document.hasFocus();"));

        // --- Paso 4: ahora si, el click nativo. Y navega. ---
        enlace.click();
        wait.until(ExpectedConditions.urlContains("project.html"));
        assertTrue(wait.until(ExpectedConditions.visibilityOfElementLocated(
                By.cssSelector("[data-testid='task-table']"))).isDisplayed());

        // Nota para el que venga: cuando esto fallaba, el arreglo facil era un
        // click por JavascriptExecutor. Habria funcionado, y habria sido un ERROR:
        // ese click salta el camino del usuario real, y si el enlace estuviera
        // tapado o deshabilitado pasaria igual, tapando un bug de verdad. Es el
        // ultimo recurso, nunca el primero.
    }

    private void entrar() {
        // Se siembra la sesion en vez de pulsar el formulario: ver utils/Sesion.
        Sesion.sembrar(driver, "ana", "ana123");
        wait.until(ExpectedConditions.urlContains("projects"));
    }
}
