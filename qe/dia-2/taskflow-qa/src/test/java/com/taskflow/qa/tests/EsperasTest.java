package com.taskflow.qa.tests;

import com.taskflow.qa.utils.Paginas;
import org.junit.jupiter.api.*;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;
import java.util.UUID;

/**
 * ESPERAS — lo mas importante de la semana.
 *
 * La UI tiene un retraso artificial de 1,5 s en cada render que viene de un
 * fetch. Sin esperas explicitas, estos cinco tests fallan de forma REPRODUCIBLE.
 *
 * Pruebalo tu: en la consola de DevTools,
 *     localStorage.setItem('tf.delayMs', '3000');
 * y vuelve a correr. Un test con sleep(3000) se cae; uno con wait, no.
 *
 * DECISION DEL CURSO, y va documentada en tu README:
 *   - implicit wait: DESACTIVADO (no toques driver.manage().timeouts())
 *   - explicit wait: SIEMPRE
 *
 * Y recuerda de donde viene esto: es el verificar.sh que escribiste el martes.
 */
class EsperasTest {

    private WebDriver driver;
    private WebDriverWait wait;

    @BeforeEach
    void abrirNavegador() {
        // TODO: driver + wait de 15 s + entrar
    }

    @AfterEach
    void cerrarNavegador() {
        // TODO
    }

    @Test
    @DisplayName("1 - visibilityOf: la lista de proyectos tarda en pintarse")
    void esperarQueAparezca() {
        // TODO
    }

    @Test
    @DisplayName("2 - invisibilityOf: el spinner se va cuando termina la carga")
    void esperarQueDesaparezca() {
        // TODO: ¿que devuelve invisibilityOf si el elemento NO existe?
        //       Averigualo: es justo lo que la hace segura aqui.
    }

    @Test
    @DisplayName("3 - elementToBeClickable: visible no es lo mismo que pulsable")
    void esperarQueSePuedaPulsar() {
        // ⚠ TRAMPA VERIFICADA: elementToBeClickable NO mira si hay algo ENCIMA.
        //   El spinner cubre la pantalla y el click se lo come el overlay
        //   (ElementClickInterceptedException). ¿Que tienes que esperar ANTES?
        //
        // TODO 1: esperar a lo que haga falta, y pulsar "Nuevo Proyecto".
        // TODO 2: comprobar que el modal aparece. Lo crea el JavaScript: no
        //         existe hasta ahora.
    }

    @Test
    @DisplayName("4 - El toast de exito aparece tras crear un proyecto")
    void esperarElToast() {
        // TODO: crea un proyecto y espera el toast.
        //
        // ⚠ DOS COSAS VERIFICADAS:
        //   (a) el testid es 'toast', NO 'toast-success'. El tipo va en la
        //       CLASE CSS. (El _spec.md de la UI promete toast-success y no existe.)
        //   (b) el toast se borra solo a los 3 segundos: aseveralo AL VUELO.
    }

    @Test
    @DisplayName("5 - El proyecto recien creado aparece en la lista")
    void esperarLaFilaNueva() {
        // TODO: crea un proyecto con nombre UNICO y espera a verlo en la lista.
        //
        // ¿Por que unico? Porque si dos ejecuciones crean el mismo nombre, la
        // segunda falla. Es la tercera causa de flaky: dependencia de datos.
        // Pista: UUID.randomUUID().toString().substring(0, 8)
        //
        // ⚠ Y espera primero el MODAL, y solo despues el campo que vive dentro.
        //   Esperar el campo directamente funciona A VECES — y "a veces" es la
        //   definicion de flaky.
    }

    private void entrar() {
        // TODO
    }
}
