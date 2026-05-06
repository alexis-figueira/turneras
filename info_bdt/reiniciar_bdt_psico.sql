SET FOREIGN_KEY_CHECKS = 0;
-- Borramos desde las tablas hijas hacia las tablas padre
DELETE FROM `psicologia__pagos`;
ALTER TABLE `psicologia__pagos` AUTO_INCREMENT = 1;
DELETE FROM `psicologia__turnos`;
ALTER TABLE `psicologia__turnos` AUTO_INCREMENT = 1;
-- DELETE FROM `psicologia__pacientes`;
-- ALTER TABLE `psicologia__pacientes` AUTO_INCREMENT = 1;
DELETE FROM `psicologia__auditoria_logs`;
ALTER TABLE `psicologia__auditoria_logs` AUTO_INCREMENT = 1;
SET FOREIGN_KEY_CHECKS = 1;