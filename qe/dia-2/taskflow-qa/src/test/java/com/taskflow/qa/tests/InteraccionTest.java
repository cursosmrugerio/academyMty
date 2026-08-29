package com.taskflow.qa.tests;

import com.taskflow.qa.utils.Paginas;
import org.junit.jupiter.api.*;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

/**
 * Interaccion: texto, clicks, y los DOS tipos de desplegable.
 */
class InteraccionTest {

    private WebDriver driver;
    private WebDriverWait wait;

    @BeforeEach
    void abrirNavegador() {
        // TODO
    }

    @AfterEach
    void cerrarNavegador() {
        // TODO
    }

    @Test
    @DisplayName("Login valido: escribir y enviar lleva a la lista de proyectos")
    void loginValido() {
        // TODO: ana / ana123. ¿Como compruebas que llegaste? La URL cambia.
    }

    @Test
    @DisplayName("Login invalido: aparece el mensaje de error que AYER no existia")
    void loginInvalido() {
        // TODO: contrasena mala, y comprueba el mensaje.
        //
        //       AYER comprobaste que [data-testid='login-error'] NO existia.
        //       Lo crea el JavaScript justo ahora, asi que NO esta cuando la
        //       pagina responde: hay que ESPERARLO. Buscarlo sin esperar es la
        //       primera causa de test intermitente.
    }

    @Test
    @DisplayName("clear(): sin el, sendKeys CONCATENA en vez de sustituir")
    void clearAntesDeEscribir() {
        // TODO: escribe dos veces seguidas en el mismo campo SIN clear() y
        //       comprueba que valor tiene. Luego con clear().
        //       Pista para leer el valor: getDomProperty("value")
    }

    @Test
    @DisplayName("<select> NATIVO: la clase Select lo resuelve")
    void selectNativo() {
        // TODO: el filtro de estado del detalle de proyecto.
        //       selectByValue("DONE") y comprueba cual quedo seleccionado.
    }

    @Test
    @DisplayName("Desplegable CUSTOM: Select NO sirve, hay que abrir y elegir")
    void desplegableCustom() {
        // TODO 1: el de ordenar. ANTES de nada, comprueba que NO es un <select>
        //         y que pasarselo a Select lanza una excepcion. ¿Cual?
        //
        // TODO 2: abrelo con un click y elige "Prioridad".
        //
        // ⚠ TRAMPA VERIFICADA: antes de pulsar el boton de ordenar tienes que
        //   esperar a que el SPINNER desaparezca. elementToBeClickable NO mira
        //   si hay algo ENCIMA, y el overlay se come el click.
    }

    private void entrarYAbrirPrimerProyecto() {
        // TODO: igual que en XPathTest. Y al llegar al detalle, espera tambien
        //       a que el spinner se vaya: la tabla es HTML estatico y esta
        //       visible desde el primer instante, pero el spinner la TAPA.
    }
}
