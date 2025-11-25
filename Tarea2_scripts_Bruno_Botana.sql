--CADENA DE PROPIEDAD


-- como siempre elimino vista si ya existe

DROP VIEW IF EXISTS Infoclientes
GO

-- creo una vista con información de los clientes
CREATE VIEW Infoclientes
AS SELECT   
Id_cliente,nombre,apellidos,email
FROM dbo.Cliente
GO

-- creo también un rol 

DROP ROLE IF EXISTS Consultasclientes
GO

CREATE ROLE Consultasclientes
GO

--damos permisos SELECT sobre esa vista

GRANT SELECT ON Infoclientes TO Consultasclientes
GO	

-- creo un usuario
CREATE USER Xoel WITHOUT LOGIN
GO

-- añado al user creao al ROL 
ALTER ROLE Consultasclientes ADD MEMBER Xoel;
GO

--impersono sobre el usuario Xoel
EXECUTE AS USER = 'Xoel';
GO

--consulto sobre la vista
SELECT 
	Nombre, apellidos
FROM dbo.InfoClientes;
GO



	EXECUTE AS USER = 'Xoel';
	SELECT * FROM Infoclientes
	GO

	REVERT;
GO

-- DEMOSTRACIÓN USANDO SP
-- STORED PROCEDURE (PROCEDIMIENTO ALMACENADO)

GRANT CREATE PROCEDURE

CREATE OR ALTER PROCEDURE dbo.insertarnuevoempleado
--IMPUT PARAMETERS
@id_empleado varchar (15),
@nombre varchar(50),
@apellidos varchar(50),
@puesto varchar(50),
@telefono varchar(50)

AS
BEGIN
	INSERT INTO dbo.empleado
	(id_empleado,nombre,apellidos,puesto,telefono)
	VALUES
	(@id_empleado,@nombre,@apellidos,@puesto,@telefono);
END;
GO
USE BBA_Camping
GO
-------------------
EXECUTE AS USER = 'Xoel';
GO
REVERT
GO
PRINT USER
GO

EXECUTE AS USER = 'sa'
GO
---------------------

- Probar el procedimiento
EXEC dbo.InsertarNuevoEmpleado
    @id_empleado = 'E001',
    @nombre = 'Carlos',
    @apellidos = 'García',
    @puesto = 'Recepción',
    @telefono ='652636263'


	--CURSORES
	---Los cursores son un conjunto de registros en memoria. Lo que hay que hacer es reservar posiciones de memoria, 
	--declarar esas posiciones como si fuera una variable.	

	--Backup de bases de datos con Cursores	

	USE master
GO
CREATE OR ALTER PROC Cursor_Backup
AS
BEGIN
 DECLARE @name NVARCHAR(128);   -- aquí declarada
 DECLARE @path NVARCHAR(256);
 DECLARE @fileName NVARCHAR(256);
 DECLARE @fileDate NVARCHAR(20);

 SET @path = 'C:\Backup\';

 SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) 
 + REPLACE(CONVERT(VARCHAR(20),GETDATE(),108),':','');

 DECLARE db_cursor CURSOR READ_ONLY FOR
 SELECT name 
 FROM sys.databases
 WHERE name IN ('Northwind','AdventureWorks2017');

 OPEN db_cursor;
 FETCH NEXT FROM db_cursor INTO @name;

 WHILE @@FETCH_STATUS = 0
 BEGIN
 SET @fileName = @path + @name + '_' + @fileDate + '.BAK';
 BACKUP DATABASE @name TO DISK = @fileName;

 FETCH NEXT FROM db_cursor INTO @name;
 END;

 CLOSE db_cursor;
 DEALLOCATE db_cursor;
END;
GO

EXEC Cursor_Backup; 

--------------
--Procedimiento para crear usuario a partir de registros de una tabla
------------------

 Creamos el procedimiento
CREATE OR ALTER PROCEDURE Actualizar_Usuarios_Empleados
AS
BEGIN
-- Declaramos  variables para los nombres, apellidos y user name

DECLARE @nombre NVARCHAR(50)
DECLARE @apellido NVARCHAR (80)
DECLARE @user_name NVARCHAR (80)

--ahora declaramos la variable del cursor

DECLARE empleado_cursor CURSOR FOR

SELECT nombre, apellidos FROM empleado

--Ahora abrimos el cursor
OPEN empleado_cursor

-- se situa en la primera posición para que comience a leer
FETCH NEXT FROM profesor_cursor INTO @nombre, @apellido

