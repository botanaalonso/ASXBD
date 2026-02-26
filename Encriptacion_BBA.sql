--ENCRIPTACTION SP PROCEDIMIENTO ALMACENADO--

USE [BBA_Camping]
GO
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  [Id_cliente],
      [nombre],
      [apellidos],
      [dni],
	  [telefono],
	  [fecha_registro]

  FROM [dbo].[Cliente]
GO


CREATE OR ALTER PROCEDURE sp_ReclamaciónCliente
WITH ENCRYPTION
AS
BEGIN
	SELECT 
		Id_cliente, 
		nombre, 
		apellidos, 
		dni, 
		telefono, 
		fecha_registro
	FROM [dbo].[Cliente]
	WHERE ciudad = 'Barcelona';
END
GO

EXECUTE sp_ReclamaciónCliente
GO







SP_HELP sp_ReclamaciónCliente
GO
SP_HELPTEXT sp_ReclamaciónCliente
GO

-- The text for object 'Royalties' is encrypted.



/*
ENCRIPTAR COLUMNAS
La encriptación de columnas en SQL Server protege datos sensibles (ej. DNI, tarjetas) mediante cifrado simétrico (EncryptByKey) o tecnologías avanzadas como Always Encrypted.
Implica crear claves maestras, certificados y claves simétricas, almacenando los datos como VARBINARY. 
Always Encrypted es recomendado porque cifra los datos en tránsito y reposo, impidiendo el acceso incluso al administrador de la base de datos.
*/


--verificar que estoy en la BD correcta

SELECT DB_NAME();

-- Lista las claves simétricas existentes:

SELECT name 
FROM sys.symmetric_keys;


--uso mi base de datos

USE BBA_Camping;
GO
--creamos la master key

DROP MASTER KEY
GO
 CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
 GO

 --para ver si se ha creado correctamente
 SELECT name KeyName,
	symmetric_key_id KeyID,
	key_length KeyLength,
	algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO


 --creo el certificado con el que se protegerá la clave simétrica

 CREATE CERTIFICATE Cert_Cliente_DNI
WITH SUBJECT = 'Cifrado del DNI de los clientes';
GO


--compruebo que se haya creado el certificado
SELECT name CertName,
	certificate_id CertID,
	pvt_key_encryption_type_desc EncryptType,
	issuer_name Issuer
FROM sys.certificates;
GO


-- creo la clave simétrica
CREATE SYMMETRIC KEY SK_Cliente_DNI
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE Cert_Cliente_DNI;
GO

--comprobamos
SELECT name KeyName,
	symmetric_key_id KeyID,
	key_length KeyLength,
	algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO


--Se añade columna cifrada a la tabla cliente
ALTER TABLE dbo.Cliente
ADD dni_encriptado VARBINARY(128);
GO

--verificar tabla
SELECT Id_cliente, dni, dni_encriptado
FROM dbo.Cliente;
GO

-- Abro clave simétrica
OPEN SYMMETRIC KEY SK_Cliente_DNI
DECRYPTION BY CERTIFICATE Cert_Cliente_DNI;
GO

-- se cifran los DNI existentes
UPDATE dbo.Cliente
SET dni_encriptado =
    EncryptByKey(
        Key_GUID('SK_Cliente_DNI'),
        dni
    );
GO

-- Compruebo datos cifrados
SELECT Id_cliente, dni, dni_encriptado
FROM dbo.Cliente;
GO

-- Desencirptar el DNI , consulta


OPEN SYMMETRIC KEY SK_Cliente_DNI
DECRYPTION BY CERTIFICATE Cert_Cliente_DNI;
GO

SELECT 
    Id_cliente,
    dni_encriptado AS DNI_Cifrado,
    CONVERT(varchar(15), DecryptByKey(dni_encriptado)) AS DNI_Desencriptado
FROM dbo.Cliente;
GO

-- Cierro la clave
CLOSE SYMMETRIC KEY SK_Cliente_DNI;
GO

