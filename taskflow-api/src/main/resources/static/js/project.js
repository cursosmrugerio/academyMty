// Lógica para la página de detalle de un proyecto (project.html)

document.addEventListener('DOMContentLoaded', () => {
    ui.protectPage();

    const params = new URLSearchParams(window.location.search);
    const projectId = params.get('id');

    if (!projectId) {
        window.location.href = '/projects.html';
        return;
    }

    // Elementos del DOM
    const projectNameEl = document.querySelector('[data-testid="project-name"]');
    // Hueco intencional: el contador NO tiene id ni data-testid; se localiza por su
    // relacion con el h1 (following-sibling). Aqui lo tomamos por clase para uso interno.
    const taskCountEl = document.querySelector('.task-count');
    const taskTableBody = document.querySelector('#task-table-body');
    const usernameSpan = document.querySelector('[data-testid="nav-username"]');
    const logoutButton = document.querySelector('[data-testid="btn-logout"]');
    const newTaskButton = document.querySelector('[data-testid="btn-new-task"]');
    const statusFilter = document.querySelector('[data-testid="select-filter-status"]');
    const sortDropdownButton = document.querySelector('[data-testid="dropdown-sort"]');
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

    let allTasks = []; // Caché de tareas para filtrado y orden en cliente
    let currentSort = { value: 'id', label: 'id' };

    // --- Renderizado ---
    const renderTasks = () => {
        let tasksToRender = [...allTasks];

        // Filtrar
        const filterValue = statusFilter.value;
        if (filterValue !== 'ALL') {
            tasksToRender = tasksToRender.filter(task => task.status === filterValue);
        }

        // Ordenar
        const sorter = (a, b) => {
            switch(currentSort.value) {
                case 'title':
                    return a.title.localeCompare(b.title);
                case 'priority':
                    const pOrder = { 'HIGH': 0, 'MED': 1, 'LOW': 2 };
                    return pOrder[a.priority] - pOrder[b.priority];
                case 'dueDate':
                    if (a.dueDate && b.dueDate) return new Date(a.dueDate) - new Date(b.dueDate);
                    return a.dueDate ? -1 : 1; // nulls al final
                default: // id
                    return a.id - b.id;
            }
        };
        tasksToRender.sort(sorter);

        taskTableBody.innerHTML = '';
        if (tasksToRender.length === 0) {
            taskTableBody.innerHTML = `<tr data-testid="empty-state"><td colspan="6">Sin tareas</td></tr>`;
        } else {
            tasksToRender.forEach(task => {
                const row = document.createElement('tr');
                row.dataset.testid = `task-row-${task.id}`;
                row.innerHTML = `
                    <td>${task.title}</td>
                    <td><span class="badge badge-${task.status.toLowerCase().replace('_', '-')}">${task.status.replace('_', ' ')}</span></td>
                    <td><span class="badge badge-${task.priority.toLowerCase()}">${task.priority}</span></td>
                    <td>${task.dueDate || '—'}</td>
                    <td>${task.assigneeId || '—'}</td>
                    <td class="actions">
                        <select class="form-control btn-sm" data-testid="select-status-${task.id}">
                            <option value="TODO" ${task.status === 'TODO' ? 'selected' : ''}>Por hacer</option>
                            <option value="IN_PROGRESS" ${task.status === 'IN_PROGRESS' ? 'selected' : ''}>En curso</option>
                            <option value="DONE" ${task.status === 'DONE' ? 'selected' : ''}>Hecha</option>
                        </select>
                        <button class="btn btn-secondary btn-sm" data-testid="btn-edit-${task.id}">Editar</button>
                        <button class="btn btn-danger btn-sm" data-testid="btn-delete-${task.id}">Borrar</button>
                    </td>
                `;
                taskTableBody.appendChild(row);
            });
        }
        taskCountEl.textContent = `${tasksToRender.length} tareas`;
        addEventListenersToTasks();
    };

    // --- Carga de datos ---
    const loadProjectDetails = async () => {
        ui.showSpinner(true);
        try {
            const [project, tasks] = await Promise.all([
                api.get(`/projects/${projectId}`),
                api.get(`/projects/${projectId}/tasks`)
            ]);
            allTasks = tasks;
            setTimeout(() => {
                ui.showSpinner(false);
                projectNameEl.textContent = project.name;
                renderTasks();
            }, window.TF_CONFIG.delayMs);
        } catch (error) {
            setTimeout(() => {
                ui.showSpinner(false);
                ui.showToast(`Error al cargar el proyecto: ${error.message}`, 'error');
            }, window.TF_CONFIG.delayMs);
        }
    };

    // --- Lógica de Modales ---
    const openTaskModal = (task = null) => {
        const isEditing = task !== null;
        const modal = document.createElement('div');
        modal.className = 'modal-overlay';
        modal.dataset.testid = 'modal-task';
        modal.innerHTML = `
            <div class="modal-content">
                <div class="modal-header">
                    <h2 class="modal-title" data-testid="modal-task-title">${isEditing ? 'Editar Tarea' : 'Nueva Tarea'}</h2>
                </div>
                <div id="modal-error-container"></div>
                <form id="task-form">
                    <div class="form-group">
                        <label for="task-title">Título</label>
                        <input type="text" id="task-title" class="form-control" data-testid="input-task-title" required value="${task?.title || ''}">
                    </div>
                    <div class="form-group">
                        <label for="task-description">Descripción</label>
                        <textarea id="task-description" class="form-control" data-testid="input-task-description">${task?.description || ''}</textarea>
                    </div>
                    <div class="form-group">
                        <label for="task-priority">Prioridad</label>
                        <select id="task-priority" class="form-control" data-testid="select-task-priority">
                            <option value="LOW" ${task?.priority === 'LOW' ? 'selected' : ''}>Baja</option>
                            <option value="MED" ${task?.priority === 'MED' || !isEditing ? 'selected' : ''}>Media</option>
                            <option value="HIGH" ${task?.priority === 'HIGH' ? 'selected' : ''}>Alta</option>
                        </select>
                    </div>
                     <div class="form-group">
                        <label for="task-duedate">Fecha Límite</label>
                        <input type="date" id="task-duedate" class="form-control" data-testid="input-task-duedate" value="${task?.dueDate || ''}">
                    </div>
                    <div class="form-group">
                        <label for="task-assignee">Asignado (ID de usuario)</label>
                        <input type="number" id="task-assignee" class="form-control" data-testid="input-task-assignee" placeholder="Id de usuario (opcional)" value="${task?.assigneeId || ''}">
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-testid="btn-cancel-task">Cancelar</button>
                        <button type="submit" class="btn btn-primary" data-testid="btn-save-task">Guardar</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);

        const form = modal.querySelector('#task-form');
        const cancelButton = modal.querySelector('[data-testid="btn-cancel-task"]');
        const saveButton = modal.querySelector('[data-testid="btn-save-task"]');
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

            const taskData = {
                title: form.elements['task-title'].value,
                description: form.elements['task-description'].value,
                priority: form.elements['task-priority'].value,
                dueDate: form.elements['task-duedate'].value || null,
                assigneeId: form.elements['task-assignee'].value ? Number(form.elements['task-assignee'].value) : null,
            };

            try {
                let updatedTask;
                if (isEditing) {
                    updatedTask = await api.put(`/tasks/${task.id}`, { ...task, ...taskData });
                    const index = allTasks.findIndex(t => t.id === task.id);
                    allTasks[index] = updatedTask;
                } else {
                    updatedTask = await api.post(`/projects/${projectId}/tasks`, taskData);
                    allTasks.push(updatedTask);
                }
                
                setTimeout(() => {
                    closeModal();
                    ui.showToast(`Tarea ${isEditing ? 'actualizada' : 'creada'} con éxito.`);
                    renderTasks();
                }, window.TF_CONFIG.delayMs);

            } catch (error) {
                const errorDiv = document.createElement('div');
                errorDiv.className = 'alert alert-danger';
                errorDiv.dataset.testid = 'modal-task-error';
                errorDiv.textContent = error.message;
                modalErrorContainer.appendChild(errorDiv);
                saveButton.disabled = false;
            }
        });
    };

    // --- Event Listeners ---
    const addEventListenersToTasks = () => {
        document.querySelectorAll('[data-testid^="btn-edit-"]').forEach(button => {
            button.addEventListener('click', (e) => {
                const taskId = e.target.dataset.testid.split('-').pop();
                const task = allTasks.find(t => t.id == taskId);
                openTaskModal(task);
            });
        });

        document.querySelectorAll('[data-testid^="btn-delete-"]').forEach(button => {
            button.addEventListener('click', async (e) => {
                const taskId = e.target.dataset.testid.split('-').pop();
                const task = allTasks.find(t => t.id == taskId);
                
                const confirmed = await ui.showConfirmDialog(`¿Eliminar la tarea «${task.title}»?`);
                if (confirmed) {
                    try {
                        await api.delete(`/tasks/${taskId}`);
                        allTasks = allTasks.filter(t => t.id != taskId);
                        setTimeout(() => {
                            ui.showToast('Tarea eliminada.');
                            renderTasks();
                        }, window.TF_CONFIG.delayMs);
                    } catch(error) {
                        setTimeout(() => ui.showToast(`Error al eliminar: ${error.message}`, 'error'), window.TF_CONFIG.delayMs);
                    }
                }
            });
        });
        
        document.querySelectorAll('[data-testid^="select-status-"]').forEach(select => {
            select.addEventListener('change', async (e) => {
                const taskId = e.target.dataset.testid.split('-').pop();
                const newStatus = e.target.value;
                const originalStatus = allTasks.find(t => t.id == taskId).status;

                try {
                    const updatedTask = await api.patch(`/tasks/${taskId}/status`, { status: newStatus });
                    const index = allTasks.findIndex(t => t.id == taskId);
                    allTasks[index] = updatedTask;
                    
                    setTimeout(() => {
                        ui.showToast('Estado actualizado.');
                        renderTasks();
                    }, window.TF_CONFIG.delayMs);

                } catch (error) {
                    // Revertir el select en caso de error
                    e.target.value = originalStatus;
                    setTimeout(() => ui.showToast(`Error al actualizar: ${error.message}`, 'error'), window.TF_CONFIG.delayMs);
                }
            });
        });
    };
    
    newTaskButton.addEventListener('click', () => openTaskModal());
    statusFilter.addEventListener('change', renderTasks);

    const sortOptions = [
        { label: 'Título (A-Z)', value: 'title', testId: 'sort-option-title' },
        { label: 'Prioridad (Alta primero)', value: 'priority', testId: 'sort-option-priority' },
        { label: 'Fecha Límite (próxima primero)', value: 'dueDate', testId: 'sort-option-duedate' },
    ];

    ui.initDropdown(sortDropdownButton, sortOptions, (value, label) => {
        currentSort = { value, label };
        sortDropdownButton.textContent = `Ordenar: ${label}`;
        renderTasks();
    });

    // Carga inicial
    loadProjectDetails();
});
