USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 89: prefijo ORD- en secuencia de ordenes ===';
GO

UPDATE dbo.Ordenes
SET NumeroOrden = 'ORD-' + LTRIM(RTRIM(NumeroOrden))
WHERE RowStatus = 1
  AND NumeroOrden IS NOT NULL
  AND LTRIM(RTRIM(NumeroOrden)) <> ''
  AND NumeroOrden NOT LIKE 'ORD-%';
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesCRUD
  @Accion CHAR(1),
  @IdOrden INT = NULL,
  @IdRecurso INT = NULL,
  @IdEstadoOrden INT = NULL,
  @IdUsuario INT = NULL,
  @ReferenciaCliente VARCHAR(200) = NULL,
  @Observaciones VARCHAR(500) = NULL,
  @Activo BIT = NULL,
  @IdSesion BIGINT = 0,
  @TokenSesion NVARCHAR(200) = NULL,
  @UsuarioCreacion INT = NULL,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT
      O.IdOrden,
      O.NumeroOrden,
      O.IdRecurso,
      R.Nombre AS Recurso,
      O.IdEstadoOrden,
      E.Nombre AS EstadoOrden,
      O.IdUsuario,
      CONCAT(U.Nombres, ' ', U.Apellidos) AS NombreCompletoUsuario,
      U.NombreUsuario,
      O.FechaOrden,
      O.ReferenciaCliente,
      O.Observaciones,
      O.Subtotal,
      O.Impuesto,
      O.Total,
      O.FechaCierre,
      O.Activo,
      O.RowStatus,
      O.FechaCreacion,
      (
        SELECT COUNT(*)
        FROM dbo.OrdenesDetalle D
        WHERE D.IdOrden = O.IdOrden
          AND D.RowStatus = 1
      ) AS CantidadLineas
    FROM dbo.Ordenes O
    INNER JOIN dbo.Recursos R ON R.IdRecurso = O.IdRecurso
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    INNER JOIN dbo.Usuarios U ON U.IdUsuario = O.IdUsuario
    WHERE O.RowStatus = 1
    ORDER BY O.IdOrden DESC;
    RETURN;
  END;

  IF @Accion = 'O'
  BEGIN
    SELECT
      O.IdOrden,
      O.NumeroOrden,
      O.IdRecurso,
      R.Nombre AS Recurso,
      O.IdEstadoOrden,
      E.Nombre AS EstadoOrden,
      O.IdUsuario,
      CONCAT(U.Nombres, ' ', U.Apellidos) AS NombreCompletoUsuario,
      U.NombreUsuario,
      O.FechaOrden,
      O.ReferenciaCliente,
      O.Observaciones,
      O.Subtotal,
      O.Impuesto,
      O.Total,
      O.FechaCierre,
      O.Activo,
      O.RowStatus,
      O.FechaCreacion,
      O.FechaModificacion
    FROM dbo.Ordenes O
    INNER JOIN dbo.Recursos R ON R.IdRecurso = O.IdRecurso
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    INNER JOIN dbo.Usuarios U ON U.IdUsuario = O.IdUsuario
    WHERE O.IdOrden = @IdOrden
      AND O.RowStatus = 1;
    RETURN;
  END;

  IF @Accion = 'I'
  BEGIN
    DECLARE @IdEstadoAbierta INT;
    SELECT TOP 1 @IdEstadoAbierta = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Abierta'
      AND RowStatus = 1;

    IF @IdEstadoAbierta IS NULL
      THROW 50810, 'No existe el estado Abierta para crear ordenes.', 1;

    INSERT INTO dbo.Ordenes (
      NumeroOrden,
      IdRecurso,
      IdEstadoOrden,
      IdUsuario,
      FechaOrden,
      ReferenciaCliente,
      Observaciones,
      Subtotal,
      Impuesto,
      Total,
      FechaCierre,
      Activo,
      RowStatus,
      FechaCreacion,
      UsuarioCreacion
    )
    VALUES (
      'ORD-' + RIGHT('00000000' + CAST(ISNULL((SELECT MAX(IdOrden) + 1 FROM dbo.Ordenes), 1) AS VARCHAR(20)), 8),
      @IdRecurso,
      ISNULL(@IdEstadoOrden, @IdEstadoAbierta),
      @IdUsuario,
      GETDATE(),
      NULLIF(LTRIM(RTRIM(@ReferenciaCliente)), ''),
      NULLIF(LTRIM(RTRIM(@Observaciones)), ''),
      0,
      0,
      0,
      NULL,
      ISNULL(@Activo, 1),
      1,
      GETDATE(),
      @UsuarioCreacion
    );

    SET @IdOrden = SCOPE_IDENTITY();

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_CREADA',
      @EstadoNuevo = 'Abierta',
      @Observacion = 'Creacion de orden',
      @UsuarioMovimiento = @UsuarioCreacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'A'
  BEGIN
    DECLARE @EstadoAnterior VARCHAR(50);
    DECLARE @EstadoNuevo VARCHAR(50);

    SELECT @EstadoAnterior = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden;

    IF EXISTS (
      SELECT 1
      FROM dbo.Ordenes O
      INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
      WHERE O.IdOrden = @IdOrden
        AND O.RowStatus = 1
        AND E.PermiteEditar = 0
    )
    BEGIN
      RAISERROR('La orden no permite edicion.', 16, 1);
      RETURN;
    END;

    UPDATE dbo.Ordenes
    SET
      IdRecurso = ISNULL(@IdRecurso, IdRecurso),
      IdEstadoOrden = ISNULL(@IdEstadoOrden, IdEstadoOrden),
      ReferenciaCliente = CASE WHEN @ReferenciaCliente IS NULL THEN ReferenciaCliente ELSE NULLIF(LTRIM(RTRIM(@ReferenciaCliente)), '') END,
      Observaciones = CASE WHEN @Observaciones IS NULL THEN Observaciones ELSE NULLIF(LTRIM(RTRIM(@Observaciones)), '') END,
      Activo = ISNULL(@Activo, Activo),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    SELECT @EstadoNuevo = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_ACTUALIZADA',
      @EstadoAnterior = @EstadoAnterior,
      @EstadoNuevo = @EstadoNuevo,
      @Observacion = 'Actualizacion de cabecera',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'C'
  BEGIN
    DECLARE @EstadoCierreAnterior VARCHAR(50);

    SELECT @EstadoCierreAnterior = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden
      AND O.RowStatus = 1;

    IF NOT EXISTS (
      SELECT 1
      FROM dbo.OrdenesDetalle
      WHERE IdOrden = @IdOrden
        AND RowStatus = 1
        AND Activo = 1
    )
    BEGIN
      RAISERROR('No se puede cerrar una orden sin lineas activas.', 16, 1);
      RETURN;
    END;

    DECLARE @IdEstadoFacturada INT;
    SELECT TOP 1 @IdEstadoFacturada = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Facturada'
      AND RowStatus = 1;

    IF @IdEstadoFacturada IS NULL
      THROW 50811, 'No existe el estado Facturada.', 1;

    EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrden;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoFacturada,
      FechaCierre = GETDATE(),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_CERRADA',
      @EstadoAnterior = @EstadoCierreAnterior,
      @EstadoNuevo = 'Facturada',
      @Observacion = 'Cierre de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'X'
  BEGIN
    DECLARE @EstadoAnulacionAnterior VARCHAR(50);
    DECLARE @IdEstadoCancelada INT;

    SELECT @EstadoAnulacionAnterior = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden
      AND O.RowStatus = 1;

    SELECT TOP 1 @IdEstadoCancelada = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Cancelada'
      AND RowStatus = 1;

    IF @IdEstadoCancelada IS NULL
      THROW 50812, 'No existe el estado Cancelada.', 1;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoCancelada,
      Activo = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_ANULADA',
      @EstadoAnterior = @EstadoAnulacionAnterior,
      @EstadoNuevo = 'Cancelada',
      @Observacion = 'Anulacion de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'R'
  BEGIN
    DECLARE @EstadoReaperturaAnterior VARCHAR(50);
    DECLARE @IdEstadoAbiertaReapertura INT;

    SELECT @EstadoReaperturaAnterior = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden
      AND O.RowStatus = 1;

    SELECT TOP 1 @IdEstadoAbiertaReapertura = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Abierta'
      AND RowStatus = 1;

    IF @IdEstadoAbiertaReapertura IS NULL
      THROW 50813, 'No existe el estado Abierta.', 1;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoAbiertaReapertura,
      Activo = 1,
      FechaCierre = NULL,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_REABIERTA',
      @EstadoAnterior = @EstadoReaperturaAnterior,
      @EstadoNuevo = 'Abierta',
      @Observacion = 'Reapertura de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;
END;
GO
