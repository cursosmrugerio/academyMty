package auditoria;

import java.util.ArrayList;
import java.util.List;

/** Libro mayor: una linea por afirmacion, con su origen. Sin agregados. */
final class Libro {
    record Linea(String familia, String origen, String afirmacion, String esperado,
                 String obtenido, boolean cumple) {}

    static final List<Linea> LINEAS = new ArrayList<>();

    static void anota(String familia, String origen, String afirmacion,
                      Object esperado, Object obtenido) {
        boolean ok = String.valueOf(esperado).equals(String.valueOf(obtenido));
        LINEAS.add(new Linea(familia, origen, afirmacion,
                String.valueOf(esperado), String.valueOf(obtenido), ok));
    }

    static void imprime() {
        System.out.println("\n" + "=".repeat(118));
        System.out.printf("%-9s %-16s %-46s %-12s %-12s %s%n",
                "FAMILIA", "ORIGEN", "AFIRMACION", "ESPERADO", "OBTENIDO", "");
        System.out.println("=".repeat(118));
        for (Linea l : LINEAS) {
            System.out.printf("%-9s %-16s %-46s %-12s %-12s %s%n",
                    l.familia, l.origen, corta(l.afirmacion, 46),
                    corta(l.esperado, 12), corta(l.obtenido, 12),
                    l.cumple ? "OK" : "<<< FALLA");
        }
        long malas = LINEAS.stream().filter(l -> !l.cumple).count();
        System.out.println("=".repeat(118));
        System.out.printf("TOTAL %d afirmaciones · %d cumplen · %d FALLAN%n",
                LINEAS.size(), LINEAS.size() - malas, malas);
    }

    private static String corta(String s, int n) {
        return s.length() <= n ? s : s.substring(0, n - 1) + "…";
    }
}
