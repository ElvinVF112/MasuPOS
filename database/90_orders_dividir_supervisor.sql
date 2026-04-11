USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 90: supervisor + dividir ordenes ===';
GO

IF OBJECT_ID('dbo.spOrdenesCerrar', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spOrdenesCerrar;
GO

IF OBJECT_ID('dbo.spOrdenesAnular', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spOrdenesAnular;
GO

IF OBJECT_ID('dbo.spOrdenesReabrir', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spOrdenesReabrir;
GO

CREATE OR ALTER PROCEDURE dbo.spAuthVerificarSupervisor
  @NombreUsuario NVARCHAR(150),
  @ClaveHash NVARCHAR(500),
  @ClavePermiso NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Usuario NVARCHAR(150) = LTRIM(RTRIM(ISNULL(@NombreUsuario, '')));
  DECLARE @Permiso NVARCHAR(100) = LOWER(LTRIM(RTRIM(ISNULL(@ClavePermiso, ''))));

  IF @Usuario = ''
    THROW 50910, 'Debe indicar el usuario del supervisor.', 1;

  IF ISNULL(@ClaveHash, '') = ''
    THROW 50911, 'Debe indicar la clave del supervisor.', 1;

  IF @Permiso = ''
    THROW 50912, 'Debe indicar el permiso a validar.', 1;

  DECLARE @IdUsuario INT;
  DECLARE @IdRol INT;

  SELECT TOP 1
    @IdUsuario = U.IdUsuario,
    @IdRol = U.IdRol
  FROM dbo.Usuarios U
  WHERE U.RowStatus = 1
    AND U.Activo = 1
    AND ISNULL(U.Bloqueado, 0) = 0
    AND U.NombreUsuario = @Usuario
    AND U.ClaveHash = @ClaveHash;

  IF @IdUsuario IS NULL
    THROW 50913, 'Credenciales de supervisor invalidas.', 1;

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
    WHERE RP.RowStatus = 1
      AND RP.Activo = 1
      AND RP.IdRol = @IdRol
      AND P.RowStatus = 1
      AND P.Activo = 1
      AND LOWER(LTRIM(RTRIM(P.Clave))) = @Permiso
  )
    THROW 50914, 'El supervisor no tiene el permiso requerido.', 1;

  SELECT TOP 1
    U.IdUsuario,
    U.IdRol,
    R.Nombre AS Rol,
    U.NombreUsuario,
    U.Nombres,
    U.Apellidos,
    @Permiso AS ClavePermiso
  FROM dbo.Usuarios U
  INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
  WHERE U.IdUsuario = @IdUsuario;
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
    @TotalLineasOrigen INT,
    @TotalLineasMover INT,
    @IdOrdenNueva INT,
    @NumeroOrdenNueva VARCHAR(50),
    @MensajeOrdenNueva VARCHAR(500),
    @MensajeLineaOrigen VARCHAR(500),
    @MensajeLineaNueva VARCHAR(500),
    @MensajeResumenOrigen VARCHAR(500),
    @MensajeResumenNueva VARCHAR(500);

  SELECT TOP 1
    @IdRecurso = O.IdRecurso,
    @IdUsuarioOrden = O.IdUsuario,
    @NumeroOrdenOrigen = O.NumeroOrden,
    @ReferenciaOrigen = O.ReferenciaCliente,
    @ObservacionesOrigen = O.Observaciones
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

  SET @MensajeResumenOrigen = CONCAT('Se dividieron ', @TotalLineasMover, ' linea(s) hacia ', @NumeroOrdenNueva);
  SET @MensajeResumenNueva = CONCAT('Orden creada por division desde ', @NumeroOrdenOrigen);

  EXEC dbo.spOrdenesRegistrarMovimiento
    @IdOrden = @IdOrdenOrigen,
    @TipoMovimiento = 'ORDEN_DIVIDIDA',
    @Observacion = @MensajeResumenOrigen,
    @UsuarioMovimiento = @UsuarioAccion;

  EXEC dbo.spOrdenesRegistrarMovimiento
    @IdOrden = @IdOrdenNueva,
    @TipoMovimiento = 'ORDEN_DIVISION_RECIBIDA',
    @Observacion = @MensajeResumenNueva,
    @UsuarioMovimiento = @UsuarioAccion;

  COMMIT TRANSACTION;

  SELECT
    @IdOrdenNueva AS IdOrdenNueva,
    @NumeroOrdenNueva AS NumeroOrdenNueva;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE RowStatus = 1 AND Clave = 'orders.delete')
BEGIN
  DECLARE @IdPantallaOrders INT = (
    SELECT TOP 1 IdPantalla
    FROM dbo.Pantallas
    WHERE RowStatus = 1
      AND LOWER(LTRIM(RTRIM(Ruta))) = '/orders'
  );

  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (@IdPantallaOrders, N'Eliminar lineas de orden', N'Permite eliminar lineas individuales de una orden', N'orders.delete', 1, 1, GETDATE(), 1);
END
GO

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
SELECT
  1,
  P.IdPermiso,
  1,
  1,
  GETDATE(),
  1
FROM dbo.Permisos P
WHERE P.RowStatus = 1
  AND P.Activo = 1
  AND P.Clave = 'orders.delete'
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = 1
      AND RP.IdPermiso = P.IdPermiso
      AND RP.RowStatus = 1
  );
GO

PRINT '90_orders_dividir_supervisor.sql ejecutado correctamente.';
GO
