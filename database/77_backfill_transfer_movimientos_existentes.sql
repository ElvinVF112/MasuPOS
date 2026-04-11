SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

;WITH TransferBase AS (
  SELECT
    D.IdDocumento,
    D.NumeroDocumento,
    D.Periodo,
    D.Observacion,
    D.IdAlmacen AS IdAlmacenOrigen,
    T.IdAlmacenDestino,
    T.IdAlmacenTransito,
    T.EstadoTransferencia,
    CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE) AS FechaSalidaMov,
    CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE) AS FechaRecepcionMov
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  WHERE D.RowStatus = 1
    AND T.RowStatus = 1
    AND D.TipoOperacion = 'T'
    AND T.EstadoTransferencia IN ('T', 'C')
),
TransferDetalle AS (
  SELECT
    TB.IdDocumento,
    TB.NumeroDocumento,
    TB.Periodo,
    TB.Observacion,
    TB.IdAlmacenOrigen,
    TB.IdAlmacenDestino,
    TB.IdAlmacenTransito,
    TB.EstadoTransferencia,
    TB.FechaSalidaMov,
    TB.FechaRecepcionMov,
    DET.IdProducto,
    SUM(dbo.fnInvCantidadABase(DET.IdProducto, DET.IdUnidadMedida, DET.Cantidad)) AS Cantidad,
    MAX(DET.Costo) AS Costo
  FROM TransferBase TB
  INNER JOIN dbo.InvDocumentoDetalle DET ON DET.IdDocumento = TB.IdDocumento AND DET.RowStatus = 1
  GROUP BY
    TB.IdDocumento, TB.NumeroDocumento, TB.Periodo, TB.Observacion,
    TB.IdAlmacenOrigen, TB.IdAlmacenDestino, TB.IdAlmacenTransito,
    TB.EstadoTransferencia, TB.FechaSalidaMov, TB.FechaRecepcionMov, DET.IdProducto
)
INSERT INTO dbo.InvMovimientos (
  IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
  NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
  CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
)
SELECT
  TD.IdProducto,
  TD.IdAlmacenOrigen,
  'SAL',
  -1,
  TD.IdDocumento,
  'TRF',
  TD.NumeroDocumento,
  NULL,
  TD.Cantidad,
  TD.Costo,
  ROUND(TD.Cantidad * TD.Costo, 4),
  ISNULL(PAO.Cantidad, 0) + TD.Cantidad,
  ISNULL(PAO.Cantidad, 0),
  P.CostoPromedio,
  P.CostoPromedio,
  TD.FechaSalidaMov,
  TD.Periodo,
  CONCAT('Salida por transferencia hacia transito. ', ISNULL(TD.Observacion, '')),
  1,
  GETDATE(),
  1
FROM TransferDetalle TD
INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
LEFT JOIN dbo.ProductoAlmacenes PAO ON PAO.IdProducto = TD.IdProducto AND PAO.IdAlmacen = TD.IdAlmacenOrigen AND PAO.RowStatus = 1
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.InvMovimientos M
  WHERE M.IdDocumentoOrigen = TD.IdDocumento
    AND M.IdProducto = TD.IdProducto
    AND M.IdAlmacen = TD.IdAlmacenOrigen
    AND M.TipoMovimiento = 'SAL'
    AND M.Signo = -1
    AND M.RowStatus = 1
);
GO

