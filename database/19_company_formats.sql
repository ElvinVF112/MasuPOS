SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Empresa', 'FormatoDecimal') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD FormatoDecimal NVARCHAR(10) NOT NULL CONSTRAINT DF_Empresa_FormatoDecimal DEFAULT('.');
END
GO
IF COL_LENGTH('dbo.Empresa', 'DigitosDecimales') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD DigitosDecimales INT NOT NULL CONSTRAINT DF_Empresa_DigitosDecimales DEFAULT(2);
END
GO
IF COL_LENGTH('dbo.Empresa', 'SeparadorMiles') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD SeparadorMiles NVARCHAR(10) NOT NULL CONSTRAINT DF_Empresa_SeparadorMiles DEFAULT(',');
END
GO
IF COL_LENGTH('dbo.Empresa', 'SimboloNegativo') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD SimboloNegativo NVARCHAR(5) NOT NULL CONSTRAINT DF_Empresa_SimboloNegativo DEFAULT('-');
END
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoFechaCorta') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD FormatoFechaCorta NVARCHAR(20) NOT NULL CONSTRAINT DF_Empresa_FormatoFechaCorta DEFAULT('dd/MM/yyyy');
END
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoFechaLarga') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD FormatoFechaLarga NVARCHAR(80) NOT NULL CONSTRAINT DF_Empresa_FormatoFechaLarga DEFAULT('dddd, d ''de'' MMMM ''de'' yyyy');
END
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoHoraCorta') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD FormatoHoraCorta NVARCHAR(20) NOT NULL CONSTRAINT DF_Empresa_FormatoHoraCorta DEFAULT('h:mm tt');
END
GO
IF COL_LENGTH('dbo.Empresa', 'FormatoHoraLarga') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD FormatoHoraLarga NVARCHAR(20) NOT NULL CONSTRAINT DF_Empresa_FormatoHoraLarga DEFAULT('h:mm:ss tt');
END
GO
IF COL_LENGTH('dbo.Empresa', 'SimboloAM') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD SimboloAM NVARCHAR(5) NOT NULL CONSTRAINT DF_Empresa_SimboloAM DEFAULT('AM');
END
GO
IF COL_LENGTH('dbo.Empresa', 'SimboloPM') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD SimboloPM NVARCHAR(5) NOT NULL CONSTRAINT DF_Empresa_SimboloPM DEFAULT('PM');
END
GO
IF COL_LENGTH('dbo.Empresa', 'PrimerDiaSemana') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD PrimerDiaSemana INT NOT NULL CONSTRAINT DF_Empresa_PrimerDiaSemana DEFAULT(1);
END
GO
IF COL_LENGTH('dbo.Empresa', 'SistemaMedida') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD SistemaMedida NVARCHAR(20) NOT NULL CONSTRAINT DF_Empresa_SistemaMedida DEFAULT('Metrico');
END
GO

