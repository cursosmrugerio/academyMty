package com.taskflow.qa.tests;

import com.taskflow.qa.utils.Paginas;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.openqa.selenium.WebDriver;

/**
 * Los OCHO objetivos de localizacion del dia 1.
 *
 * REGLA DE ORO: ningun localizador se escribe aqui sin haberlo validado antes
 * en la consola de DevTools con $$("...") o $x("..."). Si devuelve uno, sirve.
 * Si devuelve cero o siete, todavia no.
 *
 * Y por cada objetivo tienes que rellenar una fila del README diciendo QUE
 * estrategia elegiste y POR QUE esa y no otra. Sin esa tabla, esto es copiar
 * selectores y no cuenta como entregado.
 *
 * Hoy solo se ENCUENTRA. No se hace click en nada que cambie la pagina: eso es
 * manana. Por eso hoy no hace falta ni una sola espera.
 */
class LocalizacionTest {

    private WebDriver driver;

    @BeforeEach
    void abrirNavegador() {
        // TODO: driver + ir a Paginas.LOGIN
    }

    @AfterEach
    void cerrarNavegador() {
        // TODO
    }

    @Test
    @DisplayName("1 - El campo de usuario, por su data-testid")
    void campoUsuario() {
        // TODO
    }

    @Test
    @DisplayName("2 - El boton de entrar")
    void botonEntrar() {
        // TODO
    }

    @Test
    @DisplayName("3 - El campo de contrasena es de tipo password")
    void campoContrasenaEsPassword() {
        // TODO: localizalo por su TIPO, no por su data-testid.
        //       Es el unico objetivo donde se pide una estrategia concreta,
        //       para que compares como se siente.
    }

    @Test
    @DisplayName("4 - El contenedor de errores existe y esta vacio")
    void contenedorDeErroresVacio() {
        // TODO 4a: este div NO tiene data-testid. Es de los pocos elementos de
        //          la UI sin contrato, asi que tienes que tirar de otra cosa.
        //          (Asi es la vida real cuando el frontend no dejo testids.)
        //          Encuentralo y comprueba que esta vacio.
        //
        // TODO 4b: ahora busca [data-testid='login-error'] y comprueba que
        //          NO EXISTE todavia. Lo crea el JavaScript cuando un login
        //          falla. Guarda la observacion: manana es la diferencia entre
        //          "existe" y "se ve", y a mucha gente le cuesta tiempo.
    }

    @Test
    @DisplayName("5 - El enlace de registro, por su texto")
    void enlaceDeRegistro() {
        // TODO: por su texto. Hay dos localizadores para esto: uno exige el
        //       texto completo y otro se conforma con un trozo.
        //       OJO: el texto de ese enlace lleva ACENTO. Si eliges el que
        //       exige el texto completo, tiene que ser exacto, acento incluido.
    }

    @Test
    @DisplayName("6 - El formulario de login tiene exactamente dos campos de texto")
    void dosCamposDeTexto() {
        // TODO: aqui no buscas UNO, buscas TODOS.
        //       ¿Que metodo del driver devuelve una lista?
    }

    @Test
    @DisplayName("7 - El boton es hijo DIRECTO del formulario")
    void botonEsHijoDirectoDelFormulario() {
        // TODO: la diferencia entre "form button" y "form > button".
        //       Pruebalos los dos en DevTools antes de decidir.
    }

    @Test
    @DisplayName("8 - Un elemento inexistente devuelve lista vacia, no excepcion")
    void elementoInexistente() {
        // TODO: busca algo que no existe.
        //       findElement lanza NoSuchElementException. findElements NO.
        //       Comprueba la diferencia: es como se pregunta "¿existe?" sin
        //       que el test reviente.
    }
}
