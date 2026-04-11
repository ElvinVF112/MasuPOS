-- ============================================================
-- Script 142: SP spDescuentosPorUsuario
-- Devuelve descuentos activos y vigentes disponibles para un usuario:
-- - Sin usuarios asignados = disponible para todos
-- - Con usuarios asignados = solo si el usuario está en la lista
-- ============================================================

IF OBJECT_ID('dbo.spDescuentosPorUsuario', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spDescuentosPorUsuario
GO

CREATE PROCEDURE dbo.spDescuentosPorUsuario
  @IdUsuario INT
AS
BEGIN
  SET NOCOUNT ON

  SELECT
    D.IdDescuento,
    D.Codigo,
    D.Nombre,
    D.Porcentaje,
    D.EsGlobal,
    CONVERT(VARCHAR(10), D.FechaInicio, 23) AS FechaInicio,
    CONVERT(VARCHAR(10), D.FechaFin, 23)    AS FechaFin,
    D.LimiteDescuentoManual
  FROM dbo.Descuentos D
  WHERE D.Activo = 1
    AND D.RowStatus = 1
    -- Vigencia: sin fechas o dentro del rango
    AND (D.FechaInicio IS NULL OR D.FechaInicio <= CAST(GETDATE() AS DATE))
    AND (D.FechaFin   IS NULL OR D.FechaFin   >= CAST(GETDATE() AS DATE))
    AND (
      -- Sin usuarios asignados = aplica a todos
      NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdDescuento = D.IdDescuento AND DU.RowStatus = 1
      )
      OR
      -- Usuario está asignado
      EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdDescuento = D.IdDescuento
          AND DU.IdUsuario = @IdUsuario
          AND DU.RowStatus = 1
      )
    )
  ORDER BY D.Codigo
END
GO

PRINT 'SP spDescuentosPorUsuario creado.'
GO
