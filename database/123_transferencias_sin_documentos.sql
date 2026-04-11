-- ============================================================
-- Script: 123_transferencias_sin_documentos.sql
-- Propósito: Refactorizar transferencias para no usar InvDocumentos
--            Solo control en InvTransferencias + movimientos directos
-- ============================================================

USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Crear tabla InvTransferenciasDetalle (líneas de transferencia)
IF OBJECT_ID('dbo.InvTransferenciasDetalle', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.InvTransferenciasDetalle (
    IdDetalle           INT IDENTITY(1,1) PRIMARY KEY,
    IdTransferencia     INT NOT NULL,
    NumeroLinea         INT NOT NULL,
    IdProducto          INT NOT NULL CONSTRAINT FK_InvTD_Producto FOREIGN KEY REFERENCES dbo.Productos(IdProducto),
    Codigo              NVARCHAR(60) NULL,
    Descripcion         NVARCHAR(200) NOT NULL,
    IdUnidadMedida      INT NULL,
    NombreUnidad        NVARCHAR(50) NULL,
    Cantidad            DECIMAL(18,4) NOT NULL DEFAULT 0,
    Costo               DECIMAL(18,4) NOT NULL DEFAULT 0,
    Total               DECIMAL(18,4) NOT NULL DEFAULT 0,
    RowStatus           INT NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT NOT NULL DEFAULT 1,
    CONSTRAINT UQ_InvTD_Linea UNIQUE (IdTransferencia, NumeroLinea),
    CONSTRAINT FK_InvTD_Transfer FOREIGN KEY (IdTransferencia) REFERENCES dbo.InvTransferencias(IdTransferencia)
  );
  PRINT 'Tabla InvTransferenciasDetalle creada.';
END
GO

-- 2. SP simplificada para generar salida de transferencia (GS)
CREATE OR ALTER PROCEDURE dbo.spInvTransferenciasGenerarSalida
  @IdTransferencia     INT,
  @IdAlmacenOrigen     INT,
  @IdUsuario           INT,
  @IdSesion            INT = NULL,
  @Observacion         NVARCHAR(500) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @EstadoActual CHAR(1);
  DECLARE @TransitoDoc INT;

  SELECT @EstadoActual = EstadoTransferencia, @TransitoDoc = IdAlmacenTransito
  FROM dbo.InvTransferencias
  WHERE IdTransferencia = @IdTransferencia AND RowStatus = 1;

  IF @EstadoActual IS NULL
    THROW 50047, 'Transferencia no encontrada.', 1;

  IF @EstadoActual <> 'B'
    THROW 50048, 'Solo se puede generar salida desde borrador.', 1;

  -- Verificar stock
  IF EXISTS (
    SELECT 1
    FROM dbo.InvTransferenciasDetalle D
    OUTER APPLY (
      SELECT TOP 1 ISNULL(PA.Cantidad, 0) AS Existencia
      FROM dbo.ProductoAlmacenes PA
      WHERE PA.IdProducto = D.IdProducto
        AND PA.IdAlmacen = @IdAlmacenOrigen
        AND PA.RowStatus = 1
    ) S
    WHERE D.IdTransferencia = @IdTransferencia
      AND D.RowStatus = 1
      AND ISNULL(S.Existencia, 0) < D.Cantidad
  )
    THROW 50049, 'Stock insuficiente para generar la salida.', 1;

  -- Crear movimientos para salida de origen
  INSERT INTO dbo.InvMovimientos (
    IdProducto, IdAlmacen, TipoMovimiento, Signo,
    IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
    Cantidad, CostoUnitario, CostoTotal,
    SaldoAnterior, SaldoNuevo,
    Fecha, Periodo, Observacion, UsuarioCreacion
  )
  SELECT
    D.IdProducto,
    @IdAlmacenOrigen,
    'SAL',
    -1,
    @IdTransferencia,
    'TRF',
    CONCAT('TRF-', @IdTransferencia),
    D.Cantidad,
    D.Costo,
    D.Total,
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @IdAlmacenOrigen),
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @IdAlmacenOrigen) - D.Cantidad,
    GETDATE(),
    FORMAT(GETDATE(), 'yyyyMM'),
    @Observacion,
    @IdUsuario
  FROM dbo.InvTransferenciasDetalle D
  WHERE D.IdTransferencia = @IdTransferencia AND D.RowStatus = 1;

  -- Crear movimientos para entrada en transito
  INSERT INTO dbo.InvMovimientos (
    IdProducto, IdAlmacen, TipoMovimiento, Signo,
    IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
    Cantidad, CostoUnitario, CostoTotal,
    SaldoAnterior, SaldoNuevo,
    Fecha, Periodo, Observacion, UsuarioCreacion
  )
  SELECT
    D.IdProducto,
    @TransitoDoc,
    'ENT',
    1,
    @IdTransferencia,
    'TRF',
    CONCAT('TRF-', @IdTransferencia),
    D.Cantidad,
    D.Costo,
    D.Total,
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @TransitoDoc),
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @TransitoDoc) + D.Cantidad,
    GETDATE(),
    FORMAT(GETDATE(), 'yyyyMM'),
    @Observacion,
    @IdUsuario
  FROM dbo.InvTransferenciasDetalle D
  WHERE D.IdTransferencia = @IdTransferencia AND D.RowStatus = 1;

  -- Actualizar stock en ProductoAlmacenes
  UPDATE PA
  SET PA.Cantidad = PA.Cantidad - D.Cantidad,
      PA.FechaModificacion = GETDATE(),
      PA.UsuarioModificacion = @IdUsuario
  FROM dbo.ProductoAlmacenes PA
  INNER JOIN dbo.InvTransferenciasDetalle D ON D.IdProducto = PA.IdProducto
  WHERE PA.IdAlmacen = @IdAlmacenOrigen
    AND D.IdTransferencia = @IdTransferencia
    AND D.RowStatus = 1;

  UPDATE PA
  SET PA.Cantidad = PA.Cantidad + D.Cantidad,
      PA.FechaModificacion = GETDATE(),
      PA.UsuarioModificacion = @IdUsuario
  FROM dbo.ProductoAlmacenes PA
  INNER JOIN dbo.InvTransferenciasDetalle D ON D.IdProducto = PA.IdProducto
  WHERE PA.IdAlmacen = @TransitoDoc
    AND D.IdTransferencia = @IdTransferencia
    AND D.RowStatus = 1;

  -- Actualizar estado a En Transito
  UPDATE dbo.InvTransferencias
  SET EstadoTransferencia = 'T',
      FechaSalida = GETDATE(),
      UsuarioSalida = @IdUsuario,
      IdSesionSalida = @IdSesion,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario
  WHERE IdTransferencia = @IdTransferencia;

  PRINT 'Salida generada correctamente.';
