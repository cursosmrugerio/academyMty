package com.taskflow.qa.tests;

import com.taskflow.qa.utils.Paginas;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.openqa.selenium.WebDriver;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Los tres smoke tests del dia 1.
 *
 * Un smoke test no comprueba que la aplicacion este bien: comprueba que
 * este VIVA. Si estos tres fallan, no tiene sentido correr los demas.
 */
class SmokeTest {

    private WebDriver driver;

    @BeforeEach
    void abrirNavegador() {
        // TODO 1: crear el driver de Chrome.
        //         Recuerda: Selenium Manager resuelve el driver solo.
        //         NO hace falta System.setProperty ni WebDriverManager.
    }

    @AfterEach
    void cerrarNavegador() {
        // TODO 2: cerrar el navegador.
        //         Si no lo haces, vas a acabar la manana con quince Chrome
        //         abiertos y la laptop de rodillas. Protegete del null.
    }

    @Test
    @DisplayName("La aplicacion responde y el titulo es el esperado")
    void laAplicacionResponde() {
        // TODO 3: ir a Paginas.LOGIN y comprobar el titulo de la pagina.
        //         Antes de escribirlo: abre la pagina a mano y mira que titulo tiene.
    }

    @Test
    @DisplayName("La pantalla de login muestra sus tres controles")
    void elLoginTieneSusControles() {
        // TODO 4: comprobar que se ven el campo de usuario, el de contrasena
        //         y el boton de entrar.
        //         Valida cada localizador en DevTools con $$(...) ANTES de escribirlo.
    }

    @Test
    @DisplayName("Se navega a la pagina de registro y se vuelve atras")
    void navegacionEntrePaginas() {
        // TODO 5: navegar al registro, comprobar la URL, y volver atras.
        //         Pista: driver.navigate() tiene mas metodos que to().
    }
}
