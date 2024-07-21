--Vistas
--1
CREATE VIEW vista_mascotas_adoptadas AS
SELECT m.id_mascota, m.nombre AS nombre_mascota, a.id_adoptante, a.nombre AS nombre_adoptante
FROM mascota m
INNER JOIN adopciones ad ON m.id_mascota = ad.id_mascota
INNER JOIN adoptantes a ON ad.id_adoptante = a.id_adoptante;

SELECT *
FROM vista_mascotas_adoptadas;

--2

CREATE VIEW vista_salud_mascotas AS
SELECT s.id_salud, m.nombre AS nombre_mascota, s.fecha_examen, s.resultados, v.licencia AS Licencia_Veterinario
FROM salud_animales s
INNER JOIN mascota m ON s.id_mascota = m.id_mascota
INNER JOIN veterinarios v ON s.veterinario_id = v.id_veterinario;

SELECT *
FROM vista_salud_mascotas;

--3

CREATE VIEW vista_contratos_activos AS
SELECT ca.id_contrato, sa.fecha, sa.observaciones
FROM contratos_adopcion ca
INNER JOIN contratos_adopcion sa ON ca.id_contrato = sa.id_contrato
WHERE sa.fecha >= '2024-02-10';

SELECT *
FROM vista_contratos_activos;

--4

CREATE VIEW vista_eventos_patrocinados AS
SELECT p.id_patrocinio, e.nombre AS nombre_evento, p.patrocinador, s.Nombre AS nombre_sucursal
FROM patrocinios p
INNER JOIN eventos e ON p.id_evento = e.id_evento
INNER JOIN sucursal s ON p.id_sucursal = s.id_sucursal;

SELECT *
FROM vista_eventos_patrocinados;


--5

CREATE VIEW vista_gastos_sucursal AS
SELECT g.id_gasto, s.Nombre AS nombre_sucursal, g.tipo, g.monto, g.fecha
FROM gastos g
INNER JOIN sucursal s ON g.id_sucursal = s.id_sucursal;

SELECT *
FROM vista_gastos_sucursal;

--6

CREATE VIEW vista_voluntarios_activos_2024 AS
SELECT v.id_voluntario, v.nombre, v.apellido, v.fecha_inicio, v.horas_trabajadas
FROM voluntarios v
WHERE v.fecha_inicio >= '2024-01-01'; 

SELECT *
FROM vista_voluntarios_activos_2024;



--7 

CREATE VIEW vista_compras AS
SELECT c.id_compra, p.nombre AS nombre_proveedor, c.fecha, c.monto, c.descripcion
FROM compras c
INNER JOIN proveedores p ON c.id_proveedor = p.id_proveedor;

SELECT *
FROM vista_contratos_activos;

--8 

CREATE VIEW vista_inventario_suministros AS
SELECT s.id_suministros, p.nombre AS nombre_proveedor, s.nombre AS nombre_suministro, s.cantidad, MAX(s.fecha_ingreso) AS ultima_fecha_ingreso
FROM suministros s
INNER JOIN proveedores p ON s.id_proveedor = p.id_proveedor
GROUP BY s.id_suministros, p.nombre, s.nombre, s.cantidad;

SELECT *
FROM vista_inventario_suministros;

--9

CREATE VIEW vista_resumen_gastos AS
SELECT g.id_gasto, g.tipo, g.monto, g.fecha, s.Nombre AS nombre_sucursal
FROM gastos g
INNER JOIN sucursal s ON g.id_sucursal = s.id_sucursal;


SELECT *
FROM vista_resumen_gastos;


--10

CREATE VIEW vista_suministros_proveedor AS
SELECT s.id_suministros, p.nombre AS nombre_proveedor, s.nombre AS nombre_suministro, s.cantidad, s.fecha_ingreso
FROM suministros s
INNER JOIN proveedores p ON s.id_proveedor = p.id_proveedor;

SELECT *
FROM vista_suministros_proveedor;


-- PROCEDIMIENTOS ALMACENADOS ------------------------------------------------------------------------------------------------------------------------------------

BACKUP DATABASE CentroAdopciones TO  DISK = N'D:\CentroAdopcionesBackUp.bak' WITH  INIT , NOUNLOAD ,  NAME = N'CentroAdopcionesbackup',  STATS = 10,  FORMAT

CREATE PROCEDURE sp_BonificacionPorAntiguedad
    @id_empleado INT
