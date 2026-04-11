SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.SesionesActivas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SesionesActivas (
        IdSesion BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SesionesActivas PRIMARY KEY,
        IdUsuario INT NOT NULL,
        TokenSesion UNIQUEIDENTIFIER NOT NULL,
        SesionActiva BIT NOT NULL CONSTRAINT DF_SesionesActivas_SesionActiva DEFAULT (1),
        IdCaja INT NULL,
        IdSucursal INT NULL,
        IdPuntoEmision INT NULL,
        Canal NVARCHAR(30) NULL,
        IpAddress NVARCHAR(64) NULL,
        UserAgent NVARCHAR(300) NULL,
        FechaInicio DATETIME2(0) NOT NULL CONSTRAINT DF_SesionesActivas_FechaInicio DEFAULT (SYSDATETIME()),
        FechaUltimaActividad DATETIME2(0) NOT NULL CONSTRAINT DF_SesionesActivas_FechaUltimaActividad DEFAULT (SYSDATETIME()),
        FechaExpiracion DATETIME2(0) NULL,
        FechaCierre DATETIME2(0) NULL,
        Observaciones NVARCHAR(250) NULL,
        CONSTRAINT FK_SesionesActivas_Usuarios_IdUsuario FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuarios (IdUsuario)
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.SesionesActivas')
      AND name = 'UX_SesionesActivas_TokenSesion'
)
BEGIN
    CREATE UNIQUE INDEX UX_SesionesActivas_TokenSesion ON dbo.SesionesActivas (TokenSesion);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.SesionesActivas')
      AND name = 'IX_SesionesActivas_IdUsuario_Activa'
)
BEGIN
    CREATE INDEX IX_SesionesActivas_IdUsuario_Activa ON dbo.SesionesActivas (IdUsuario, SesionActiva, FechaInicio DESC);
END
GO

IF OBJECT_ID('dbo.Empresa', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Empresa (
        IdEmpresa INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Empresa PRIMARY KEY,
        RNC NVARCHAR(11) NULL,
        RazonSocial NVARCHAR(200) NOT NULL,
        NombreComercial NVARCHAR(200) NULL,
        Direccion NVARCHAR(300) NULL,
        Telefono1 NVARCHAR(30) NULL,
        Telefono2 NVARCHAR(30) NULL,
        Correo NVARCHAR(150) NULL,
        SitioWeb NVARCHAR(200) NULL,
        Instagram NVARCHAR(150) NULL,
        Facebook NVARCHAR(150) NULL,
        XTwitter NVARCHAR(150) NULL,
        LogoUrl NVARCHAR(300) NULL,
        Moneda NVARCHAR(10) NULL CONSTRAINT DF_Empresa_Moneda DEFAULT ('DOP'),
        Activo BIT NOT NULL CONSTRAINT DF_Empresa_Activo DEFAULT (1),
        RowStatus BIT NOT NULL CONSTRAINT DF_Empresa_RowStatus DEFAULT (1),
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Empresa_FechaCreacion DEFAULT (SYSDATETIME()),
        UsuarioCreacion INT NULL,
        FechaModificacion DATETIME2(0) NULL,
        UsuarioModificacion INT NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Empresa)
BEGIN
    INSERT INTO dbo.Empresa (RazonSocial, NombreComercial)
    VALUES ('Empresa Demo SRL', 'Masu POS Demo');
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
      AND U.Activo = 1;

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
        U.Activo
    FROM dbo.SesionesActivas S
    INNER JOIN dbo.Usuarios U ON U.IdUsuario = S.IdUsuario
    INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    WHERE S.SesionActiva = 1
      AND U.RowStatus = 1
      AND U.Activo = 1
      AND (
            (@IdSesion > 0 AND S.IdSesion = @IdSesion)
         OR (LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) <> '' AND CONVERT(NVARCHAR(36), S.TokenSesion) = LTRIM(RTRIM(@TokenSesion)))
      )
      AND (S.FechaExpiracion IS NULL OR S.FechaExpiracion >= SYSDATETIME());
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAuthCerrarSesion
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@IdSesion, 0) = 0 AND LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) = ''
    BEGIN
        RAISERROR('Debe enviar @IdSesion o @TokenSesion.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.SesionesActivas
    SET
        SesionActiva = 0,
        FechaCierre = SYSDATETIME(),
        FechaUltimaActividad = SYSDATETIME(),
        Observaciones = ISNULL(@Observaciones, Observaciones)
    WHERE SesionActiva = 1
      AND (
            (@IdSesion > 0 AND IdSesion = @IdSesion)
         OR (LTRIM(RTRIM(ISNULL(@TokenSesion, ''))) <> '' AND CONVERT(NVARCHAR(36), TokenSesion) = LTRIM(RTRIM(@TokenSesion)))
      );

    SELECT @@ROWCOUNT AS SesionesCerradas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAuthCerrarSesionesUsuario
    @IdUsuario INT,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SesionesActivas
    SET
        SesionActiva = 0,
        FechaCierre = SYSDATETIME(),
        FechaUltimaActividad = SYSDATETIME(),
        Observaciones = ISNULL(@Observaciones, 'Cierre administrativo de sesiones.')
    WHERE IdUsuario = @IdUsuario
      AND SesionActiva = 1;

    SELECT @@ROWCOUNT AS SesionesCerradas;
END;
GO
