-- Agregar parámetro Eslogan al SP
EXEC('
ALTER PROCEDURE dbo.spEmpresaCRUD
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
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = '\''L'\''
    BEGIN
        SELECT E.IdEmpresa, E.IdentificacionFiscal, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida, E.Eslogan
        FROM dbo.Empresa E WHERE E.RowStatus = 1 ORDER BY E.IdEmpresa;
        RETURN;
    END
    IF @Accion = '\''O'\''
    BEGIN
        SELECT E.IdEmpresa, E.IdentificacionFiscal, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion, E.UsuarioCreacion, E.FechaModificacion, E.UsuarioModificacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida, E.Eslogan
        FROM dbo.Empresa E WHERE E.IdEmpresa = @IdEmpresa AND E.RowStatus = 1;
        RETURN;
    END
    IF @Accion = '\''A'\''
    BEGIN
        UPDATE dbo.Empresa SET
            IdentificacionFiscal = NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), '\'''\''),
            RazonSocial = LTRIM(RTRIM(@RazonSocial)),
            NombreComercial = NULLIF(LTRIM(RTRIM(@NombreComercial)), '\'''\''),
            Direccion = NULLIF(LTRIM(RTRIM(@Direccion)), '\'''\''),
            Ciudad = NULLIF(LTRIM(RTRIM(@Ciudad)), '\'''\''),
            ProvinciaEstado = NULLIF(LTRIM(RTRIM(@ProvinciaEstado)), '\'''\''),
            CodigoPostal = NULLIF(LTRIM(RTRIM(@CodigoPostal)), '\'''\''),
            Pais = NULLIF(LTRIM(RTRIM(@Pais)), '\'''\''),
            Telefono1 = NULLIF(LTRIM(RTRIM(@Telefono1)), '\'''\''),
            Telefono2 = NULLIF(LTRIM(RTRIM(@Telefono2)), '\'''\''),
            Correo = NULLIF(LTRIM(RTRIM(@Correo)), '\'''\''),
            SitioWeb = NULLIF(LTRIM(RTRIM(@SitioWeb)), '\'''\''),
            Instagram = NULLIF(LTRIM(RTRIM(@Instagram)), '\'''\''),
            Facebook = NULLIF(LTRIM(RTRIM(@Facebook)), '\'''\''),
            XTwitter = NULLIF(LTRIM(RTRIM(@XTwitter)), '\'''\''),
            LogoUrl = NULLIF(LTRIM(RTRIM(@LogoUrl)), '\'''\''),
            Moneda = ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), '\'''\''), Moneda),
            Activo = ISNULL(@Activo, Activo),
            FormatoDecimal = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoDecimal)), '\'''\''), FormatoDecimal),
            DigitosDecimales = ISNULL(@DigitosDecimales, DigitosDecimales),
            SeparadorMiles = ISNULL(NULLIF(LTRIM(RTRIM(@SeparadorMiles)), '\'''\''), SeparadorMiles),
            SimboloNegativo = ISNULL(NULLIF(LTRIM(RTRIM(@SimboloNegativo)), '\'''\''), SimboloNegativo),
            FormatoFechaCorta = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaCorta)), '\'''\''), FormatoFechaCorta),
            FormatoFechaLarga = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaLarga)), '\'''\''), FormatoFechaLarga),
            FormatoHoraCorta = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraCorta)), '\'''\''), FormatoHoraCorta),
            FormatoHoraLarga = ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraLarga)), '\'''\''), FormatoHoraLarga),
            SimboloAM = ISNULL(NULLIF(LTRIM(RTRIM(@SimboloAM)), '\'''\''), SimboloAM),
            SimboloPM = ISNULL(NULLIF(LTRIM(RTRIM(@SimboloPM)), '\'''\''), SimboloPM),
            PrimerDiaSemana = ISNULL(@PrimerDiaSemana, PrimerDiaSemana),
            SistemaMedida = ISNULL(NULLIF(LTRIM(RTRIM(@SistemaMedida)), '\'''\''), SistemaMedida),
            Eslogan = NULLIF(LTRIM(RTRIM(@Eslogan)),
            FechaModificacion = SYSDATETIME(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdEmpresa = @IdEmpresa AND RowStatus = 1;
        EXEC dbo.spEmpresaCRUD @Accion='\''O'\'', @IdEmpresa=@IdEmpresa, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END
END
')