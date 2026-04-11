-- TAREA 32 — Estructura Organizacional: Divisiones, Sucursales, PuntosEmision
-- Ejecutar en DbMasuPOS

-- ══════════════════════════════════════════════════════════════
-- 1. TABLAS
-- ══════════════════════════════════════════════════════════════

IF OBJECT_ID('dbo.Divisiones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Divisiones (
        IdDivision          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Nombre              NVARCHAR(100)     NOT NULL,
        Descripcion         NVARCHAR(255)     NULL,
        Activo              BIT               NOT NULL DEFAULT 1,
        RowStatus           BIT               NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME          NOT NULL DEFAULT GETDATE(),
        UsuarioCreacion     INT               NULL,
        FechaModificacion   DATETIME          NULL,
        UsuarioModificacion INT               NULL
    );
END;
GO

IF OBJECT_ID('dbo.Sucursales', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Sucursales (
        IdSucursal          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        IdDivision          INT               NOT NULL REFERENCES dbo.Divisiones(IdDivision),
        Nombre              NVARCHAR(100)     NOT NULL,
        Descripcion         NVARCHAR(255)     NULL,
        Direccion           NVARCHAR(255)     NULL,
        Activo              BIT               NOT NULL DEFAULT 1,
        RowStatus           BIT               NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME          NOT NULL DEFAULT GETDATE(),
        UsuarioCreacion     INT               NULL,
        FechaModificacion   DATETIME          NULL,
        UsuarioModificacion INT               NULL
    );
END;
GO

IF OBJECT_ID('dbo.PuntosEmision', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PuntosEmision (
        IdPuntoEmision      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        IdSucursal          INT               NOT NULL REFERENCES dbo.Sucursales(IdSucursal),
        Nombre              NVARCHAR(100)     NOT NULL,
        Codigo              NVARCHAR(20)      NULL,
        Activo              BIT               NOT NULL DEFAULT 1,
        RowStatus           BIT               NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME          NOT NULL DEFAULT GETDATE(),
        UsuarioCreacion     INT               NULL,
        FechaModificacion   DATETIME          NULL,
        UsuarioModificacion INT               NULL
    );
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 2. STORED PROCEDURES
-- ══════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE dbo.spDivisionesCRUD
    @Accion              CHAR(1),
    @IdDivision          INT           = NULL,
    @Nombre              NVARCHAR(100) = NULL,
    @Descripcion         NVARCHAR(255) = NULL,
    @Activo              BIT           = NULL,
    @UsuarioCreacion     INT           = NULL,
    @UsuarioModificacion INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT IdDivision, Nombre, ISNULL(Descripcion,'') AS Descripcion, Activo
        FROM dbo.Divisiones
        WHERE ISNULL(RowStatus,1) = 1
        ORDER BY Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT IdDivision, Nombre, ISNULL(Descripcion,'') AS Descripcion, Activo
        FROM dbo.Divisiones
        WHERE IdDivision = @IdDivision;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.Divisiones WHERE Nombre = LTRIM(RTRIM(@Nombre)) AND ISNULL(RowStatus,1)=1)
        BEGIN
            RAISERROR('Ya existe una division con ese nombre.', 16, 1);
            RETURN;
        END;
        INSERT INTO dbo.Divisiones (Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (LTRIM(RTRIM(@Nombre)), @Descripcion, ISNULL(@Activo,1), 1, GETDATE(), @UsuarioCreacion);
        DECLARE @NuevoIdD INT = SCOPE_IDENTITY();
        EXEC dbo.spDivisionesCRUD @Accion='O', @IdDivision=@NuevoIdD;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Divisiones
        SET Nombre=LTRIM(RTRIM(@Nombre)), Descripcion=@Descripcion,
            Activo=ISNULL(@Activo,Activo), FechaModificacion=GETDATE(),
            UsuarioModificacion=@UsuarioModificacion
        WHERE IdDivision=@IdDivision AND ISNULL(RowStatus,1)=1;
        EXEC dbo.spDivisionesCRUD @Accion='O', @IdDivision=@IdDivision;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Divisiones
        SET RowStatus=0, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion
        WHERE IdDivision=@IdDivision;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spSucursalesCRUD
    @Accion              CHAR(1),
    @IdSucursal          INT           = NULL,
    @IdDivision          INT           = NULL,
    @Nombre              NVARCHAR(100) = NULL,
    @Descripcion         NVARCHAR(255) = NULL,
    @Direccion           NVARCHAR(255) = NULL,
    @Activo              BIT           = NULL,
    @UsuarioCreacion     INT           = NULL,
    @UsuarioModificacion INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT S.IdSucursal, S.IdDivision, D.Nombre AS NombreDivision,
               S.Nombre, ISNULL(S.Descripcion,'') AS Descripcion,
               ISNULL(S.Direccion,'') AS Direccion, S.Activo
        FROM dbo.Sucursales S
        INNER JOIN dbo.Divisiones D ON D.IdDivision=S.IdDivision AND ISNULL(D.RowStatus,1)=1
        WHERE ISNULL(S.RowStatus,1)=1
          AND (@IdDivision IS NULL OR S.IdDivision=@IdDivision)
        ORDER BY D.Nombre, S.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT S.IdSucursal, S.IdDivision, D.Nombre AS NombreDivision,
               S.Nombre, ISNULL(S.Descripcion,'') AS Descripcion,
               ISNULL(S.Direccion,'') AS Direccion, S.Activo
        FROM dbo.Sucursales S
        INNER JOIN dbo.Divisiones D ON D.IdDivision=S.IdDivision
        WHERE S.IdSucursal=@IdSucursal;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Divisiones WHERE IdDivision=@IdDivision AND ISNULL(RowStatus,1)=1)
        BEGIN
            RAISERROR('La division no existe o esta inactiva.', 16, 1);
            RETURN;
        END;
        INSERT INTO dbo.Sucursales (IdDivision, Nombre, Descripcion, Direccion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdDivision, LTRIM(RTRIM(@Nombre)), @Descripcion, @Direccion, ISNULL(@Activo,1), 1, GETDATE(), @UsuarioCreacion);
        DECLARE @NuevoIdS INT = SCOPE_IDENTITY();
        EXEC dbo.spSucursalesCRUD @Accion='O', @IdSucursal=@NuevoIdS;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Sucursales
        SET IdDivision=ISNULL(@IdDivision,IdDivision), Nombre=LTRIM(RTRIM(@Nombre)),
            Descripcion=@Descripcion, Direccion=@Direccion,
            Activo=ISNULL(@Activo,Activo), FechaModificacion=GETDATE(),
            UsuarioModificacion=@UsuarioModificacion
        WHERE IdSucursal=@IdSucursal AND ISNULL(RowStatus,1)=1;
        EXEC dbo.spSucursalesCRUD @Accion='O', @IdSucursal=@IdSucursal;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Sucursales
        SET RowStatus=0, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion
        WHERE IdSucursal=@IdSucursal;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spPuntosEmisionCRUD
    @Accion              CHAR(1),
    @IdPuntoEmision      INT           = NULL,
    @IdSucursal          INT           = NULL,
    @Nombre              NVARCHAR(100) = NULL,
    @Codigo              NVARCHAR(20)  = NULL,
    @Activo              BIT           = NULL,
    @UsuarioCreacion     INT           = NULL,
    @UsuarioModificacion INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT PE.IdPuntoEmision, PE.IdSucursal, S.Nombre AS NombreSucursal,
               S.IdDivision, D.Nombre AS NombreDivision,
               PE.Nombre, ISNULL(PE.Codigo,'') AS Codigo, PE.Activo
        FROM dbo.PuntosEmision PE
        INNER JOIN dbo.Sucursales S ON S.IdSucursal=PE.IdSucursal AND ISNULL(S.RowStatus,1)=1
        INNER JOIN dbo.Divisiones D ON D.IdDivision=S.IdDivision AND ISNULL(D.RowStatus,1)=1
        WHERE ISNULL(PE.RowStatus,1)=1
          AND (@IdSucursal IS NULL OR PE.IdSucursal=@IdSucursal)
        ORDER BY D.Nombre, S.Nombre, PE.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT PE.IdPuntoEmision, PE.IdSucursal, S.Nombre AS NombreSucursal,
               S.IdDivision, D.Nombre AS NombreDivision,
               PE.Nombre, ISNULL(PE.Codigo,'') AS Codigo, PE.Activo
        FROM dbo.PuntosEmision PE
        INNER JOIN dbo.Sucursales S ON S.IdSucursal=PE.IdSucursal
        INNER JOIN dbo.Divisiones D ON D.IdDivision=S.IdDivision
        WHERE PE.IdPuntoEmision=@IdPuntoEmision;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Sucursales WHERE IdSucursal=@IdSucursal AND ISNULL(RowStatus,1)=1)
        BEGIN
            RAISERROR('La sucursal no existe o esta inactiva.', 16, 1);
            RETURN;
        END;
        INSERT INTO dbo.PuntosEmision (IdSucursal, Nombre, Codigo, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdSucursal, LTRIM(RTRIM(@Nombre)), LTRIM(RTRIM(ISNULL(@Codigo,''))), ISNULL(@Activo,1), 1, GETDATE(), @UsuarioCreacion);
        DECLARE @NuevoIdP INT = SCOPE_IDENTITY();
        EXEC dbo.spPuntosEmisionCRUD @Accion='O', @IdPuntoEmision=@NuevoIdP;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.PuntosEmision
        SET IdSucursal=ISNULL(@IdSucursal,IdSucursal), Nombre=LTRIM(RTRIM(@Nombre)),
            Codigo=LTRIM(RTRIM(ISNULL(@Codigo,''))),
            Activo=ISNULL(@Activo,Activo), FechaModificacion=GETDATE(),
            UsuarioModificacion=@UsuarioModificacion
        WHERE IdPuntoEmision=@IdPuntoEmision AND ISNULL(RowStatus,1)=1;
        EXEC dbo.spPuntosEmisionCRUD @Accion='O', @IdPuntoEmision=@IdPuntoEmision;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.PuntosEmision
        SET RowStatus=0, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion
        WHERE IdPuntoEmision=@IdPuntoEmision;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 3. PERMISOS (Pantallas + Permisos + RolesPermisos para admin)
