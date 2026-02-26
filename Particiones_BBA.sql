

--PARTICIONES--
-- CON MI BASE DE DATOS BBA_CampingPart

-- Habilitar la caracteristica
EXECUTE sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO

-- Desactivar
--EXECUTE sp_configure 'show advanced options', 0;
--GO
--RECONFIGURE;
--GO

-- CREANDO CARPETA CON XP_CMDSHELL

xp_cmdshell 'mkdir C:\DATA\'
GO

DROP DATABASE IF EXISTS BBA_CampingP
GO
CREATE DATABASE [BBA_CampingP] 
	ON PRIMARY ( NAME = 'BBA_CampingP', 
		FILENAME = 'C:\Data\BBA_CampingP_Fijo.mdf' , 
		SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) 
	LOG ON ( NAME = 'BBA_CampingP_log', 
		FILENAME = 'C:\Data\BBA_CampingP_log.ldf' , 
		SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%) 
GO

-- SSMS DB Properties

USE BBA_CampingP
GO
--creo los filegroups
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Antiguos] 
GO 
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2023] 
GO 
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2024] 
GO 
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2025]
GO
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2025]
GO	

select * from sys.filegroups
GO


SELECT name, physical_name
FROM sys.database_files
WHERE physical_name LIKE 'C:\DATA%'


-- Creamos los archivos y los vinculamos a los filegroups:

ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Antiguos', FILENAME = 'c:\DATA\Antiguos.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Antiguos] 
GO
ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Altas_2023', FILENAME = 'c:\DATA\Altas_2023.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2023]
GO
ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Altas_2024', FILENAME = 'c:\DATA\Altas_2024.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2024] 
GO
ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Altas_2025', FILENAME = 'c:\DATA\Altas_2025.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2025] 
GO


-- CONSULTANDO TABLAS DEL SISTEMA
select * from sys.filegroups
GO
select * from sys.database_files
GO
SELECT file_id, name, physical_name 
from sys.database_files
go


 --PARTITION FUNCTION (FUNCIÓN DE PARTICIÓN)
-- BOUNDARIES (LIMITES)
-- TENEMOS RANGE : LEFT - RIGHT PARA ESTABLECER LIMITES

--Creamos la función partición, particionará los datos en función de la fecha:
CREATE PARTITION FUNCTION FN_altas_fecha (datetime) 
AS RANGE RIGHT 
	FOR VALUES ('2023-01-01','2024-01-01','2025-01-01')

GO

-- PARTITION SCHEME (ESQUEMA DE PARTICIÓN)
-- MAPEA LOS REGITROS A SUS PARICIONES CORRESPONDIENTES
-- Creamos el esquema de partición, nos mapeará los registros según las particiones:

CREATE PARTITION SCHEME altas_fecha 
AS PARTITION FN_altas_fecha 
	TO (Antiguos,Altas_2023,Altas_2024,Altas_2025) 
GO

DROP TABLE IF EXISTS Alta_reserva
GO
CREATE TABLE Altas_reserva
	( id_alta int identity (1,1), 
	nombre varchar(20), 
	apellido varchar (20), 
	fecha_alta datetime ) 
	ON altas_fecha -- partition scheme 
		(fecha_alta) -- COLUMNA A LA QUE SE LA APLICA LA FUNCIÓN DENTRO DEL ESQUEMA
GO


INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Lucas','Gonzalez','2022-03-14');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Martina','Rodriguez','2021-06-03');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Santiago','Perez','2020-11-22');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Valentina','Lopez','2019-09-17');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Matias','Garcia','2022-07-29');
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO


-- partition function
select name, create_date, value from sys.partition_functions f 
inner join sys.partition_range_values rv 
on f.function_id=rv.function_id 
where f.name = 'FN_altas_fecha'
gO

select p.partition_number, p.rows from sys.partitions p 
inner join sys.tables t 
on p.object_id=t.object_id and t.name = 'Alta_Coleg' 
GO

DECLARE @TableName NVARCHAR(200) = N'Alta_Coleg' 
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--INSERTO MAS REGISTROS EN LA TABLA

INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Nicolas','Torres','2023-02-15');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Isabella','Ramirez','2023-05-20');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Tomás','Flores','2023-01-30');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Emma','Gomez','2023-06-25');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Mateo','Vargas','2023-02-07');

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO

INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Emiliano','Ortiz','2024-04-07');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Julian','Silva','2024-12-27');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Paula','Medina','2024-05-30');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Sebastian','Gaitan','2024-03-05');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Mia','Navarro','2024-06-17');

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO



INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Sofia','Reyes','2025-04-25');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Diego','Figueroa','2025-07-30');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Valentina','Lopez','2025-05-08');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Matias','Gonzalez','2025-12-15');
INSERT INTO Altas_reserva (nombre, apellido, fecha_alta) VALUES ('Isabella','Castro','2025-03-21');

DECLARE @TableName NVARCHAR(200) = N'Altas_reserva' 
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

------------
--OPERACIONES CON PARTICIONES
------------

--SPLIT

ALTER PARTITION FUNCTION FN_altas_fecha()
	SPLIT RANGE ('2021-01-01');
	GO
--
--Nos da error porque debemos de tener un Filegroup libre para asignar a la partición que queremos crear. Al no haber dejado ninguno libre tenemos que crear uno nuevo, adjudicarle el archivo y modificar el esquema de particiones.
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Reservas_2021]
GO
ALTER DATABASE [BBA_CampingP] ADD FILE (NAME = 'Reservas_2021', FILENAME = 'C:\DATA\Reservas_2021.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Reservas_2021]
GO

ALTER PARTITION SCHEME altas_fecha
NEXT USED Reservas_2021;

ALTER PARTITION FUNCTION FN_altas_fecha()
SPLIT RANGE ('2021-01-01');
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO

--MERGE
--Con Merge lo que hacemos es fusionar las particiones, eliminamos el limite que habíamos creado con split.

ALTER PARTITION FUNCTION FN_altas_fecha()
MERGE RANGE ('2021-01-01');
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO

--SWITCH
--Sirve para mover datos entre tablas de manera instantánea, sin necesidad de copiarlos físicamente.

DROP TABLE IF EXISTS Archivo_Reserrvas
GO

CREATE TABLE Antiguo_Reservas 
( id_alta int identity (1,1), 
nombre varchar(20), 
apellido varchar (20), 
fecha_alta datetime ) 
ON Antiguos
go

-- INTERCAMBIO
ALTER TABLE Altas_reserva 
	SWITCH Partition 1 to Antiguo_Reservas
go

select * from Altas_reserva 
go


select * from Antiguo_Reserrvas
go

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO


DECLARE @TableName NVARCHAR(200) = N'Altas_reserva' 
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--TRUNCATE
--El comando TRUNCATE TABLE se utiliza para eliminar todas las filas de una tabla de manera muy rápida, pero con algunas diferencias importantes respecto a DELETE. En este caso elimino la partición 4

TRUNCATE TABLE Altas_reserva 
	WITH (PARTITIONS (4));
go

select * from Altas_reserva
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_reserva
GO

---------------------------------------
--------OTRO EJEMPLO PARTICIONES
-----------------------------------

USE master
GO

DROP DATABASE IF EXISTS PARTICION_CAMPING
GO
CREATE DATABASE PARTICION_CAMPING
GO

USE PARTICION_CAMPING
GO

--creamos los FILEGROUPS
ALTER DATABASE PARTICION_CAMPING ADD FILEGROUP FG_Estancia1
ALTER DATABASE PARTICION_CAMPING ADD FILEGROUP FG_Estancia2
ALTER DATABASE PARTICION_CAMPING ADD FILEGROUP FG_Estancia3
ALTER DATABASE PARTICION_CAMPING ADD FILEGROUP FG_Estancia4
ALTER DATABASE PARTICION_CAMPING ADD FILEGROUP FG_Estancia5
GO

select * from sys.filegroups
GO

--AÑADO ARCHIVOS A LOS FILEGRUOPS
ALTER DATABASE PARTICION_CAMPING
ADD FILE ( NAME = 'Estancia1', FILENAME = 'C:\DATOS\Estancia1.ndf') TO FILEGROUP FG_Estancia1
GO
ALTER DATABASE PARTICION_CAMPING
ADD FILE ( NAME = 'Estancia2', FILENAME = 'C:\DATOS\Estancia2.ndf') TO FILEGROUP FG_Estancia2
GO
ALTER DATABASE PARTICION_CAMPING
ADD FILE ( NAME = 'Estancia3', FILENAME = 'C:\DATOS\Estancia3.ndf') TO FILEGROUP FG_Estancia3
GO
ALTER DATABASE PARTICION_CAMPING
ADD FILE ( NAME = 'Estancia4', FILENAME = 'C:\DATOS\Estancia4.ndf') TO FILEGROUP FG_Estancia4
GO
ALTER DATABASE PARTICION_CAMPING
ADD FILE ( NAME = 'Estancia5', FILENAME = 'C:\DATOS\Estancia5.ndf') TO FILEGROUP FG_Estancia5
GO

SP_HELPFILE  
go

--Creo función de partición basada en dias estancia

CREATE PARTITION FUNCTION PF_DiasEstancia (INT)
AS RANGE LEFT FOR VALUES (3, 7, 14, 30);
GO


-- Crear un esquema de partición con diferentes grupos de archivos

CREATE PARTITION SCHEME PS_DiasEstancia
AS PARTITION PF_DiasEstancia
TO (FG_Estancia1, FG_Estancia2, FG_Estancia3, FG_Estancia4, FG_Estancia5);
GO


DROP TABLE IF EXISTS Reservas_Camping
GO

CREATE TABLE Reservas_Camping (
    IDReserva INT,
    Cliente NVARCHAR(100),
    Parcela NVARCHAR(50),
    DiasEstancia INT,
    FechaEntrada DATE
)
ON PS_DiasEstancia(DiasEstancia);
GO

INSERT INTO Reservas_Camping VALUES
(1, 'Juan', 'P1', 2, '2024-06-01'),
(2, 'Ana', 'P2', 5, '2024-06-02'),
(3, 'Luis', 'P3', 8, '2024-06-03'),
(4, 'Marta', 'P4', 12, '2024-06-04'),
(5, 'Carlos', 'P5', 20, '2024-06-05'),
(6, 'Sofía', 'P6', 35, '2024-06-06');
GO

-- vemos a que particion cada reserva
SELECT *,
       $PARTITION.PF_DiasEstancia(DiasEstancia) AS Particion
FROM Reservas_Camping;
GO

SELECT p.partition_number, p.rows
FROM sys.partitions p
JOIN sys.tables t ON p.object_id = t.object_id
WHERE t.name = 'Reservas_Camping';
GO

--EJEMPLO SPLIT

ALTER DATABASE PARTICION_CAMPING ADD FILEGROUP FG_Estancia6
GO

ALTER DATABASE PARTICION_CAMPING
ADD FILE ( NAME = 'Estancia6', FILENAME = 'C:\DATOS\Estancia6.ndf') TO FILEGROUP FG_Estancia6
GO

ALTER PARTITION SCHEME PS_DiasEstancia
NEXT USED FG_Estancia6
GO

ALTER PARTITION FUNCTION PF_DiasEstancia()
SPLIT RANGE (10);
GO

SP_HELPFILE  
go

DECLARE @TableName NVARCHAR(200) = 'Reservas_Camping'
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , fg.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'less than' ELSE 'less than or equal to' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

--EJEMPLO DE SWITCH--

DROP TABLE IF EXISTS Reservas_Camping_Archivo
GO

CREATE TABLE Reservas_Camping_Archivo (
    IDReserva INT,
    Cliente NVARCHAR(100),
    Parcela NVARCHAR(50),
    DiasEstancia INT,
    FechaEntrada DATE
)
ON FG_Estancia4;
GO

ALTER TABLE Reservas_Camping
SWITCH PARTITION 5 TO Reservas_Camping_Archivo;
GO

SELECT * FROM Reservas_Camping
GO

--TRUNCATE
TRUNCATE TABLE Reservas_Camping
WITH (PARTITIONS (1));
GO
SELECT * FROM Reservas_Camping
GO


-------
--SWITCH IN SWITCH OUT
-----

-- SWITCH IN : CONTENIDO DE UNA TABLA NO PARTICIONADA A UNA PARTICIONADA

DROP DATABASE IF EXISTS PARTITION_SWITCH_CAMPING
GO
CREATE DATABASE PARTITION_SWITCH_CAMPING
GO
USE PARTITION_SWITCH_CAMPING
GO

--Habilitamos el cmdshell y creamos carpeta

EXEC sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO

EXEC master..xp_cmdshell 'mkdir C:\PARTITION_SWITCH_CAMPING\'
GO

--CREAMOS FILEGROUPS

ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILEGROUP Temporada_Baja_1;
ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILEGROUP Temporada_Media;
ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILEGROUP Temporada_Alta;
ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILEGROUP Temporada_Baja_2;
GO


--CREAMOS LOS FICHEROS FISICOS

ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILE (
    NAME = Temporada_Baja_1_dat,
    FILENAME = 'C:\PARTITION_SWITCH_CAMPING\Temporada_Baja_1.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
) TO FILEGROUP Temporada_Baja_1;
GO

ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILE (
    NAME = Temporada_Media_dat,
    FILENAME = 'C:\PARTITION_SWITCH_CAMPING\Temporada_Media.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
) TO FILEGROUP Temporada_Media;
GO

ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILE (
    NAME = Temporada_Alta_dat,
    FILENAME = 'C:\PARTITION_SWITCH_CAMPING\Temporada_Alta.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
) TO FILEGROUP Temporada_Alta;
GO

ALTER DATABASE PARTITION_SWITCH_CAMPING ADD FILE (
    NAME = Temporada_Baja_2_dat,
    FILENAME = 'C:\PARTITION_SWITCH_CAMPING\Temporada_Baja_2.ndf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
) TO FILEGROUP Temporada_Baja_2;
GO

--CREAMOS LA FUNCION DE PARTICION

CREATE PARTITION FUNCTION Estancias_PF (date)
AS RANGE RIGHT FOR VALUES (
    '20230601',  -- fin temporada baja 1
    '20230701',  -- fin temporada media
    '20230801'   -- fin temporada alta
);
GO

--Creamos el schema de partición

CREATE PARTITION SCHEME Estancias_PS
AS PARTITION Estancias_PF
TO (
    Temporada_Baja_1,
    Temporada_Media,
    Temporada_Alta,
    Temporada_Baja_2
);
GO

--Tabla no particionada

DROP TABLE IF EXISTS Estancias_Old
GO
CREATE TABLE Estancias_Old (
    FechaEntrada date NOT NULL,
    IdEstancia int IDENTITY NOT NULL,
    DescripcionEstancia varchar(255) NOT NULL,
    CONSTRAINT chk_FechaEntrada_Julio
        CHECK (FechaEntrada >= '20230701' AND FechaEntrada < '20230801'),
    CONSTRAINT PK_Estancias_Old
        PRIMARY KEY CLUSTERED (FechaEntrada, IdEstancia)
)
ON Temporada_Alta;
GO

--tabla destino particionada

DROP TABLE IF EXISTS Estancias
GO
CREATE TABLE Estancias (
    FechaEntrada date NOT NULL,
    IdEstancia int IDENTITY NOT NULL,
    DescripcionEstancia varchar(255) NOT NULL,
    CONSTRAINT PK_Estancias
        PRIMARY KEY CLUSTERED (FechaEntrada, IdEstancia)
)
ON Estancias_PS (FechaEntrada);
GO

--utilizamos el SWITCH IN

ALTER TABLE Estancias_Old
SWITCH TO Estancias PARTITION 3;
GO

SELECT 
    t.name AS Tabla,
    ps.name AS EsquemaParticion
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
LEFT JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
WHERE t.name = 'Estancias_Old'
  AND i.index_id < 2;
GO

SELECT 
    t.name AS Tabla,
    ps.name AS EsquemaParticion
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
WHERE t.name = 'Estancias'
  AND i.index_id < 2;
GO