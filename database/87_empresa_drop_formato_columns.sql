SET NOCOUNT ON;
GO

-- Eliminar columnas de formato de Empresa (reemplazadas por defaults hardcodeados en la app)
-- Primero se eliminan los constraints DEFAULT, luego las columnas

IF OBJECT_ID('DF_Empresa_FormatoDecimal', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_FormatoDecimal;
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoDecimal') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN FormatoDecimal;
GO

IF OBJECT_ID('DF_Empresa_DigitosDecimales', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_DigitosDecimales;
GO
IF COL_LENGTH('dbo.Empresa', 'DigitosDecimales') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN DigitosDecimales;
GO

IF OBJECT_ID('DF_Empresa_SeparadorMiles', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_SeparadorMiles;
GO
IF COL_LENGTH('dbo.Empresa', 'SeparadorMiles') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN SeparadorMiles;
GO

IF OBJECT_ID('DF_Empresa_SimboloNegativo', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_SimboloNegativo;
GO
IF COL_LENGTH('dbo.Empresa', 'SimboloNegativo') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN SimboloNegativo;
GO

IF OBJECT_ID('DF_Empresa_FormatoFechaCorta', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_FormatoFechaCorta;
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoFechaCorta') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN FormatoFechaCorta;
GO

IF OBJECT_ID('DF_Empresa_FormatoFechaLarga', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_FormatoFechaLarga;
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoFechaLarga') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN FormatoFechaLarga;
GO

IF OBJECT_ID('DF_Empresa_FormatoHoraCorta', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_FormatoHoraCorta;
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoHoraCorta') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN FormatoHoraCorta;
GO

IF OBJECT_ID('DF_Empresa_FormatoHoraLarga', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_FormatoHoraLarga;
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoHoraLarga') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN FormatoHoraLarga;
GO

IF OBJECT_ID('DF_Empresa_SimboloAM', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_SimboloAM;
GO
IF COL_LENGTH('dbo.Empresa', 'SimboloAM') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN SimboloAM;
GO

IF OBJECT_ID('DF_Empresa_SimboloPM', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_SimboloPM;
GO
IF COL_LENGTH('dbo.Empresa', 'SimboloPM') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN SimboloPM;
GO

IF OBJECT_ID('DF_Empresa_PrimerDiaSemana', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_PrimerDiaSemana;
GO
IF COL_LENGTH('dbo.Empresa', 'PrimerDiaSemana') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN PrimerDiaSemana;
GO

IF OBJECT_ID('DF_Empresa_SistemaMedida', 'D') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_SistemaMedida;
GO
IF COL_LENGTH('dbo.Empresa', 'SistemaMedida') IS NOT NULL
    ALTER TABLE dbo.Empresa DROP COLUMN SistemaMedida;
GO

-- Recrear spEmpresaCRUD sin columnas de formato
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
    @Eslogan NVARCHAR(500) = NULL,
    @SesionDuracionMinutos INT = NULL,
    @SesionIdleMinutos INT = NULL,
    @AplicaPropina BIT = NULL,
    @PorcentajePropina DECIMAL(5,2) = NULL,
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
            E.Eslogan, E.SesionDuracionMinutos, E.SesionIdleMinutos,
            ISNULL(E.AplicaPropina, 0) AS AplicaPropina,
            ISNULL(E.PorcentajePropina, 10.00) AS PorcentajePropina
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
            E.Eslogan, E.SesionDuracionMinutos, E.SesionIdleMinutos,
            ISNULL(E.AplicaPropina, 0) AS AplicaPropina,
            ISNULL(E.PorcentajePropina, 10.00) AS PorcentajePropina
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
            Eslogan, SesionDuracionMinutos, SesionIdleMinutos, AplicaPropina, PorcentajePropina,
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
            NULLIF(LTRIM(RTRIM(@Eslogan)), ''),
            ISNULL(NULLIF(@SesionDuracionMinutos, 0), 600),
            ISNULL(NULLIF(@SesionIdleMinutos, 0), 30),
            ISNULL(@AplicaPropina, 0),
            ISNULL(NULLIF(@PorcentajePropina, 0), 10.00),
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
            Eslogan = NULLIF(LTRIM(RTRIM(@Eslogan)), ''),
            SesionDuracionMinutos = ISNULL(NULLIF(@SesionDuracionMinutos, 0), SesionDuracionMinutos),
            SesionIdleMinutos = ISNULL(NULLIF(@SesionIdleMinutos, 0), SesionIdleMinutos),
            AplicaPropina = ISNULL(@AplicaPropina, AplicaPropina),
            PorcentajePropina = ISNULL(NULLIF(@PorcentajePropina, 0), PorcentajePropina),
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