-- ══════════════════════════════════════════════════════════════

DECLARE @IdModulo INT = (SELECT TOP 1 IdModulo FROM dbo.Modulos WHERE Nombre='Configuracion' AND ISNULL(Activo,1)=1);
DECLARE @IdRolAdmin INT = 1;

-- Divisiones
IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta='/config/company/divisions' AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Pantallas (IdModulo,Nombre,Ruta,Controlador,Accion,Icono,Orden,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdModulo,'Divisiones','/config/company/divisions','Company','Divisions','layers',10,1,1,GETDATE(),1);

DECLARE @PantDiv INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta='/config/company/divisions' AND ISNULL(RowStatus,1)=1);
IF @PantDiv IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla=@PantDiv AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Permisos (IdPantalla,Nombre,Descripcion,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@PantDiv,'Ver Divisiones','Acceder a la pantalla de divisiones',1,1,GETDATE(),1);

DECLARE @PermDiv INT = (SELECT TOP 1 IdPermiso FROM dbo.Permisos WHERE IdPantalla=@PantDiv AND ISNULL(RowStatus,1)=1);
IF @PermDiv IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol=@IdRolAdmin AND IdPermiso=@PermDiv AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.RolesPermisos (IdRol,IdPermiso,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdRolAdmin,@PermDiv,1,1,GETDATE(),1);

