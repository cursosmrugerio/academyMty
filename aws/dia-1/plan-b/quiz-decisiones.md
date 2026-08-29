# Quiz de decisiones — se responde con o sin cuenta AWS

> No busca que recuerdes dónde está un botón. Busca que sepas **por qué**.

## Red y seguridad

1. El RDS no tiene IP pública. ¿Qué se perdería si se la pusiéramos?
2. La regla del RDS apunta al **security group** de la EC2, no a su IP. Funciona igual hoy.
   ¿Qué pasa mañana, cuando haya tres instancias, con cada una de las dos opciones?
3. Dejamos el 8080 abierto a todo internet **a propósito**. ¿Qué haría falta para que eso
   no fuera una mala idea en producción?
4. Un compañero dice: «da igual, el SSH abierto al mundo está protegido por la llave».
   ¿Qué le respondes?

## Errores

5. Tu aplicación no conecta a la base y el log dice `Connection timed out`.
   ¿Qué **descartas** inmediatamente y qué miras primero?
6. Ahora dice `Connection refused`. ¿Cambió tu diagnóstico? ¿Por qué?
7. El log tiene 339 líneas y la primera excepción grande habla de `jwtAuthenticationFilter`.
   ¿Está roto el filtro? ¿Cómo encuentras la causa real?

## Artefactos y configuración

8. ¿Por qué no compilamos el proyecto dentro de la EC2?
9. Pasamos de H2 a PostgreSQL sin recompilar. ¿Qué propiedad del diseño lo hizo posible?
10. El perfil se llama `docker` y no hay ningún Docker. ¿Qué te dice eso sobre fiarte
    de los nombres?
11. Subiste el jar a un bucket privado. Necesitas mandárselo a alguien de fuera.
    ¿Haces público el bucket? ¿Qué haces?

## Dinero

12. Se te olvida terminar la EC2 y el RDS, y te acuerdas dentro de un mes.
    ¿Cuánto llevas gastado, más o menos? ¿Qué te habría avisado?
13. Un compañero se registró con el plan de pago. ¿Qué riesgo corre que tú no corres?
    ¿Puede cambiarse?