AS
BEGIN
    DECLARE @antiguedad INT;
    DECLARE @bonificacion DECIMAL(10, 2);

    SELECT @antiguedad = DATEDIFF(YEAR, fecha_contratacion, GETDATE())
    FROM dbo.empleados
    WHERE id_empleado = @id_empleado;

    IF @antiguedad >= 10
        SET @bonificacion = 1000.00;
    ELSE
        SET @bonificacion = 500.00;

    UPDATE dbo.empleados
    SET salario = salario + @bonificacion
    WHERE id_empleado = @id_empleado;
END;
GO

--Calcular edad promedio de mascotas
GO
CREATE PROCEDURE EdadPromedioMascotas
AS
BEGIN
    DECLARE @edadPromedio INT;

    SELECT @edadPromedio = AVG(DATEDIFF(YEAR, m.fecha_nacimiento, GETDATE()))
    FROM mascota m
    INNER JOIN adopciones a ON m.id_mascota = a.id_mascota;

    IF @edadPromedio IS NULL
        SET @edadPromedio = 0; 

    SELECT @edadPromedio AS EdadPromedio;
END;
GO

--Actualizar fecha adopcion

CREATE PROCEDURE ActualizarFechaAdopcion
    @idAdopcion INT,
    @nuevaFecha DATE
AS
BEGIN
    DECLARE @fechaActual DATE;
    SELECT @fechaActual = fecha_solicitud FROM adopciones WHERE id_adopcion = @idAdopcion;

    IF @nuevaFecha >= @fechaActual 
    BEGIN
        UPDATE adopciones
        SET fecha_solicitud = @nuevaFecha
        WHERE id_adopcion = @idAdopcion;
    END
    ELSE
    BEGIN
        RAISERROR('La nueva fecha no puede ser anterior a la fecha actual de adopción.', 16, 1);
    END
END;
-- Registrar un gasto en la BD --------------------------
CREATE PROCEDURE RegistrarGasto2
    @idGasto INT,
    @Descripcion VARCHAR(50),
    @monto DECIMAL(10, 2),
    @fechaGasto DATE,
	@idSucursal INT,
	@Tipo VARCHAR
AS
BEGIN
    IF @monto > 0
    BEGIN
        INSERT INTO gastos (id_gasto, descripcion, monto, fecha, id_sucursal,tipo)
        VALUES (@idGasto, @Descripcion, @monto, @fechaGasto,@idSucursal,@Tipo);
    END
    ELSE
    BEGIN
        RAISERROR('El monto del gasto debe ser mayor a cero.', 16, 1);
    END
END;

-- Registrar una mantenimiento en la base de datos---------------
CREATE PROCEDURE RegistrarMantenimiento1
	@idMantenimiento INT,
    @idHabitacion INT,
    @fecha DATE,
    @descripcion TEXT,
    @costo DECIMAL(10, 2),
    @idEquipo INT
AS
BEGIN
    IF @costo > 0 AND @fecha <= GETDATE()
    BEGIN
        INSERT INTO mantenimiento (id_mantenimiento,id_habitacion, fecha, descripcion, costo, id_equipo)
        VALUES (@idMantenimiento, @idHabitacion, @fecha, @descripcion, @costo, @idEquipo);
    END
    ELSE
    BEGIN
        RAISERROR('El costo debe ser mayor a cero y la fecha no puede ser futura.', 16, 1);
    END
END;

-- Eliminar compras anteriores realizadas en la base de datos

CREATE PROCEDURE EliminarComprasAnteriores
    @anio INT
AS
BEGIN
    SET NOCOUNT ON; 

    
    IF EXISTS (SELECT 1 FROM compras WHERE YEAR(fecha) < @anio)
    BEGIN
        
        DELETE FROM compras WHERE YEAR(fecha) < @anio;

        PRINT 'Compras anteriores al año ' + CAST(@anio AS VARCHAR(4)) + ' eliminadas exitosamente.';
    END
    ELSE
    BEGIN
        PRINT 'No se encontraron compras anteriores al año ' + CAST(@anio AS VARCHAR(4)) + '.';
    END
END;

-- Calcular el inventario total que tiene la BD
CREATE PROCEDURE CalcularInventarioTotal
    @tipoSuministro VARCHAR(50),
    @cantidadTotal INT OUTPUT
