-- ============================================================
-- 44.4) spInvActualizarDocumento con movimientos de reversa+nuevos
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spInvActualizarDocumento
  @IdDocumento         INT,
  @IdTipoDocumento     INT             = NULL,
  @Fecha               DATE,
  @IdAlmacen           INT,
  @IdMoneda            INT             = NULL,
  @TasaCambio          DECIMAL(18,6)   = 1.000000,
  @Referencia          NVARCHAR(250)   = NULL,
  @Observacion         NVARCHAR(500)   = NULL,
  @DetalleJSON         NVARCHAR(MAX),
  @IdUsuario           INT             = NULL,
  @IdSesion            INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    DECLARE @OldTipoOp CHAR(1), @OldAlmacen INT, @OldTipoDocumento INT, @OldActualizaCosto BIT;
    DECLARE @DocNum VARCHAR(30), @DocPeriodo VARCHAR(6);
    SELECT
      @OldTipoOp = d.TipoOperacion,
      @OldAlmacen = d.IdAlmacen,
      @OldTipoDocumento = d.IdTipoDocumento,
      @OldActualizaCosto = ISNULL(t.ActualizaCosto, 0),
      @DocNum = d.NumeroDocumento,
      @DocPeriodo = d.Periodo
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
    WHERE d.IdDocumento = @IdDocumento
      AND d.RowStatus = 1
      AND d.Estado = 'A';

    IF @OldTipoOp IS NULL
      THROW 50020, 'Documento no encontrado o no editable (anulado).', 1;

    IF @IdTipoDocumento IS NULL SET @IdTipoDocumento = @OldTipoDocumento;

    DECLARE @NewTipoOp CHAR(1), @TipoMoneda INT, @NewActualizaCosto BIT;
    SELECT
      @NewTipoOp = t.TipoOperacion,
      @TipoMoneda = t.IdMoneda,
      @NewActualizaCosto = ISNULL(t.ActualizaCosto, 0)
    FROM dbo.InvTiposDocumento t
    WHERE t.IdTipoDocumento = @IdTipoDocumento
      AND t.RowStatus = 1;

    IF @NewTipoOp IS NULL
      THROW 50021, 'Tipo de documento no valido.', 1;

    IF @NewTipoOp <> @OldTipoOp
      THROW 50022, 'No se permite cambiar tipo de operacion en edicion.', 1;

    IF @IdMoneda IS NULL SET @IdMoneda = @TipoMoneda;

    -- Reversa del detalle previo con movimiento ANU
    DECLARE @LineaOld INT, @ProdOld INT, @CantOld DECIMAL(18,4), @CostoOld DECIMAL(18,4), @TotalOld DECIMAL(18,4), @CantBaseOld DECIMAL(18,4);
    DECLARE @StockAntesOld DECIMAL(18,4), @StockNuevoOld DECIMAL(18,4), @SignoOld SMALLINT;
    DECLARE @CostoPromAntesOld DECIMAL(10,4), @CostoPromNuevoOld DECIMAL(10,4), @CostoBaseOld DECIMAL(18,4);

    DECLARE c_old CURSOR LOCAL FAST_FORWARD FOR
    SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
           dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento
      AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;

    OPEN c_old;
    FETCH NEXT FROM c_old INTO @LineaOld, @ProdOld, @CantOld, @CostoOld, @TotalOld, @CantBaseOld;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @CostoBaseOld = CASE WHEN ISNULL(@CantBaseOld, 0) > 0 THEN ROUND(@TotalOld / @CantBaseOld, 4) ELSE @CostoOld END;

      SELECT @CostoPromAntesOld = ISNULL(p.CostoPromedio, 0)
      FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
      WHERE p.IdProducto = @ProdOld;

      SELECT @StockAntesOld = ISNULL(pa.Cantidad, 0)
      FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
      WHERE pa.IdProducto = @ProdOld
        AND pa.IdAlmacen = @OldAlmacen
        AND pa.RowStatus = 1;

      IF @OldTipoOp IN ('E', 'C')
      BEGIN
        SET @SignoOld = -1;
        SET @StockNuevoOld = @StockAntesOld - @CantBaseOld;

        SET @CostoPromNuevoOld = @CostoPromAntesOld;
        IF @OldActualizaCosto = 1
        BEGIN
          SET @CostoPromNuevoOld = CASE
            WHEN (@StockAntesOld - @CantBaseOld) > 0 THEN ROUND(((@CostoPromAntesOld * @StockAntesOld) - (@CostoOld * @CantOld)) / (@StockAntesOld - @CantBaseOld), 4)
            ELSE @CostoPromAntesOld
          END;

          UPDATE dbo.Productos
          SET
            CostoPromedio = @CostoPromNuevoOld,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @ProdOld;
        END

        UPDATE dbo.ProductoAlmacenes
        SET
          Cantidad = @StockNuevoOld,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdOld
          AND IdAlmacen = @OldAlmacen
          AND RowStatus = 1;
      END
      ELSE
      BEGIN
        SET @SignoOld = 1;
        SET @StockNuevoOld = @StockAntesOld + @CantBaseOld;
        SET @CostoPromNuevoOld = @CostoPromAntesOld;

        UPDATE dbo.ProductoAlmacenes
        SET
          Cantidad = @StockNuevoOld,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdOld
          AND IdAlmacen = @OldAlmacen
          AND RowStatus = 1;
      END

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo,
        IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
        Cantidad, CostoUnitario, CostoTotal,
        SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo,
        Fecha, Periodo, UsuarioCreacion,
        Observacion
      )
      VALUES (
        @ProdOld,
        @OldAlmacen,
        'ANU',
        @SignoOld,
        @IdDocumento,
        'InvDocumento',
        @DocNum,
        @LineaOld,
        @CantBaseOld,
        @CostoBaseOld,
        @TotalOld,
        @StockAntesOld,
        @StockNuevoOld,
        @CostoPromAntesOld,
        @CostoPromNuevoOld,
        @Fecha,
        CONVERT(VARCHAR(6), @Fecha, 112),
        @IdUsuario,
        N'Reversion por edicion'
      );

      FETCH NEXT FROM c_old INTO @LineaOld, @ProdOld, @CantOld, @CostoOld, @TotalOld, @CantBaseOld;
    END

    CLOSE c_old;
    DEALLOCATE c_old;

    -- Soft delete detalle actual (historico)
    UPDATE dbo.InvDocumentoDetalle
    SET RowStatus = 0
    WHERE IdDocumento = @IdDocumento
      AND RowStatus = 1;

    DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);

    UPDATE dbo.InvDocumentos
    SET
      IdTipoDocumento = @IdTipoDocumento,
      Fecha = @Fecha,
      Periodo = @Periodo,
      IdAlmacen = @IdAlmacen,
      IdMoneda = @IdMoneda,
      TasaCambio = @TasaCambio,
      Referencia = @Referencia,
      Observacion = @Observacion,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario,
      IdSesionModif = @IdSesion
    WHERE IdDocumento = @IdDocumento;

    -- Inserta nuevo detalle
    INSERT INTO dbo.InvDocumentoDetalle (
      IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
      IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
    )
    SELECT
      @IdDocumento,
      j.linea,
      j.idProducto,
      j.codigo,
      j.descripcion,
      j.idUnidadMedida,
      j.unidad,
      j.cantidad,
      j.costo,
      ROUND(j.cantidad * j.costo, 4),
      @IdUsuario
    FROM OPENJSON(@DetalleJSON)
    WITH (
      linea          INT            '$.linea',
      idProducto     INT            '$.idProducto',
      codigo         NVARCHAR(60)   '$.codigo',
      descripcion    NVARCHAR(200)  '$.descripcion',
      idUnidadMedida INT            '$.idUnidadMedida',
      unidad         NVARCHAR(50)   '$.unidad',
      cantidad       DECIMAL(18,4)  '$.cantidad',
      costo          DECIMAL(18,4)  '$.costo'
    ) j
    WHERE j.idProducto IS NOT NULL
      AND j.cantidad > 0;

    IF @OldTipoOp IN ('E', 'C')
    BEGIN
      INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
      SELECT DISTINCT det.IdProducto, @IdAlmacen, 0, @IdUsuario
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @IdDocumento
        AND det.RowStatus = 1
        AND NOT EXISTS (
          SELECT 1
          FROM dbo.ProductoAlmacenes pa
          WHERE pa.IdProducto = det.IdProducto
            AND pa.IdAlmacen = @IdAlmacen
            AND pa.RowStatus = 1
        );
    END

    DECLARE @LineaNew INT, @ProdNew INT, @CantNew DECIMAL(18,4), @CostoNew DECIMAL(18,4), @TotalNew DECIMAL(18,4), @CantBaseNew DECIMAL(18,4);
    DECLARE @StockAntesNew DECIMAL(18,4), @StockNuevoNew DECIMAL(18,4), @SignoNew SMALLINT;
    DECLARE @CostoPromAntesNew DECIMAL(10,4), @CostoPromNuevoNew DECIMAL(10,4), @CostoBaseNew DECIMAL(18,4);
    DECLARE @ManejaNew BIT, @VendeSinNew BIT;

    DECLARE c_new CURSOR LOCAL FAST_FORWARD FOR
    SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
           dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento
      AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;

    OPEN c_new;
    FETCH NEXT FROM c_new INTO @LineaNew, @ProdNew, @CantNew, @CostoNew, @TotalNew, @CantBaseNew;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @CostoBaseNew = CASE WHEN ISNULL(@CantBaseNew, 0) > 0 THEN ROUND(@TotalNew / @CantBaseNew, 4) ELSE @CostoNew END;

      SELECT
        @CostoPromAntesNew = ISNULL(p.CostoPromedio, 0),
        @ManejaNew = ISNULL(p.ManejaExistencia, 1),
        @VendeSinNew = ISNULL(p.VenderSinExistencia, 0)
      FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
      WHERE p.IdProducto = @ProdNew;

      SELECT @StockAntesNew = ISNULL(pa.Cantidad, 0)
      FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
      WHERE pa.IdProducto = @ProdNew
        AND pa.IdAlmacen = @IdAlmacen
        AND pa.RowStatus = 1;

      SET @SignoNew = CASE WHEN @OldTipoOp IN ('E', 'C') THEN 1 ELSE -1 END;

      IF @OldTipoOp = 'S' AND @ManejaNew = 1 AND @VendeSinNew = 0 AND @StockAntesNew < @CantBaseNew
      BEGIN
        CLOSE c_new;
        DEALLOCATE c_new;
        THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
      END

      SET @StockNuevoNew = @StockAntesNew + (@SignoNew * @CantBaseNew);

      UPDATE dbo.ProductoAlmacenes
      SET
        Cantidad = @StockNuevoNew,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdProducto = @ProdNew
        AND IdAlmacen = @IdAlmacen
        AND RowStatus = 1;

      SET @CostoPromNuevoNew = @CostoPromAntesNew;
      IF @OldTipoOp IN ('E', 'C') AND @NewActualizaCosto = 1
      BEGIN
        SET @CostoPromNuevoNew = CASE
          WHEN @StockNuevoNew > 0 THEN ROUND(((@CostoPromAntesNew * @StockAntesNew) + @TotalNew) / @StockNuevoNew, 4)
          ELSE @CostoBaseNew
        END;

        UPDATE dbo.Productos
        SET
          CostoPromedio = @CostoPromNuevoNew,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdNew;
      END

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo,
        IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
        Cantidad, CostoUnitario, CostoTotal,
        SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo,
        Fecha, Periodo, UsuarioCreacion,
        Observacion
      )
      VALUES (
        @ProdNew,
        @IdAlmacen,
        CASE @OldTipoOp WHEN 'E' THEN 'ENT' WHEN 'S' THEN 'SAL' WHEN 'C' THEN 'COM' ELSE 'TRF' END,
        @SignoNew,
        @IdDocumento,
        'InvDocumento',
        @DocNum,
        @LineaNew,
        @CantBaseNew,
        @CostoBaseNew,
        @TotalNew,
        @StockAntesNew,
        @StockNuevoNew,
        @CostoPromAntesNew,
        @CostoPromNuevoNew,
        @Fecha,
        @Periodo,
        @IdUsuario,
        N'Reaplicacion por edicion'
      );

      FETCH NEXT FROM c_new INTO @LineaNew, @ProdNew, @CantNew, @CostoNew, @TotalNew, @CantBaseNew;
    END

    CLOSE c_new;
    DEALLOCATE c_new;

    UPDATE d
    SET d.TotalDocumento = x.TotalDoc
    FROM dbo.InvDocumentos d
    CROSS APPLY (
      SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = d.IdDocumento
        AND det.RowStatus = 1
    ) x
    WHERE d.IdDocumento = @IdDocumento;

    COMMIT TRANSACTION;
    EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @IdDocumento;
  END TRY
  BEGIN CATCH
    IF CURSOR_STATUS('local', 'c_old') >= -1 BEGIN TRY CLOSE c_old; END TRY BEGIN CATCH END CATCH;
    IF CURSOR_STATUS('local', 'c_old') >= -1 BEGIN TRY DEALLOCATE c_old; END TRY BEGIN CATCH END CATCH;
    IF CURSOR_STATUS('local', 'c_new') >= -1 BEGIN TRY CLOSE c_new; END TRY BEGIN CATCH END CATCH;
    IF CURSOR_STATUS('local', 'c_new') >= -1 BEGIN TRY DEALLOCATE c_new; END TRY BEGIN CATCH END CATCH;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END