---------------------------------------
---------OTRO EJEMPLO ENCRIPTACION COLUMNAS--
---------------------------

USE master
GO

CREATE LOGIN recepcionista1 WITH PASSWORD = 'Abcd1234.'
GO
CREATE LOGIN recepcionista2 WITH PASSWORD = 'Abcd1234.'
GO


DROP DATABASE IF EXISTS BBA_CampingP
GO
CREATE DATABASE BBA_CampingP
GO

USE BBA_CampingP
GO

--creamos usuarios en la base de datos
DROP USER IF EXISTS recepcionista1
GO
DROP USER IF EXISTS recepcionista2
GO

CREATE USER recepcionista1 FOR LOGIN recepcionista1
GO
CREATE USER recepcionista2 FOR LOGIN recepcionista2
GO

--Creamos tablay metemos algunos campos cifrados

DROP TABLE IF EXISTS Reserva
GO

CREATE TABLE Reserva
(
    id_reserva INT,
    cliente_nombre VARCHAR(50),
    recepcionista VARCHAR(30),
    documento_cliente VARBINARY(1000),   -- CIFRADO
    observaciones VARBINARY(4000)         -- CIFRADO
)
GO

SELECT * FROM Reserva
go

--permisos sobre la tabla

GRANT SELECT, INSERT ON Reserva TO recepcionista1
GRANT SELECT, INSERT ON Reserva TO recepcionista2
GO

-- creamos master key

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'CampingP_MasterKey_2026!'
GO

--comprobamos
SELECT name KeyName,
  symmetric_key_id KeyID,
  key_length KeyLength,
  algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO
/*
##MS_DatabaseMasterKey##	101	256	AES_256
recepcionista1_key	256	256	AES_256
recepcionista2_key	257	256	AES_256
*/
SELECT *
FROM sys.symmetric_keys
GO

--creamos certificados, uno por cada recepcionista

CREATE CERTIFICATE recepcionista1_cert
AUTHORIZATION recepcionista1
WITH SUBJECT = 'Certificado recepcionista 1'
GO

CREATE CERTIFICATE recepcionista2_cert
AUTHORIZATION recepcionista2
WITH SUBJECT = 'Certificado recepcionista 2'
GO


SELECT name CertName,
  certificate_id CertID,
  pvt_key_encryption_type_desc EncryptType,
  issuer_name Issuer
FROM sys.certificates;
GO


--creamos claves simétricas

CREATE SYMMETRIC KEY recepcionista1_key
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE recepcionista1_cert
GO

CREATE SYMMETRIC KEY recepcionista2_key
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE recepcionista2_cert
GO
--comprobamos
SELECT name KeyName,
  symmetric_key_id KeyID,
  key_length KeyLength,
  algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO


--permisos sobre certificados y claves

GRANT VIEW DEFINITION ON CERTIFICATE::recepcionista1_cert TO recepcionista1
GRANT VIEW DEFINITION ON SYMMETRIC KEY::recepcionista1_key TO recepcionista1
GO

GRANT VIEW DEFINITION ON CERTIFICATE::recepcionista2_cert TO recepcionista2
GRANT VIEW DEFINITION ON SYMMETRIC KEY::recepcionista2_key TO recepcionista2
GO
--insertación como recepcionista 1

EXECUTE AS USER = 'recepcionista1'
GO

OPEN SYMMETRIC KEY recepcionista1_key
DECRYPTION BY CERTIFICATE recepcionista1_cert
GO

INSERT INTO Reserva
VALUES
(1,'Carlos López','recepcionista1',
 EncryptByKey(Key_GUID('recepcionista1_key'),'12345678A'),
 EncryptByKey(Key_GUID('recepcionista1_key'),'Cliente VIP'))
GO

CLOSE ALL SYMMETRIC KEYS
GO
REVERT
GO

--inserción recepcionista2
EXECUTE AS USER = 'recepcionista2'
GO

OPEN SYMMETRIC KEY recepcionista2_key
DECRYPTION BY CERTIFICATE recepcionista2_cert
GO

