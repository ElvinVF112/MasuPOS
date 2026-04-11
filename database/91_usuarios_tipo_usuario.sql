USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 91: tipo de usuario A/S/O ===';
GO

IF COL_LENGTH('dbo.Usuarios', 'TipoUsuario') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD TipoUsuario CHAR(1) NULL;
END
GO

UPDATE U
SET TipoUsuario = CASE
    WHEN UPPER(LTRIM(RTRIM(R.Nombre))) LIKE '%ADMIN%' THEN 'A'
    WHEN UPPER(LTRIM(RTRIM(R.Nombre))) LIKE '%SUPERVIS%' THEN 'S'
    ELSE 'O'
END
FROM dbo.Usuarios U
INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
WHERE U.RowStatus = 1
  AND (U.TipoUsuario IS NULL OR LTRIM(RTRIM(U.TipoUsuario)) = '');
GO

UPDATE dbo.Usuarios
SET TipoUsuario = 'O'
WHERE TipoUsuario IS NULL OR LTRIM(RTRIM(TipoUsuario)) = '';
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.Usuarios')
      AND name = 'TipoUsuario'
      AND is_nullable = 1
)
BEGIN
    ALTER TABLE dbo.Usuarios ALTER COLUMN TipoUsuario CHAR(1) NOT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Usuarios_TipoUsuario'
      AND parent_object_id = OBJECT_ID('dbo.Usuarios')
)
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD CONSTRAINT CK_Usuarios_TipoUsuario
    CHECK (TipoUsuario IN ('A', 'S', 'O'));
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
    @TipoUsuario CHAR(1) = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @TipoUsuario = UPPER(LTRIM(RTRIM(ISNULL(@TipoUsuario, 'O'))));

    IF @Accion IN ('I', 'A') AND @TipoUsuario NOT IN ('A', 'S', 'O')
    BEGIN
        RAISERROR('Debe indicar @TipoUsuario valido: A, S u O.', 16, 1);
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
            (IdRol, TipoUsuario, IdPantallaInicio, Nombres, Apellidos, NombreUsuario, Correo, ClaveHash, RequiereCambioClave, Bloqueado, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdRol, @TipoUsuario, NULLIF(@IdPantallaInicio, 0), LTRIM(RTRIM(@Nombres)), LTRIM(RTRIM(@Apellidos)), LTRIM(RTRIM(@NombreUsuario)), NULLIF(LTRIM(RTRIM(@Correo)), ''), @ClaveHash, ISNULL(@RequiereCambioClave, 0), ISNULL(@Bloqueado, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        SET @IdUsuario = SCOPE_IDENTITY();
        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Usuarios
        SET
            IdRol = ISNULL(@IdRol, IdRol),
            TipoUsuario = ISNULL(@TipoUsuario, TipoUsuario),
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

CREATE OR ALTER PROCEDURE dbo.spAuthVerificarSupervisor
  @NombreUsuario NVARCHAR(150),
  @ClaveHash NVARCHAR(500),
  @ClavePermiso NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Usuario NVARCHAR(150) = LTRIM(RTRIM(ISNULL(@NombreUsuario, '')));
  DECLARE @Permiso NVARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@ClavePermiso, ''))));

  IF @Usuario = ''
    THROW 50910, 'Debe indicar el usuario del supervisor.', 1;

  IF ISNULL(@ClaveHash, '') = ''
    THROW 50911, 'Debe indicar la clave del supervisor.', 1;

  IF @Permiso = ''
    THROW 50912, 'Debe indicar el permiso a validar.', 1;

  DECLARE @IdUsuario INT;
  DECLARE @IdRol INT;
  DECLARE @TipoUsuario CHAR(1);

  SELECT TOP 1
    @IdUsuario = U.IdUsuario,
    @IdRol = U.IdRol,
    @TipoUsuario = U.TipoUsuario
  FROM dbo.Usuarios U
  WHERE U.RowStatus = 1
    AND U.Activo = 1
    AND ISNULL(U.Bloqueado, 0) = 0
    AND U.NombreUsuario = @Usuario
    AND U.ClaveHash = @ClaveHash;

  IF @IdUsuario IS NULL
    THROW 50913, 'Credenciales de supervisor invalidas.', 1;

  IF ISNULL(@TipoUsuario, 'O') NOT IN ('A', 'S')
    THROW 50915, 'El usuario indicado no tiene perfil de supervisor.', 1;

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
    WHERE RP.RowStatus = 1
      AND RP.Activo = 1
      AND RP.IdRol = @IdRol
      AND P.RowStatus = 1
      AND P.Activo = 1
      AND LOWER(LTRIM(RTRIM(P.Clave))) = @Permiso
  )
    THROW 50914, 'El supervisor no tiene el permiso requerido.', 1;

  SELECT TOP 1
    U.IdUsuario,
    U.IdRol,
    U.TipoUsuario,
    R.Nombre AS Rol,
    U.NombreUsuario,
    U.Nombres,
    U.Apellidos,
    @Permiso AS ClavePermiso
  FROM dbo.Usuarios U
  INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
  WHERE U.IdUsuario = @IdUsuario;
END;
GO
