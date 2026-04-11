SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '=== Script 78: documentos reales asociados a transferencias ==='
GO

IF COL_LENGTH('dbo.InvTransferencias', 'IdDocumentoSalida') IS NULL
BEGIN
  ALTER TABLE dbo.InvTransferencias ADD IdDocumentoSalida INT NULL;
END
GO

IF COL_LENGTH('dbo.InvTransferencias', 'IdDocumentoEntrada') IS NULL
BEGIN
  ALTER TABLE dbo.InvTransferencias ADD IdDocumentoEntrada INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InvTransferencias_DocSalida')
BEGIN
  ALTER TABLE dbo.InvTransferencias
    ADD CONSTRAINT FK_InvTransferencias_DocSalida
    FOREIGN KEY (IdDocumentoSalida) REFERENCES dbo.InvDocumentos(IdDocumento);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InvTransferencias_DocEntrada')
BEGIN
  ALTER TABLE dbo.InvTransferencias
    ADD CONSTRAINT FK_InvTransferencias_DocEntrada
    FOREIGN KEY (IdDocumentoEntrada) REFERENCES dbo.InvDocumentos(IdDocumento);
END
GO

CREATE OR ALTER PROCEDURE dbo.spInvCrearDocumentoAsociadoTransferencia
  @IdDocumentoTransferencia INT,
  @Modo CHAR(1),
  @IdUsuario INT = NULL,
  @IdSesion INT = NULL,
  @IdDocumentoNuevo INT OUTPUT,
  @NumeroDocumentoNuevo VARCHAR(30) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @IdTipoDocumentoAux INT,
    @Prefijo VARCHAR(10),
    @NuevaSecuencia INT,
    @TipoMoneda INT,
    @FechaDocumento DATE,
    @IdAlmacenDocumento INT,
    @Periodo VARCHAR(6),
    @Referencia NVARCHAR(250),
    @Observacion NVARCHAR(500),
    @NumeroTransferencia VARCHAR(30),
    @IdDocumentoExistente INT;

  IF @Modo NOT IN ('S', 'E')
    THROW 50080, 'Modo de documento asociado no valido.', 1;

  SELECT
    @NumeroTransferencia = D.NumeroDocumento,
    @TipoMoneda = D.IdMoneda,
    @FechaDocumento = CASE WHEN @Modo = 'S' THEN CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE) ELSE CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE) END,
    @IdAlmacenDocumento = CASE WHEN @Modo = 'S' THEN D.IdAlmacen ELSE T.IdAlmacenDestino END,
    @IdDocumentoExistente = CASE WHEN @Modo = 'S' THEN T.IdDocumentoSalida ELSE T.IdDocumentoEntrada END
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  WHERE D.IdDocumento = @IdDocumentoTransferencia
    AND D.RowStatus = 1
    AND T.RowStatus = 1;

  IF @NumeroTransferencia IS NULL
    THROW 50081, 'Transferencia no encontrada.', 1;

  IF @IdDocumentoExistente IS NOT NULL
  BEGIN
    SELECT @IdDocumentoNuevo = @IdDocumentoExistente, @NumeroDocumentoNuevo = NumeroDocumento
    FROM dbo.InvDocumentos
    WHERE IdDocumento = @IdDocumentoExistente;
    RETURN;
  END

  SELECT TOP (1) @IdTipoDocumentoAux = TD.IdTipoDocumento
  FROM dbo.InvTiposDocumento TD
  WHERE TD.RowStatus = 1
    AND TD.Activo = 1
    AND TD.TipoOperacion = @Modo
  ORDER BY TD.IdTipoDocumento;

  IF @IdTipoDocumentoAux IS NULL
    THROW 50082, 'No existe tipo de documento activo para el documento asociado.', 1;

  UPDATE dbo.InvTiposDocumento
  SET SecuenciaActual = SecuenciaActual + 1
  WHERE IdTipoDocumento = @IdTipoDocumentoAux;

  SELECT
    @Prefijo = ISNULL(Prefijo, ''),
    @NuevaSecuencia = SecuenciaActual,
    @TipoMoneda = COALESCE(@TipoMoneda, IdMoneda)
  FROM dbo.InvTiposDocumento
  WHERE IdTipoDocumento = @IdTipoDocumentoAux;

  SET @NumeroDocumentoNuevo = CASE
    WHEN @Prefijo <> '' THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR(10)), 4)
    ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR(10)), 4)
  END;

  SET @Periodo = CONVERT(VARCHAR(6), @FechaDocumento, 112);
  SET @Referencia = @NumeroTransferencia;
  SET @Observacion = CASE WHEN @Modo = 'S' THEN CONCAT('Documento de salida asociado a transferencia ', @NumeroTransferencia) ELSE CONCAT('Documento de entrada asociado a transferencia ', @NumeroTransferencia) END;

  INSERT INTO dbo.InvDocumentos (
    IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento,
    Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion,
    TotalDocumento, Estado, UsuarioCreacion, IdSesionCreacion
  )
  VALUES (
    @IdTipoDocumentoAux, @Modo, @Periodo, @NuevaSecuencia, @NumeroDocumentoNuevo,
    @FechaDocumento, @IdAlmacenDocumento, @TipoMoneda, 1.000000, @Referencia, @Observacion,
    0, 'A', ISNULL(@IdUsuario, 1), @IdSesion
  );

  SET @IdDocumentoNuevo = SCOPE_IDENTITY();

  INSERT INTO dbo.InvDocumentoDetalle (
    IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
    IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
  )
  SELECT
    @IdDocumentoNuevo, NumeroLinea, IdProducto, Codigo, Descripcion,
    IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, ISNULL(@IdUsuario, 1)
  FROM dbo.InvDocumentoDetalle
  WHERE IdDocumento = @IdDocumentoTransferencia
    AND RowStatus = 1;

  UPDATE D
  SET D.TotalDocumento = X.TotalDoc
  FROM dbo.InvDocumentos D
  CROSS APPLY (
    SELECT ISNULL(SUM(DET.Total), 0) AS TotalDoc
    FROM dbo.InvDocumentoDetalle DET
    WHERE DET.IdDocumento = @IdDocumentoNuevo
      AND DET.RowStatus = 1
  ) X
  WHERE D.IdDocumento = @IdDocumentoNuevo;

  IF @Modo = 'S'
  BEGIN
    UPDATE dbo.InvTransferencias
    SET IdDocumentoSalida = @IdDocumentoNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = ISNULL(@IdUsuario, 1)
    WHERE IdDocumento = @IdDocumentoTransferencia;
  END
  ELSE
  BEGIN
    UPDATE dbo.InvTransferencias
    SET IdDocumentoEntrada = @IdDocumentoNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = ISNULL(@IdUsuario, 1)
    WHERE IdDocumento = @IdDocumentoTransferencia;
  END
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
    DECLARE
      @EstadoActual CHAR(1),
      @OrigenDoc INT,
      @DestinoDoc INT,
      @TransitoDoc INT,
      @NumeroDocumentoDoc VARCHAR(30),
      @FechaDoc DATE,
      @PeriodoDoc VARCHAR(6),
      @ObsDoc NVARCHAR(500),
      @IdDocumentoSalidaLink INT,
      @IdDocumentoEntradaLink INT;

    SELECT
      @EstadoActual = T.EstadoTransferencia,
      @OrigenDoc = D.IdAlmacen,
      @DestinoDoc = T.IdAlmacenDestino,
      @TransitoDoc = T.IdAlmacenTransito,
      @NumeroDocumentoDoc = D.NumeroDocumento,
      @FechaDoc = D.Fecha,
      @PeriodoDoc = D.Periodo,
      @ObsDoc = D.Observacion,
      @IdDocumentoSalidaLink = T.IdDocumentoSalida,
      @IdDocumentoEntradaLink = T.IdDocumentoEntrada
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

      DECLARE @IdDocumentoSalidaGenerado INT, @NumeroDocumentoSalida VARCHAR(30);
      EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
        @IdDocumentoTransferencia = @IdDocumento,
        @Modo = 'S',
        @IdUsuario = @IdUsuario,
        @IdSesion = @IdSesion,
        @IdDocumentoNuevo = @IdDocumentoSalidaGenerado OUTPUT,
        @NumeroDocumentoNuevo = @NumeroDocumentoSalida OUTPUT;

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

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
        NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
      )
      SELECT
        D.IdProducto,
        @OrigenDoc,
        'SAL',
        -1,
        @IdDocumentoSalidaGenerado,
        'SAL',
        @NumeroDocumentoSalida,
        NULL,
        D.Cantidad,
        D.Costo,
        ROUND(D.Cantidad * D.Costo, 4),
        PA.Cantidad + D.Cantidad,
        PA.Cantidad,
        P.CostoPromedio,
        P.CostoPromedio,
        COALESCE(CONVERT(date, GETDATE()), @FechaDoc),
        @PeriodoDoc,
        CONCAT('Salida por transferencia hacia transito. ', ISNULL(@ObsDoc, '')),
        1,
        GETDATE(),
        ISNULL(@IdUsuario, 1)
      FROM #TransferDetalle D
      INNER JOIN dbo.ProductoAlmacenes PA ON PA.IdProducto = D.IdProducto AND PA.IdAlmacen = @OrigenDoc AND PA.RowStatus = 1
      INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto;

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
        NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
      )
      SELECT
        D.IdProducto,
        @TransitoDoc,
        'ENT',
        1,
        @IdDocumento,
        'TRF',
        @NumeroDocumentoDoc,
        NULL,
        D.Cantidad,
        D.Costo,
        ROUND(D.Cantidad * D.Costo, 4),
        PA.Cantidad - D.Cantidad,
        PA.Cantidad,
        P.CostoPromedio,
        P.CostoPromedio,
        COALESCE(CONVERT(date, GETDATE()), @FechaDoc),
        @PeriodoDoc,
        CONCAT('Entrada a almacen de transito por transferencia. ', ISNULL(@ObsDoc, '')),
        1,
        GETDATE(),
        ISNULL(@IdUsuario, 1)
      FROM #TransferDetalle D
      INNER JOIN dbo.ProductoAlmacenes PA ON PA.IdProducto = D.IdProducto AND PA.IdAlmacen = @TransitoDoc AND PA.RowStatus = 1
      INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto;

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

      DECLARE @IdDocumentoEntradaGenerado INT, @NumeroDocumentoEntrada VARCHAR(30);
      EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
        @IdDocumentoTransferencia = @IdDocumento,
        @Modo = 'E',
        @IdUsuario = @IdUsuario,
        @IdSesion = @IdSesion,
        @IdDocumentoNuevo = @IdDocumentoEntradaGenerado OUTPUT,
        @NumeroDocumentoNuevo = @NumeroDocumentoEntrada OUTPUT;

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

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
        NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
      )
      SELECT
        D.IdProducto,
        @TransitoDoc,
        'SAL',
        -1,
        @IdDocumento,
        'TRF',
        @NumeroDocumentoDoc,
        NULL,
        D.Cantidad,
        D.Costo,
        ROUND(D.Cantidad * D.Costo, 4),
        PA.Cantidad + D.Cantidad,
        PA.Cantidad,
        P.CostoPromedio,
        P.CostoPromedio,
        CONVERT(date, GETDATE()),
        @PeriodoDoc,
        CONCAT('Salida de almacen de transito por recepcion de transferencia. ', ISNULL(@ObsDoc, '')),
        1,
        GETDATE(),
        ISNULL(@IdUsuario, 1)
      FROM #TransferDetalle D
      INNER JOIN dbo.ProductoAlmacenes PA ON PA.IdProducto = D.IdProducto AND PA.IdAlmacen = @TransitoDoc AND PA.RowStatus = 1
      INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto;

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
        NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
      )
      SELECT
        D.IdProducto,
        @DestinoDoc,
        'ENT',
        1,
        @IdDocumentoEntradaGenerado,
        'ENT',
        @NumeroDocumentoEntrada,
        NULL,
        D.Cantidad,
        D.Costo,
        ROUND(D.Cantidad * D.Costo, 4),
        PA.Cantidad - D.Cantidad,
        PA.Cantidad,
        P.CostoPromedio,
        P.CostoPromedio,
        CONVERT(date, GETDATE()),
        @PeriodoDoc,
        CONCAT('Entrada al almacen destino por recepcion de transferencia. ', ISNULL(@ObsDoc, '')),
        1,
        GETDATE(),
        ISNULL(@IdUsuario, 1)
      FROM #TransferDetalle D
      INNER JOIN dbo.ProductoAlmacenes PA ON PA.IdProducto = D.IdProducto AND PA.IdAlmacen = @DestinoDoc AND PA.RowStatus = 1
      INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto;

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

      IF @IdDocumentoSalidaLink IS NOT NULL
      BEGIN
        UPDATE dbo.InvDocumentos
        SET Estado = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario, IdSesionModif = @IdSesion
        WHERE IdDocumento = @IdDocumentoSalidaLink;
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

