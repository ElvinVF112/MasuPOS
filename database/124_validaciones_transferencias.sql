-- ============================================================
-- Script: 124_validaciones_transferencias.sql
-- Propósito: Agregar validaciones para transferencias
--  1. Movimientos de transferencia no se pueden editar/anular
--  2. Transferencias en tránsito no se pueden editar/anular
-- ============================================================

USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- SP para validar si un movimiento pertenece a una transferencia
CREATE OR ALTER PROCEDURE dbo.spInvMovimientosValidarTransferencia
  @IdMovimiento INT,
  @TipoDocOrigen VARCHAR(20) OUTPUT,
  @IdDocumentoOrigen INT OUTPUT,
  @PermiteEditar BIT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @TipoDoc VARCHAR(20);
  DECLARE @IdDoc INT;

  SELECT @TipoDoc = TipoDocOrigen, @IdDoc = IdDocumentoOrigen
  FROM dbo.InvMovimientos
  WHERE IdMovimiento = @IdMovimiento AND RowStatus = 1;

  SET @TipoDocOrigen = @TipoDoc;
  SET @IdDocumentoOrigen = @IdDoc;

  -- No se puede editar si es movimiento de transferencia
  IF @TipoDoc = 'TRF'
    SET @PermiteEditar = 0;
  ELSE
    SET @PermiteEditar = 1;
END;
GO

-- Modificar spInvDocumentosCRUD para agregar validación
-- Nota: Esta validación debe ir en la sección de UPDATE/DELETE de documentos
-- El script actual debe verificar si el documento está vinculado a una transferencia

-- SP para validar si una transferencia puede ser editada/anulada
CREATE OR ALTER PROCEDURE dbo.spInvTransferenciasValidarEstado
  @IdTransferencia INT,
  @EstadoActual CHAR(1) OUTPUT,
  @PermiteEditar BIT OUTPUT,
  @PermiteAnular BIT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Estado CHAR(1);

  SELECT @Estado = EstadoTransferencia
  FROM dbo.InvTransferencias
  WHERE IdTransferencia = @IdTransferencia AND RowStatus = 1;

  SET @EstadoActual = @Estado;

  -- Solo se puede editar en Borrador (B)
  SET @PermiteEditar = CASE WHEN @Estado = 'B' THEN 1 ELSE 0 END;

  -- Solo se puede anular en Borrador (B) o En Transito (T), NO en Completada (C)
  SET @PermiteAnular = CASE WHEN @Estado IN ('B', 'T') THEN 1 ELSE 0 END;
END;
GO

