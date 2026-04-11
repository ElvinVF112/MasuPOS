-- ============================================================
-- Script 131: Acciones LP/SP para gestionar puntos de emisión
--             compartidos en secuencias hijas
-- Modifica: dbo.spSecuenciasNCFCRUD
--   LP = Listar puntos asociados a una hija
--   SP = Sincronizar puntos (reemplaza la lista completa)
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spSecuenciasNCFCRUD
  @Accion              NVARCHAR(10)  = 'L',
  @IdSecuencia         INT           = NULL,
  @IdCatalogoNCF       INT           = NULL,
  @IdPuntoEmision      INT           = NULL,
  @IdSecuenciaMadre    INT           = NULL,
  @UsoComprobante      CHAR(1)       = NULL,
  @Descripcion         NVARCHAR(200) = NULL,
  @EsElectronico       BIT           = NULL,
  @DigitosSecuencia    TINYINT       = NULL,
  @Prefijo             NVARCHAR(10)  = NULL,
  @RangoDesde          BIGINT        = NULL,
  @RangoHasta          BIGINT        = NULL,
  @SecuenciaActual     BIGINT        = NULL,
  @FechaVencimiento    DATE          = NULL,
  @ColaPrefijo         NVARCHAR(10)  = NULL,
  @ColaRangoDesde      BIGINT        = NULL,
  @ColaRangoHasta      BIGINT        = NULL,
  @ColaFechaVencimiento DATE         = NULL,
  @MinimoParaAlertar   INT           = NULL,
  @RellenoAutomatico   INT           = NULL,
  @Activo              BIT           = NULL,
  @CantidadDistribuir  BIGINT        = NULL,
  @Observacion         NVARCHAR(300) = NULL,
  @UsuarioAccion       INT           = NULL,
  -- Para SP: lista de IdPuntoEmision separados por coma (ej. '1,3,5')
  @PuntosEmision       NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- ===========================================================
  -- L: Listar todas las secuencias activas
  -- ===========================================================
  IF @Accion = 'L'
  BEGIN
    SELECT S.IdSecuencia, S.IdCatalogoNCF,
           C.Codigo AS CodigoNCF,
           ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
           C.EsElectronico AS CatEsElectronico,
           S.IdPuntoEmision,
           PE.Nombre AS NombrePuntoEmision,
           S.IdSecuenciaMadre,
           SM.Descripcion AS DescripcionMadre,
           S.UsoComprobante, S.Descripcion,
           S.EsElectronico, S.DigitosSecuencia,
           S.Prefijo, S.RangoDesde, S.RangoHasta, S.SecuenciaActual, S.FechaVencimiento,
           S.ColaPrefijo, S.ColaRangoDesde, S.ColaRangoHasta, S.ColaFechaVencimiento,
           S.MinimoParaAlertar, S.RellenoAutomatico,
           S.Agotado, S.Activo AS Activo,
           S.RangoHasta - S.RangoDesde + 1 AS CantidadRegistrada,
           S.FechaCreacion, S.UsuarioCreacion, S.FechaModificacion, S.UsuarioModificacion
    FROM   dbo.SecuenciasNCF S
    JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
    LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = S.IdPuntoEmision
    LEFT JOIN dbo.SecuenciasNCF SM ON SM.IdSecuencia = S.IdSecuenciaMadre
    WHERE  S.RowStatus = 1
    ORDER  BY C.Codigo, S.UsoComprobante, S.IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- O: Obtener una secuencia por ID
  -- ===========================================================
  IF @Accion = 'O'
  BEGIN
    SELECT S.IdSecuencia, S.IdCatalogoNCF,
           C.Codigo AS CodigoNCF,
           ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
           C.EsElectronico AS CatEsElectronico,
           S.IdPuntoEmision,
           PE.Nombre AS NombrePuntoEmision,
           S.IdSecuenciaMadre,
           SM.Descripcion AS DescripcionMadre,
           S.UsoComprobante, S.Descripcion,
           S.EsElectronico, S.DigitosSecuencia,
           S.Prefijo, S.RangoDesde, S.RangoHasta, S.SecuenciaActual, S.FechaVencimiento,
           S.ColaPrefijo, S.ColaRangoDesde, S.ColaRangoHasta, S.ColaFechaVencimiento,
           S.MinimoParaAlertar, S.RellenoAutomatico,
           S.Agotado, S.Activo AS Activo,
           S.RangoHasta - S.RangoDesde + 1 AS CantidadRegistrada,
           S.FechaCreacion, S.UsuarioCreacion, S.FechaModificacion, S.UsuarioModificacion
    FROM   dbo.SecuenciasNCF S
    JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
    LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = S.IdPuntoEmision
    LEFT JOIN dbo.SecuenciasNCF SM ON SM.IdSecuencia = S.IdSecuenciaMadre
    WHERE  S.IdSecuencia = @IdSecuencia AND S.RowStatus = 1
    RETURN
  END

  -- ===========================================================
  -- I: Insertar nueva secuencia
  -- ===========================================================
  IF @Accion = 'I'
  BEGIN
    IF @RangoHasta IS NULL OR @IdCatalogoNCF IS NULL
      THROW 50001, 'IdCatalogoNCF y RangoHasta son obligatorios.', 1

    IF @UsoComprobante = 'O' AND @IdSecuenciaMadre IS NULL
      THROW 50002, 'Una secuencia de Operación requiere IdSecuenciaMadre.', 1

    -- Madres no tienen punto de emisión
    DECLARE @PEFinal INT = CASE WHEN ISNULL(@UsoComprobante,'D') = 'D' THEN NULL ELSE @IdPuntoEmision END

    DECLARE @NewId INT

    INSERT INTO dbo.SecuenciasNCF (
      IdCatalogoNCF, IdPuntoEmision, IdSecuenciaMadre, UsoComprobante, Descripcion,
      EsElectronico, DigitosSecuencia,
      Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento,
      ColaPrefijo, ColaRangoDesde, ColaRangoHasta, ColaFechaVencimiento,
      MinimoParaAlertar, RellenoAutomatico,
      Activo, UsuarioCreacion
    ) VALUES (
      @IdCatalogoNCF, @PEFinal, @IdSecuenciaMadre,
      ISNULL(@UsoComprobante, 'D'), @Descripcion,
      ISNULL(@EsElectronico, 0), ISNULL(@DigitosSecuencia, 8),
      @Prefijo, ISNULL(@RangoDesde, 1), @RangoHasta, ISNULL(@SecuenciaActual, 0), @FechaVencimiento,
      @ColaPrefijo, @ColaRangoDesde, @ColaRangoHasta, @ColaFechaVencimiento,
      ISNULL(@MinimoParaAlertar, 10), @RellenoAutomatico,
      ISNULL(@Activo, 1), @UsuarioAccion
    )

    SET @NewId = SCOPE_IDENTITY()
    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @NewId
    RETURN
  END

  -- ===========================================================
  -- A: Actualizar secuencia
  -- ===========================================================
  IF @Accion = 'A'
  BEGIN
    -- Madres no tienen punto de emisión
    DECLARE @PEUpdate INT = CASE WHEN ISNULL(@UsoComprobante,'D') = 'D' THEN NULL ELSE @IdPuntoEmision END

    UPDATE dbo.SecuenciasNCF
    SET    IdCatalogoNCF       = ISNULL(@IdCatalogoNCF, IdCatalogoNCF),
           IdPuntoEmision      = @PEUpdate,
           IdSecuenciaMadre    = @IdSecuenciaMadre,
           UsoComprobante      = ISNULL(@UsoComprobante, UsoComprobante),
           Descripcion         = ISNULL(@Descripcion, Descripcion),
           EsElectronico       = ISNULL(@EsElectronico, EsElectronico),
           DigitosSecuencia    = ISNULL(@DigitosSecuencia, DigitosSecuencia),
           Prefijo             = @Prefijo,
           RangoDesde          = ISNULL(@RangoDesde, RangoDesde),
           RangoHasta          = ISNULL(@RangoHasta, RangoHasta),
           FechaVencimiento    = @FechaVencimiento,
           ColaPrefijo         = @ColaPrefijo,
           ColaRangoDesde      = @ColaRangoDesde,
           ColaRangoHasta      = @ColaRangoHasta,
           ColaFechaVencimiento= @ColaFechaVencimiento,
           MinimoParaAlertar   = ISNULL(@MinimoParaAlertar, MinimoParaAlertar),
           RellenoAutomatico   = @RellenoAutomatico,
           Activo              = ISNULL(@Activo, Activo),
           FechaModificacion   = GETDATE(),
           UsuarioModificacion = @UsuarioAccion
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- D: Soft-delete
  -- ===========================================================
  IF @Accion = 'D'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdSecuenciaMadre = @IdSecuencia AND RowStatus = 1)
      THROW 50004, 'No se puede eliminar: tiene secuencias hijas asociadas.', 1

    UPDATE dbo.SecuenciasNCF
    SET    RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE  IdSecuencia = @IdSecuencia

    DELETE FROM dbo.SecuenciasNCF_PuntosEmision WHERE IdSecuencia = @IdSecuencia

    SELECT 'OK' AS Resultado
    RETURN
  END

  -- ===========================================================
  -- LP: Listar puntos de emisión de una hija
  -- ===========================================================
  IF @Accion = 'LP'
  BEGIN
    SELECT SP.IdSecuencia, SP.IdPuntoEmision, PE.Nombre AS NombrePuntoEmision
    FROM   dbo.SecuenciasNCF_PuntosEmision SP
    JOIN   dbo.PuntosEmision PE ON PE.IdPuntoEmision = SP.IdPuntoEmision
    WHERE  SP.IdSecuencia = @IdSecuencia
    ORDER  BY PE.Nombre
    RETURN
  END

  -- ===========================================================
  -- SP: Sincronizar puntos de emisión de una hija
  --     @PuntosEmision = CSV de IdPuntoEmision (ej. '1,3,5')
  --     Pasa NULL o '' para limpiar todos
  -- ===========================================================
  IF @Accion = 'SP'
  BEGIN
    IF @IdSecuencia IS NULL
      THROW 50020, 'Se requiere @IdSecuencia.', 1

    -- Verificar que sea hija
    IF NOT EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdSecuencia = @IdSecuencia AND UsoComprobante = 'O' AND RowStatus = 1)
      THROW 50021, 'Solo las secuencias hija (Operación) pueden tener puntos compartidos.', 1

    BEGIN TRANSACTION
    BEGIN TRY
      -- Borrar los existentes
      DELETE FROM dbo.SecuenciasNCF_PuntosEmision WHERE IdSecuencia = @IdSecuencia

      -- Reinsertar si hay lista
      IF @PuntosEmision IS NOT NULL AND LEN(LTRIM(RTRIM(@PuntosEmision))) > 0
      BEGIN
        INSERT INTO dbo.SecuenciasNCF_PuntosEmision (IdSecuencia, IdPuntoEmision, UsuarioCreacion)
        SELECT @IdSecuencia, CAST(value AS INT), @UsuarioAccion
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

    -- Retornar la lista actualizada
    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'LP', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- DIST: Distribución manual madre → hija
  -- ===========================================================
  IF @Accion = 'DIST'
  BEGIN
    IF @IdSecuencia IS NULL OR @IdSecuenciaMadre IS NULL
      THROW 50005, 'Se requiere IdSecuencia (hija) e IdSecuenciaMadre.', 1

    IF @CantidadDistribuir IS NULL OR @CantidadDistribuir <= 0
      THROW 50006, 'La cantidad a distribuir debe ser mayor a cero.', 1

    DECLARE @MadreHasta2 BIGINT, @MadreActual2 BIGINT
    SELECT @MadreHasta2  = RangoHasta,
           @MadreActual2 = SecuenciaActual
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuenciaMadre AND RowStatus = 1

    IF @MadreHasta2 IS NULL
      THROW 50007, 'La secuencia madre no existe o está inactiva.', 1

    DECLARE @DistDesde2 BIGINT, @DistHasta2 BIGINT
    DECLARE @MadreRangoDesde2 BIGINT
    SELECT @MadreRangoDesde2 = RangoDesde FROM dbo.SecuenciasNCF WHERE IdSecuencia = @IdSecuenciaMadre

    IF @MadreActual2 = 0
      SET @DistDesde2 = @MadreRangoDesde2
    ELSE
      SET @DistDesde2 = @MadreActual2 + 1

    SET @DistHasta2 = @DistDesde2 + @CantidadDistribuir - 1

    IF @DistHasta2 > @MadreHasta2
      THROW 50008, 'La cantidad solicitada supera el rango disponible en la madre.', 1

    DECLARE @HijaColaDesde2 BIGINT
    DECLARE @HijaRangoHasta2 BIGINT
    SELECT @HijaRangoHasta2 = RangoHasta,
           @HijaColaDesde2  = ColaRangoDesde
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    IF @HijaRangoHasta2 IS NULL
      THROW 50009, 'La secuencia hija no existe.', 1

    BEGIN TRANSACTION
    BEGIN TRY
      UPDATE dbo.SecuenciasNCF
      SET    SecuenciaActual     = @DistHasta2,
             FechaModificacion   = GETDATE(),
             UsuarioModificacion = @UsuarioAccion
      WHERE  IdSecuencia = @IdSecuenciaMadre

      IF @HijaColaDesde2 IS NULL
      BEGIN
        UPDATE dbo.SecuenciasNCF
        SET    ColaRangoDesde      = @DistDesde2,
               ColaRangoHasta      = @DistHasta2,
               FechaModificacion   = GETDATE(),
               UsuarioModificacion = @UsuarioAccion
        WHERE  IdSecuencia = @IdSecuencia
      END
      ELSE
      BEGIN
        UPDATE dbo.SecuenciasNCF
        SET    ColaRangoHasta      = @DistHasta2,
               FechaModificacion   = GETDATE(),
               UsuarioModificacion = @UsuarioAccion
        WHERE  IdSecuencia = @IdSecuencia
      END

      INSERT INTO dbo.HistorialDistribucionNCF
        (IdSecuenciaMadre, IdSecuenciaHija, CantidadDistribuida, RangoDesde, RangoHasta, UsuarioDistribucion, Observacion, UsuarioCreacion)
      VALUES
        (@IdSecuenciaMadre, @IdSecuencia, @CantidadDistribuir, @DistDesde2, @DistHasta2, @UsuarioAccion, @Observacion, @UsuarioAccion)

      COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
      ROLLBACK TRANSACTION
      THROW
    END CATCH

    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- FILL: Auto-relleno
  -- ===========================================================
  IF @Accion = 'FILL'
  BEGIN
    DECLARE @AutoCantidad INT, @AutoMadre INT

    SELECT @AutoCantidad = RellenoAutomatico,
           @AutoMadre    = IdSecuenciaMadre
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    IF @AutoCantidad IS NULL
      THROW 50010, 'Esta secuencia no tiene relleno automático configurado.', 1

    IF @AutoMadre IS NULL
      THROW 50011, 'Esta secuencia no tiene madre asignada para el relleno.', 1

    EXEC dbo.spSecuenciasNCFCRUD
      @Accion           = 'DIST',
      @IdSecuencia      = @IdSecuencia,
      @IdSecuenciaMadre = @AutoMadre,
      @CantidadDistribuir = @AutoCantidad,
      @Observacion      = N'Relleno automático',
      @UsuarioAccion    = @UsuarioAccion
    RETURN
  END

  -- ===========================================================
  -- SWAP: Promover Cola → En Uso
  -- ===========================================================
  IF @Accion = 'SWAP'
  BEGIN
    DECLARE @ColaDesde BIGINT, @ColaHasta BIGINT, @ColaPref NVARCHAR(10), @ColaFecha DATE

    SELECT @ColaPref  = ColaPrefijo,
           @ColaDesde = ColaRangoDesde,
           @ColaHasta = ColaRangoHasta,
           @ColaFecha = ColaFechaVencimiento
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    IF @ColaDesde IS NULL
      THROW 50012, 'No hay rango En Cola disponible para promover.', 1

    UPDATE dbo.SecuenciasNCF
    SET    Prefijo             = ISNULL(@ColaPref, Prefijo),
           RangoDesde         = @ColaDesde,
           RangoHasta         = @ColaHasta,
           SecuenciaActual    = 0,
           FechaVencimiento   = @ColaFecha,
           ColaPrefijo        = NULL,
           ColaRangoDesde     = NULL,
           ColaRangoHasta     = NULL,
           ColaFechaVencimiento = NULL,
           Agotado            = 0,
           FechaModificacion  = GETDATE(),
           UsuarioModificacion= @UsuarioAccion
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- STATUS: Estadísticas de consumo
  -- ===========================================================
  IF @Accion = 'STATUS'
  BEGIN
    SELECT S.IdSecuencia,
           S.Descripcion,
           ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
           C.Codigo AS CodigoNCF,
           S.RangoDesde, S.RangoHasta, S.SecuenciaActual,
           S.RangoHasta - S.RangoDesde + 1 AS CantidadRegistrada,
           CASE WHEN S.SecuenciaActual = 0 THEN S.RangoHasta - S.RangoDesde + 1
                ELSE S.RangoHasta - S.SecuenciaActual END AS CantidadRestante,
           S.MinimoParaAlertar,
           CASE WHEN (CASE WHEN S.SecuenciaActual = 0 THEN S.RangoHasta - S.RangoDesde + 1
                           ELSE S.RangoHasta - S.SecuenciaActual END) <= S.MinimoParaAlertar
                THEN 1 ELSE 0 END AS EnAlerta,
           S.Agotado,
           S.ColaRangoDesde, S.ColaRangoHasta,
           CASE WHEN S.ColaRangoDesde IS NOT NULL THEN S.ColaRangoHasta - S.ColaRangoDesde + 1 ELSE 0 END AS CantidadEnCola
    FROM   dbo.SecuenciasNCF S
    JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
    WHERE  S.RowStatus = 1 AND S.Activo = 1
      AND  (@IdSecuencia IS NULL OR S.IdSecuencia = @IdSecuencia)
    ORDER  BY EnAlerta DESC, CantidadRestante ASC
    RETURN
  END
END
GO

PRINT '=== Script 131 completado — SP actualizado con acciones LP y SP ==='
GO
