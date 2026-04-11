USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 93: PAX por orden y persona por linea ===';
GO

IF COL_LENGTH('dbo.Ordenes', 'CantidadPersonas') IS NULL
BEGIN
  ALTER TABLE dbo.Ordenes
    ADD CantidadPersonas INT NOT NULL
      CONSTRAINT DF_Ordenes_CantidadPersonas DEFAULT (1);
END;
GO

UPDATE dbo.Ordenes
SET CantidadPersonas = 1
WHERE ISNULL(CantidadPersonas, 0) <= 0;
GO

IF COL_LENGTH('dbo.OrdenesDetalle', 'NumeroPersona') IS NULL
BEGIN
  ALTER TABLE dbo.OrdenesDetalle
    ADD NumeroPersona INT NULL;
END;
GO

UPDATE dbo.OrdenesDetalle
SET NumeroPersona = 1
WHERE RowStatus = 1
  AND ISNULL(NumeroPersona, 0) <= 0;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesCRUD
  @Accion CHAR(1),
  @IdOrden INT = NULL,
  @IdRecurso INT = NULL,
  @IdEstadoOrden INT = NULL,
  @IdUsuario INT = NULL,
  @ReferenciaCliente VARCHAR(200) = NULL,
  @Observaciones VARCHAR(500) = NULL,
  @CantidadPersonas INT = NULL,
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
      O.CantidadPersonas,
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
      O.CantidadPersonas,
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
    DECLARE @CantidadPersonasI INT = CASE WHEN ISNULL(@CantidadPersonas, 1) < 1 THEN 1 ELSE ISNULL(@CantidadPersonas, 1) END;

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
      CantidadPersonas,
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
      @CantidadPersonasI,
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
    DECLARE @CantidadPersonasA INT = CASE WHEN @CantidadPersonas IS NULL THEN NULL WHEN @CantidadPersonas < 1 THEN 1 ELSE @CantidadPersonas END;

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
      CantidadPersonas = ISNULL(@CantidadPersonasA, CantidadPersonas),
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
  @NumeroPersona INT = NULL,
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
      D.NumeroPersona,
      D.Activo,
      D.RowStatus,
      D.FechaCreacion,
      UC.NombreUsuario AS UsuarioCreacionNombre
    FROM dbo.OrdenesDetalle D
    INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto
    INNER JOIN dbo.UnidadesMedida U ON U.IdUnidadMedida = D.IdUnidadMedida
    LEFT JOIN dbo.EstadosDetalleOrden EDO ON EDO.IdEstadoDetalleOrden = D.IdEstadoDetalleOrden
    LEFT JOIN dbo.Usuarios UC ON UC.IdUsuario = D.UsuarioCreacion
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
      D.NumeroPersona,
      D.Activo,
      D.RowStatus,
      D.FechaCreacion,
      UC.NombreUsuario AS UsuarioCreacionNombre
    FROM dbo.OrdenesDetalle D
    INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto
    INNER JOIN dbo.UnidadesMedida U ON U.IdUnidadMedida = D.IdUnidadMedida
    LEFT JOIN dbo.EstadosDetalleOrden EDO ON EDO.IdEstadoDetalleOrden = D.IdEstadoDetalleOrden
    LEFT JOIN dbo.Usuarios UC ON UC.IdUsuario = D.UsuarioCreacion
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
    DECLARE @NumeroPersonaI INT = CASE WHEN ISNULL(@NumeroPersona, 1) < 1 THEN 1 ELSE ISNULL(@NumeroPersona, 1) END;

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
      NumeroPersona,
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
      @NumeroPersonaI,
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
    DECLARE @NumeroPersonaA INT = CASE WHEN @NumeroPersona IS NULL THEN NULL WHEN @NumeroPersona < 1 THEN 1 ELSE @NumeroPersona END;

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
      NumeroPersona = ISNULL(@NumeroPersonaA, NumeroPersona),
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
    O.CantidadPersonas,
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

