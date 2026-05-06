CREATE TABLE `psicologia__auditoria_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  
  -- ¿Dónde ocurrió el cambio?
  `tabla_afectada` VARCHAR(100) NOT NULL COMMENT 'Nombre de la tabla modificada, ej: psicologia__turnos',
  `registro_id` INT NOT NULL COMMENT 'ID del registro que sufrió la modificación',
  
  -- ¿Qué tipo de cambio fue?
  `accion` VARCHAR(20) NOT NULL COMMENT 'Puede ser: CREATE, UPDATE, DELETE',
  
  -- Los datos del cambio (Usamos tipo JSON, soportado en MySQL moderno, o LONGTEXT si es antiguo)
  `estado_anterior` JSON NULL DEFAULT NULL COMMENT 'JSON con los datos antes del cambio (Nulo si es un CREATE)',
  `estado_nuevo` JSON NULL DEFAULT NULL COMMENT 'JSON con los datos después del cambio (Nulo si es un DELETE)',
  
  -- ¿Quién y cuándo?
  `usuario_id` INT NULL DEFAULT NULL COMMENT 'ID del usuario que realizó la acción',
  `fecha` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora exacta del cambio',
  
  PRIMARY KEY (`id`),
  INDEX `idx_tabla_registro` (`tabla_afectada`, `registro_id`), -- Índice para búsquedas rápidas por tabla y ID
  INDEX `idx_fecha` (`fecha`) -- Índice para buscar rápido por fechas
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
