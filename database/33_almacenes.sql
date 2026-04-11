-- TAREA 33 — Almacenes: tabla + SP + permisos
-- Ejecutar en DbMasuPOS

-- ══════════════════════════════════════════════════════════════
-- 1. TABLA
-- ══════════════════════════════════════════════════════════════

IF OBJECT_ID('dbo.Almacenes','U') IS NULL
BEGIN
    CREATE TABLE dbo.Almacenes (
        IdAlmacen           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Descripcion         NVARCHAR(100)     NOT NULL,
        Siglas              NVARCHAR(20)      NOT NULL,
        TipoAlmacen         CHAR(1)           NOT NULL DEFAULT 'O'
            CONSTRAINT CK_Almacenes_Tipo CHECK (TipoAlmacen IN ('C','V','T','N','O')),
        -- C=Central  V=Venta  T=Transito  N=Consignacion  O=Otro
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
-- 2. STORED PROCEDURE
-- ══════════════════════════════════════════════════════════════

CREATE OR ALTER PROCEDURE dbo.spAlmacenesCRUD
    @Accion              CHAR(1),
    @IdAlmacen           INT           = NULL,
    @Descripcion         NVARCHAR(100) = NULL,
    @Siglas              NVARCHAR(20)  = NULL,
    @TipoAlmacen         CHAR(1)       = NULL,
    @Activo              BIT           = NULL,
    @UsuarioCreacion     INT           = NULL,
    @UsuarioModificacion INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT IdAlmacen, Descripcion, Siglas, TipoAlmacen, Activo
        FROM dbo.Almacenes
        WHERE ISNULL(RowStatus,1)=1
        ORDER BY Descripcion;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT IdAlmacen, Descripcion, Siglas, TipoAlmacen, Activo
        FROM dbo.Almacenes
        WHERE IdAlmacen=@IdAlmacen;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.Almacenes WHERE Siglas=LTRIM(RTRIM(@Siglas)) AND ISNULL(RowStatus,1)=1)
        BEGIN
            RAISERROR('Ya existe un almacen con esas siglas.', 16, 1);
            RETURN;
        END;
        INSERT INTO dbo.Almacenes (Descripcion, Siglas, TipoAlmacen, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (LTRIM(RTRIM(@Descripcion)), LTRIM(RTRIM(@Siglas)),
                ISNULL(@TipoAlmacen,'O'), ISNULL(@Activo,1), 1, GETDATE(), @UsuarioCreacion);
        DECLARE @NuevoId INT = SCOPE_IDENTITY();
        EXEC dbo.spAlmacenesCRUD @Accion='O', @IdAlmacen=@NuevoId;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Almacenes
        SET Descripcion=LTRIM(RTRIM(@Descripcion)), Siglas=LTRIM(RTRIM(@Siglas)),
            TipoAlmacen=ISNULL(@TipoAlmacen,TipoAlmacen),
            Activo=ISNULL(@Activo,Activo), FechaModificacion=GETDATE(),
            UsuarioModificacion=@UsuarioModificacion
        WHERE IdAlmacen=@IdAlmacen AND ISNULL(RowStatus,1)=1;
        EXEC dbo.spAlmacenesCRUD @Accion='O', @IdAlmacen=@IdAlmacen;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Almacenes
        SET RowStatus=0, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion
        WHERE IdAlmacen=@IdAlmacen;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 3. PERMISOS
-- ══════════════════════════════════════════════════════════════

DECLARE @IdModulo INT = (SELECT TOP 1 IdModulo FROM dbo.Modulos WHERE Nombre='Configuracion' AND ISNULL(Activo,1)=1);
DECLARE @IdRolAdmin INT = 1;

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta='/config/company/warehouses' AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Pantallas (IdModulo,Nombre,Ruta,Controlador,Accion,Icono,Orden,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdModulo,'Almacenes','/config/company/warehouses','Company','Warehouses','warehouse',13,1,1,GETDATE(),1);

DECLARE @PantAlm INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta='/config/company/warehouses' AND ISNULL(RowStatus,1)=1);
IF @PantAlm IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla=@PantAlm AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.Permisos (IdPantalla,Nombre,Descripcion,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@PantAlm,'Ver Almacenes','Acceder a la pantalla de almacenes',1,1,GETDATE(),1);

DECLARE @PermAlm INT = (SELECT TOP 1 IdPermiso FROM dbo.Permisos WHERE IdPantalla=@PantAlm AND ISNULL(RowStatus,1)=1);
IF @PermAlm IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol=@IdRolAdmin AND IdPermiso=@PermAlm AND ISNULL(RowStatus,1)=1)
    INSERT INTO dbo.RolesPermisos (IdRol,IdPermiso,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
    VALUES (@IdRolAdmin,@PermAlm,1,1,GETDATE(),1);
GO

PRINT 'TAREA 33 ejecutada: Almacenes listo.';