;WITH TransferBase AS (
  SELECT
    D.IdDocumento,
    D.NumeroDocumento,
    D.Fecha,
    D.Periodo,
    D.Observacion,
    D.IdAlmacen AS IdAlmacenOrigen,
    T.IdAlmacenDestino,
    T.IdAlmacenTransito,
    T.EstadoTransferencia,
    CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE) AS FechaSalidaMov,
    CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE) AS FechaRecepcionMov
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  WHERE D.RowStatus = 1
    AND T.RowStatus = 1
    AND D.TipoOperacion = 'T'
    AND T.EstadoTransferencia IN ('T', 'C')
),
TransferDetalle AS (
  SELECT
    TB.IdDocumento,
    TB.NumeroDocumento,
    TB.Fecha,
    TB.Periodo,
    TB.Observacion,
    TB.IdAlmacenOrigen,
    TB.IdAlmacenDestino,
    TB.IdAlmacenTransito,
    TB.EstadoTransferencia,
    TB.FechaSalidaMov,
    TB.FechaRecepcionMov,
    DET.IdProducto,
    SUM(dbo.fnInvCantidadABase(DET.IdProducto, DET.IdUnidadMedida, DET.Cantidad)) AS Cantidad,
    MAX(DET.Costo) AS Costo
  FROM TransferBase TB
  INNER JOIN dbo.InvDocumentoDetalle DET ON DET.IdDocumento = TB.IdDocumento AND DET.RowStatus = 1
  GROUP BY
    TB.IdDocumento, TB.NumeroDocumento, TB.Fecha, TB.Periodo, TB.Observacion,
    TB.IdAlmacenOrigen, TB.IdAlmacenDestino, TB.IdAlmacenTransito, TB.EstadoTransferencia,
    TB.FechaSalidaMov, TB.FechaRecepcionMov, DET.IdProducto
)
INSERT INTO dbo.InvMovimientos (
  IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
  NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
  CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
)
SELECT X.*
FROM (
  SELECT
    TD.IdProducto,
    TD.IdAlmacenOrigen,
    'SAL',
    -1,
    TD.IdDocumento,
    'TRF',
    TD.NumeroDocumento,
    NULL,
    TD.Cantidad,
    TD.Costo,
    ROUND(TD.Cantidad * TD.Costo, 4),
    ISNULL(PAO.Cantidad, 0) + TD.Cantidad,
    ISNULL(PAO.Cantidad, 0),
    P.CostoPromedio,
    P.CostoPromedio,
    TD.FechaSalidaMov,
    TD.Periodo,
    CONCAT('Salida por transferencia hacia transito. ', ISNULL(TD.Observacion, '')),
    1,
    GETDATE(),
    1
  FROM TransferDetalle TD
  INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
  LEFT JOIN dbo.ProductoAlmacenes PAO ON PAO.IdProducto = TD.IdProducto AND PAO.IdAlmacen = TD.IdAlmacenOrigen AND PAO.RowStatus = 1
  WHERE TD.EstadoTransferencia IN ('T', 'C')

  UNION ALL

  SELECT
    TD.IdProducto,
    TD.IdAlmacenTransito,
    'ENT',
    1,
    TD.IdDocumento,
    'TRF',
    TD.NumeroDocumento,
    NULL,
    TD.Cantidad,
    TD.Costo,
    ROUND(TD.Cantidad * TD.Costo, 4),
    CASE WHEN TD.EstadoTransferencia = 'C' THEN 0 ELSE ISNULL(PAT.Cantidad, 0) - TD.Cantidad END,
    CASE WHEN TD.EstadoTransferencia = 'C' THEN TD.Cantidad ELSE ISNULL(PAT.Cantidad, 0) END,
    P.CostoPromedio,
    P.CostoPromedio,
    TD.FechaSalidaMov,
    TD.Periodo,
    CONCAT('Entrada a almacen de transito por transferencia. ', ISNULL(TD.Observacion, '')),
    1,
    GETDATE(),
    1
  FROM TransferDetalle TD
  INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
  LEFT JOIN dbo.ProductoAlmacenes PAT ON PAT.IdProducto = TD.IdProducto AND PAT.IdAlmacen = TD.IdAlmacenTransito AND PAT.RowStatus = 1
  WHERE TD.EstadoTransferencia IN ('T', 'C')

  UNION ALL

  SELECT
    TD.IdProducto,
    TD.IdAlmacenTransito,
    'SAL',
    -1,
    TD.IdDocumento,
    'TRF',
    TD.NumeroDocumento,
    NULL,
    TD.Cantidad,
    TD.Costo,
    ROUND(TD.Cantidad * TD.Costo, 4),
    TD.Cantidad,
    0,
    P.CostoPromedio,
    P.CostoPromedio,
    TD.FechaRecepcionMov,
    TD.Periodo,
    CONCAT('Salida de almacen de transito por recepcion de transferencia. ', ISNULL(TD.Observacion, '')),
    1,
    GETDATE(),
    1
  FROM TransferDetalle TD
  INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
  WHERE TD.EstadoTransferencia = 'C'

  UNION ALL

  SELECT
    TD.IdProducto,
    TD.IdAlmacenDestino,
    'ENT',
    1,
    TD.IdDocumento,
    'TRF',
    TD.NumeroDocumento,
    NULL,
    TD.Cantidad,
    TD.Costo,
    ROUND(TD.Cantidad * TD.Costo, 4),
    ISNULL(PAD.Cantidad, 0) - TD.Cantidad,
    ISNULL(PAD.Cantidad, 0),
    P.CostoPromedio,
    P.CostoPromedio,
    TD.FechaRecepcionMov,
    TD.Periodo,
    CONCAT('Entrada al almacen destino por recepcion de transferencia. ', ISNULL(TD.Observacion, '')),
    1,
    GETDATE(),
    1
  FROM TransferDetalle TD
  INNER JOIN dbo.Productos P ON P.IdProducto = TD.IdProducto
  LEFT JOIN dbo.ProductoAlmacenes PAD ON PAD.IdProducto = TD.IdProducto AND PAD.IdAlmacen = TD.IdAlmacenDestino AND PAD.RowStatus = 1
  WHERE TD.EstadoTransferencia = 'C'
) AS X (
  IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento,
  NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
  CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
)
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.InvMovimientos M
  WHERE M.IdDocumentoOrigen = X.IdDocumentoOrigen
    AND M.IdProducto = X.IdProducto
    AND M.IdAlmacen = X.IdAlmacen
    AND M.Signo = X.Signo
    AND M.TipoMovimiento = X.TipoMovimiento
    AND M.RowStatus = 1
);
GO


