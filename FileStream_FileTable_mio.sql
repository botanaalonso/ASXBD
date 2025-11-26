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
ALTER DATABASE [autoescuelap]
SET FILESTREAM (DIRECTORY_NAME = 'FotografiaStore')
WITH ROLLBACK IMMEDIATE
GO

ALTER DATABASE [autoescuelap]
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

CREATE DATABASE [BBA_CampingP] 
	ON PRIMARY ( NAME = 'BBA_CampingP', 
		FILENAME = 'C:\Data\BBA_CampingP_Fijo.mdf' , 
		SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) 
	LOG ON ( NAME = 'BBA_CampingP_log', 
		FILENAME = 'C:\Data\BBA_CampingP_log.ldf' , 
		SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%) 
GO

-- creo los filegroups

ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Antiguos] 
GO 
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2023] 
GO 
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2024] 
GO 
ALTER DATABASE [BBA_CampingP] ADD FILEGROUP [Altas_2025]
GO

-- Creamos los archivos y los vinculamos a los filegroups:

ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Antiguos', FILENAME = 'c:\DATA\Antiguos.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Antiguos] 
GO

ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Altas_2023', FILENAME = 'c:\DATA\Altas_2023.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2023]
GO

ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Altas_2024', FILENAME = 'c:\DATA\Altas_2024.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2024] 
GO

ALTER DATABASE [BBA_CampingP] ADD FILE ( NAME = 'Altas_2025', FILENAME = 'c:\DATA\Altas_2025.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2025] 
GO

select file_id, name, physical_name
from sys.database_files
GO