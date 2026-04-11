-- ============================================================
-- Script 141: Agregar LimiteDescuentoManual a Descuentos
-- y SP para obtener descuentos disponibles por usuario
-- ============================================================

-- 1. Columna LimiteDescuentoManual (NULL = sin límite, 0 = no permite manual)
IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.Descuentos') AND name = 'LimiteDescuentoManual'
)
BEGIN
  ALTER TABLE dbo.Descuentos ADD LimiteDescuentoManual DECIMAL(5,2) NULL
  PRINT 'Columna LimiteDescuentoManual agregada.'
END
ELSE
  PRINT 'Columna LimiteDescuentoManual ya existe.'
GO

-- 2. Actualizar SP spDescuentosCRUD para incluir la nueva columna
-- (regenerar completo para que el SP la devuelva en la acción L)
-- Verificamos si existe primero
IF OBJECT_ID('dbo.spDescuentosCRUD', 'P') IS NOT NULL
BEGIN
  EXEC('
  ALTER PROCEDURE dbo.spDescuentosCRUD
    @Accion               NVARCHAR(5)    = NULL,
    @IdDescuento          INT            = NULL,
    @Codigo               VARCHAR(10)    = NULL,
    @Nombre               NVARCHAR(80)   = NULL,
    @Porcentaje           DECIMAL(5,2)   = NULL,
    @EsGlobal             BIT            = NULL,
    @FechaInicio          DATE           = NULL,
    @FechaFin             DATE           = NULL,
    @Activo               BIT            = NULL,
    @LimiteDescuentoManual DECIMAL(5,2)  = NULL,
    @UsuarioCreacion      INT            = NULL,
    @UsuarioModificacion  INT            = NULL,
    @IdSesion             INT            = NULL,
    @TokenSesion          NVARCHAR(128)  = NULL
  AS
  BEGIN
    SET NOCOUNT ON

    IF @Accion = ''L''
    BEGIN
      SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal,
             CONVERT(VARCHAR(10), FechaInicio, 23) AS FechaInicio,
             CONVERT(VARCHAR(10), FechaFin, 23) AS FechaFin,
             Activo, LimiteDescuentoManual
      FROM dbo.Descuentos
      WHERE RowStatus = 1
      ORDER BY Codigo
      RETURN
    END

    IF @Accion = ''I''
    BEGIN
      INSERT INTO dbo.Descuentos
        (Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin, Activo, LimiteDescuentoManual,
         RowStatus, FechaCreacion, UsuarioCreacion)
      VALUES
        (@Codigo, @Nombre, ISNULL(@Porcentaje,0), ISNULL(@EsGlobal,1),
         @FechaInicio, @FechaFin, ISNULL(@Activo,1), @LimiteDescuentoManual,
         1, GETDATE(), @UsuarioCreacion)

      SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal,
             CONVERT(VARCHAR(10), FechaInicio, 23) AS FechaInicio,
             CONVERT(VARCHAR(10), FechaFin, 23) AS FechaFin,
             Activo, LimiteDescuentoManual
      FROM dbo.Descuentos WHERE IdDescuento = SCOPE_IDENTITY()
      RETURN
    END

    IF @Accion = ''A''
    BEGIN
      UPDATE dbo.Descuentos SET
        Codigo = @Codigo,
        Nombre = @Nombre,
        Porcentaje = ISNULL(@Porcentaje, Porcentaje),
        EsGlobal = ISNULL(@EsGlobal, EsGlobal),
        FechaInicio = @FechaInicio,
        FechaFin = @FechaFin,
        Activo = ISNULL(@Activo, Activo),
        LimiteDescuentoManual = @LimiteDescuentoManual,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
      WHERE IdDescuento = @IdDescuento AND RowStatus = 1

      SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal,
             CONVERT(VARCHAR(10), FechaInicio, 23) AS FechaInicio,
             CONVERT(VARCHAR(10), FechaFin, 23) AS FechaFin,
             Activo, LimiteDescuentoManual
      FROM dbo.Descuentos WHERE IdDescuento = @IdDescuento
      RETURN
    END

    IF @Accion = ''D''
    BEGIN
      UPDATE dbo.Descuentos SET
        RowStatus = 0,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
      WHERE IdDescuento = @IdDescuento
      RETURN
    END
  END
  ')
  PRINT 'SP spDescuentosCRUD actualizado.'
END
ELSE
  PRINT 'SP spDescuentosCRUD no existe - crealo manualmente.'
GO

PRINT 'Script 141 completado.'
GO
