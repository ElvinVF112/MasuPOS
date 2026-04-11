-- ============================================================
-- 44.5) SP Kardex
-- ============================================================
CREATE   PROCEDURE dbo.spInvKardex
  @IdProducto  INT,
  @IdAlmacen   INT = NULL,
  @FechaDesde  DATE = NULL,
  @FechaHasta  DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    m.IdMovimiento,
    m.Fecha,
    m.TipoMovimiento,
    m.NumeroDocumento,
    m.Observacion,
    CASE WHEN m.Signo = 1 THEN m.Cantidad ELSE 0 END AS Entrada,
    CASE WHEN m.Signo = -1 THEN m.Cantidad ELSE 0 END AS Salida,
    m.SaldoNuevo AS Saldo,
    m.CostoUnitario,
    m.CostoTotal,
    m.CostoPromedioNuevo AS CostoPromedio,
    a.Descripcion AS NombreAlmacen
  FROM dbo.InvMovimientos m
  LEFT JOIN dbo.Almacenes a ON a.IdAlmacen = m.IdAlmacen
  WHERE m.IdProducto = @IdProducto
    AND m.RowStatus = 1
    AND (@IdAlmacen IS NULL OR m.IdAlmacen = @IdAlmacen)
    AND (@FechaDesde IS NULL OR m.Fecha >= @FechaDesde)
    AND (@FechaHasta IS NULL OR m.Fecha <= @FechaHasta)
  ORDER BY m.Fecha, m.IdMovimiento;
END

(1 rows affected)
