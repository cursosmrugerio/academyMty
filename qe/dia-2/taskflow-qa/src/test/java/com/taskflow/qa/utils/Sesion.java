package com.taskflow.qa.utils;

import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;

/**
 * Entrar SIN pasar por el formulario de login.
 *
 * Se pide el token al API y se deja sembrado en localStorage, que es
 * exactamente lo que hace la propia UI cuando el login tiene exito.
 *
 * DOS razones, y la segunda costo una manana entera de medir:
 *
 * 1. El login solo se prueba donde se prueba el login. Repetirlo antes de cada
 *    test de otra cosa no prueba nada nuevo y multiplica el tiempo de la suite.
 *
 * 2. Completar el formulario deja el documento SIN FOCO, y Chrome no entrega
 *    input sintetico a un documento sin foco: a partir de ese momento NINGUN
 *    click de Selenium vuelve a llegar a la pagina, en ninguna pagina, y no se
 *    recupera con refresh, ni con driver.get, ni con switchTo. Medido el
 *    29-ago-2026: sembrando la sesion, 5 de 5 clicks funcionan; pulsando el
 *    formulario, 0 de 5.
 */
public final class Sesion {

    private Sesion() { }

    public static void sembrar(WebDriver driver, String usuario, String password) {
        driver.get(Paginas.LOGIN);
        ((JavascriptExecutor) driver).executeScript(
                "const r = await fetch('/auth/login', {method:'POST'," +
                " headers:{'Content-Type':'application/json'}," +
                " body: JSON.stringify({username: arguments[0], password: arguments[1]})});" +
                "const d = await r.json();" +
                "localStorage.setItem('tf.token', d.token || d.accessToken || d.jwt);" +
                "localStorage.setItem('tf.username', arguments[0]);",
                usuario, password);
        driver.get(Paginas.PROYECTOS);
    }
}
