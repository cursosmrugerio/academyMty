# Checklist de limpieza — <TU NOMBRE>

**En este orden. Nadie se va sin esto marcado.**

- [ ] **EC2 → Terminate instance** (no «Stop»: *terminate*)
- [ ] **RDS → Delete** → sin snapshot final → escribir la frase de confirmación
- [ ] **S3 → vaciar** el bucket → borrarlo
- [ ] **EC2 → Key pairs** → borrar `taskflow-key`
- [ ] `rm taskflow-key.pem` en mi laptop
- [ ] **Budgets → NO TOCAR.** El presupuesto se queda de vigía

## Verificación cruzada

Mi consola la revisó: `_______________________`
Su consola la revisé yo: `_______________________`

## Si algo quedó vivo

Dilo **hoy** en el canal, no mañana. No pasa nada por decirlo; pasa por no decirlo.

> Recuerda: la evidencia en tu repositorio es el entregable duradero.
> En una hora, nada de esto va a existir.
