package com.taskflow.qa.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

import java.util.List;

public class ProyectosPage extends BasePage {

    // TODO: localizadores

    public ProyectosPage(WebDriver driver) {
        super(driver);
    }

    /**
     * TODO: esperar a que la pagina este lista DE VERDAD.
     *
     * ⚠ LA TRAMPA MAS CARA DEL DIA:
     *   NO esperes por [data-testid='project-list']. Ese div esta en el HTML
     *   ESTATICO y ya es visible cuando la pagina responde, ANTES de que el
     *   JavaScript haya pintado nada. Esperar por el es NO ESPERAR.
     *
     *   Espera por algo que solo exista cuando el render ha terminado.
     *   ¿Que elemento cumple eso en esta pagina?
     *
     * Y despues, el spinner.
     */
    ProyectosPage esperarACargar() {
        throw new UnsupportedOperationException("TODO");
    }

    public boolean estaVisible() {
        throw new UnsupportedOperationException("TODO");
    }

    public List<String> nombres() {
        throw new UnsupportedOperationException("TODO");
    }

    public boolean contiene(String nombre) {
        throw new UnsupportedOperationException("TODO");
    }

    public ProyectosPage crearProyecto(String nombre) {
        // TODO: spinner -> pulsar Nuevo -> esperar el MODAL -> escribir -> guardar
        //       -> esperar a ver el nombre en la lista.
        //       (El modal primero y el campo despues: el campo vive dentro.)
        throw new UnsupportedOperationException("TODO");
    }

    /**
     * TODO: abrir el primer proyecto.
     *
     * Se navega por URL en vez de pulsar el enlace. NO es un rodeo: aqui lo que
     * se prueba es lo que pasa DENTRO del proyecto, no el viaje. Lee el href del
     * primer enlace y navega a el.
     *
     * Y si no hay ningun proyecto, lanza un error que se entienda: quien lo lea
     * a las 8 de la manana tiene que saber que le falto arrancar el SUT con
     * -Dspring-boot.run.profiles=h2, que es lo que siembra los datos.
     */
    public ProyectoPage abrirPrimerProyecto() {
        throw new UnsupportedOperationException("TODO");
    }
}