;WITH TransferBase AS (
  SELECT
    D.IdDocumento,
    D.NumeroDocumento,
    D.Periodo,
    D.Observacion,
    D.IdAlmacen AS IdAlmacenOrigen,
    T.IdAlmacenDestino,
    T.IdAlmacenTransito,
    T.EstadoTransferencia,
    CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE) AS FechaSalidaMov,
    CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE) AS FechaRecepcionMov
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  WHERE D.RowStatus = 1
    AND T.RowStatus = 1
    AND D.TipoOperacion = 'T'
    AND T.EstadoTransferencia IN ('T', 'C')
),
TransferDetalle AS (
  SELECT
    TB.IdDocumento,
    TB.NumeroDocumento,
    TB.Periodo,
    TB.Observacion,
    TB.IdAlmacenOrigen,
    TB.IdAlmacenDestino,
    TB.IdAlmacenTransito,
    TB.EstadoTransferencia,
    TB.FechaSalidaMov,
    TB.FechaRecepcionMov,
    DET.IdProducto,
    SUM(dbo.fnInvCantidadABase(DET.IdProducto, DET.IdUnidadMedida, DET.Cantidad)) AS Cantidad,
    MAX(DET.Costo) AS Costo
  FROM TransferBase TB
  INNER JOIN dbo.InvDocumentoDetalle DET ON DET.IdDocumento = TB.IdDocumento AND DET.RowStatus = 1
  GROUP BY
    TB.IdDocumento, TB.NumeroDocumento, TB.Periodo, TB.Observacion,
    TB.IdAlmacenOrigen, TB.IdAlmacenDestino, TB.IdAlmacenTransito,
    TB.EstadoTransferencia, TB.FechaSalidaMov, TB.FechaRecepcionMov, DET.IdProducto
)
INSERT INTO dbo.InvMovimientos (
  IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
  NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
  CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
)
SELECT
  TD.IdProducto,
  TD.IdAlmacenTransito,
  'ENT',
  1,
  TD.IdDocumento,
  'TRF',
  TD.NumeroDocumento,
  NULL,
  TD.Cantidad,
  TD.Costo,
  ROUND(TD.Cantidad * TD.Costo, 4),
  CASE WHEN TD.EstadoTransferencia = 'C' THEN 0 ELSE ISNULL(PAT.Cantidad, 0) - TD.Cantidad END,
  CASE WHEN TD.EstadoTransferencia = 'C' THEN TD.Cantidad ELSE ISNULL(PAT.Cantidad, 0) END,
  P.CostoPromedio,
  P.CostoPromedio,
  TD.FechaSalidaMov,
  TD.Periodo,
  CONCAT('Entrada a almacen de transito por transferencia. ', ISNULL(TD.Observacion, '')),
  1,
  GETDATE(),
  1
FROM TransferDetalle TD
INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
LEFT JOIN dbo.ProductoAlmacenes PAT ON PAT.IdProducto = TD.IdProducto AND PAT.IdAlmacen = TD.IdAlmacenTransito AND PAT.RowStatus = 1
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.InvMovimientos M
  WHERE M.IdDocumentoOrigen = TD.IdDocumento
    AND M.IdProducto = TD.IdProducto
    AND M.IdAlmacen = TD.IdAlmacenTransito
    AND M.TipoMovimiento = 'ENT'
    AND M.Signo = 1
    AND M.RowStatus = 1
);
GO

;WITH TransferBase AS (
  SELECT
    D.IdDocumento,
    D.NumeroDocumento,
    D.Periodo,
    D.Observacion,
    D.IdAlmacen AS IdAlmacenOrigen,
    T.IdAlmacenDestino,
    T.IdAlmacenTransito,
    T.EstadoTransferencia,
    CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE) AS FechaSalidaMov,
    CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE) AS FechaRecepcionMov
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  WHERE D.RowStatus = 1
    AND T.RowStatus = 1
    AND D.TipoOperacion = 'T'
    AND T.EstadoTransferencia = 'C'
),
TransferDetalle AS (
  SELECT
    TB.IdDocumento,
    TB.NumeroDocumento,
    TB.Periodo,
    TB.Observacion,
    TB.IdAlmacenOrigen,
    TB.IdAlmacenDestino,
    TB.IdAlmacenTransito,
    TB.EstadoTransferencia,
    TB.FechaSalidaMov,
    TB.FechaRecepcionMov,
    DET.IdProducto,
    SUM(dbo.fnInvCantidadABase(DET.IdProducto, DET.IdUnidadMedida, DET.Cantidad)) AS Cantidad,
    MAX(DET.Costo) AS Costo
  FROM TransferBase TB
  INNER JOIN dbo.InvDocumentoDetalle DET ON DET.IdDocumento = TB.IdDocumento AND DET.RowStatus = 1
  GROUP BY
    TB.IdDocumento, TB.NumeroDocumento, TB.Periodo, TB.Observacion,
    TB.IdAlmacenOrigen, TB.IdAlmacenDestino, TB.IdAlmacenTransito,
    TB.EstadoTransferencia, TB.FechaSalidaMov, TB.FechaRecepcionMov, DET.IdProducto
)
INSERT INTO dbo.InvMovimientos (
  IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
  NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
  CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
)
SELECT
  TD.IdProducto,
  TD.IdAlmacenTransito,
  'SAL',
  -1,
  TD.IdDocumento,
  'TRF',
  TD.NumeroDocumento,
  NULL,
  TD.Cantidad,
  TD.Costo,
  ROUND(TD.Cantidad * TD.Costo, 4),
  TD.Cantidad,
  0,
  P.CostoPromedio,
  P.CostoPromedio,
  TD.FechaRecepcionMov,
  TD.Periodo,
  CONCAT('Salida de almacen de transito por recepcion de transferencia. ', ISNULL(TD.Observacion, '')),
  1,
  GETDATE(),
  1
