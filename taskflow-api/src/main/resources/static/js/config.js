// Archivo de configuración central para la UI de TaskFlow.

window.TF_CONFIG = {
    // Retraso artificial en milisegundos para simular latencia de red.
    // Esto es crucial para los ejercicios de esperas explícitas (explicit waits) en Selenium.
    // Un valor de 0 hace que la UI sea instantánea, útil para depuración manual.
    // El valor por defecto es 1500ms.
    // Se puede sobreescribir desde la consola del navegador para pruebas:
    // localStorage.setItem('tf.delayMs', '3000');
    delayMs: Number(localStorage.getItem('tf.delayMs') ?? 1500)
};
