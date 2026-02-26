------------------
--ADO.NET
----------------------

USE BBA;
GO
SELECT * FROM cliente;
go

BULK INSERT [dbo].[Cliente]
FROM 'C:\Users\Bruno\Desktop\Scripts\RegistrosClientes.txt'
WITH
(
    FIELDTERMINATOR = ',',  -- Separador de campos
    ROWTERMINATOR = '\n',   -- Separador de filas (salto de línea)
    FIRSTROW = 1             -- Si no hay encabezado, empezar desde la primera fila
);

SELECT * FROM cliente;
GO


--BASES DE DATOS CONTENIDAS

--TEORIA

--Las bases de datos contenidas en SQL Server son un tipo de base de datos que está aislada de otras 
--bases de datos y de la instancia de SQL Server que aloja la base de datos. 
--Este aislamiento proporciona varios beneficios, que incluyen:

--Seguridad mejorada: Las bases de datos contenidas se pueden hacer más seguras al restringir el acceso a 
-- ellas y al dificultar que los usuarios no autorizados modifiquen o eliminen datos.

--Gestión simplificada: Las bases de datos contenidas se pueden administrar de forma independiente 
-- de otras bases de datos, lo que puede simplificar el proceso de copia de seguridad, restauración 
--y migración de bases de datos.

--Mayor portabilidad: Las bases de datos contenidas se pueden mover fácilmente entre diferentes instancias
-- de SQL Server, lo que puede ser útil para la recuperación ante desastres y fines de desarrollo.



-----------------------------------
-- BD CONTENIDAS BRUNO BOTANA ALONSO
------------------------------------

USE MASTER
GO

-- SE ACTIVAN OPCIONES AVANZADAS CON 1
EXEC SP_CONFIGURE 'show advanced options', 1
GO
-- Actualizamos el valor con RECONFIGURE
-- Es como reiniciar la Instancia cambiando la Configuración
RECONFIGURE
GO

--ACTIVAMOS LA CARACTERISTICA DE BD CONTENIDA
EXEC SP_CONFIGURE 'contained database authentication', 1
GO

-- Configuration option 'contained database authentication' changed from 1 to 1. Run the RECONFIGURE statement to install.

-- Actualizamos de nuevo
RECONFIGURE
GO

-- Configuration option 'contained database authentication' changed from 0 to 1. Run the RECONFIGURE statement to install.

---
-- Hasta aqui preparamos el entorno para lo que vamos a ejecutar
---
--CREATE DATABASE Contenida
--CONTAINMENT=FULL
--GO


DROP DATABASE IF EXISTS BBA_Contenida
GO
CREATE DATABASE BBA_Contenida
CONTAINMENT=PARTIAL
GO

-- EN SSMS
-- PROPIEDADES DE LA BASE DE DATOS  Containmnent  Partial, todavía NO existe la Full

-- Una vez creada la activamos
USE BBA_Contenida
GO

-- Creo usuario bruno, asocio esquema dbo en la BD Contenida
	
DROP USER IF EXISTS bruno
GO
CREATE USER bruno
	WITH PASSWORD='Abcd1234.',
	DEFAULT_SCHEMA=[dbo]
	GO

