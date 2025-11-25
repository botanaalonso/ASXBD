EXEC sp_configure filestream_access_level, 2  
RECONFIGURE  
GO
DROP DATABASE IF EXISTS BBA_Camping_test 
GO
CREATE DATABASE BBA_Camping_test
GO
USE  BBA_Camping_test
GO

ALTER DATABASE [BBA_Camping_test] 
ADD FILEGROUP [fs_BBA_Camping_test] CONTAINS FILESTREAM 
GO

--Msg 5591, Level 16, State 3, Line 73
--FILESTREAM feature is disabled.


EXEC sp_configure filestream_access_level, 2;
GO
RECONFIGURE WITH OVERRIDE
GO

-- Configuration option 'filestream access level' changed from 2 to 2. Run the RECONFIGURE statement to install.

ALTER DATABASE BBA_Camping_test
ADD FILE (
    NAME = 'BBA_Camping_filestream_file',
    FILENAME = 'C:\BBA_Camping_FILESTREAM'
)
TO FILEGROUP fs_BBA_Camping_test;
GO
--Activo la Base de Datos
USE BBA_Camping_test
GO
DROP TABLE IF EXISTS BBA_Camping
GO
CREATE TABLE Images_BBA_Camping (
    ID UNIQUEIDENTIFIER ROWGUIDCOL 
        NOT NULL 
        UNIQUE,
    imageFile VARBINARY(MAX) 
        FILESTREAM 
        NULL
);
GO
USE BBA_Camping_test;
GO

--FOLDER C:\Fotos Camping
-- Insertar imagen de Brad
INSERT INTO dbo.Images_BBA_Camping (ID, imageFile)
SELECT NEWID(), BulkColumn
FROM OPENROWSET(
    BULK N'C:\Fotos Camping\Bungalows.jpg',
    SINGLE_BLOB
) AS Document;
GO

-- Insertar imagen de Tom
INSERT INTO dbo.Images_BBA_Camping (ID, imageFile)
SELECT NEWID(), BulkColumn
FROM OPENROWSET(
    BULK N'C:\Fotos Camping\tiendas.jpg',
    SINGLE_BLOB
) AS Document;
GO

-- Verificar datos
SELECT * FROM dbo.Images_BBA_Camping;
GO

---FILETABLE    

-- Usar master para crear la base de datos
USE master;
GO

-- Habilitar FILESTREAM
EXEC sp_configure filestream_access_level, 2;
RECONFIGURE;
GO

-- Eliminar base de datos si existe
IF DB_ID('BBA_Camping_test') IS NOT NULL
    DROP DATABASE BBA_Camping_test;
GO

-- Crear base de datos con FILESTREAM
CREATE DATABASE BBA_Camping_test
ON 
PRIMARY
(
    NAME = BBA_Camping_test_data,
    FILENAME = 'C:\BBA_Camping_FileTable\BBA_Camping_test.mdf'
),
FILEGROUP BBA_Camping_FileStreamFG CONTAINS FILESTREAM
(
    NAME = BBA_Camping_FileStream,
    FILENAME = 'C:\BBA_Camping_FileTable\FT_Container'
)
LOG ON
(
    NAME = BBA_Camping_test_Log,
    FILENAME = 'C:\BBA_Camping_FileTable\BBA_Camping_Log.ldf'
)
WITH FILESTREAM
(
    NON_TRANSACTED_ACCESS = FULL,
    DIRECTORY_NAME = 'FT_Container'
);
GO

-- Verificar configuración FILESTREAM
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    non_transacted_access,
    non_transacted_access_desc
FROM sys.database_filestream_options;
GO


--Activamos filestream
ALTER DATABASE [BBA_Campingp]
SET FILESTREAM (DIRECTORY_NAME = 'FotografiaStore')
WITH ROLLBACK IMMEDIATE
GO

ALTER DATABASE [BBA_Campingp]
	SET FILESTREAM(NON_TRANSACTED_ACCESS = FULL,
	DIRECTORY_NAME = 'FOTOGRAFIA')
	WITH ROLLBACK IMMEDIATE
GO

--PARTICIONES

EXECUTE sp_configure ‘xp_cmdshell’, 1;
GO
RECONFIGURE;
GO
xp_cmdshell ‘mkdir C:\DATA\’
GO

CREATE DATABASE [BBA_Campingp] 
	ON PRIMARY ( NAME = 'BBA_Campingp', 
		FILENAME = 'C:\Data\BBA_Campingp_Fijo.mdf' , 
		SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) 
	LOG ON ( NAME = 'BBA_Campingp_log', 
		FILENAME = 'C:\Data\BBA_Campingp_log.ldf' , 
		SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%) 
