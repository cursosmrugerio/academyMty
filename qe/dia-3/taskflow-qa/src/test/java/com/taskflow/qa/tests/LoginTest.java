package com.taskflow.qa.tests;

import com.taskflow.qa.pages.LoginPage;
import com.taskflow.qa.pages.ProyectosPage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Reescribe aqui los tests de login del miercoles, ahora contra los page objects.
 * Ponlos al lado de los de entonces y comparalos: si el de hoy no se entiende
 * sin saber Selenium, todavia no esta bien.
 */
class LoginTest extends BaseTest {

    @Test
    @DisplayName("Un login valido lleva a la lista de proyectos")
    void loginValido() {
        // TODO
    }

    @Test
    @DisplayName("Un login invalido muestra un mensaje de error")
    void loginInvalido() {
        // TODO
    }
}
