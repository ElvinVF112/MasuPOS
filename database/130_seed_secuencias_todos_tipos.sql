-- ============================================================
-- Script 130: Seed secuencias NCF Madre (1-100) para cada tipo
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @tipos TABLE (IdCatalogoNCF INT, Prefijo NVARCHAR(10))
INSERT INTO @tipos VALUES
  (1,  'B01'), (2,  'B02'), (3,  'B11'), (4,  'B14'),
  (5,  'B15'), (6,  'B16'), (7,  'B17'),
  (8,  'E31'), (9,  'E32'), (10, 'E33'), (11, 'E34'),
  (12, 'E41'), (13, 'E43'), (14, 'E44'), (15, 'E45'),
  (16, 'E46'), (17, 'E47')

INSERT INTO dbo.SecuenciasNCF
  (IdCatalogoNCF, UsoComprobante, Descripcion, Prefijo,
   RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento,
   MinimoParaAlertar, Activo)
SELECT
  T.IdCatalogoNCF,
  'D',
  C.Codigo + N' - ' + C.Nombre + N' (Madre)',
  T.Prefijo,
  1, 100, 0,
  '2025-12-31',
  10, 1
FROM @tipos T
JOIN dbo.CatalogoNCF C ON C.IdCatalogoNCF = T.IdCatalogoNCF
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.SecuenciasNCF S
  WHERE S.IdCatalogoNCF = T.IdCatalogoNCF
    AND S.UsoComprobante = 'D'
    AND S.RowStatus = 1
)

SELECT COUNT(*) AS InsertedMadres FROM dbo.SecuenciasNCF WHERE UsoComprobante = 'D' AND RowStatus = 1
GO

SELECT S.IdSecuencia, C.Codigo, S.UsoComprobante, S.Descripcion,
       S.RangoDesde, S.RangoHasta, S.FechaVencimiento
FROM   dbo.SecuenciasNCF S
JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
WHERE  S.RowStatus = 1
ORDER  BY C.Codigo, S.UsoComprobante
GO

PRINT '=== Script 130 completado ==='
GO
