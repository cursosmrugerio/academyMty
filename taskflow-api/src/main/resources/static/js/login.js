// Lógica para la página de login (index.html)

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('login-form');
    const usernameInput = document.querySelector('[data-testid="input-username"]');
    const passwordInput = document.querySelector('[data-testid="input-password"]');
    const loginButton = document.querySelector('[data-testid="btn-login"]');
    const errorContainer = document.getElementById('error-container');

    // Mostrar mensaje de sesión expirada si es aplicable
    const params = new URLSearchParams(window.location.search);
    if (params.get('expired') === '1') {
        const expiredMsg = document.createElement('div');
        expiredMsg.className = 'alert alert-warning';
        expiredMsg.dataset.testid = 'session-expired-msg';
        expiredMsg.textContent = 'Tu sesión expiró. Inicia sesión de nuevo.';
        loginForm.prepend(expiredMsg);
    }

    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        // Limpiar errores previos
        if (errorContainer.firstChild) {
            errorContainer.firstChild.remove();
        }

        loginButton.disabled = true;
        ui.showSpinner(true);

        try {
            const response = await api.post('/auth/login', {
                username: usernameInput.value,
                password: passwordInput.value,
            });

            // Guardar el token y el nombre de usuario
            // El wrapper de API es tolerante a 'token', 'accessToken' o 'jwt'
            const token = response.token || response.accessToken || response.jwt;
            localStorage.setItem('tf.token', token);
            localStorage.setItem('tf.username', usernameInput.value);

            // La spec no pide delay en el login, pero para consistencia del flujo de QE
            // se puede añadir una pequeña pausa antes de redirigir
            setTimeout(() => {
                window.location.href = '/projects.html';
            }, 500);

        } catch (error) {
            // El delay artificial se aplica también en caso de error
            setTimeout(() => {
                ui.showSpinner(false);
                loginButton.disabled = false;
                const errorDiv = document.createElement('div');
                errorDiv.className = 'alert alert-danger';
                errorDiv.dataset.testid = 'login-error';
                // Contrato de la UI (superficie de localizadores): el texto del error de
                // login es SIEMPRE exacto «Credenciales inválidas». No dependemos de la
                // forma del cuerpo de error del API de cada alumno (unos devuelven
                // {message}, otros el 401 pelón): el login solo puede fallar por credenciales.
                errorDiv.textContent = 'Credenciales inválidas';
                errorContainer.appendChild(errorDiv);
            }, window.TF_CONFIG.delayMs);
        }
    });

    // Detectar si la UI se abre desde file:// y mostrar un error.
    if (window.location.protocol === 'file:') {
        const fileError = document.createElement('div');
        fileError.className = 'alert alert-danger';
        fileError.innerHTML = '<b>Error:</b> Esta UI debe servirse desde tu API (localhost:8080), no abrirse como un archivo local (`file://`).';
        document.body.prepend(fileError);
        loginButton.disabled = true;
    }
});
