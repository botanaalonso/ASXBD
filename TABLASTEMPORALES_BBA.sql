-- Temporal Tables




USE [BBA_Camping]
GO
DROP TABLE IF EXISTS reservas
GO
-- si quiero borrarla da error
--Msg 13552, Level 16, State 1, Line 8
--Drop table operation failed on table 'BBA_Camping.dbo.reservas' because it is not a supported operation on system-versioned temporal tables.

--usar
ALTER TABLE reservas
SET (SYSTEM_VERSIONING = OFF);
GO

DROP TABLE IF EXISTS reservas;
GO

create table reservas
	(   parcela varchar(20) Primary Key Clustered,  
		dias_reserva integer,  
	SysStartTime datetime2 generated always as row start not null,  
	SysEndTime datetime2 generated always as row end not null,  
	period for System_time (SysStartTime,SysEndTime) ) 
	with (System_Versioning = ON (History_Table = dbo.reservas_historico)
	) 
go
SELECT * FROM [dbo].[reservas]
GO
SELECT * FROM [dbo].[reservas_historico]
GO

insert into reservas (parcela,dias_reserva) 
values ('parcela1',2), 
	('parcela2',3), 
	('parcela3',5), 
	('parcela4',2), 
	('parcela5',8) 
GO 

ºPRINT GETUTCDATE()
GO

SELECT * FROM [dbo].[reservas]
GO


SELECT * FROM [dbo].[reservas_historico]
GO

--actualizamos un registro, dias de reserva de parcela 1 y vemos el cambio

update [dbo].[reservas]
	set dias_reserva = 4
	where parcela = 'parcela1'
GO

SELECT * FROM [dbo].[reservas]
GO

SELECT * FROM [dbo].[reservas_historico]
GO

--Hacemos mas cambios

update [dbo].[reservas]
	set dias_reserva = 8
	where parcela = 'parcela2'
GO


update [dbo].[reservas]
	set dias_reserva = 10
	where parcela = 'parcela2'
GO

SELECT * FROM [dbo].[reservas]
GO

SELECT * FROM [dbo].[reservas_historico]
GO

-- eliminamos una de las parcelas porque se han ido o está en obras

delete from reservas
	where parcela='parcela1'
GO

SELECT * FROM [dbo].[reservas]
GO

SELECT * FROM [dbo].[reservas_historico]
GO



SELECT * FROM [dbo].[reservas]
FOR system_time ALL
GO


--AS OF para ver el estado de la tabla en un momento determinado en el tiempo

SELECT *
FROM dbo.reservas
FOR SYSTEM_TIME AS OF '2026-02-13 22:49:03.4634173'
ORDER BY dias_reserva
GO

--FROM para ver el estado en un perdiodo de tiempo específico

SELECT *
FROM dbo.reservas
FOR SYSTEM_TIME BETWEEN 
GO

--BETWEEN  Devuelve todas las filas cuya versión estuvo vigente en algún momento entre las dos fechas. 

select * 
from dbo.reservas
for system_time between '2026-02-13 00:00:00' AND '2026-02-13 22:50:59';
--order by SysStartTime
GO

--CONTAINED IN  Selecciona los registros que estuvieron activos COMPLETAMENTE dentro del periodo especificado, es decir, que al inicio del periodo estaban y que al final del mismo también. 
SELECT * FROM reservas
FOR system_time CONTAINED IN ('2026-02-13','2026-02-14')
GO




