package com.taskflow.qa.tests;

import com.taskflow.qa.utils.CapturaAlFallo;
import com.taskflow.qa.utils.DriverFactory;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.ExtendWith;
import org.openqa.selenium.WebDriver;

/**
 * El ciclo de vida del navegador, EN UN SOLO SITIO.
 *
 * El miercoles y el jueves cada clase repetia su @BeforeEach y su @AfterEach.
 * Era intencional: el dolor de haberlo copiado es lo que hace que hoy se
 * entienda por que existe esta clase. Ahora se borra de todas partes.
 */
// TODO: engancha aqui la extension que guarda una captura cuando un test falla.
public abstract class BaseTest {

    protected WebDriver driver;

    @BeforeEach
    void abrirNavegador() {
        // TODO
    }

    @AfterEach
    void cerrarNavegador() {
        // TODO
    }
}
