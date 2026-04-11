USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 45.1.a) Tabla InvSaldosMensuales
-- ============================================================
IF OBJECT_ID('dbo.InvSaldosMensuales', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.InvSaldosMensuales (
    IdSaldoMensual    INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto        INT NOT NULL REFERENCES dbo.Productos(IdProducto),
    IdAlmacen         INT NOT NULL REFERENCES dbo.Almacenes(IdAlmacen),
    Periodo           VARCHAR(6) NOT NULL,
    SaldoInicial      DECIMAL(18,4) NOT NULL DEFAULT 0,
    Entradas          DECIMAL(18,4) NOT NULL DEFAULT 0,
    Salidas           DECIMAL(18,4) NOT NULL DEFAULT 0,
    SaldoFinal        DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoPromedio     DECIMAL(10,4) NOT NULL DEFAULT 0,
    ValorInventario   DECIMAL(18,4) NOT NULL DEFAULT 0,
    FechaCierre       DATETIME NULL,
    RowStatus         INT NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_InvSaldosMensuales UNIQUE (IdProducto, IdAlmacen, Periodo)
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InvSaldos_Periodo' AND object_id = OBJECT_ID('dbo.InvSaldosMensuales'))
BEGIN
  CREATE INDEX IX_InvSaldos_Periodo ON dbo.InvSaldosMensuales (Periodo)
    INCLUDE (IdProducto, SaldoFinal, ValorInventario);
END
GO

-- ============================================================
-- 45.1.b) Cierre mensual
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spInvCierreMensual
  @Periodo VARCHAR(6)
AS
BEGIN
  SET NOCOUNT ON;

  IF @Periodo IS NULL OR LEN(@Periodo) <> 6 OR TRY_CONVERT(INT, @Periodo) IS NULL
    THROW 50100, 'Periodo invalido. Formato esperado YYYYMM.', 1;

  DECLARE @Anio INT = TRY_CONVERT(INT, LEFT(@Periodo, 4));
  DECLARE @Mes INT = TRY_CONVERT(INT, RIGHT(@Periodo, 2));
  IF @Anio IS NULL OR @Mes IS NULL OR @Mes < 1 OR @Mes > 12
    THROW 50101, 'Periodo invalido. Mes fuera de rango.', 1;

  DECLARE @FechaInicio DATE = DATEFROMPARTS(@Anio, @Mes, 1);
  DECLARE @FechaFin DATE = EOMONTH(@FechaInicio);

  DECLARE @PrevPeriodo VARCHAR(6) = CONVERT(VARCHAR(6), DATEADD(MONTH, -1, @FechaInicio), 112);

  ;WITH Combos AS (
    SELECT DISTINCT m.IdProducto, m.IdAlmacen
    FROM dbo.InvMovimientos m
    WHERE m.RowStatus = 1 AND m.Fecha <= @FechaFin
    UNION
    SELECT DISTINCT s.IdProducto, s.IdAlmacen
    FROM dbo.InvSaldosMensuales s
    WHERE s.RowStatus = 1
  ),
  PrevSaldo AS (
    SELECT s.IdProducto, s.IdAlmacen, s.SaldoFinal, s.CostoPromedio
    FROM dbo.InvSaldosMensuales s
    WHERE s.RowStatus = 1 AND s.Periodo = @PrevPeriodo
  ),
  MovPeriodo AS (
    SELECT
      m.IdProducto,
      m.IdAlmacen,
      SUM(CASE WHEN m.Signo = 1 THEN m.Cantidad ELSE 0 END) AS Entradas,
      SUM(CASE WHEN m.Signo = -1 THEN m.Cantidad ELSE 0 END) AS Salidas,
      MAX(m.IdMovimiento) AS LastMovId
    FROM dbo.InvMovimientos m
    WHERE m.RowStatus = 1
      AND m.Fecha >= @FechaInicio
      AND m.Fecha <= @FechaFin
    GROUP BY m.IdProducto, m.IdAlmacen
  ),
  LastCosto AS (
    SELECT
      m.IdProducto,
      m.IdAlmacen,
      m.CostoPromedioNuevo,
      ROW_NUMBER() OVER (PARTITION BY m.IdProducto, m.IdAlmacen ORDER BY m.Fecha DESC, m.IdMovimiento DESC) AS rn
    FROM dbo.InvMovimientos m
    WHERE m.RowStatus = 1
      AND m.Fecha <= @FechaFin
  ),
  Dataset AS (
    SELECT
      c.IdProducto,
      c.IdAlmacen,
      ISNULL(ps.SaldoFinal, 0) AS SaldoInicial,
      ISNULL(mp.Entradas, 0) AS Entradas,
      ISNULL(mp.Salidas, 0) AS Salidas,
      ISNULL(ps.SaldoFinal, 0) + ISNULL(mp.Entradas, 0) - ISNULL(mp.Salidas, 0) AS SaldoFinal,
      ISNULL(lc.CostoPromedioNuevo, ISNULL(ps.CostoPromedio, 0)) AS CostoPromedio
    FROM Combos c
    LEFT JOIN PrevSaldo ps ON ps.IdProducto = c.IdProducto AND ps.IdAlmacen = c.IdAlmacen
    LEFT JOIN MovPeriodo mp ON mp.IdProducto = c.IdProducto AND mp.IdAlmacen = c.IdAlmacen
    LEFT JOIN LastCosto lc ON lc.IdProducto = c.IdProducto AND lc.IdAlmacen = c.IdAlmacen AND lc.rn = 1
  )
  MERGE dbo.InvSaldosMensuales AS T
  USING (
    SELECT
      d.IdProducto,
      d.IdAlmacen,
      @Periodo AS Periodo,
      d.SaldoInicial,
      d.Entradas,
      d.Salidas,
      d.SaldoFinal,
      d.CostoPromedio,
      ROUND(d.SaldoFinal * d.CostoPromedio, 4) AS ValorInventario,
      GETDATE() AS FechaCierre
    FROM Dataset d
  ) AS S
  ON T.IdProducto = S.IdProducto
   AND T.IdAlmacen = S.IdAlmacen
   AND T.Periodo = S.Periodo
  WHEN MATCHED THEN
    UPDATE SET
      T.SaldoInicial = S.SaldoInicial,
      T.Entradas = S.Entradas,
      T.Salidas = S.Salidas,
      T.SaldoFinal = S.SaldoFinal,
      T.CostoPromedio = S.CostoPromedio,
      T.ValorInventario = S.ValorInventario,
      T.FechaCierre = S.FechaCierre,
      T.RowStatus = 1
  WHEN NOT MATCHED THEN
    INSERT (IdProducto, IdAlmacen, Periodo, SaldoInicial, Entradas, Salidas, SaldoFinal, CostoPromedio, ValorInventario, FechaCierre, RowStatus)
    VALUES (S.IdProducto, S.IdAlmacen, S.Periodo, S.SaldoInicial, S.Entradas, S.Salidas, S.SaldoFinal, S.CostoPromedio, S.ValorInventario, S.FechaCierre, 1);

  SELECT
    @Periodo AS Periodo,
    COUNT(*) AS RegistrosCerrados
  FROM dbo.InvSaldosMensuales
  WHERE Periodo = @Periodo
    AND RowStatus = 1;
END
GO

-- ============================================================
-- 45.1.c) Existencia al fecha
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spInvExistenciaAlFecha
  @Fecha DATE,
  @IdProducto INT = NULL,
  @IdAlmacen INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Fecha IS NULL
    THROW 50110, 'Debe enviar @Fecha.', 1;

  ;WITH Combos AS (
    SELECT DISTINCT m.IdProducto, m.IdAlmacen
    FROM dbo.InvMovimientos m
    WHERE m.RowStatus = 1
      AND m.Fecha <= @Fecha
      AND (@IdProducto IS NULL OR m.IdProducto = @IdProducto)
      AND (@IdAlmacen IS NULL OR m.IdAlmacen = @IdAlmacen)
    UNION
    SELECT DISTINCT s.IdProducto, s.IdAlmacen
    FROM dbo.InvSaldosMensuales s
    WHERE s.RowStatus = 1
      AND (@IdProducto IS NULL OR s.IdProducto = @IdProducto)
      AND (@IdAlmacen IS NULL OR s.IdAlmacen = @IdAlmacen)
  ),
  PrevCierre AS (
    SELECT
      c.IdProducto,
      c.IdAlmacen,
      x.Periodo,
      x.SaldoFinal,
      x.CostoPromedio,
      DATEADD(DAY, 1, EOMONTH(DATEFROMPARTS(TRY_CONVERT(INT, LEFT(x.Periodo, 4)), TRY_CONVERT(INT, RIGHT(x.Periodo, 2)), 1))) AS FechaInicioMov
    FROM Combos c
    OUTER APPLY (
      SELECT TOP 1 s.Periodo, s.SaldoFinal, s.CostoPromedio
      FROM dbo.InvSaldosMensuales s
      WHERE s.RowStatus = 1
        AND s.IdProducto = c.IdProducto
        AND s.IdAlmacen = c.IdAlmacen
        AND s.Periodo < CONVERT(VARCHAR(6), @Fecha, 112)
      ORDER BY s.Periodo DESC
    ) x
  ),
  MovHasta AS (
    SELECT
      c.IdProducto,
      c.IdAlmacen,
      SUM(CASE WHEN m.Signo = 1 THEN m.Cantidad ELSE -m.Cantidad END) AS Delta,
      MAX(m.IdMovimiento) AS LastMovId
    FROM Combos c
    LEFT JOIN PrevCierre pc ON pc.IdProducto = c.IdProducto AND pc.IdAlmacen = c.IdAlmacen
    LEFT JOIN dbo.InvMovimientos m
      ON m.IdProducto = c.IdProducto
     AND m.IdAlmacen = c.IdAlmacen
     AND m.RowStatus = 1
     AND m.Fecha >= ISNULL(pc.FechaInicioMov, '19000101')
     AND m.Fecha <= @Fecha
    GROUP BY c.IdProducto, c.IdAlmacen
  ),
  LastCosto AS (
    SELECT
      m.IdProducto,
      m.IdAlmacen,
      m.CostoPromedioNuevo,
      ROW_NUMBER() OVER (PARTITION BY m.IdProducto, m.IdAlmacen ORDER BY m.Fecha DESC, m.IdMovimiento DESC) AS rn
    FROM dbo.InvMovimientos m
    WHERE m.RowStatus = 1
      AND m.Fecha <= @Fecha
  )
  SELECT
    c.IdProducto,
    p.Nombre AS NombreProducto,
    c.IdAlmacen,
    a.Descripcion AS NombreAlmacen,
    @Fecha AS FechaConsulta,
    ISNULL(pc.SaldoFinal, 0) + ISNULL(mh.Delta, 0) AS Existencia,
    ISNULL(lc.CostoPromedioNuevo, ISNULL(pc.CostoPromedio, 0)) AS CostoPromedio
  FROM Combos c
  LEFT JOIN PrevCierre pc ON pc.IdProducto = c.IdProducto AND pc.IdAlmacen = c.IdAlmacen
  LEFT JOIN MovHasta mh ON mh.IdProducto = c.IdProducto AND mh.IdAlmacen = c.IdAlmacen
  LEFT JOIN LastCosto lc ON lc.IdProducto = c.IdProducto AND lc.IdAlmacen = c.IdAlmacen AND lc.rn = 1
  LEFT JOIN dbo.Productos p ON p.IdProducto = c.IdProducto
  LEFT JOIN dbo.Almacenes a ON a.IdAlmacen = c.IdAlmacen
  ORDER BY p.Nombre, a.Descripcion;
END
GO

PRINT 'Script 59_inv_saldos_mensuales.sql ejecutado correctamente.';
GO
