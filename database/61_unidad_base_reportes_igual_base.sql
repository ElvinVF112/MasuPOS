USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

UPDATE dbo.Productos SET UnidadBaseExistencia = 'measure' WHERE ISNULL(UnidadBaseExistencia,'') <> 'measure';
GO

IF COL_LENGTH('dbo.Productos', 'PideUnidadInventario') IS NULL
BEGIN
  ALTER TABLE dbo.Productos ADD PideUnidadInventario BIT NOT NULL CONSTRAINT DF_Productos_PideUnidadInventario DEFAULT (0);
  PRINT 'Columna Productos.PideUnidadInventario creada.';
END
ELSE
BEGIN
  PRINT 'Columna Productos.PideUnidadInventario ya existe.';
END
GO

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
    @AplicaImpuesto             BIT           = NULL,
    @IdTasaImpuesto             INT           = NULL,
    @UnidadBaseExistencia       NVARCHAR(20)  = NULL,
    @SeVendeEnFactura           BIT           = NULL,
    @PermiteDescuento           BIT           = NULL,
    @PermiteCambioPrecio        BIT           = NULL,
    @PermitePrecioManual        BIT           = NULL,
    @PideUnidad                 BIT           = NULL,
    @PideUnidadInventario       BIT           = NULL,
    @PermiteFraccionesDecimales BIT           = NULL,
    @VenderSinExistencia        BIT           = NULL,
    @AplicaPropina              BIT           = NULL,
    @ManejaExistencia           BIT           = NULL,
    @IdMoneda                   INT           = NULL,
    @DescuentoProveedor         DECIMAL(10,4) = NULL,
    @CostoProveedor             DECIMAL(10,4) = NULL,
    @CostoConImpuesto           DECIMAL(10,4) = NULL,
    @CostoPromedio              DECIMAL(10,4) = NULL,
    @PermitirCostoManual        BIT           = NULL,
    @IdSesion                   BIGINT        = 0,
    @TokenSesion                NVARCHAR(200) = NULL,
    @UsuarioCreacion            INT           = NULL,
    @UsuarioModificacion        INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

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
               P.PideUnidadInventario,
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
               ISNULL((SELECT TOP 1 PP.Precio
                        FROM dbo.ProductoPrecios PP
                        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                        ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
        LEFT JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
        WHERE P.RowStatus = 1
        ORDER BY P.Nombre;
        RETURN;
    END;

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
               P.PideUnidadInventario,
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
        INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
        LEFT JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
        WHERE P.IdProducto = @IdProducto;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Productos
            (IdCategoria, IdTipoProducto, IdUnidadMedida,
             IdUnidadVenta, IdUnidadCompra,
             IdUnidadAlterna1, IdUnidadAlterna2, IdUnidadAlterna3,
             Nombre, Descripcion,
             AplicaImpuesto, IdTasaImpuesto,
             UnidadBaseExistencia, SeVendeEnFactura, PermiteDescuento,
             PermiteCambioPrecio, PermitePrecioManual, PideUnidad, PideUnidadInventario,
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
             'measure',
             ISNULL(@SeVendeEnFactura, 1),
             ISNULL(@PermiteDescuento, 1),
             ISNULL(@PermiteCambioPrecio, 1),
             ISNULL(@PermitePrecioManual, 1),
             ISNULL(@PideUnidad, 0),
             ISNULL(@PideUnidadInventario, 0),
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

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Productos
        SET IdCategoria                = @IdCategoria,
            IdTipoProducto             = @IdTipoProducto,
            IdUnidadMedida             = @IdUnidadMedida,
            IdUnidadVenta              = ISNULL(@IdUnidadVenta, @IdUnidadMedida),
            IdUnidadCompra             = ISNULL(@IdUnidadCompra, @IdUnidadMedida),
            IdUnidadAlterna1           = @IdUnidadAlterna1,
            IdUnidadAlterna2           = @IdUnidadAlterna2,
            IdUnidadAlterna3           = @IdUnidadAlterna3,
            Nombre                     = LTRIM(RTRIM(@Nombre)),
            Descripcion                = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            AplicaImpuesto             = ISNULL(@AplicaImpuesto, AplicaImpuesto),
            IdTasaImpuesto             = @IdTasaImpuesto,
            UnidadBaseExistencia       = 'measure',
            SeVendeEnFactura           = ISNULL(@SeVendeEnFactura, SeVendeEnFactura),
            PermiteDescuento           = ISNULL(@PermiteDescuento, PermiteDescuento),
            PermiteCambioPrecio        = ISNULL(@PermiteCambioPrecio, PermiteCambioPrecio),
            PermitePrecioManual        = ISNULL(@PermitePrecioManual, PermitePrecioManual),
            PideUnidad                 = ISNULL(@PideUnidad, PideUnidad),
            PideUnidadInventario       = ISNULL(@PideUnidadInventario, PideUnidadInventario),
            PermiteFraccionesDecimales = ISNULL(@PermiteFraccionesDecimales, PermiteFraccionesDecimales),
            VenderSinExistencia        = ISNULL(@VenderSinExistencia, VenderSinExistencia),
            AplicaPropina              = ISNULL(@AplicaPropina, AplicaPropina),
            ManejaExistencia           = ISNULL(@ManejaExistencia, ManejaExistencia),
            IdMoneda                   = @IdMoneda,
            DescuentoProveedor         = ISNULL(@DescuentoProveedor, DescuentoProveedor),
            CostoProveedor             = ISNULL(@CostoProveedor, CostoProveedor),
            CostoConImpuesto           = ISNULL(@CostoConImpuesto, CostoConImpuesto),
            CostoPromedio              = ISNULL(@CostoPromedio, CostoPromedio),
            PermitirCostoManual        = ISNULL(@PermitirCostoManual, PermitirCostoManual),
            Activo                     = ISNULL(@Activo, Activo),
            FechaModificacion          = GETDATE(),
            UsuarioModificacion        = @UsuarioModificacion
        WHERE IdProducto = @IdProducto;

        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProducto,
             @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

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

CREATE OR ALTER PROCEDURE dbo.spInvBuscarProducto
  @Modo       CHAR(1)       = 'E',
  @Busqueda   NVARCHAR(100) = NULL,
  @IdAlmacen  INT           = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Modo = 'E'
  BEGIN
    SELECT TOP 1
      p.IdProducto,
      p.Codigo,
      p.Nombre,
      p.PideUnidadInventario,
      p.IdUnidadMedida,
      um.Nombre AS NombreUnidad,
      um.Abreviatura AS AbreviaturaUnidad,
      p.IdUnidadVenta,
      um2.Nombre AS NombreUnidadVenta,
      um2.Abreviatura AS AbreviaturaUnidadVenta,
      p.IdUnidadCompra,
      um3.Nombre AS NombreUnidadCompra,
      um3.Abreviatura AS AbreviaturaUnidadCompra,
      p.IdUnidadAlterna1,
      um4.Nombre AS NombreUnidadAlterna1,
      um4.Abreviatura AS AbreviaturaUnidadAlterna1,
      p.IdUnidadAlterna2,
      um5.Nombre AS NombreUnidadAlterna2,
      um5.Abreviatura AS AbreviaturaUnidadAlterna2,
      p.IdUnidadAlterna3,
      um6.Nombre AS NombreUnidadAlterna3,
      um6.Abreviatura AS AbreviaturaUnidadAlterna3,
      p.CostoPromedio,
      p.ManejaExistencia,
      ISNULL(pa.Cantidad, 0) AS Existencia
    FROM dbo.Productos p
    LEFT JOIN dbo.UnidadesMedida um  ON um.IdUnidadMedida = p.IdUnidadMedida
    LEFT JOIN dbo.UnidadesMedida um2 ON um2.IdUnidadMedida = p.IdUnidadVenta
    LEFT JOIN dbo.UnidadesMedida um3 ON um3.IdUnidadMedida = p.IdUnidadCompra
    LEFT JOIN dbo.UnidadesMedida um4 ON um4.IdUnidadMedida = p.IdUnidadAlterna1
    LEFT JOIN dbo.UnidadesMedida um5 ON um5.IdUnidadMedida = p.IdUnidadAlterna2
    LEFT JOIN dbo.UnidadesMedida um6 ON um6.IdUnidadMedida = p.IdUnidadAlterna3
    LEFT JOIN dbo.ProductoAlmacenes pa
      ON pa.IdProducto = p.IdProducto
      AND pa.IdAlmacen = @IdAlmacen
      AND pa.RowStatus = 1
    WHERE p.RowStatus = 1
      AND p.Activo = 1
      AND p.Codigo = @Busqueda;
    RETURN;
  END

  IF @Modo = 'P'
  BEGIN
    SELECT TOP 50
      p.IdProducto,
      p.Codigo,
      p.Nombre,
      p.PideUnidadInventario,
      p.IdUnidadMedida,
      um.Nombre AS NombreUnidad,
      um.Abreviatura AS AbreviaturaUnidad,
      p.IdUnidadVenta,
      um2.Nombre AS NombreUnidadVenta,
      um2.Abreviatura AS AbreviaturaUnidadVenta,
      p.IdUnidadCompra,
      um3.Nombre AS NombreUnidadCompra,
      um3.Abreviatura AS AbreviaturaUnidadCompra,
      p.IdUnidadAlterna1,
      um4.Nombre AS NombreUnidadAlterna1,
      um4.Abreviatura AS AbreviaturaUnidadAlterna1,
      p.IdUnidadAlterna2,
      um5.Nombre AS NombreUnidadAlterna2,
      um5.Abreviatura AS AbreviaturaUnidadAlterna2,
      p.IdUnidadAlterna3,
      um6.Nombre AS NombreUnidadAlterna3,
      um6.Abreviatura AS AbreviaturaUnidadAlterna3,
      p.CostoPromedio,
      p.ManejaExistencia,
      ISNULL(pa.Cantidad, 0) AS Existencia
    FROM dbo.Productos p
    LEFT JOIN dbo.UnidadesMedida um  ON um.IdUnidadMedida = p.IdUnidadMedida
    LEFT JOIN dbo.UnidadesMedida um2 ON um2.IdUnidadMedida = p.IdUnidadVenta
    LEFT JOIN dbo.UnidadesMedida um3 ON um3.IdUnidadMedida = p.IdUnidadCompra
    LEFT JOIN dbo.UnidadesMedida um4 ON um4.IdUnidadMedida = p.IdUnidadAlterna1
    LEFT JOIN dbo.UnidadesMedida um5 ON um5.IdUnidadMedida = p.IdUnidadAlterna2
    LEFT JOIN dbo.UnidadesMedida um6 ON um6.IdUnidadMedida = p.IdUnidadAlterna3
    LEFT JOIN dbo.ProductoAlmacenes pa
      ON pa.IdProducto = p.IdProducto
      AND pa.IdAlmacen = @IdAlmacen
      AND pa.RowStatus = 1
    WHERE p.RowStatus = 1
      AND p.Activo = 1
      AND (
        p.Codigo LIKE '%' + @Busqueda + '%'
        OR p.Nombre LIKE '%' + @Busqueda + '%'
      )
    ORDER BY
      CASE WHEN p.Codigo = @Busqueda THEN 0 ELSE 1 END,
      p.Nombre;
    RETURN;
  END
END;
GO

PRINT 'Script 60_productos_pide_unidad_inventario.sql listo.';
GO