-- Trigger para prevenir edición de movimientos de transferencia
CREATE OR ALTER TRIGGER dbo.TR_InvMovimientos_PreventirEditTransfer
ON dbo.InvMovimientos
FOR UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (
    SELECT 1
    FROM inserted i
    WHERE i.TipoDocOrigen = 'TRF'
  )
  BEGIN
    RAISERROR('No se pueden editar movimientos de transferencia. Anule la transferencia para deshacer.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  END
END;
GO

-- Trigger para prevenir eliminación de movimientos de transferencia
CREATE OR ALTER TRIGGER dbo.TR_InvMovimientos_PreventirDeleteTransfer
ON dbo.InvMovimientos
FOR DELETE
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (
    SELECT 1
    FROM deleted d
    WHERE d.TipoDocOrigen = 'TRF'
  )
  BEGIN
    RAISERROR('No se pueden eliminar movimientos de transferencia. Anule la transferencia para deshacer.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  END
END;
GO

-- SP para anular transferencia con validaciones
CREATE OR ALTER PROCEDURE dbo.spInvTransferenciasAnular
  @IdTransferencia INT,
  @IdUsuario INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @EstadoActual CHAR(1);
  DECLARE @TransitoDoc INT;
  DECLARE @OrigenDoc INT;

  SELECT
    @EstadoActual = EstadoTransferencia,
    @TransitoDoc = IdAlmacenTransito
  FROM dbo.InvTransferencias
  WHERE IdTransferencia = @IdTransferencia AND RowStatus = 1;

  IF @EstadoActual IS NULL
    THROW 50047, 'Transferencia no encontrada.', 1;

  -- No se puede anular si está completada
  IF @EstadoActual = 'C'
    THROW 50051, 'No se pueden anular transferencias completadas.', 1;

  -- Si estaba en transito, deshacer movimientos
  IF @EstadoActual = 'T'
  BEGIN
    -- Obtener almacén origen desde los movimientos
    SELECT TOP 1 @OrigenDoc = IdAlmacen
    FROM dbo.InvMovimientos
    WHERE IdDocumentoOrigen = @IdTransferencia
      AND TipoDocOrigen = 'TRF'
      AND TipoMovimiento = 'SAL'
      AND RowStatus = 1;

    IF @OrigenDoc IS NOT NULL
    BEGIN
      -- Deshacer: sumar stock a origen
      UPDATE PA
      SET PA.Cantidad = PA.Cantidad + D.Cantidad,
          PA.FechaModificacion = GETDATE(),
          PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN dbo.InvTransferenciasDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @OrigenDoc
        AND D.IdTransferencia = @IdTransferencia
        AND D.RowStatus = 1;

      -- Deshacer: restar stock a transito
      UPDATE PA
      SET PA.Cantidad = PA.Cantidad - D.Cantidad,
          PA.FechaModificacion = GETDATE(),
          PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN dbo.InvTransferenciasDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @TransitoDoc
        AND D.IdTransferencia = @IdTransferencia
        AND D.RowStatus = 1;
    END
  END

  UPDATE dbo.InvTransferencias
  SET EstadoTransferencia = 'N',
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario
  WHERE IdTransferencia = @IdTransferencia;

  PRINT 'Transferencia anulada correctamente.';
END;
GO

-- Agregamos una vista útil para consultar transferencias con estado
CREATE OR ALTER VIEW vw_InvTransferenciasSaldo AS
SELECT
  T.IdTransferencia,
  T.EstadoTransferencia,
  T.FechaSalida,
  T.FechaRecepcion,
  COUNT(DISTINCT D.IdProducto) AS TotalProductos,
  SUM(D.Cantidad) AS QuantidadTotal,
  SUM(D.Total) AS MontoTotal,
  CASE WHEN T.EstadoTransferencia = 'B' THEN 'Borrador'
       WHEN T.EstadoTransferencia = 'T' THEN 'En Tránsito'
       WHEN T.EstadoTransferencia = 'C' THEN 'Completada'
       WHEN T.EstadoTransferencia = 'N' THEN 'Anulada'
       ELSE 'Desconocido' END AS NombreEstado,
  CASE WHEN T.EstadoTransferencia = 'B' THEN 1 ELSE 0 END AS PermiteEditar,
  CASE WHEN T.EstadoTransferencia IN ('B', 'T') THEN 1 ELSE 0 END AS PermiteAnular
FROM dbo.InvTransferencias T
LEFT JOIN dbo.InvTransferenciasDetalle D ON D.IdTransferencia = T.IdTransferencia AND D.RowStatus = 1
WHERE T.RowStatus = 1
GROUP BY T.IdTransferencia, T.EstadoTransferencia, T.FechaSalida, T.FechaRecepcion;
GO

PRINT 'Script 124_validaciones_transferencias.sql ejecutado:';
PRINT '  - SP spInvMovimientosValidarTransferencia';
PRINT '  - SP spInvTransferenciasValidarEstado';
PRINT '  - Trigger TR_InvMovimientos_PreventirEditTransfer';
PRINT '  - Trigger TR_InvMovimientos_PreventirDeleteTransfer';
PRINT '  - Vista vw_InvTransferenciasSaldo';
GO
