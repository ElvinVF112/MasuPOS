USE [msdb];
GO

/*
  Crea o reemplaza un SQL Server Agent Job para respaldar la base DbMasuPOS.

  Ajusta estas variables antes de ejecutarlo si hace falta:
  - @BackupDirectory: carpeta donde SQL Server escribira los .bak
  - @RetentionDays: cantidad de dias a conservar
  - @ScheduleName: nombre del horario
  - @StartTime: hora inicial en formato HHMMSS para el ciclo de 6 horas

  Requisitos:
  - SQL Server Agent debe estar iniciado
  - La cuenta del servicio de SQL Server debe tener permisos sobre @BackupDirectory
*/

DECLARE @JobName SYSNAME = N'BACKUP - DbMasuPOS - Cada 6 Horas';
DECLARE @ScheduleName SYSNAME = N'BACKUP - DbMasuPOS - Cada 6 Horas';
DECLARE @BackupDirectory NVARCHAR(260) = N'D:\Backups\DbMasuPOS';
DECLARE @DatabaseName SYSNAME = N'DbMasuPOS';
DECLARE @RetentionDays INT = 3;
DECLARE @StartTime INT = 000000;
DECLARE @OwnerLogin SYSNAME = SUSER_SNAME();

DECLARE @JobId UNIQUEIDENTIFIER;
DECLARE @Command NVARCHAR(MAX);
DECLARE @CleanupCommand NVARCHAR(MAX);
DECLARE @DirectoryExists TABLE (
    [File Exists] INT,
    [File is a Directory] INT,
    [Parent Directory Exists] INT
);

IF DB_ID(@DatabaseName) IS NULL
BEGIN
    RAISERROR(N'La base de datos %s no existe en esta instancia.', 16, 1, @DatabaseName);
    RETURN;
END;

INSERT INTO @DirectoryExists
EXEC master.dbo.xp_fileexist @BackupDirectory;

IF NOT EXISTS (
    SELECT 1
    FROM @DirectoryExists
    WHERE [File is a Directory] = 1
)
BEGIN
    EXEC master.dbo.xp_create_subdir @BackupDirectory;
END;

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.syscategories
    WHERE name = N'Database Maintenance'
      AND category_class = 1
)
BEGIN
    EXEC msdb.dbo.sp_add_category
        @class = N'JOB',
        @type = N'LOCAL',
        @name = N'Database Maintenance';
END;

IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs
    WHERE name = @JobName
)
BEGIN
    EXEC msdb.dbo.sp_delete_job
        @job_name = @JobName;
END;

EXEC msdb.dbo.sp_add_job
    @job_name = @JobName,
    @enabled = 1,
    @description = N'Respaldo FULL de DbMasuPOS cada 6 horas con nombre de archivo por fecha y hora y limpieza automatica de backups con mas de 3 dias.',
    @category_name = N'Database Maintenance',
    @owner_login_name = @OwnerLogin,
    @job_id = @JobId OUTPUT;

SET @Command = N'
DECLARE @BackupDirectory NVARCHAR(260) = N''' + REPLACE(@BackupDirectory, '''', '''''') + N''';
DECLARE @DatabaseName SYSNAME = N''' + REPLACE(@DatabaseName, '''', '''''') + N''';
DECLARE @FileName NVARCHAR(400);

SET @FileName =
    @BackupDirectory + N''\''
    + @DatabaseName + N''_''
    + CONVERT(VARCHAR(8), GETDATE(), 112) + N''_''
    + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), '':'', '''')
    + N''.bak'';

BACKUP DATABASE [DbMasuPOS]
TO DISK = @FileName
WITH
    INIT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;
';

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Backup FULL DbMasuPOS',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = @Command,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 1,
    @retry_interval = 5;

SET @CleanupCommand = N'
DECLARE @BackupDirectory NVARCHAR(260) = N''' + REPLACE(@BackupDirectory, '''', '''''') + N''';
DECLARE @CutoffDate DATETIME = DATEADD(DAY, -' + CAST(@RetentionDays AS NVARCHAR(10)) + N', GETDATE());

EXEC master.dbo.xp_delete_file
    0,
    @BackupDirectory,
    N''bak'',
    @CutoffDate,
    1;
';

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Limpiar backups anteriores a 3 dias',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = @CleanupCommand,
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 1,
    @retry_interval = 5;

IF EXISTS (
    SELECT 1
    FROM msdb.dbo.sysschedules
    WHERE name = @ScheduleName
)
BEGIN
    EXEC msdb.dbo.sp_delete_schedule
        @schedule_name = @ScheduleName;
END;

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = @ScheduleName,
    @enabled = 1,
    @freq_type = 4,               -- diario
    @freq_interval = 1,           -- cada 1 dia
    @freq_subday_type = 8,        -- horas
    @freq_subday_interval = 6,    -- cada 6 horas
    @active_start_time = @StartTime,
    @active_end_time = 235959;

EXEC msdb.dbo.sp_attach_schedule
    @job_id = @JobId,
    @schedule_name = @ScheduleName;

EXEC msdb.dbo.sp_add_jobserver
    @job_id = @JobId,
    @server_name = N'(LOCAL)';

PRINT N'Job creado correctamente: ' + @JobName;
PRINT N'Horario creado correctamente: ' + @ScheduleName;
PRINT N'Carpeta de backup configurada: ' + @BackupDirectory;
PRINT N'Dias de retencion configurados: ' + CAST(@RetentionDays AS NVARCHAR(10));
