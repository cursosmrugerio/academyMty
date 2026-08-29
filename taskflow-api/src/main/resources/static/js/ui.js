// Módulo de UI: maneja componentes de UI reusables como toasts, spinner, modales.

const ui = {
    // Muestra u oculta el spinner de carga.
    showSpinner(show = true) {
        let spinner = document.querySelector('[data-testid="spinner"]');
        if (show) {
            if (!spinner) {
                spinner = document.createElement('div');
                spinner.className = 'spinner-overlay';
                spinner.dataset.testid = 'spinner';
                spinner.innerHTML = '<div class="spinner"></div>';
                document.body.appendChild(spinner);
            }
        } else {
            if (spinner) {
                spinner.remove();
            }
        }
    },

    // Muestra un toast (notificación emergente).
    showToast(message, type = 'success') {
        const container = document.querySelector('[data-testid="toast-container"]');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.dataset.testid = 'toast';
        toast.textContent = message;

        container.appendChild(toast);

        // El toast se elimina automáticamente después de 3 segundos.
        setTimeout(() => {
            toast.remove();
        }, 3000);
    },

    // Limpia el storage y redirige al login por sesión expirada.
    handleSessionExpired() {
        localStorage.removeItem('tf.token');
        localStorage.removeItem('tf.username');
        window.location.href = '/index.html?expired=1';
    },
    
    // Verifica si hay un token al cargar las páginas protegidas.
    // Si no hay token, redirige inmediatamente al login.
    protectPage() {
        if (!localStorage.getItem('tf.token')) {
            window.location.href = '/index.html';
        }
    },

    // Inserta y gestiona un diálogo de confirmación modal.
    // Retorna una promesa que se resuelve a `true` si se confirma, o `false` si se cancela.
    showConfirmDialog(message) {
        return new Promise(resolve => {
            // Eliminar cualquier diálogo existente para evitar duplicados.
            const existingDialog = document.querySelector('[data-testid="dialog-confirm"]');
            if (existingDialog) existingDialog.remove();

            const dialog = document.createElement('div');
            dialog.className = 'modal-overlay';
            dialog.dataset.testid = 'dialog-confirm';
            dialog.innerHTML = `
                <div class="modal-content">
                    <p data-testid="confirm-text">${message}</p>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" data-testid="btn-confirm-no">Cancelar</button>
                        <button class="btn btn-danger" data-testid="btn-confirm-yes">Eliminar</button>
                    </div>
                </div>
            `;

            const btnYes = dialog.querySelector('[data-testid="btn-confirm-yes"]');
            const btnNo = dialog.querySelector('[data-testid="btn-confirm-no"]');

            const closeDialog = (value) => {
                dialog.remove();
                resolve(value);
            };

            btnYes.addEventListener('click', () => closeDialog(true));
            btnNo.addEventListener('click', () => closeDialog(false));
            dialog.addEventListener('click', (e) => {
                if (e.target === dialog) closeDialog(false); // Cierra si se hace click en el overlay
            });

            document.body.appendChild(dialog);
        });
    },

    // Crea y gestiona un dropdown custom (botón que despliega una lista <ul>).
    // `target` es el botón que dispara el dropdown.
    // `items` es un array de objetos { label, value, testId }.
    // `onSelect` es una función callback que recibe el `value` del item seleccionado.
    initDropdown(target, items, onSelect) {
        target.addEventListener('click', (e) => {
            e.stopPropagation();
            
            // Si ya hay un menú abierto, lo cerramos.
            const existingMenu = document.querySelector('[data-testid="dropdown-sort-list"]');
            if (existingMenu) {
                existingMenu.remove();
                return;
            }

            const menu = document.createElement('ul');
            menu.className = 'dropdown-menu';
            menu.dataset.testid = 'dropdown-sort-list';

            items.forEach(item => {
                const li = document.createElement('li');
                li.className = 'dropdown-item';
                li.textContent = item.label;
                li.dataset.testid = item.testId;
                li.addEventListener('click', () => {
                    menu.remove();
                    onSelect(item.value, item.label);
                });
                menu.appendChild(li);
            });

            document.body.appendChild(menu);
            
            // Posicionar el menú junto al botón
            const rect = target.getBoundingClientRect();
            menu.style.left = `${rect.left}px`;
            menu.style.top = `${rect.bottom}px`;

            // Cierra el menú si se hace click en cualquier otro lugar.
            const closeMenu = () => {
                if (document.body.contains(menu)) {
                    menu.remove();
                }
                document.removeEventListener('click', closeMenu);
            };
            setTimeout(() => document.addEventListener('click', closeMenu), 0);
        });
    }
};