--se inicia el bucle, que saldrá cuando no queden más registros

WHILE @@FETCH_STATUS =  0
BEGIN

---creamos el usuario con la primera letra del nombre y apellido

SET @user_name = LEFT(@nombre, 1) + @apellido
	 CREATE USER [@user_name]  WITHOUT LOGIN;
	        ALTER ROLE R_Empleado ADD MEMBER [@user_name];
-- se pasa al registro siguiente

	FETCH NEXT FROM empleado_cursor INTO @nombre, @apellido
	END

-- cerramos el cursor y liberamos memoria
	CLOSE empleado_cursor
	DEALLOCATE empleado_cursor
END

------------
---PROCEDIMIENTO ALMACENADO PARA HACER BACKUP DE LA BASE DE DATOS
-----------

USE master
GO
DROP PROCEDURE IF EXISTS BACKUP_ALL_DB_PARENTRADA
GO
-- PATH = RUTA

CREATE OR ALTER PROC BACKUP_ALL_DB_PARENTRADA
	@path VARCHAR(256) -- PARAMETRO DE ENTRADA PARA DAR RUTA
AS
-- Declarando variables
DECLARE @name VARCHAR(50), -- database name
-- @path VARCHAR(256), -- path for backup files
@fileName VARCHAR(256), -- filename for backup
@fileDate VARCHAR(20), -- used for file name
@backupCount INT

-- TABLA TEMPORAL #tempBackup 

CREATE TABLE [dbo].#tempBackup 
	(intID INT IDENTITY (1, 1), 
	name VARCHAR(200))

-- OTRA POSIBILIDAD. ASIGNAR LA RUTA A UNA VARIABLE la Carpeta Backup
-- SET @path = 'C:\Backup\'

-- INCLUIR LA FECHA EN EL NOMBRE DE FICHERO RESULTANTE
-- Includes the date in the filename
SET @fileDate = CONVERT(VARCHAR(20), GETDATE(), 112)

-- INCLUIR LA FECHA Y LA HOARA EN EL NOMBRE DE FICHERO RESULTANTE
-- Includes the date and time in the filename
-- SET @fileDate = CONVERT(VARCHAR(20), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '')

INSERT INTO [dbo].#tempBackup (name)
	SELECT name
	FROM master.dbo.sysdatabases
	WHERE name in ( 'BBA_Camping','BBA_Campingp')
-- WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb')

SELECT TOP 1 @backupCount = intID 
FROM [dbo].#tempBackup 
ORDER BY intID DESC

-- Utilidad: PARA COMPROBAR NUMERO DE Backups a realizar. SOLO PARA DEPURACIÓN LUGO LO BORRARÍA.
print @backupCount

