# Diseño de Base de Datos: Agenda de Psicología

He analizado tu propuesta en `idea_de_proyecto.txt`. La idea base está muy bien encaminada y cubre el flujo principal (paciente -> turno -> cobro). Sin embargo, pensando en la **escalabilidad** y en las **buenas prácticas** de diseño de sistemas, te propongo varios ajustes importantes.

## Análisis Crítico de tu Propuesta

1. **Tabla Pacientes (`psicologia__pacientes`)**:
   - **Faltan datos clínicos/comunicacionales básicos**: En el ámbito de la salud es crucial tener la **fecha de nacimiento** (para calcular edad en reportes o evolución) y un **email** (fundamental si a futuro quieres enviar recordatorios automáticos de turnos o facturas).
   - **Baja lógica (Soft Delete)**: Conviene agregar un campo `estado` (Activo/Inactivo) para no tener que eliminar (DELETE) un paciente si deja de asistir, preservando así el historial de turnos y pagos.

2. **Tabla Turnos (`psicologia__turnos`)**:
   - **Manejo de Tiempos**: Separar `fecha` y `horario` está bien, pero te sugiero renombrar a `horario_inicio` y agregar `horario_fin` (o una duración estimada). Esto te va a facilitar muchísimo a futuro validar que no se superpongan dos turnos por error (ej: si da una sesión de 1 hora vs una de 45 min).
   - **El valor de la sesión**: Te sugiero mover el campo `valor_sesion` directamente a esta tabla. ¿Por qué? Porque el precio que se cobra "en ese momento" debe quedar congelado junto con el turno. Si el paciente asiste y la sesión costaba $10.000, ese turno vale $10.000, independientemente de cuándo lo pague.

3. **Tabla Detalles (`psicologia__turnos_detalle`) -> CAMBIO ESTRUCTURAL MAYOR**:
   - Crear una tabla de detalle 1 a 1 con el turno es muy limitante. 
   - **¿Qué pasa si...**
     - ¿Un paciente abona 4 sesiones (el mes entero) por adelantado en un solo pago?
     - ¿Un paciente asiste, no tiene dinero, y paga dos sesiones juntas la semana siguiente?
     - ¿Paga la mitad en efectivo y la mitad por transferencia?
   - **Solución Escalable**: Transformar esta tabla en una verdadera tabla de transacciones financieras llamada **`psicologia__pagos`**. Esta tabla registrará los pagos y se relacionará con el paciente y (opcionalmente) con el turno.

---

## Esquema Propuesto (Escalable)

### 1. `psicologia__pacientes`
*Mantuvimos tu base y agregamos campos clave para escalar.*
- `id_paciente` (INT, PRIMARY KEY, AUTO_INCREMENT)
- `dni` (VARCHAR, UNIQUE) - *Evita pacientes duplicados*
- `nombre` (VARCHAR)
- `apellido` (VARCHAR)
- `telefono` (VARCHAR)
- `email` (VARCHAR) - *[NUEVO] Para notificaciones futuras*
- `fecha_nacimiento` (DATE) - *[NUEVO] Contexto del paciente*
- `direccion` (VARCHAR)
- `localidad` (VARCHAR)
- `estado` (TINYINT) - *[NUEVO] 1=Activo, 0=Inactivo (Baja lógica)*
- `reg_user` (INT)
- `reg_fecha` (DATETIME)

### 2. `psicologia__turnos`
*Se agregó control de superposición y el precio acordado para la sesión.*
- `id_turno` (INT, PRIMARY KEY, AUTO_INCREMENT)
- `id_paciente` (INT, FOREIGN KEY)
- `fecha` (DATE)
- `horario_inicio` (TIME)
- `horario_fin` (TIME) - *[NUEVO] Permite calcular disponibilidad real*
- `valor_sesion` (DECIMAL) - *[MOVIDO AQUI] Precio fijado histórico de ese turno*
- `estado` (TINYINT) - *(0=Anulado, 1=Pendiente, 10=Ausente, 11=Presente)*
- `observaciones` (TEXT) - *[NUEVO] Notas breves del turno (no es la historia clínica)*
- `reg_user` (INT)
- `reg_fecha` (DATETIME)

### 3. `psicologia__pagos` (Reemplaza a turnos_detalle)
*Permite pagos múltiples, pagos adelantados y registrar métodos de pago.*
- `id_pago` (INT, PRIMARY KEY, AUTO_INCREMENT)
- `id_paciente` (INT, FOREIGN KEY) - *El que paga*
- `id_turno` (INT, FOREIGN KEY, NULLABLE) - *[NUEVO] Si es NULL, puede ser un saldo a favor o pago de mes por adelantado.*
- `monto` (DECIMAL)
- `metodo_pago` (VARCHAR) - *[NUEVO] Ej: 'Efectivo', 'Transferencia', 'MercadoPago'*
- `fecha_pago` (DATETIME)
- `reg_user` (INT)
- `reg_fecha` (DATETIME)

### 4. Tablas a Futuro (Mencionadas en tu texto)
- `psicologia__evoluciones` o `psicologia__historia_clinica`: 
  - `id_evolucion`, `id_paciente`, `id_turno` (opcional), `texto_evolucion`, `fecha`, `reg_user`. Esto permitirá guardar notas encriptadas o privadas sobre cada sesión, separado de la lógica de agenda.
