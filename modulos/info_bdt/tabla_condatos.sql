-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 22-04-2026 a las 20:13:43
-- Versión del servidor: 8.1.0
-- Versión de PHP: 8.3.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `desa__alexis`
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
CREATE DEFINER=`root`@`localhost` FUNCTION `FN_Turno_No_Cerrado` (`p_FECHA` DATE, `p_HORARIO` TIME, `p_CIERRE_DIA` INT, `p_CIERRE_HORARIO` TIME, `p_ID_FERIADO` INT) RETURNS INT DETERMINISTIC BEGIN
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
  `id_categoria` tinyint UNSIGNED NOT NULL,
  `categoria` varchar(20) NOT NULL,
  `sobreturnos` tinyint(1) NOT NULL DEFAULT '0',
  `sobreturnos_padre` tinyint UNSIGNED DEFAULT NULL,
  `intervalos_max_turnos` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `intervalo_lapso` smallint UNSIGNED NOT NULL DEFAULT '0',
  `intervalos_tipo` varchar(10) DEFAULT NULL,
  `reg_usuario` smallint UNSIGNED DEFAULT NULL,
  `reg_fecha` datetime DEFAULT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `parametricas__turneras_categorias`
--

INSERT INTO `parametricas__turneras_categorias` (`id_categoria`, `categoria`, `sobreturnos`, `sobreturnos_padre`, `intervalos_max_turnos`, `intervalo_lapso`, `intervalos_tipo`, `reg_usuario`, `reg_fecha`, `disponible`) VALUES
(1, 'ODONTOLOGIA', 0, NULL, 1, 30, 'DAY', 1, '2025-02-20 12:47:29', 1),
(2, 'DIABETES', 0, NULL, 2, 3, 'MONTH', 1, '2025-02-19 19:59:59', 1),
(3, 'GINECO', 0, NULL, 0, 365, 'DAY', 1, '2025-02-19 20:00:11', 1),
(4, 'CHEQUEO ANUAL', 0, NULL, 1, 1, 'YEAR', 1, '2025-03-18 14:25:07', 1),
(5, 'GENERO', 0, NULL, 0, 0, '', 1, '2025-02-20 06:56:25', 1),
(6, 'PRUEBA 1', 0, NULL, 1, 2, 'MONTH', 9, '2025-02-24 11:20:39', 1),
(7, 'PRUEBA 2', 0, NULL, 1, 15, 'DAY', 9, '2025-02-24 14:17:07', 1),
(8, 'PRUEBA 3', 0, NULL, 1, 1, 'MONTH', 9, '2025-02-24 15:44:27', 1),
(9, 'PRUEBA PERMISO', 0, NULL, 1, 7, 'DAY', 12, '2025-04-15 12:08:51', 1),
(10, 'PERMISO E', 0, NULL, 1, 7, 'DAY', 12, '2025-04-15 12:17:58', 1),
(11, 'ASD', 0, NULL, 0, 0, '', 1, '2025-04-28 14:07:08', 1),
(12, 'ODONTOLOGIA ST', 1, 1, 0, 0, NULL, 1, '2025-05-13 08:38:54', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sys__turneras_permisos`
--

DROP TABLE IF EXISTS `sys__turneras_permisos`;
CREATE TABLE `sys__turneras_permisos` (
  `id_usuario` smallint UNSIGNED NOT NULL,
  `id_categoria` tinyint UNSIGNED NOT NULL,
  `permiso` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
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
-- Estructura de tabla para la tabla `turneras__agenda`
--

DROP TABLE IF EXISTS `turneras__agenda`;
CREATE TABLE `turneras__agenda` (
  `id_agenda` int NOT NULL,
  `id_categoria` int NOT NULL,
  `profesional` varchar(100) NOT NULL,
  `edad_minima` tinyint UNSIGNED DEFAULT NULL,
  `edad_maxima` tinyint UNSIGNED DEFAULT NULL,
  `sexo` varchar(3) DEFAULT NULL,
  `cierre_dia` tinyint NOT NULL DEFAULT '0',
  `cierre_horario` time DEFAULT NULL,
  `correo_subj` varchar(255) DEFAULT NULL,
  `correo_mens` text,
  `portal` tinyint(1) NOT NULL DEFAULT '0',
  `id_feriados` tinyint UNSIGNED NOT NULL,
  `reg_usuario` smallint UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `turneras__agenda`
--

INSERT INTO `turneras__agenda` (`id_agenda`, `id_categoria`, `profesional`, `edad_minima`, `edad_maxima`, `sexo`, `cierre_dia`, `cierre_horario`, `correo_subj`, `correo_mens`, `portal`, `id_feriados`, `reg_usuario`, `reg_fecha`, `disponible`) VALUES
(1, 4, 'FAVALORO', 18, 120, 'FMX', 2, '16:00:00', 'Chequeo Anual Favaloro', 'Prueba comillas E', 1, 2, 12, '2025-04-15 13:53:54', 1),
(2, 2, 'GENERAL', 18, 120, 'FMX', 0, NULL, 'DIABETES', 'B', 1, 2, 12, '2025-04-15 14:08:45', 1),
(3, 5, 'GENERAL', 18, 120, 'FMX', 0, NULL, 'C', 'C', 0, 2, 12, '2025-04-15 13:43:03', 1),
(4, 9, 'GENERAL', 18, 120, 'FMX', 0, NULL, 'Acceso a agenda', 'Prueba de permiso E', 0, 2, 12, '2025-04-15 12:17:31', 1),
(5, 10, 'GENERAL', 18, 120, 'FMX', 0, NULL, 'ASUNTO', 'AS', 0, 2, 12, '2025-04-15 12:18:16', 1),
(6, 4, 'FINOCHIETTO', 18, 120, 'FMX', 0, NULL, 'Chequeo Anual Finochietto', 'PREPARACION PARA LA REALIZACION DE LOS CHEQUEOS\nHaber realizado 8 horas de ayuno (se puede tomar agua libremente).\nTraer la primera orina de la mañana.\nVestir ropa deportiva o comoda para realizar la prueba de esfuerzo.\nDebera presentarse en Boulogne Sur Mer 972. 3º Piso - CABA', 1, 4, 12, '2025-04-16 12:43:05', 1),
(7, 1, 'PROFESIONAL 1', 18, 120, 'FMX', 0, NULL, 'ODONTOLOGÍA', 'Por favor concurrir con 15 minutos de anticipación.', 0, 2, 12, '2025-04-15 13:50:23', 1),
(8, 12, 'PROFESIONAL 1', 18, 120, 'FMX', 0, NULL, 'ODONTOLOGÍA', 'Por favor concurrir con 15 minutos de anticipación.', 0, 2, 12, '2025-04-15 13:50:23', 1),
(9, 1, 'ANA ANTAKLE', 18, 120, 'FMX', 0, NULL, 'ODONTOLOGÍA', 'Por favor concurrir con 15 minutos de anticipación.', 0, 2, 12, '2025-05-13 11:13:52', 1),
(10, 12, 'ANA ANTAKLE', 18, 120, 'FMX', 0, NULL, 'SOBRETURNOS', 'Por favor concurrir con 15 minutos de anticipación.', 0, 2, 12, '2025-05-13 11:15:27', 1),
(11, 6, 'GENERAL', 18, 120, 'FMX', 0, '17:00:00', 'a', 'xds', 1, 3, 8, '2025-05-26 09:47:59', 1),
(12, 7, 'GENERAL', 18, 120, 'FMX', 0, NULL, 'c', 'c', 1, 4, 8, '2025-05-26 09:42:30', 1),
(13, 1, 'GENERAL', 18, 120, 'FMX', 0, NULL, 'a', 'a', 1, 2, 8, '2025-05-26 09:52:40', 1),
(14, 4, 'FAVLORO', 18, 120, 'FMX', 1, '18:00:00', 'turno favaloro', 'Turno prueba favaloro', 0, 3, 12, '2025-07-11 14:07:04', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__agendas_horarios`
--

DROP TABLE IF EXISTS `turneras__agendas_horarios`;
CREATE TABLE `turneras__agendas_horarios` (
  `id_horario` int NOT NULL,
  `id_periodo` int NOT NULL,
  `dia_semana` tinyint UNSIGNED NOT NULL,
  `hora` time NOT NULL,
  `turnos` tinyint UNSIGNED NOT NULL,
  `reg_usuario` smallint UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `turneras__agendas_horarios`
--

INSERT INTO `turneras__agendas_horarios` (`id_horario`, `id_periodo`, `dia_semana`, `hora`, `turnos`, `reg_usuario`, `reg_fecha`) VALUES
(13, 5, 1, '09:00:00', 1, 1, '2025-03-11 09:49:06'),
(14, 5, 2, '09:00:00', 1, 1, '2025-03-11 09:49:06'),
(15, 5, 3, '09:00:00', 1, 1, '2025-03-11 09:49:06'),
(16, 5, 4, '09:00:00', 1, 1, '2025-03-11 09:49:06'),
(17, 5, 5, '09:00:00', 1, 1, '2025-03-11 09:49:06'),
(18, 5, 1, '09:30:00', 1, 1, '2025-03-11 09:49:15'),
(19, 5, 2, '09:30:00', 1, 1, '2025-03-11 09:49:15'),
(20, 5, 3, '09:30:00', 1, 1, '2025-03-11 09:49:15'),
(21, 5, 4, '09:30:00', 1, 1, '2025-03-11 09:49:15'),
(22, 5, 5, '09:30:00', 1, 1, '2025-03-11 09:49:15'),
(24, 6, 1, '09:00:00', 1, 1, '2025-03-11 09:50:07'),
(25, 6, 2, '09:00:00', 1, 1, '2025-03-11 09:50:07'),
(26, 6, 3, '09:00:00', 1, 1, '2025-03-11 09:50:07'),
(27, 6, 4, '09:00:00', 1, 1, '2025-03-11 09:50:07'),
(28, 6, 5, '09:00:00', 1, 1, '2025-03-11 09:50:07'),
(29, 6, 1, '09:30:00', 1, 1, '2025-03-11 09:50:07'),
(30, 6, 2, '09:30:00', 1, 1, '2025-03-11 09:50:07'),
(31, 6, 3, '09:30:00', 1, 1, '2025-03-11 09:50:07'),
(32, 6, 4, '09:30:00', 1, 1, '2025-03-11 09:50:07'),
(33, 6, 5, '09:30:00', 1, 1, '2025-03-11 09:50:07'),
(34, 6, 1, '14:26:00', 1, 1, '2025-03-17 14:25:54'),
(35, 3, 1, '09:30:00', 5, 12, '2025-04-15 13:59:43'),
(36, 3, 2, '09:30:00', 5, 12, '2025-04-15 13:59:43'),
(37, 3, 3, '09:30:00', 5, 12, '2025-04-15 13:59:43'),
(38, 3, 4, '09:30:00', 5, 12, '2025-04-15 13:59:43'),
(39, 3, 5, '09:30:00', 5, 12, '2025-04-15 13:59:43'),
(40, 3, 1, '14:00:00', 5, 12, '2025-04-15 14:00:06'),
(41, 3, 2, '14:00:00', 5, 12, '2025-04-15 14:00:06'),
(42, 3, 3, '14:00:00', 5, 12, '2025-04-15 14:00:06'),
(43, 3, 4, '14:00:00', 5, 12, '2025-04-15 14:00:06'),
(44, 3, 5, '14:00:00', 5, 12, '2025-04-15 14:00:06'),
(45, 8, 1, '07:00:00', 5, 12, '2025-04-15 14:02:51'),
(46, 8, 2, '07:00:00', 5, 12, '2025-04-15 14:02:51'),
(47, 8, 3, '07:00:00', 5, 12, '2025-04-15 14:02:51'),
(48, 8, 4, '07:00:00', 5, 12, '2025-04-15 14:02:51'),
(49, 8, 5, '07:00:00', 5, 12, '2025-04-15 14:02:51'),
(50, 8, 1, '07:15:00', 5, 12, '2025-04-15 14:03:01'),
(51, 8, 2, '07:15:00', 5, 12, '2025-04-15 14:03:01'),
(52, 8, 3, '07:15:00', 5, 12, '2025-04-15 14:03:01'),
(53, 8, 4, '07:15:00', 5, 12, '2025-04-15 14:03:01'),
(54, 8, 5, '07:15:00', 5, 12, '2025-04-15 14:03:01'),
(55, 9, 1, '08:00:00', 5, 12, '2025-04-15 14:04:19'),
(56, 9, 2, '08:00:00', 5, 12, '2025-04-15 14:04:20'),
(57, 9, 3, '08:00:00', 5, 12, '2025-04-15 14:04:20'),
(58, 9, 4, '08:00:00', 5, 12, '2025-04-15 14:04:21'),
(59, 9, 5, '08:00:00', 5, 12, '2025-04-15 14:04:21'),
(60, 11, 1, '09:00:00', 1, 12, '2025-04-15 14:12:34'),
(61, 11, 2, '09:00:00', 1, 12, '2025-04-15 14:12:34'),
(62, 11, 3, '09:00:00', 1, 12, '2025-04-15 14:12:34'),
(63, 11, 4, '09:00:00', 1, 12, '2025-04-15 14:12:34'),
(64, 11, 5, '09:00:00', 1, 12, '2025-04-15 14:12:34'),
(65, 11, 1, '09:45:00', 1, 12, '2025-04-15 14:12:43'),
(66, 11, 2, '09:45:00', 1, 12, '2025-04-15 14:12:43'),
(67, 11, 3, '09:45:00', 1, 12, '2025-04-15 14:12:43'),
(68, 11, 4, '09:45:00', 1, 12, '2025-04-15 14:12:43'),
(69, 11, 5, '09:45:00', 1, 12, '2025-04-15 14:12:43'),
(70, 11, 1, '10:30:00', 1, 12, '2025-04-15 14:12:52'),
(71, 11, 2, '10:30:00', 1, 12, '2025-04-15 14:12:52'),
(72, 11, 3, '10:30:00', 1, 12, '2025-04-15 14:12:52'),
(73, 11, 4, '10:30:00', 1, 12, '2025-04-15 14:12:52'),
(74, 11, 5, '10:30:00', 1, 12, '2025-04-15 14:12:52'),
(75, 11, 1, '11:00:00', 1, 12, '2025-04-15 14:12:59'),
(76, 11, 2, '11:00:00', 1, 12, '2025-04-15 14:12:59'),
(77, 11, 3, '11:00:00', 1, 12, '2025-04-15 14:12:59'),
(78, 11, 4, '11:00:00', 1, 12, '2025-04-15 14:12:59'),
(79, 11, 5, '11:00:00', 1, 12, '2025-04-15 14:12:59'),
(80, 11, 1, '11:30:00', 1, 12, '2025-04-15 14:13:35'),
(81, 11, 2, '11:30:00', 1, 12, '2025-04-15 14:13:35'),
(82, 11, 3, '11:30:00', 1, 12, '2025-04-15 14:13:35'),
(83, 11, 4, '11:30:00', 1, 12, '2025-04-15 14:13:35'),
(84, 11, 5, '11:30:00', 1, 12, '2025-04-15 14:13:35'),
(85, 13, 1, '10:00:00', 1, 1, '2025-05-13 10:41:57'),
(86, 13, 2, '10:00:00', 1, 1, '2025-05-13 10:41:57'),
(87, 13, 3, '10:00:00', 1, 1, '2025-05-13 10:41:57'),
(88, 13, 4, '10:00:00', 1, 1, '2025-05-13 10:41:57'),
(89, 13, 5, '10:00:00', 1, 1, '2025-05-13 10:41:57'),
(90, 14, 1, '08:00:00', 1, 12, '2025-05-13 11:16:23'),
(91, 14, 2, '08:00:00', 1, 12, '2025-05-13 11:16:23'),
(92, 14, 3, '08:00:00', 1, 12, '2025-05-13 11:16:23'),
(93, 14, 4, '08:00:00', 1, 12, '2025-05-13 11:16:23'),
(94, 14, 5, '08:00:00', 1, 12, '2025-05-13 11:16:23'),
(95, 14, 1, '08:45:00', 1, 12, '2025-05-13 11:16:30'),
(96, 14, 2, '08:45:00', 1, 12, '2025-05-13 11:16:30'),
(97, 14, 3, '08:45:00', 1, 12, '2025-05-13 11:16:30'),
(98, 14, 4, '08:45:00', 1, 12, '2025-05-13 11:16:30'),
(99, 14, 5, '08:45:00', 1, 12, '2025-05-13 11:16:30'),
(100, 14, 1, '09:30:00', 1, 12, '2025-05-13 11:16:40'),
(101, 14, 2, '09:30:00', 1, 12, '2025-05-13 11:16:40'),
(102, 14, 3, '09:30:00', 1, 12, '2025-05-13 11:16:40'),
(103, 14, 4, '09:30:00', 1, 12, '2025-05-13 11:16:40'),
(104, 14, 5, '09:30:00', 1, 12, '2025-05-13 11:16:40'),
(105, 14, 1, '10:15:00', 1, 12, '2025-05-13 11:16:47'),
(106, 14, 2, '10:15:00', 1, 12, '2025-05-13 11:16:47'),
(107, 14, 3, '10:15:00', 1, 12, '2025-05-13 11:16:47'),
(108, 14, 4, '10:15:00', 1, 12, '2025-05-13 11:16:47'),
(109, 14, 5, '10:15:00', 1, 12, '2025-05-13 11:16:47'),
(110, 13, 1, '08:00:00', 1, 9, '2025-05-13 11:20:52'),
(111, 13, 2, '08:00:00', 1, 9, '2025-05-13 11:23:06'),
(112, 15, 1, '08:00:00', 1, 12, '2025-05-13 11:25:10'),
(113, 15, 2, '08:00:00', 1, 12, '2025-05-13 11:25:10'),
(114, 15, 3, '08:00:00', 1, 12, '2025-05-13 11:25:10'),
(115, 15, 4, '08:00:00', 1, 12, '2025-05-13 11:25:10'),
(116, 15, 5, '08:00:00', 1, 12, '2025-05-13 11:25:10'),
(117, 15, 1, '08:45:00', 1, 12, '2025-05-13 11:25:18'),
(118, 15, 2, '08:45:00', 1, 12, '2025-05-13 11:25:18'),
(119, 15, 3, '08:45:00', 1, 12, '2025-05-13 11:25:18'),
(120, 15, 4, '08:45:00', 1, 12, '2025-05-13 11:25:19'),
(121, 15, 5, '08:45:00', 1, 12, '2025-05-13 11:25:19'),
(122, 15, 1, '09:30:00', 1, 12, '2025-05-13 11:25:26'),
(123, 15, 2, '09:30:00', 1, 12, '2025-05-13 11:25:26'),
(124, 15, 3, '09:30:00', 1, 12, '2025-05-13 11:25:26'),
(125, 15, 4, '09:30:00', 1, 12, '2025-05-13 11:25:27'),
(126, 15, 5, '09:30:00', 1, 12, '2025-05-13 11:25:27'),
(127, 15, 1, '10:15:00', 1, 12, '2025-05-13 11:25:34'),
(128, 15, 2, '10:15:00', 1, 12, '2025-05-13 11:25:34'),
(129, 15, 3, '10:15:00', 1, 12, '2025-05-13 11:25:34'),
(130, 15, 4, '10:15:00', 1, 12, '2025-05-13 11:25:34'),
(131, 15, 5, '10:15:00', 1, 12, '2025-05-13 11:25:34'),
(132, 16, 1, '09:38:00', 25, 8, '2025-05-26 09:38:55'),
(133, 16, 2, '09:38:00', 25, 8, '2025-05-26 09:38:55'),
(134, 16, 3, '09:38:00', 25, 8, '2025-05-26 09:38:55'),
(135, 16, 4, '09:38:00', 25, 8, '2025-05-26 09:38:55'),
(136, 16, 5, '09:38:00', 25, 8, '2025-05-26 09:38:55'),
(137, 17, 1, '11:40:00', 5, 8, '2025-05-26 09:48:14'),
(138, 17, 2, '11:40:00', 25, 8, '2025-05-26 09:40:08'),
(139, 17, 3, '11:40:00', 25, 8, '2025-05-26 09:40:08'),
(140, 17, 4, '11:40:00', 25, 8, '2025-05-26 09:40:08'),
(141, 17, 5, '11:40:00', 25, 8, '2025-05-26 09:40:08'),
(142, 18, 1, '10:00:00', 1, 8, '2025-05-26 09:56:50'),
(143, 18, 2, '10:00:00', 1, 8, '2025-05-26 09:56:50'),
(144, 18, 4, '10:00:00', 1, 8, '2025-05-26 09:56:50'),
(145, 18, 5, '10:00:00', 1, 8, '2025-05-26 09:56:50'),
(146, 19, 1, '10:00:00', 1, 8, '2025-05-26 09:58:09'),
(147, 19, 2, '10:00:00', 1, 8, '2025-05-26 09:58:09'),
(148, 19, 4, '10:00:00', 1, 8, '2025-05-26 09:58:09'),
(149, 19, 5, '10:00:00', 1, 8, '2025-05-26 09:58:09'),
(155, 21, 1, '10:00:00', 1, 12, '2025-07-14 15:51:46'),
(156, 21, 2, '10:00:00', 1, 12, '2025-07-14 15:51:46'),
(157, 21, 3, '10:00:00', 1, 12, '2025-07-14 15:51:46'),
(158, 21, 4, '10:00:00', 1, 12, '2025-07-14 15:51:46'),
(159, 21, 5, '10:00:00', 1, 12, '2025-07-14 15:51:46'),
(162, 13, 1, '11:00:00', 1, 12, '2025-07-14 17:25:56'),
(163, 13, 2, '11:00:00', 1, 12, '2025-07-14 17:25:56'),
(164, 13, 3, '11:00:00', 1, 12, '2025-07-14 17:25:56'),
(165, 13, 4, '11:00:00', 1, 12, '2025-07-14 17:25:56'),
(166, 13, 5, '11:00:00', 1, 12, '2025-07-14 17:25:56'),
(167, 13, 1, '12:00:00', 1, 12, '2025-07-14 17:26:03'),
(168, 13, 2, '12:00:00', 1, 12, '2025-07-14 17:26:03'),
(169, 13, 3, '12:00:00', 1, 12, '2025-07-14 17:26:03'),
(170, 13, 4, '12:00:00', 1, 12, '2025-07-14 17:26:03'),
(171, 13, 5, '12:00:00', 1, 12, '2025-07-14 17:26:03'),
(172, 13, 1, '13:00:00', 1, 12, '2025-07-14 17:26:09'),
(173, 13, 2, '13:00:00', 1, 12, '2025-07-14 17:26:09'),
(174, 13, 3, '13:00:00', 1, 12, '2025-07-14 17:26:09'),
(175, 13, 4, '13:00:00', 1, 12, '2025-07-14 17:26:09'),
(176, 13, 5, '13:00:00', 1, 12, '2025-07-14 17:26:09'),
(177, 13, 1, '14:00:00', 1, 12, '2025-07-14 17:26:15'),
(178, 13, 2, '14:00:00', 1, 12, '2025-07-14 17:26:15'),
(179, 13, 3, '14:00:00', 1, 12, '2025-07-14 17:26:15'),
(180, 13, 4, '14:00:00', 1, 12, '2025-07-14 17:26:15'),
(181, 13, 5, '14:00:00', 1, 12, '2025-07-14 17:26:15'),
(182, 13, 1, '15:00:00', 1, 12, '2025-07-14 17:26:22'),
(183, 13, 2, '15:00:00', 1, 12, '2025-07-14 17:26:22'),
(184, 13, 3, '15:00:00', 1, 12, '2025-07-14 17:26:22'),
(185, 13, 4, '15:00:00', 1, 12, '2025-07-14 17:26:22'),
(186, 13, 5, '15:00:00', 1, 12, '2025-07-14 17:26:22'),
(187, 21, 1, '11:00:00', 1, 12, '2025-07-14 17:27:25'),
(188, 21, 2, '11:00:00', 1, 12, '2025-07-14 17:27:25'),
(189, 21, 3, '11:00:00', 1, 12, '2025-07-14 17:27:25'),
(190, 21, 4, '11:00:00', 1, 12, '2025-07-14 17:27:25'),
(191, 21, 5, '11:00:00', 1, 12, '2025-07-14 17:27:25'),
(192, 21, 1, '12:00:00', 1, 12, '2025-07-14 17:27:31'),
(193, 21, 2, '12:00:00', 1, 12, '2025-07-14 17:27:31'),
(194, 21, 3, '12:00:00', 1, 12, '2025-07-14 17:27:31'),
(195, 21, 4, '12:00:00', 1, 12, '2025-07-14 17:27:31'),
(196, 21, 5, '12:00:00', 1, 12, '2025-07-14 17:27:31'),
(197, 21, 1, '13:00:00', 1, 12, '2025-07-14 17:27:36'),
(198, 21, 2, '13:00:00', 1, 12, '2025-07-14 17:27:36'),
(199, 21, 3, '13:00:00', 1, 12, '2025-07-14 17:27:36'),
(200, 21, 4, '13:00:00', 1, 12, '2025-07-14 17:27:36'),
(201, 21, 5, '13:00:00', 1, 12, '2025-07-14 17:27:36'),
(202, 21, 1, '14:00:00', 1, 12, '2025-07-14 17:27:43'),
(203, 21, 2, '14:00:00', 1, 12, '2025-07-14 17:27:43'),
(204, 21, 3, '14:00:00', 1, 12, '2025-07-14 17:27:43'),
(205, 21, 4, '14:00:00', 1, 12, '2025-07-14 17:27:43'),
(206, 21, 5, '14:00:00', 1, 12, '2025-07-14 17:27:43'),
(207, 21, 1, '15:00:00', 1, 12, '2025-07-14 17:27:49'),
(208, 21, 2, '15:00:00', 1, 12, '2025-07-14 17:27:49'),
(209, 21, 3, '15:00:00', 1, 12, '2025-07-14 17:27:49'),
(210, 21, 4, '15:00:00', 1, 12, '2025-07-14 17:27:49'),
(211, 21, 5, '15:00:00', 1, 12, '2025-07-14 17:27:49'),
(212, 22, 1, '09:30:00', 5, 12, '2025-07-31 15:20:55'),
(213, 22, 2, '09:30:00', 5, 12, '2025-07-31 15:20:55'),
(214, 22, 3, '09:30:00', 5, 12, '2025-07-31 15:20:55'),
(215, 22, 4, '09:30:00', 5, 12, '2025-07-31 15:20:55'),
(216, 22, 5, '09:30:00', 5, 12, '2025-07-31 15:20:55'),
(217, 22, 1, '14:00:00', 5, 12, '2025-07-31 15:20:55'),
(218, 22, 2, '14:00:00', 5, 12, '2025-07-31 15:20:55'),
(219, 22, 3, '14:00:00', 5, 12, '2025-07-31 15:20:55'),
(220, 22, 4, '14:00:00', 5, 12, '2025-07-31 15:20:55'),
(221, 22, 5, '14:00:00', 5, 12, '2025-07-31 15:20:55'),
(222, 23, 1, '08:00:00', 5, 12, '2025-10-02 14:53:46'),
(223, 23, 2, '08:00:00', 5, 12, '2025-10-02 14:53:46'),
(224, 23, 3, '08:00:00', 5, 12, '2025-10-02 14:53:46'),
(225, 23, 4, '08:00:00', 5, 12, '2025-10-02 14:53:46'),
(226, 23, 5, '08:00:00', 5, 12, '2025-10-02 14:53:46'),
(227, 24, 1, '08:00:00', 5, 12, '2026-01-27 17:29:38'),
(228, 24, 2, '08:00:00', 5, 12, '2026-01-27 17:29:38'),
(229, 24, 3, '08:00:00', 5, 12, '2026-01-27 17:29:38'),
(230, 24, 4, '08:00:00', 5, 12, '2026-01-27 17:29:38'),
(231, 24, 5, '08:00:00', 5, 12, '2026-01-27 17:29:38'),
(234, 25, 1, '08:00:00', 1, 12, '2026-01-27 18:04:25'),
(235, 25, 2, '08:00:00', 1, 12, '2026-01-27 18:04:25'),
(236, 25, 3, '08:00:00', 1, 12, '2026-01-27 18:04:25'),
(237, 25, 4, '08:00:00', 1, 12, '2026-01-27 18:04:25'),
(238, 25, 5, '08:00:00', 1, 12, '2026-01-27 18:04:25'),
(239, 25, 1, '08:45:00', 1, 12, '2026-01-27 18:04:25'),
(240, 25, 2, '08:45:00', 1, 12, '2026-01-27 18:04:25'),
(241, 25, 3, '08:45:00', 1, 12, '2026-01-27 18:04:25'),
(242, 25, 4, '08:45:00', 1, 12, '2026-01-27 18:04:25'),
(243, 25, 5, '08:45:00', 1, 12, '2026-01-27 18:04:25'),
(244, 25, 1, '09:30:00', 1, 12, '2026-01-27 18:04:25'),
(245, 25, 2, '09:30:00', 1, 12, '2026-01-27 18:04:25'),
(246, 25, 3, '09:30:00', 1, 12, '2026-01-27 18:04:25'),
(247, 25, 4, '09:30:00', 1, 12, '2026-01-27 18:04:25'),
(248, 25, 5, '09:30:00', 1, 12, '2026-01-27 18:04:25'),
(249, 25, 1, '10:15:00', 1, 12, '2026-01-27 18:04:25'),
(250, 25, 2, '10:15:00', 1, 12, '2026-01-27 18:04:25'),
(251, 25, 3, '10:15:00', 1, 12, '2026-01-27 18:04:25'),
(252, 25, 4, '10:15:00', 1, 12, '2026-01-27 18:04:25'),
(253, 25, 5, '10:15:00', 1, 12, '2026-01-27 18:04:25'),
(265, 26, 1, '08:00:00', 1, 12, '2026-01-27 18:05:37'),
(266, 26, 2, '08:00:00', 1, 12, '2026-01-27 18:05:37'),
(267, 26, 3, '08:00:00', 1, 12, '2026-01-27 18:05:37'),
(268, 26, 4, '08:00:00', 1, 12, '2026-01-27 18:05:37'),
(269, 26, 5, '08:00:00', 1, 12, '2026-01-27 18:05:37'),
(270, 26, 1, '08:45:00', 1, 12, '2026-01-27 18:05:37'),
(271, 26, 2, '08:45:00', 1, 12, '2026-01-27 18:05:37'),
(272, 26, 3, '08:45:00', 1, 12, '2026-01-27 18:05:37'),
(273, 26, 4, '08:45:00', 1, 12, '2026-01-27 18:05:37'),
(274, 26, 5, '08:45:00', 1, 12, '2026-01-27 18:05:37'),
(275, 26, 1, '09:30:00', 1, 12, '2026-01-27 18:05:37'),
(276, 26, 2, '09:30:00', 1, 12, '2026-01-27 18:05:37'),
(277, 26, 3, '09:30:00', 1, 12, '2026-01-27 18:05:37'),
(278, 26, 4, '09:30:00', 1, 12, '2026-01-27 18:05:37'),
(279, 26, 5, '09:30:00', 1, 12, '2026-01-27 18:05:37'),
(280, 26, 1, '10:15:00', 1, 12, '2026-01-27 18:05:37'),
(281, 26, 2, '10:15:00', 1, 12, '2026-01-27 18:05:37'),
(282, 26, 3, '10:15:00', 1, 12, '2026-01-27 18:05:37'),
(283, 26, 4, '10:15:00', 1, 12, '2026-01-27 18:05:37'),
(284, 26, 5, '10:15:00', 1, 12, '2026-01-27 18:05:37');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__agendas_periodo`
--

DROP TABLE IF EXISTS `turneras__agendas_periodo`;
CREATE TABLE `turneras__agendas_periodo` (
  `id_periodo` int NOT NULL,
  `id_agenda` int NOT NULL,
  `fecha_desde` date NOT NULL,
  `fecha_hasta` date NOT NULL,
  `reg_usuario` smallint UNSIGNED DEFAULT NULL,
  `reg_fecha` datetime NOT NULL,
  `disponible` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `turneras__agendas_periodo`
--

INSERT INTO `turneras__agendas_periodo` (`id_periodo`, `id_agenda`, `fecha_desde`, `fecha_hasta`, `reg_usuario`, `reg_fecha`, `disponible`) VALUES
(3, 1, '2025-03-01', '2025-07-31', 12, '2025-04-15 14:09:46', 1),
(5, 2, '2025-03-10', '2025-03-15', 1, '2025-03-11 09:48:54', 1),
(6, 2, '2025-03-17', '2025-03-21', 1, '2025-03-11 09:50:07', 1),
(7, 2, '2025-03-24', '2025-03-29', 1, '2025-03-12 08:28:49', 1),
(8, 6, '2025-04-15', '2025-08-15', 12, '2025-04-15 14:00:43', 1),
(9, 7, '2025-04-01', '2025-06-30', 12, '2025-04-15 14:04:08', 1),
(11, 2, '2025-04-01', '2025-06-30', 12, '2025-04-15 14:12:06', 1),
(13, 8, '2025-07-14', '2025-08-14', 12, '2025-07-14 18:10:19', 1),
(14, 9, '2025-05-13', '2025-05-31', 12, '2025-05-13 11:16:11', 1),
(15, 10, '2025-05-13', '2025-05-31', 12, '2025-05-13 11:17:14', 1),
(16, 11, '2025-05-01', '2025-06-30', 8, '2025-05-26 09:38:27', 1),
(17, 12, '2025-05-01', '2025-06-29', 8, '2025-05-26 09:39:53', 1),
(18, 13, '2025-05-01', '2025-07-04', 8, '2025-05-26 09:54:52', 1),
(19, 13, '2025-10-01', '2025-10-31', 8, '2025-05-26 09:58:09', 1),
(21, 7, '2025-07-05', '2025-08-10', 12, '2025-07-14 17:29:14', 1),
(22, 1, '2025-08-01', '2025-09-30', 12, '2025-07-31 15:20:55', 1),
(23, 7, '2025-10-02', '2025-10-30', 12, '2025-10-02 14:53:46', 1),
(24, 7, '2026-01-25', '2026-02-20', 12, '2026-01-27 17:29:38', 1),
(25, 9, '2026-01-27', '2026-02-27', 12, '2026-01-27 18:04:25', 1),
(26, 10, '2026-01-27', '2026-02-27', 12, '2026-01-27 18:05:37', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__suspenciones`
--

DROP TABLE IF EXISTS `turneras__suspenciones`;
CREATE TABLE `turneras__suspenciones` (
  `id_suspencion` int UNSIGNED NOT NULL,
  `id_persona` smallint UNSIGNED NOT NULL,
  `id_categoria` tinyint UNSIGNED NOT NULL,
  `fecha_finalizacion` date NOT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `reg_usuario` smallint UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `turneras__suspenciones`
--

INSERT INTO `turneras__suspenciones` (`id_suspencion`, `id_persona`, `id_categoria`, `fecha_finalizacion`, `motivo`, `reg_usuario`, `reg_fecha`) VALUES
(1, 19030, 1, '2026-01-29', 'Prueba de suspensión. ', 12, '2026-01-27 17:35:24');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `turneras__turnos`
--

DROP TABLE IF EXISTS `turneras__turnos`;
CREATE TABLE `turneras__turnos` (
  `id_turno` int UNSIGNED NOT NULL,
  `id_persona` int UNSIGNED DEFAULT NULL,
  `id_agenda` int UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `horario` time NOT NULL,
  `celular` varchar(50) DEFAULT NULL,
  `mail` varchar(80) DEFAULT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `reg_usuario` smallint UNSIGNED NOT NULL,
  `reg_fecha` datetime NOT NULL,
  `reg_ip` varchar(32) NOT NULL,
  `estado` tinyint UNSIGNED NOT NULL DEFAULT '1' COMMENT '0=ANULADO\r\n1=PENDIENTE\r\n10=AUSENTE\r\n11=PRESENTE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `turneras__turnos`
--

INSERT INTO `turneras__turnos` (`id_turno`, `id_persona`, `id_agenda`, `fecha`, `horario`, `celular`, `mail`, `motivo`, `reg_usuario`, `reg_fecha`, `reg_ip`, `estado`) VALUES
(1, 19030, 7, '2025-10-06', '08:00:00', '1538519426', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', 'PRUEBA DE MOTIVO DEL TURNO RESERVADO', 12, '2025-10-03 13:34:30', '172.16.5.42', 1),
(2, 19030, 13, '2025-10-07', '10:00:00', '15305', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2025-10-03 13:56:44', '172.16.5.42', 1),
(3, 19030, 13, '2025-10-31', '10:00:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2025-10-03 14:02:12', '172.16.5.42', 1),
(4, 19030, 7, '2026-01-28', '08:00:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2026-01-27 17:36:59', '172.16.5.42', 0),
(5, 19030, 7, '2026-01-29', '08:00:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2026-01-27 17:37:03', '172.16.5.42', 0),
(6, 0, 7, '2026-01-28', '08:00:00', NULL, NULL, NULL, 12, '2026-01-27 17:36:43', '172.16.5.42', 1),
(7, 19030, 7, '2026-01-30', '08:00:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2026-01-27 17:46:14', '172.16.5.42', 0),
(8, 19030, 7, '2026-01-29', '08:00:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2026-01-27 18:04:05', '172.16.5.42', 0),
(9, 19030, 10, '2026-01-28', '08:45:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2026-01-27 18:15:14', '172.16.5.42', 0),
(10, 19030, 9, '2026-01-28', '10:15:00', '1538514050', 'ALEXIS.FIGUEIRA@HOTMAIL.COM', NULL, 12, '2026-01-27 18:16:49', '172.16.5.42', 0);

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
  MODIFY `id_categoria` tinyint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `turneras__agenda`
--
ALTER TABLE `turneras__agenda`
  MODIFY `id_agenda` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `turneras__agendas_horarios`
--
ALTER TABLE `turneras__agendas_horarios`
  MODIFY `id_horario` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=285;

--
-- AUTO_INCREMENT de la tabla `turneras__agendas_periodo`
--
ALTER TABLE `turneras__agendas_periodo`
  MODIFY `id_periodo` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT de la tabla `turneras__suspenciones`
--
ALTER TABLE `turneras__suspenciones`
  MODIFY `id_suspencion` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `turneras__turnos`
--
ALTER TABLE `turneras__turnos`
  MODIFY `id_turno` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
