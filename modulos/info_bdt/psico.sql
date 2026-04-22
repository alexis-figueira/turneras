-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 22-04-2026 a las 21:37:11
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `psico`
--

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `SP_ExpMovimientos`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_ExpMovimientos` (IN `p_id_exp` INT)   BEGIN
    SELECT `id_mov`, `movimiento`, `fecha`, `sector`, `usuario`
    FROM (
        -- Caratulado
        SELECT M.`id_mov`, M.`movimiento`, M.`fecha_destino` AS "fecha", S.`sector`, U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_destino`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_destino`
        WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`movimiento` = "CARATULADO"
        
UNION ALL
         -- ANEXADO AL ACTUAL
        SELECT M.`id_mov`, "SE LE ANEXO" AS `movimiento`, M.`fecha_destino` AS "fecha", CONCAT(E.number,"/",E.year) AS "sector", U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__expedientes` E ON E.`id_exp` = M.`id_exp`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_destino`
        WHERE M.`vinculado` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`movimiento` = "FUSIONADO"
        
UNION ALL        

-- Archivado
        SELECT M.`id_mov`, M.`movimiento`, M.`fecha_destino` AS "fecha", S.`sector`, U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_destino`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_destino`
        WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`movimiento` = "ARCHIVADO"
  
UNION ALL

-- Desarchivado
        SELECT M.`id_mov`, M.`movimiento`, M.`fecha_destino` AS "fecha", S.`sector`, U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_destino`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_destino`
        WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`movimiento` = "DESARCHIVADO"
		
        UNION ALL
		-- FUSIONADO
        SELECT M.`id_mov`, M.`movimiento`, M.`fecha_destino` AS "fecha", (SELECT CONCAT("EXP: ",`number`,"/",`year`) AS "exp" FROM desa__alexis.`expedientes__expedientes` WHERE `id_exp`=M.`vinculado` AND `estado` >= 0) AS "sector", U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_destino`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_destino`
       	WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`movimiento` = "FUSIONADO"
        
        UNION ALL

        -- Enviado
        SELECT M.`id_mov`, "ENVIADO" AS "mov", M.`fecha_origen` AS "fecha", S.`sector`, U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_origen`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_origen`
        WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`usuario_destino` IS NOT NULL
          AND M.`movimiento` = "PASE"

        UNION ALL

        -- Recibido
        SELECT M.`id_mov`, "RECIBIDO" AS "mov", M.`fecha_destino` AS "fecha", S.`sector`, U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_destino`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_destino`
        WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`usuario_destino` IS NOT NULL
          AND M.`movimiento` = "PASE"

        UNION ALL

        -- En Camino
        SELECT M.`id_mov`, "EN CAMINO" AS "mov", M.`fecha_origen` AS "fecha", S.`sector`, U.`usuario`
        FROM desa__alexis.`expedientes__movimientos` M
        LEFT JOIN desa__alexis.`expedientes__sectores` S ON S.`id_sector` = M.`sector_destino`
        LEFT JOIN desa__alexis.`sys__users` U ON U.`id_usuario` = M.`usuario_origen`
        WHERE M.`id_exp` = p_id_exp
          AND M.`disponible` = "1"
          AND M.`usuario_destino` IS NULL
          AND M.`movimiento` = "PASE"
    ) B 
    ORDER BY `fecha` DESC;
END$$

DROP PROCEDURE IF EXISTS `SP_ExpPermisosSectores`$$
CREATE DEFINER=`desa__alexis`@`%` PROCEDURE `SP_ExpPermisosSectores` (IN `id_usuario` INT)   BEGIN
    WITH RECURSIVE permisos_sector_recursivo AS (
        -- Empezamos con los sectores autónomos (padre = 0)
        SELECT 
            S.id_sector, 
            S.sector, 
            S.padre, 
            P.permiso, 
        	S.caratulacion,
            1 AS nivel,
            S.sector AS orden
        FROM 
            expedientes__sectores S
        LEFT JOIN 
            expedientes__agentes P ON P.id_sector = S.id_sector AND P.id_usuario = id_usuario
        WHERE 
            S.padre = 0 AND S.disponible = '1'
        
        UNION ALL
        
        -- Para cada sector, buscamos sus hijos recursivamente y aumentamos el nivel
        SELECT 
            es.id_sector, 
            es.sector, 
            es.padre, 
            pa.permiso, 
        	es.caratulacion,
            sh.nivel + 1 AS nivel,
            CONCAT(sh.orden, ' > ', es.sector) AS orden
        FROM 
            expedientes__sectores es
        LEFT JOIN 
            expedientes__agentes pa ON pa.id_sector = es.id_sector AND pa.id_usuario = id_usuario
        INNER JOIN 
            permisos_sector_recursivo sh ON es.padre = sh.id_sector
        WHERE 
            es.disponible = '1'
    )
    -- Ordenamos los resultados según la jerarquía y el orden alfabético en cada nivel
    SELECT 
        id_sector, 
        sector, 
        padre, 
        permiso, 
        caratulacion, 
        nivel
    FROM 
        permisos_sector_recursivo
    ORDER BY 
        orden;
END$$

DROP PROCEDURE IF EXISTS `SP_ExpSectoresMiembros`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_ExpSectoresMiembros` ()   BEGIN
    UPDATE desa__alexis.`expedientes__sectores` ES
	JOIN ( SELECT `id_sector`, COUNT(`id_sector`) AS "miembros" FROM desa__alexis.`expedientes__agentes` EA LEFT JOIN desa__alexis.`sys__users` U ON EA.`id_usuario`=U.`id_usuario`
WHERE U.`disponible`="1" GROUP BY `id_sector` ) AS SM ON ES.`id_sector` = SM.`id_sector`
	SET ES.`miembros` = SM.`miembros`;
