package com.taskflow.mcp;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;

/**
 * La regla «vencida», sin Spring y sin la API: solo datos y una fecha fija.
 * Cada test es un caso de la regla de Task.estaVencida() de taskflow-api.
 */
class VencidasTest {

    private static final LocalDate HOY = LocalDate.of(2026, 9, 16);

    private static Tarea tarea(long id, String status, LocalDate dueDate) {
        return new Tarea(id, "Tarea " + id, null, status, "MED", 1L, null, dueDate);
    }

    @Test
    void fechaDeAyerYEnCursoEstaVencida() {
        assertThat(Vencidas.estaVencida(tarea(7, "IN_PROGRESS", HOY.minusDays(1)), HOY)).isTrue();
    }

    @Test
    void fechaPasadaPeroDoneNoEstaVencida() {
        assertThat(Vencidas.estaVencida(tarea(2, "DONE", HOY.minusDays(2)), HOY)).isFalse();
    }

    @Test
    void fechaDeHoyNoEstaVencida() {
        assertThat(Vencidas.estaVencida(tarea(1, "TODO", HOY), HOY)).isFalse();
    }

    @Test
    void sinFechaNoEstaVencida() {
        assertThat(Vencidas.estaVencida(tarea(5, "TODO", null), HOY)).isFalse();
    }

    @Test
    void conLaSemillaDeTaskflowSoloLaSieteEstaVencida() {
        // Las 9 tareas de DataSeeder (perfil h2), con sus fechas relativas a «hoy».
        List<Tarea> semilla = List.of(
                tarea(1, "TODO", HOY.plusDays(5)),
                tarea(2, "DONE", HOY.minusDays(2)),
                tarea(3, "IN_PROGRESS", HOY.plusDays(3)),
                tarea(4, "TODO", HOY.plusDays(7)),
                tarea(5, "TODO", null),
                tarea(6, "TODO", HOY.plusDays(10)),
                tarea(7, "IN_PROGRESS", HOY.minusDays(1)),
                tarea(8, "DONE", HOY.minusDays(5)),
                tarea(9, "IN_PROGRESS", null));

        assertThat(Vencidas.filtrar(semilla, HOY)).extracting(Tarea::id).containsExactly(7L);
    }
}
