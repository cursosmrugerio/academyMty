package auditoria;

import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.*;

import java.time.Duration;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * RONDA 2 del arnes. La ronda 1 tenia cuatro checks mal escritos:
 *   - pedia /projects.html sin sesion (ui.js redirige al login)
 *   - miraba el spinner DESPUES del render, cuando ya se habia ido
 *   - usaba getDomAttribute("href"), que devuelve el atributo literal relativo
 *   - afirmaba que 'form button' y 'form > button' se distinguen aqui (no lo hacen,
 *     y el material tampoco lo afirma: es NOTA, no fallo)
 *
 * Cada check va en su try/catch para que un fallo no tape a los siguientes.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AuditoriaDelMaterialTest {

    static final String BASE = System.getProperty("baseUrl", "http://localhost:8080");
    static WebDriver d;
    static WebDriverWait wait;

    @BeforeAll static void abrir() {
        exigirSutVivo();
        ChromeOptions o = new ChromeOptions();
        if (!"false".equals(System.getProperty("headless"))) o.addArguments("--headless=new");
        o.addArguments("--window-size=1400,1000");
        d = new ChromeDriver(o);
        wait = new WebDriverWait(d, Duration.ofSeconds(20));
    }

    /** Sin SUT no hay auditoria, y el fallo tiene que decirlo en una linea, no en cien. */
    private static void exigirSutVivo() {
        try {
            var con = (java.net.HttpURLConnection) java.net.URI.create(BASE + "/").toURL().openConnection();
            con.setConnectTimeout(3000);
            con.setReadTimeout(3000);
            if (con.getResponseCode() / 100 != 2) throw new IllegalStateException("HTTP " + con.getResponseCode());
        } catch (Exception e) {
            throw new IllegalStateException(
                    "El SUT no responde en " + BASE + " (" + e.getMessage() + ").\n"
                  + "        Arrancalo asi, desde la raiz del repo:\n"
                  + "          cd taskflow-api && mvn spring-boot:run -Dspring-boot.run.profiles=h2\n"
                  + "        O apunta a otro sitio:  mvn test -DbaseUrl=http://host:puerto", e);
        }
    }

    @AfterAll static void cerrar() {
        if (d != null) d.quit();
        Libro.imprime();
        long malas = Libro.LINEAS.stream().filter(l -> !l.cumple()).count();
        assertEquals(0, malas, "afirmaciones del material que NO se cumplen: " + malas);
    }

    static void check(String fam, String org, String af, Object esp, Prov p) {
        Object obt;
        try { obt = p.get(); } catch (Exception e) { obt = "EXC:" + e.getClass().getSimpleName(); }
        Libro.anota(fam, org, af, esp, obt);
    }
    interface Prov { Object get() throws Exception; }

    static int n(String css) { return d.findElements(By.cssSelector(css)).size(); }
    static int x(String xp)  { return d.findElements(By.xpath(xp)).size(); }

    static void sembrar() {
        d.get(BASE + "/");
        ((JavascriptExecutor) d).executeScript(
                "const r = await fetch('/auth/login', {method:'POST'," +
                " headers:{'Content-Type':'application/json'}," +
                " body: JSON.stringify({username:'ana', password:'ana123'})});" +
                "const dd = await r.json();" +
                "localStorage.setItem('tf.token', dd.token || dd.accessToken || dd.jwt);" +
                "localStorage.setItem('tf.username','ana');");
    }

    @Test @Order(1)
    void rutas() {
        d.get(BASE + "/");
        check("ruta","Paginas.LOGIN","GET / -> <title>","Login - TaskFlow",()->d.getTitle());
        d.get(BASE + "/register.html");
        check("ruta","Paginas.REGISTRO","GET /register.html -> <title>","Registro - TaskFlow",()->d.getTitle());
        d.get(BASE + "/help.html");
        check("ruta","Paginas.AYUDA","GET /help.html -> <title>","Ayuda de TaskFlow",()->d.getTitle());
        sembrar();
        d.get(BASE + "/projects.html");
        check("ruta","Paginas.PROYECTOS","GET /projects.html CON sesion -> <title>","Proyectos - TaskFlow",()->d.getTitle());
        d.get(BASE + "/projects.html");
        // el arnes de la ronda 1 fallo aqui: sin token la UI redirige. Eso es contrato, y se audita.
        check("compor","ui.js:50","sin token, /projects.html redirige al login","Login - TaskFlow",()->{
            ((JavascriptExecutor) d).executeScript("localStorage.clear();");
            d.get(BASE + "/projects.html");
            new WebDriverWait(d, Duration.ofSeconds(10)).until(ExpectedConditions.titleIs("Login - TaskFlow"));
            return d.getTitle();
        });
    }

    @Test @Order(2)
    void idsYCuentas() {
        d.get(BASE + "/");
        check("id","guia d3 c7","#error-container existe",1,()->n("#error-container"));
        check("id","guia d3 c6","#error-container vacio al cargar","",()->d.findElement(By.id("error-container")).getText());
        check("cuenta","LocalizacionTest#3","input[type='password'] -> 1",1,()->n("input[type='password']"));
        check("cuenta","LocalizacionTest#6","'#login-form input' -> 2 campos",2,()->n("#login-form input"));
        check("cuenta","LocalizacionTest#7","'form > button' hijo directo -> 1",1,()->n("form > button"));
        check("cuenta","LocalizacionTest#8","findElements inexistente -> 0",0,()->n("[data-testid='no-existe']"));
        check("cuenta","LocalizacionTest#4b","login-error ausente antes de fallar",0,()->n("[data-testid='login-error']"));
        // NOTA, no afirmacion del material: aqui los dos selectores dan lo mismo
        Libro.anota("nota","LocalizacionTest#7","'form button' y 'form > button' dan igual en login",
                n("form button"), n("form > button"));
    }

    @Test @Order(3)
    void porTexto() {
        d.get(BASE + "/");
        check("texto","guia d3 c8","linkText exacto 'Regístrate'",1,()->d.findElements(By.linkText("Regístrate")).size());
        // el material AHORA cita 'egistr' como el trozo que falla: se audita que siga fallando
        check("texto","LocalizacionTest#5","partialLinkText 'egistr' devuelve CERO (contraejemplo)",
                0,()->d.findElements(By.partialLinkText("egistr")).size());
        check("texto","LocalizacionTest#5","un trozo que NO pisa la i acentuada si resuelve",
                1,()->d.findElements(By.partialLinkText("strate")).size());
        check("texto","guia d4 c3","//button[text()='Entrar']",1,()->x("//button[text()='Entrar']"));
        check("texto","guia d4 c3","//button[normalize-space()='Entrar']",1,()->x("//button[normalize-space()='Entrar']"));
        d.get(BASE + "/register.html");
        check("texto","XPathTest#porTextoParcial","contains(text(),'Crear Cuenta') -> h2 + boton",
                2,()->x("//*[contains(text(),'Crear Cuenta')]"));
        check("texto","XPathTest#porTextoParcial","text()='Crear Cuenta' -> solo el boton",
                1,()->x("//*[text()='Crear Cuenta']"));
        check("texto","XPathTest#porTextoParcial","'cuenta' en minuscula cae en OTRO nodo (XPath 1.0 distingue)",
                1,()->x("//*[contains(text(),'cuenta')]"));
    }

    @Test @Order(4)
    void spinnerYRender() {
        sembrar();
        d.get(BASE + "/projects.html");
        // AHORA si: en el instante 0, antes de que el JS pinte
        check("compor","guia d4 c4","spinner presente al cargar (antes del render)",true,()->n("[data-testid='spinner']")>0);
        check("compor","guia d5 c5","project-list YA visible antes del render",true,
                ()->d.findElement(By.cssSelector("[data-testid='project-list']")).isDisplayed());
        check("compor","guia d5 c5","…con CERO project-card dentro",0,()->n("[data-testid^='project-card-']"));
        long t0=System.currentTimeMillis();
        wait.until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector("[data-testid^='project-card-']")));
        long ms=System.currentTimeMillis()-t0;
        check("compor","config.js delayMs","el render tarda >1s",true,()->ms>1000);
        check("compor","guia d4 c4","el spinner desaparece al terminar",true,()->{
            wait.until(ExpectedConditions.invisibilityOfElementLocated(By.cssSelector("[data-testid='spinner']")));
            return true;
        });
    }

    @Test @Order(5)
    void loginYToast() {
        d.get(BASE + "/");
        d.findElement(By.cssSelector("[data-testid='input-username']")).sendKeys("ana");
        d.findElement(By.cssSelector("[data-testid='input-password']")).sendKeys("mala");
        d.findElement(By.cssSelector("[data-testid='btn-login']")).click();
        check("compor","login.js contrato","texto del error de login","Credenciales inválidas",
                ()->wait.until(ExpectedConditions.visibilityOfElementLocated(
                        By.cssSelector("[data-testid='login-error']"))).getText());
        check("compor","guia d4 c4","sendKeys concatena sin clear()","anaXX",()->{
            WebElement u=d.findElement(By.cssSelector("[data-testid='input-username']"));
            u.sendKeys("XX"); return u.getDomProperty("value");
        });

        sembrar();
        d.get(BASE + "/projects.html");
        wait.until(ExpectedConditions.invisibilityOfElementLocated(By.cssSelector("[data-testid='spinner']")));
        String nombre = "QA " + UUID.randomUUID().toString().substring(0,8);
        wait.until(ExpectedConditions.elementToBeClickable(By.cssSelector("[data-testid='btn-new-project']"))).click();
        wait.until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector("[data-testid='modal-project']")));
        d.findElement(By.cssSelector("[data-testid='input-project-name']")).sendKeys(nombre);
        d.findElement(By.cssSelector("[data-testid='btn-save-project']")).click();
        check("compor","guia d4 c5 / EsperasTest#4","el testid del toast es 'toast'",true,
                ()->wait.until(ExpectedConditions.visibilityOfElementLocated(
                        By.cssSelector("[data-testid='toast']"))).isDisplayed());
        check("compor","EsperasTest#4","…y el tipo va en la CLASE, no en el testid",true,
                ()->d.findElement(By.cssSelector("[data-testid='toast']")).getDomAttribute("class").contains("toast-success"));
        check("compor","guia d4 c5","toast-success NO existe como testid",0,()->n("[data-testid='toast-success']"));
        check("compor","ui.js:34","el toast se borra solo (<5s)",true,()->{
            new WebDriverWait(d, Duration.ofSeconds(5)).until(
                    ExpectedConditions.invisibilityOfElementLocated(By.cssSelector("[data-testid='toast']")));
            return true;
        });
    }

    @Test @Order(6)
    void detalleDeProyecto() {
        sembrar();
        d.get(BASE + "/projects.html");
        WebElement link = wait.until(ExpectedConditions.presenceOfElementLocated(
                By.cssSelector("[data-testid^='link-project-']")));
        // LA TRAMPA que el material no avisa: literal vs resuelto
        Libro.anota("nota","XPathTest / ProyectosPage","getDomAttribute('href') devuelve el href LITERAL",
                "relativo", link.getDomAttribute("href").startsWith("http") ? "absoluto" : "relativo");
        check("compor","XPathTest helper","getAttribute('href') si resuelve a absoluto",true,
                ()->link.getAttribute("href").startsWith("http"));

        d.get(link.getAttribute("href"));
        wait.until(ExpectedConditions.invisibilityOfElementLocated(By.cssSelector("[data-testid='spinner']")));
        wait.until(ExpectedConditions.presenceOfElementLocated(By.cssSelector("[data-testid='task-table'] tbody tr td")));

        check("compor","guia d4 c4","Select.selectByValue('DONE')","Hechas",()->{
            Select f=new Select(d.findElement(By.cssSelector("[data-testid='select-filter-status']")));
            f.selectByValue("DONE"); String s=f.getFirstSelectedOption().getText(); f.selectByValue("ALL"); return s;
        });
        check("compor","guia d4 c4","Select sobre dropdown-sort lanza…","UnexpectedTagNameException",()->{
            try { new Select(d.findElement(By.cssSelector("[data-testid='dropdown-sort']"))); return "ninguna"; }
            catch (Exception e) { return e.getClass().getSimpleName(); }
        });
        check("compor","guia d4 c3","eje parent:: -> boton de borrar de ESA fila",1,()->{
            String t=d.findElement(By.cssSelector("[data-testid='task-table'] tbody tr td")).getText();
            return x("//td[normalize-space()='"+t+"']/parent::tr//button[starts-with(@data-testid,'btn-delete-')]");
        });
        check("compor","guia d3 c7","[data-testid^='sort-option-'] al abrir el custom",true,()->{
            d.findElement(By.cssSelector("[data-testid='dropdown-sort']")).click();
            return n("[data-testid^='sort-option-']")>0;
        });
    }
}
