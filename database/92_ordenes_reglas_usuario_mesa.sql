USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 92: reglas de negocio de órdenes por usuario y bloqueo de mesa ===';
GO

IF COL_LENGTH('dbo.Empresa', 'RestringirOrdenesPorUsuario') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa
    ADD RestringirOrdenesPorUsuario BIT NOT NULL
        CONSTRAINT DF_Empresa_RestringirOrdenesPorUsuario DEFAULT (0);
END
GO

IF COL_LENGTH('dbo.Empresa', 'BloquearMesaPorUsuario') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa
    ADD BloquearMesaPorUsuario BIT NOT NULL
        CONSTRAINT DF_Empresa_BloquearMesaPorUsuario DEFAULT (0);
END
GO

IF COL_LENGTH('dbo.Recursos', 'IdUsuarioBloqueoOrdenes') IS NULL
BEGIN
    ALTER TABLE dbo.Recursos ADD IdUsuarioBloqueoOrdenes INT NULL;
END
GO

IF COL_LENGTH('dbo.Recursos', 'FechaBloqueoOrdenes') IS NULL
BEGIN
    ALTER TABLE dbo.Recursos ADD FechaBloqueoOrdenes DATETIME2(0) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Recursos_Usuarios_BloqueoOrdenes'
)
AND COL_LENGTH('dbo.Recursos', 'IdUsuarioBloqueoOrdenes') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Recursos
    ADD CONSTRAINT FK_Recursos_Usuarios_BloqueoOrdenes
        FOREIGN KEY (IdUsuarioBloqueoOrdenes) REFERENCES dbo.Usuarios(IdUsuario);
END
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
    @Eslogan NVARCHAR(500) = NULL,
    @SesionDuracionMinutos INT = NULL,
    @SesionIdleMinutos INT = NULL,
    @AplicaImpuesto BIT = NULL,
    @NombreImpuesto NVARCHAR(50) = NULL,
    @PorcentajeImpuesto DECIMAL(5,2) = NULL,
    @AplicaPropina BIT = NULL,
    @NombrePropina NVARCHAR(50) = NULL,
    @PorcentajePropina DECIMAL(5,2) = NULL,
    @RestringirOrdenesPorUsuario BIT = NULL,
    @BloquearMesaPorUsuario BIT = NULL,
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
            ISNULL(E.AplicaImpuesto, 1) AS AplicaImpuesto,
            ISNULL(E.NombreImpuesto, N'ITBIS') AS NombreImpuesto,
            ISNULL(E.PorcentajeImpuesto, 18.00) AS PorcentajeImpuesto,
            ISNULL(E.AplicaPropina, 0) AS AplicaPropina,
            ISNULL(E.NombrePropina, N'Propina Legal') AS NombrePropina,
            ISNULL(E.PorcentajePropina, 10.00) AS PorcentajePropina,
            ISNULL(E.RestringirOrdenesPorUsuario, 0) AS RestringirOrdenesPorUsuario,
            ISNULL(E.BloquearMesaPorUsuario, 0) AS BloquearMesaPorUsuario
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
            ISNULL(E.AplicaImpuesto, 1) AS AplicaImpuesto,
            ISNULL(E.NombreImpuesto, N'ITBIS') AS NombreImpuesto,
            ISNULL(E.PorcentajeImpuesto, 18.00) AS PorcentajeImpuesto,
            ISNULL(E.AplicaPropina, 0) AS AplicaPropina,
            ISNULL(E.NombrePropina, N'Propina Legal') AS NombrePropina,
            ISNULL(E.PorcentajePropina, 10.00) AS PorcentajePropina,
            ISNULL(E.RestringirOrdenesPorUsuario, 0) AS RestringirOrdenesPorUsuario,
            ISNULL(E.BloquearMesaPorUsuario, 0) AS BloquearMesaPorUsuario
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
            Eslogan, SesionDuracionMinutos, SesionIdleMinutos,
            AplicaImpuesto, NombreImpuesto, PorcentajeImpuesto,
            AplicaPropina, NombrePropina, PorcentajePropina,
            RestringirOrdenesPorUsuario, BloquearMesaPorUsuario,
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
            ISNULL(@AplicaImpuesto, 1),
            ISNULL(NULLIF(LTRIM(RTRIM(@NombreImpuesto)), ''), N'ITBIS'),
            ISNULL(NULLIF(@PorcentajeImpuesto, 0), 18.00),
            ISNULL(@AplicaPropina, 0),
            ISNULL(NULLIF(LTRIM(RTRIM(@NombrePropina)), ''), N'Propina Legal'),
            ISNULL(NULLIF(@PorcentajePropina, 0), 10.00),
            ISNULL(@RestringirOrdenesPorUsuario, 0),
            ISNULL(@BloquearMesaPorUsuario, 0),
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
            AplicaImpuesto = ISNULL(@AplicaImpuesto, AplicaImpuesto),
            NombreImpuesto = ISNULL(NULLIF(LTRIM(RTRIM(@NombreImpuesto)), ''), NombreImpuesto),
            PorcentajeImpuesto = ISNULL(NULLIF(@PorcentajeImpuesto, 0), PorcentajeImpuesto),
            AplicaPropina = ISNULL(@AplicaPropina, AplicaPropina),
            NombrePropina = ISNULL(NULLIF(LTRIM(RTRIM(@NombrePropina)), ''), NombrePropina),
            PorcentajePropina = ISNULL(NULLIF(@PorcentajePropina, 0), PorcentajePropina),
            RestringirOrdenesPorUsuario = ISNULL(@RestringirOrdenesPorUsuario, RestringirOrdenesPorUsuario),
            BloquearMesaPorUsuario = ISNULL(@BloquearMesaPorUsuario, BloquearMesaPorUsuario),
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