CREATE OR ALTER PROCEDURE dbo.spOrdenesDashboardDetalle
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    D.IdOrdenDetalle,
    D.IdOrden,
    P.Nombre AS Producto,
    D.Cantidad,
    D.Unidades,
    D.PrecioUnitario,
    ISNULL(D.PorcentajeImpuesto, 0) AS PorcentajeImpuesto,
    ISNULL(D.MontoImpuesto, 0) AS MontoImpuesto,
    D.TotalLinea,
    ISNULL(D.ObservacionLinea, '') AS ObservacionLinea,
    ISNULL(D.NumeroPersona, 1) AS NumeroPersona,
    D.FechaCreacion,
    ISNULL(U.NombreUsuario, '') AS UsuarioCreacionNombre
  FROM dbo.OrdenesDetalle D
  INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto
  LEFT JOIN dbo.Usuarios U ON U.IdUsuario = D.UsuarioCreacion
  WHERE D.RowStatus = 1
  ORDER BY D.IdOrdenDetalle;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesDividir
  @IdOrdenOrigen INT,
  @IdsOrdenDetalleCsv NVARCHAR(MAX),
  @ReferenciaCliente VARCHAR(200) = NULL,
  @UsuarioAccion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF ISNULL(@IdOrdenOrigen, 0) <= 0
    THROW 50920, 'Debe indicar la orden origen.', 1;

  IF LTRIM(RTRIM(ISNULL(@IdsOrdenDetalleCsv, ''))) = ''
    THROW 50921, 'Debe indicar al menos una linea para dividir.', 1;

  DECLARE @LineasSeleccionadas TABLE (IdOrdenDetalle INT PRIMARY KEY);

  INSERT INTO @LineasSeleccionadas (IdOrdenDetalle)
  SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
  FROM STRING_SPLIT(@IdsOrdenDetalleCsv, ',')
  WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;

  IF NOT EXISTS (SELECT 1 FROM @LineasSeleccionadas)
    THROW 50922, 'La seleccion de lineas no es valida.', 1;

  DECLARE
    @IdRecurso INT,
    @IdUsuarioOrden INT,
    @IdEstadoAbierta INT,
    @NumeroOrdenOrigen VARCHAR(50),
    @ReferenciaOrigen VARCHAR(200),
    @ObservacionesOrigen VARCHAR(500),
    @CantidadPersonasOrigen INT,
    @TotalLineasOrigen INT,
    @TotalLineasMover INT,
    @IdOrdenNueva INT,
    @NumeroOrdenNueva VARCHAR(50),
    @MensajeOrdenNueva VARCHAR(500),
    @MensajeLineaOrigen VARCHAR(500),
    @MensajeLineaNueva VARCHAR(500);

  SELECT TOP 1
    @IdRecurso = O.IdRecurso,
    @IdUsuarioOrden = O.IdUsuario,
    @NumeroOrdenOrigen = O.NumeroOrden,
    @ReferenciaOrigen = O.ReferenciaCliente,
    @ObservacionesOrigen = O.Observaciones,
    @CantidadPersonasOrigen = ISNULL(O.CantidadPersonas, 1)
  FROM dbo.Ordenes O
  WHERE O.IdOrden = @IdOrdenOrigen
    AND O.RowStatus = 1;

  IF @IdRecurso IS NULL
    THROW 50923, 'La orden origen no existe.', 1;

  SELECT TOP 1 @IdEstadoAbierta = IdEstadoOrden
  FROM dbo.EstadosOrden
  WHERE Nombre = 'Abierta'
    AND RowStatus = 1;

  IF @IdEstadoAbierta IS NULL
    THROW 50924, 'No existe el estado Abierta.', 1;

  SELECT @TotalLineasOrigen = COUNT(*)
  FROM dbo.OrdenesDetalle
  WHERE IdOrden = @IdOrdenOrigen
    AND RowStatus = 1
    AND ISNULL(Activo, 1) = 1;

  SELECT @TotalLineasMover = COUNT(*)
  FROM dbo.OrdenesDetalle D
  INNER JOIN @LineasSeleccionadas S ON S.IdOrdenDetalle = D.IdOrdenDetalle
  WHERE D.IdOrden = @IdOrdenOrigen
    AND D.RowStatus = 1
    AND ISNULL(D.Activo, 1) = 1;

  IF ISNULL(@TotalLineasMover, 0) <= 0
    THROW 50925, 'Las lineas seleccionadas no pertenecen a la orden origen.', 1;

  IF @TotalLineasMover >= @TotalLineasOrigen
    THROW 50926, 'La division debe dejar al menos una linea en la orden original.', 1;

  BEGIN TRANSACTION;

  INSERT INTO dbo.Ordenes (
    NumeroOrden,
    IdRecurso,
    IdEstadoOrden,
    IdUsuario,
    FechaOrden,
    ReferenciaCliente,
    Observaciones,
    CantidadPersonas,
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
    @IdEstadoAbierta,
    @IdUsuarioOrden,
    GETDATE(),
    NULLIF(LTRIM(RTRIM(ISNULL(@ReferenciaCliente, @ReferenciaOrigen))), ''),
    NULLIF(LTRIM(RTRIM(@ObservacionesOrigen)), ''),
    CASE WHEN ISNULL(@CantidadPersonasOrigen, 1) < 1 THEN 1 ELSE @CantidadPersonasOrigen END,
    0,
    0,
    0,
    NULL,
    1,
    1,
    GETDATE(),
    @UsuarioAccion
  );

  SET @IdOrdenNueva = SCOPE_IDENTITY();

  SELECT @NumeroOrdenNueva = NumeroOrden
  FROM dbo.Ordenes
  WHERE IdOrden = @IdOrdenNueva;

  SET @MensajeOrdenNueva = CONCAT('Orden creada por division desde ', @NumeroOrdenOrigen);

  EXEC dbo.spOrdenesRegistrarMovimiento
    @IdOrden = @IdOrdenNueva,
    @TipoMovimiento = 'ORDEN_CREADA',
    @EstadoNuevo = 'Abierta',
    @Observacion = @MensajeOrdenNueva,
    @UsuarioMovimiento = @UsuarioAccion;

  UPDATE D
  SET
    D.IdOrden = @IdOrdenNueva,
    D.FechaModificacion = GETDATE(),
    D.UsuarioModificacion = @UsuarioAccion
  FROM dbo.OrdenesDetalle D
  INNER JOIN @LineasSeleccionadas S ON S.IdOrdenDetalle = D.IdOrdenDetalle
  WHERE D.IdOrden = @IdOrdenOrigen
    AND D.RowStatus = 1
    AND ISNULL(D.Activo, 1) = 1;

  DECLARE @IdOrdenDetalleMovida INT;
  DECLARE moved_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT IdOrdenDetalle FROM @LineasSeleccionadas ORDER BY IdOrdenDetalle;

  OPEN moved_cursor;
  FETCH NEXT FROM moved_cursor INTO @IdOrdenDetalleMovida;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @MensajeLineaOrigen = CONCAT('Linea movida a ', @NumeroOrdenNueva);
    SET @MensajeLineaNueva = CONCAT('Linea recibida desde ', @NumeroOrdenOrigen);

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrdenOrigen,
      @IdOrdenDetalle = @IdOrdenDetalleMovida,
      @TipoMovimiento = 'LINEA_DIVIDIDA',
      @Observacion = @MensajeLineaOrigen,
      @UsuarioMovimiento = @UsuarioAccion;

    EXEC dbo.spOrdenesRegistrarMovimiento
      @IdOrden = @IdOrdenNueva,
      @IdOrdenDetalle = @IdOrdenDetalleMovida,
      @TipoMovimiento = 'LINEA_RECIBIDA',
      @Observacion = @MensajeLineaNueva,
      @UsuarioMovimiento = @UsuarioAccion;

    FETCH NEXT FROM moved_cursor INTO @IdOrdenDetalleMovida;
  END

  CLOSE moved_cursor;
  DEALLOCATE moved_cursor;

  EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrdenOrigen;
  EXEC dbo.spOrdenesRecalcularTotales @IdOrden = @IdOrdenNueva;

  COMMIT TRANSACTION;

  SELECT
    @IdOrdenNueva AS IdOrdenNueva,
    @NumeroOrdenNueva AS NumeroOrdenNueva;
END;
GO

PRINT '93_ordenes_pax_personas.sql ejecutado correctamente.';
GO
