SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Empresa', 'RNC') IS NOT NULL
   AND COL_LENGTH('dbo.Empresa', 'IdentificacionFiscal') IS NOT NULL
BEGIN
    UPDATE dbo.Empresa
    SET IdentificacionFiscal = NULLIF(LTRIM(RTRIM(RNC)), '')
    WHERE RowStatus = 1
      AND (IdentificacionFiscal IS NULL OR LTRIM(RTRIM(IdentificacionFiscal)) = '')
      AND NULLIF(LTRIM(RTRIM(RNC)), '') IS NOT NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'NombreEmpresa') IS NOT NULL
   AND COL_LENGTH('dbo.Empresa', 'NombreComercial') IS NOT NULL
BEGIN
    UPDATE dbo.Empresa
    SET NombreComercial = NULLIF(LTRIM(RTRIM(NombreEmpresa)), '')
    WHERE RowStatus = 1
      AND (NombreComercial IS NULL OR LTRIM(RTRIM(NombreComercial)) = '')
      AND NULLIF(LTRIM(RTRIM(NombreEmpresa)), '') IS NOT NULL;
END
GO

IF COL_LENGTH('dbo.Empresa', 'CalleNumero') IS NOT NULL
   AND COL_LENGTH('dbo.Empresa', 'Direccion') IS NOT NULL