CREATE OR ALTER PROCEDURE dbo.spRecursosCRUD
    @Accion CHAR(2),
    @IdRecurso INT = NULL OUTPUT,
    @IdCategoriaRecurso INT = NULL,
    @Nombre VARCHAR(100) = NULL,
    @Estado VARCHAR(20) = NULL,
    @Activo BIT = NULL,
    @IdUsuarioBloqueoOrdenes INT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            R.IdRecurso,
            R.IdCategoriaRecurso,
            R.Nombre,
            R.Estado,
            R.Activo,
            R.IdUsuarioBloqueoOrdenes,
            R.FechaBloqueoOrdenes,
            ISNULL(U.NombreUsuario, '') AS UsuarioBloqueo,
            R.RowStatus,
            R.FechaCreacion
        FROM dbo.Recursos R
        LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
        WHERE R.RowStatus = 1
        ORDER BY R.Nombre;
        RETURN;
    END;

    IF @Accion = 'LC'
    BEGIN
        SELECT
            R.IdRecurso,
            R.IdCategoriaRecurso,
            R.Nombre,
            R.Estado,
            R.Activo,
            R.IdUsuarioBloqueoOrdenes,
            R.FechaBloqueoOrdenes,
            ISNULL(U.NombreUsuario, '') AS UsuarioBloqueo,
            R.RowStatus,
            R.FechaCreacion
        FROM dbo.Recursos R
        LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
        WHERE R.IdCategoriaRecurso = @IdCategoriaRecurso
          AND R.RowStatus = 1
        ORDER BY R.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            R.IdRecurso,
            R.IdCategoriaRecurso,
            R.Nombre,
            R.Estado,
            R.Activo,
            R.IdUsuarioBloqueoOrdenes,
            R.FechaBloqueoOrdenes,
            ISNULL(U.NombreUsuario, '') AS UsuarioBloqueo,
            R.RowStatus,
            R.FechaCreacion,
            R.UsuarioCreacion,
            R.FechaModificacion,
            R.UsuarioModificacion
        FROM dbo.Recursos R
        LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
        WHERE R.IdRecurso = @IdRecurso;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Recursos
            (IdCategoriaRecurso, Nombre, Estado, Activo, IdUsuarioBloqueoOrdenes, FechaBloqueoOrdenes, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdCategoriaRecurso, LTRIM(RTRIM(@Nombre)), ISNULL(@Estado, 'Libre'), ISNULL(@Activo, 1), NULL, NULL, 1, GETDATE(), @UsuarioCreacion);

        SET @IdRecurso = SCOPE_IDENTITY();
        EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Recursos
        SET
            IdCategoriaRecurso = @IdCategoriaRecurso,
            Nombre = LTRIM(RTRIM(@Nombre)),
            Estado = ISNULL(@Estado, Estado),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRecurso = @IdRecurso;

        EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
        RETURN;
    END;

    IF @Accion = 'CE'
    BEGIN
        UPDATE dbo.Recursos
        SET
            Estado = @Estado,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRecurso = @IdRecurso;

        EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
        RETURN;
    END;

    IF @Accion = 'BO'
    BEGIN
        UPDATE dbo.Recursos
        SET
            IdUsuarioBloqueoOrdenes = @IdUsuarioBloqueoOrdenes,
            FechaBloqueoOrdenes = CASE WHEN @IdUsuarioBloqueoOrdenes IS NULL THEN NULL ELSE GETDATE() END,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRecurso = @IdRecurso;

        EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
        RETURN;
    END;

    IF @Accion = 'DB'
    BEGIN
        UPDATE dbo.Recursos
        SET
            IdUsuarioBloqueoOrdenes = NULL,
            FechaBloqueoOrdenes = NULL,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRecurso = @IdRecurso;

        EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Recursos
        SET
            RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRecurso = @IdRecurso;

        EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, LC, O, I, A, CE, BO, DB o D.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesValidarAccesoUsuario
    @Operacion VARCHAR(30),
    @IdUsuario INT,
    @TipoUsuario CHAR(1) = 'O',
    @IdOrden INT = NULL,
    @IdRecurso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EsPrivilegiado BIT = CASE WHEN @TipoUsuario IN ('A', 'S') THEN 1 ELSE 0 END;
    DECLARE @RestringirOrdenes BIT = 0;
    DECLARE @BloquearMesa BIT = 0;

    SELECT TOP 1
        @RestringirOrdenes = ISNULL(RestringirOrdenesPorUsuario, 0),
        @BloquearMesa = ISNULL(BloquearMesaPorUsuario, 0)
    FROM dbo.Empresa
    WHERE RowStatus = 1
    ORDER BY IdEmpresa;

    IF @IdOrden IS NOT NULL AND @RestringirOrdenes = 1 AND @EsPrivilegiado = 0
    BEGIN
        DECLARE @IdUsuarioOrden INT;
        SELECT TOP 1 @IdUsuarioOrden = IdUsuario
        FROM dbo.Ordenes
        WHERE IdOrden = @IdOrden
          AND RowStatus = 1;

        IF @IdUsuarioOrden IS NULL
            THROW 50960, 'La orden no existe.', 1;

        IF @IdUsuarioOrden <> @IdUsuario
            THROW 50961, 'No puedes entrar o modificar una orden de otro usuario.', 1;
    END;

    IF @IdRecurso IS NOT NULL AND @BloquearMesa = 1 AND @EsPrivilegiado = 0
    BEGIN
        DECLARE @IdUsuarioBloqueo INT;
        DECLARE @UsuarioBloqueo NVARCHAR(60);
        DECLARE @MensajeBloqueo NVARCHAR(200);

        SELECT TOP 1
            @IdUsuarioBloqueo = R.IdUsuarioBloqueoOrdenes,
            @UsuarioBloqueo = U.NombreUsuario
        FROM dbo.Recursos R
        LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
        WHERE R.IdRecurso = @IdRecurso
          AND R.RowStatus = 1;

        IF @IdUsuarioBloqueo IS NOT NULL AND @IdUsuarioBloqueo <> @IdUsuario
        BEGIN
            SET @MensajeBloqueo = N'La mesa esta bloqueada por ' + ISNULL(@UsuarioBloqueo, N'otro usuario') + N'.';
            RAISERROR(@MensajeBloqueo, 16, 1);
            RETURN;
        END
    END;

    SELECT
        CAST(1 AS BIT) AS Permitido,
        @RestringirOrdenes AS RestringirOrdenesPorUsuario,
        @BloquearMesa AS BloquearMesaPorUsuario;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesSincronizarBloqueoRecurso
    @IdRecurso INT,
    @UsuarioAccion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BloquearMesa BIT = 0;
    SELECT TOP 1 @BloquearMesa = ISNULL(BloquearMesaPorUsuario, 0)
    FROM dbo.Empresa
    WHERE RowStatus = 1
    ORDER BY IdEmpresa;

    IF ISNULL(@BloquearMesa, 0) = 0
    BEGIN
        UPDATE dbo.Recursos
        SET
            IdUsuarioBloqueoOrdenes = NULL,
            FechaBloqueoOrdenes = NULL,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioAccion, UsuarioModificacion)
        WHERE IdRecurso = @IdRecurso
          AND RowStatus = 1;

        RETURN;
    END;

    DECLARE @IdUsuarioPrimeraOrden INT;
    SELECT TOP 1 @IdUsuarioPrimeraOrden = O.IdUsuario
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdRecurso = @IdRecurso
      AND O.RowStatus = 1
      AND E.Nombre IN ('Abierta', 'En proceso', 'Reabierta')
    ORDER BY O.FechaOrden, O.IdOrden;

    IF @IdUsuarioPrimeraOrden IS NULL
    BEGIN
        UPDATE dbo.Recursos
        SET
            IdUsuarioBloqueoOrdenes = NULL,
            FechaBloqueoOrdenes = NULL,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioAccion, UsuarioModificacion)
        WHERE IdRecurso = @IdRecurso
          AND RowStatus = 1;

        RETURN;
    END;

    UPDATE dbo.Recursos
    SET
        IdUsuarioBloqueoOrdenes = @IdUsuarioPrimeraOrden,
        FechaBloqueoOrdenes = COALESCE(FechaBloqueoOrdenes, GETDATE()),
        FechaModificacion = GETDATE(),
        UsuarioModificacion = COALESCE(@UsuarioAccion, UsuarioModificacion)
    WHERE IdRecurso = @IdRecurso
      AND RowStatus = 1;
END;
GO