AS
BEGIN
    SET @cantidadTotal = 0;
    DECLARE @idSuministro INT;
    DECLARE @cantidad INT;

    DECLARE cursor_suministros CURSOR FOR
        SELECT id_suministros, cantidad FROM suministros WHERE nombre= @tipoSuministro;

    OPEN cursor_suministros;
    FETCH NEXT FROM cursor_suministros INTO @idSuministro, @cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @cantidadTotal = @cantidadTotal + @cantidad;
        FETCH NEXT FROM cursor_suministros INTO @idSuministro, @cantidad;
    END

    CLOSE cursor_suministros;
    DEALLOCATE cursor_suministros;

    RETURN @cantidadTotal;
END;

-- Eliminar los voluntarios que tienen horas restantes y hayan acabado
CREATE PROCEDURE EliminarVoluntarioConHoras
    @horasMinimas INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM voluntarios WHERE horas_trabajadas < @horasMinimas)
    BEGIN
        DELETE FROM voluntarios WHERE horas_trabajadas < @horasMinimas;
        PRINT 'Voluntarios con menos de ' + CAST(@horasMinimas AS VARCHAR(10)) + ' horas eliminados.';
    END
    ELSE
    BEGIN
        PRINT 'No se encontraron voluntarios con menos de ' + CAST(@horasMinimas AS VARCHAR(10)) + ' horas.';
    END
END;

-- Registrar esterilizacion en la BD para una mascota

CREATE PROCEDURE RegistrarEsterilizacion2
	@idEsterilizacion INT,
    @idMascota INT,
    @fecha DATE,
    @veterinarioId INT
AS
BEGIN
    SET NOCOUNT ON; 

    
    IF NOT EXISTS (SELECT 1 FROM esterilizaciones WHERE id_mascota = @idMascota)
    BEGIN
        
        INSERT INTO esterilizaciones (id_esterilizacion,id_mascota, fecha, veterinario_id)
        VALUES (@idEsterilizacion,@idMascota, @fecha, @veterinarioId);

        PRINT 'Esterilización registrada exitosamente.';
    END
    ELSE
    BEGIN
        RAISERROR('La mascota ya ha sido esterilizada.', 16, 1);
    END
END;
-- Registrar visita 

CREATE PROCEDURE RegistrarVisita1
	@idVisita INT,
    @idAdoptante INT,
    @idMascota INT,
    @fecha DATE,
    @resultado TEXT
AS
BEGIN
    IF @fecha <= GETDATE() AND NOT EXISTS (SELECT 1 FROM adopciones WHERE id_mascota = @idMascota)
    BEGIN
        INSERT INTO visitas (id_visita,id_adoptante, id_mascota, fecha, resultado)
        VALUES (@idVisita, @idAdoptante, @idMascota, @fecha, @resultado);
        PRINT 'Visita registrada exitosamente.';
    END
    ELSE IF @fecha > GETDATE()
    BEGIN
        RAISERROR('La fecha de la visita no puede ser futura.', 16, 1);
    END
    ELSE 
    BEGIN
        RAISERROR('La mascota ya ha sido adoptada.', 16, 1);
    END
END;


-- Ejecutar el procedimiento almacenado para un empleado específico
EXEC sp_BonificacionPorAntiguedad 1;

-- Ejecutar el procedimiento almacenado EdadPromedioMascotas
EXEC EdadPromedioMascotas;

--Ejecutar procedimiento para actualizar fecha adopcion
EXEC ActualizarFechaAdopcion @idAdopcion = 2, @nuevaFecha = '2026-07-15';

--Ejecutar procedimiento para registrar gastos
EXEC RegistrarGasto2
    @idGasto = 103,
    @Descripcion = 'Compra de Medicamentos',
    @monto = 250.00,
    @fechaGasto = '2024-07-15',
    @idSucursal = 1,
    @Tipo = 'Compra';

--Ejecutar procedimiento para registrar mantenimiento
EXEC RegistrarMantenimiento1
	@idMantenimiento = 201,
    @idHabitacion = 1,
    @fecha = '2024-07-15',
    @descripcion = 'Reparación de equipo resonancia magnetica',
    @costo = 350.00,
    @idEquipo = 20;

--Ejecutar procedimiento para eliminar compras inferiores a un año
EXEC EliminarComprasAnteriores @anio = 2024;

