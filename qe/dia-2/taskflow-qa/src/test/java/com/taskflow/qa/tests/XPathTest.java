package com.taskflow.qa.tests;

import com.taskflow.qa.utils.Paginas;
import org.junit.jupiter.api.*;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

/**
 * XPath: SOLO donde CSS no llega.
 *
 * Los dos casos que CSS no cubre:
 *   1. buscar por TEXTO
 *   2. SUBIR o moverse de lado en el arbol
 *
 * Valida cada XPath en DevTools con $x("...") ANTES de escribirlo aqui.
 */
class XPathTest {

    private WebDriver driver;
    private WebDriverWait wait;

    @BeforeEach
    void abrirNavegador() {
        // TODO: driver + un WebDriverWait de 10 segundos
    }

    @AfterEach
    void cerrarNavegador() {
        // TODO
    }

    @Test
    @DisplayName("Por texto exacto: el boton de entrar")
    void porTextoExacto() {
        // TODO: //button[text()='...']
    }

    @Test
    @DisplayName("Por texto parcial con contains()")
    void porTextoParcial() {
        // TODO: en la pagina de registro, algo que contenga 'egistr'.
        //       ¿Por que aqui conviene contains() y no text()?
    }

    @Test
    @DisplayName("normalize-space(): el HTML real viene con espacios sobrantes")
    void conNormalizeSpace() {
        // TODO: el mismo boton de antes, pero con normalize-space().
        //       Pruebalo tambien SIN el en DevTools sobre un elemento cuyo texto
        //       este en varias lineas: vas a ver por que existe.
    }

    @Test
    @DisplayName("Ejes: de una tarea a SU boton de borrar (imposible con CSS)")
    void ejeParentDesdeElTexto() {
        // TODO 1: llega al detalle del primer proyecto (usa el helper de abajo).
        //
        // TODO 2: coge el titulo de la primera tarea de la tabla.
        //
        // TODO 3: desde ESE TEXTO, sube a la fila y baja a su boton de borrar.
        //         Pista: //td[...]/parent::tr//button[starts-with(@data-testid,'...')]
        //
        //         Este es EL ejercicio del bloque. Intenta hacerlo con CSS
        //         primero, para comprobar por ti mismo que no se puede.
    }

    @Test
    @DisplayName("El XPath absoluto encuentra lo mismo, y por eso enganna")
    void xpathAbsolutoEsFragil() {
        // TODO: localiza el boton de login de DOS formas —por data-testid y por
        //       una ruta tipo //form/button— y comprueba que hoy encuentran lo mismo.
        //
        //       Luego, en DevTools, mete un <div> en medio del formulario y vuelve
        //       a probar los dos selectores a mano. ¿Cual sobrevive?
    }

    /**
     * Entra y abre el primer proyecto.
     *
     * OJO: NO se llega al detalle haciendo click en el enlace "Abrir".
     * Lee NavegacionPorClickTest para saber por que — y de paso aprende el
     * metodo de diagnostico cuando un click no hace nada.
     *
     * Aqui se navega por URL a proposito: en este test lo que se prueba es
     * XPath, NO el viaje entre paginas.
     */
    private void entrarYAbrirPrimerProyecto() {
        // TODO: login con ana/ana123, leer el href del primer link-project-,
        //       navegar a el con driver.get(), y esperar a que la tabla tenga filas.
    }
}
