-- ============================================================
-- Script 168: Fix FacDocumentosPOS + spFacDocumentosPOSCRUD + spEmitirFacturaPOS
--
-- Problemas corregidos:
--   1. FacDocumentosPOS faltaban IdMoneda y TasaCambio
--   2. spFacDocumentosPOSCRUD recrea con IdMoneda/TasaCambio (sin Estado - eliminado en 155)
--   3. spEmitirFacturaPOS: usa d.Codigo (borrador) en vez de JOIN a Productos
-- ============================================================

-- ── 1. Agregar IdMoneda y TasaCambio a FacDocumentosPOS ─────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentosPOS')
      AND name = 'IdMoneda'
)
BEGIN
    ALTER TABLE dbo.FacDocumentosPOS
        ADD IdMoneda   INT            NULL,
            TasaCambio DECIMAL(18,6)  NOT NULL DEFAULT 1;
    PRINT 'Columnas FacDocumentosPOS.IdMoneda y TasaCambio agregadas.';
END
ELSE
    PRINT 'Columnas FacDocumentosPOS.IdMoneda/TasaCambio ya existen.';
GO

-- ── 2. Recrear spFacDocumentosPOSCRUD con IdMoneda/TasaCambio ──
IF OBJECT_ID('dbo.spFacDocumentosPOSCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spFacDocumentosPOSCRUD;
GO

CREATE PROCEDURE dbo.spFacDocumentosPOSCRUD
    @Accion             CHAR(1),
    @IdDocumentoPOS     INT             = NULL,
    @IdPuntoEmision     INT             = NULL,
    @IdUsuario          INT             = NULL,
    @IdCliente          INT             = NULL,
    @ReferenciaCliente  NVARCHAR(150)   = NULL,
    @Referencia         NVARCHAR(100)   = NULL,
    @ComentarioGeneral  NVARCHAR(500)   = NULL,
    @IdTipoDocumento    INT             = NULL,
    @IdAlmacen          INT             = NULL,
    @FechaDocumento     DATE            = NULL,
    @Vendedor           NVARCHAR(100)   = NULL,
    @Notas              NVARCHAR(500)   = NULL,
    @IdMoneda           INT             = NULL,
    @TasaCambio         DECIMAL(18,6)   = 1,
    @LineasJson         NVARCHAR(MAX)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- I: Insertar nuevo documento con sus lineas
    IF @Accion = 'I'
    BEGIN
        DECLARE @NewId INT;
        INSERT INTO dbo.FacDocumentosPOS (
            IdPuntoEmision, IdUsuario, IdCliente, ReferenciaCliente, Referencia,
            ComentarioGeneral, IdTipoDocumento, IdAlmacen, FechaDocumento, Vendedor,
            IdMoneda, TasaCambio, Notas, IdUsuarioCreacion
        ) VALUES (
            @IdPuntoEmision, @IdUsuario, @IdCliente, @ReferenciaCliente, @Referencia,
            @ComentarioGeneral, @IdTipoDocumento, @IdAlmacen,
            ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
            @Vendedor,
            @IdMoneda, ISNULL(@TasaCambio, 1),
            @Notas, @IdUsuario
        );
        SET @NewId = SCOPE_IDENTITY();
        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea, ComentarioLinea
            )
            SELECT @NewId, CAST(j.NumLinea AS INT), NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo, j.Descripcion, CAST(j.Cantidad AS DECIMAL(18,4)), j.Unidad,
                CAST(j.PrecioBase AS DECIMAL(18,4)), CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto AS BIT), CAST(j.AplicaPropina AS BIT),
                CAST(j.DescuentoLinea AS DECIMAL(18,4)), j.ComentarioLinea
            FROM OPENJSON(@LineasJson) WITH (
                NumLinea            INT             '$.numLinea',
                IdProducto          INT             '$.productId',
                Codigo              NVARCHAR(50)    '$.code',
                Descripcion         NVARCHAR(200)   '$.description',
                Cantidad            DECIMAL(18,4)   '$.quantity',
                Unidad              NVARCHAR(20)    '$.unit',
                PrecioBase          DECIMAL(18,4)   '$.basePrice',
                PorcentajeImpuesto  DECIMAL(8,4)    '$.taxRate',
                AplicaImpuesto      BIT             '$.applyTax',
                AplicaPropina       BIT             '$.applyTip',
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount',
                ComentarioLinea     NVARCHAR(300)   '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @NewId AS IdDocumentoPOS;
        RETURN;
    END

    -- U: Actualizar encabezado + reemplazar lineas
    IF @Accion = 'U'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            IdCliente         = ISNULL(@IdCliente,         IdCliente),
            ReferenciaCliente = ISNULL(@ReferenciaCliente, ReferenciaCliente),
            Referencia        = ISNULL(@Referencia,        Referencia),
            ComentarioGeneral = @ComentarioGeneral,
            IdTipoDocumento   = ISNULL(@IdTipoDocumento,   IdTipoDocumento),
            IdAlmacen         = ISNULL(@IdAlmacen,         IdAlmacen),
            FechaDocumento    = ISNULL(@FechaDocumento,    FechaDocumento),
            Vendedor          = ISNULL(@Vendedor,          Vendedor),
            Notas             = ISNULL(@Notas,             Notas),
            IdMoneda          = ISNULL(@IdMoneda,          IdMoneda),
            TasaCambio        = ISNULL(@TasaCambio,        TasaCambio),
            FechaModificacion = GETDATE(),
            IdUsuarioModif    = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS AND RowStatus = 1;

        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            DELETE FROM dbo.FacDocumentoPOSDetalle WHERE IdDocumentoPOS = @IdDocumentoPOS;
            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea, ComentarioLinea
            )
            SELECT @IdDocumentoPOS, CAST(j.NumLinea AS INT), NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo, j.Descripcion, CAST(j.Cantidad AS DECIMAL(18,4)), j.Unidad,
                CAST(j.PrecioBase AS DECIMAL(18,4)), CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto AS BIT), CAST(j.AplicaPropina AS BIT),
                CAST(j.DescuentoLinea AS DECIMAL(18,4)), j.ComentarioLinea
            FROM OPENJSON(@LineasJson) WITH (
                NumLinea            INT             '$.numLinea',
                IdProducto          INT             '$.productId',
                Codigo              NVARCHAR(50)    '$.code',
                Descripcion         NVARCHAR(200)   '$.description',
                Cantidad            DECIMAL(18,4)   '$.quantity',
                Unidad              NVARCHAR(20)    '$.unit',
                PrecioBase          DECIMAL(18,4)   '$.basePrice',
                PorcentajeImpuesto  DECIMAL(8,4)    '$.taxRate',
                AplicaImpuesto      BIT             '$.applyTax',
                AplicaPropina       BIT             '$.applyTip',
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount',
                ComentarioLinea     NVARCHAR(300)   '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    -- L: Listar pendientes de un punto de emision
    IF @Accion = 'L'
    BEGIN
        SELECT
            D.IdDocumentoPOS, D.IdPuntoEmision, D.IdCliente,
            ISNULL(D.ReferenciaCliente, T.Nombre) AS NombreCliente,
            D.ReferenciaCliente, D.Referencia, D.ComentarioGeneral,
            D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento,
            D.FechaDocumento, D.Vendedor, D.Notas,
            D.IdMoneda, D.TasaCambio,
            D.FechaCreacion, D.FechaModificacion,
            LTRIM(RTRIM(ISNULL(U.Nombres,'') + ' ' + ISNULL(U.Apellidos,''))) AS NombreUsuario,
            (SELECT COUNT(*) FROM dbo.FacDocumentoPOSDetalle DL
             WHERE DL.IdDocumentoPOS = D.IdDocumentoPOS AND DL.RowStatus = 1
               AND DL.IdProducto IS NOT NULL) AS CantidadLineas,
            (SELECT SUM(
                (DL.Cantidad * DL.PrecioBase)
                + CASE WHEN DL.AplicaImpuesto = 1
                       THEN DL.Cantidad * DL.PrecioBase * (DL.PorcentajeImpuesto / 100)
                       ELSE 0 END
                - DL.DescuentoLinea
             ) FROM dbo.FacDocumentoPOSDetalle DL
             WHERE DL.IdDocumentoPOS = D.IdDocumentoPOS AND DL.RowStatus = 1) AS TotalEstimado
        FROM dbo.FacDocumentosPOS D
        LEFT JOIN dbo.Terceros T           ON T.IdTercero = D.IdCliente
        LEFT JOIN dbo.FacTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
        LEFT JOIN dbo.Usuarios U           ON U.IdUsuario = D.IdUsuario
        WHERE D.IdPuntoEmision = @IdPuntoEmision
          AND D.RowStatus = 1
        ORDER BY D.FechaModificacion DESC, D.FechaCreacion DESC;
        RETURN;
    END

    -- O: Obtener documento con sus lineas
    IF @Accion = 'O'
    BEGIN
        SELECT
            D.IdDocumentoPOS, D.IdPuntoEmision, D.IdCliente,
            ISNULL(D.ReferenciaCliente, T.Nombre) AS NombreCliente,
            D.ReferenciaCliente, D.Referencia, D.ComentarioGeneral,
            D.IdTipoDocumento, D.IdAlmacen, D.FechaDocumento, D.Vendedor,
            D.Notas, D.IdMoneda, D.TasaCambio,
            D.FechaCreacion, D.IdUsuario, D.IdUsuarioCreacion
        FROM dbo.FacDocumentosPOS D
        LEFT JOIN dbo.Terceros T ON T.IdTercero = D.IdCliente
        WHERE D.IdDocumentoPOS = @IdDocumentoPOS AND D.RowStatus = 1;

        SELECT
            DL.IdDetalle, DL.NumLinea, DL.IdProducto, DL.Codigo, DL.Descripcion,
            DL.Cantidad, DL.Unidad, DL.PrecioBase, DL.PorcentajeImpuesto,
            DL.AplicaImpuesto, DL.AplicaPropina, DL.DescuentoLinea, DL.ComentarioLinea
        FROM dbo.FacDocumentoPOSDetalle DL
        WHERE DL.IdDocumentoPOS = @IdDocumentoPOS AND DL.RowStatus = 1
        ORDER BY DL.NumLinea;
        RETURN;
    END

    -- X: Anular (soft-delete)
    IF @Accion = 'X'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            RowStatus         = 0,
            FechaModificacion = GETDATE(),
            IdUsuarioModif    = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS AND RowStatus = 1;
        RETURN;
    END
END
GO

-- ── 3. Recrear spEmitirFacturaPOS con los fixes ─────────────
IF OBJECT_ID('dbo.spEmitirFacturaPOS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spEmitirFacturaPOS;
GO

CREATE PROCEDURE dbo.spEmitirFacturaPOS
  @IdDocumentoPOS     INT,
  @IdSesionCaja       INT           = NULL,
  @IdUsuario          INT,
  @PagosJSON          NVARCHAR(MAX),
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
      @NombreCliente  = ISNULL(p.ReferenciaCliente, t.Nombre),
      @IdMoneda       = p.IdMoneda,
      @TasaCambio     = ISNULL(p.TasaCambio, 1)
    FROM dbo.FacDocumentosPOS p
    LEFT JOIN dbo.Terceros t ON t.IdTercero = p.IdCliente
    WHERE p.IdDocumentoPOS = @IdDocumentoPOS AND p.RowStatus = 1

    IF @IdPuntoEmision IS NULL
      RAISERROR('Borrador no encontrado o ya fue procesado.', 16, 1)

    -- Si el borrador no tenía moneda, tomar la del tipo de documento
    IF @IdMoneda IS NULL
    BEGIN
      SELECT @IdMoneda = td.IdMoneda
      FROM dbo.FacDocumentosPOS p
      JOIN dbo.FacTiposDocumento td ON td.IdTipoDocumento = p.IdTipoDocumento
      WHERE p.IdDocumentoPOS = @IdDocumentoPOS
    END

    -- Calcular totales desde las líneas del borrador
    SELECT
      @SubTotal  = SUM(d.Cantidad * d.PrecioBase),
      @Descuento = SUM(d.DescuentoLinea),
      @Impuesto  = SUM(CASE WHEN d.AplicaImpuesto = 1
                            THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0)
                            ELSE 0 END),
      @Propina   = 0
    FROM dbo.FacDocumentoPOSDetalle d
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    SET @SubTotal  = ISNULL(@SubTotal, 0)
    SET @Descuento = ISNULL(@Descuento, 0)
    SET @Impuesto  = ISNULL(@Impuesto, 0)
    SET @Total     = @SubTotal - @Descuento + @Impuesto + @Propina

    -- Determinar tipo de documento final
    SELECT @IdTipoDocFinal = ISNULL(@IdTipoDocumento, p.IdTipoDocumento)
    FROM dbo.FacDocumentosPOS p
    WHERE p.IdDocumentoPOS = @IdDocumentoPOS

    IF @IdTipoDocFinal IS NULL
      SET @IdTipoDocFinal = (
        SELECT TOP 1 IdTipoDocumento
        FROM dbo.FacTiposDocumento
        WHERE Activo = 1 AND RowStatus = 1
        ORDER BY IdTipoDocumento
      )

    SELECT @TipoDocCodigo = Codigo
    FROM dbo.FacTiposDocumento
    WHERE IdTipoDocumento = @IdTipoDocFinal

    -- Obtener caja de la sesión (opcional)
    IF @IdSesionCaja IS NOT NULL
    BEGIN
      SELECT @IdCaja = IdCaja
      FROM dbo.FacCajasSesiones
      WHERE IdSesion = @IdSesionCaja AND Estado = 'AB'
    END

    -- Obtener próxima secuencia
    DECLARE @Secuencia INT
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
    --    FIX: usar d.Codigo (desnorm. en el borrador) en vez del JOIN a Productos
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
      d.IdProducto,
      d.Codigo,
      d.Descripcion,
      d.Cantidad,
      d.Unidad,
      d.PrecioBase,
      d.PorcentajeImpuesto,
      d.AplicaImpuesto,
      d.AplicaPropina,
      d.DescuentoLinea,
      d.ComentarioLinea,
      d.Cantidad * d.PrecioBase,
      CASE WHEN d.AplicaImpuesto = 1
           THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0)
           ELSE 0 END,
      (d.Cantidad * d.PrecioBase)
        + CASE WHEN d.AplicaImpuesto = 1
               THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0)
               ELSE 0 END
        - d.DescuentoLinea
    FROM dbo.FacDocumentoPOSDetalle d
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    -- 4. Registrar pagos desde JSON
    INSERT INTO dbo.FacDocumentoPagos (
      IdDocumento, IdFormaPago, Monto, MontoBase,
      IdMoneda, TasaCambio, Referencia, Autorizacion,
      IdUsuarioCreacion, FechaCreacion
    )
    SELECT
      @IdDocumento,
      CAST(j.IdFormaPago            AS INT),
      CAST(j.Monto                  AS DECIMAL(18,2)),
      CAST(ISNULL(j.MontoBase, j.Monto) AS DECIMAL(18,2)),
      CAST(j.IdMoneda               AS INT),
      CAST(ISNULL(j.TasaCambio, 1)  AS DECIMAL(18,6)),
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
    DECLARE @TotalPagado DECIMAL(18,2)
    SELECT @TotalPagado = ISNULL(SUM(Monto), 0)
    FROM dbo.FacDocumentoPagos
    WHERE IdDocumento = @IdDocumento AND RowStatus = 1

    UPDATE dbo.FacDocumentos SET TotalPagado = @TotalPagado
    WHERE IdDocumento = @IdDocumento

    -- 5. Registrar movimientos de caja (solo si hay sesión activa)
    IF @IdSesionCaja IS NOT NULL
    BEGIN
      INSERT INTO dbo.FacMovimientosCaja (
        IdSesion, IdDocumento, IdFormaPago,
        TipoMovimiento, TipoValor, Monto,
        IdUsuarioCreacion, FechaCreacion
      )
      SELECT
        @IdSesionCaja, @IdDocumento, p.IdFormaPago,
        'COBRO', f.TipoValor, p.Monto,
        @IdUsuario, GETDATE()
      FROM dbo.FacDocumentoPagos p
      JOIN dbo.FacFormasPago f ON f.IdFormaPago = p.IdFormaPago
      WHERE p.IdDocumento = @IdDocumento AND p.RowStatus = 1
    END

    -- 6. Marcar borrador como procesado
    UPDATE dbo.FacDocumentosPOS SET
      RowStatus = 0, FechaModificacion = GETDATE(), IdUsuarioModif = @IdUsuario
    WHERE IdDocumentoPOS = @IdDocumentoPOS

    COMMIT TRANSACTION

    SELECT d.IdDocumento, d.Secuencia, d.NCF, d.TipoDocumentoCodigo,
           d.Total, d.TotalPagado, d.Estado
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

PRINT 'Script 168 aplicado correctamente.';
GO