-- Añadimos el usuario bruno el rol dbo_owner
-- Deprecated (Microsoft considera que este sp en el futuro se eliminara.
EXEC sp_addrolemember 'db_owner', 'bruno'
GO
-- Usamos la nueva sentencia ALTER ROLE
ALTER ROLE db_owner
ADD MEMBER bruno
GO

-- Intento conectarme bruno Abcd1234. desde Object Explorer
-- ERROR
-- TITLE: Connect to Server
--------------------------------
--Cannot connect to DESKTOP-V9719B2
--------------------------------
--ADDITIONAL INFORMATION:
--Login failed for user 'juan'. (Microsoft SQL Server, Error: 18456)
--For help, click: http://go.microsoft.com/fwlink?ProdName=Microsoft%20SQL%20Server&EvtSrc=MSSQLServer&EvtID=18456&LinkId=20476
------------------------------

-- Damos permiso grant para que juan se pueda conectar
GRANT CONNECT TO bruno
GO

-- Intento conectarme bruno abcd1234.
-- Login failed for user 'bruno'. (Microsoft SQL Server, Error: 18456)

-- Vamos a
-- SSMS -> Object Explorer -> Connect -> Aditional Connection Parameters
-- En "Aditional Connection Parameters" DATABASE=Contenida
-- Vuelvo a intentarlo 
-- Autenticación    SQL Server Authentication         (Autenticacion Mixta)
-- bruno      Abcd1234.


-- Entramos. Mirar GUI

-- Desde bruno pruebo a crear una Tabla


-- Entramos. Mirar GUI

-- Desde Juan pruebo a crear una Tabla

CREATE TABLE [dbo].[TablaContenida](
	[Codigo] [nchar](10) NULL,
	[Nombre] [nchar](10) NULL
) ON [PRIMARY]
GO

-----------------------
--BLOB FILESTREAM FILETABLE--
----------------------------
-- ALMACENANDO EN LA BD COMO VARBINARY

--	VARBINARY

-- INSERTAR BLOB SIN FILESTREAM 

-- Trabajando con Procedimiento Almacenado Extendido xp_cmdshell
-- Activar opciones avanzadas
EXECUTE sp_configure 'show advanced options', 1;
GO
-- Actualizar la configuración
RECONFIGURE;
GO

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

exec master..xp_cmdshell 'mkdir C:\Fotos_Actores\' , no_output 
GO
-- En lugar de exec master..xp_cmdshell puedo usar
xp_cmdshell 'dir c:\F*'
GO

DROP DATABASE IF EXISTS IMAGENES  
GO
CREATE DATABASE IMAGENES
GO
USE IMAGENES 
GO
DROP TABLE IF EXISTS DBO.DOCUMENTOS
GO
CREATE TABLE DBO.DOCUMENTOS (ID INT IDENTITY,
                             NOMBRE VARCHAR(255),
                             CONTENIDO VARBINARY(MAX),
							 EXTENSION CHAR(4)
							 )
GO
INSERT INTO DBO.DOCUMENTOS (NOMBRE,CONTENIDO,EXTENSION)
SELECT 'Bardem', BULKCOLUMN,'JPG'
FROM OPENROWSET(BULK N'C:\Fotos_Actores\Bardem.JPG', SINGLE_BLOB) AS DOCUMENT
GO
INSERT INTO DBO.DOCUMENTOS (NOMBRE,CONTENIDO,EXTENSION)
SELECT 'Zahera', BULKCOLUMN,'JPG'
FROM OPENROWSET(BULK N'C:\Fotos_Actores\Zahera.JPG', SINGLE_BLOB) AS DOCUMENT
GO
SELECT * FROM DBO.DOCUMENTOS 
GO


---------------
----FILSTREAM
-------------

--Activar opciones avanzadas
EXEC sp_configure filestream_access_level, 2  
--Actualizar la configuración
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

SELECT * FROM sys.filegroups
GO
SELECT * FROM sys.database_files
GO

--Activo la Base de Datos
USE BBA_Camping_test
GO
DROP TABLE IF EXISTS DBO.DOCUMENTOS
GO
CREATE TABLE DBO.DOCUMENTOS (ID INT IDENTITY,
                             NOMBRE VARCHAR(255),
                             CONTENIDO VARBINARY(MAX),
							 EXTENSION CHAR(4)
							 )
GO

INSERT INTO DBO.DOCUMENTOS (NOMBRE,CONTENIDO,EXTENSION)
SELECT 'Bungalows', BULKCOLUMN,'JPG'
FROM OPENROWSET(BULK N'C:\Fotos Camping\Bungalows.JPG', SINGLE_BLOB) AS DOCUMENT
GO
INSERT INTO DBO.DOCUMENTOS (NOMBRE,CONTENIDO,EXTENSION)
SELECT 'tiendas', BULKCOLUMN,'JPG'
FROM OPENROWSET(BULK N'C:\Fotos Camping\tiendas.JPG', SINGLE_BLOB) AS DOCUMENT
GO
SELECT * FROM DBO.DOCUMENTOS 
GO



------------
--FILETABLE
--------------

USE [master]
GO
ALTER DATABASE [BBA_Camping_test]
SET FILESTREAM( DIRECTORY_NAME = 'BBA_Camping_test' ) 
WITH ROLLBACK IMMEDIATE
GO

USE [master]
GO
ALTER DATABASE [BBA_Camping_test] 
	SET FILESTREAM( NON_TRANSACTED_ACCESS = FULL, 
	DIRECTORY_NAME = 'BBA_Camping_test' ) 
	WITH ROLLBACK IMMEDIATE
GO


use BBA_Camping_test 
GO
-- TABLA DIFERENTE DE LA CREADA POR USUARIOS
drop table if exists DocumentosCamping
GO
CREATE TABLE DocumentosCamping AS FileTable
WITH
(
    FileTable_Directory = 'DocumentosCamping',
    FileTable_Collate_Filename = database_default,
	FILETABLE_STREAMID_UNIQUE_CONSTRAINT_NAME=UQ_stream_id);
GO
-- Ver en SSMS FileTables-> Explore FileTable Directory 
-- Ver Carpeta Fisica relacionada
-- Imagen
-- Arrastramos BLOB´s a la Carpeta

SELECT * FROM [dbo].[DocumentosCamping]
GO

-------------