END$$

DROP PROCEDURE IF EXISTS `SP_ExpVinculados`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_ExpVinculados` (IN `expedienteInicial` INT)   BEGIN
    WITH RECURSIVE `expediente_descendiente` AS (
        SELECT `id_exp`, `year`, `number`, `vinculado`, `estado`
        FROM desa__alexis.`v_expedientes`
        WHERE `id_exp` = expedienteInicial

        UNION ALL

        SELECT V.`id_exp`, V.`year`, V.`number`, V.`vinculado`, V.`estado`
        FROM desa__alexis.`v_expedientes` V
        INNER JOIN `expediente_descendiente` ED ON V.`vinculado` = ED.`id_exp`
    )

    SELECT `id_exp`, `year`, `number`, `vinculado`, `estado`
    FROM `expediente_descendiente` WHERE `id_exp` != expedienteInicial;
END$$

DROP PROCEDURE IF EXISTS `SP_GrupoFamiliar`$$
CREATE DEFINER=`desa__ari`@`%` PROCEDURE `SP_GrupoFamiliar` (IN `persona` INT)   BEGIN
    DECLARE FILTRO_SEARCH INT;
    
    -- VERIFICO SI FILTRO POR TITULAR O ID_PERSONA
    SELECT IFNULL(`titular`,`id_persona`) INTO FILTRO_SEARCH 
    FROM `padron__afiliacion` 
    WHERE `id_persona`=persona AND `current`='1' AND `disponible`='1';
	
	-- Selecciona todos los miembros del grupo familiar incluyendo al titular
    SELECT V.`id_afiliacion`,V.`id_persona`, P.`apellido`,P.`nombre`, P.`dni`,P.`cuil`, V.`subtipo`, P.`fecha_nacimiento`, P.`estado`
	FROM `v_padron__afiliacion` V
	LEFT JOIN `padron__personas` P ON V.`id_persona`=P.`id_persona`
	WHERE V.`current`='1' AND (V.`id_persona`=FILTRO_SEARCH OR V.`titular`=FILTRO_SEARCH);
END$$

DROP PROCEDURE IF EXISTS `SP_Turnera_Calendario`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_Turnera_Calendario` (IN `p_FECHA` DATE, IN `p_AGENDA` INT, IN `p_CATEGORIA` INT, IN `p_PERIODO` VARCHAR(3))   BEGIN
    WITH RECURSIVE calendario AS (
        SELECT DATE_FORMAT(p_FECHA, "%Y-%m-01") AS fecha
        UNION ALL
        SELECT DATE_ADD(fecha, INTERVAL 1 DAY)
        FROM calendario
        WHERE fecha < LAST_DAY(p_FECHA)
    )

    SELECT 
        F.`fecha`,
        A.`id_agenda`,
        A.`id_categoria`,
        A.`id_feriados`,
        A.`profesional`,
        H.`hora`,
        H.`turnos`,
        COALESCE(T.`total_tomados`, 0) AS "turnos_tomados",
        IF(FERIADOS.`fecha` IS NOT NULL, 1, 0) AS "feriado",
        FN_Turno_No_Cerrado(F.`fecha`,H.`hora`, A.`cierre_dia`,A.`cierre_horario`,A.`id_feriados`) AS "disponible"
    FROM `calendario` F
    JOIN desa__alexis.`turneras__agendas_periodo` P  ON F.`fecha` BETWEEN P.`fecha_desde` AND P.`fecha_hasta`
    JOIN desa__alexis.`turneras__agendas_horarios` H  ON P.`id_periodo` = H.`id_periodo` AND H.`dia_semana` = DAYOFWEEK(F.`fecha`) - 1
    JOIN desa__alexis.`turneras__agenda` A ON A.`id_agenda` = P.`id_agenda` 

    LEFT JOIN (
        SELECT `id_agenda`, `fecha`, `horario`, COUNT(*) AS "total_tomados" 
        FROM desa__alexis.`turneras__turnos` 
        WHERE `estado` >= 1 
        GROUP BY `id_agenda`, `fecha`, `horario`
    ) T  
        ON T.`id_agenda` = A.`id_agenda` 
        AND T.`fecha` = F.`fecha` 
        AND T.`horario` = H.`hora`
    LEFT JOIN desa__alexis.`sys__feriados` FERIADOS 
        ON FERIADOS.`fecha` = F.`fecha` 
        AND (FERIADOS.`id_agenda` = 1 OR FERIADOS.`id_agenda` = A.id_feriados)
    WHERE A.`disponible` = "1" 
        AND (`p_AGENDA` = 0 OR A.`id_agenda` = `p_AGENDA`) 
        AND A.`id_categoria` = `p_CATEGORIA`
        AND (p_PERIODO = "MES" OR F.`fecha` = p_FECHA)
    ORDER BY F.`fecha` ASC;