UPDATE dbo.Empresa
SET
    FormatoDecimal = ISNULL(NULLIF(FormatoDecimal, ''), '.'),
    DigitosDecimales = ISNULL(DigitosDecimales, 2),
    SeparadorMiles = ISNULL(NULLIF(SeparadorMiles, ''), ','),
    SimboloNegativo = ISNULL(NULLIF(SimboloNegativo, ''), '-'),
    FormatoFechaCorta = ISNULL(NULLIF(FormatoFechaCorta, ''), 'dd/MM/yyyy'),
    FormatoFechaLarga = ISNULL(NULLIF(FormatoFechaLarga, ''), 'dddd, d ''de'' MMMM ''de'' yyyy'),
    FormatoHoraCorta = ISNULL(NULLIF(FormatoHoraCorta, ''), 'h:mm tt'),
    FormatoHoraLarga = ISNULL(NULLIF(FormatoHoraLarga, ''), 'h:mm:ss tt'),
    SimboloAM = ISNULL(NULLIF(SimboloAM, ''), 'AM'),
    SimboloPM = ISNULL(NULLIF(SimboloPM, ''), 'PM'),
    PrimerDiaSemana = ISNULL(PrimerDiaSemana, 1),
    SistemaMedida = ISNULL(NULLIF(SistemaMedida, ''), 'Metrico')
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
            E.IdEmpresa, E.RNC, E.IdentificacionFiscal, E.NombreEmpresa, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.CalleNumero, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida
        FROM dbo.Empresa E
        WHERE E.RowStatus = 1
        ORDER BY E.IdEmpresa;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            E.IdEmpresa, E.RNC, E.IdentificacionFiscal, E.NombreEmpresa, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.CalleNumero, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion, E.UsuarioCreacion, E.FechaModificacion, E.UsuarioModificacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida
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
        (RNC, IdentificacionFiscal, NombreEmpresa, RazonSocial, NombreComercial, Direccion, CalleNumero, Ciudad, ProvinciaEstado, CodigoPostal, Pais,
         Telefono1, Telefono2, Correo, SitioWeb, Instagram, Facebook, XTwitter, LogoUrl, Moneda, Activo,
         FormatoDecimal, DigitosDecimales, SeparadorMiles, SimboloNegativo, FormatoFechaCorta, FormatoFechaLarga,
         FormatoHoraCorta, FormatoHoraLarga, SimboloAM, SimboloPM, PrimerDiaSemana, SistemaMedida,
         RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
        (NULLIF(LTRIM(RTRIM(@RNC)), ''), NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), ''), NULLIF(LTRIM(RTRIM(@NombreEmpresa)), ''),
         LTRIM(RTRIM(@RazonSocial)), NULLIF(LTRIM(RTRIM(@NombreComercial)), ''), NULLIF(LTRIM(RTRIM(@Direccion)), ''),
         NULLIF(LTRIM(RTRIM(@CalleNumero)), ''), NULLIF(LTRIM(RTRIM(@Ciudad)), ''), NULLIF(LTRIM(RTRIM(@ProvinciaEstado)), ''),
         NULLIF(LTRIM(RTRIM(@CodigoPostal)), ''), NULLIF(LTRIM(RTRIM(@Pais)), ''),
         NULLIF(LTRIM(RTRIM(@Telefono1)), ''), NULLIF(LTRIM(RTRIM(@Telefono2)), ''), NULLIF(LTRIM(RTRIM(@Correo)), ''),
         NULLIF(LTRIM(RTRIM(@SitioWeb)), ''), NULLIF(LTRIM(RTRIM(@Instagram)), ''), NULLIF(LTRIM(RTRIM(@Facebook)), ''),
         NULLIF(LTRIM(RTRIM(@XTwitter)), ''), NULLIF(LTRIM(RTRIM(@LogoUrl)), ''), ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'DOP'), ISNULL(@Activo, 1),
         ISNULL(NULLIF(LTRIM(RTRIM(@FormatoDecimal)), ''), '.'), ISNULL(@DigitosDecimales, 2), ISNULL(NULLIF(LTRIM(RTRIM(@SeparadorMiles)), ''), ','),
         ISNULL(NULLIF(LTRIM(RTRIM(@SimboloNegativo)), ''), '-'), ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaCorta)), ''), 'dd/MM/yyyy'),
         ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaLarga)), ''), 'dddd, d ''de'' MMMM ''de'' yyyy'),
         ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraCorta)), ''), 'h:mm tt'), ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraLarga)), ''), 'h:mm:ss tt'),
         ISNULL(NULLIF(LTRIM(RTRIM(@SimboloAM)), ''), 'AM'), ISNULL(NULLIF(LTRIM(RTRIM(@SimboloPM)), ''), 'PM'), ISNULL(@PrimerDiaSemana, 1),
         ISNULL(NULLIF(LTRIM(RTRIM(@SistemaMedida)), ''), 'Metrico'),
         1, SYSDATETIME(), @UsuarioCreacion);

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
        SET RowStatus = 0,
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
