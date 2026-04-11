SET NOCOUNT ON;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.spInvMovimientosProducto', 'P') IS NOT NULL
BEGIN
  DROP PROCEDURE dbo.spInvMovimientosProducto;
END
GO

CREATE OR ALTER PROCEDURE dbo.spInvMovimientos
  @IdProducto INT,
  @IdAlmacen INT = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF ISNULL(@IdProducto, 0) <= 0
    THROW 50120, 'Debe enviar @IdProducto.', 1;

  SELECT
    m.IdMovimiento,
    m.Fecha,
    m.TipoMovimiento,
    m.NumeroDocumento,
    ISNULL(m.Observacion, '') AS Observacion,
    CASE WHEN m.Signo = 1 THEN m.Cantidad ELSE 0 END AS Entrada,
    CASE WHEN m.Signo = -1 THEN m.Cantidad ELSE 0 END AS Salida,
    m.CostoUnitario,
    m.CostoTotal,
    a.Descripcion AS NombreAlmacen
  FROM dbo.InvMovimientos m
  LEFT JOIN dbo.Almacenes a ON a.IdAlmacen = m.IdAlmacen
  WHERE m.IdProducto = @IdProducto
    AND m.RowStatus = 1
    AND m.TipoMovimiento <> 'ANU'
    AND (@IdAlmacen IS NULL OR m.IdAlmacen = @IdAlmacen)
    AND (@FechaDesde IS NULL OR m.Fecha >= @FechaDesde)
    AND (@FechaHasta IS NULL OR m.Fecha <= @FechaHasta)
  ORDER BY m.Fecha DESC, m.IdMovimiento DESC;
END
GO