END$$

DROP PROCEDURE IF EXISTS `SP_Turnera_Intervalos`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_Turnera_Intervalos` (IN `p_ID_PERSONA` INT, IN `p_ID_CATEGORIA` INT, IN `p_TIPO` ENUM("DAY","MONTH","YEAR"), IN `p_LAPSO` INT, IN `p_MAX_TURNOS` INT, IN `p_FECHA_SOLICITADA` DATE)   BEGIN
    DECLARE v_CANTIDAD INT DEFAULT 0;
    DECLARE v_FECHA_LIMITE DATE;
    DECLARE v_MENSAJE VARCHAR(500);
    DECLARE v_TIPO_LAPSO VARCHAR(20);
    DECLARE v_FECHA_SUSPENSION DATE;
    DECLARE v_FECHA_PRIMER_TURNO DATE;
    DECLARE v_FECHA_ULTIMO_TURNO DATE;
    DECLARE v_FECHA_REFERENCIA DATE;
    
    -- 1. Obtener el último turno (reservado o asistido)
    SELECT MAX(fecha) INTO v_FECHA_ULTIMO_TURNO
    FROM desa__alexis.`turneras__turnos`
    WHERE id_persona = p_ID_PERSONA
      AND id_agenda IN (SELECT id_agenda 
                        FROM desa__alexis.`turneras__agenda` 
                        WHERE id_categoria = p_ID_CATEGORIA)
      AND estado IN (1, 11);
    
    -- 2. Determinar la fecha de referencia:
    -- Si el último turno es mayor que la fecha solicitada, se usa ese valor; de lo contrario, se utiliza p_FECHA_SOLICITADA.
    IF v_FECHA_ULTIMO_TURNO IS NOT NULL AND v_FECHA_ULTIMO_TURNO > p_FECHA_SOLICITADA THEN
        SET v_FECHA_REFERENCIA = v_FECHA_ULTIMO_TURNO;
    ELSE
        SET v_FECHA_REFERENCIA = p_FECHA_SOLICITADA;
    END IF;
    
    -- 3. Calcular el intervalo según el tipo, usando la fecha de referencia
    IF p_TIPO = "DAY" THEN
        SET v_FECHA_LIMITE = DATE_SUB(v_FECHA_REFERENCIA, INTERVAL p_LAPSO DAY);
        SET v_TIPO_LAPSO = CONCAT(p_LAPSO, " día", IF(p_LAPSO > 1, "s", ""));
    ELSEIF p_TIPO = "MONTH" THEN
        SET v_FECHA_LIMITE = DATE_SUB(v_FECHA_REFERENCIA, INTERVAL p_LAPSO MONTH);
        SET v_TIPO_LAPSO = CONCAT(p_LAPSO, " mes", IF(p_LAPSO > 1, "es", ""));
    ELSEIF p_TIPO = "YEAR" THEN
        SET v_FECHA_LIMITE = DATE_SUB(v_FECHA_REFERENCIA, INTERVAL p_LAPSO YEAR);
        SET v_TIPO_LAPSO = CONCAT(p_LAPSO, " año", IF(p_LAPSO > 1, "s", ""));
    END IF;
    
    -- 4. Contar los turnos existentes en el intervalo y obtener el primer turno del mismo
    SELECT COUNT(*), MIN(fecha) INTO v_CANTIDAD, v_FECHA_PRIMER_TURNO
    FROM desa__alexis.`turneras__turnos`
    WHERE id_persona = p_ID_PERSONA
      AND id_agenda IN (SELECT id_agenda 
                        FROM desa__alexis.`turneras__agenda` 
                        WHERE id_categoria = p_ID_CATEGORIA)
      AND estado IN (1, 11)
      AND fecha BETWEEN v_FECHA_LIMITE AND v_FECHA_REFERENCIA;
    
    -- Al agregar el nuevo turno, el total sería (v_CANTIDAD + 1).
    IF (v_CANTIDAD + 1) > p_MAX_TURNOS THEN
        -- Se calcula la próxima fecha disponible a partir del primer turno registrado en el intervalo
        IF p_TIPO = "DAY" THEN
            SET v_FECHA_LIMITE = DATE_ADD(v_FECHA_PRIMER_TURNO, INTERVAL p_LAPSO DAY);
        ELSEIF p_TIPO = "MONTH" THEN
            SET v_FECHA_LIMITE = DATE_FORMAT(DATE_ADD(v_FECHA_PRIMER_TURNO, INTERVAL p_LAPSO MONTH), "%Y-%m-01");
        ELSEIF p_TIPO = "YEAR" THEN
            SET v_FECHA_LIMITE = DATE_FORMAT(DATE_ADD(v_FECHA_PRIMER_TURNO, INTERVAL p_LAPSO YEAR), "%Y-01-01");
        END IF;
    
        SET v_MENSAJE = CONCAT("El afiliado ha alcanzado el límite de ", p_MAX_TURNOS,
                               " turno", IF(p_MAX_TURNOS > 1, "s", ""),
                               " cada ", v_TIPO_LAPSO,
                               ". Podrá solicitar un nuevo turno a partir del ", DATE_FORMAT(v_FECHA_LIMITE, "%d/%m/%Y"), ".");
    ELSE
        SET v_MENSAJE = NULL;
    END IF;
    
    -- 5. Buscar si la persona tiene una suspensión activa y agregarla al mensaje
    SELECT MAX(fecha_finalizacion) INTO v_FECHA_SUSPENSION
    FROM desa__alexis.`turneras__suspenciones`
    WHERE id_persona = p_ID_PERSONA 
      AND id_categoria = p_ID_CATEGORIA
      AND fecha_finalizacion >= CURDATE();
    
    IF v_FECHA_SUSPENSION IS NOT NULL THEN
        IF v_MENSAJE IS NOT NULL THEN
            SET v_MENSAJE = CONCAT(v_MENSAJE, " Además, el afiliado tiene una suspensión activa hasta el ", DATE_FORMAT(v_FECHA_SUSPENSION, "%d/%m/%Y"), ".");
        ELSE
            SET v_MENSAJE = CONCAT("El afiliado tiene una suspensión activa hasta el ", DATE_FORMAT(v_FECHA_SUSPENSION, "%d/%m/%Y"), ".");
        END IF;
    END IF;
    
    -- 6. Devolver el mensaje final
    SELECT v_MENSAJE AS Explicacion;
END$$

DROP PROCEDURE IF EXISTS `SP_Turno_Anular`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_Turno_Anular` (IN `p_ID_TURNO` INT, IN `p_HORAS_ANTES` DECIMAL(4,2))   BEGIN
    DECLARE v_ID_AGENDA INT;
    DECLARE v_FECHA_TURNO DATE;
    DECLARE v_HORARIO_TURNO TIME;
    DECLARE v_CIERRE_DIA INT DEFAULT 0;
    DECLARE v_CIERRE_HORARIO TIME DEFAULT NULL;
    DECLARE v_FECHA_LIMITE DATE DEFAULT NULL;
    DECLARE v_HORA_LIMITE TIME DEFAULT NULL;
    DECLARE v_RESULTADO BOOLEAN DEFAULT FALSE;
    DECLARE v_ID_FERIADO INT;

    -- Obtiene datos del turno y la agenda
    SELECT T.id_agenda, T.fecha, T.horario, 
           COALESCE(A.cierre_dia, 0), COALESCE(A.cierre_horario, NULL), A.id_feriados
    INTO v_ID_AGENDA, v_FECHA_TURNO, v_HORARIO_TURNO, v_CIERRE_DIA, v_CIERRE_HORARIO, v_ID_FERIADO
	FROM desa__alexis.`turneras__turnos` T
    JOIN desa__alexis.`turneras__agenda` A ON T.id_agenda = A.id_agenda	
    WHERE T.id_turno = p_ID_TURNO AND T.estado = 1
    LIMIT 1;

    -- Si no encuentra el turno, retorna FALSE inmediatamente
    IF v_ID_AGENDA IS NULL OR v_FECHA_TURNO IS NULL THEN
        SET v_RESULTADO = FALSE;
    ELSE
        -- Si cierre_dia es 0, la fecha límite es el mismo día del turno
        IF v_CIERRE_DIA = 0 THEN
            SET v_FECHA_LIMITE = v_FECHA_TURNO;
            -- Si cierre_horario es NULL, usar la hora del turno menos HORAS_ANTES
            SET v_HORA_LIMITE = IFNULL(v_CIERRE_HORARIO, SEC_TO_TIME(TIME_TO_SEC(v_HORARIO_TURNO) - (p_HORAS_ANTES * 3600)));
        ELSE
            -- Fecha base restando cierre_dia
            SET v_FECHA_LIMITE = DATE_SUB(v_FECHA_TURNO, INTERVAL v_CIERRE_DIA DAY);
            SET v_HORA_LIMITE = IFNULL(v_CIERRE_HORARIO, v_HORARIO_TURNO);
        END IF;

        -- Retroceder si cierre_dia es mayor a 0 y la fecha límite cae en un feriado
        IF v_CIERRE_DIA > 0 THEN
			WHILE v_FECHA_LIMITE IS NOT NULL AND (
    			EXISTS (
        			SELECT 1 FROM desa__alexis.`sys__feriados` F
        			WHERE F.fecha = v_FECHA_LIMITE 
        			AND (F.id_agenda = 1 OR F.id_agenda = v_ID_FERIADO)
    			)
    			OR DAYOFWEEK(v_FECHA_LIMITE) IN (1, 7) -- 1 = Domingo, 7 = Sábado
			) DO
    			SET v_FECHA_LIMITE = DATE_SUB(v_FECHA_LIMITE, INTERVAL 1 DAY);
			END WHILE;
		END IF;
        -- Verifica si se puede anular (Debe ser antes de la fecha y horario límite)
        IF v_FECHA_LIMITE IS NOT NULL AND NOW() < TIMESTAMP(v_FECHA_LIMITE, v_HORA_LIMITE) THEN
            SET v_RESULTADO = TRUE;
        ELSE
            SET v_RESULTADO = FALSE;
        END IF;
    END IF;

    -- Retorna el resultado
    SELECT v_RESULTADO AS es_anulable;