DECLARE @IdDocumentoTransferenciaBF INT, @EstadoBF CHAR(1), @UsuarioBF INT, @SesionBF INT, @TmpId INT, @TmpNum VARCHAR(30);

DECLARE c_transfer_docs CURSOR LOCAL FAST_FORWARD FOR
SELECT
  T.IdDocumento,
  T.EstadoTransferencia,
  COALESCE(T.UsuarioSalida, T.UsuarioRecepcion, T.UsuarioCreacion, D.UsuarioCreacion) AS UsuarioAccion,
  COALESCE(T.IdSesionSalida, T.IdSesionRecepcion, D.IdSesionCreacion) AS IdSesionAccion
FROM dbo.InvTransferencias T
INNER JOIN dbo.InvDocumentos D ON D.IdDocumento = T.IdDocumento
WHERE T.RowStatus = 1
  AND D.RowStatus = 1
  AND D.TipoOperacion = 'T';

OPEN c_transfer_docs;
FETCH NEXT FROM c_transfer_docs INTO @IdDocumentoTransferenciaBF, @EstadoBF, @UsuarioBF, @SesionBF;
WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
    @IdDocumentoTransferencia = @IdDocumentoTransferenciaBF,
    @Modo = 'S',
    @IdUsuario = @UsuarioBF,
    @IdSesion = @SesionBF,
    @IdDocumentoNuevo = @TmpId OUTPUT,
    @NumeroDocumentoNuevo = @TmpNum OUTPUT;

  IF @EstadoBF = 'C'
  BEGIN
    EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
      @IdDocumentoTransferencia = @IdDocumentoTransferenciaBF,
      @Modo = 'E',
      @IdUsuario = @UsuarioBF,
      @IdSesion = @SesionBF,
      @IdDocumentoNuevo = @TmpId OUTPUT,
      @NumeroDocumentoNuevo = @TmpNum OUTPUT;
  END

  FETCH NEXT FROM c_transfer_docs INTO @IdDocumentoTransferenciaBF, @EstadoBF, @UsuarioBF, @SesionBF;
