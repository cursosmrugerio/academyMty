// Lógica para la página de registro (register.html)

document.addEventListener('DOMContentLoaded', () => {
    const registerForm = document.getElementById('register-form');
    const usernameInput = document.querySelector('[data-testid="input-reg-username"]');
    const emailInput = document.querySelector('[data-testid="input-reg-email"]');
    const passwordInput = document.querySelector('[data-testid="input-reg-password"]');
    const registerButton = document.querySelector('[data-testid="btn-register"]');
    const errorContainer = document.getElementById('error-container');

    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        if (errorContainer.firstChild) {
            errorContainer.firstChild.remove();
        }

        registerButton.disabled = true;
        ui.showSpinner(true);

        try {
            await api.post('/auth/register', {
                username: usernameInput.value,
                email: emailInput.value,
                password: passwordInput.value,
            });

            // Éxito: mostrar toast y redirigir tras 1.5s
            setTimeout(() => {
                ui.showSpinner(false);
                ui.showToast('Cuenta creada', 'success');
                setTimeout(() => {
                    window.location.href = '/index.html';
                }, 1500);
            }, window.TF_CONFIG.delayMs);


        } catch (error) {
            // Error: mostrar mensaje y rehabilitar el formulario
            setTimeout(() => {
                ui.showSpinner(false);
                registerButton.disabled = false;
                const errorDiv = document.createElement('div');
                errorDiv.className = 'alert alert-danger';
                errorDiv.dataset.testid = 'reg-error';
                errorDiv.textContent = error.message;
                errorContainer.appendChild(errorDiv);
            }, window.TF_CONFIG.delayMs);
        }
    });
});
