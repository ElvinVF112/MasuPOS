-- ============================================================
-- Script 129: Seed secuencias NCF de prueba (1-100)
-- Una secuencia Madre (Distribución) por cada tipo físico común
-- Una secuencia Hija (Operación) para B01 y B02
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Secuencia Madre B01 - Facturas Crédito Fiscal (1-100)
IF NOT EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 1 AND UsoComprobante = 'D')
  INSERT INTO dbo.SecuenciasNCF
    (IdCatalogoNCF, UsoComprobante, Descripcion, Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento, MinimoParaAlertar, Activo)
  VALUES
    (1, 'D', N'B01 - Facturas Crédito Fiscal (Madre)', 'B01', 1, 100, 0, '2025-12-31', 10, 1)

-- Secuencia Madre B02 - Facturas Consumo (1-100)
IF NOT EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 2 AND UsoComprobante = 'D')
  INSERT INTO dbo.SecuenciasNCF
    (IdCatalogoNCF, UsoComprobante, Descripcion, Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento, MinimoParaAlertar, Activo)
  VALUES
    (2, 'D', N'B02 - Facturas Consumo (Madre)', 'B02', 1, 100, 0, '2025-12-31', 10, 1)

-- Secuencia Madre B11 - Notas de Débito (1-100)
IF NOT EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 3 AND UsoComprobante = 'D')
  INSERT INTO dbo.SecuenciasNCF
    (IdCatalogoNCF, UsoComprobante, Descripcion, Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento, MinimoParaAlertar, Activo)
  VALUES
    (3, 'D', N'B11 - Notas de Débito (Madre)', 'B11', 1, 100, 0, '2025-12-31', 10, 1)

GO

-- Secuencia Hija B01 - Operación (toma de la madre B01)
DECLARE @MadreB01 INT = (SELECT TOP 1 IdSecuencia FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 1 AND UsoComprobante = 'D' AND RowStatus = 1)

IF @MadreB01 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 1 AND UsoComprobante = 'O')
  INSERT INTO dbo.SecuenciasNCF
    (IdCatalogoNCF, IdSecuenciaMadre, UsoComprobante, Descripcion, Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento, MinimoParaAlertar, RellenoAutomatico, Activo)
  VALUES
    (1, @MadreB01, 'O', N'B01 - Facturas Crédito Fiscal (Operación)', 'B01', 1, 50, 0, '2025-12-31', 5, 20, 1)

-- Secuencia Hija B02 - Operación (toma de la madre B02)
DECLARE @MadreB02 INT = (SELECT TOP 1 IdSecuencia FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 2 AND UsoComprobante = 'D' AND RowStatus = 1)

IF @MadreB02 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdCatalogoNCF = 2 AND UsoComprobante = 'O')
  INSERT INTO dbo.SecuenciasNCF
    (IdCatalogoNCF, IdSecuenciaMadre, UsoComprobante, Descripcion, Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento, MinimoParaAlertar, RellenoAutomatico, Activo)
  VALUES
    (2, @MadreB02, 'O', N'B02 - Facturas Consumo (Operación)', 'B02', 1, 50, 0, '2025-12-31', 5, 20, 1)

GO

SELECT S.IdSecuencia, C.Codigo, S.UsoComprobante, S.Descripcion,
       S.RangoDesde, S.RangoHasta, S.SecuenciaActual,
       S.MinimoParaAlertar, S.RellenoAutomatico, S.IdSecuenciaMadre
FROM   dbo.SecuenciasNCF S
JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
WHERE  S.RowStatus = 1
ORDER  BY C.Codigo, S.UsoComprobante
GO

PRINT '=== Script 129 completado ==='
GO
