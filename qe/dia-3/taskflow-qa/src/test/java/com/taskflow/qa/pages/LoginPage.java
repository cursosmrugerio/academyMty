package com.taskflow.qa.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;

public class LoginPage extends BasePage {

    // TODO: los localizadores de esta pagina, como constantes privadas.
    //       Son los mismos que usaste el miercoles; ahora viven AQUI y en
    //       ningun otro sitio.

    public LoginPage(WebDriver driver) {
        super(driver);
    }

    public LoginPage abrir() {
        irA("/");
        return this;
    }

    /**
     * ESTE VIENE ESCRITO. No es un ejercicio de Selenium, es una leccion:
     *
     * Entra SIN pasar por el formulario, pidiendo el token al API y sembrandolo
     * en localStorage, que es lo mismo que hace la UI cuando el login funciona.
     * Uselo en TODOS los tests que no prueben el login.
     *
     * Dos razones:
     * 1. El login se prueba UNA vez, en LoginTest. Repetirlo antes de cada test
     *    de proyectos y tareas no prueba nada nuevo y multiplica el tiempo.
     * 2. Y la cara: completar el formulario deja el documento SIN FOCO, y Chrome
     *    no entrega input sintetico a un documento sin foco. A partir de ahi
     *    NINGUN click de Selenium vuelve a llegar, en ninguna pagina, y no se
     *    recupera con refresh ni con driver.get. Medido el 29-ago-2026:
     *    sembrando, 5 de 5 clicks funcionan; pulsando el formulario, 0 de 5.
     */
    public ProyectosPage entrarSembrando(String usuario, String password) {
        irA("/");
        ((JavascriptExecutor) driver).executeScript(
                "const r = await fetch('/auth/login', {method:'POST'," +
                " headers:{'Content-Type':'application/json'}," +
                " body: JSON.stringify({username: arguments[0], password: arguments[1]})});" +
                "const d = await r.json();" +
                "localStorage.setItem('tf.token', d.token || d.accessToken || d.jwt);" +
                "localStorage.setItem('tf.username', arguments[0]);",
                usuario, password);
        irA("/projects.html");
        return new ProyectosPage(driver).esperarACargar();
    }

    /**
     * TODO: escribir usuario y password, pulsar entrar, y devolver la pagina
     *       de proyectos YA CARGADA.
     *
     *       Este SI pulsa el formulario, porque aqui el formulario es lo que se
     *       prueba. Solo lo usa LoginTest.
     *
     * Fijate en que devuelve ProyectosPage y no void: asi el test se lee como
     * el recorrido del usuario.
     */
    public ProyectosPage entrar(String usuario, String password) {
        throw new UnsupportedOperationException("TODO");
    }

    /**
     * TODO: el login que FALLA. Devuelve el TEXTO del mensaje de error.
     *
     * ¿Por que dos metodos y no uno? Piensalo antes de escribirlo: ¿que pasaria
     * si `entrar` llevara dentro un assertTrue de que llegamos a proyectos?
     * Ese es el motivo de que las aserciones sean del test.
     */
    public String entrarEsperandoError(String usuario, String password) {
        throw new UnsupportedOperationException("TODO");
    }
}
