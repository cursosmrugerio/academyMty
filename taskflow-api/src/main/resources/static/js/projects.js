// Lógica para la página de lista de proyectos (projects.html)

document.addEventListener('DOMContentLoaded', () => {
    // Proteger la página: si no hay token, redirigir a login.
    ui.protectPage();

    const projectList = document.querySelector('[data-testid="project-list"]');
    const usernameSpan = document.querySelector('[data-testid="nav-username"]');
    const logoutButton = document.querySelector('[data-testid="btn-logout"]');
    const newProjectButton = document.querySelector('[data-testid="btn-new-project"]');
    const helpToggleButton = document.querySelector('[data-testid="btn-help-toggle"]');
    const helpPanel = document.querySelector('[data-testid="help-panel"]');

    usernameSpan.textContent = localStorage.getItem('tf.username');

    logoutButton.addEventListener('click', () => {
        localStorage.removeItem('tf.token');
        localStorage.removeItem('tf.username');
        window.location.href = '/index.html';
    });
    
    helpToggleButton.addEventListener('click', () => {
        helpPanel.classList.toggle('hidden');
    });

    const renderProjects = (projects) => {
        projectList.innerHTML = '';
        if (projects.length === 0) {
            projectList.innerHTML = `<div data-testid="empty-state" class="card"><p>No hay proyectos. Crea el primero.</p></div>`;
            return;
        }

        projects.forEach(project => {
            const card = document.createElement('div');
            card.className = 'card';
            card.dataset.testid = `project-card-${project.id}`;
            card.innerHTML = `
                <h3>${project.name}</h3>
                <p>${project.description || 'Sin descripción.'}</p>
                <a href="/project.html?id=${project.id}" class="btn btn-primary btn-sm" data-testid="link-project-${project.id}">Abrir</a>
            `;
            projectList.appendChild(card);
        });
    };

    const loadProjects = async () => {
        ui.showSpinner(true);
        try {
            const projects = await api.get('/projects');
            setTimeout(() => {
                ui.showSpinner(false);
                renderProjects(projects);
            }, window.TF_CONFIG.delayMs);
        } catch (error) {
            setTimeout(() => {
                ui.showSpinner(false);
                ui.showToast(`Error al cargar proyectos: ${error.message}`, 'error');
            }, window.TF_CONFIG.delayMs);
        }
    };

    const openNewProjectModal = () => {
        const modal = document.createElement('div');
        modal.className = 'modal-overlay';
        modal.dataset.testid = 'modal-project';
        modal.innerHTML = `
            <div class="modal-content">
                <div class="modal-header">
                    <h2 class="modal-title">Nuevo Proyecto</h2>
                </div>
                <div id="modal-error-container"></div>
                <form id="new-project-form">
                    <div class="form-group">
                        <label for="project-name">Nombre</label>
                        <input type="text" id="project-name" class="form-control" data-testid="input-project-name" required>
                    </div>
                    <div class="form-group">
                        <label for="project-description">Descripción</label>
                        <textarea id="project-description" class="form-control" data-testid="input-project-description"></textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-testid="btn-cancel-project">Cancelar</button>
                        <button type="submit" class="btn btn-primary" data-testid="btn-save-project">Guardar</button>
                    </div>
                </form>
            </div>
        `;

        document.body.appendChild(modal);

        const form = modal.querySelector('#new-project-form');
        const cancelButton = modal.querySelector('[data-testid="btn-cancel-project"]');
        const saveButton = modal.querySelector('[data-testid="btn-save-project"]');
        const nameInput = modal.querySelector('[data-testid="input-project-name"]');
        const descriptionInput = modal.querySelector('[data-testid="input-project-description"]');
        const modalErrorContainer = modal.querySelector('#modal-error-container');

        const closeModal = () => modal.remove();

        cancelButton.addEventListener('click', closeModal);
        modal.addEventListener('click', (e) => {
            if (e.target === modal) closeModal();
        });

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            saveButton.disabled = true;

            if (modalErrorContainer.firstChild) {
                modalErrorContainer.firstChild.remove();
            }

            try {
                await api.post('/projects', {
                    name: nameInput.value,
                    description: descriptionInput.value
                });
                closeModal();
                ui.showToast('Proyecto creado con éxito.');
                loadProjects(); // Recargar la lista de proyectos
            } catch (error) {
                const errorDiv = document.createElement('div');
                errorDiv.className = 'alert alert-danger';
                errorDiv.dataset.testid = 'modal-project-error';
                errorDiv.textContent = error.message;
                modalErrorContainer.appendChild(errorDiv);
            } finally {
                saveButton.disabled = false;
            }
        });
    };

    newProjectButton.addEventListener('click', openNewProjectModal);

    // Carga inicial
    loadProjects();
});
