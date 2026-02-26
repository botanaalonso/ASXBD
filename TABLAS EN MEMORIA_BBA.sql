-TABLAS EN MEMORIA 


---------------------

USE master;
GO

-- Eliminar base de datos si existe
DROP DATABASE IF EXISTS BBA_Camping_mem;
GO

-- Crear nueva base de datos
CREATE DATABASE BBA_Camping_mem;
GO

-- Crear filegroup para datos en memoria
ALTER DATABASE BBA_Camping_mem
ADD FILEGROUP BBA_Camping_mem_mod CONTAINS MEMORY_OPTIMIZED_DATA;
GO

-- Agregar archivo para el filegroup de memoria
ALTER DATABASE BBA_Camping_mem ADD FILE
(
    NAME = 'BBA_Camping_mem_mod',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\BBA_Camping_mem_mod'
)
TO FILEGROUP BBA_Camping_mem_mod;
GO

USE BBA_Camping_mem;
GO

-- 1. Tabla en memoria (In-Memory OLTP)
CREATE TABLE dbo.ReservasMemoria
(
    ReservaID INT IDENTITY(1,1) 
        PRIMARY KEY NONCLUSTERED,
    ClienteID INT NOT NULL,
    ZonaID INT NOT NULL,
    CantidadPersonas INT NOT NULL,
    Precio MONEY NOT NULL,
    FechaReserva DATETIME2 NOT NULL
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO

-- 2. Tabla tradicional en disco
CREATE TABLE dbo.ReservasDisco
(
    ReservaID INT IDENTITY(1,1) 
        PRIMARY KEY,
    ClienteID INT NOT NULL,
    ZonaID INT NOT NULL,
    CantidadPersonas INT NOT NULL,
    Precio MONEY NOT NULL,
    FechaReserva DATETIME2 NOT NULL
);
GO

-- 3. Procedimiento para insertar datos de prueba

CREATE OR ALTER PROCEDURE InsertarDatosPrueba
    @NumRegistros INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    DECLARE @StartTime DATETIME;

    /* Inserción en tabla en memoria */
    SET @StartTime = GETDATE();

    WHILE @i <= @NumRegistros
    BEGIN
        INSERT INTO dbo.ReservasMemoria
        (
            ClienteID,
            ZonaID,
            CantidadPersonas,
            Precio,
            FechaReserva
        )
        VALUES
        (
            CAST(RAND() * 1000 AS INT),
            CAST(RAND() * 50 AS INT),
            CAST(RAND() * 10 AS INT),
            RAND() * 1000,
            GETDATE()
        );

       SET @i = @i + 1;
    END

    SELECT 'Inserción en Memoria' AS Tipo,
           DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS TiempoMS;

    /* Inserción en tabla en disco */
    SET @i = 1;
    SET @StartTime = GETDATE();

    WHILE @i <= @NumRegistros
    BEGIN
        INSERT INTO dbo.ReservasDisco
        (
            ClienteID,
            ZonaID,
            CantidadPersonas,
            Precio,
            FechaReserva
        )
        VALUES
        (
            CAST(RAND() * 1000 AS INT),
            CAST(RAND() * 50 AS INT),
            CAST(RAND() * 10 AS INT),
            RAND() * 1000,
            GETDATE()
        );

        SET @i += 1;
    END

    SELECT 'Inserción en Disco' AS Tipo,
           DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS TiempoMS;
END;
GO

-- 4. Ejecutar prueba de rendimiento
EXEC InsertarDatosPrueba @NumRegistros = 10000;
GO

-- 5. Comparación de consultas
SET STATISTICS TIME ON;

SELECT COUNT(*) AS TotalReservas,
       AVG(Precio) AS PrecioPromedio
FROM dbo.ReservasMemoria
WHERE ClienteID BETWEEN 1 AND 500;

SELECT COUNT(*) AS TotalReservas,
       AVG(Precio) AS PrecioPromedio
FROM dbo.ReservasDisco
WHERE ClienteID BETWEEN 1 AND 500;

SET STATISTICS TIME OFF;
GO

-- 6. Estadísticas de uso de memoria
SELECT OBJECT_NAME(object_id) AS TablaName,
       memory_allocated_for_table_kb,
       memory_used_by_table_kb
FROM sys.dm_db_xtp_table_memory_stats
WHERE object_id IN
(
    OBJECT_ID('dbo.ReservasMemoria'),
    OBJECT_ID('dbo.ReservasDisco')
);
GO