--Ejecutar procedimiento para calcular la cantidad de un suministro
DECLARE @cantidadTotalOutput INT;

EXEC CalcularInventarioTotal 
    @tipoSuministro = 'Alimento para perros', 
    @cantidadTotal = @cantidadTotalOutput OUTPUT;

SELECT @cantidadTotalOutput AS 'CantidadTotal';

--Ejecutar procedimiento para eliminar voluntarios que no lleven x cantidad de horas
EXEC EliminarVoluntarioConHoras @horasMinimas = 50;

--Ejecutar procedimiento para registrar esterilizaciones RARA REVISAR
EXEC RegistrarEsterilizacion2
	@idEsterilizacion=22,
    @idMascota = 52,
    @fecha = '2022-12-12',
    @veterinarioId = 2;


--Insertar visitas dependiendo si la mascota esta adoptada  o no RARA REVISAR
EXEC RegistrarVisita1
	@idVisita =22,
    @idAdoptante = 1,
    @idMascota = 52,
    @fecha = '2023-12-12',
    @resultado = 'realizada';

-- FUNCIONES -----------------------------------------------------------------------------------------------------

-- FUNCIONES AGREGADAS --

--1 Obtiene el tiempo que lleva la mascota con su nuevo dueño

GO
CREATE FUNCTION dbo.obtener_tiempo_adoptado (@fecha_solicitud DATE) 
RETURNS INT
AS
BEGIN
    DECLARE @tiempo INT;
    SET @tiempo = DATEDIFF(YEAR, @fecha_solicitud, GETDATE());
    RETURN @tiempo;
END;
GO

--2 obtiene el numero de mascotas que ha adoptado una persona

GO
CREATE FUNCTION dbo.numero_mascotas_adoptadas (@id_adoptante INT) 
RETURNS INT
AS
BEGIN
    DECLARE @num_adopciones INT;
    SELECT @num_adopciones = COUNT(*)
    FROM adopciones
    WHERE id_adoptante = @id_adoptante;
    RETURN @num_adopciones;
END;
GO

--3 Cantidad donaciones realizadas por una persona

GO
CREATE FUNCTION dbo.total_donaciones (@id_donante INT) 
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    SELECT @total = SUM(monto)
    FROM donaciones
    WHERE id_donante = @id_donante;
    RETURN @total;
END;
GO

--4 Obtiene el nombre completo de una persona basado en su id

GO

CREATE FUNCTION dbo.obtener_nombre_completo_persona (@id_empleado INT) 
RETURNS VARCHAR(200)
AS
BEGIN
    DECLARE @nombre_completo VARCHAR(200);
    SELECT @nombre_completo = nombre + ' ' + apellido
    FROM empleados
    WHERE id_empleado = @id_empleado;
    RETURN @nombre_completo;
END;

GO

--5 Saber cuantas vacunas ha tenido una mascota a lo largo de su estadia en la veterinaria

GO

CREATE FUNCTION dbo.total_vacunas_mascota (@id_mascota INT) 
RETURNS INT
AS
BEGIN
    DECLARE @total_vacunas INT;
    SELECT @total_vacunas = COUNT(*)
    FROM vacunacion
    WHERE id_mascota = @id_mascota;
    RETURN @total_vacunas;
END;


GO

-- Llamar funciones agregadas

--1 

SELECT dbo.obtener_tiempo_adoptado('2015-05-20') AS edad_mascota;

--2

SELECT dbo.numero_mascotas_adoptadas(3) AS numero_adopciones;

--3

SELECT dbo.total_donaciones(5) AS total_donaciones;

--4 

SELECT dbo.obtener_nombre_completo_persona(1) AS nombre_completo;

--5 

SELECT dbo.total_vacunas_mascota(1) AS total_vacunas;

-- FUNCIONES ESCALARES -- 

--1 Obtiene el tiempo de contratacion que lleva un empleado

GO

CREATE FUNCTION dbo.tiempo_contratacion_empleado (@id_empleado INT) 
RETURNS INT
AS
BEGIN
    DECLARE @tiempo INT;
    SELECT @tiempo = DATEDIFF(YEAR, fecha_contratacion, GETDATE())
    FROM empleados
    WHERE id_empleado = @id_empleado;
    RETURN @tiempo;
END;

GO

--2 Muestra la cantidad de dinero reunido en un evento

GO

