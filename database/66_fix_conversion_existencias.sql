SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '=== Script 66: Fix conversion existencias por almacen ==='
GO

CREATE OR ALTER PROCEDURE dbo.spProductoExistencias
  @IdProducto INT,
  @IdSesion INT = NULL,
  @TokenSesion NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    al.IdAlmacen,
    al.Descripcion AS NombreAlmacen,

    pal.Minimo,
    pal.Maximo,
    pal.PuntoReorden,

    CAST(ISNULL(pa.Cantidad, 0) AS DECIMAL(18,4)) AS Existencia,
    CAST(0 AS DECIMAL(18,4)) AS PendienteRecibir,
    CAST(0 AS DECIMAL(18,4)) AS PendienteEntregar,
    CAST(ISNULL(pa.Cantidad, 0) + ISNULL(pa.CantidadTransito, 0) AS DECIMAL(18,4)) AS ExistenciaReal,
    CAST(ISNULL(pa.CantidadReservada, 0) AS DECIMAL(18,4)) AS Reservado,
    CAST(ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0) AS DECIMAL(18,4)) AS DisponibleBase,

    p.IdUnidadVenta,
    uv.Nombre AS NombreUnidadVenta,
    uv.Abreviatura AS AbreviaturaUnidadVenta,

    p.IdUnidadAlterna1,
    ua1.Nombre AS NombreAlterna1,
    ua1.Abreviatura AS AbreviaturaAlterna1,
    ua1.BaseA AS BaseA1,
    ua1.BaseB AS BaseB1,
    CASE
      WHEN p.IdUnidadAlterna1 IS NULL THEN NULL
      WHEN ISNULL(ua1.BaseA, 0) <= 0 OR ISNULL(ua1.BaseB, 0) <= 0 THEN NULL
      ELSE CAST((ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0)) / (CAST(ua1.BaseB AS DECIMAL(18,6)) / NULLIF(CAST(ua1.BaseA AS DECIMAL(18,6)), 0)) AS DECIMAL(18,4))
    END AS DisponibleAlterna1,

    p.IdUnidadAlterna2,
    ua2.Nombre AS NombreAlterna2,
    ua2.Abreviatura AS AbreviaturaAlterna2,
    ua2.BaseA AS BaseA2,
    ua2.BaseB AS BaseB2,
    CASE
      WHEN p.IdUnidadAlterna2 IS NULL THEN NULL
      WHEN ISNULL(ua2.BaseA, 0) <= 0 OR ISNULL(ua2.BaseB, 0) <= 0 THEN NULL
      ELSE CAST((ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0)) / (CAST(ua2.BaseB AS DECIMAL(18,6)) / NULLIF(CAST(ua2.BaseA AS DECIMAL(18,6)), 0)) AS DECIMAL(18,4))
    END AS DisponibleAlterna2,

    p.IdUnidadAlterna3,
    ua3.Nombre AS NombreAlterna3,
    ua3.Abreviatura AS AbreviaturaAlterna3,
    ua3.BaseA AS BaseA3,
    ua3.BaseB AS BaseB3,
    CASE
      WHEN p.IdUnidadAlterna3 IS NULL THEN NULL
      WHEN ISNULL(ua3.BaseA, 0) <= 0 OR ISNULL(ua3.BaseB, 0) <= 0 THEN NULL
      ELSE CAST((ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0)) / (CAST(ua3.BaseB AS DECIMAL(18,6)) / NULLIF(CAST(ua3.BaseA AS DECIMAL(18,6)), 0)) AS DECIMAL(18,4))
    END AS DisponibleAlterna3
  FROM dbo.ProductoAlmacenes pa
  INNER JOIN dbo.Almacenes al ON al.IdAlmacen = pa.IdAlmacen
  INNER JOIN dbo.Productos p ON p.IdProducto = pa.IdProducto
  LEFT JOIN dbo.ProductoAlmacenesLimites pal
    ON pal.IdProducto = pa.IdProducto
   AND pal.IdAlmacen = pa.IdAlmacen
   AND pal.RowStatus = 1
  LEFT JOIN dbo.UnidadesMedida uv ON uv.IdUnidadMedida = p.IdUnidadVenta
  LEFT JOIN dbo.UnidadesMedida ua1 ON ua1.IdUnidadMedida = p.IdUnidadAlterna1
  LEFT JOIN dbo.UnidadesMedida ua2 ON ua2.IdUnidadMedida = p.IdUnidadAlterna2
  LEFT JOIN dbo.UnidadesMedida ua3 ON ua3.IdUnidadMedida = p.IdUnidadAlterna3
  WHERE pa.IdProducto = @IdProducto
    AND pa.RowStatus = 1
    AND ISNULL(al.RowStatus, 1) = 1
  ORDER BY al.Descripcion ASC;
END
GO

PRINT '=== Script 66 ejecutado correctamente ==='
GO
