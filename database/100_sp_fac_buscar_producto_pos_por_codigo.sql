SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spFacBuscarProductoPOSPorCodigo
  @Codigo NVARCHAR(60)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @CodigoNormalizado NVARCHAR(60) = LTRIM(RTRIM(ISNULL(@Codigo, '')));
  IF @CodigoNormalizado = ''
  BEGIN
    SELECT TOP (0)
      CAST(NULL AS INT) AS IdProducto,
      CAST('' AS NVARCHAR(60)) AS Codigo,
      CAST('' AS NVARCHAR(255)) AS Nombre,
      CAST('' AS NVARCHAR(255)) AS Categoria,
      CAST('' AS NVARCHAR(500)) AS Imagen,
      CAST('' AS NVARCHAR(500)) AS CategoriaImagen,
      CAST('#1e3a5f' AS NVARCHAR(20)) AS ColorFondo,
      CAST('#12467e' AS NVARCHAR(20)) AS ColorBoton,
      CAST('#ffffff' AS NVARCHAR(20)) AS ColorTexto,
      CAST('#1e3a5f' AS NVARCHAR(20)) AS ColorFondoItem,
      CAST('#12467e' AS NVARCHAR(20)) AS ColorBotonItem,
      CAST('#ffffff' AS NVARCHAR(20)) AS ColorTextoItem,
      CAST(NULL AS INT) AS IdUnidadVenta,
      CAST('' AS NVARCHAR(120)) AS UnidadVenta,
      CAST(0 AS BIT) AS AplicaImpuesto,
      CAST(0 AS DECIMAL(18, 4)) AS TasaImpuesto,
      CAST(0 AS BIT) AS AplicaPropina,
      CAST(1 AS BIT) AS SeVendeEnFactura,
      CAST(1 AS BIT) AS PermiteDescuento,
      CAST(1 AS BIT) AS PermiteCambioPrecio,
      CAST(0 AS BIT) AS ManejaExistencia,
      CAST(1 AS BIT) AS VenderSinExistencia,
      CAST(0 AS DECIMAL(18, 4)) AS Existencia,
      CAST(0 AS DECIMAL(18, 4)) AS Precio;
    RETURN;
  END;

  DECLARE @TieneCodigoCorto BIT = CASE WHEN COL_LENGTH('dbo.Productos', 'CodigoCorto') IS NULL THEN 0 ELSE 1 END;
  DECLARE @TieneImagenProducto BIT = CASE WHEN COL_LENGTH('dbo.Productos', 'Imagen') IS NULL THEN 0 ELSE 1 END;
  DECLARE @Sql NVARCHAR(MAX) = N'
    SELECT TOP 1
      P.IdProducto,
      ISNULL(P.Codigo, '''') AS Codigo,
      P.Nombre,
      C.Nombre AS Categoria,
      ' + CASE WHEN @TieneImagenProducto = 1 THEN N'ISNULL(P.Imagen, '''')' ELSE N'CAST('''' AS NVARCHAR(500))' END + N' AS Imagen,
      ISNULL(C.Imagen, '''') AS CategoriaImagen,
      ISNULL(C.ColorFondo, ''#1e3a5f'') AS ColorFondo,
      ISNULL(C.ColorBoton, ''#12467e'') AS ColorBoton,
      ISNULL(C.ColorTexto, ''#ffffff'') AS ColorTexto,
      ISNULL(C.ColorFondoItem, ISNULL(C.ColorFondo, ''#1e3a5f'')) AS ColorFondoItem,
      ISNULL(C.ColorBotonItem, ISNULL(C.ColorBoton, ''#12467e'')) AS ColorBotonItem,
      ISNULL(C.ColorTextoItem, ISNULL(C.ColorTexto, ''#ffffff'')) AS ColorTextoItem,
      P.IdUnidadVenta,
      UV.Nombre AS UnidadVenta,
      ISNULL(P.AplicaImpuesto, 0) AS AplicaImpuesto,
      ISNULL(TI.Tasa, 0) AS TasaImpuesto,
      ISNULL(P.AplicaPropina, 0) AS AplicaPropina,
      ISNULL(P.SeVendeEnFactura, 1) AS SeVendeEnFactura,
      ISNULL(P.PermiteDescuento, 1) AS PermiteDescuento,
      ISNULL(P.PermiteCambioPrecio, 1) AS PermiteCambioPrecio,
      ISNULL(P.ManejaExistencia, 0) AS ManejaExistencia,
      ISNULL(P.VenderSinExistencia, 1) AS VenderSinExistencia,
      ISNULL((
        SELECT SUM(ISNULL(pa.Cantidad, 0))
        FROM dbo.ProductoAlmacenes pa
        WHERE pa.IdProducto = P.IdProducto
          AND pa.RowStatus = 1
      ), 0) AS Existencia,
      ISNULL((
        SELECT TOP 1 PP.Precio
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        WHERE PP.IdProducto = P.IdProducto
          AND PP.RowStatus = 1
        ORDER BY LP.IdListaPrecio ASC
      ), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
    LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
    WHERE P.RowStatus = 1
      AND (
        ISNULL(P.Codigo, '''') = @CodigoExacto' + CASE WHEN @TieneCodigoCorto = 1 THEN N'
        OR ISNULL(P.CodigoCorto, '''') = @CodigoExacto' ELSE N'' END + N'
      )
    ORDER BY P.IdProducto;';

  EXEC sp_executesql @Sql, N'@CodigoExacto NVARCHAR(60)', @CodigoExacto = @CodigoNormalizado;
END
GO
