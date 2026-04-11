SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Usuarios', 'PuedeEliminarLineaPOS') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD PuedeEliminarLineaPOS BIT NOT NULL CONSTRAINT DF_Usuarios_PuedeEliminarLineaPOS DEFAULT (0);
END
GO

IF OBJECT_ID('dbo.spUsuariosCRUD', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.spUsuariosCRUD AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.spUsuariosCRUD
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
            SELECT 1
            FROM dbo.Usuarios
            WHERE NombreUsuario = @NombreUsuario
              AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe un usuario con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Usuarios (
            IdRol,
            TipoUsuario,
            IdPantallaInicio,
            Nombres,
            Apellidos,
            NombreUsuario,
            Correo,
            ClaveHash,
            RequiereCambioClave,
            PuedeEliminarLineaPOS,
            Bloqueado,
            Activo,
            IdEmpresa,
            IdDivision,
            IdSucursal,
            IdPuntoEmision,
            NivelAcceso,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion
        )
        VALUES (
            @IdRol,
            @TipoUsuario,
            @IdPantallaInicio,
            @Nombres,
            @Apellidos,
            @NombreUsuario,
            @Correo,
            @ClaveHash,
            ISNULL(@RequiereCambioClave, 0),
            ISNULL(@PuedeEliminarLineaPOS, 0),
            ISNULL(@Bloqueado, 0),
            ISNULL(@Activo, 1),
            @IdEmpresa,
            @IdDivision,
            @IdSucursal,
            @IdPuntoEmision,
            @NivelAcceso,
            1,
            GETDATE(),
            @UsuarioCreacion
        );

        SET @IdUsuario = SCOPE_IDENTITY();
        SELECT @IdUsuario AS IdUsuario;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.Usuarios
            WHERE NombreUsuario = @NombreUsuario
              AND IdUsuario <> @IdUsuario
              AND ISNULL(RowStatus, 1) = 1
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
        SET
            RowStatus = 0,
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
        @PuedeEliminarLineaPOS = U.PuedeEliminarLineaPOS
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
        @SesionDuracionMinutos = CASE
            WHEN ISNULL(E.SesionDuracionMinutos, 0) > 0 THEN E.SesionDuracionMinutos
            ELSE 600
        END,
        @SesionIdleMinutos = CASE
            WHEN ISNULL(E.SesionIdleMinutos, 0) > 0 THEN E.SesionIdleMinutos
            ELSE 30
        END
    FROM dbo.Empresa E
    WHERE E.RowStatus = 1
      AND ISNULL(E.Activo, 1) = 1
    ORDER BY E.IdEmpresa;

    SET @SesionDuracionMinutos = CASE
        WHEN ISNULL(@DuracionMinutos, 0) > 0 THEN @DuracionMinutos
        ELSE ISNULL(@SesionDuracionMinutos, 600)
    END;

    IF @CerrarSesionesPrevias = 1
    BEGIN
        UPDATE dbo.SesionesActivas
        SET
            SesionActiva = 0,
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
        @IdleMin = CASE
            WHEN ISNULL(E.SesionIdleMinutos, 0) > 0 THEN E.SesionIdleMinutos
            ELSE 30
        END
    FROM dbo.Empresa E
    WHERE E.RowStatus = 1
      AND ISNULL(E.Activo, 1) = 1
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
        U.Bloqueado,
        U.Activo,
        CASE
            WHEN ISNULL(E.SesionDuracionMinutos, 0) > 0 THEN E.SesionDuracionMinutos
            ELSE 600
        END AS SesionDuracionMinutos,
        CASE
            WHEN ISNULL(E.SesionIdleMinutos, 0) > 0 THEN E.SesionIdleMinutos
            ELSE 30
        END AS SesionIdleMinutos
    FROM dbo.SesionesActivas S
    INNER JOIN dbo.Usuarios U ON U.IdUsuario = S.IdUsuario
    INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    OUTER APPLY (
        SELECT TOP (1) *
        FROM dbo.Empresa E1
        WHERE E1.RowStatus = 1
          AND ISNULL(E1.Activo, 1) = 1
        ORDER BY E1.IdEmpresa
    ) E
    WHERE S.SesionActiva = 1
      AND U.RowStatus = 1
      AND U.Activo = 1
      AND ISNULL(U.Bloqueado, 0) = 0
      AND (
            (@IdSesion > 0 AND S.IdSesion = @IdSesion)
         OR (LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) <> '' AND CONVERT(NVARCHAR(36), S.TokenSesion) = LTRIM(RTRIM(@TokenSesion)))
      )
      AND (S.FechaExpiracion IS NULL OR S.FechaExpiracion >= SYSDATETIME())
      AND (
            S.FechaUltimaActividad IS NULL
         OR DATEADD(MINUTE, @IdleMin, S.FechaUltimaActividad) >= SYSDATETIME()
      );
END;
GO

DECLARE @IdPantallaFacturacionPos INT = (
    SELECT TOP (1) IdPantalla
    FROM dbo.Pantallas
    WHERE RowStatus = 1 AND Ruta = '/facturacion/pos'
);

IF @IdPantallaFacturacionPos IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM dbo.Permisos WHERE RowStatus = 1 AND Clave = 'facturacion.pos.delete-line'
)
BEGIN
    INSERT INTO dbo.Permisos (
        IdPantalla,
        Nombre,
        Descripcion,
        Clave,
        Activo,
        RowStatus,
        FechaCreacion,
        UsuarioCreacion
    )
    VALUES (
        @IdPantallaFacturacionPos,
        N'Eliminar lineas en POS',
        N'Permite eliminar lineas individuales en Punto de Ventas',
        N'facturacion.pos.delete-line',
        1,
        1,
        GETDATE(),
        1
    );
END;
GO

DECLARE @IdPermisoDeletePos INT = (
    SELECT TOP (1) IdPermiso
    FROM dbo.Permisos
    WHERE RowStatus = 1 AND Clave = 'facturacion.pos.delete-line'
);

IF @IdPermisoDeletePos IS NOT NULL
BEGIN
    INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    SELECT R.IdRol, @IdPermisoDeletePos, 1, 1, GETDATE(), 1
    FROM dbo.Roles R
    WHERE R.RowStatus = 1
      AND R.Activo = 1
      AND (
        UPPER(LTRIM(RTRIM(R.Nombre))) LIKE '%ADMIN%'
        OR UPPER(LTRIM(RTRIM(R.Nombre))) LIKE '%SUPERVIS%'
      )
      AND NOT EXISTS (
        SELECT 1
        FROM dbo.RolesPermisos RP
        WHERE RP.IdRol = R.IdRol
          AND RP.IdPermiso = @IdPermisoDeletePos
          AND RP.RowStatus = 1
      );
END;
GO