-- Sucursales
IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta='/config/company/branches' AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Pantallas (IdModulo,Nombre,Ruta,Controlador,Accion,Icono,Orden,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdModulo,'Sucursales','/config/company/branches','Company','Branches','git-branch',11,1,1,GETDATE(),1);

DECLARE @PantSuc INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta='/config/company/branches' AND ISNULL(RowStatus,1)=1);
IF @PantSuc IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla=@PantSuc AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Permisos (IdPantalla,Nombre,Descripcion,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@PantSuc,'Ver Sucursales','Acceder a la pantalla de sucursales',1,1,GETDATE(),1);

DECLARE @PermSuc INT = (SELECT TOP 1 IdPermiso FROM dbo.Permisos WHERE IdPantalla=@PantSuc AND ISNULL(RowStatus,1)=1);
IF @PermSuc IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol=@IdRolAdmin AND IdPermiso=@PermSuc AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.RolesPermisos (IdRol,IdPermiso,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdRolAdmin,@PermSuc,1,1,GETDATE(),1);

-- Puntos de Emision
IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta='/config/company/emission-points' AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Pantallas (IdModulo,Nombre,Ruta,Controlador,Accion,Icono,Orden,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdModulo,'Puntos de Emision','/config/company/emission-points','Company','EmissionPoints','zap',12,1,1,GETDATE(),1);

DECLARE @PantPE INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta='/config/company/emission-points' AND ISNULL(RowStatus,1)=1);
IF @PantPE IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla=@PantPE AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Permisos (IdPantalla,Nombre,Descripcion,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@PantPE,'Ver Puntos de Emision','Acceder a la pantalla de puntos de emision',1,1,GETDATE(),1);

DECLARE @PermPE INT = (SELECT TOP 1 IdPermiso FROM dbo.Permisos WHERE IdPantalla=@PantPE AND ISNULL(RowStatus,1)=1);
IF @PermPE IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol=@IdRolAdmin AND IdPermiso=@PermPE AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.RolesPermisos (IdRol,IdPermiso,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdRolAdmin,@PermPE,1,1,GETDATE(),1);
GO

PRINT 'TAREA 32 ejecutada: Divisiones, Sucursales, PuntosEmision listos.';
