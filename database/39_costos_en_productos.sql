-- ============================================================
-- Script 39: Costos de producto → columnas en Productos
-- Elimina tabla ProductoCostos y SP spProductosCostosCRUD.
-- Agrega columnas de costo directamente en dbo.Productos.
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ── 1. Agregar columnas de costo a Productos ─────────────────

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE OBJECT_NAME(object_id) = 'Productos' AND name = 'IdMoneda')
BEGIN
    ALTER TABLE dbo.Productos
        ADD IdMoneda             INT           NULL,
            DescuentoProveedor   DECIMAL(10,4) NOT NULL DEFAULT 0,
            CostoProveedor       DECIMAL(10,4) NOT NULL DEFAULT 0,
            CostoConImpuesto     DECIMAL(10,4) NOT NULL DEFAULT 0,
            CostoPromedio        DECIMAL(10,4) NOT NULL DEFAULT 0,
            PermitirCostoManual  BIT           NOT NULL DEFAULT 0;
    PRINT 'Columnas de costo agregadas a dbo.Productos';
END
ELSE
    PRINT 'Columnas de costo ya existen en dbo.Productos, omitido';
GO

-- FK IdMoneda → Monedas
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Productos_Monedas')
BEGIN
    ALTER TABLE dbo.Productos
        ADD CONSTRAINT FK_Productos_Monedas
            FOREIGN KEY (IdMoneda) REFERENCES dbo.Monedas(IdMoneda);
    PRINT 'FK FK_Productos_Monedas creado';
END
GO

-- ── 2. Migrar datos desde ProductoCostos ─────────────────────

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProductoCostos' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    UPDATE P
    SET P.IdMoneda            = PC.IdMoneda,
        P.DescuentoProveedor  = PC.DescuentoProveedor,
        P.CostoProveedor      = PC.CostoProveedor,
        P.CostoConImpuesto    = PC.CostoConImpuesto,
        P.CostoPromedio       = PC.CostoPromedio,
        P.PermitirCostoManual = PC.PermitirCostoManual
    FROM dbo.Productos P
    INNER JOIN dbo.ProductoCostos PC ON PC.IdProducto = P.IdProducto
    WHERE PC.RowStatus = 1;
    PRINT 'Datos migrados de ProductoCostos a Productos';
END
GO

-- ── 3. Eliminar SP spProductosCostosCRUD ─────────────────────

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'spProductosCostosCRUD' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP PROCEDURE dbo.spProductosCostosCRUD;
    PRINT 'SP spProductosCostosCRUD eliminado';
END
GO

-- ── 4. Eliminar tabla ProductoCostos ─────────────────────────

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProductoCostos' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    ALTER TABLE dbo.ProductoCostos DROP CONSTRAINT IF EXISTS FK_ProductoCostos_Productos;
    ALTER TABLE dbo.ProductoCostos DROP CONSTRAINT IF EXISTS FK_ProductoCostos_Monedas;
    DROP TABLE dbo.ProductoCostos;
    PRINT 'Tabla ProductoCostos eliminada';
END
GO

-- ── 5. Actualizar spProductosCRUD (con columnas de costo) ────

CREATE OR ALTER PROCEDURE dbo.spProductosCRUD
    @Accion                     CHAR(1),
    @IdProducto                 INT           = NULL,
    @IdCategoria                INT           = NULL,
    @IdTipoProducto             INT           = NULL,
    @IdUnidadMedida             INT           = NULL,
    @IdUnidadVenta              INT           = NULL,
    @IdUnidadCompra             INT           = NULL,
    @IdUnidadAlterna1           INT           = NULL,
    @IdUnidadAlterna2           INT           = NULL,
    @IdUnidadAlterna3           INT           = NULL,
    @Nombre                     NVARCHAR(150) = NULL,
    @Descripcion                NVARCHAR(250) = NULL,
    @Activo                     BIT           = NULL,
    -- Impuesto
    @AplicaImpuesto             BIT           = NULL,
    @IdTasaImpuesto             INT           = NULL,
    -- Parámetros operativos
    @UnidadBaseExistencia       NVARCHAR(20)  = NULL,
    @SeVendeEnFactura           BIT           = NULL,
    @PermiteDescuento           BIT           = NULL,
    @PermiteCambioPrecio        BIT           = NULL,
    @PermitePrecioManual        BIT           = NULL,
    @PideUnidad                 BIT           = NULL,
    @PermiteFraccionesDecimales BIT           = NULL,
    @VenderSinExistencia        BIT           = NULL,
    @AplicaPropina              BIT           = NULL,
    @ManejaExistencia           BIT           = NULL,
    -- Costos
    @IdMoneda                   INT           = NULL,
    @DescuentoProveedor         DECIMAL(10,4) = NULL,
    @CostoProveedor             DECIMAL(10,4) = NULL,
    @CostoConImpuesto           DECIMAL(10,4) = NULL,
    @CostoPromedio              DECIMAL(10,4) = NULL,
    @PermitirCostoManual        BIT           = NULL,
    -- Auditoría
    @IdSesion                   BIGINT        = 0,
    @TokenSesion                NVARCHAR(200) = NULL,
    @UsuarioCreacion            INT           = NULL,
    @UsuarioModificacion        INT           = NULL
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
               P.IdMoneda,
               P.DescuentoProveedor,
               P.CostoProveedor,
               P.CostoConImpuesto,
               P.CostoPromedio,
               P.PermitirCostoManual,
               -- Precio de la primera lista (referencia rápida para sidebar)
               ISNULL((SELECT TOP 1 PP.Precio
                        FROM dbo.ProductoPrecios PP
                        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                        ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C    ON C.IdCategoria     = P.IdCategoria
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
               P.IdMoneda,
               P.DescuentoProveedor,
               P.CostoProveedor,
               P.CostoConImpuesto,
               P.CostoPromedio,
               P.PermitirCostoManual,
               ISNULL((SELECT TOP 1 PP.Precio
                        FROM dbo.ProductoPrecios PP
                        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                        ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C    ON C.IdCategoria     = P.IdCategoria
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
             IdMoneda, DescuentoProveedor, CostoProveedor,
             CostoConImpuesto, CostoPromedio, PermitirCostoManual,
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
             @IdMoneda,
             ISNULL(@DescuentoProveedor, 0),
             ISNULL(@CostoProveedor, 0),
             ISNULL(@CostoConImpuesto, 0),
             ISNULL(@CostoPromedio, 0),
             ISNULL(@PermitirCostoManual, 0),
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
            IdMoneda                  = @IdMoneda,
            DescuentoProveedor        = ISNULL(@DescuentoProveedor, DescuentoProveedor),
            CostoProveedor            = ISNULL(@CostoProveedor, CostoProveedor),
            CostoConImpuesto          = ISNULL(@CostoConImpuesto, CostoConImpuesto),
            CostoPromedio             = ISNULL(@CostoPromedio, CostoPromedio),
            PermitirCostoManual       = ISNULL(@PermitirCostoManual, PermitirCostoManual),
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

PRINT '=== Script 39 ejecutado correctamente ===';
GO
