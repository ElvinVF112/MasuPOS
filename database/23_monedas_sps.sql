SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spMonedasCRUD
    @Accion CHAR(1),
    @IdMoneda INT = NULL OUTPUT,
    @Codigo NVARCHAR(5) = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Simbolo NVARCHAR(10) = NULL,
    @SimboloAlt NVARCHAR(10) = NULL,
    @EsLocal BIT = NULL,
    @CodigoBanco NVARCHAR(20) = NULL,
    @FactorConversionLocal DECIMAL(18,6) = NULL,
    @FactorConversionUSD DECIMAL(18,6) = NULL,
    @MostrarEnPOS BIT = NULL,
    @AceptaPagos BIT = NULL,
    @DecimalesPOS INT = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(100) = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- L: Listar todas con ultima tasa
    IF @Accion = 'L'
    BEGIN
        SELECT
            M.IdMoneda,
            M.Codigo,
            M.Nombre,
            M.Simbolo,
            M.SimboloAlt,
            M.EsLocal,
            M.CodigoBanco,
            M.FactorConversionLocal,
            M.FactorConversionUSD,
            M.MostrarEnPOS,
            M.AceptaPagos,
            M.DecimalesPOS,
            M.Activo,
            ISNULL(T.Fecha, CAST(SYSDATETIME() AS DATE)) AS UltimaFechaTasa,
            T.TasaAdministrativa,
            T.TasaOperativa,
            T.TasaCompra,
            T.TasaVenta
        FROM dbo.Monedas M
        LEFT JOIN (
            SELECT MT1.IdMoneda, MT1.Fecha, MT1.TasaAdministrativa, MT1.TasaOperativa,
                   MT1.TasaCompra, MT1.TasaVenta
            FROM dbo.MonedaTasas MT1
            INNER JOIN (
                SELECT IdMoneda, MAX(Fecha) AS MaxFecha
                FROM dbo.MonedaTasas
                GROUP BY IdMoneda
            ) MT2 ON MT1.IdMoneda = MT2.IdMoneda AND MT1.Fecha = MT2.MaxFecha
        ) T ON M.IdMoneda = T.IdMoneda
        WHERE M.RowStatus = 1
        ORDER BY M.EsLocal DESC, M.Codigo;
        RETURN;
    END;

    -- O: Obtener una por ID con ultima tasa
    IF @Accion = 'O'
    BEGIN
        SELECT
            M.IdMoneda,
            M.Codigo,
            M.Nombre,
            M.Simbolo,
            M.SimboloAlt,
            M.EsLocal,
            M.CodigoBanco,
            M.FactorConversionLocal,
            M.FactorConversionUSD,
            M.MostrarEnPOS,
            M.AceptaPagos,
            M.DecimalesPOS,
            M.Activo,
            ISNULL(T.Fecha, CAST(SYSDATETIME() AS DATE)) AS UltimaFechaTasa,
            T.TasaAdministrativa,
            T.TasaOperativa,
            T.TasaCompra,
            T.TasaVenta
        FROM dbo.Monedas M
        LEFT JOIN (
            SELECT MT1.IdMoneda, MT1.Fecha, MT1.TasaAdministrativa, MT1.TasaOperativa,
                   MT1.TasaCompra, MT1.TasaVenta
            FROM dbo.MonedaTasas MT1
            INNER JOIN (
                SELECT IdMoneda, MAX(Fecha) AS MaxFecha
                FROM dbo.MonedaTasas
                GROUP BY IdMoneda
            ) MT2 ON MT1.IdMoneda = MT2.IdMoneda AND MT1.Fecha = MT2.MaxFecha
        ) T ON M.IdMoneda = T.IdMoneda
        WHERE M.IdMoneda = @IdMoneda AND M.RowStatus = 1;
        RETURN;
    END;

    -- A: Actualizar moneda
    IF @Accion = 'A'
    BEGIN
        IF NULLIF(LTRIM(RTRIM(ISNULL(@Nombre, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @Nombre.', 16, 1); RETURN; END;

        UPDATE dbo.Monedas SET
            Nombre                = LTRIM(RTRIM(@Nombre)),
            Simbolo              = NULLIF(LTRIM(RTRIM(ISNULL(@Simbolo,''))), ''),
            SimboloAlt           = NULLIF(LTRIM(RTRIM(ISNULL(@SimboloAlt,''))), ''),
            CodigoBanco          = NULLIF(LTRIM(RTRIM(ISNULL(@CodigoBanco,''))), ''),
            FactorConversionLocal = ISNULL(@FactorConversionLocal, 1),
            FactorConversionUSD   = ISNULL(@FactorConversionUSD, 1),
            MostrarEnPOS         = ISNULL(@MostrarEnPOS, 1),
            AceptaPagos          = ISNULL(@AceptaPagos, 1),
            DecimalesPOS         = ISNULL(@DecimalesPOS, 2),
            Activo               = ISNULL(@Activo, 1),
            FechaModificacion    = SYSDATETIME(),
            UsuarioModificacion  = @UsuarioModificacion
        WHERE IdMoneda = @IdMoneda AND RowStatus = 1;

        SELECT @IdMoneda AS IdMoneda;
        RETURN;
    END;

    -- I: Insertar nueva moneda
    IF @Accion = 'I'
    BEGIN
        IF NULLIF(LTRIM(RTRIM(ISNULL(@Codigo, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @Codigo.', 16, 1); RETURN; END;
        IF NULLIF(LTRIM(RTRIM(ISNULL(@Nombre, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @Nombre.', 16, 1); RETURN; END;
        IF EXISTS (SELECT 1 FROM dbo.Monedas WHERE Codigo = UPPER(LTRIM(RTRIM(@Codigo))) AND RowStatus = 1)
        BEGIN RAISERROR('Ya existe una moneda con ese codigo.', 16, 1); RETURN; END;

        INSERT INTO dbo.Monedas
            (Codigo, Nombre, Simbolo, SimboloAlt, EsLocal, CodigoBanco,
             FactorConversionLocal, FactorConversionUSD, MostrarEnPOS, AceptaPagos, DecimalesPOS, Activo)
        VALUES
            (UPPER(LTRIM(RTRIM(@Codigo))), LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(ISNULL(@Simbolo,''))), ''),
             NULLIF(LTRIM(RTRIM(ISNULL(@SimboloAlt,''))), ''),
             0,
             NULLIF(LTRIM(RTRIM(ISNULL(@CodigoBanco,''))), ''),
             ISNULL(@FactorConversionLocal, 1),
             ISNULL(@FactorConversionUSD, 1),
             ISNULL(@MostrarEnPOS, 1),
             ISNULL(@AceptaPagos, 1),
             ISNULL(@DecimalesPOS, 2),
             1);

        SET @IdMoneda = SCOPE_IDENTITY();
        SELECT @IdMoneda AS IdMoneda;
        RETURN;
    END;

    -- D: Soft delete
    IF @Accion = 'D'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.Monedas WHERE IdMoneda = @IdMoneda AND EsLocal = 1)
        BEGIN RAISERROR('No se puede eliminar la moneda local.', 16, 1); RETURN; END;

        UPDATE dbo.Monedas SET RowStatus = 0 WHERE IdMoneda = @IdMoneda AND RowStatus = 1;
        SELECT @IdMoneda AS IdMoneda;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, A, I o D.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spMonedaTasasGuardar
    @IdMoneda INT,
    @Fecha DATE,
    @TasaAdministrativa DECIMAL(18,6) = NULL,
    @TasaOperativa DECIMAL(18,6) = NULL,
    @TasaCompra DECIMAL(18,6) = NULL,
    @TasaVenta DECIMAL(18,6) = NULL,
    @IdUsuario INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Monedas WHERE IdMoneda = @IdMoneda AND RowStatus = 1)
    BEGIN RAISERROR('Moneda no encontrada.', 16, 1); RETURN; END;

    IF EXISTS (SELECT 1 FROM dbo.MonedaTasas WHERE IdMoneda = @IdMoneda AND Fecha = @Fecha)
    BEGIN
        UPDATE dbo.MonedaTasas SET
            TasaAdministrativa = ISNULL(@TasaAdministrativa, TasaAdministrativa),
            TasaOperativa     = ISNULL(@TasaOperativa, TasaOperativa),
            TasaCompra        = ISNULL(@TasaCompra, TasaCompra),
            TasaVenta         = ISNULL(@TasaVenta, TasaVenta),
            IdUsuario         = ISNULL(@IdUsuario, IdUsuario),
            FechaRegistro      = SYSDATETIME()
        WHERE IdMoneda = @IdMoneda AND Fecha = @Fecha;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.MonedaTasas
            (IdMoneda, Fecha, TasaAdministrativa, TasaOperativa, TasaCompra, TasaVenta, IdUsuario)
        VALUES
            (@IdMoneda, @Fecha,
             ISNULL(@TasaAdministrativa, 0),
             ISNULL(@TasaOperativa, 0),
             ISNULL(@TasaCompra, 0),
             ISNULL(@TasaVenta, 0),
             @IdUsuario);
    END;

    SELECT
        MT.IdTasa, MT.IdMoneda, MT.Fecha, MT.TasaAdministrativa,
        MT.TasaOperativa, MT.TasaCompra, MT.TasaVenta,
        M.Codigo AS CodigoMoneda, M.Nombre AS NombreMoneda
    FROM dbo.MonedaTasas MT
    INNER JOIN dbo.Monedas M ON M.IdMoneda = MT.IdMoneda
    WHERE MT.IdMoneda = @IdMoneda AND MT.Fecha = @Fecha;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spMonedaTasasHistorial
    @IdMoneda INT = NULL,
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @Pagina INT = 1,
    @TamanoPagina INT = 50,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total INT;

    SELECT @Total = COUNT(*)
    FROM dbo.MonedaTasas MT
    INNER JOIN dbo.Monedas M ON M.IdMoneda = MT.IdMoneda
    WHERE M.RowStatus = 1
      AND (@IdMoneda IS NULL OR MT.IdMoneda = @IdMoneda)
      AND (@FechaDesde IS NULL OR MT.Fecha >= @FechaDesde)
      AND (@FechaHasta IS NULL OR MT.Fecha <= @FechaHasta);

    SELECT
        MT.IdTasa,
        MT.IdMoneda,
        M.Codigo AS CodigoMoneda,
        M.Nombre AS NombreMoneda,
        M.Simbolo,
        MT.Fecha,
        MT.TasaAdministrativa,
        MT.TasaOperativa,
        MT.TasaCompra,
        MT.TasaVenta,
        U.NombreUsuario AS UsuarioRegistro,
        MT.FechaRegistro,
        @Total AS TotalRegistros,
        CEILING(CAST(@Total AS FLOAT) / @TamanoPagina) AS TotalPaginas,
        @Pagina AS PaginaActual
    FROM dbo.MonedaTasas MT
    INNER JOIN dbo.Monedas M ON M.IdMoneda = MT.IdMoneda
    LEFT JOIN dbo.Usuarios U ON U.IdUsuario = MT.IdUsuario
    WHERE M.RowStatus = 1
      AND (@IdMoneda IS NULL OR MT.IdMoneda = @IdMoneda)
      AND (@FechaDesde IS NULL OR MT.Fecha >= @FechaDesde)
      AND (@FechaHasta IS NULL OR MT.Fecha <= @FechaHasta)
    ORDER BY MT.Fecha DESC, MT.IdMoneda
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

SELECT 'SPs de monedas creados correctamente' AS Result;
GO