END;
GO

-- 3. SP modificada para validar estado antes de editar
CREATE OR ALTER PROCEDURE dbo.spInvTransferenciasActualizar
  @IdTransferencia     INT,
  @IdAlmacenDestino    INT,
  @DetalleJSON         NVARCHAR(MAX) = NULL,
  @IdUsuario           INT = NULL,
  @IdSesion            INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @EstadoActual CHAR(1);

  SELECT @EstadoActual = EstadoTransferencia
  FROM dbo.InvTransferencias
  WHERE IdTransferencia = @IdTransferencia AND RowStatus = 1;

  IF @EstadoActual IS NULL
    THROW 50047, 'Transferencia no encontrada.', 1;

  -- IMPORTANTE: Solo se puede editar en Borrador
  IF @EstadoActual <> 'B'
  BEGIN
    DECLARE @MsgError NVARCHAR(500) = 'No se puede editar una transferencia que ya ha generado salida. Estado actual: ' +
      CASE @EstadoActual WHEN 'T' THEN 'En Tránsito' WHEN 'C' THEN 'Completada' WHEN 'N' THEN 'Anulada' ELSE @EstadoActual END;
    THROW 50052, @MsgError, 1;
  END

  UPDATE dbo.InvTransferencias
  SET IdAlmacenDestino = @IdAlmacenDestino,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario
  WHERE IdTransferencia = @IdTransferencia;

  -- Eliminar líneas antiguas
  UPDATE dbo.InvTransferenciasDetalle
  SET RowStatus = 0
  WHERE IdTransferencia = @IdTransferencia;

  -- Procesar líneas nuevas
  IF @DetalleJSON IS NOT NULL AND @DetalleJSON <> ''
  BEGIN
    DECLARE @NumeroLinea INT = 1;

    INSERT INTO dbo.InvTransferenciasDetalle (
      IdTransferencia, NumeroLinea, IdProducto, Codigo, Descripcion,
      IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total,
      UsuarioCreacion
    )
    SELECT
      @IdTransferencia,
      @NumeroLinea + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
      JSON_VALUE(value, '$.IdProducto'),
      JSON_VALUE(value, '$.Codigo'),
      JSON_VALUE(value, '$.Descripcion'),
      JSON_VALUE(value, '$.IdUnidadMedida'),
      JSON_VALUE(value, '$.NombreUnidad'),
      JSON_VALUE(value, '$.Cantidad'),
      JSON_VALUE(value, '$.Costo'),
      JSON_VALUE(value, '$.Total'),
      @IdUsuario
    FROM OPENJSON(@DetalleJSON) AS items;
  END

  PRINT 'Transferencia actualizada correctamente.';
