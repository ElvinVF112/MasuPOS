SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.PuntosEmision', 'IdFacTipoDocumentoPOSPredeterminado') IS NULL
BEGIN
    ALTER TABLE dbo.PuntosEmision
    ADD IdFacTipoDocumentoPOSPredeterminado INT NULL;
END
GO

IF COL_LENGTH('dbo.PuntosEmision', 'IdClientePOSPredeterminado') IS NULL
BEGIN
    ALTER TABLE dbo.PuntosEmision
    ADD IdClientePOSPredeterminado INT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PuntosEmision_FacTipoDocumentoPOSPredeterminado'
)
AND OBJECT_ID('dbo.FacTiposDocumento', 'U') IS NOT NULL
AND COL_LENGTH('dbo.PuntosEmision', 'IdFacTipoDocumentoPOSPredeterminado') IS NOT NULL
BEGIN
    ALTER TABLE dbo.PuntosEmision
    ADD CONSTRAINT FK_PuntosEmision_FacTipoDocumentoPOSPredeterminado
    FOREIGN KEY (IdFacTipoDocumentoPOSPredeterminado)
    REFERENCES dbo.FacTiposDocumento(IdTipoDocumento);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PuntosEmision_ClientePOSPredeterminado'
)
AND OBJECT_ID('dbo.Terceros', 'U') IS NOT NULL
AND COL_LENGTH('dbo.PuntosEmision', 'IdClientePOSPredeterminado') IS NOT NULL
BEGIN
    ALTER TABLE dbo.PuntosEmision
    ADD CONSTRAINT FK_PuntosEmision_ClientePOSPredeterminado
    FOREIGN KEY (IdClientePOSPredeterminado)
    REFERENCES dbo.Terceros(IdTercero);
END
GO

IF COL_LENGTH('dbo.Usuarios', 'PuedeCambiarFechaPOS') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD PuedeCambiarFechaPOS BIT NOT NULL CONSTRAINT DF_Usuarios_PuedeCambiarFechaPOS DEFAULT (0);
END
GO