BEGIN
    UPDATE dbo.Empresa
    SET Direccion = NULLIF(LTRIM(RTRIM(CalleNumero)), '')
    WHERE RowStatus = 1
      AND (Direccion IS NULL OR LTRIM(RTRIM(Direccion)) = '')
      AND NULLIF(LTRIM(RTRIM(CalleNumero)), '') IS NOT NULL;
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
            E.Eslogan
        FROM dbo.Empresa E
        WHERE E.RowStatus = 1
        ORDER BY E.IdEmpresa;
        RETURN;
    END

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
            E.Eslogan
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
        (IdentificacionFiscal, RazonSocial, NombreComercial, Direccion, Ciudad, ProvinciaEstado, CodigoPostal, Pais,
         Telefono1, Telefono2, Correo, SitioWeb, Instagram, Facebook, XTwitter, LogoUrl, Moneda, Activo,
         FormatoDecimal, DigitosDecimales, SeparadorMiles, SimboloNegativo, FormatoFechaCorta, FormatoFechaLarga,
         FormatoHoraCorta, FormatoHoraLarga, SimboloAM, SimboloPM, PrimerDiaSemana, SistemaMedida, Eslogan,
         RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
        (NULLIF(LTRIM(RTRIM(@IdentificacionFiscal)), ''), LTRIM(RTRIM(@RazonSocial)), NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
         NULLIF(LTRIM(RTRIM(@Direccion)), ''), NULLIF(LTRIM(RTRIM(@Ciudad)), ''), NULLIF(LTRIM(RTRIM(@ProvinciaEstado)), ''),
         NULLIF(LTRIM(RTRIM(@CodigoPostal)), ''), NULLIF(LTRIM(RTRIM(@Pais)), ''),
         NULLIF(LTRIM(RTRIM(@Telefono1)), ''), NULLIF(LTRIM(RTRIM(@Telefono2)), ''), NULLIF(LTRIM(RTRIM(@Correo)), ''),
         NULLIF(LTRIM(RTRIM(@SitioWeb)), ''), NULLIF(LTRIM(RTRIM(@Instagram)), ''), NULLIF(LTRIM(RTRIM(@Facebook)), ''),
         NULLIF(LTRIM(RTRIM(@XTwitter)), ''), NULLIF(LTRIM(RTRIM(@LogoUrl)), ''), ISNULL(NULLIF(LTRIM(RTRIM(@Moneda)), ''), 'DOP'), ISNULL(@Activo, 1),
         ISNULL(NULLIF(LTRIM(RTRIM(@FormatoDecimal)), ''), '.'), ISNULL(@DigitosDecimales, 2), ISNULL(NULLIF(LTRIM(RTRIM(@SeparadorMiles)), ''), ','),
         ISNULL(NULLIF(LTRIM(RTRIM(@SimboloNegativo)), ''), '-'), ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaCorta)), ''), 'dd/MM/yyyy'),
         ISNULL(NULLIF(LTRIM(RTRIM(@FormatoFechaLarga)), ''), 'dddd, d ''de'' MMMM ''de'' yyyy'),
         ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraCorta)), ''), 'h:mm tt'), ISNULL(NULLIF(LTRIM(RTRIM(@FormatoHoraLarga)), ''), 'h:mm:ss tt'),
         ISNULL(NULLIF(LTRIM(RTRIM(@SimboloAM)), ''), 'AM'), ISNULL(NULLIF(LTRIM(RTRIM(@SimboloPM)), ''), 'PM'), ISNULL(@PrimerDiaSemana, 1),
         ISNULL(NULLIF(LTRIM(RTRIM(@SistemaMedida)), ''), 'Metrico'), NULLIF(LTRIM(RTRIM(@Eslogan)),
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
            Eslogan = NULLIF(LTRIM(RTRIM(@Eslogan)),
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

IF COL_LENGTH('dbo.Empresa', 'RNC') IS NOT NULL
BEGIN
    DECLARE @RncDefaultConstraint SYSNAME;

    SELECT @RncDefaultConstraint = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON c.default_object_id = dc.object_id
    INNER JOIN sys.tables t ON t.object_id = c.object_id
    WHERE t.name = 'Empresa'
      AND SCHEMA_NAME(t.schema_id) = 'dbo'
      AND c.name = 'RNC';

    IF @RncDefaultConstraint IS NOT NULL
    BEGIN
        DECLARE @DropRncConstraintSql NVARCHAR(400);
        SET @DropRncConstraintSql = N'ALTER TABLE dbo.Empresa DROP CONSTRAINT ' + QUOTENAME(@RncDefaultConstraint);
        EXEC(@DropRncConstraintSql);
    END

    ALTER TABLE dbo.Empresa DROP COLUMN RNC;
END
GO

IF COL_LENGTH('dbo.Empresa', 'NombreEmpresa') IS NOT NULL
BEGIN
    DECLARE @NombreEmpresaDefaultConstraint SYSNAME;

    SELECT @NombreEmpresaDefaultConstraint = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON c.default_object_id = dc.object_id
    INNER JOIN sys.tables t ON t.object_id = c.object_id
    WHERE t.name = 'Empresa'
      AND SCHEMA_NAME(t.schema_id) = 'dbo'
      AND c.name = 'NombreEmpresa';

    IF @NombreEmpresaDefaultConstraint IS NOT NULL
    BEGIN
        DECLARE @DropNombreEmpresaConstraintSql NVARCHAR(400);
        SET @DropNombreEmpresaConstraintSql = N'ALTER TABLE dbo.Empresa DROP CONSTRAINT ' + QUOTENAME(@NombreEmpresaDefaultConstraint);
        EXEC(@DropNombreEmpresaConstraintSql);
    END

    ALTER TABLE dbo.Empresa DROP COLUMN NombreEmpresa;
END
GO

IF COL_LENGTH('dbo.Empresa', 'CalleNumero') IS NOT NULL
BEGIN
    DECLARE @CalleNumeroDefaultConstraint SYSNAME;

    SELECT @CalleNumeroDefaultConstraint = dc.name
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON c.default_object_id = dc.object_id
    INNER JOIN sys.tables t ON t.object_id = c.object_id
    WHERE t.name = 'Empresa'
      AND SCHEMA_NAME(t.schema_id) = 'dbo'
      AND c.name = 'CalleNumero';

    IF @CalleNumeroDefaultConstraint IS NOT NULL
    BEGIN
        DECLARE @DropCalleNumeroConstraintSql NVARCHAR(400);
        SET @DropCalleNumeroConstraintSql = N'ALTER TABLE dbo.Empresa DROP CONSTRAINT ' + QUOTENAME(@CalleNumeroDefaultConstraint);
        EXEC(@DropCalleNumeroConstraintSql);
    END

    ALTER TABLE dbo.Empresa DROP COLUMN CalleNumero;
END
GO
