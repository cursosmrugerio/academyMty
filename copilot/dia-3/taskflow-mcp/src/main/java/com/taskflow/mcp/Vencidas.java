package com.taskflow.mcp;

import java.time.LocalDate;
import java.util.List;

/**
 * La regla «tarea vencida», separada de todo lo demás para poder probarla sin la API.
 *
 * Es la MISMA regla que Task.estaVencida() de taskflow-api: tiene fecha límite, la fecha es anterior
 * a hoy y el estado no es DONE. Se copia aquí porque este servidor solo ve el JSON de GET /tasks, no
 * las clases de la API. Por eso no depende de GET /tasks/overdue: funciona aunque ese endpoint no exista.
 *
 * «Hoy» llega como parámetro en vez de llamar a LocalDate.now() dentro: así el test fija la fecha y el
 * resultado no cambia según el día en que lo corras.
 */
public final class Vencidas {

    private Vencidas() {
        // solo métodos estáticos
    }

    /** true si la tarea tiene fecha, la fecha es anterior a {@code hoy} y no está DONE. */
    public static boolean estaVencida(Tarea tarea, LocalDate hoy) {
        return tarea.dueDate() != null
                && tarea.dueDate().isBefore(hoy)
                && !"DONE".equals(tarea.status());
    }

    /** Las tareas vencidas de la lista, en el mismo orden en que llegaron. */
    public static List<Tarea> filtrar(List<Tarea> tareas, LocalDate hoy) {
        return tareas.stream()
                .filter(t -> estaVencida(t, hoy))
                .toList();
    }
}
