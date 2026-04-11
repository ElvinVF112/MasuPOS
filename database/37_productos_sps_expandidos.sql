-- ============================================================
-- Script 37: Productos - Stored Procedures Expandidos
-- Tarea 25 - Paso 2
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ── 1. spProductosCRUD (expandido) ────────────────────────────

CREATE OR ALTER PROCEDURE dbo.spProductosCRUD
    @Accion                     CHAR(1),
    @IdProducto                 INT          = NULL,
    @IdCategoria                INT          = NULL,
    @IdTipoProducto             INT          = NULL,
    @IdUnidadMedida             INT          = NULL,
    @IdUnidadVenta              INT          = NULL,
    @IdUnidadCompra             INT          = NULL,
    @IdUnidadAlterna1           INT          = NULL,
    @IdUnidadAlterna2           INT          = NULL,
    @IdUnidadAlterna3           INT          = NULL,
    @Nombre                     NVARCHAR(150) = NULL,
    @Descripcion                NVARCHAR(250) = NULL,
    @Activo                     BIT          = NULL,
    -- Impuesto
    @AplicaImpuesto             BIT          = NULL,
    @IdTasaImpuesto             INT          = NULL,
    -- Parámetros operativos
    @UnidadBaseExistencia       NVARCHAR(20) = NULL,
    @SeVendeEnFactura           BIT          = NULL,
    @PermiteDescuento           BIT          = NULL,
    @PermiteCambioPrecio        BIT          = NULL,
    @PermitePrecioManual        BIT          = NULL,
    @PideUnidad                 BIT          = NULL,
    @PermiteFraccionesDecimales BIT          = NULL,
    @VenderSinExistencia        BIT          = NULL,
    @AplicaPropina              BIT          = NULL,
    @ManejaExistencia           BIT          = NULL,
    -- Auditoría
    @IdSesion                   BIGINT       = 0,
    @TokenSesion                NVARCHAR(200) = NULL,
    @UsuarioCreacion            INT          = NULL,
    @UsuarioModificacion        INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ── L: Listar todos ──────────────────────────────────────
    IF @Accion = 'L'
    BEGIN
        SELECT P.IdProducto,
               P.IdCategoria,
               C.Nombre  AS Categoria,
               P.IdTipoProducto,
               TP.Nombre AS TipoProducto,
               P.IdUnidadMedida,
               UB.Nombre AS UnidadBase,
               UB.Abreviatura AS AbreviaturaUnidadBase,
               P.IdUnidadVenta,
               UV.Nombre AS UnidadVenta,
               UV.Abreviatura AS AbreviaturaUnidadVenta,
               P.IdUnidadCompra,
               UC.Nombre AS UnidadCompra,
               UC.Abreviatura AS AbreviaturaUnidadCompra,
               P.IdUnidadAlterna1,
               UA1.Nombre AS UnidadAlterna1,
               P.IdUnidadAlterna2,
               UA2.Nombre AS UnidadAlterna2,
               P.IdUnidadAlterna3,
               UA3.Nombre AS UnidadAlterna3,
               P.Nombre,
               P.Descripcion,
               P.AplicaImpuesto,
               P.IdTasaImpuesto,
               TI.Nombre  AS NombreTasa,
               TI.Tasa    AS TasaImpuesto,
               P.UnidadBaseExistencia,
               P.SeVendeEnFactura,
               P.PermiteDescuento,
               P.PermiteCambioPrecio,
               P.PermitePrecioManual,
               P.PideUnidad,
               P.PermiteFraccionesDecimales,
               P.VenderSinExistencia,
               P.AplicaPropina,
               P.ManejaExistencia,
               P.Activo,
               P.FechaCreacion,
               P.RowStatus,
               -- Precio de la primera lista (referencia rápida para sidebar)
               ISNULL((SELECT TOP 1 PP.Precio
                        FROM dbo.ProductoPrecios PP
                        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                        ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C   ON C.IdCategoria     = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
        LEFT  JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT  JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT  JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        LEFT  JOIN dbo.TasasImpuesto TI   ON TI.IdTasaImpuesto  = P.IdTasaImpuesto
        WHERE P.RowStatus = 1
        ORDER BY P.Nombre;
        RETURN;
    END;

    -- ── O: Obtener uno ───────────────────────────────────────
    IF @Accion = 'O'
    BEGIN
        SELECT P.IdProducto,
               P.IdCategoria,
               C.Nombre  AS Categoria,
               P.IdTipoProducto,
               TP.Nombre AS TipoProducto,
               P.IdUnidadMedida,
               UB.Nombre AS UnidadBase,
               UB.Abreviatura AS AbreviaturaUnidadBase,
               P.IdUnidadVenta,
               UV.Nombre AS UnidadVenta,
               UV.Abreviatura AS AbreviaturaUnidadVenta,
               P.IdUnidadCompra,
               UC.Nombre AS UnidadCompra,
               UC.Abreviatura AS AbreviaturaUnidadCompra,
               P.IdUnidadAlterna1,
               UA1.Nombre AS UnidadAlterna1,
               P.IdUnidadAlterna2,
               UA2.Nombre AS UnidadAlterna2,
               P.IdUnidadAlterna3,
               UA3.Nombre AS UnidadAlterna3,
               P.Nombre,
               P.Descripcion,
               P.AplicaImpuesto,
               P.IdTasaImpuesto,
               TI.Nombre  AS NombreTasa,
               TI.Tasa    AS TasaImpuesto,
               P.UnidadBaseExistencia,
               P.SeVendeEnFactura,
               P.PermiteDescuento,
               P.PermiteCambioPrecio,
               P.PermitePrecioManual,
               P.PideUnidad,
               P.PermiteFraccionesDecimales,
               P.VenderSinExistencia,
               P.AplicaPropina,
               P.ManejaExistencia,
               P.Activo,
               P.FechaCreacion,
               P.RowStatus,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion,
               ISNULL((SELECT TOP 1 PP.Precio
                        FROM dbo.ProductoPrecios PP
                        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                        ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C   ON C.IdCategoria     = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
        LEFT  JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT  JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT  JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        LEFT  JOIN dbo.TasasImpuesto TI   ON TI.IdTasaImpuesto  = P.IdTasaImpuesto
        WHERE P.IdProducto = @IdProducto;
        RETURN;
    END;

    -- ── I: Insertar ──────────────────────────────────────────
    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Productos
            (IdCategoria, IdTipoProducto, IdUnidadMedida,
             IdUnidadVenta, IdUnidadCompra,
             IdUnidadAlterna1, IdUnidadAlterna2, IdUnidadAlterna3,
             Nombre, Descripcion,
             AplicaImpuesto, IdTasaImpuesto,
             UnidadBaseExistencia, SeVendeEnFactura, PermiteDescuento,
             PermiteCambioPrecio, PermitePrecioManual, PideUnidad,
             PermiteFraccionesDecimales, VenderSinExistencia,
             AplicaPropina, ManejaExistencia,
             Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdCategoria, @IdTipoProducto, @IdUnidadMedida,
             ISNULL(@IdUnidadVenta, @IdUnidadMedida),
             ISNULL(@IdUnidadCompra, @IdUnidadMedida),
             @IdUnidadAlterna1, @IdUnidadAlterna2, @IdUnidadAlterna3,
             LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
             ISNULL(@AplicaImpuesto, 0), @IdTasaImpuesto,
             ISNULL(@UnidadBaseExistencia, 'measure'),
             ISNULL(@SeVendeEnFactura, 1),
             ISNULL(@PermiteDescuento, 1),
             ISNULL(@PermiteCambioPrecio, 1),
             ISNULL(@PermitePrecioManual, 1),
             ISNULL(@PideUnidad, 0),
             ISNULL(@PermiteFraccionesDecimales, 0),
             ISNULL(@VenderSinExistencia, 1),
             ISNULL(@AplicaPropina, 0),
             ISNULL(@ManejaExistencia, 1),
             ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        DECLARE @IdProductoNuevo INT = SCOPE_IDENTITY();
        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProductoNuevo,
             @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    -- ── A: Actualizar ────────────────────────────────────────
    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Productos
        SET IdCategoria               = @IdCategoria,
            IdTipoProducto            = @IdTipoProducto,
            IdUnidadMedida            = @IdUnidadMedida,
            IdUnidadVenta             = ISNULL(@IdUnidadVenta, @IdUnidadMedida),
            IdUnidadCompra            = ISNULL(@IdUnidadCompra, @IdUnidadMedida),
            IdUnidadAlterna1          = @IdUnidadAlterna1,
            IdUnidadAlterna2          = @IdUnidadAlterna2,
            IdUnidadAlterna3          = @IdUnidadAlterna3,
            Nombre                    = LTRIM(RTRIM(@Nombre)),
            Descripcion               = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            AplicaImpuesto            = ISNULL(@AplicaImpuesto, AplicaImpuesto),
            IdTasaImpuesto            = @IdTasaImpuesto,
            UnidadBaseExistencia      = ISNULL(@UnidadBaseExistencia, UnidadBaseExistencia),
            SeVendeEnFactura          = ISNULL(@SeVendeEnFactura, SeVendeEnFactura),
            PermiteDescuento          = ISNULL(@PermiteDescuento, PermiteDescuento),
            PermiteCambioPrecio       = ISNULL(@PermiteCambioPrecio, PermiteCambioPrecio),
            PermitePrecioManual       = ISNULL(@PermitePrecioManual, PermitePrecioManual),
            PideUnidad                = ISNULL(@PideUnidad, PideUnidad),
            PermiteFraccionesDecimales = ISNULL(@PermiteFraccionesDecimales, PermiteFraccionesDecimales),
            VenderSinExistencia       = ISNULL(@VenderSinExistencia, VenderSinExistencia),
            AplicaPropina             = ISNULL(@AplicaPropina, AplicaPropina),
            ManejaExistencia          = ISNULL(@ManejaExistencia, ManejaExistencia),
            Activo                    = ISNULL(@Activo, Activo),
            FechaModificacion         = GETDATE(),
            UsuarioModificacion       = @UsuarioModificacion
        WHERE IdProducto = @IdProducto;

        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProducto,
             @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    -- ── D: Eliminar (soft delete) ────────────────────────────
    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Productos
        SET RowStatus           = 0,
            FechaModificacion   = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdProducto = @IdProducto;

        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProducto,
             @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

-- ── 2. spProductosPreciosCRUD ──────────────────────────────────

CREATE OR ALTER PROCEDURE dbo.spProductosPreciosCRUD
    @Accion             CHAR(1),
    @IdProducto         INT          = NULL,
    @IdListaPrecio      INT          = NULL,
    @PorcentajeGanancia DECIMAL(10,4) = NULL,
    @Precio             DECIMAL(10,4) = NULL,
    @Impuesto           DECIMAL(10,4) = NULL,
    @PrecioConImpuesto  DECIMAL(10,4) = NULL,
    @UsuarioCreacion    INT          = NULL,
    @UsuarioModificacion INT         = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- G: Obtener todos los precios de un producto
    IF @Accion = 'G'
    BEGIN
        SELECT PP.IdProductoPrecio,
               PP.IdProducto,
               PP.IdListaPrecio,
               LP.Codigo       AS CodigoLista,
               LP.Descripcion  AS DescripcionLista,
               LP.IdMoneda,
               M.Simbolo       AS SimboloMoneda,
               PP.PorcentajeGanancia,
               PP.Precio,
               PP.Impuesto,
               PP.PrecioConImpuesto,
               PP.RowStatus,
               PP.FechaCreacion,
               PP.FechaModificacion
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        LEFT  JOIN dbo.Monedas M        ON M.IdMoneda       = LP.IdMoneda
        WHERE PP.IdProducto = @IdProducto
          AND PP.RowStatus  = 1
        ORDER BY LP.IdListaPrecio ASC;
        RETURN;
    END;

    -- U: Upsert (insertar o actualizar) un precio
    IF @Accion = 'U'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.ProductoPrecios WHERE IdProducto = @IdProducto AND IdListaPrecio = @IdListaPrecio)
        BEGIN
            UPDATE dbo.ProductoPrecios
            SET PorcentajeGanancia  = ISNULL(@PorcentajeGanancia, PorcentajeGanancia),
                Precio              = ISNULL(@Precio, Precio),
                Impuesto            = ISNULL(@Impuesto, Impuesto),
                PrecioConImpuesto   = ISNULL(@PrecioConImpuesto, PrecioConImpuesto),
                RowStatus           = 1,
                FechaModificacion   = GETDATE(),
                UsuarioModificacion = @UsuarioModificacion
            WHERE IdProducto = @IdProducto AND IdListaPrecio = @IdListaPrecio;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.ProductoPrecios
                (IdProducto, IdListaPrecio, PorcentajeGanancia, Precio, Impuesto, PrecioConImpuesto,
                 RowStatus, FechaCreacion, UsuarioCreacion)
            VALUES
                (@IdProducto, @IdListaPrecio,
                 ISNULL(@PorcentajeGanancia, 0), ISNULL(@Precio, 0),
                 ISNULL(@Impuesto, 0), ISNULL(@PrecioConImpuesto, 0),
                 1, GETDATE(), @UsuarioCreacion);
        END;

        -- Devolver la fila guardada
        SELECT PP.IdProductoPrecio,
               PP.IdProducto,
               PP.IdListaPrecio,
               LP.Codigo      AS CodigoLista,
               LP.Descripcion AS DescripcionLista,
               LP.IdMoneda,
               M.Simbolo      AS SimboloMoneda,
               PP.PorcentajeGanancia,
               PP.Precio,
               PP.Impuesto,
               PP.PrecioConImpuesto,
               PP.RowStatus,
               PP.FechaCreacion,
               PP.FechaModificacion
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        LEFT  JOIN dbo.Monedas M        ON M.IdMoneda       = LP.IdMoneda
        WHERE PP.IdProducto   = @IdProducto
          AND PP.IdListaPrecio = @IdListaPrecio;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida para spProductosPreciosCRUD. Use G o U.', 16, 1);
END;
GO

-- ── 3. spProductosCostosCRUD ───────────────────────────────────

CREATE OR ALTER PROCEDURE dbo.spProductosCostosCRUD
    @Accion              CHAR(1),
    @IdProducto          INT          = NULL,
    @IdMoneda            INT          = NULL,
    @DescuentoProveedor  DECIMAL(10,4) = NULL,
    @CostoProveedor      DECIMAL(10,4) = NULL,
    @CostoConImpuesto    DECIMAL(10,4) = NULL,
    @CostoPromedio       DECIMAL(10,4) = NULL,
    @PermitirCostoManual BIT          = NULL,
    @UsuarioCreacion     INT          = NULL,
    @UsuarioModificacion INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- G: Obtener costos del producto
    IF @Accion = 'G'
    BEGIN
        SELECT PC.IdProductoCosto,
               PC.IdProducto,
               PC.IdMoneda,
               M.Nombre       AS NombreMoneda,
               M.Simbolo      AS SimboloMoneda,
               PC.DescuentoProveedor,
               PC.CostoProveedor,
               PC.CostoConImpuesto,
               PC.CostoPromedio,
               PC.PermitirCostoManual,
               PC.FechaCreacion,
               PC.FechaModificacion
        FROM dbo.ProductoCostos PC
        LEFT  JOIN dbo.Monedas M ON M.IdMoneda = PC.IdMoneda
        WHERE PC.IdProducto = @IdProducto
          AND PC.RowStatus  = 1;
        RETURN;
    END;

    -- U: Upsert costos
    IF @Accion = 'U'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.ProductoCostos WHERE IdProducto = @IdProducto)
        BEGIN
            UPDATE dbo.ProductoCostos
            SET IdMoneda             = ISNULL(@IdMoneda, IdMoneda),
                DescuentoProveedor   = ISNULL(@DescuentoProveedor, DescuentoProveedor),
                CostoProveedor       = ISNULL(@CostoProveedor, CostoProveedor),
                CostoConImpuesto     = ISNULL(@CostoConImpuesto, CostoConImpuesto),
                CostoPromedio        = ISNULL(@CostoPromedio, CostoPromedio),
                PermitirCostoManual  = ISNULL(@PermitirCostoManual, PermitirCostoManual),
                RowStatus            = 1,
                FechaModificacion    = GETDATE(),
                UsuarioModificacion  = @UsuarioModificacion
            WHERE IdProducto = @IdProducto;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.ProductoCostos
                (IdProducto, IdMoneda, DescuentoProveedor, CostoProveedor,
                 CostoConImpuesto, CostoPromedio, PermitirCostoManual,
                 RowStatus, FechaCreacion, UsuarioCreacion)
            VALUES
                (@IdProducto, @IdMoneda,
                 ISNULL(@DescuentoProveedor, 0), ISNULL(@CostoProveedor, 0),
                 ISNULL(@CostoConImpuesto, 0), ISNULL(@CostoPromedio, 0),
                 ISNULL(@PermitirCostoManual, 0),
                 1, GETDATE(), @UsuarioCreacion);
        END;

        SELECT PC.IdProductoCosto,
               PC.IdProducto,
               PC.IdMoneda,
               M.Nombre  AS NombreMoneda,
               M.Simbolo AS SimboloMoneda,
               PC.DescuentoProveedor,
               PC.CostoProveedor,
               PC.CostoConImpuesto,
               PC.CostoPromedio,
               PC.PermitirCostoManual,
               PC.FechaCreacion,
               PC.FechaModificacion
        FROM dbo.ProductoCostos PC
        LEFT JOIN dbo.Monedas M ON M.IdMoneda = PC.IdMoneda
        WHERE PC.IdProducto = @IdProducto AND PC.RowStatus = 1;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida para spProductosCostosCRUD. Use G o U.', 16, 1);
END;
GO

-- ── 4. spProductosOfertasCRUD ──────────────────────────────────

CREATE OR ALTER PROCEDURE dbo.spProductosOfertasCRUD
    @Accion              CHAR(1),
    @IdProducto          INT          = NULL,
    @Activo              BIT          = NULL,
    @PrecioOferta        DECIMAL(10,4) = NULL,
    @FechaInicio         DATE         = NULL,
    @FechaFin            DATE         = NULL,
    @UsuarioCreacion     INT          = NULL,
    @UsuarioModificacion INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- G: Obtener oferta del producto
    IF @Accion = 'G'
    BEGIN
        SELECT IdProductoOferta, IdProducto, Activo, PrecioOferta,
               FechaInicio, FechaFin, FechaCreacion, FechaModificacion
        FROM dbo.ProductoOfertas
        WHERE IdProducto = @IdProducto
          AND RowStatus  = 1;
        RETURN;
    END;

    -- U: Upsert oferta
    IF @Accion = 'U'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.ProductoOfertas WHERE IdProducto = @IdProducto)
        BEGIN
            UPDATE dbo.ProductoOfertas
            SET Activo              = ISNULL(@Activo, Activo),
                PrecioOferta        = ISNULL(@PrecioOferta, PrecioOferta),
                FechaInicio         = @FechaInicio,
                FechaFin            = @FechaFin,
                RowStatus           = 1,
                FechaModificacion   = GETDATE(),
                UsuarioModificacion = @UsuarioModificacion
            WHERE IdProducto = @IdProducto;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.ProductoOfertas
                (IdProducto, Activo, PrecioOferta, FechaInicio, FechaFin,
                 RowStatus, FechaCreacion, UsuarioCreacion)
            VALUES
                (@IdProducto, ISNULL(@Activo, 0), ISNULL(@PrecioOferta, 0),
                 @FechaInicio, @FechaFin,
                 1, GETDATE(), @UsuarioCreacion);
        END;

        SELECT IdProductoOferta, IdProducto, Activo, PrecioOferta,
               FechaInicio, FechaFin, FechaCreacion, FechaModificacion
        FROM dbo.ProductoOfertas
        WHERE IdProducto = @IdProducto AND RowStatus = 1;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida para spProductosOfertasCRUD. Use G o U.', 16, 1);
END;
GO

PRINT '=== Script 37 ejecutado correctamente ===';
GO
