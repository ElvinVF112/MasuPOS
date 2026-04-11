SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Empresa', 'SesionDuracionMinutos') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa
    ADD SesionDuracionMinutos INT NOT NULL
        CONSTRAINT DF_Empresa_SesionDuracionMinutos DEFAULT (600);
END
GO

IF COL_LENGTH('dbo.Empresa', 'SesionIdleMinutos') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa
    ADD SesionIdleMinutos INT NOT NULL
        CONSTRAINT DF_Empresa_SesionIdleMinutos DEFAULT (30);
END
GO

UPDATE dbo.Empresa
SET
    SesionDuracionMinutos = ISNULL(NULLIF(SesionDuracionMinutos, 0), 600),
    SesionIdleMinutos = ISNULL(NULLIF(SesionIdleMinutos, 0), 30)
WHERE RowStatus = 1;
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

CREATE OR ALTER PROCEDURE dbo.spAuthHeartbeat
    @IdSesion BIGINT = NULL,
    @TokenSesion UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SesionesActivas
    SET FechaUltimaActividad = SYSDATETIME()
    WHERE (IdSesion = @IdSesion OR TokenSesion = @TokenSesion)
      AND SesionActiva = 1;
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

CREATE OR ALTER PROCEDURE dbo.spAuthCerrarSesion
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @Observaciones NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SesionesCerradas INT = 0;

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

    SET @SesionesCerradas = @@ROWCOUNT;

    DELETE FROM dbo.SesionesActivas
    WHERE SesionActiva = 0
      AND FechaCierre IS NOT NULL
      AND FechaCierre < DATEADD(DAY, -30, SYSDATETIME());

    SELECT @SesionesCerradas AS SesionesCerradas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spEmpresaCRUD
    @Accion CHAR(1),
    @IdEmpresa INT = NULL OUTPUT,
    @IdentificacionFiscal NVARCHAR(30) = NULL,
    @RazonSocial NVARCHAR(200) = NULL,
    @NombreComercial NVARCHAR(200) = NULL,
    @Direccion NVARCHAR(300) = NULL,
    @Ciudad NVARCHAR(100) = NULL,
    @ProvinciaEstado NVARCHAR(100) = NULL,
    @CodigoPostal NVARCHAR(20) = NULL,
    @Pais NVARCHAR(100) = NULL,
    @Telefono1 NVARCHAR(30) = NULL,
    @Telefono2 NVARCHAR(30) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @SitioWeb NVARCHAR(200) = NULL,
    @Instagram NVARCHAR(150) = NULL,
    @Facebook NVARCHAR(150) = NULL,
    @XTwitter NVARCHAR(150) = NULL,
    @LogoUrl NVARCHAR(300) = NULL,
    @Moneda NVARCHAR(10) = NULL,
    @Activo BIT = NULL,
    @FormatoDecimal NVARCHAR(10) = NULL,
    @DigitosDecimales INT = NULL,
    @SeparadorMiles NVARCHAR(10) = NULL,
    @SimboloNegativo NVARCHAR(5) = NULL,
    @FormatoFechaCorta NVARCHAR(20) = NULL,
    @FormatoFechaLarga NVARCHAR(80) = NULL,
    @FormatoHoraCorta NVARCHAR(20) = NULL,
    @FormatoHoraLarga NVARCHAR(20) = NULL,
    @SimboloAM NVARCHAR(5) = NULL,
    @SimboloPM NVARCHAR(5) = NULL,
    @PrimerDiaSemana INT = NULL,
    @SistemaMedida NVARCHAR(20) = NULL,
    @Eslogan NVARCHAR(500) = NULL,
    @SesionDuracionMinutos INT = NULL,
    @SesionIdleMinutos INT = NULL,
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
            E.IdEmpresa, E.IdentificacionFiscal, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida,
            E.Eslogan, E.SesionDuracionMinutos, E.SesionIdleMinutos
        FROM dbo.Empresa E
        WHERE E.RowStatus = 1
        ORDER BY E.IdEmpresa;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            E.IdEmpresa, E.IdentificacionFiscal, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion, E.UsuarioCreacion, E.FechaModificacion, E.UsuarioModificacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida,
            E.Eslogan, E.SesionDuracionMinutos, E.SesionIdleMinutos
        FROM dbo.Empresa E
        WHERE (@IdEmpresa IS NULL AND E.RowStatus = 1)
           OR (E.IdEmpresa = @IdEmpresa AND E.RowStatus = 1)
        ORDER BY E.IdEmpresa;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF LTRIM(RTRIM(ISNULL(@RazonSocial, ''))) = ''
        BEGIN
            RAISERROR('Debe enviar @RazonSocial.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Empresa
        (
            IdentificacionFiscal, RazonSocial, NombreComercial, Direccion, Ciudad, ProvinciaEstado, CodigoPostal, Pais,
            Telefono1, Telefono2, Correo, SitioWeb, Instagram, Facebook, XTwitter, LogoUrl, Moneda, Activo,
            FormatoDecimal, DigitosDecimales, SeparadorMiles, SimboloNegativo, FormatoFechaCorta, FormatoFechaLarga,
            FormatoHoraCorta, FormatoHoraLarga, SimboloAM, SimboloPM, PrimerDiaSemana, SistemaMedida, Eslogan,
            SesionDuracionMinutos, SesionIdleMinutos,
            RowStatus, FechaCreacion, UsuarioCreacion
        )
        VALUES
        (
            NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), ''),
            LTRIM(RTRIM(@RazonSocial)),
            NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
            NULLIF(LTRIM(RTRIM(@Direccion)), ''),
            NULLIF(LTRIM(RTRIM(@Ciudad)), ''),
            NULLIF(LTRIM(RTRIM(@ProvinciaEstado)), ''),
            NULLIF(LTRIM(RTRIM(@CodigoPostal)), ''),
            NULLIF(LTRIM(RTRIM(@Pais)), ''),
            NULLIF(LTRIM(RTRIM(@Telefono1)), ''),
            NULLIF(LTRIM(RTRIM(@Telefono2)), ''),
            NULLIF(LTRIM(RTRIM(@Correo)), ''),
            NULLIF(LTRIM(RTRIM(@SitioWeb)), ''),
            NULLIF(LTRIM(RTRIM(@Instagram)), ''),
            NULLIF(LTRIM(RTRIM(@Facebook)), ''),
            NULLIF(LTRIM(RTRIM(@XTwitter)), ''),
            NULLIF(LTRIM(RTRIM(@LogoUrl)), ''),
            ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'DOP'),
            ISNULL(@Activo, 1),
            ISNULL(NULLIF(LTRIM(RTRIM(@FormatoDecimal)), ''), '.'),
            ISNULL(@DigitosDecimales, 2),
            ISNULL(NULLIF(LTRIM(RTRIM(@SeparadorMiles)), ''), ','),
            ISNULL(NULLIF(LTRIM(RTRIM(@SimboloNegativo)), ''), '-'),
            ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaCorta)), ''), 'dd/MM/yyyy'),
            ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaLarga)), ''), 'dddd, d ''de'' MMMM ''de'' yyyy'),
            ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraCorta)), ''), 'h:mm tt'),
            ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraLarga)), ''), 'h:mm:ss tt'),
            ISNULL(NULLIF(LTRIM(RTRIM(@SimboloAM)), ''), 'AM'),
            ISNULL(NULLIF(LTRIM(RTRIM(@SimboloPM)), ''), 'PM'),
            ISNULL(@PrimerDiaSemana, 1),
            ISNULL(NULLIF(LTRIM(RTRIM(@SistemaMedida)), ''), 'Metrico'),
            NULLIF(LTRIM(RTRIM(@Eslogan)), ''),
            ISNULL(NULLIF(@SesionDuracionMinutos, 0), 600),
            ISNULL(NULLIF(@SesionIdleMinutos, 0), 30),
            1,
            SYSDATETIME(),
            @UsuarioCreacion
        );

        SET @IdEmpresa = SCOPE_IDENTITY();
        EXEC dbo.spEmpresaCRUD @Accion = 'O', @IdEmpresa = @IdEmpresa, @IdSesion = @IdSesion, @TokenSesion = @TokenSesion;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        IF LTRIM(RTRIM(ISNULL(@RazonSocial, ''))) = ''
        BEGIN
            RAISERROR('Debe enviar @RazonSocial.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.Empresa
        SET
            IdentificacionFiscal = NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), ''),
            RazonSocial = LTRIM(RTRIM(@RazonSocial)),
            NombreComercial = NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
            Direccion = NULLIF(LTRIM(RTRIM(@Direccion)), ''),
            Ciudad = NULLIF(LTRIM(RTRIM(@Ciudad)), ''),
            ProvinciaEstado = NULLIF(LTRIM(RTRIM(@ProvinciaEstado)), ''),
            CodigoPostal = NULLIF(LTRIM(RTRIM(@CodigoPostal)), ''),
            Pais = NULLIF(LTRIM(RTRIM(@Pais)), ''),
            Telefono1 = NULLIF(LTRIM(RTRIM(@Telefono1)), ''),
            Telefono2 = NULLIF(LTRIM(RTRIM(@Telefono2)), ''),
            Correo = NULLIF(LTRIM(RTRIM(@Correo)), ''),
            SitioWeb = NULLIF(LTRIM(RTRIM(@SitioWeb)), ''),
            Instagram = NULLIF(LTRIM(RTRIM(@Instagram)), ''),
            Facebook = NULLIF(LTRIM(RTRIM(@Facebook)), ''),
            XTwitter = NULLIF(LTRIM(RTRIM(@XTwitter)), ''),
            LogoUrl = NULLIF(LTRIM(RTRIM(@LogoUrl)), ''),
            Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), Moneda),
            Activo = ISNULL(@Activo, Activo),
            FormatoDecimal = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoDecimal)), ''), FormatoDecimal),
            DigitosDecimales = ISNULL(@DigitosDecimales, DigitosDecimales),
            SeparadorMiles = ISNULL(NULLIF(LTRIM(RTRIM(@SeparadorMiles)), ''), SeparadorMiles),
            SimboloNegativo = ISNULL(NULLIF(LTRIM(RTRIM(@SimboloNegativo)), ''), SimboloNegativo),
            FormatoFechaCorta = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaCorta)), ''), FormatoFechaCorta),
            FormatoFechaLarga = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaLarga)), ''), FormatoFechaLarga),
            FormatoHoraCorta = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraCorta)), ''), FormatoHoraCorta),
            FormatoHoraLarga = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraLarga)), ''), FormatoHoraLarga),
            SimboloAM = ISNULL(NULLIF(LTRIM(RTRIM(@SimboloAM)), ''), SimboloAM),
            SimboloPM = ISNULL(NULLIF(LTRIM(RTRIM(@SimboloPM)), ''), SimboloPM),
            PrimerDiaSemana = ISNULL(@PrimerDiaSemana, PrimerDiaSemana),
            SistemaMedida = ISNULL(NULLIF(LTRIM(RTRIM(@SistemaMedida)), ''), SistemaMedida),
            Eslogan = NULLIF(LTRIM(RTRIM(@Eslogan)), ''),
            SesionDuracionMinutos = ISNULL(NULLIF(@SesionDuracionMinutos, 0), SesionDuracionMinutos),
            SesionIdleMinutos = ISNULL(NULLIF(@SesionIdleMinutos, 0), SesionIdleMinutos),
            FechaModificacion = SYSDATETIME(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdEmpresa = @IdEmpresa
          AND RowStatus = 1;

        EXEC dbo.spEmpresaCRUD @Accion = 'O', @IdEmpresa = @IdEmpresa, @IdSesion = @IdSesion, @TokenSesion = @TokenSesion;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Empresa
        SET
            RowStatus = 0,
            FechaModificacion = SYSDATETIME(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdEmpresa = @IdEmpresa
          AND RowStatus = 1;

        EXEC dbo.spEmpresaCRUD @Accion = 'O', @IdEmpresa = @IdEmpresa, @IdSesion = @IdSesion, @TokenSesion = @TokenSesion;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO
