SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Usuarios', 'Bloqueado') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD Bloqueado BIT NOT NULL
        CONSTRAINT DF_Usuarios_Bloqueado DEFAULT (0);
END
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
    @Bloqueado BIT = NULL,
    @Activo BIT = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.IdPantallaInicio,
            ISNULL(P.Nombre, '') AS PantallaInicio,
            ISNULL(P.Ruta, '/') AS RutaInicio,
            R.Nombre AS Rol,
            U.Nombres,
            U.Apellidos,
            U.NombreUsuario,
            U.Correo,
            U.RequiereCambioClave,
            U.Bloqueado,
            U.Activo,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        WHERE U.RowStatus = 1
        ORDER BY U.NombreUsuario;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
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
            U.Bloqueado,
            U.Activo,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        WHERE U.IdUsuario = @IdUsuario
          AND U.RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF @IdRol IS NULL
        BEGIN
            RAISERROR('Debe enviar @IdRol para crear el usuario.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Usuarios
            (IdRol, IdPantallaInicio, Nombres, Apellidos, NombreUsuario, Correo, ClaveHash, RequiereCambioClave, Bloqueado, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdRol, NULLIF(@IdPantallaInicio, 0), LTRIM(RTRIM(@Nombres)), LTRIM(RTRIM(@Apellidos)), LTRIM(RTRIM(@NombreUsuario)), NULLIF(LTRIM(RTRIM(@Correo)), ''), @ClaveHash, ISNULL(@RequiereCambioClave, 0), ISNULL(@Bloqueado, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        SET @IdUsuario = SCOPE_IDENTITY();
        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Usuarios
        SET
            IdRol = ISNULL(@IdRol, IdRol),
            IdPantallaInicio = CASE WHEN @IdPantallaInicio IS NULL THEN IdPantallaInicio ELSE NULLIF(@IdPantallaInicio, 0) END,
            Nombres = LTRIM(RTRIM(@Nombres)),
            Apellidos = LTRIM(RTRIM(@Apellidos)),
            NombreUsuario = LTRIM(RTRIM(@NombreUsuario)),
            Correo = NULLIF(LTRIM(RTRIM(@Correo)), ''),
            RequiereCambioClave = ISNULL(@RequiereCambioClave, RequiereCambioClave),
            Bloqueado = ISNULL(@Bloqueado, Bloqueado),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario
          AND RowStatus = 1;

        IF @ClaveHash IS NOT NULL AND LEN(@ClaveHash) > 0
        BEGIN
            UPDATE dbo.Usuarios
            SET ClaveHash = @ClaveHash
            WHERE IdUsuario = @IdUsuario
              AND RowStatus = 1;
        END;

        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Usuarios
        SET
            RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario
          AND RowStatus = 1;

        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
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
    @DuracionMinutos INT = 480,
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
    DECLARE @IdPantallaInicio INT;
    DECLARE @RutaInicio NVARCHAR(200);
    DECLARE @Rol NVARCHAR(100);
    DECLARE @Nombres NVARCHAR(150);
    DECLARE @Apellidos NVARCHAR(150);
    DECLARE @Correo NVARCHAR(150);
    DECLARE @RequiereCambioClave BIT;

    SELECT TOP (1)
        @IdUsuario = U.IdUsuario,
        @IdRol = U.IdRol,
        @IdPantallaInicio = U.IdPantallaInicio,
        @RutaInicio = ISNULL(P.Ruta, '/'),
        @Rol = R.Nombre,
        @Nombres = U.Nombres,
        @Apellidos = U.Apellidos,
        @Correo = U.Correo,
        @RequiereCambioClave = U.RequiereCambioClave
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
        (@IdUsuario, @Token, 1, @IdCaja, @IdSucursal, @IdPuntoEmision, ISNULL(@Canal, 'WEB'), @IpAddress, @UserAgent, DATEADD(MINUTE, @DuracionMinutos, SYSDATETIME()));

    DECLARE @IdSesion BIGINT = SCOPE_IDENTITY();

    SELECT
        @IdSesion AS IdSesion,
        CONVERT(NVARCHAR(36), @Token) AS TokenSesion,
        @IdUsuario AS IdUsuario,
        @IdRol AS IdRol,
        @IdPantallaInicio AS IdPantallaInicio,
        ISNULL(@RutaInicio, '/') AS RutaInicio,
        @Rol AS Rol,
        @Nombres AS Nombres,
        @Apellidos AS Apellidos,
        @NombreUsuario AS NombreUsuario,
        @Correo AS Correo,
        ISNULL(@RequiereCambioClave, 0) AS RequiereCambioClave,
        DATEADD(MINUTE, @DuracionMinutos, SYSDATETIME()) AS FechaExpiracion;
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
        U.IdPantallaInicio,
        ISNULL(P.Ruta, '/') AS RutaInicio,
        R.Nombre AS Rol,
        U.Nombres,
        U.Apellidos,
        U.NombreUsuario,
        U.Correo,
        U.RequiereCambioClave,
        U.Bloqueado,
        U.Activo
    FROM dbo.SesionesActivas S
    INNER JOIN dbo.Usuarios U ON U.IdUsuario = S.IdUsuario
    INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    WHERE S.SesionActiva = 1
      AND U.RowStatus = 1
      AND U.Activo = 1
      AND ISNULL(U.Bloqueado, 0) = 0
      AND (
            (@IdSesion > 0 AND S.IdSesion = @IdSesion)
         OR (LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) <> '' AND CONVERT(NVARCHAR(36), S.TokenSesion) = LTRIM(RTRIM(@TokenSesion)))
      )
      AND (S.FechaExpiracion IS NULL OR S.FechaExpiracion >= SYSDATETIME());
END;
GO