INSERT INTO Reserva
VALUES
(2,'Ana Martín','recepcionista2',
 EncryptByKey(Key_GUID('recepcionista2_key'),'87654321B'),
 EncryptByKey(Key_GUID('recepcionista2_key'),'Mascota permitida'))
GO

CLOSE ALL SYMMETRIC KEYS
GO
REVERT
GO


	--ver los datos que están cifrados

	SELECT id_reserva, cliente_nombre, recepcionista, documento_cliente, observaciones
	FROM Reserva
	GO

--cada recepcionista solo ve sus datos

EXECUTE AS USER = 'recepcionista1'
GO

OPEN SYMMETRIC KEY recepcionista1_key
DECRYPTION BY CERTIFICATE recepcionista1_cert
GO

SELECT id_reserva, cliente_nombre,
       CONVERT(VARCHAR, DecryptByKey(documento_cliente)) AS Documento,
       CONVERT(VARCHAR, DecryptByKey(observaciones)) AS Observaciones
FROM Reserva
GO

CLOSE ALL SYMMETRIC KEYS
GO
REVERT
GO


EXECUTE AS USER = 'recepcionista2'
GO

OPEN SYMMETRIC KEY recepcionista2_key
DECRYPTION BY CERTIFICATE recepcionista2_cert
GO

SELECT id_reserva, cliente_nombre,
       CONVERT(VARCHAR, DecryptByKey(documento_cliente)) AS Documento,
       CONVERT(VARCHAR, DecryptByKey(observaciones)) AS Observaciones
FROM Reserva
GO

CLOSE ALL SYMMETRIC KEYS
GO
REVERT
GO


------
--ENCRIPTACION USANDO PARAFRASE
-------------------


USE [BBA_Camping]
GO 

SELECT * FROM empleado
GO

--creo la columna varbinary para guardar la tarjeta cifrada
IF COL_LENGTH('empleado', 'tarjeta_credito_enc') IS NULL
BEGIN
    ALTER TABLE empleado
    ADD tarjeta_credito_enc VARBINARY(256);
END
GO

SELECT * FROM empleado
GO
--declaro variable y la frase de encriptación

DECLARE @MiFraseSecreta NVARCHAR(128);  
SET @MiFraseSecreta = 'Tengo que aprobar Bases de datos para sacar la FP';  

--Asigno numeros de tajeta y los cifrarlos con la frase

UPDATE empleado
SET tarjeta_credito_enc = EncryptByPassPhrase(
    @MiFraseSecreta,
    CONVERT(NVARCHAR(20), '4539148803436467'), 
    1,
    CONVERT(VARBINARY, id_empleado)
)
WHERE id_empleado = 'E001';

UPDATE empleado
SET tarjeta_credito_enc = EncryptByPassPhrase(
    @MiFraseSecreta,
    CONVERT(NVARCHAR(20), '4916221245678901'),
    1,
    CONVERT(VARBINARY, id_empleado)
)
WHERE id_empleado = 'E002';

SELECT * FROM empleado
GO
--DESENCRIPTANDO

DECLARE @MiFraseSecreta NVARCHAR(128) =
'Tengo que aprobar Bases de datos para sacar la FP';

SELECT
    id_empleado,
    CONVERT(
        NVARCHAR(20),
        DecryptByPassPhrase(
           @MiFraseSecreta,
            tarjeta_credito_enc,
            1,
            CONVERT(VARBINARY, id_empleado)
        )
    ) AS tarjeta_desencriptada
FROM empleado;



---------------
--BACKUP ENCRIPTADO

---------------------


CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

USE master
GO
 

  --crear un certificado de backup
  CREATE CERTIFICATE BBACampingCertificadoBackup
WITH SUBJECT = 'Certificado BBA_CampingP Encriptado';
GO


--hacemos copia del certificado como aconseja Microsoft

BACKUP CERTIFICATE [BBACampingCertificadoBackup]
  TO FILE = 'C:\Backup\Certificados\BBACampingCertificadoBackup.cert'
  WITH PRIVATE KEY (
                     FILE = 'C:\Backup\Certificados\BBACampingCertificadoBackup.key'
                     ,ENCRYPTION BY PASSWORD = 'Abcd1234.'
                   );
