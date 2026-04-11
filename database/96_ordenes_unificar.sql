USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 96: unificar ordenes ===';
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesUnificar
  @IdOrdenDestino INT,
  @IdsOrdenOrigenCsv NVARCHAR(MAX),
  @UsuarioAccion INT,
  @TipoUsuario CHAR(1) = 'O'
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @IdOrdenDestino IS NULL OR @IdOrdenDestino <= 0
    THROW 50990, 'Debes seleccionar una orden destino valida.', 1;

  IF NULLIF(LTRIM(RTRIM(ISNULL(@IdsOrdenOrigenCsv, ''))), '') IS NULL
    THROW 50991, 'Debes seleccionar al menos una orden origen.', 1;

  DECLARE @Ids TABLE (IdOrden INT PRIMARY KEY);

  INSERT INTO @Ids (IdOrden)
  SELECT DISTINCT TRY_CAST(LTRIM(RTRIM([value])) AS INT)
  FROM STRING_SPLIT(@IdsOrdenOrigenCsv, ',')
  WHERE TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
    AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) > 0;

  DELETE FROM @Ids WHERE IdOrden = @IdOrdenDestino;

  IF NOT EXISTS (SELECT 1 FROM @Ids)
    THROW 50992, 'Las ordenes origen no son validas.', 1;

  DECLARE
    @IdRecursoDestino INT,
    @IdUsuarioDestino INT,
    @EstadoDestino NVARCHAR(50),
    @ReferenciaDestino NVARCHAR(200),
    @CantidadPersonasDestino INT,
    @NumeroOrdenDestino NVARCHAR(30),
    @IdEstadoAnulada INT;

  SELECT TOP 1
    @IdRecursoDestino = O.IdRecurso,
    @IdUsuarioDestino = O.IdUsuario,
    @EstadoDestino = E.Nombre,
    @ReferenciaDestino = O.ReferenciaCliente,
    @CantidadPersonasDestino = ISNULL(O.CantidadPersonas, 1),
    @NumeroOrdenDestino = O.NumeroOrden
  FROM dbo.Ordenes O
  INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
  WHERE O.IdOrden = @IdOrdenDestino
    AND O.RowStatus = 1
    AND ISNULL(O.Activo, 1) = 1;

  IF @IdRecursoDestino IS NULL
    THROW 50993, 'La orden destino no existe o no esta activa.', 1;

  IF @EstadoDestino NOT IN ('Abierta', 'En proceso', 'Reabierta')
    THROW 50994, 'La orden destino no permite unificacion.', 1;

  IF ISNULL(@TipoUsuario, 'O') NOT IN ('A', 'S')
  BEGIN
    IF @IdUsuarioDestino <> @UsuarioAccion
      THROW 50997, 'Solo puedes unificar ordenes propias.', 1;

    IF EXISTS (
      SELECT 1
      FROM @Ids X
      INNER JOIN dbo.Ordenes O ON O.IdOrden = X.IdOrden
      WHERE O.IdUsuario <> @UsuarioAccion
    )
    BEGIN
      THROW 50998, 'Solo puedes unificar ordenes propias.', 1;
    END;
  END;

  SELECT TOP 1
    @IdEstadoAnulada = IdEstadoOrden
  FROM dbo.EstadosOrden
  WHERE Nombre = 'Anulada'
    AND RowStatus = 1;

  IF @IdEstadoAnulada IS NULL
    THROW 50996, 'No existe el estado Anulada para ordenar la unificacion.', 1;

  IF EXISTS (
    SELECT 1
    FROM @Ids X
    LEFT JOIN dbo.Ordenes O ON O.IdOrden = X.IdOrden
    LEFT JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden IS NULL
      OR O.RowStatus <> 1
      OR ISNULL(O.Activo, 1) <> 1
      OR O.IdRecurso <> @IdRecursoDestino
      OR E.Nombre NOT IN ('Abierta', 'En proceso', 'Reabierta')
  )
  BEGIN
    THROW 50995, 'Solo puedes unificar ordenes activas de la misma mesa.', 1;
  END;

  BEGIN TRANSACTION;

  UPDATE O
  SET
    CantidadPersonas = CASE WHEN ISNULL(O.CantidadPersonas, 1) > @CantidadPersonasDestino THEN O.CantidadPersonas ELSE @CantidadPersonasDestino END
  FROM dbo.Ordenes O
  WHERE O.IdOrden = @IdOrdenDestino;

  UPDATE D
  SET
    IdOrden = @IdOrdenDestino,
    FechaModificacion = GETDATE(),
    UsuarioModificacion = @UsuarioAccion
  FROM dbo.OrdenesDetalle D
  INNER JOIN @Ids X ON X.IdOrden = D.IdOrden
  WHERE D.RowStatus = 1
    AND ISNULL(D.Activo, 1) = 1;

  DECLARE @OrigenId INT;
  DECLARE @OrigenNumero NVARCHAR(30);
  DECLARE @ObservacionDestino NVARCHAR(400);
  DECLARE @ObservacionOrigen NVARCHAR(400);

  DECLARE cursor_origen CURSOR LOCAL FAST_FORWARD FOR
    SELECT O.IdOrden, O.NumeroOrden
    FROM dbo.Ordenes O
    INNER JOIN @Ids X ON X.IdOrden = O.IdOrden
    ORDER BY O.IdOrden;

  OPEN cursor_origen;
  FETCH NEXT FROM cursor_origen INTO @OrigenId, @OrigenNumero;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @ObservacionDestino = CONCAT('Lineas absorbidas desde ', @OrigenNumero);
    SET @ObservacionOrigen = CONCAT('Unificada en orden ', @NumeroOrdenDestino);

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrdenDestino,
      @TipoMovimiento = 'ORDEN_UNIFICADA',
      @EstadoAnterior = @EstadoDestino,
      @EstadoNuevo = @EstadoDestino,
      @Observacion = @ObservacionDestino,
      @UsuarioMovimiento = @UsuarioAccion;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoAnulada,
      Activo = 0,
      Observaciones = CONCAT(
        ISNULL(NULLIF(Observaciones, ''), ''),
        CASE WHEN NULLIF(Observaciones, '') IS NULL THEN '' ELSE ' | ' END,
        'Unificada en orden ',
        @NumeroOrdenDestino
      ),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioAccion
    WHERE IdOrden = @OrigenId
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @OrigenId,
      @TipoMovimiento = 'ORDEN_UNIFICADA',
      @EstadoAnterior = 'Abierta',
      @EstadoNuevo = 'Anulada',
      @Observacion = @ObservacionOrigen,
      @UsuarioMovimiento = @UsuarioAccion;

    FETCH NEXT FROM cursor_origen INTO @OrigenId, @OrigenNumero;
  END;

  CLOSE cursor_origen;
  DEALLOCATE cursor_origen;

  EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrdenDestino;

  COMMIT TRANSACTION;

  EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrdenDestino;
END;
GO
