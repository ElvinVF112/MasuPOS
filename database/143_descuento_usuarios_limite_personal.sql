-- ============================================================
-- Script 143: LimiteDescuentoManual por usuario en DescuentoUsuarios
-- Permite sobreescribir el límite global del descuento por usuario específico
-- ============================================================

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.DescuentoUsuarios') AND name = 'LimiteDescuentoManual'
)
BEGIN
  ALTER TABLE dbo.DescuentoUsuarios ADD LimiteDescuentoManual DECIMAL(5,2) NULL
  PRINT 'Columna LimiteDescuentoManual agregada a DescuentoUsuarios.'
END
ELSE
  PRINT 'Columna LimiteDescuentoManual ya existe en DescuentoUsuarios.'
GO

-- Actualizar SP spDescuentoUsuarios para incluir LimiteDescuentoManual
-- en lecturas y permitir actualización
IF OBJECT_ID('dbo.spDescuentoUsuarios', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spDescuentoUsuarios
GO

CREATE PROCEDURE dbo.spDescuentoUsuarios
  @Accion                NVARCHAR(5),
  @IdDescuento           INT            = NULL,
  @IdUsuario             INT            = NULL,
  @LimiteDescuentoManual DECIMAL(5,2)   = NULL
AS
BEGIN
  SET NOCOUNT ON

  -- LA: Listar usuarios asignados (con su límite personal)
  IF @Accion = 'LA'
  BEGIN
    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos,
           DU.LimiteDescuentoManual
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento
      AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- LD: Listar usuarios disponibles
  IF @Accion = 'LD'
  BEGIN
    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos,
           NULL AS LimiteDescuentoManual
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario
          AND DU.IdDescuento = @IdDescuento
          AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- A: Asignar usuario
  IF @Accion = 'A'
  BEGIN
    IF NOT EXISTS (
      SELECT 1 FROM dbo.DescuentoUsuarios
      WHERE IdDescuento = @IdDescuento AND IdUsuario = @IdUsuario AND RowStatus = 1
    )
    BEGIN
      INSERT INTO dbo.DescuentoUsuarios (IdDescuento, IdUsuario, LimiteDescuentoManual, FechaCreacion)
      VALUES (@IdDescuento, @IdUsuario, @LimiteDescuentoManual, GETDATE())
    END

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, DU.LimiteDescuentoManual
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, NULL AS LimiteDescuentoManual
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- UL: Actualizar límite de un usuario asignado
  IF @Accion = 'UL'
  BEGIN
    UPDATE dbo.DescuentoUsuarios
    SET LimiteDescuentoManual = @LimiteDescuentoManual,
        FechaModificacion = GETDATE()
    WHERE IdDescuento = @IdDescuento AND IdUsuario = @IdUsuario AND RowStatus = 1

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, DU.LimiteDescuentoManual
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, NULL AS LimiteDescuentoManual
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- Q: Quitar usuario
  IF @Accion = 'Q'
  BEGIN
    UPDATE dbo.DescuentoUsuarios
    SET RowStatus = 0, FechaModificacion = GETDATE()
    WHERE IdDescuento = @IdDescuento AND IdUsuario = @IdUsuario AND RowStatus = 1

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, DU.LimiteDescuentoManual
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, NULL AS LimiteDescuentoManual
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- AA: Asignar todos
  IF @Accion = 'AA'
  BEGIN
    INSERT INTO dbo.DescuentoUsuarios (IdDescuento, IdUsuario, FechaCreacion)
    SELECT @IdDescuento, U.IdUsuario, GETDATE()
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, DU.LimiteDescuentoManual
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, NULL AS LimiteDescuentoManual
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- QA: Quitar todos
  IF @Accion = 'QA'
  BEGIN
    UPDATE dbo.DescuentoUsuarios
    SET RowStatus = 0, FechaModificacion = GETDATE()
    WHERE IdDescuento = @IdDescuento AND RowStatus = 1

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, DU.LimiteDescuentoManual
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos, NULL AS LimiteDescuentoManual
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END
END
GO

-- Actualizar SP spDescuentosPorUsuario para devolver el límite personal si existe
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
    -- Límite personal tiene precedencia sobre el del descuento
    COALESCE(DU.LimiteDescuentoManual, D.LimiteDescuentoManual) AS LimiteDescuentoManual
  FROM dbo.Descuentos D
  LEFT JOIN dbo.DescuentoUsuarios DU
    ON DU.IdDescuento = D.IdDescuento
    AND DU.IdUsuario = @IdUsuario
    AND DU.RowStatus = 1
  WHERE D.Activo = 1
    AND D.RowStatus = 1
    AND (D.FechaInicio IS NULL OR D.FechaInicio <= CAST(GETDATE() AS DATE))
    AND (D.FechaFin   IS NULL OR D.FechaFin   >= CAST(GETDATE() AS DATE))
    AND (
      NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU2
        WHERE DU2.IdDescuento = D.IdDescuento AND DU2.RowStatus = 1
      )
      OR
      EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU2
        WHERE DU2.IdDescuento = D.IdDescuento
          AND DU2.IdUsuario = @IdUsuario
          AND DU2.RowStatus = 1
      )
    )
  ORDER BY D.Codigo
END
GO

PRINT 'Script 143 completado.'
GO