GO

-- BACKUP COMPLETO DE LA BD

BACKUP DATABASE [BBA_CampingP]
  TO DISK = 'C:\Backup\BBA_CampingP-with-encryption.bak'
  WITH COMPRESSION, ENCRYPTION(ALGORITHM = AES_256, 
  SERVER CERTIFICATE = [BBACampingCertificadoBackup]);
GO


---EN OTRO EQUIPO PARA RESTURAR EL BACKUP ENCRIIPTADO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

USE master
GO

CREATE CERTIFICATE BBACampingCertificadoBackup
FROM FILE = 'C:\Certificados\BBACampingCertificadoBackup.cert'
WITH PRIVATE KEY
(
FILE = 'C:\Certificados\BBACampingCertificadoBackup.key',
DECRYPTION BY PASSWORD = 'Abcd1234.'
);
GO

-- 
RESTORE DATABASE BBA_CampingP
FROM DISK = 'C:\Backup\BBA_CampingP-with-encryption.bak'
go




--------------
--ENCRIPTAR TDE
---------------

USE [master];
GO 

--Puedo activar las opciones avanzadas para usar por ejemplo cmdshell para crear el directorio sino lo tengo crado


--para activarlas con el 1

EXECUTE sp_configure 'show advanced options', 1;  
GO  
-- para cambiar al servidor sin tener que reiniciar
.  
RECONFIGURE;  
GO  
-- habilitamos el procedimiento extendido de cmdshell 
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO

-- PRIMERA OPCIÓN PARA CREAR DIRECTORIO
exec xp_create_subdir 'C:\CERTIFICADOS'
GO

-- SEGUNDA OPCIÓN PARA CREAR DIRECTORIO
-- BORRAR SI EXISTE
EXEC xp_cmdshell 'rmdir C:\CERTIFICADOS'
go
-- CREAR
EXEC xp_cmdshell 'mkdir C:\CERTIFICADOS'
go


--creamos la master key para encriptar el certificado

CREATE MASTER KEY
	ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

--Creamos el certificado que va a usarse con TDE
CREATE CERTIFICATE CertTDE
	WITH SUBJECT = 'Certificado para encriptar TDE';
GO

-- 2 Formas de ver los certificados, uno desde SSMS y otro con el siguiente script

SELECT TOP 1 *
FROM sys.certificates
ORDER BY name DESC
GO

--Como recomienda siempre Microsoft realizamos un backup de la clave privada y del Certificado
BACKUP CERTIFICATE CertTDE
	TO FILE ='C:\CERTIFICADOS\CertTDE.cer'
	WITH PRIVATE KEY (
		FILE = 'C:\CERTIFICADOS\CertTDE_key.pvk',
	ENCRYPTION BY PASSWORD = 'Abcd1234.'
	);
GO

--ver carpeta CERTIFICADOS
EXEC xp_cmdshell 'DIR C:\CERTIFICADOS'
GO


USE BBA_CampingP
GO

--Creamos la Database Encryption Key (DEK) para activar la encriptación (Turn on)

CREATE DATABASE ENCRYPTION KEY
	WITH ALGORITHM = AES_256
	ENCRYPTION BY SERVER CERTIFICATE CertTDE;
GO


SELECT *
FROM sys.dm_database_encryption_keys
GO
--database_id	encryption_state	create_date	regenerate_date	modify_date	set_date	opened_date	key_algorithm	key_length	encryptor_thumbprint	encryptor_type	percent_complete	encryption_state_desc	encryption_scan_state	encryption_scan_state_desc	encryption_scan_modify_date
--13	1	2026-02-22 21:16:25.627	2026-02-22 21:16:25.627	2026-02-22 21:16:25.627	1900-01-01 00:00:00.000	2026-02-22 21:16:25.627	AES	256	0x6B88ABBD771699679AD4647EA3805A78B4A24343	CERTIFICATE	0	UNENCRYPTED	0	NONE	1900-01-01 00:00:00.000