END$$

DROP PROCEDURE IF EXISTS `SP_Turno_Disponible`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_Turno_Disponible` (IN `p_ID_AGENDA` INT, IN `p_FECHA` DATE, IN `p_HORARIO` TIME)   BEGIN
    DECLARE v_DISPONIBLE BOOLEAN DEFAULT TRUE;
    DECLARE v_CIERRE_DIA INT DEFAULT NULL;
    DECLARE v_CIERRE_HORARIO TIME DEFAULT NULL;
    DECLARE v_ID_FERIADO INT DEFAULT NULL;
    DECLARE v_TURNOS_DISPONIBLES INT DEFAULT 0;
    DECLARE v_TURNOS_TOMADOS INT DEFAULT 0;

    -- Obtener datos de la agenda
    SELECT cierre_dia, cierre_horario, id_feriados
      INTO v_CIERRE_DIA, v_CIERRE_HORARIO, v_ID_FERIADO
      FROM desa__alexis.`turneras__agenda`
     WHERE id_agenda = p_ID_AGENDA AND disponible = 1;

    SP_BLOCK: BEGIN
        -- Si la agenda tiene definido el cierre de turno, usamos la función para validarlo.
        IF v_CIERRE_DIA IS NOT NULL AND v_CIERRE_DIA >= 0 THEN
            IF FN_Turno_No_Cerrado(p_FECHA, p_HORARIO, v_CIERRE_DIA, v_CIERRE_HORARIO, v_ID_FERIADO) = 0 THEN
                SET v_DISPONIBLE = FALSE;
                LEAVE SP_BLOCK;
            END IF;
        END IF;

        -- Validar que la fecha esté dentro del período habilitado
        IF NOT EXISTS (
             SELECT 1 
               FROM desa__alexis.`turneras__agendas_periodo`
              WHERE id_agenda = p_ID_AGENDA 
                AND p_FECHA BETWEEN fecha_desde AND fecha_hasta
        ) THEN
             SET v_DISPONIBLE = FALSE;
             LEAVE SP_BLOCK;
        END IF;

        -- Validar que la hora esté definida en la agenda
        IF NOT EXISTS (
             SELECT 1 
               FROM desa__alexis.`turneras__agendas_horarios` H
               JOIN desa__alexis.`turneras__agendas_periodo` P ON H.id_periodo = P.id_periodo
              WHERE P.id_agenda = p_ID_AGENDA
                AND H.dia_semana = DAYOFWEEK(p_FECHA) - 1
                AND H.hora = p_HORARIO
        ) THEN
             SET v_DISPONIBLE = FALSE;
             LEAVE SP_BLOCK;
        END IF;

        -- Validar si la fecha es feriado
        IF EXISTS (
             SELECT 1 
               FROM desa__alexis.`sys__feriados`
              WHERE fecha = p_FECHA AND (id_agenda = 1 OR id_agenda = v_ID_FERIADO)
        ) THEN
             SET v_DISPONIBLE = FALSE;
             LEAVE SP_BLOCK;
        END IF;

        -- Obtener la cantidad de turnos disponibles en el horario
        SELECT H.turnos 
          INTO v_TURNOS_DISPONIBLES
          FROM desa__alexis.`turneras__agendas_horarios` H
          JOIN desa__alexis.`turneras__agendas_periodo` P ON H.id_periodo = P.id_periodo
         WHERE P.id_agenda = p_ID_AGENDA
           AND H.dia_semana = DAYOFWEEK(p_FECHA) - 1
           AND H.hora = p_HORARIO
         LIMIT 1;

        -- Obtener la cantidad de turnos tomados en ese horario
        SELECT COUNT(*) 
          INTO v_TURNOS_TOMADOS
          FROM desa__alexis.`turneras__turnos`
		  WHERE id_agenda = p_ID_AGENDA 
           AND fecha = p_FECHA 
           AND horario = p_HORARIO
           AND estado >= 1;

        -- Si no hay turnos disponibles, rechazar
        IF v_TURNOS_DISPONIBLES IS NULL OR v_TURNOS_TOMADOS >= v_TURNOS_DISPONIBLES THEN
             SET v_DISPONIBLE = FALSE;
             LEAVE SP_BLOCK;
        END IF;
    END SP_BLOCK;

    -- Retornar el resultado final
    SELECT v_DISPONIBLE AS turno_disponible;
END$$

--
-- Funciones
--
DROP FUNCTION IF EXISTS `FN_Turno_No_Cerrado`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `FN_Turno_No_Cerrado` (`p_FECHA` DATE, `p_HORARIO` TIME, `p_CIERRE_DIA` INT, `p_CIERRE_HORARIO` TIME, `p_ID_FERIADO` INT) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE v_FECHA_LIMITE DATE;
    DECLARE v_HORA_LIMITE TIME;
    DECLARE v_CIERRE_DIA_INT INT DEFAULT p_CIERRE_DIA;
    DECLARE v_DISPONIBLE INT DEFAULT 1;
    
    -- Inicializamos la fecha límite
    SET v_FECHA_LIMITE = p_FECHA;
    
    -- Restamos días según la lógica definida
    WHILE v_CIERRE_DIA_INT > 0 AND v_FECHA_LIMITE > "2000-01-01" DO
        SET v_FECHA_LIMITE = DATE_SUB(v_FECHA_LIMITE, INTERVAL 1 DAY);
        
        -- Solo decrementamos si no es sábado (7), domingo (1) ni feriado
        IF DAYOFWEEK(v_FECHA_LIMITE) NOT IN (1, 7)
           AND NOT EXISTS (
               SELECT 1 
               FROM desa__alexis.`sys__feriados` 
               WHERE fecha = v_FECHA_LIMITE 
                 AND (id_agenda = 1 OR id_agenda = p_ID_FERIADO)
           ) THEN
            SET v_CIERRE_DIA_INT = v_CIERRE_DIA_INT - 1;
        END IF;
    END WHILE;
    
    SET v_HORA_LIMITE = IFNULL(p_CIERRE_HORARIO, p_HORARIO);
    
    -- Verificamos si ya pasó el tiempo límite
    IF NOW() > TIMESTAMP(v_FECHA_LIMITE, v_HORA_LIMITE) THEN
        SET v_DISPONIBLE = 0;
    END IF;
    
    RETURN v_DISPONIBLE;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `parametricas__turneras_categorias`
--

DROP TABLE IF EXISTS `parametricas__turneras_categorias`;
CREATE TABLE `parametricas__turneras_categorias` (
  `id_categoria` tinyint(3) UNSIGNED NOT NULL,
  `categoria` varchar(30) NOT NULL,
  `sobreturnos` tinyint(1) NOT NULL DEFAULT 0,
  `sobreturnos_padre` tinyint(3) UNSIGNED DEFAULT NULL,
  `intervalos_max_turnos` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `intervalo_lapso` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `intervalos_tipo` varchar(10) DEFAULT NULL,
  `reg_usuario` smallint(5) UNSIGNED DEFAULT NULL,
  `reg_fecha` datetime DEFAULT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sys__turneras_permisos`