CREATE FUNCTION dbo.total_recaudacion_evento (@id_evento INT) 
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    SELECT @total = recaudacion
    FROM eventos
    WHERE id_evento = @id_evento;
    RETURN @total;
END;

GO

--3 Averigua los gastos que ha tenido la sucursal seleccionada

GO

CREATE FUNCTION dbo.total_gastos_sucursal (@id_sucursal INT) 
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    SELECT @total = SUM(monto)
    FROM gastos
    WHERE id_sucursal = @id_sucursal;
    RETURN @total;
END;

GO

-- 4 Obtener el nombre del proveedor

GO

CREATE FUNCTION dbo.obtener_nombre_proveedor (@id_proveedor INT) 
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @nombre VARCHAR(100);
    SELECT @nombre = nombre
    FROM proveedores
    WHERE id_proveedor = @id_proveedor;
    RETURN @nombre;
END;

GO

--5 Calcula el promedio de donaciones de un donante

GO

CREATE FUNCTION dbo.promedio_donaciones (@id_donante INT) 
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @promedio DECIMAL(10,2);
    SELECT @promedio = AVG(monto)
    FROM donaciones
    WHERE id_donante = @id_donante;
    RETURN @promedio;
END;


GO

-- LLAMAR LAS FUNCIONES ESCALARES

--1
SELECT dbo.tiempo_contratacion_empleado(1) AS tiempo_contratacion;

--2
SELECT dbo.total_recaudacion_evento(1) AS total_recaudacion;

--3
SELECT dbo.total_gastos_sucursal(1) AS total_gastos;

--4
SELECT dbo.obtener_nombre_proveedor(1) AS nombre_proveedor;

--5
SELECT dbo.promedio_donaciones(1) AS promedio_donaciones;


-- TRIGGERS --------------------------------------------------------------------

--1 Actualizar la edad de la mascota automaticamente
GO
CREATE TRIGGER trg_update_edad_mascota
ON mascota
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE m
    SET m.edad = DATEDIFF(YEAR, m.fecha_nacimiento, GETDATE())
    FROM mascota m
    INNER JOIN inserted i ON m.id_mascota = i.id_mascota;
END;
GO

--2 Evitar que se puedan eliminar mascotas con adopcion

GO
CREATE TRIGGER trg_prevent_delete_mascota
ON mascota
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM adopciones WHERE id_mascota IN (SELECT id_mascota FROM deleted))
    BEGIN
        RAISERROR ('No se puede eliminar la mascota porque tiene adopciones asociadas.', 16, 1);
    END
    ELSE
    BEGIN
        DELETE FROM mascota WHERE id_mascota IN (SELECT id_mascota FROM deleted);
    END
END;
GO

--3 CREAR UN LOG DE DONACIONES

CREATE TABLE log_donaciones (
    id_log INT IDENTITY PRIMARY KEY,
    id_donante INT,
    fecha DATE,
    monto DECIMAL(10,2),
    tipo VARCHAR(50),
    descripcion VARCHAR(50),
    fecha_registro DATETIME
);

GO
CREATE TRIGGER trg_log_donaciones
ON donaciones
AFTER INSERT
AS
BEGIN
    INSERT INTO log_donaciones (id_donante, fecha, monto, tipo, descripcion, fecha_registro)
    SELECT id_donante, fecha, monto, tipo, descripcion, GETDATE()
    FROM inserted;
END;
GO

--4 Actualizar el inventario despues de una compra

GO
CREATE TRIGGER trg_update_inventario_after_compra
ON compras
AFTER INSERT
AS
BEGIN
    UPDATE inventario
    SET cantidad = cantidad + i.cantidad
    FROM inventario i
    INNER JOIN inserted ins ON i.id_proveedor = ins.id_proveedor;
END;
GO

-- 5 Actualizar Número de Mascotas Adoptadas por Adoptante

GO
CREATE TRIGGER trg_actualizar_num_mascotas_adoptadas
ON adopciones
AFTER INSERT
AS
BEGIN
    DECLARE @id_adoptante INT;

    SELECT @id_adoptante = id_adoptante
    FROM inserted;

    IF @id_adoptante IS NOT NULL
    BEGIN
        UPDATE adoptantes
        SET num_mascotas_adoptadas = (SELECT COUNT(*) FROM adopciones WHERE id_adoptante = @id_adoptante)
        WHERE id_adoptante = @id_adoptante;
    END
END;
GO

