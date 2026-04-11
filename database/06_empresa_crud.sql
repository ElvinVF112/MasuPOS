SET NOCOUNT ON;
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

CREATE OR ALTER PROCEDURE dbo.spEmpresaCRUD
    @Accion CHAR(1),
    @IdEmpresa INT = NULL OUTPUT,
    @RNC NVARCHAR(11) = NULL,
    @RazonSocial NVARCHAR(200) = NULL,
    @NombreComercial NVARCHAR(200) = NULL,
    @Direccion NVARCHAR(300) = NULL,
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
            E.RazonSocial,
            E.NombreComercial,
            E.Direccion,
            E.Telefono1,
            E.Telefono2,
            E.Correo,
            E.SitioWeb,
            E.Instagram,
            E.Facebook,
            E.XTwitter,
            E.LogoUrl,
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
            E.RazonSocial,
            E.NombreComercial,
            E.Direccion,
            E.Telefono1,
            E.Telefono2,
            E.Correo,
            E.SitioWeb,
            E.Instagram,
            E.Facebook,
            E.XTwitter,
            E.LogoUrl,
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
            (RNC, RazonSocial, NombreComercial, Direccion, Telefono1, Telefono2, Correo, SitioWeb, Instagram, Facebook, XTwitter, LogoUrl, Moneda, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (
                NULLIF(LTRIM(RTRIM(@RNC)), ''),
                LTRIM(RTRIM(@RazonSocial)),
                NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
                NULLIF(LTRIM(RTRIM(@Direccion)), ''),
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
            RazonSocial = LTRIM(RTRIM(@RazonSocial)),
            NombreComercial = NULLIF(LTRIM(RTRIM(@NombreComercial)), ''),
            Direccion = NULLIF(LTRIM(RTRIM(@Direccion)), ''),
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