USE master
GO

--Activo TDE desde Transact SQL o SSMS

ALTER DATABASE [BBA_CampingP] SET ENCRYPTION ON;
GO

--Chequeamos el estado de la encriptación con la siguiente query

SELECT DB_Name(database_id) AS 'Database', encryption_state 
FROM sys.dm_database_encryption_keys;
GO

--Hago Backup Completo de la Base de Datos

BACKUP DATABASE [BBA_CampingP]
TO DISK = 'C:\CERTIFICADOS\BBA_CampingP_Full.bak';
GO 
+--me da error
/*Msg 927, Level 14, State 2, Line 617
Database 'BBA_CampingP' cannot be opened. It is in the middle of a restore.
Msg 3013, Level 16, State 1, Line 617
BACKUP DATABASE is terminating abnormally.

Completion time: 2026-02-25T19:48:55.8692790+01:00
*/
--compruebo el estado de la base de datos

SELECT name, state_desc
FROM sys.databases
WHERE name = 'BBA_CampingP';

--cerramos la cadena de resotres
RESTORE DATABASE BBA_CampingP WITH RECOVERY;


--volvemos a intentar backup
BACKUP DATABASE [BBA_CampingP]
TO DISK = 'C:\CERTIFICADOS\BBA_CampingP_Full.bak';
GO 
--Hacemos backup de LOG

BACKUP LOG [BBA_CampingP]
TO DISK = 'C:\CERTIFICADOS\BBA_CampingP_log.bak'
With NORECOVERY
GO


-- Ver Carpeta C:\CERTIFICADOS
EXEC xp_cmdshell 'DIR C:\CERTIFICADOS'
GO

- SI INTENTO RESTAURA EN OTRO SERVIDO Y NO TENGO EL CERTIFICADA.

RESTORE DATABASE [BBA_CampingP]
  FROM DISK = 'C:\CERTIFICADOS\BBA_CampingP_Full.bak'
  WITH MOVE 'BBA_CampingP' TO 'C:\data\BBA_CampingP_2ndServer.mdf',
       MOVE 'BBA_CampingP_log' TO 'C:\data\BBA_CampingP_2ndServer_log.mdf';
GO

--Msg 33111, Level 16, State 3, Line 130
--Cannot find server certificate with thumbprint '0x192834B1A8B932393B9101D24B8F759A49BB1397'.
--Msg 3013, Level 16, State 1, Line 130
--RESTORE DATABASE is terminating abnormally.

-- sI ESTAMOS EN OTRO SERVIDOR PERO TENEMOS EL CERIFICADO

-- SI FUERA NECESARIO CREAMOS MASTER KEY EN EL SEGUNDO EQUIPO
-- PUEDE TENER UNA PASSWORD DIFERENTE

CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'SecondServerPassw0rd!';
GO 

-- RESTAURAMOS EL CERTIFICADO Y LA CLAVE


CREATE CERTIFICATE TDECert
  FROM FILE = 'C:\CERTIFICADOS\CertTDE.cer'
  WITH PRIVATE KEY ( 
    FILE = 'C:\CERTIFICADOS\CertTDE_key.pvk',
 DECRYPTION BY PASSWORD = 'Abcd1234.'
  );
GO


RESTORE DATABASE [BBA_CampingP]
  FROM DISK = 'C:\CERTIFICADOS\BBA_CampingP_Full.bak'
  WITH MOVE 'BBA_CampingP' TO 'C:\data\BBA_CampingP_2ndServer.mdf',
       MOVE 'BBA_CampingP_log' TO 'C:\data\BBA_CampingP_2ndServer_log.mdf';
GO


-----------
--ALWAYS ENCRIPTED
------------

	--USAMOS EL ASISTENTE DE SSMS EN BOTON DERECHO EN BD- TASK - ENCRYPTCOLUMS

	
	SELECT * FROM [dbo].[Factura]
	GO