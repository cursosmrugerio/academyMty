// Módulo de API: wrapper para las llamadas fetch al backend de TaskFlow.

const api = {
    // Realiza una petición a la API.
    // Abstrae la adición del token de autorización, el manejo de la URL base
    // y el parseo de la respuesta.
    async request(endpoint, options = {}) {
        // URL relativa: la UI la sirve la MISMA taskflow-api que expone el API,
        // asi que las peticiones van al mismo origen (localhost:8080) sin CORS
        // y sin acoplar el puerto en el codigo. Cero origenes externos.
        const url = endpoint;
        const token = localStorage.getItem('tf.token');

        const headers = {
            'Content-Type': 'application/json',
            ...options.headers,
        };

        // Añade el token de autorización si existe y no es una ruta pública
        if (token && !endpoint.startsWith('/auth')) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        const config = {
            ...options,
            headers,
        };

        const response = await fetch(url, config);

        // Si la respuesta es 401 (No autorizado) en una ruta protegida,
        // se asume que la sesión expiró. Se limpia el storage y se redirige al login.
        if (response.status === 401 && !endpoint.startsWith('/auth')) {
            ui.handleSessionExpired();
            // Retorna una promesa que nunca se resuelve para detener la cadena de `then`.
            return new Promise(() => {});
        }

        // Si la respuesta no es OK (e.g., 400, 404, 500), intenta extraer un mensaje
        // de error del cuerpo de la respuesta. Si no puede, construye un error genérico.
        if (!response.ok) {
            let errorMessage = `Error HTTP ${response.status}: ${response.statusText}`;
            try {
                const errorBody = await response.json();
                // Compatible con el formato de error de Spring Boot Validation (`@Valid`)
                // y con mensajes de error personalizados.
                errorMessage = errorBody.message || (errorBody.errors ? Object.values(errorBody.errors)[0] : errorMessage);
            } catch (e) {
                // El cuerpo no era JSON o estaba vacío, se usa el error genérico.
            }
            throw new Error(errorMessage);
        }

        // Si la respuesta es 204 (No Content), no hay cuerpo que parsear.
        if (response.status === 204) {
            return null;
        }

        // Parsea la respuesta como JSON.
        return response.json();
    },

    // Métodos de conveniencia para verbos HTTP comunes

    get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    },

    post(endpoint, body) {
        return this.request(endpoint, { method: 'POST', body: JSON.stringify(body) });
    },

    put(endpoint, body) {
        return this.request(endpoint, { method: 'PUT', body: JSON.stringify(body) });
    },

    patch(endpoint, body) {
        return this.request(endpoint, { method: 'PATCH', body: JSON.stringify(body) });
    },

    delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }
};