CREATE OR ALTER PROCEDURE dbo.spPuntosEmisionCRUD
    @Accion CHAR(1),
    @IdPuntoEmision INT = NULL,
    @IdSucursal INT = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Codigo NVARCHAR(20) = NULL,
    @IdListaPrecioPredeterminada INT = NULL,
    @IdFacTipoDocumentoPOSPredeterminado INT = NULL,
    @IdClientePOSPredeterminado INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            PE.IdPuntoEmision,
            PE.IdSucursal,
            S.Nombre AS NombreSucursal,
            S.IdDivision,
            D.Nombre AS NombreDivision,
            PE.Nombre,
            ISNULL(PE.Codigo, '') AS Codigo,
            PE.IdListaPrecioPredeterminada,
            LP.Descripcion AS NombreListaPrecio,
            PE.IdFacTipoDocumentoPOSPredeterminado,
            FTD.Descripcion AS NombreFacTipoDocumentoPOSPredeterminado,
            PE.IdClientePOSPredeterminado,
            T.Nombre AS NombreClientePOSPredeterminado,
            PE.Activo
        FROM dbo.PuntosEmision PE
        INNER JOIN dbo.Sucursales S ON S.IdSucursal = PE.IdSucursal AND ISNULL(S.RowStatus,1) = 1
        INNER JOIN dbo.Divisiones D ON D.IdDivision = S.IdDivision AND ISNULL(D.RowStatus,1) = 1
        LEFT JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PE.IdListaPrecioPredeterminada
        LEFT JOIN dbo.FacTiposDocumento FTD ON FTD.IdTipoDocumento = PE.IdFacTipoDocumentoPOSPredeterminado AND ISNULL(FTD.RowStatus,1) = 1
        LEFT JOIN dbo.Terceros T ON T.IdTercero = PE.IdClientePOSPredeterminado AND ISNULL(T.RowStatus,1) = 1
        WHERE ISNULL(PE.RowStatus,1) = 1
          AND (@IdSucursal IS NULL OR PE.IdSucursal = @IdSucursal)
        ORDER BY D.Nombre, S.Nombre, PE.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            PE.IdPuntoEmision,
            PE.IdSucursal,
            S.Nombre AS NombreSucursal,
            S.IdDivision,
            D.Nombre AS NombreDivision,
            PE.Nombre,
            ISNULL(PE.Codigo, '') AS Codigo,
            PE.IdListaPrecioPredeterminada,
            LP.Descripcion AS NombreListaPrecio,
            PE.IdFacTipoDocumentoPOSPredeterminado,
            FTD.Descripcion AS NombreFacTipoDocumentoPOSPredeterminado,
            PE.IdClientePOSPredeterminado,
            T.Nombre AS NombreClientePOSPredeterminado,
            PE.Activo
        FROM dbo.PuntosEmision PE
        INNER JOIN dbo.Sucursales S ON S.IdSucursal = PE.IdSucursal
        INNER JOIN dbo.Divisiones D ON D.IdDivision = S.IdDivision
        LEFT JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PE.IdListaPrecioPredeterminada
        LEFT JOIN dbo.FacTiposDocumento FTD ON FTD.IdTipoDocumento = PE.IdFacTipoDocumentoPOSPredeterminado AND ISNULL(FTD.RowStatus,1) = 1
        LEFT JOIN dbo.Terceros T ON T.IdTercero = PE.IdClientePOSPredeterminado AND ISNULL(T.RowStatus,1) = 1
        WHERE PE.IdPuntoEmision = @IdPuntoEmision;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Sucursales WHERE IdSucursal = @IdSucursal AND ISNULL(RowStatus,1) = 1)
        BEGIN
            RAISERROR('La sucursal no existe o esta inactiva.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.PuntosEmision (
            IdSucursal,
            Nombre,
            Codigo,
            IdListaPrecioPredeterminada,
            IdFacTipoDocumentoPOSPredeterminado,
            IdClientePOSPredeterminado,
            Activo,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion
        )
        VALUES (
            @IdSucursal,
            LTRIM(RTRIM(@Nombre)),
            LTRIM(RTRIM(ISNULL(@Codigo, ''))),
            @IdListaPrecioPredeterminada,
            @IdFacTipoDocumentoPOSPredeterminado,
            @IdClientePOSPredeterminado,
            ISNULL(@Activo, 1),
            1,
            GETDATE(),
            @UsuarioCreacion
        );

        DECLARE @NuevoIdP INT = SCOPE_IDENTITY();
        EXEC dbo.spPuntosEmisionCRUD @Accion = 'O', @IdPuntoEmision = @NuevoIdP;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.PuntosEmision
        SET
            IdSucursal = ISNULL(@IdSucursal, IdSucursal),
            Nombre = LTRIM(RTRIM(@Nombre)),
            Codigo = LTRIM(RTRIM(ISNULL(@Codigo, ''))),
            IdListaPrecioPredeterminada = @IdListaPrecioPredeterminada,
            IdFacTipoDocumentoPOSPredeterminado = @IdFacTipoDocumentoPOSPredeterminado,
            IdClientePOSPredeterminado = @IdClientePOSPredeterminado,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPuntoEmision = @IdPuntoEmision
          AND ISNULL(RowStatus,1) = 1;

        EXEC dbo.spPuntosEmisionCRUD @Accion = 'O', @IdPuntoEmision = @IdPuntoEmision;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.PuntosEmision
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPuntoEmision = @IdPuntoEmision;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spUsuariosCRUD
    @Accion CHAR(1),
    @IdUsuario INT = NULL OUTPUT,
    @IdRol INT = NULL,
    @IdPantallaInicio INT = NULL,
    @Nombres NVARCHAR(150) = NULL,
    @Apellidos NVARCHAR(150) = NULL,
    @NombreUsuario NVARCHAR(100) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @ClaveHash NVARCHAR(500) = NULL,
    @RequiereCambioClave BIT = NULL,
    @PuedeEliminarLineaPOS BIT = NULL,
    @PuedeCambiarFechaPOS BIT = NULL,
    @Bloqueado BIT = NULL,
    @Activo BIT = NULL,
    @TipoUsuario CHAR(1) = NULL,
    @IdEmpresa INT = NULL,
    @IdDivision INT = NULL,
    @IdSucursal INT = NULL,
    @IdPuntoEmision INT = NULL,
    @NivelAcceso CHAR(1) = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @TipoUsuario = UPPER(LTRIM(RTRIM(ISNULL(@TipoUsuario, 'O'))));
    SET @NivelAcceso = UPPER(LTRIM(RTRIM(ISNULL(@NivelAcceso, 'G'))));

    IF @Accion IN ('I', 'A') AND @TipoUsuario NOT IN ('A', 'S', 'O')
    BEGIN
        RAISERROR('Debe indicar @TipoUsuario valido: A, S u O.', 16, 1);
        RETURN;
    END;

    IF @Accion IN ('I', 'A') AND @NivelAcceso NOT IN ('G', 'E', 'D', 'S', 'P', 'U')
    BEGIN
        RAISERROR('Debe indicar @NivelAcceso valido: G, E, D, S, P o U.', 16, 1);
        RETURN;
    END;

    IF @Accion = 'L'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.TipoUsuario,
            U.IdPantallaInicio,
            ISNULL(P.Nombre, '') AS PantallaInicio,
            ISNULL(P.Ruta, '/') AS RutaInicio,
            R.Nombre AS Rol,
            U.Nombres,
            U.Apellidos,
            U.NombreUsuario,
            U.Correo,
            U.RequiereCambioClave,
            U.PuedeEliminarLineaPOS,
            U.PuedeCambiarFechaPOS,
            U.Bloqueado,
            U.Activo,
            U.IdEmpresa,
            E.RazonSocial AS EmpresaNombre,
            U.IdDivision,
            D.Nombre AS DivisionNombre,
            U.IdSucursal,
            S.Nombre AS SucursalNombre,
            U.IdPuntoEmision,
            PE.Nombre AS PuntoEmisionNombre,
            U.NivelAcceso,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        LEFT JOIN dbo.Empresa E ON E.IdEmpresa = U.IdEmpresa
        LEFT JOIN dbo.Divisiones D ON D.IdDivision = U.IdDivision
        LEFT JOIN dbo.Sucursales S ON S.IdSucursal = U.IdSucursal
        LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = U.IdPuntoEmision
        WHERE ISNULL(U.RowStatus, 1) = 1
        ORDER BY U.NombreUsuario;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.TipoUsuario,
            U.IdPantallaInicio,
            ISNULL(P.Nombre, '') AS PantallaInicio,
            ISNULL(P.Ruta, '/') AS RutaInicio,
            R.Nombre AS Rol,
            U.Nombres,
            U.Apellidos,
            U.NombreUsuario,
            U.Correo,
            U.ClaveHash,
            U.RequiereCambioClave,
            U.PuedeEliminarLineaPOS,
            U.PuedeCambiarFechaPOS,
            U.Bloqueado,
            U.Activo,
            U.IdEmpresa,
            E.RazonSocial AS EmpresaNombre,
            U.IdDivision,
            D.Nombre AS DivisionNombre,
            U.IdSucursal,
            S.Nombre AS SucursalNombre,
            U.IdPuntoEmision,
            PE.Nombre AS PuntoEmisionNombre,
            U.NivelAcceso,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        LEFT JOIN dbo.Empresa E ON E.IdEmpresa = U.IdEmpresa
        LEFT JOIN dbo.Divisiones D ON D.IdDivision = U.IdDivision
        LEFT JOIN dbo.Sucursales S ON S.IdSucursal = U.IdSucursal
        LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = U.IdPuntoEmision
        WHERE U.IdUsuario = @IdUsuario;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1 FROM dbo.Usuarios WHERE NombreUsuario = @NombreUsuario AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe un usuario con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Usuarios (
            IdRol, TipoUsuario, IdPantallaInicio, Nombres, Apellidos, NombreUsuario, Correo, ClaveHash,
            RequiereCambioClave, PuedeEliminarLineaPOS, PuedeCambiarFechaPOS, Bloqueado, Activo,
            IdEmpresa, IdDivision, IdSucursal, IdPuntoEmision, NivelAcceso,
            RowStatus, FechaCreacion, UsuarioCreacion
        )
        VALUES (
            @IdRol, @TipoUsuario, @IdPantallaInicio, @Nombres, @Apellidos, @NombreUsuario, @Correo, @ClaveHash,
            ISNULL(@RequiereCambioClave, 0), ISNULL(@PuedeEliminarLineaPOS, 0), ISNULL(@PuedeCambiarFechaPOS, 0), ISNULL(@Bloqueado, 0), ISNULL(@Activo, 1),
            @IdEmpresa, @IdDivision, @IdSucursal, @IdPuntoEmision, @NivelAcceso,
            1, GETDATE(), @UsuarioCreacion
        );

        SET @IdUsuario = SCOPE_IDENTITY();
        SELECT @IdUsuario AS IdUsuario;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        IF EXISTS (
            SELECT 1 FROM dbo.Usuarios WHERE NombreUsuario = @NombreUsuario AND IdUsuario <> @IdUsuario AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe un usuario con ese nombre.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.Usuarios
        SET
            IdRol = ISNULL(@IdRol, IdRol),
            TipoUsuario = ISNULL(@TipoUsuario, TipoUsuario),
            IdPantallaInicio = @IdPantallaInicio,
            Nombres = ISNULL(@Nombres, Nombres),
            Apellidos = ISNULL(@Apellidos, Apellidos),
            NombreUsuario = ISNULL(@NombreUsuario, NombreUsuario),
            Correo = @Correo,
            ClaveHash = ISNULL(NULLIF(@ClaveHash, ''), ClaveHash),
            RequiereCambioClave = ISNULL(@RequiereCambioClave, RequiereCambioClave),
            PuedeEliminarLineaPOS = ISNULL(@PuedeEliminarLineaPOS, PuedeEliminarLineaPOS),
            PuedeCambiarFechaPOS = ISNULL(@PuedeCambiarFechaPOS, PuedeCambiarFechaPOS),
            Bloqueado = ISNULL(@Bloqueado, Bloqueado),
            Activo = ISNULL(@Activo, Activo),
            IdEmpresa = @IdEmpresa,
            IdDivision = @IdDivision,
            IdSucursal = @IdSucursal,
            IdPuntoEmision = @IdPuntoEmision,
            NivelAcceso = ISNULL(@NivelAcceso, NivelAcceso),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Usuarios
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario;
        RETURN;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAuthLogin
    @NombreUsuario NVARCHAR(150),
    @ClaveHash NVARCHAR(500),
    @IdCaja INT = NULL,
    @IdSucursal INT = NULL,
    @IdPuntoEmision INT = NULL,
    @Canal NVARCHAR(30) = NULL,
    @IpAddress NVARCHAR(64) = NULL,
    @UserAgent NVARCHAR(300) = NULL,
    @DuracionMinutos INT = NULL,
    @CerrarSesionesPrevias BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(ISNULL(@NombreUsuario, ''))) = ''
    BEGIN
        RAISERROR('Debe enviar @NombreUsuario.', 16, 1);
        RETURN;
    END;

    IF @ClaveHash IS NULL
    BEGIN
        RAISERROR('Debe enviar @ClaveHash.', 16, 1);
        RETURN;
    END;

    DECLARE @IdUsuario INT;
    DECLARE @IdRol INT;
    DECLARE @TipoUsuario CHAR(1);
    DECLARE @IdPantallaInicio INT;
    DECLARE @RutaInicio NVARCHAR(200);
    DECLARE @Rol NVARCHAR(100);
    DECLARE @Nombres NVARCHAR(150);
    DECLARE @Apellidos NVARCHAR(150);
    DECLARE @Correo NVARCHAR(150);
    DECLARE @RequiereCambioClave BIT;
    DECLARE @PuedeEliminarLineaPOS BIT;
    DECLARE @PuedeCambiarFechaPOS BIT;
    DECLARE @SesionDuracionMinutos INT = 600;
    DECLARE @SesionIdleMinutos INT = 30;

    SELECT TOP (1)
        @IdUsuario = U.IdUsuario,
        @IdRol = U.IdRol,
        @TipoUsuario = U.TipoUsuario,
        @IdPantallaInicio = U.IdPantallaInicio,
        @RutaInicio = ISNULL(P.Ruta, '/'),
        @Rol = R.Nombre,
        @Nombres = U.Nombres,
        @Apellidos = U.Apellidos,
        @Correo = U.Correo,
        @RequiereCambioClave = U.RequiereCambioClave,
        @PuedeEliminarLineaPOS = U.PuedeEliminarLineaPOS,
        @PuedeCambiarFechaPOS = U.PuedeCambiarFechaPOS
    FROM dbo.Usuarios U
    INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    WHERE U.NombreUsuario = LTRIM(RTRIM(@NombreUsuario))
      AND U.ClaveHash = @ClaveHash
      AND U.RowStatus = 1
      AND U.Activo = 1
      AND ISNULL(U.Bloqueado, 0) = 0;

    IF @IdUsuario IS NULL
    BEGIN
        RAISERROR('Credenciales invalidas o usuario inactivo.', 16, 1);
        RETURN;
    END;

    SELECT TOP (1)
        @SesionDuracionMinutos = CASE WHEN ISNULL(E.SesionDuracionMinutos, 0) > 0 THEN E.SesionDuracionMinutos ELSE 600 END,
        @SesionIdleMinutos = CASE WHEN ISNULL(E.SesionIdleMinutos, 0) > 0 THEN E.SesionIdleMinutos ELSE 30 END
    FROM dbo.Empresa E
    WHERE E.RowStatus = 1 AND ISNULL(E.Activo, 1) = 1
    ORDER BY E.IdEmpresa;

    SET @SesionDuracionMinutos = CASE WHEN ISNULL(@DuracionMinutos, 0) > 0 THEN @DuracionMinutos ELSE ISNULL(@SesionDuracionMinutos, 600) END;

    IF @CerrarSesionesPrevias = 1
    BEGIN
        UPDATE dbo.SesionesActivas
        SET SesionActiva = 0,
            FechaCierre = SYSDATETIME(),
            FechaUltimaActividad = SYSDATETIME(),
            Observaciones = 'Cierre por nueva autenticacion.'
        WHERE IdUsuario = @IdUsuario
          AND SesionActiva = 1;
    END;

    DECLARE @Token UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.SesionesActivas
        (IdUsuario, TokenSesion, SesionActiva, IdCaja, IdSucursal, IdPuntoEmision, Canal, IpAddress, UserAgent, FechaExpiracion)
    VALUES
        (@IdUsuario, @Token, 1, @IdCaja, @IdSucursal, @IdPuntoEmision, ISNULL(@Canal, 'WEB'), @IpAddress, @UserAgent, DATEADD(MINUTE, @SesionDuracionMinutos, SYSDATETIME()));

    DECLARE @IdSesion BIGINT = SCOPE_IDENTITY();

    SELECT
        @IdSesion AS IdSesion,
        CONVERT(NVARCHAR(36), @Token) AS TokenSesion,
        @IdUsuario AS IdUsuario,
        @IdRol AS IdRol,
        @TipoUsuario AS TipoUsuario,
        @IdPantallaInicio AS IdPantallaInicio,
        ISNULL(@RutaInicio, '/') AS RutaInicio,
        @Rol AS Rol,
        @Nombres AS Nombres,
        @Apellidos AS Apellidos,
        @NombreUsuario AS NombreUsuario,
        @Correo AS Correo,
        ISNULL(@RequiereCambioClave, 0) AS RequiereCambioClave,
        ISNULL(@PuedeEliminarLineaPOS, 0) AS PuedeEliminarLineaPOS,
        ISNULL(@PuedeCambiarFechaPOS, 0) AS PuedeCambiarFechaPOS,
        DATEADD(MINUTE, @SesionDuracionMinutos, SYSDATETIME()) AS FechaExpiracion,
        @SesionDuracionMinutos AS SesionDuracionMinutos,
        @SesionIdleMinutos AS SesionIdleMinutos;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAuthValidarSesion
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@IdSesion, 0) = 0 AND LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) = ''
    BEGIN
        RAISERROR('Debe enviar @IdSesion o @TokenSesion.', 16, 1);
        RETURN;
    END;

    DECLARE @IdleMin INT = 30;

    SELECT TOP (1)
        @IdleMin = CASE WHEN ISNULL(E.SesionIdleMinutos, 0) > 0 THEN E.SesionIdleMinutos ELSE 30 END
    FROM dbo.Empresa E
    WHERE E.RowStatus = 1 AND ISNULL(E.Activo, 1) = 1
    ORDER BY E.IdEmpresa;

    SELECT TOP (1)
        S.IdSesion,
        CONVERT(NVARCHAR(36), S.TokenSesion) AS TokenSesion,
        S.SesionActiva,
        S.IdCaja,
        S.IdSucursal,
        S.IdPuntoEmision,
        S.Canal,
        S.IpAddress,
        S.UserAgent,
        S.FechaInicio,
        S.FechaUltimaActividad,
        S.FechaExpiracion,
        U.IdUsuario,
        U.IdRol,
        U.TipoUsuario,
        U.IdPantallaInicio,
        ISNULL(P.Ruta, '/') AS RutaInicio,
        R.Nombre AS Rol,
        U.Nombres,
        U.Apellidos,
        U.NombreUsuario,
        U.Correo,
        U.RequiereCambioClave,
        U.PuedeEliminarLineaPOS,
        U.PuedeCambiarFechaPOS,
        U.Bloqueado,
        U.Activo,
        CASE WHEN ISNULL(E.SesionDuracionMinutos, 0) > 0 THEN E.SesionDuracionMinutos ELSE 600 END AS SesionDuracionMinutos,
        CASE WHEN ISNULL(E.SesionIdleMinutos, 0) > 0 THEN E.SesionIdleMinutos ELSE 30 END AS SesionIdleMinutos
    FROM dbo.SesionesActivas S
    INNER JOIN dbo.Usuarios U ON U.IdUsuario = S.IdUsuario
    INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    OUTER APPLY (
        SELECT TOP (1) *
        FROM dbo.Empresa E1
        WHERE E1.RowStatus = 1 AND ISNULL(E1.Activo, 1) = 1
        ORDER BY E1.IdEmpresa
    ) E
    WHERE (@IdSesion <> 0 AND S.IdSesion = @IdSesion)
       OR (LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) <> '' AND CONVERT(NVARCHAR(36), S.TokenSesion) = LTRIM(RTRIM(@TokenSesion)))
    ORDER BY S.IdSesion DESC;
END;
GO
