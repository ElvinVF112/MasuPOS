USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 82: core de ordenes - stored procedures ===';
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesRegistrarMovimiento
  @IdOrden INT,
  @IdOrdenDetalle INT = NULL,
  @TipoMovimiento VARCHAR(50),
  @EstadoAnterior VARCHAR(50) = NULL,
  @EstadoNuevo VARCHAR(50) = NULL,
  @Observacion VARCHAR(500) = NULL,
  @UsuarioMovimiento INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO dbo.OrdenesMovimientos (
    IdOrden,
    IdOrdenDetalle,
    TipoMovimiento,
    EstadoAnterior,
    EstadoNuevo,
    Observacion,
    FechaMovimiento,
    UsuarioMovimiento,
    Activo,
    RowStatus,
    FechaCreacion,
    UsuarioCreacion
  )
  VALUES (
    @IdOrden,
    @IdOrdenDetalle,
    @TipoMovimiento,
    NULLIF(LTRIM(RTRIM(@EstadoAnterior)), ''),
    NULLIF(LTRIM(RTRIM(@EstadoNuevo)), ''),
    NULLIF(LTRIM(RTRIM(@Observacion)), ''),
    GETDATE(),
    @UsuarioMovimiento,
    1,
    1,
    GETDATE(),
    @UsuarioMovimiento
  );
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesRecalcularTotales
  @IdOrden INT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE O
  SET
    Subtotal = Totales.Subtotal,
    Impuesto = Totales.Impuesto,
    Total = Totales.Total,
    FechaModificacion = GETDATE()
  FROM dbo.Ordenes O
  CROSS APPLY (
    SELECT
      ISNULL(SUM(D.SubtotalLinea), 0) AS Subtotal,
      ISNULL(SUM(D.MontoImpuesto), 0) AS Impuesto,
      ISNULL(SUM(D.TotalLinea), 0) AS Total
    FROM dbo.OrdenesDetalle D
    WHERE D.IdOrden = O.IdOrden
      AND D.RowStatus = 1
      AND ISNULL(D.Activo, 1) = 1
  ) Totales
  WHERE O.IdOrden = @IdOrden;