END
CLOSE c_transfer_docs;
DEALLOCATE c_transfer_docs;
GO

UPDATE M
SET
  M.IdDocumentoOrigen = T.IdDocumentoSalida,
  M.TipoDocOrigen = 'SAL',
  M.NumeroDocumento = DS.NumeroDocumento
FROM dbo.InvMovimientos M
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = M.IdDocumentoOrigen
INNER JOIN dbo.InvDocumentos DTR ON DTR.IdDocumento = T.IdDocumento
INNER JOIN dbo.InvDocumentos DS ON DS.IdDocumento = T.IdDocumentoSalida
WHERE DTR.TipoOperacion = 'T'
  AND M.RowStatus = 1
  AND M.TipoMovimiento = 'SAL'
  AND M.Signo = -1
  AND M.IdAlmacen = DTR.IdAlmacen
  AND T.IdDocumentoSalida IS NOT NULL;
GO

UPDATE M
SET
  M.IdDocumentoOrigen = T.IdDocumentoEntrada,
  M.TipoDocOrigen = 'ENT',
  M.NumeroDocumento = DE.NumeroDocumento
FROM dbo.InvMovimientos M
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = M.IdDocumentoOrigen
INNER JOIN dbo.InvDocumentos DTR ON DTR.IdDocumento = T.IdDocumento
INNER JOIN dbo.InvDocumentos DE ON DE.IdDocumento = T.IdDocumentoEntrada
WHERE DTR.TipoOperacion = 'T'
  AND M.RowStatus = 1
  AND M.TipoMovimiento = 'ENT'
  AND M.Signo = 1
  AND M.IdAlmacen = T.IdAlmacenDestino
  AND T.IdDocumentoEntrada IS NOT NULL;
GO

SELECT
  DTR.NumeroDocumento AS Transferencia,
  DS.NumeroDocumento AS DocumentoSalida,
  DE.NumeroDocumento AS DocumentoEntrada,
  T.EstadoTransferencia
FROM dbo.InvTransferencias T
INNER JOIN dbo.InvDocumentos DTR ON DTR.IdDocumento = T.IdDocumento
LEFT JOIN dbo.InvDocumentos DS ON DS.IdDocumento = T.IdDocumentoSalida
LEFT JOIN dbo.InvDocumentos DE ON DE.IdDocumento = T.IdDocumentoEntrada
WHERE DTR.TipoOperacion = 'T'
ORDER BY DTR.IdDocumento DESC;
GO

PRINT '=== Script 78 ejecutado correctamente ==='
GO
