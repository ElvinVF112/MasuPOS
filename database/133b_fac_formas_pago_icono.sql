-- ============================================================
-- Script 133b: Agrega campo Icono a FacFormasPago y actualiza SP
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FacFormasPago' AND COLUMN_NAME = 'Icono')
  ALTER TABLE dbo.FacFormasPago ADD Icono VARCHAR(30) NULL;
GO

CREATE OR ALTER PROCEDURE dbo.spFacFormasPagoCRUD
  @Accion               NVARCHAR(10)   = 'L',
  @IdFormaPago           INT            = NULL,
  @Descripcion           NVARCHAR(150)  = NULL,
  @Comentario            NVARCHAR(500)  = NULL,
  @TipoValor             VARCHAR(2)     = NULL,
  @TipoValor607          VARCHAR(2)     = NULL,
  @IdMonedaBase          INT            = NULL,
  @IdMonedaOrigen        INT            = NULL,
  @TasaCambioOrigen      DECIMAL(18,6)  = NULL,
  @TasaCambioBase        DECIMAL(18,6)  = NULL,
  @Factor                DECIMAL(18,6)  = NULL,
  @MostrarEnPantallaCobro BIT           = NULL,
  @AutoConsumo           BIT            = NULL,
  @MostrarEnCobrosMixtos BIT            = NULL,
  @AfectaCuadreCaja      BIT            = NULL,
  @Posicion              INT            = NULL,
  @GrupoCierre           NVARCHAR(50)   = NULL,
  @CantidadImpresiones   INT            = NULL,
  @ColorFondo            VARCHAR(7)     = NULL,
  @ColorTexto            VARCHAR(7)     = NULL,
  @Icono                 VARCHAR(30)    = NULL,
  @Activo                BIT            = NULL,
  @UsuarioAccion         INT            = NULL,
  @PuntosEmision         NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT f.IdFormaPago, f.Descripcion, f.Comentario,
           f.TipoValor, f.TipoValor607,
           f.IdMonedaBase, mb.Nombre AS NombreMonedaBase, mb.Simbolo AS SimboloMonedaBase,
           f.IdMonedaOrigen, mo.Nombre AS NombreMonedaOrigen, mo.Simbolo AS SimboloMonedaOrigen,
           f.TasaCambioOrigen, f.TasaCambioBase, f.Factor,
           f.MostrarEnPantallaCobro, f.AutoConsumo, f.MostrarEnCobrosMixtos, f.AfectaCuadreCaja,
           f.Posicion, f.GrupoCierre,
           f.CantidadImpresiones, f.ColorFondo, f.ColorTexto, f.Icono,
           f.Activo,
           f.FechaCreacion, f.UsuarioCreacion, f.FechaModificacion, f.UsuarioModificacion
    FROM   dbo.FacFormasPago f
    LEFT JOIN dbo.Monedas mb ON mb.IdMoneda = f.IdMonedaBase
    LEFT JOIN dbo.Monedas mo ON mo.IdMoneda = f.IdMonedaOrigen
    WHERE  f.RowStatus = 1
    ORDER BY f.Posicion, f.Descripcion
    RETURN
  END

  IF @Accion = 'O'
  BEGIN
    SELECT f.IdFormaPago, f.Descripcion, f.Comentario,
           f.TipoValor, f.TipoValor607,
           f.IdMonedaBase, mb.Nombre AS NombreMonedaBase, mb.Simbolo AS SimboloMonedaBase,
           f.IdMonedaOrigen, mo.Nombre AS NombreMonedaOrigen, mo.Simbolo AS SimboloMonedaOrigen,
           f.TasaCambioOrigen, f.TasaCambioBase, f.Factor,
           f.MostrarEnPantallaCobro, f.AutoConsumo, f.MostrarEnCobrosMixtos, f.AfectaCuadreCaja,
           f.Posicion, f.GrupoCierre,
           f.CantidadImpresiones, f.ColorFondo, f.ColorTexto, f.Icono,
           f.Activo,
           f.FechaCreacion, f.UsuarioCreacion, f.FechaModificacion, f.UsuarioModificacion
    FROM   dbo.FacFormasPago f
    LEFT JOIN dbo.Monedas mb ON mb.IdMoneda = f.IdMonedaBase
    LEFT JOIN dbo.Monedas mo ON mo.IdMoneda = f.IdMonedaOrigen
    WHERE  f.IdFormaPago = @IdFormaPago AND f.RowStatus = 1
    RETURN
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.FacFormasPago (
      Descripcion, Comentario, TipoValor, TipoValor607,
      IdMonedaBase, IdMonedaOrigen, TasaCambioOrigen, TasaCambioBase, Factor,
      MostrarEnPantallaCobro, AutoConsumo, MostrarEnCobrosMixtos, AfectaCuadreCaja,
      Posicion, GrupoCierre, CantidadImpresiones, ColorFondo, ColorTexto, Icono,
      Activo, UsuarioCreacion
    ) VALUES (
      @Descripcion, @Comentario, ISNULL(@TipoValor, 'EF'), @TipoValor607,
      @IdMonedaBase, @IdMonedaOrigen,
      ISNULL(@TasaCambioOrigen, 1), ISNULL(@TasaCambioBase, 1), ISNULL(@Factor, 1),
      ISNULL(@MostrarEnPantallaCobro, 1), ISNULL(@AutoConsumo, 0),
      ISNULL(@MostrarEnCobrosMixtos, 0), ISNULL(@AfectaCuadreCaja, 1),
      ISNULL(@Posicion, 1), @GrupoCierre,
      ISNULL(@CantidadImpresiones, 1), @ColorFondo, @ColorTexto, @Icono,
      ISNULL(@Activo, 1), @UsuarioAccion
    )
    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spFacFormasPagoCRUD @Accion = 'O', @IdFormaPago = @NewId
    RETURN
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.FacFormasPago
    SET    Descripcion           = ISNULL(@Descripcion, Descripcion),
           Comentario            = @Comentario,
           TipoValor             = ISNULL(@TipoValor, TipoValor),
           TipoValor607          = @TipoValor607,
           IdMonedaBase          = @IdMonedaBase,
           IdMonedaOrigen        = @IdMonedaOrigen,
           TasaCambioOrigen      = ISNULL(@TasaCambioOrigen, TasaCambioOrigen),
           TasaCambioBase        = ISNULL(@TasaCambioBase, TasaCambioBase),
           Factor                = ISNULL(@Factor, Factor),
           MostrarEnPantallaCobro = ISNULL(@MostrarEnPantallaCobro, MostrarEnPantallaCobro),
           AutoConsumo           = ISNULL(@AutoConsumo, AutoConsumo),
           MostrarEnCobrosMixtos = ISNULL(@MostrarEnCobrosMixtos, MostrarEnCobrosMixtos),
           AfectaCuadreCaja      = ISNULL(@AfectaCuadreCaja, AfectaCuadreCaja),
           Posicion              = ISNULL(@Posicion, Posicion),
           GrupoCierre           = @GrupoCierre,
           CantidadImpresiones   = ISNULL(@CantidadImpresiones, CantidadImpresiones),
           ColorFondo            = @ColorFondo,
           ColorTexto            = @ColorTexto,
           Icono                 = @Icono,
           Activo                = ISNULL(@Activo, Activo),
           FechaModificacion     = GETDATE(),
           UsuarioModificacion   = @UsuarioAccion
    WHERE  IdFormaPago = @IdFormaPago AND RowStatus = 1
    EXEC dbo.spFacFormasPagoCRUD @Accion = 'O', @IdFormaPago = @IdFormaPago
    RETURN
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacFormasPago SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion WHERE IdFormaPago = @IdFormaPago
    DELETE FROM dbo.FacFormaPagoPuntoEmision WHERE IdFormaPago = @IdFormaPago
    SELECT 'OK' AS Resultado
    RETURN
  END

  IF @Accion = 'LP'
  BEGIN
    SELECT fp.IdFormaPago, fp.IdPuntoEmision, pe.Nombre AS NombrePuntoEmision
    FROM   dbo.FacFormaPagoPuntoEmision fp
    JOIN   dbo.PuntosEmision pe ON pe.IdPuntoEmision = fp.IdPuntoEmision
    WHERE  fp.IdFormaPago = @IdFormaPago
    ORDER  BY pe.Nombre
    RETURN
  END

  IF @Accion = 'SP'
  BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
      DELETE FROM dbo.FacFormaPagoPuntoEmision WHERE IdFormaPago = @IdFormaPago
      IF @PuntosEmision IS NOT NULL AND LEN(LTRIM(RTRIM(@PuntosEmision))) > 0
      BEGIN
        INSERT INTO dbo.FacFormaPagoPuntoEmision (IdFormaPago, IdPuntoEmision, UsuarioCreacion)
        SELECT @IdFormaPago, CAST(value AS INT), @UsuarioAccion
        FROM   STRING_SPLIT(@PuntosEmision, ',')
        WHERE  LTRIM(RTRIM(value)) <> ''
          AND  EXISTS (SELECT 1 FROM dbo.PuntosEmision WHERE IdPuntoEmision = CAST(value AS INT))
      END
      COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
      ROLLBACK TRANSACTION
      THROW
    END CATCH
    EXEC dbo.spFacFormasPagoCRUD @Accion = 'LP', @IdFormaPago = @IdFormaPago
    RETURN
  END
END
GO

PRINT '=== Script 133b completado ==='
GO