END;
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

    DECLARE @TipoMovimientoActualizacion VARCHAR(50) =
      CASE WHEN ISNULL(@EstadoAnterior, '') <> ISNULL(@EstadoNuevo, '') THEN 'ORDEN_ESTADO' ELSE 'ORDEN_EDITADA' END;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = @TipoMovimientoActualizacion,
      @EstadoAnterior = @EstadoAnterior,
      @EstadoNuevo = @EstadoNuevo,
      @Observacion = 'Actualizacion de cabecera',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'C'
  BEGIN
    IF NOT EXISTS (
      SELECT 1
      FROM dbo.OrdenesDetalle
      WHERE IdOrden = @IdOrden
        AND RowStatus = 1
        AND ISNULL(Activo, 1) = 1
    )
    BEGIN
      RAISERROR('La orden no tiene detalle.', 16, 1);
      RETURN;
    END;

    DECLARE @IdEstadoCerrada INT;
    SELECT TOP 1 @IdEstadoCerrada = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Cerrada'
      AND RowStatus = 1;

    IF @IdEstadoCerrada IS NULL
      THROW 50811, 'No existe el estado Cerrada.', 1;

    DECLARE @EstadoAnteriorCierre VARCHAR(50);
    SELECT @EstadoAnteriorCierre = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden;

    EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrden;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoCerrada,
      FechaCierre = GETDATE(),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_CERRADA',
      @EstadoAnterior = @EstadoAnteriorCierre,
      @EstadoNuevo = 'Cerrada',
      @Observacion = 'Cierre de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'X'
  BEGIN
    DECLARE @IdEstadoAnulada INT;
    SELECT TOP 1 @IdEstadoAnulada = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Anulada'
      AND RowStatus = 1;

    IF @IdEstadoAnulada IS NULL
      THROW 50812, 'No existe el estado Anulada.', 1;

    DECLARE @EstadoAnteriorAnular VARCHAR(50);
    SELECT @EstadoAnteriorAnular = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoAnulada,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_ANULADA',
      @EstadoAnterior = @EstadoAnteriorAnular,
      @EstadoNuevo = 'Anulada',
      @Observacion = 'Anulacion de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'R'
  BEGIN
    DECLARE @IdEstadoReabierta INT;
    SELECT TOP 1 @IdEstadoReabierta = IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'Reabierta'
      AND RowStatus = 1;

    IF @IdEstadoReabierta IS NULL
      THROW 50813, 'No existe el estado Reabierta.', 1;

    DECLARE @EstadoAnteriorReabrir VARCHAR(50);
    SELECT @EstadoAnteriorReabrir = E.Nombre
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrden;

    IF ISNULL(@EstadoAnteriorReabrir, '') NOT IN ('Cerrada', 'Anulada')
    BEGIN
      RAISERROR('Solo se pueden reabrir ordenes cerradas o anuladas.', 16, 1);
      RETURN;
    END;

    UPDATE dbo.Ordenes
    SET
      IdEstadoOrden = @IdEstadoReabierta,
      FechaCierre = NULL,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_REABIERTA',
      @EstadoAnterior = @EstadoAnteriorReabrir,
      @EstadoNuevo = 'Reabierta',
      @Observacion = 'Reapertura de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Ordenes
    SET
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrden = @IdOrden;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrden,
      @TipoMovimiento = 'ORDEN_ELIMINADA',
      @Observacion = 'Eliminacion logica de orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesCRUD @Accion = 'O', @IdOrden = @IdOrden;
    RETURN;
  END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesDetalleCRUD
  @Accion CHAR(1),
  @IdOrdenDetalle INT = NULL,
  @IdOrden INT = NULL,
  @IdProducto INT = NULL,
  @IdUnidadMedida INT = NULL,
  @Cantidad DECIMAL(12,2) = NULL,
  @Unidades INT = NULL,
  @PrecioUnitario DECIMAL(12,2) = NULL,
  @PorcentajeImpuesto DECIMAL(5,2) = NULL,
  @ObservacionLinea VARCHAR(250) = NULL,
  @IdEstadoDetalleOrden INT = NULL,
  @Activo BIT = NULL,
  @UsuarioCreacion INT = NULL,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT
      D.IdOrdenDetalle,
      D.IdOrden,
      D.IdProducto,
      P.Nombre AS Producto,
      D.IdUnidadMedida,
      U.Nombre AS UnidadMedida,
      U.Abreviatura,
      D.IdEstadoDetalleOrden,
      EDO.Nombre AS EstadoDetalleOrden,
      D.Cantidad,
      D.Unidades,
      D.PrecioUnitario,
      D.PorcentajeImpuesto,
      D.SubtotalLinea,
      D.MontoImpuesto,
      D.TotalLinea,
      D.ObservacionLinea,
      D.Activo,
      D.RowStatus,
      D.FechaCreacion
    FROM dbo.OrdenesDetalle D
    INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto
    INNER JOIN dbo.UnidadesMedida U ON U.IdUnidadMedida = D.IdUnidadMedida
    LEFT JOIN dbo.EstadosDetalleOrden EDO ON EDO.IdEstadoDetalleOrden = D.IdEstadoDetalleOrden
    WHERE D.IdOrden = @IdOrden
      AND D.RowStatus = 1
    ORDER BY D.IdOrdenDetalle;
    RETURN;
  END;

  IF @Accion = 'O'
  BEGIN
    SELECT
      D.IdOrdenDetalle,
      D.IdOrden,
      D.IdProducto,
      P.Nombre AS Producto,
      D.IdUnidadMedida,
      U.Nombre AS UnidadMedida,
      U.Abreviatura,
      D.IdEstadoDetalleOrden,
      EDO.Nombre AS EstadoDetalleOrden,
      D.Cantidad,
      D.Unidades,
      D.PrecioUnitario,
      D.PorcentajeImpuesto,
      D.SubtotalLinea,
      D.MontoImpuesto,
      D.TotalLinea,
      D.ObservacionLinea,
      D.Activo,
      D.RowStatus,
      D.FechaCreacion
    FROM dbo.OrdenesDetalle D
    INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto
    INNER JOIN dbo.UnidadesMedida U ON U.IdUnidadMedida = D.IdUnidadMedida
    LEFT JOIN dbo.EstadosDetalleOrden EDO ON EDO.IdEstadoDetalleOrden = D.IdEstadoDetalleOrden
    WHERE D.IdOrdenDetalle = @IdOrdenDetalle;
    RETURN;
  END;

  DECLARE @IdOrdenTarget INT = ISNULL(@IdOrden, (SELECT TOP 1 IdOrden FROM dbo.OrdenesDetalle WHERE IdOrdenDetalle = @IdOrdenDetalle));

  IF EXISTS (
    SELECT 1
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.IdOrden = @IdOrdenTarget
      AND O.RowStatus = 1
      AND E.PermiteEditar = 0
  )
  BEGIN
    RAISERROR('La orden no permite modificar el detalle.', 16, 1);
    RETURN;
  END;

  DECLARE @IdEstadoDetallePendiente INT;
  DECLARE @IdEstadoDetalleCancelado INT;
  SELECT TOP 1 @IdEstadoDetallePendiente = IdEstadoDetalleOrden FROM dbo.EstadosDetalleOrden WHERE Nombre = 'Pendiente' AND RowStatus = 1;
  SELECT TOP 1 @IdEstadoDetalleCancelado = IdEstadoDetalleOrden FROM dbo.EstadosDetalleOrden WHERE Nombre = 'Cancelado' AND RowStatus = 1;

  IF @Accion = 'I'
  BEGIN
    DECLARE @FactorI INT = ISNULL(NULLIF(@Unidades, 0), 1);
    DECLARE @CantidadI DECIMAL(12,2) = ISNULL(@Cantidad, 0);
    DECLARE @PrecioI DECIMAL(12,2) = ISNULL(@PrecioUnitario, 0);
    DECLARE @PctI DECIMAL(5,2) = ISNULL(@PorcentajeImpuesto, 0);
    DECLARE @SubI DECIMAL(12,2) = @CantidadI * @PrecioI;
    DECLARE @ImpI DECIMAL(12,2) = @SubI * (@PctI / 100.0);

    INSERT INTO dbo.OrdenesDetalle (
      IdOrden,
      IdProducto,
      IdUnidadMedida,
      IdEstadoDetalleOrden,
      Cantidad,
      Unidades,
      PrecioUnitario,
      PorcentajeImpuesto,
      SubtotalLinea,
      MontoImpuesto,
      TotalLinea,
      ObservacionLinea,
      Activo,
      RowStatus,
      FechaCreacion,
      UsuarioCreacion
    )
    VALUES (
      @IdOrdenTarget,
      @IdProducto,
      @IdUnidadMedida,
      ISNULL(@IdEstadoDetalleOrden, @IdEstadoDetallePendiente),
      @CantidadI,
      @FactorI,
      @PrecioI,
      @PctI,
      @SubI,
      @ImpI,
      @SubI + @ImpI,
      NULLIF(LTRIM(RTRIM(@ObservacionLinea)), ''),
      ISNULL(@Activo, 1),
      1,
      GETDATE(),
      @UsuarioCreacion
    );

    SET @IdOrdenDetalle = SCOPE_IDENTITY();

    EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrdenTarget;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrdenTarget,
      @IdOrdenDetalle = @IdOrdenDetalle,
      @TipoMovimiento = 'LINEA_AGREGADA',
      @EstadoNuevo = 'Pendiente',
      @Observacion = 'Linea agregada a la orden',
      @UsuarioMovimiento = @UsuarioCreacion;

    EXEC dbo.spOrdenesDetalleCRUD @Accion = 'O', @IdOrdenDetalle = @IdOrdenDetalle;
    RETURN;
  END;

  IF @Accion = 'A'
  BEGIN
    DECLARE @FactorA INT = ISNULL(NULLIF(@Unidades, 0), 1);
    DECLARE @CantidadA DECIMAL(12,2) = ISNULL(@Cantidad, 0);
    DECLARE @PrecioA DECIMAL(12,2) = ISNULL(@PrecioUnitario, 0);
    DECLARE @PctA DECIMAL(5,2) = ISNULL(@PorcentajeImpuesto, 0);
    DECLARE @SubA DECIMAL(12,2) = @CantidadA * @PrecioA;
    DECLARE @ImpA DECIMAL(12,2) = @SubA * (@PctA / 100.0);

    UPDATE dbo.OrdenesDetalle
    SET
      IdProducto = ISNULL(@IdProducto, IdProducto),
      IdUnidadMedida = ISNULL(@IdUnidadMedida, IdUnidadMedida),
      IdEstadoDetalleOrden = ISNULL(@IdEstadoDetalleOrden, IdEstadoDetalleOrden),
      Cantidad = @CantidadA,
      Unidades = @FactorA,
      PrecioUnitario = @PrecioA,
      PorcentajeImpuesto = @PctA,
      SubtotalLinea = @SubA,
      MontoImpuesto = @ImpA,
      TotalLinea = @SubA + @ImpA,
      ObservacionLinea = CASE WHEN @ObservacionLinea IS NULL THEN ObservacionLinea ELSE NULLIF(LTRIM(RTRIM(@ObservacionLinea)), '') END,
      Activo = ISNULL(@Activo, Activo),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenDetalle = @IdOrdenDetalle
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrdenTarget;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrdenTarget,
      @IdOrdenDetalle = @IdOrdenDetalle,
      @TipoMovimiento = 'LINEA_EDITADA',
      @Observacion = 'Linea editada en la orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesDetalleCRUD @Accion = 'O', @IdOrdenDetalle = @IdOrdenDetalle;
    RETURN;
  END;

  IF @Accion IN ('D', 'X')
  BEGIN
    UPDATE dbo.OrdenesDetalle
    SET
      IdEstadoDetalleOrden = ISNULL(@IdEstadoDetalleCancelado, IdEstadoDetalleOrden),
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenDetalle = @IdOrdenDetalle
      AND RowStatus = 1;

    EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrdenTarget;

    DECLARE @TipoMovimientoDetalleSalida VARCHAR(50) =
      CASE WHEN @Accion = 'X' THEN 'LINEA_CANCELADA' ELSE 'LINEA_ELIMINADA' END;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrdenTarget,
      @IdOrdenDetalle = @IdOrdenDetalle,
      @TipoMovimiento = @TipoMovimientoDetalleSalida,
      @EstadoNuevo = 'Cancelado',
      @Observacion = 'Linea retirada de la orden',
      @UsuarioMovimiento = @UsuarioModificacion;

    EXEC dbo.spOrdenesDetalleCRUD @Accion = 'O', @IdOrdenDetalle = @IdOrdenDetalle;
    RETURN;
  END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesDashboard
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    R.IdRecurso,
    R.Nombre AS Recurso,
    A.Nombre AS Area,
    CR.Nombre AS Categoria,
    O.IdOrden,
    O.NumeroOrden,
    O.IdEstadoOrden,
    E.Nombre AS EstadoOrden,
    O.IdUsuario,
    CONCAT(U.Nombres, ' ', U.Apellidos) AS Mesero,
    O.FechaOrden,
    O.ReferenciaCliente,
    O.Subtotal,
    O.Impuesto,
    O.Total
  FROM dbo.Recursos R
  INNER JOIN dbo.CategoriasRecurso CR ON CR.IdCategoriaRecurso = R.IdCategoriaRecurso
  INNER JOIN dbo.Areas A ON A.IdArea = CR.IdArea
  LEFT JOIN dbo.Ordenes O
    ON O.IdRecurso = R.IdRecurso
   AND O.RowStatus = 1
   AND O.IdEstadoOrden IN (
      SELECT IdEstadoOrden
      FROM dbo.EstadosOrden
      WHERE RowStatus = 1
        AND Nombre IN ('Abierta', 'En proceso', 'Reabierta')
   )
  LEFT JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
  LEFT JOIN dbo.Usuarios U ON U.IdUsuario = O.IdUsuario
  WHERE R.RowStatus = 1
  ORDER BY R.IdRecurso, O.FechaOrden, O.IdOrden;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesHistorial
  @IdOrden INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    M.IdOrdenMovimiento,
    M.IdOrden,
    M.IdOrdenDetalle,
    M.TipoMovimiento,
    M.EstadoAnterior,
    M.EstadoNuevo,
    M.Observacion,
    M.FechaMovimiento,
    M.UsuarioMovimiento,
    U.NombreUsuario,
    CONCAT(U.Nombres, ' ', U.Apellidos) AS NombreCompleto
  FROM dbo.OrdenesMovimientos M
  LEFT JOIN dbo.Usuarios U ON U.IdUsuario = M.UsuarioMovimiento
  WHERE M.IdOrden = @IdOrden
    AND M.RowStatus = 1
  ORDER BY M.IdOrdenMovimiento DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesCerrar
  @IdOrden INT,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  EXEC dbo.spOrdenesCRUD @Accion = 'C', @IdOrden = @IdOrden, @UsuarioModificacion = @UsuarioModificacion;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesAnular
  @IdOrden INT,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  EXEC dbo.spOrdenesCRUD @Accion = 'X', @IdOrden = @IdOrden, @UsuarioModificacion = @UsuarioModificacion;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesReabrir
  @IdOrden INT,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  EXEC dbo.spOrdenesCRUD @Accion = 'R', @IdOrden = @IdOrden, @UsuarioModificacion = @UsuarioModificacion;
END;
GO

PRINT '82_orders_core_sps.sql ejecutado correctamente.';
GO