END;
GO

-- 4. SP simplificada para confirmar recepción (CR)
CREATE OR ALTER PROCEDURE dbo.spInvTransferenciasConfirmarRecepcion
  @IdTransferencia     INT,
  @IdUsuario           INT,
  @IdSesion            INT = NULL,
  @Observacion         NVARCHAR(500) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @EstadoActual CHAR(1);
  DECLARE @TransitoDoc INT;
  DECLARE @DestinoDoc INT;

  SELECT
    @EstadoActual = EstadoTransferencia,
    @TransitoDoc = IdAlmacenTransito,
    @DestinoDoc = IdAlmacenDestino
  FROM dbo.InvTransferencias
  WHERE IdTransferencia = @IdTransferencia AND RowStatus = 1;

  IF @EstadoActual IS NULL
    THROW 50047, 'Transferencia no encontrada.', 1;

  IF @EstadoActual <> 'T'
    THROW 50050, 'Solo se puede confirmar recepcion desde En Transito.', 1;

  -- Crear movimientos para salida en transito
  INSERT INTO dbo.InvMovimientos (
    IdProducto, IdAlmacen, TipoMovimiento, Signo,
    IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
    Cantidad, CostoUnitario, CostoTotal,
    SaldoAnterior, SaldoNuevo,
    Fecha, Periodo, Observacion, UsuarioCreacion
  )
  SELECT
    D.IdProducto,
    @TransitoDoc,
    'SAL',
    -1,
    @IdTransferencia,
    'TRF',
    CONCAT('TRF-', @IdTransferencia),
    D.Cantidad,
    D.Costo,
    D.Total,
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @TransitoDoc),
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @TransitoDoc) - D.Cantidad,
    GETDATE(),
    FORMAT(GETDATE(), 'yyyyMM'),
    @Observacion,
    @IdUsuario
  FROM dbo.InvTransferenciasDetalle D
  WHERE D.IdTransferencia = @IdTransferencia AND D.RowStatus = 1;

  -- Crear movimientos para entrada en destino
  INSERT INTO dbo.InvMovimientos (
    IdProducto, IdAlmacen, TipoMovimiento, Signo,
    IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
    Cantidad, CostoUnitario, CostoTotal,
    SaldoAnterior, SaldoNuevo,
    Fecha, Periodo, Observacion, UsuarioCreacion
  )
  SELECT
    D.IdProducto,
    @DestinoDoc,
    'ENT',
    1,
    @IdTransferencia,
    'TRF',
    CONCAT('TRF-', @IdTransferencia),
    D.Cantidad,
    D.Costo,
    D.Total,
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @DestinoDoc),
    (SELECT ISNULL(Cantidad, 0) FROM dbo.ProductoAlmacenes WHERE IdProducto = D.IdProducto AND IdAlmacen = @DestinoDoc) + D.Cantidad,
    GETDATE(),
    FORMAT(GETDATE(), 'yyyyMM'),
    @Observacion,
    @IdUsuario
  FROM dbo.InvTransferenciasDetalle D
  WHERE D.IdTransferencia = @IdTransferencia AND D.RowStatus = 1;

  -- Actualizar stock
  UPDATE PA
  SET PA.Cantidad = PA.Cantidad - D.Cantidad,
      PA.FechaModificacion = GETDATE(),
      PA.UsuarioModificacion = @IdUsuario
  FROM dbo.ProductoAlmacenes PA
  INNER JOIN dbo.InvTransferenciasDetalle D ON D.IdProducto = PA.IdProducto
  WHERE PA.IdAlmacen = @TransitoDoc
    AND D.IdTransferencia = @IdTransferencia
    AND D.RowStatus = 1;

  UPDATE PA
  SET PA.Cantidad = PA.Cantidad + D.Cantidad,
      PA.FechaModificacion = GETDATE(),
      PA.UsuarioModificacion = @IdUsuario
  FROM dbo.ProductoAlmacenes PA
  INNER JOIN dbo.InvTransferenciasDetalle D ON D.IdProducto = PA.IdProducto
  WHERE PA.IdAlmacen = @DestinoDoc
    AND D.IdTransferencia = @IdTransferencia
    AND D.RowStatus = 1;

  -- Actualizar estado a Completada
  UPDATE dbo.InvTransferencias
  SET EstadoTransferencia = 'C',
      FechaRecepcion = GETDATE(),
      UsuarioRecepcion = @IdUsuario,
      IdSesionRecepcion = @IdSesion,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario
  WHERE IdTransferencia = @IdTransferencia;

  PRINT 'Recepción confirmada correctamente.';
END;
GO

PRINT '123_transferencias_sin_documentos.sql: Tablas y SPs para transferencias sin InvDocumentos.';
GO
