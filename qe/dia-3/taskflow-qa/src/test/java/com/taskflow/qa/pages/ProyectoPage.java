package com.taskflow.qa.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.Select;

import java.util.List;

/**
 * TODO: escribe esta clase entera siguiendo el patron de LoginPage.
 *
 * Recuerda la regla de oro: devuelve DATOS o devuelve OTRO PAGE OBJECT.
 * Nunca un WebElement.
 *
 * ProyectoPage: nombre del proyecto, lista de tareas, filtrar por estado
 *   (<select> nativo -> clase Select), ordenar (desplegable CUSTOM -> dos
 *   clicks), y nuevaTarea() que devuelve el modal.
 *
 * TareaModal: es un COMPONENTE, no una pagina — no tiene URL propia. Por eso
 *   va en su clase: si no, ProyectoPage acaba con treinta metodos, que es como
 *   mueren los page objects mal cortados.
 */
public class ProyectoPage extends BasePage {

    public ProyectoPage(WebDriver driver) {
        super(driver);
    }
}