--

DROP TABLE IF EXISTS `sys__turneras_permisos`;
CREATE TABLE `sys__turneras_permisos` (
  `id_usuario` smallint(5) UNSIGNED NOT NULL,
  `id_categoria` tinyint(3) UNSIGNED NOT NULL,
  `permiso` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sys__turneras_permisos`
--

INSERT INTO `sys__turneras_permisos` (`id_usuario`, `id_categoria`, `permiso`) VALUES
(1, 1, 'C'),
(1, 2, 'C'),
(1, 3, 'C'),
(1, 4, 'C'),
(1, 5, 'C'),
(1, 6, 'C'),
(1, 7, 'C'),
(1, 8, 'C'),
(1, 9, 'C'),
(1, 10, 'C'),
(1, 11, 'C'),
(1, 12, 'C'),
(12, 1, 'CABME'),
(12, 12, 'CABME');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sys__users`
--

DROP TABLE IF EXISTS `sys__users`;
CREATE TABLE `sys__users` (
  `id_usuario` int(11) NOT NULL,
  `usuario` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `dni` int(10) UNSIGNED NOT NULL,
  `login_hash` varchar(32) DEFAULT NULL,
  `login_date` datetime DEFAULT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sys__users`
--

INSERT INTO `sys__users` (`id_usuario`, `usuario`, `password`, `dni`, `login_hash`, `login_date`, `disponible`) VALUES
(1, 'ADMIN', '$2y$10$C.eDGe2ViK3Rw5wkxG1DZuDsB0ZjXG.cd.ZS1jy9bTkJwhNIvMAIO', 39490719, '3f2d8e6ce019fe476b97b6deb7613082', '2026-04-22 16:29:55', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sys__users_logs`
--

DROP TABLE IF EXISTS `sys__users_logs`;
CREATE TABLE `sys__users_logs` (
  `id_usuario` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `login_datetime` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sys__users_logs`
--

INSERT INTO `sys__users_logs` (`id_usuario`, `ip_address`, `login_datetime`) VALUES
(1, '127.0.0.1', '2026-04-03 23:33:50'),
(1, '127.0.0.1', '2026-04-03 23:33:56'),
(1, '127.0.0.1', '2026-04-03 23:46:17'),
(1, '127.0.0.1', '2026-04-04 00:23:37'),
(1, '127.0.0.1', '2026-04-04 00:51:44'),
(1, '::1', '2026-04-07 14:31:32'),
(1, '::1', '2026-04-07 14:35:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sys__users_mail`
--

DROP TABLE IF EXISTS `sys__users_mail`;
CREATE TABLE `sys__users_mail` (
  `id_usuario` int(11) NOT NULL,
  `correo` varchar(255) NOT NULL,
  `hash` varchar(32) DEFAULT NULL,
  `reg_fecha` datetime NOT NULL,
  `recovery_hash` varchar(32) DEFAULT NULL,
  `recovery_datetime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sys__users_mail`
--

INSERT INTO `sys__users_mail` (`id_usuario`, `correo`, `hash`, `reg_fecha`, `recovery_hash`, `recovery_datetime`) VALUES
(1, 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, '2026-04-03 23:31:58', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sys__users_permisos`
--

DROP TABLE IF EXISTS `sys__users_permisos`;
CREATE TABLE `sys__users_permisos` (
  `id_usuario` int(10) UNSIGNED NOT NULL,
  `route` varchar(255) NOT NULL,
  `permiso` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sys__users_permisos`
--

INSERT INTO `sys__users_permisos` (`id_usuario`, `route`, `permiso`) VALUES
(1, 'Usuarios', 'CABM'),
(1, 'Sistema', 'C'),
(1, 'TurnerasAdministrar', 'CAMBE'),
(1, 'Turneras', 'C'),
(1, 'TurnerasAgenda', 'C'),
(1, 'TurnerasCalendario', 'C'),
(1, 'TurnerasDas', 'C'),
(1, 'PsicologiaCalendario', 'CAMBE'),
(1, 'Psicologia', 'C'),
(1, 'PsicologiaAdministrar', 'CAMBE');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__agenda`
--

DROP TABLE IF EXISTS `turneras__agenda`;
CREATE TABLE `turneras__agenda` (
  `id_agenda` int(11) NOT NULL,
  `id_categoria` int(11) NOT NULL,
  `profesional` varchar(100) NOT NULL,
  `edad_minima` tinyint(3) UNSIGNED DEFAULT NULL,
  `edad_maxima` tinyint(3) UNSIGNED DEFAULT NULL,
  `sexo` varchar(3) DEFAULT NULL,
  `cierre_dia` tinyint(4) NOT NULL DEFAULT 0,
  `cierre_horario` time DEFAULT NULL,
  `correo_subj` varchar(255) DEFAULT NULL,
  `correo_mens` text DEFAULT NULL,
  `portal` tinyint(1) NOT NULL DEFAULT 0,
  `id_feriados` tinyint(3) UNSIGNED NOT NULL,
  `reg_usuario` smallint(5) UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__agendas_horarios`
--

DROP TABLE IF EXISTS `turneras__agendas_horarios`;
CREATE TABLE `turneras__agendas_horarios` (
  `id_horario` int(11) NOT NULL,
  `id_periodo` int(11) NOT NULL,
  `dia_semana` tinyint(3) UNSIGNED NOT NULL,
  `hora` time NOT NULL,
  `turnos` tinyint(3) UNSIGNED NOT NULL,
  `reg_usuario` smallint(5) UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__agendas_periodo`
--

DROP TABLE IF EXISTS `turneras__agendas_periodo`;
CREATE TABLE `turneras__agendas_periodo` (
  `id_periodo` int(11) NOT NULL,
  `id_agenda` int(11) NOT NULL,
  `fecha_desde` date NOT NULL,
  `fecha_hasta` date NOT NULL,
  `reg_usuario` smallint(5) UNSIGNED DEFAULT NULL,
  `reg_fecha` datetime NOT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__suspenciones`
--

DROP TABLE IF EXISTS `turneras__suspenciones`;
CREATE TABLE `turneras__suspenciones` (
  `id_suspencion` int(10) UNSIGNED NOT NULL,
  `id_persona` smallint(5) UNSIGNED NOT NULL,
  `id_categoria` tinyint(3) UNSIGNED NOT NULL,
  `fecha_finalizacion` date NOT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `reg_usuario` smallint(5) UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__turnos`
--

DROP TABLE IF EXISTS `turneras__turnos`;
CREATE TABLE `turneras__turnos` (
  `id_turno` int(10) UNSIGNED NOT NULL,
  `id_persona` int(10) UNSIGNED DEFAULT NULL,
  `id_agenda` int(10) UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `horario` time NOT NULL,
  `celular` varchar(50) DEFAULT NULL,
  `mail` varchar(80) DEFAULT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `reg_usuario` smallint(5) UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL,
  `reg_ip` varchar(32) NOT NULL,
  `estado` tinyint(3) UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=ANULADO\r\n1=PENDIENTE\r\n10=AUSENTE\r\n11=PRESENTE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `parametricas__turneras_categorias`
--
ALTER TABLE `parametricas__turneras_categorias`
  ADD PRIMARY KEY (`id_categoria`),
  ADD UNIQUE KEY `categoria` (`categoria`);

--
-- Indices de la tabla `sys__turneras_permisos`
--
ALTER TABLE `sys__turneras_permisos`
  ADD UNIQUE KEY `id_usuario` (`id_usuario`,`id_categoria`);

--
-- Indices de la tabla `sys__users`
--
ALTER TABLE `sys__users`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `username` (`usuario`);

--
-- Indices de la tabla `sys__users_logs`
--
ALTER TABLE `sys__users_logs`
  ADD PRIMARY KEY (`id_usuario`,`login_datetime`);

--
-- Indices de la tabla `sys__users_mail`
--
ALTER TABLE `sys__users_mail`
  ADD PRIMARY KEY (`id_usuario`,`correo`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `turneras__agenda`
--
ALTER TABLE `turneras__agenda`
  ADD PRIMARY KEY (`id_agenda`);

--
-- Indices de la tabla `turneras__agendas_horarios`
--
ALTER TABLE `turneras__agendas_horarios`
  ADD PRIMARY KEY (`id_horario`);

--
-- Indices de la tabla `turneras__agendas_periodo`
--
ALTER TABLE `turneras__agendas_periodo`
  ADD PRIMARY KEY (`id_periodo`),
  ADD KEY `id_agenda` (`id_agenda`);

--
-- Indices de la tabla `turneras__suspenciones`
--
ALTER TABLE `turneras__suspenciones`
  ADD PRIMARY KEY (`id_suspencion`);

--
-- Indices de la tabla `turneras__turnos`
--
ALTER TABLE `turneras__turnos`
  ADD PRIMARY KEY (`id_turno`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `parametricas__turneras_categorias`
--
ALTER TABLE `parametricas__turneras_categorias`
  MODIFY `id_categoria` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `sys__users`
--
ALTER TABLE `sys__users`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `turneras__agenda`
--
ALTER TABLE `turneras__agenda`
  MODIFY `id_agenda` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `turneras__agendas_horarios`
--
ALTER TABLE `turneras__agendas_horarios`
  MODIFY `id_horario` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `turneras__agendas_periodo`
--
ALTER TABLE `turneras__agendas_periodo`
  MODIFY `id_periodo` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `turneras__suspenciones`
--
ALTER TABLE `turneras__suspenciones`
  MODIFY `id_suspencion` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `turneras__turnos`
--
ALTER TABLE `turneras__turnos`
  MODIFY `id_turno` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `sys__users_logs`
--
ALTER TABLE `sys__users_logs`
  ADD CONSTRAINT `sys__users_logs_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `sys__users` (`id_usuario`) ON DELETE CASCADE;

--
-- Filtros para la tabla `sys__users_mail`
--
ALTER TABLE `sys__users_mail`
  ADD CONSTRAINT `sys__users_mail_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `sys__users` (`id_usuario`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