GO

CREATE OR ALTER PROCEDURE dbo.spInvTransferenciasCRUD
  @Accion              CHAR(2)        = 'L',
  @IdDocumento         INT            = NULL,
  @IdTipoDocumento     INT            = NULL,
  @Fecha               DATE           = NULL,
  @IdAlmacen           INT            = NULL,
  @IdAlmacenDestino    INT            = NULL,
  @EstadoTransferencia CHAR(1)        = NULL,
  @Referencia          NVARCHAR(250)  = NULL,
  @Observacion         NVARCHAR(500)  = NULL,
  @DetalleJSON         NVARCHAR(MAX)  = NULL,
  @IdUsuario           INT            = NULL,
  @NumeroPagina        INT            = 1,
  @TamanoPagina        INT            = 20,
  @FechaDesde          DATE           = NULL,
  @FechaHasta          DATE           = NULL,
  @IdSesion            INT            = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    ;WITH Base AS (
      SELECT
        D.IdDocumento, D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento, D.TipoOperacion, D.Periodo, D.Secuencia,
        D.NumeroDocumento, D.Fecha, D.IdAlmacen, AO.Descripcion AS NombreAlmacen, D.IdMoneda, M.Nombre AS NombreMoneda,
        M.Simbolo AS SimboloMoneda, D.TasaCambio, D.Referencia, D.Observacion, D.TotalDocumento, D.Estado,
        T.IdAlmacenDestino, AD.Descripcion AS NombreAlmacenDestino, T.IdAlmacenTransito, ATN.Descripcion AS NombreAlmacenTransito,
        T.EstadoTransferencia, T.FechaSalida, T.FechaRecepcion
      FROM dbo.InvDocumentos D
      INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento AND T.RowStatus = 1
      INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
      INNER JOIN dbo.Almacenes AO ON AO.IdAlmacen = D.IdAlmacen
      INNER JOIN dbo.Almacenes AD ON AD.IdAlmacen = T.IdAlmacenDestino
      INNER JOIN dbo.Almacenes ATN ON ATN.IdAlmacen = T.IdAlmacenTransito
      LEFT JOIN dbo.Monedas M ON M.IdMoneda = D.IdMoneda
      WHERE D.RowStatus = 1
        AND D.TipoOperacion = 'T'
        AND (@IdAlmacen IS NULL OR D.IdAlmacen = @IdAlmacen)
        AND (@IdAlmacenDestino IS NULL OR T.IdAlmacenDestino = @IdAlmacenDestino)
        AND (@IdTipoDocumento IS NULL OR D.IdTipoDocumento = @IdTipoDocumento)
        AND (@EstadoTransferencia IS NULL OR T.EstadoTransferencia = @EstadoTransferencia)
        AND (@FechaDesde IS NULL OR D.Fecha >= @FechaDesde)
        AND (@FechaHasta IS NULL OR D.Fecha <= @FechaHasta)
    )
    SELECT *, COUNT(1) OVER() AS TotalRows
    FROM Base
    ORDER BY Fecha DESC, IdDocumento DESC
    OFFSET (@NumeroPagina - 1) * @TamanoPagina ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      D.IdDocumento, D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento, D.TipoOperacion, D.Periodo, D.Secuencia,
      D.NumeroDocumento, D.Fecha, D.IdAlmacen, AO.Descripcion AS NombreAlmacen, D.IdMoneda, M.Nombre AS NombreMoneda,
      M.Simbolo AS SimboloMoneda, D.TasaCambio, D.Referencia, D.Observacion, D.TotalDocumento, D.Estado,
      T.IdAlmacenDestino, AD.Descripcion AS NombreAlmacenDestino, T.IdAlmacenTransito, ATN.Descripcion AS NombreAlmacenTransito,
      T.EstadoTransferencia, T.FechaSalida, T.FechaRecepcion
    FROM dbo.InvDocumentos D
    INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento AND T.RowStatus = 1
    INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
    INNER JOIN dbo.Almacenes AO ON AO.IdAlmacen = D.IdAlmacen
    INNER JOIN dbo.Almacenes AD ON AD.IdAlmacen = T.IdAlmacenDestino
    INNER JOIN dbo.Almacenes ATN ON ATN.IdAlmacen = T.IdAlmacenTransito
    LEFT JOIN dbo.Monedas M ON M.IdMoneda = D.IdMoneda
    WHERE D.IdDocumento = @IdDocumento AND D.RowStatus = 1;

    SELECT IdDetalle, NumeroLinea, IdProducto, Codigo, Descripcion, IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total
    FROM dbo.InvDocumentoDetalle
    WHERE IdDocumento = @IdDocumento AND RowStatus = 1
    ORDER BY NumeroLinea;
    RETURN;
  END

  IF @Accion IN ('I', 'U')
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @TransitoOrigen INT;
      SELECT @TransitoOrigen = IdAlmacenTransito
      FROM dbo.Almacenes
      WHERE IdAlmacen = @IdAlmacen
        AND RowStatus = 1;

      IF @TransitoOrigen IS NULL
        THROW 50045, 'El almacen origen no tiene almacen de transito configurado.', 1;

      IF @Accion = 'I'
      BEGIN
        DECLARE @TipoOp CHAR(1), @Prefijo VARCHAR(10), @NuevaSecuencia INT, @NumDoc VARCHAR(30), @TipoMoneda INT;
        DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);

        UPDATE dbo.InvTiposDocumento
        SET SecuenciaActual = SecuenciaActual + 1
        WHERE IdTipoDocumento = @IdTipoDocumento;

        SELECT
          @TipoOp = TipoOperacion,
          @Prefijo = ISNULL(Prefijo, ''),
          @NuevaSecuencia = SecuenciaActual,
          @TipoMoneda = IdMoneda
        FROM dbo.InvTiposDocumento
        WHERE IdTipoDocumento = @IdTipoDocumento
          AND RowStatus = 1;

        IF @TipoOp IS NULL
          THROW 50052, 'Tipo de documento no valido.', 1;

        IF @TipoOp <> 'T'
          THROW 50053, 'El tipo de documento no corresponde a transferencias.', 1;

        SET @NumDoc = CASE
          WHEN @Prefijo <> '' THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR(10)), 4)
          ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR(10)), 4)
        END;

        INSERT INTO dbo.InvDocumentos (
          IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento,
          Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion,
          TotalDocumento, Estado, UsuarioCreacion, IdSesionCreacion
        )
        VALUES (
          @IdTipoDocumento, 'T', @Periodo, @NuevaSecuencia, @NumDoc,
          @Fecha, @IdAlmacen, @TipoMoneda, 1.000000, @Referencia, @Observacion,
          0, 'A', @IdUsuario, @IdSesion
        );

        SET @IdDocumento = SCOPE_IDENTITY();

        INSERT INTO dbo.InvDocumentoDetalle (
          IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
          IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
        )
        SELECT
          @IdDocumento,
          j.linea,
          j.idProducto,
          j.codigo,
          j.descripcion,
          j.idUnidadMedida,
          j.unidad,
          j.cantidad,
          j.costo,
          ROUND(j.cantidad * j.costo, 4),
          @IdUsuario
        FROM OPENJSON(@DetalleJSON)
        WITH (
          linea          INT            '$.linea',
          idProducto     INT            '$.idProducto',
          codigo         NVARCHAR(60)   '$.codigo',
          descripcion    NVARCHAR(200)  '$.descripcion',
          idUnidadMedida INT            '$.idUnidadMedida',
          unidad         NVARCHAR(50)   '$.unidad',
          cantidad       DECIMAL(18,4)  '$.cantidad',
          costo          DECIMAL(18,4)  '$.costo'
        ) j
        WHERE j.idProducto IS NOT NULL
          AND j.cantidad > 0;

        UPDATE d
        SET d.TotalDocumento = x.TotalDoc
        FROM dbo.InvDocumentos d
        CROSS APPLY (
          SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
          FROM dbo.InvDocumentoDetalle det
          WHERE det.IdDocumento = @IdDocumento
            AND det.RowStatus = 1
        ) x
        WHERE d.IdDocumento = @IdDocumento;

        INSERT INTO dbo.InvTransferencias (IdDocumento, IdAlmacenDestino, IdAlmacenTransito, EstadoTransferencia, UsuarioCreacion)
        VALUES (@IdDocumento, @IdAlmacenDestino, @TransitoOrigen, 'B', @IdUsuario);

        COMMIT TRANSACTION;
        EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
        RETURN;
      END

      IF NOT EXISTS (
        SELECT 1
        FROM dbo.InvTransferencias
        WHERE IdDocumento = @IdDocumento
          AND EstadoTransferencia = 'B'
          AND RowStatus = 1
      )
        THROW 50046, 'Solo se pueden editar transferencias en borrador.', 1;

      DECLARE @DocTipoOp CHAR(1), @TipoMonedaEdit INT, @PeriodoEdit VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);
      SELECT
        @DocTipoOp = D.TipoOperacion,
        @TipoMonedaEdit = TD.IdMoneda
      FROM dbo.InvDocumentos D
      INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = @IdTipoDocumento
      WHERE D.IdDocumento = @IdDocumento
        AND D.RowStatus = 1
        AND D.Estado = 'A';

      IF @DocTipoOp IS NULL
        THROW 50054, 'Transferencia no encontrada o no editable.', 1;

      IF @DocTipoOp <> 'T'
        THROW 50055, 'El documento indicado no es una transferencia.', 1;

      UPDATE dbo.InvDocumentoDetalle
      SET RowStatus = 0
      WHERE IdDocumento = @IdDocumento
        AND RowStatus = 1;

      UPDATE dbo.InvDocumentos
      SET
        IdTipoDocumento = @IdTipoDocumento,
        Fecha = @Fecha,
        Periodo = @PeriodoEdit,
        IdAlmacen = @IdAlmacen,
        IdMoneda = @TipoMonedaEdit,
        TasaCambio = 1.000000,
        Referencia = @Referencia,
        Observacion = @Observacion,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario,
        IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      INSERT INTO dbo.InvDocumentoDetalle (
        IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
        IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
      )
      SELECT
        @IdDocumento,
        j.linea,
        j.idProducto,
        j.codigo,
        j.descripcion,
        j.idUnidadMedida,
        j.unidad,
        j.cantidad,
        j.costo,
        ROUND(j.cantidad * j.costo, 4),
        @IdUsuario
      FROM OPENJSON(@DetalleJSON)
      WITH (
        linea          INT            '$.linea',
        idProducto     INT            '$.idProducto',
        codigo         NVARCHAR(60)   '$.codigo',
        descripcion    NVARCHAR(200)  '$.descripcion',
        idUnidadMedida INT            '$.idUnidadMedida',
        unidad         NVARCHAR(50)   '$.unidad',
        cantidad       DECIMAL(18,4)  '$.cantidad',
        costo          DECIMAL(18,4)  '$.costo'
      ) j
      WHERE j.idProducto IS NOT NULL
        AND j.cantidad > 0;

      UPDATE d
      SET d.TotalDocumento = x.TotalDoc
      FROM dbo.InvDocumentos d
      CROSS APPLY (
        SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = d.IdDocumento
          AND det.RowStatus = 1
      ) x
      WHERE d.IdDocumento = @IdDocumento;

      UPDATE dbo.InvTransferencias
      SET
        IdAlmacenDestino = @IdAlmacenDestino,
        IdAlmacenTransito = @TransitoOrigen,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      COMMIT TRANSACTION;
      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  IF @Accion IN ('GS', 'CR', 'N')
  BEGIN
    DECLARE @EstadoActual CHAR(1), @OrigenDoc INT, @DestinoDoc INT, @TransitoDoc INT;

    SELECT
      @EstadoActual = T.EstadoTransferencia,
      @OrigenDoc = D.IdAlmacen,
      @DestinoDoc = T.IdAlmacenDestino,
      @TransitoDoc = T.IdAlmacenTransito
    FROM dbo.InvTransferencias T
    INNER JOIN dbo.InvDocumentos D ON D.IdDocumento = T.IdDocumento
    WHERE T.IdDocumento = @IdDocumento
      AND T.RowStatus = 1
      AND D.RowStatus = 1;

    IF @EstadoActual IS NULL
      THROW 50047, 'Transferencia no encontrada.', 1;

    IF OBJECT_ID('tempdb..#TransferDetalle') IS NOT NULL DROP TABLE #TransferDetalle;
    SELECT
      IdProducto,
      SUM(dbo.fnInvCantidadABase(IdProducto, IdUnidadMedida, Cantidad)) AS Cantidad,
      MAX(Costo) AS Costo
    INTO #TransferDetalle
    FROM dbo.InvDocumentoDetalle
    WHERE IdDocumento = @IdDocumento
      AND RowStatus = 1
    GROUP BY IdProducto;

    IF @Accion = 'GS'
    BEGIN
      IF @EstadoActual <> 'B'
        THROW 50048, 'Solo se puede generar salida desde borrador.', 1;

      IF EXISTS (
        SELECT 1
        FROM #TransferDetalle D
        OUTER APPLY (
          SELECT TOP 1 ISNULL(PA.Cantidad, 0) AS Existencia
          FROM dbo.ProductoAlmacenes PA
          WHERE PA.IdProducto = D.IdProducto
            AND PA.IdAlmacen = @OrigenDoc
            AND PA.RowStatus = 1
        ) S
        WHERE ISNULL(S.Existencia, 0) < D.Cantidad
      )
        THROW 50049, 'Stock insuficiente para generar la salida.', 1;

      MERGE dbo.ProductoAlmacenes AS T
      USING (SELECT IdProducto, @TransitoDoc AS IdAlmacen FROM #TransferDetalle) AS S
      ON T.IdProducto = S.IdProducto AND T.IdAlmacen = S.IdAlmacen
      WHEN NOT MATCHED THEN
        INSERT (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (S.IdProducto, S.IdAlmacen, 0, 0, 0, 1, GETDATE(), @IdUsuario);

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad - D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @OrigenDoc
        AND PA.RowStatus = 1;

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad + D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @TransitoDoc
        AND PA.RowStatus = 1;

      UPDATE dbo.InvTransferencias
      SET
        EstadoTransferencia = 'T',
        FechaSalida = GETDATE(),
        UsuarioSalida = @IdUsuario,
        IdSesionSalida = @IdSesion,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    IF @Accion = 'CR'
    BEGIN
      IF @EstadoActual <> 'T'
        THROW 50050, 'Solo se puede confirmar recepcion desde En Transito.', 1;

      MERGE dbo.ProductoAlmacenes AS T
      USING (SELECT IdProducto, @DestinoDoc AS IdAlmacen FROM #TransferDetalle) AS S
      ON T.IdProducto = S.IdProducto AND T.IdAlmacen = S.IdAlmacen
      WHEN NOT MATCHED THEN
        INSERT (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (S.IdProducto, S.IdAlmacen, 0, 0, 0, 1, GETDATE(), @IdUsuario);

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad - D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @TransitoDoc
        AND PA.RowStatus = 1;

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad + D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @DestinoDoc
        AND PA.RowStatus = 1;

      UPDATE dbo.InvTransferencias
      SET
        EstadoTransferencia = 'C',
        FechaRecepcion = GETDATE(),
        UsuarioRecepcion = @IdUsuario,
        IdSesionRecepcion = @IdSesion,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    IF @Accion = 'N'
    BEGIN
      IF @EstadoActual = 'C'
        THROW 50051, 'Transferencias completadas no pueden anularse.', 1;

      IF @EstadoActual = 'T'
      BEGIN
        UPDATE PA
        SET
          PA.Cantidad = PA.Cantidad + D.Cantidad,
          PA.FechaModificacion = GETDATE(),
          PA.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes PA
        INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
        WHERE PA.IdAlmacen = @OrigenDoc
          AND PA.RowStatus = 1;

        UPDATE PA
        SET
          PA.Cantidad = PA.Cantidad - D.Cantidad,
          PA.FechaModificacion = GETDATE(),
          PA.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes PA
        INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
        WHERE PA.IdAlmacen = @TransitoDoc
          AND PA.RowStatus = 1;
      END

      UPDATE dbo.InvTransferencias
      SET EstadoTransferencia = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      UPDATE dbo.InvDocumentos
      SET Estado = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario, IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    RETURN;
  END
END;

GO