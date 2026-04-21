-- ============================================================
-- Script 162: spEmitirFacturaPOS
-- Convierte un borrador FacDocumentosPOS en un documento
-- definitivo FacDocumentos, registra pagos y movimientos de caja.
-- Ejecutar en una sola transacción.
-- ============================================================

IF OBJECT_ID('dbo.spEmitirFacturaPOS', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spEmitirFacturaPOS
GO

CREATE PROCEDURE dbo.spEmitirFacturaPOS
  @IdDocumentoPOS     INT,
  @IdSesionCaja       INT,
  @IdUsuario          INT,
  -- JSON de pagos: [{IdFormaPago, Monto, MontoBase, IdMoneda, TasaCambio, Referencia, Autorizacion}]
  -- Se itera con OPENJSON (SQL Server 2016+)
  @PagosJSON          NVARCHAR(MAX),
  -- Datos del documento final
  @IdTipoDocumento    INT           = NULL,
  @NCF                VARCHAR(19)   = NULL,
  @IdTipoNCF          INT           = NULL,
  @RNCCliente         VARCHAR(11)   = NULL,
  @FechaDocumento     DATE          = NULL,
  @Comentario         NVARCHAR(500) = NULL
AS
BEGIN
  SET NOCOUNT ON
  SET XACT_ABORT ON

  BEGIN TRANSACTION

  BEGIN TRY

    -- 1. Leer el borrador
    DECLARE
      @IdPuntoEmision   INT,
      @IdCaja           INT,
      @IdCliente        INT,
      @NombreCliente    NVARCHAR(200),
      @SubTotal         DECIMAL(18,2),
      @Descuento        DECIMAL(18,2),
      @Impuesto         DECIMAL(18,2),
      @Propina          DECIMAL(18,2),
      @Total            DECIMAL(18,2),
      @IdMoneda         INT,
      @TasaCambio       DECIMAL(18,6),
      @TipoDocCodigo    VARCHAR(10),
      @IdTipoDocFinal   INT

    SELECT
      @IdPuntoEmision = p.IdPuntoEmision,
      @IdCliente      = p.IdCliente,
      @NombreCliente  = t.Nombre,
      @TasaCambio     = 1
    FROM dbo.FacDocumentosPOS p
    LEFT JOIN dbo.Terceros t       ON t.IdTercero = p.IdCliente
    WHERE p.IdDocumentoPOS = @IdDocumentoPOS AND p.RowStatus = 1

    -- IdMoneda from the tipo documento
    SELECT @IdMoneda = td.IdMoneda
    FROM dbo.FacDocumentosPOS p
    JOIN dbo.FacTiposDocumento td ON td.IdTipoDocumento = p.IdTipoDocumento
    WHERE p.IdDocumentoPOS = @IdDocumentoPOS

    IF @IdPuntoEmision IS NULL
      RAISERROR('Borrador no encontrado o ya fue procesado.', 16, 1)

    -- Calcular totales desde las líneas del borrador
    SELECT
      @SubTotal  = SUM(d.Cantidad * d.PrecioBase),
      @Descuento = SUM(d.DescuentoLinea),
      @Impuesto  = SUM(CASE WHEN d.AplicaImpuesto = 1 THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0) ELSE 0 END),
      @Propina   = 0   -- calcular si aplica según config
    FROM dbo.FacDocumentoPOSDetalle d
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    SET @SubTotal  = ISNULL(@SubTotal, 0)
    SET @Descuento = ISNULL(@Descuento, 0)
    SET @Impuesto  = ISNULL(@Impuesto, 0)
    SET @Total     = @SubTotal - @Descuento + @Impuesto + @Propina

    -- Determinar tipo de documento
    SET @IdTipoDocFinal = ISNULL(@IdTipoDocumento,
      (SELECT TOP 1 IdTipoDocumento FROM dbo.FacTiposDocumento
       WHERE Activo = 1 AND RowStatus = 1 ORDER BY IdTipoDocumento))

    SELECT @TipoDocCodigo = Codigo
    FROM dbo.FacTiposDocumento
    WHERE IdTipoDocumento = @IdTipoDocFinal

    -- Obtener caja de la sesión (opcional — si no hay sesión se omiten movimientos de caja)
    IF @IdSesionCaja IS NOT NULL
    BEGIN
      SELECT @IdCaja = IdCaja
      FROM dbo.FacCajasSesiones
      WHERE IdSesion = @IdSesionCaja AND Estado = 'AB'
    END

    -- Obtener próxima secuencia
    DECLARE @Secuencia INT = 0
    SELECT @Secuencia = ISNULL(MAX(Secuencia), 0) + 1
    FROM dbo.FacDocumentos
    WHERE IdPuntoEmision = @IdPuntoEmision
      AND TipoDocumentoCodigo = @TipoDocCodigo

    -- 2. Insertar FacDocumentos
    DECLARE @IdDocumento INT

    INSERT INTO dbo.FacDocumentos (
      IdTipoDocumento, TipoDocumentoCodigo,
      IdDocumentoPOSOrigen,
      NCF, IdTipoNCF, RNCCliente,
      IdPuntoEmision, IdCaja, IdSesionCaja,
      IdUsuario, IdCliente, NombreCliente,
      Secuencia, FechaDocumento,
      SubTotal, Descuento, Impuesto, Propina, Total,
      IdMoneda, TasaCambio, Comentario, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdTipoDocFinal, ISNULL(@TipoDocCodigo, 'FAC'),
      @IdDocumentoPOS,
      @NCF, @IdTipoNCF, @RNCCliente,
      @IdPuntoEmision, @IdCaja, @IdSesionCaja,
      @IdUsuario, @IdCliente, @NombreCliente,
      @Secuencia, ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
      @SubTotal, @Descuento, @Impuesto, @Propina, @Total,
      @IdMoneda, @TasaCambio, @Comentario, 'EM',
      @IdUsuario, GETDATE()
    )

    SET @IdDocumento = SCOPE_IDENTITY()

    -- 3. Copiar líneas del borrador → FacDocumentoDetalle
    INSERT INTO dbo.FacDocumentoDetalle (
      IdDocumento, NumeroLinea,
      IdProducto, Codigo, Descripcion,
      Cantidad, Unidad, PrecioBase,
      PorcentajeImpuesto, AplicaImpuesto, AplicaPropina,
      DescuentoLinea, ComentarioLinea,
      SubTotalLinea, ImpuestoLinea, TotalLinea
    )
    SELECT
      @IdDocumento,
      ROW_NUMBER() OVER (ORDER BY d.IdDetalle),
      d.IdProducto, p.Codigo, d.Descripcion,
      d.Cantidad, d.Unidad, d.PrecioBase,
      d.PorcentajeImpuesto, d.AplicaImpuesto, d.AplicaPropina,
      d.DescuentoLinea, d.ComentarioLinea,
      d.Cantidad * d.PrecioBase,
      CASE WHEN d.AplicaImpuesto = 1 THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0) ELSE 0 END,
      (d.Cantidad * d.PrecioBase)
        + CASE WHEN d.AplicaImpuesto = 1 THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0) ELSE 0 END
        - d.DescuentoLinea
    FROM dbo.FacDocumentoPOSDetalle d
    LEFT JOIN dbo.Productos p ON p.IdProducto = d.IdProducto
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    -- 4. Registrar pagos desde JSON
    DECLARE @TotalPagado DECIMAL(18,2) = 0

    INSERT INTO dbo.FacDocumentoPagos (
      IdDocumento, IdFormaPago, Monto, MontoBase,
      IdMoneda, TasaCambio, Referencia, Autorizacion,
      IdUsuarioCreacion, FechaCreacion
    )
    SELECT
      @IdDocumento,
      CAST(j.IdFormaPago     AS INT),
      CAST(j.Monto           AS DECIMAL(18,2)),
      CAST(ISNULL(j.MontoBase, j.Monto) AS DECIMAL(18,2)),
      CAST(j.IdMoneda        AS INT),
      CAST(ISNULL(j.TasaCambio, 1) AS DECIMAL(18,6)),
      j.Referencia,
      j.Autorizacion,
      @IdUsuario, GETDATE()
    FROM OPENJSON(@PagosJSON) WITH (
      IdFormaPago   INT            '$.IdFormaPago',
      Monto         DECIMAL(18,2)  '$.Monto',
      MontoBase     DECIMAL(18,2)  '$.MontoBase',
      IdMoneda      INT            '$.IdMoneda',
      TasaCambio    DECIMAL(18,6)  '$.TasaCambio',
      Referencia    NVARCHAR(100)  '$.Referencia',
      Autorizacion  NVARCHAR(100)  '$.Autorizacion'
    ) j

    -- Actualizar TotalPagado
    SELECT @TotalPagado = SUM(Monto)
    FROM dbo.FacDocumentoPagos
    WHERE IdDocumento = @IdDocumento AND RowStatus = 1

    UPDATE dbo.FacDocumentos SET
      TotalPagado = ISNULL(@TotalPagado, 0)
    WHERE IdDocumento = @IdDocumento

    -- 5. Registrar movimientos de caja por cada pago (solo si hay sesión activa)
    IF @IdSesionCaja IS NOT NULL
    BEGIN
      INSERT INTO dbo.FacMovimientosCaja (
        IdSesion, IdDocumento, IdFormaPago,
        TipoMovimiento, TipoValor, Monto,
        IdUsuarioCreacion, FechaCreacion
      )
      SELECT
        @IdSesionCaja,
        @IdDocumento,
        p.IdFormaPago,
        'COBRO',
        f.TipoValor,
        p.Monto,
        @IdUsuario, GETDATE()
      FROM dbo.FacDocumentoPagos p
      JOIN dbo.FacFormasPago f ON f.IdFormaPago = p.IdFormaPago
      WHERE p.IdDocumento = @IdDocumento AND p.RowStatus = 1
    END

    -- 6. Marcar borrador como procesado
    UPDATE dbo.FacDocumentosPOS SET
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      IdUsuarioModif = @IdUsuario
    WHERE IdDocumentoPOS = @IdDocumentoPOS

    COMMIT TRANSACTION

    -- Retornar el documento generado
    SELECT
      d.IdDocumento,
      d.Secuencia,
      d.NCF,
      d.TipoDocumentoCodigo,
      d.Total,
      d.TotalPagado,
      d.Estado
    FROM dbo.FacDocumentos d
    WHERE d.IdDocumento = @IdDocumento

  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
    RAISERROR(@ErrMsg, 16, 1)
  END CATCH

END
GO
