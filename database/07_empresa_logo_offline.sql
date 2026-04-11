SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Empresa', 'NombreEmpresa') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD NombreEmpresa NVARCHAR(200) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'IdentificacionFiscal') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD IdentificacionFiscal NVARCHAR(30) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'CalleNumero') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD CalleNumero NVARCHAR(300) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'Ciudad') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD Ciudad NVARCHAR(100) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'ProvinciaEstado') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD ProvinciaEstado NVARCHAR(100) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'CodigoPostal') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD CodigoPostal NVARCHAR(20) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'Pais') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD Pais NVARCHAR(100) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'LogoData') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD LogoData VARBINARY(MAX) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'LogoMimeType') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD LogoMimeType NVARCHAR(100) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'LogoFileName') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD LogoFileName NVARCHAR(260) NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'LogoActualizacion') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD LogoActualizacion DATETIME2(0) NULL;
END
GO

UPDATE dbo.Empresa
SET
    NombreEmpresa = ISNULL(NombreEmpresa, ISNULL(NombreComercial, RazonSocial)),
    IdentificacionFiscal = ISNULL(IdentificacionFiscal, RNC),
    CalleNumero = ISNULL(CalleNumero, Direccion),
    Pais = ISNULL(Pais, 'Republica Dominicana')
WHERE RowStatus = 1;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spEmpresaCRUD
    @Accion CHAR(1),
    @IdEmpresa INT = NULL OUTPUT,
    @RNC NVARCHAR(11) = NULL,
    @IdentificacionFiscal NVARCHAR(30) = NULL,
    @NombreEmpresa NVARCHAR(200) = NULL,
    @RazonSocial NVARCHAR(200) = NULL,
    @NombreComercial NVARCHAR(200) = NULL,
    @Direccion NVARCHAR(300) = NULL,
    @CalleNumero NVARCHAR(300) = NULL,
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
            E.IdEmpresa,
            E.RNC,
            E.IdentificacionFiscal,
            E.NombreEmpresa,
            E.RazonSocial,
            E.NombreComercial,
            E.Direccion,
            E.CalleNumero,
            E.Ciudad,
            E.ProvinciaEstado,
            E.CodigoPostal,
            E.Pais,
            E.Telefono1,
            E.Telefono2,
            E.Correo,
            E.SitioWeb,
            E.Instagram,
            E.Facebook,
            E.XTwitter,
            E.LogoUrl,
            E.LogoMimeType,
            E.LogoFileName,
            E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda,
            E.Activo,
            E.RowStatus,
            E.FechaCreacion
        FROM dbo.Empresa E
        WHERE E.RowStatus = 1
        ORDER BY E.IdEmpresa;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            E.IdEmpresa,
            E.RNC,
            E.IdentificacionFiscal,
            E.NombreEmpresa,
            E.RazonSocial,
            E.NombreComercial,
            E.Direccion,
            E.CalleNumero,
            E.Ciudad,
            E.ProvinciaEstado,
            E.CodigoPostal,
            E.Pais,
            E.Telefono1,
            E.Telefono2,
            E.Correo,
            E.SitioWeb,
            E.Instagram,
            E.Facebook,
            E.XTwitter,
            E.LogoUrl,
            E.LogoMimeType,
            E.LogoFileName,
            E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda,
            E.Activo,
            E.RowStatus,
            E.FechaCreacion,
            E.UsuarioCreacion,
            E.FechaModificacion,
            E.UsuarioModificacion
        FROM dbo.Empresa E
        WHERE E.IdEmpresa = @IdEmpresa
          AND E.RowStatus = 1;
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
            (RNC, IdentificacionFiscal, NombreEmpresa, RazonSocial, NombreComercial, Direccion, CalleNumero, Ciudad, ProvinciaEstado, CodigoPostal, Pais, Telefono1, Telefono2, Correo, SitioWeb, Instagram, Facebook, XTwitter, LogoUrl, Moneda, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (
                NULLIF(LTRIM(RTRIM(@RNC)), ''),
                NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), ''),
                NULLIF(LTRIM(RTRIM(@NombreEmpresa)), ''),
                LTRIM(RTRIM(@RazonSocial)),
                NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
                NULLIF(LTRIM(RTRIM(@Direccion)), ''),
                NULLIF(LTRIM(RTRIM(@CalleNumero)), ''),
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
                1,
                SYSDATETIME(),
                @UsuarioCreacion
            );

        SET @IdEmpresa = SCOPE_IDENTITY();
        EXEC dbo.spEmpresaCRUD @Accion='O', @IdEmpresa=@IdEmpresa, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
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
            RNC = NULLIF(LTRIM(RTRIM(@RNC)), ''),
            IdentificacionFiscal = NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), ''),
            NombreEmpresa = NULLIF(LTRIM(RTRIM(@NombreEmpresa)), ''),
            RazonSocial = LTRIM(RTRIM(@RazonSocial)),
            NombreComercial = NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
            Direccion = NULLIF(LTRIM(RTRIM(@Direccion)), ''),
            CalleNumero = NULLIF(LTRIM(RTRIM(@CalleNumero)), ''),
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
            FechaModificacion = SYSDATETIME(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdEmpresa = @IdEmpresa
          AND RowStatus = 1;

        EXEC dbo.spEmpresaCRUD @Accion='O', @IdEmpresa=@IdEmpresa, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
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

        EXEC dbo.spEmpresaCRUD @Accion='O', @IdEmpresa=@IdEmpresa, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spEmpresaLogoGuardar
    @IdEmpresa INT,
    @LogoData VARBINARY(MAX),
    @LogoMimeType NVARCHAR(100),
    @LogoFileName NVARCHAR(260) = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @IdEmpresa IS NULL OR @IdEmpresa <= 0
    BEGIN
        RAISERROR('Debe enviar @IdEmpresa.', 16, 1);
        RETURN;
    END;

    IF @LogoData IS NULL
    BEGIN
        RAISERROR('Debe enviar @LogoData.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.Empresa
    SET
        LogoData = @LogoData,
        LogoMimeType = NULLIF(LTRIM(RTRIM(@LogoMimeType)), ''),
        LogoFileName = NULLIF(LTRIM(RTRIM(@LogoFileName)), ''),
        LogoActualizacion = SYSDATETIME(),
        FechaModificacion = SYSDATETIME(),
        UsuarioModificacion = @UsuarioModificacion
    WHERE IdEmpresa = @IdEmpresa
      AND RowStatus = 1;

    SELECT
        IdEmpresa,
        LogoMimeType,
        LogoFileName,
        LogoActualizacion,
        CASE WHEN LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo
    FROM dbo.Empresa
    WHERE IdEmpresa = @IdEmpresa;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spEmpresaLogoObtener
    @IdEmpresa INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        E.IdEmpresa,
        E.LogoData,
        E.LogoMimeType,
        E.LogoFileName,
        E.LogoActualizacion
    FROM dbo.Empresa E
    WHERE E.RowStatus = 1
      AND (ISNULL(@IdEmpresa, 0) = 0 OR E.IdEmpresa = @IdEmpresa)
    ORDER BY E.IdEmpresa;
END;
GO