-- COMPROBAR QUE HAY ALGUNA BD A LA CUAL REALIZARLE EL BACKUP
IF ((@backupCount IS NOT NULL) AND (@backupCount > 0))
BEGIN
	DECLARE @currentBackup INT
	SET @currentBackup = 1 -- ASIGNACIÓN DEL VALOR INICIAL
	WHILE (@currentBackup <= @backupCount) -- MIENTRAS QUE SE CUMPLA LA CONDICIÓN SE EJECUTA EL BUCLE
		BEGIN
			SELECT
				@name = name,
				@fileName = @path + name + '_' + @fileDate + '.BAK' -- Unique FileName
				--@fileName = @path + @name + '.BAK' -- Non-Unique Filename
				FROM [dbo].#tempBackup
				WHERE intID = @currentBackup

			-- Utilidad: Solo Comprobaci�n Nombre Backup
			print @fileName
			
			-- SIN INIT NO SOBREESCRIBE EL FICHERO. MEJOR USAR WITH INIT
			-- does not overwrite the existing file
				BACKUP DATABASE @name TO DISK = @fileName
			-- overwrites the existing file (Note: remove @fileDate from the fileName so they are no longer unique
			--BACKUP DATABASE @name TO DISK = @fileName WITH INIT

				SET @currentBackup = @currentBackup + 1 -- CONTADOR
		END
END

-- Utilidad: Solo ComprobaciÓn Mirar panel de Resultados Autonumerico y Nombre BD
SELECT * FROM [dbo].#tempBackup
-- 
DROP TABLE [dbo].#tempBackup

GO


-- Ejecutar Procedimiento
-- Input Parameter 'C:\Backup\'
EXEC BACKUP_ALL_DB_PARENTRADA 'C:\Backup\'
GO

-- RESULTADO



-- Messages

    SELECT * FROM #tempBackup;

    DROP TABLE #tempBackup;
END;
GO

-- Ejecutar Procedimiento
-- Input Parameter 'C:\Backup\'
EXEC BACKUP_ALL_DB_PARENTRADA 'C:\Backup\'
GO

-- RESULTADO

-- Results

--intID	name
--1	Northwind
--2	pubs


-- Messages

---------------------------------------------------

--TRANSACIONES

-------------------------------------------------------

-- CREAR UNA TRANASCCION PARA QUE SE PASE DINERO DE LA CUENTA DEL CAMPING A LA CUENTA PARA PAGAR A LOS PROVEEDORES

-- creo la base de datos
USE master;
GO
DROP DATABASE IF EXISTS BBA_Camping_Transaccion;
GO
CREATE DATABASE BBA_Camping_Transaccion;
GO
USE BBA_Camping_Transaccion;
GO

--CREO TABLA DE  CUENTAS DEL CAMPING Y CUENTA DE PROVEEDORES


--Cuentas del camping (Caja interna)

CREATE TABLE dbo.CuentasCamping
(
    CuentaID INT IDENTITY PRIMARY KEY,
    NombreCuenta NVARCHAR(100) NOT NULL,
    Saldo DECIMAL(19,2) NOT NULL
);
GO

-- Cuenta para pagar proveedores

CREATE TABLE dbo.CuentaProveedores
(
    ID INT PRIMARY KEY,
    Saldo DECIMAL(19,2) NOT NULL
);
GO

-- inserto datos  (camping y proveedores)

INSERT INTO dbo.CuentasCamping (NombreCuenta, Saldo)
VALUES ('Ingresos Piscina', 800.00),
       ('Ingresos Restaurante', 1200.00),
       ('Ingresos Supermercado', 500.00);
GO

INSERT INTO dbo.CuentaProveedores (ID, Saldo)
VALUES (1, 0.00);
GO

---PROCEDIMIENTO para transferir dinero de una cuenta del Camping a la cuenta de proveedores


-- Uso transacción, valido si hay saldo suficiente, si algo falla vuelvo para atras con ROOLBACK y si todo ok le hago el COMMIT


CREATE OR ALTER PROCEDURE dbo.TransferirDineroAProveedores
    @CuentaCampingID INT,
    @Cantidad DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SaldoActual DECIMAL(10,2);

    BEGIN TRAN;

    -- Obtener saldo original
    SELECT @SaldoActual = Saldo
    FROM dbo.CuentasCamping
    WHERE CuentaID = @CuentaCampingID;

    IF @SaldoActual IS NULL
    BEGIN
        ROLLBACK TRAN;
        RAISERROR('La cuenta seleccionada no existe.', 16, 1);
        RETURN;
    END

    -- Validar saldo suficiente
    IF @SaldoActual < @Cantidad
    BEGIN
        ROLLBACK TRAN;
        RAISERROR('Saldo insuficiente para realizar la transferencia.', 16, 1);
        RETURN;
    END

    -- Restar al camping
    UPDATE dbo.CuentasCamping
    SET Saldo = Saldo - @Cantidad
    WHERE CuentaID = @CuentaCampingID;

    -- Sumar a proveedores
    UPDATE dbo.CuentaProveedores
    SET Saldo = Saldo + @Cantidad
    WHERE ID = 1;

    COMMIT TRAN;

    PRINT 'Transferencia realizada correctamente.';
END;
GO

---PRUEBO FUNCIONAMIENTO : TRANSFERIR 300€ DESDE “INGRESOS RESTAURANTE”


--miro cuentas :

SELECT * FROM dbo.CuentasCamping;


CuentaID	NombreCuenta	Saldo
1	Ingresos Piscina	800.00
2	Ingresos Restaurante	1200.00
3	Ingresos Supermercado	500.00
4	Ingresos Piscina	800.00
5	Ingresos Restaurante	1200.00
6	Ingresos Supermercado	500.00


SELECT * FROM dbo.CuentaProveedores;

ID	Saldo
1	0.00


--- ejecuto transferencia

EXEC dbo.TransferirDineroAProveedores 
     @CuentaCampingID = 2,   -- Ingresos Restaurante
     @Cantidad = 300.00;


	 Transferencia realizada correctamente.

Completion time: 2025-11-23T12:47:48.8848459+01:00


-- reviso saldos 

SELECT * FROM dbo.CuentasCamping;
SELECT * FROM dbo.CuentaProveedores;

------------------------------
--- TRANSACION EXPLICITA CON UPDATE
--------------------------------

USE BBA_Camping_Transaccion;
GO

DECLARE @CuentaCampingID INT = 1;  -- Ej: Ingresos Restaurante
DECLARE @Cantidad DECIMAL(10,2) = 500.00;
DECLARE @SaldoActual DECIMAL(10,2);

SET XACT_ABORT ON; -- Controla errores y asegura rollback automático si hay fallo

BEGIN TRY
    BEGIN TRANSACTION;

    -- Obtener saldo actual de la cuenta del camping
    SELECT @SaldoActual = Saldo
    FROM dbo.CuentasCamping
    WHERE CuentaID = @CuentaCampingID;

    IF @SaldoActual IS NULL
    BEGIN
        RAISERROR('La cuenta del camping no existe.', 20, 1);
    END

    -- 2️⃣ Verificar saldo suficiente
    IF @SaldoActual < @Cantidad
    BEGIN
        RAISERROR('Saldo insuficiente para la transferencia.', 20, 1);
    END

    -- 3️⃣ Restar dinero a la cuenta del camping
    UPDATE dbo.CuentasCamping
    SET Saldo = Saldo - @Cantidad
    WHERE CuentaID = @CuentaCampingID;

    -- 4️⃣ Sumar dinero a la cuenta de proveedores
    UPDATE dbo.CuentaProveedores
    SET Saldo = Saldo + @Cantidad
    WHERE ID = 1;

    COMMIT TRANSACTION;
    PRINT 'Transferencia realizada correctamente.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Ocurrió un error durante la transferencia.';
    PRINT ERROR_MESSAGE();  -- Muestra el mensaje de error
END CATCH;
GO


SELECT * FROM dbo.CuentasCamping;
SELECT * FROM dbo.CuentaProveedores;
GO

EXEC dbo.TransferirDineroAProveedores
-

--OTRA TRANSACCIÓN EXPLICITA PARA para calcular el número total de clientes inscritos por actividad,



USE BBA_Camping;
GO

-- Añadir columna para almacenar el total de clientes inscritos (si no existe)
IF COL_LENGTH('dbo.Actividades','TotalClientes') IS NULL
BEGIN
    ALTER TABLE dbo.Actividades
    ADD TotalClientes INT NULL;
END
GO
--Transacción explícita para actualizar TotalClientes

sql
Copiar código
SET XACT_ABORT ON;  -- Asegura rollback automático si algo falla
BEGIN TRANSACTION;

BEGIN TRY
    -- Actualizamos TotalClientes por actividad
    UPDATE A
    SET TotalClientes = ISNULL(COUNT(I.ClienteID),0)
    FROM dbo.Actividades A
    LEFT JOIN dbo.Inscripciones I
        ON A.ActividadID = I.ActividadID
    GROUP BY A.ActividadID, A.NombreActividad;

    COMMIT TRANSACTION;
    PRINT 'Actualización de total de clientes completada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Ocurrió un error, se revirtieron los cambios.';
    PRINT ERROR_MESSAGE();
END CATCH;
GO
--compruebo
sql

SELECT ActividadID, NombreActividad, TotalClientes
FROM dbo.Actividades;
GO


------------------------------------------------
--IMPORTAR /EXPORTAR IMAGENES
------------------------------------------------

USE tempdb
GO
DROP TABLE IF EXISTS Pictures
GO
CREATE TABLE Pictures (
   pictureName NVARCHAR(40) PRIMARY KEY NOT NULL
   , picFileName NVARCHAR (100)
   , PictureData VARBINARY (max)
   )
GO
Use master
Go
EXEC sp_configure 'show advanced options', 1; 
GO 
RECONFIGURE; 
GO 
--RECONFIGURE WITH OVERRIDE; 
--GO
EXEC sp_configure 'Ole Automation Procedures', 1; 
GO 
RECONFIGURE; 
GO

--ALTER SERVER ROLE [bulkadmin] ADD MEMBER [Enter here the Login Name that will execute the Import] 
--GO  

ALTER SERVER ROLE [bulkadmin] ADD MEMBER [DESKTOP-LH68S6O\Bruno]
GO

USE tempdb
GO
-- Image Import Stored Procedure
-- IMPORTAR IMAGENES

CREATE OR ALTER PROCEDURE dbo.usp_ImportImage (
     @PicName NVARCHAR (100)
   , @ImageFolderPath NVARCHAR (1000)
   , @Filename NVARCHAR (1000)
   )
AS
BEGIN
   DECLARE @Path2OutFile NVARCHAR (2000);
   DECLARE @tsql NVARCHAR (2000);
   SET NOCOUNT ON
   SET @Path2OutFile = CONCAT (
         @ImageFolderPath
         ,'\'
         , @Filename
         );
   SET @tsql = 'insert into Pictures (pictureName, picFileName, PictureData) ' +
               ' SELECT ' + '''' + @PicName + '''' + ',' + '''' + @Filename + '''' + ', * ' + 
               'FROM Openrowset( Bulk ' + '''' + @Path2OutFile + '''' + ', Single_Blob) as img'
   EXEC (@tsql)
   SET NOCOUNT OFF
END
GO



--Image Export Stored Procedure
-- EXPORT IMAGENES

CREATE OR ALTER PROCEDURE dbo.usp_ExportImage (
   @PicName NVARCHAR (100)              -- Nombre de la imagen a exportar (clave en la tabla)
   ,@ImageFolderPath NVARCHAR(1000)     -- Carpeta destino donde se guardará el archivo
   ,@Filename NVARCHAR(1000)            -- Nombre del archivo que se generará (ej: SSMS.jpg)
)
AS
BEGIN
   DECLARE @ImageData VARBINARY (MAX);   -- Variable para guardar los bytes de la imagen
   DECLARE @Path2OutFile NVARCHAR (2000);-- Ruta completa al archivo a exportar
   DECLARE @Obj INT;                     -- Identificador del objeto COM (ADODB.Stream)
 
   SET NOCOUNT ON;                       -- Evita mensajes de "x filas afectadas"
 
   -- Recupera los datos binarios de la imagen almacenada en la tabla Pictures
   SELECT @ImageData = (
         SELECT CONVERT(VARBINARY(MAX), PictureData, 1) -- Asegura formato VARBINARY
         FROM Pictures
         WHERE pictureName = @PicName                   -- Coincide por nombre
         );
 
   -- Construye la ruta final del archivo concatenando carpeta + "\" + nombre
   SET @Path2OutFile = CONCAT(
         @ImageFolderPath
         ,'\'
         ,@Filename
         );

   BEGIN TRY
     -- Crea un objeto COM tipo ADODB.Stream (para manipular archivos binarios)
     EXEC sp_OACreate 'ADODB.Stream' ,@Obj OUTPUT;

     -- Establece propiedad Type = 1 (indica que se trata de datos binarios)
     EXEC sp_OASetProperty @Obj, 'Type', 1;

     -- Abre el stream
     EXEC sp_OAMethod @Obj, 'Open';

     -- Escribe los bytes de la imagen dentro del stream
     EXEC sp_OAMethod @Obj, 'Write', NULL, @ImageData;

     -- Guarda el stream en un archivo físico en la ruta especificada
     -- El parámetro "2" indica que sobreescriba si ya existe
     EXEC sp_OAMethod @Obj, 'SaveToFile', NULL, @Path2OutFile, 2;

     -- Cierra el stream
     EXEC sp_OAMethod @Obj, 'Close';

     -- Libera el objeto COM
     EXEC sp_OADestroy @Obj;
   END TRY
    
   BEGIN CATCH
     -- Si ocurre un error, destruye el objeto COM para evitar fugas
     EXEC sp_OADestroy @Obj;
   END CATCH
 
   SET NOCOUNT OFF;
END
GO
SELECT * FROM Pictures
GO

-- PROBANDO
-- CARPETA C:\IMAGENES\ENTRADA

-- In order to import to SQL Server execute the following:

exec dbo.usp_ImportImage 'SSMS','C:\IMAGENES\ENTRADA','SSMS.png'  
GO

SELECT * FROM Pictures
GO

-- in order to export the file, use the following:
-- EXPORTAR FICHERO USANDO LA EJECUCIÓN SIGUIENTE
exec dbo.usp_ExportImage  'SSMS','C:\IMAGENES\SALIDA','SSMS.jpg'
GO


EXEC sp_configure 'xp_cmdshell', 1; 
GO 
RECONFIGURE; 
GO

xp_cmdshell "dir C:\IMAGENES\SALIDA"
go

-- 10/05/2023  09:45 AM            97,161 SSMS.jpg


--deshabilitamos proc 'xp_cmdshell' por seguridad ya que un atacante podria tener permisos sobre el sistema operativo

EXEC sp_configure 'xp_cmdshell', 0; 
GO 