GO

-- creo los filegroups

ALTER DATABASE [BBA_Campingp] ADD FILEGROUP [Antiguos] 
GO 
ALTER DATABASE [BBA_Campingp] ADD FILEGROUP [Altas_2023] 
GO 
ALTER DATABASE [BBA_Campingp] ADD FILEGROUP [Altas_2024] 
GO 
ALTER DATABASE [BBA_Campingp] ADD FILEGROUP [Altas_2025]
GO

-- Creamos los archivos y los vinculamos a los filegroups:

ALTER DATABASE [BBA_Campingp] ADD FILE ( NAME = 'Antiguos', FILENAME = 'c:\DATA\Antiguos.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Antiguos] 
GO

ALTER DATABASE [BBA_Campingp] ADD FILE ( NAME = 'Altas_2023', FILENAME = 'c:\DATA\Altas_2023.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2023]
GO

ALTER DATABASE [BBA_Campingp] ADD FILE ( NAME = 'Altas_2024', FILENAME = 'c:\DATA\Altas_2024.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2024] 
GO

ALTER DATABASE [BBA_Campingp] ADD FILE ( NAME = 'Altas_2025', FILENAME = 'c:\DATA\Altas_2025.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2025] 
GO

select file_id, name, physical_name
from sys.database_files
GO

SELECT name FROM sys.filegroups;




USE BBA_CampingP
GO

--Creamos la función partición, particionará los datos en función de la fecha:
CREATE PARTITION FUNCTION FN_reservas_fecha (datetime)
AS RANGE RIGHT
FOR VALUES ('2023-01-01','2024-01-01','2025-01-01');

-- Creamos el esquema de partición, nos mapeará los registros según las particiones:



CREATE PARTITION SCHEME reservas_fecha
AS PARTITION FN_reservas_fecha
TO (Antiguos, Altas_2023, Altas_2024, Altas_2025);
GO

SELECT name 
FROM sys.filegroups;


--Creamos la tabla para añadir los registros y posteriormente comprobamos como directamente cada registro se ha distribuido en cada partición

CREATE TABLE Reservas_Camping
(
  id_reserva int IDENTITY(1,1),
  nombre_cliente varchar(30),
  parcela varchar(10),
  fecha_reserva datetime
)
ON reservas_fecha(fecha_reserva);

SELECT name, function_id 
FROM sys.partition_functions;

INSERT INTO Reservas_Camping (nombre_cliente, parcela, fecha_reserva)
VALUES
('Carlos Pérez', 'P01', '2023-06-15 12:00:00'),
('Marta López', 'P02', '2023-07-20 15:30:00'),
('Javier Gómez', 'P03', '2024-08-05 10:00:00'),
('Laura Fernández', 'P04', '2024-09-12 18:45:00'),
('Sergio Ruiz', 'P05', '2025-05-01 09:15:00'),
('Ana Torres', 'P06', '2025-07-10 11:20:00'),
('David Castro', 'P07', '2026-03-21 11:15:00'),
('Isabel Martín', 'P08', '2027-07-08 13:40:00'),
('Raúl Hernández', 'P09', '2028-11-19 15:55:00'),
('Beatriz Silva', 'P10', '2029-04-25 09:05:00');
GO
USE BBA_Campingp
GO

SELECT * FROM [dbo].[Reservas_Camping]
GO
SELECT p.partition_number AS Numero_Partición,
       p.rows AS Registros
FROM sys.partitions p
JOIN sys.indexes i
	ON p.object_id = i.object_id
WHERE i.object_id = OBJECT_ID('Reservas_Camping')
ORDER BY p.partition_number;
GO

--SPLIT divide una particion 

ALTER DATABASE [BBA_Campingp] ADD FILEGROUP [Reservas_2021]
GO
ALTER DATABASE [BBA_Campingp] ADD FILE (NAME = 'Reservas_2021', FILENAME = 'C:\DATA\Reservas_2021.ndf', SIZE = 5MB, MAXSIZE =100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Reservas_2023]
GO

ALTER PARTITION SCHEME reservas_fecha
NEXT USED Reservas_2021;

ALTER PARTITION FUNCTION FN_reservas_fecha()
 SPLIT RANGE ('2021-01-01');
 GO

  SELECT * ,$Partition.FN_reservas_fecha(fecha_reserva) AS Partition
 FROM [dbo].[Reservas_Camping]
 GO

 


 --verificar limites actuales de la funcion de particion-------

 SELECT pf.name AS PartitionFunction,
       prv.boundary_id,
       prv.value
FROM sys.partition_functions pf
JOIN sys.partition_range_values prv
     ON pf.function_id = prv.function_id
WHERE pf.name = 'FN_reservas_fecha';

--MERGE  Elimina un límite existente y fusiona dos particiones adyacentes en una sola. 

ALTER PARTITION FUNCTION FN_reservas_fecha ()
 MERGE RANGE ('2021-01-01');
 GO
 SELECT *,$Partition.FN_reservas_fecha(fecha_reserva) AS Partition
 FROM [dbo].[Reservas_Camping]
 GO

 --SWITCH 

 CREATE TABLE dbo.Reservas_Camping_2023 (
    id_reserva INT IDENTITY (1,1),
    nombre_cliente VARCHAR(30),
    parcela VARCHAR(10),
    fecha_reserva DATETIME 
);

INSERT INTO dbo.Reservas_Camping_2023 (id_reserva, nombre_cliente, parcela, fecha_reserva)
VALUES (1001, 'Cliente Demo', 'P01', '2023-06-15');

ALTER TABLE [dbo].[Reservas_Camping]
SWITCH Partition 3 to [dbo].[Reservas_Camping_2023]
GO

SELECT * FROM [dbo].[Reservas_Camping]
GO
















--split Establecemos una partición para los registros del año 2025

ALTER PARTITION FUNCTION FN_altas_fecha()
  SPLIT RANGE ('2025-01-01');
  GO


--verifico  el esquema de particion
  SELECT * 
FROM sys.partition_schemes 
WHERE name = 'altas_fecha';


-- creamos un FILEGROUP nuevo para la partición que se va a generar

ALTER DATABASE [BBA_Campingp] ADD FILEGROUP [Altas_2024]
GO
ALTER DATABASE [BBA_Campingp] ADD FILE ( NAME = 'Altas_2024', FILENAME = 'C:\DATA\Altas_2024.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP  [Altas_2024]
GO

--Agrega un filegroup adicional al esquema de partición antes de hacer el SPLIT.
ALTER PARTITION SCHEME altas_fecha
NEXT USED Altas_2024;

--añado un filegroup nuevo
ALTER DATABASE [BBA_Campingp]
ADD FILEGROUP FG_altas_fecha;







--crear partition function
CREATE PARTITION FUNCTION altas_funcion (datetime)
AS RANGE LEFT FOR VALUES ('2015-01-01', '2020-01-01', '2025-01-01');
GO



--hago el split
ALTER PARTITION FUNCTION altas_funcion()
SPLIT RANGE ('2023-01-01');




SELECT 
    nombre,
    apellido,
    fecha_alta,
    $PARTITION.FN_altas_fecha(fecha_alta) AS PartitionNumber
FROM Altas_matricula;
GO

--MERGE    en una función de partición sirve para eliminar un límite de rango y combinar dos particiones adyacentes en una sola, reduciendo el número de particiones

ALTER PARTITION FUNCTION FN_Altas_Fecha ()
	MERGE RANGE ('2023-01-01');
	GO

SELECT *, $Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_matricula
GO

gr
CREATE TABLE dbo.Reservas_Camping_Stage_2023 (
    id_reserva INT identity (1,1),
    nombre_cliente VARCHAR(30) NULL,
    parcela VARCHAR(10) NULL,
    fecha_reserva DATETIME NOT NULL
);

ALTER TABLE 
-- PARA SABER SI UNA TABLA ESTA pARTICIONADA 
SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, *   
FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
JOIN sys.partition_schemes ps   
    ON i.data_space_id = ps.data_space_id   
WHERE t.name = 'Reservas_Camping_2023';   
GO

-- Hacemos un SWITCH de los datos de la partición de 2023 de 'Reservas_Camping' a 'Reservas_Camping_2023'

USE BBA_Campingp;
GO

IF OBJECT_ID('dbo.Reservas_Camping_2023_OUT', 'U') IS NOT NULL
    DROP TABLE dbo.Reservas_Camping_2023_OUT;
GO

	CREATE TABLE dbo.Reservas_Camping_2023_OUT
	(
		id_reserva INT IDENTITY(1,1) NOT NULL,
		nombre_cliente VARCHAR(30) NULL,
		parcela VARCHAR(10) NULL,
		fecha_reserva DATETIME NULL
	)

	ON [Altas_2024];
GO

ALTER TABLE dbo.Reservas_Camping
SWITCH PARTITION 3 TO dbo.Reservas_Camping_2023_OUT;
GO

--verificar si la partición quedó vacia

SELECT *
FROM dbo.Reservas_Camping
WHERE $PARTITION.FN_reservas_fecha(fecha_reserva) = 3;
GO

SELECT *
FROM dbo.Reservas_Camping_2023_OUT;
GO
--SWITCH OUT  Partición → tabla normal
--La tabla debe estar en el MISMO filegroup que la partición origen.


TRUNCATE TABLE dbo.Reservas_Camping_2023_OUT;
GO


ALTER TABLE dbo.Reservas_Camping
SWITCH PARTITION 3 TO dbo.Reservas_Camping_2023_OUT;
GO

-- TRUNCATE

--Truncate nos sirve para eliminar particiones, es la operación mas simple. Eliminamos las de la partición 4 que son de este año.

TRUNCATE TABLE Reservas_Camping
 WITH (PARTITIONS (4));

 SELECT * from Reservas_Camping
 go

SELECT *, $Partition.FN_reservas_fecha(fecha_reserva) AS Partition
FROM Reservas_Camping
GO


--TABLAS TEMPORALES DEL SISTEMA


USE master
Go

--Controla la existencia de la base de datos
DROP DATABASE IF EXISTS BBA_Camping
GO

--CREO MI BASE DE DATOS

CREATE DATABASE BBA_Camping
ON PRIMARY    --archivo de datos principal
(
    NAME = 'BBA_Camping',
    FILENAME = 'C:\Data\BBA_Camping.mdf',   
    SIZE = 15360KB, -- tamaño inicial 
    MAXSIZE = UNLIMITED,  -- crecimiento ilimitado
    FILEGROWTH = 0 -- no crece autimaticamente
)
LOG ON   --archivo de log de transacciones
(
    NAME = 'BBA_Camping_log',
    FILENAME = 'C:\Data\BBA_Camping_log.ldf',
    SIZE = 10176KB, -- tamaño inicial de log
    MAXSIZE = 2048GB,  -- tamaño maximo de log
    FILEGROWTH = 10%   -- crece autimaticamente un 10% al llenarse
);
GO

USE BBA_Camping
GO

CREATE TABLE [dbo].[Reserva](
    [Id_reserva] VARCHAR(20) NOT NULL PRIMARY KEY,
    [fecha_entrada] DATE NULL,
    [fecha_salida] DATE NULL,
    [personas] INT NULL,
    [estado] VARCHAR(20) NULL,
    [Cliente_Id_cliente] VARCHAR(20) NULL,
    [empleado_id_empleado] VARCHAR(15) NOT NULL,
    [Alojamiento_Id_alojamiento] VARCHAR(20) NOT NULL,
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysEndTime   DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Reserva_Historial));
GO

INSERT INTO [dbo].[Reserva]
(Id_reserva, fecha_entrada, fecha_salida, personas, estado, Cliente_Id_cliente, empleado_id_empleado, Alojamiento_Id_alojamiento)
VALUES
('R001', '2025-11-20', '2025-11-25', 2, 'Pendiente', 'C001', 'E001', 'A001'),
('R002', '2025-12-01', '2025-12-05', 4, 'Confirmada', 'C002', 'E002', 'A002'),
('R003', '2025-11-22', '2025-11-28', 3, 'Confirmada', 'C003', 'E001', 'A003'),
('R004', '2025-11-25', '2025-11-30', 2, 'Cancelada', 'C004', 'E003', 'A004'),
('R005', '2025-12-03', '2025-12-10', 5, 'Pendiente', 'C005', 'E002', 'A005'),
('R006', '2025-11-27', '2025-12-02', 2, 'Confirmada', 'C006', 'E001', 'A006'),
('R007', '2025-12-05', '2025-12-12', 4, 'Pendiente', 'C007', 'E003', 'A007'),
('R008', '2025-12-07', '2025-12-14', 3, 'Confirmada', 'C008', 'E002', 'A008'),
('R009', '2025-11-29', '2025-12-04', 2, 'Cancelada', 'C009', 'E001', 'A009'),
('R010', '2025-12-10', '2025-12-17', 6, 'Pendiente', 'C010', 'E003', 'A010');
GO

-- Actualizar reservas específicas
UPDATE [dbo].[Reserva]
SET fecha_entrada = '2025-12-01', fecha_salida = '2025-12-07', estado = 'Confirmada'
WHERE Id_reserva = 'R001';

UPDATE [dbo].[Reserva]
SET fecha_entrada = '2025-11-25', fecha_salida = '2025-11-30', estado = 'Cancelada'
WHERE Id_reserva = 'R002';
GO

-- Cambiar solo el estado de una reserva
UPDATE [dbo].[Reserva]
SET estado = 'Pendiente'
WHERE Id_reserva = 'R001';
GO

-- Mostrar la fecha y hora actual
PRINT GETUTCDATE();
GO

-- Repetir ejemplo de actualización
UPDATE [dbo].[Reserva]
SET fecha_entrada = '2025-12-01', fecha_salida = '2025-12-07', estado = 'Confirmada'
WHERE Id_reserva = 'R001';

UPDATE [dbo].[Reserva]
SET fecha_entrada = '2025-11-25', fecha_salida = '2025-11-30', estado = 'Cancelada'
WHERE Id_reserva = 'R002';
GO

PRINT GETUTCDATE();
GO

--Nov 20 2025  9:59PM

Completion time: 2025-11-20T22:59:32.9930776+01:00


SELECT * FROM dbo.Reserva_Historial;
GO

SELECT * FROM dbo.Reserva_Historial
WHERE Id_reserva = 'R001';
GO

--borrar uno de las reservas y vemos que desaparece de la tabla pero no del historial

DELETE FROM Reserva
WHERE id_reserva = 'R001';
GO

SELECT * FROM Reserva
GO
-- miro en el historial a ver si aparece la reserva que elimine de la tabla

SELECT * FROM dbo.Reserva_Historial
GO

--revisamos todo el historial de la tabla desde su creación
SELECT * FROM Reserva
FOR system_time ALL
GO

--AS OF para que nos muestre como estaba la tabla en un determinado momento en el tiempo

SELECT *
FROM dbo.Reserva
FOR SYSTEM_TIME AS OF '2025-11-20 21:55:14.5106631'
ORDER BY [empleado_id_empleado]
GO


--FROM para extraer los datos en un periodo de tiempo especifico

SELECT * FROM reserva 
FOR SYSTEM_TIME FROM '2025-11-21' TO '2025-11-23'
ORDER BY Alojamiento_Id_alojamiento
GO


--BETWEEN  Devuelve todas las filas cuya versión estuvo vigente en algún momento entre las dos fechas.

SELECT * FROM Reserva
FOR system_time BETWEEN '2025-11-10' AND '2025-12-05'
ORDER BY Id_reserva;
GO


--CONTAINED IN  Selecciona los registros que estuvieron activos COMPLETAMENTE dentro del periodo especificado, 
--es decir, que al inicio del periodo estaban y que al final del mismo también.

SELECT * FROM Reserva
FOR system_time CONTAINED IN ('2025-11-10','2025-12-12')
WHERE estado = 'Confirmada';
GO





--TABLAS EN MEMORIA 

-----

DROP DATABASE IF EXISTS BBA_Camping_mem;
GO

CREATE DATABASE BBA_Camping_mem;
GO

---- Nivel de compatibilidad (160 para SQL Server 2022, por ejemplo)
ALTER DATABASE BBA_Camping_mem
SET COMPATIBILITY_LEVEL = 160;
GO

USE BBA_Camping_mem;
GO

--Activar opciones para tablas en memoria
ALTER DATABASE CURRENT
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
GO

-- Crear filegroup para memoria optimizada
ALTER DATABASE BBA_Camping_mem
ADD FILEGROUP BBA_Camping_MOD CONTAINS MEMORY_OPTIMIZED_DATA;
GO

-- Agregar archivo físico al filegroup
ALTER DATABASE BBA_Camping_mem
ADD FILE (NAME='BBA_Camping_mem_file',
          FILENAME='C:\DATA\BBA_Camping_mem')
TO FILEGROUP BBA_Camping_MOD;
GO


DROP TABLE IF EXISTS RESERVA;
GO

CREATE TABLE RESERVA (
    Id_reserva VARCHAR(20) NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 500),
    Cliente_Id_cliente VARCHAR(20) NOT NULL,
    Alojamiento_Id_alojamiento VARCHAR(20) NOT NULL,
    fecha_entrada DATE DEFAULT GETDATE() NOT NULL,
    fecha_salida DATE DEFAULT DATEADD(DAY,1,GETDATE()) NOT NULL,
    personas INT DEFAULT 2,
    estado VARCHAR(20) DEFAULT 'Activa',
    empleado_id_empleado VARCHAR(15) NULL,
    precio MONEY DEFAULT 0
)
WITH
(
    MEMORY_OPTIMIZED = ON,
    DURABILITY = SCHEMA_AND_DATA
);
GO


INSERT INTO RESERVA (Id_reserva, Cliente_Id_cliente, Alojamiento_Id_alojamiento)
VALUES 
('R001','CL01','AL01'),
('R002','CL02','AL02'),
('R003','CL03','AL03');
GO

-- Consultar todas las reservas
SELECT * FROM RESERVA;
GO