FROM TransferDetalle TD
INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.InvMovimientos M
  WHERE M.IdDocumentoOrigen = TD.IdDocumento
    AND M.IdProducto = TD.IdProducto
    AND M.IdAlmacen = TD.IdAlmacenTransito
    AND M.TipoMovimiento = 'SAL'
    AND M.Signo = -1
    AND M.RowStatus = 1
);
GO

;WITH TransferBase AS (
  SELECT
    D.IdDocumento,
    D.NumeroDocumento,
    D.Periodo,
    D.Observacion,
    D.IdAlmacen AS IdAlmacenOrigen,
    T.IdAlmacenDestino,
    T.IdAlmacenTransito,
    T.EstadoTransferencia,
    CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE) AS FechaSalidaMov,
    CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE) AS FechaRecepcionMov
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  WHERE D.RowStatus = 1
    AND T.RowStatus = 1
    AND D.TipoOperacion = 'T'
    AND T.EstadoTransferencia = 'C'
),
TransferDetalle AS (
  SELECT
    TB.IdDocumento,
    TB.NumeroDocumento,
    TB.Periodo,
    TB.Observacion,
    TB.IdAlmacenOrigen,
    TB.IdAlmacenDestino,
    TB.IdAlmacenTransito,
    TB.EstadoTransferencia,
    TB.FechaSalidaMov,
    TB.FechaRecepcionMov,
    DET.IdProducto,
    SUM(dbo.fnInvCantidadABase(DET.IdProducto, DET.IdUnidadMedida, DET.Cantidad)) AS Cantidad,
    MAX(DET.Costo) AS Costo
  FROM TransferBase TB
  INNER JOIN dbo.InvDocumentoDetalle DET ON DET.IdDocumento = TB.IdDocumento AND DET.RowStatus = 1
  GROUP BY
    TB.IdDocumento, TB.NumeroDocumento, TB.Periodo, TB.Observacion,
    TB.IdAlmacenOrigen, TB.IdAlmacenDestino, TB.IdAlmacenTransito,
    TB.EstadoTransferencia, TB.FechaSalidaMov, TB.FechaRecepcionMov, DET.IdProducto
)
INSERT INTO dbo.InvMovimientos (
  IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
  NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
  CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
)
SELECT
  TD.IdProducto,
  TD.IdAlmacenDestino,
  'ENT',
  1,
  TD.IdDocumento,
  'TRF',
  TD.NumeroDocumento,
  NULL,
  TD.Cantidad,
  TD.Costo,
  ROUND(TD.Cantidad * TD.Costo, 4),
  ISNULL(PAD.Cantidad, 0) - TD.Cantidad,
  ISNULL(PAD.Cantidad, 0),
  P.CostoPromedio,
  P.CostoPromedio,
  TD.FechaRecepcionMov,
  TD.Periodo,
  CONCAT('Entrada al almacen destino por recepcion de transferencia. ', ISNULL(TD.Observacion, '')),
  1,
  GETDATE(),
  1
FROM TransferDetalle TD
INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
LEFT JOIN dbo.ProductoAlmacenes PAD ON PAD.IdProducto = TD.IdProducto AND PAD.IdAlmacen = TD.IdAlmacenDestino AND PAD.RowStatus = 1
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.InvMovimientos M
  WHERE M.IdDocumentoOrigen = TD.IdDocumento
    AND M.IdProducto = TD.IdProducto
    AND M.IdAlmacen = TD.IdAlmacenDestino
    AND M.TipoMovimiento = 'ENT'
    AND M.Signo = 1
    AND M.RowStatus = 1
);
GO

SELECT
  D.NumeroDocumento,
  T.EstadoTransferencia,
  COUNT(M.IdMovimiento) AS MovimientosCreados
FROM dbo.InvDocumentos D
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
LEFT JOIN dbo.InvMovimientos M ON M.IdDocumentoOrigen = D.IdDocumento AND M.RowStatus = 1
WHERE D.TipoOperacion = 'T'
GROUP BY D.NumeroDocumento, T.EstadoTransferencia
ORDER BY D.NumeroDocumento;
GO
