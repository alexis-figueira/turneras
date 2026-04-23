-- Base de Datos: Agenda de Psicología
-- Estas tablas están pensadas para ser escalables y tener un registro financiero y clínico ordenado.

-- 1. Tabla de Pacientes
CREATE TABLE IF NOT EXISTS `psicologia__pacientes` (
    `id_paciente` INT AUTO_INCREMENT PRIMARY KEY,
    `dni` VARCHAR(20) UNIQUE NOT NULL,
    `nombre` VARCHAR(100) NOT NULL,
    `apellido` VARCHAR(100) NOT NULL,
    `telefono` VARCHAR(50) DEFAULT NULL,
    `email` VARCHAR(150) DEFAULT NULL,
    `fecha_nacimiento` DATE DEFAULT NULL,
    `direccion` VARCHAR(255) DEFAULT NULL,
    `localidad` VARCHAR(100) DEFAULT NULL,
    `estado` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=Activo, 0=Inactivo',
    `reg_user` INT DEFAULT NULL COMMENT 'ID del usuario en sys_users que lo registró',
    `reg_fecha` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. Tabla de Turnos
CREATE TABLE IF NOT EXISTS `psicologia__turnos` (
    `id_turno` INT AUTO_INCREMENT PRIMARY KEY,
    `id_paciente` INT NOT NULL,
    `fecha` DATE NOT NULL,
    `horario_inicio` TIME NOT NULL,
    `horario_fin` TIME NOT NULL,
    `valor_sesion` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Precio acordado para esta sesión específica',
    `estado` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '0=Anulado, 1=Pendiente, 10=Ausente, 11=Presente',
    `observaciones` TEXT DEFAULT NULL COMMENT 'Notas previas sobre el turno',
    `reg_user` INT DEFAULT NULL COMMENT 'ID del usuario en sys_users que registró el turno',
    `reg_fecha` DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_turnos_paciente` FOREIGN KEY (`id_paciente`) REFERENCES `psicologia__pacientes` (`id_paciente`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 3. Tabla de Pagos
CREATE TABLE IF NOT EXISTS `psicologia__pagos` (
    `id_pago` INT AUTO_INCREMENT PRIMARY KEY,
    `id_paciente` INT NOT NULL,
    `id_turno` INT DEFAULT NULL COMMENT 'Puede ser NULL si es un pago por adelantado mensual',
    `monto` DECIMAL(10, 2) NOT NULL,
    `metodo_pago` VARCHAR(50) NOT NULL DEFAULT 'Efectivo' COMMENT 'Efectivo, Transferencia, etc.',
    `fecha_pago` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `reg_user` INT DEFAULT NULL COMMENT 'ID del usuario en sys_users que registró el pago',
    `reg_fecha` DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_pagos_paciente` FOREIGN KEY (`id_paciente`) REFERENCES `psicologia__pacientes` (`id_paciente`) ON DELETE CASCADE,
    CONSTRAINT `fk_pagos_turno` FOREIGN KEY (`id_turno`) REFERENCES `psicologia__turnos` (`id_turno`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
