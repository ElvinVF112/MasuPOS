SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '=== Script 79: documentos reales de transito para transferencias ==='
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

IF COL_LENGTH('dbo.InvTransferencias', 'IdDocumentoEntradaTransito') IS NULL
BEGIN
  ALTER TABLE dbo.InvTransferencias ADD IdDocumentoEntradaTransito INT NULL;
END
GO

IF COL_LENGTH('dbo.InvTransferencias', 'IdDocumentoSalidaTransito') IS NULL
BEGIN
  ALTER TABLE dbo.InvTransferencias ADD IdDocumentoSalidaTransito INT NULL;
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

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InvTransferencias_DocEntradaTransito')
BEGIN
  ALTER TABLE dbo.InvTransferencias
    ADD CONSTRAINT FK_InvTransferencias_DocEntradaTransito
    FOREIGN KEY (IdDocumentoEntradaTransito) REFERENCES dbo.InvDocumentos(IdDocumento);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InvTransferencias_DocSalidaTransito')
BEGIN
  ALTER TABLE dbo.InvTransferencias
    ADD CONSTRAINT FK_InvTransferencias_DocSalidaTransito
    FOREIGN KEY (IdDocumentoSalidaTransito) REFERENCES dbo.InvDocumentos(IdDocumento);
END
GO

CREATE OR ALTER PROCEDURE dbo.spInvCrearDocumentoAsociadoTransferencia
  @IdDocumentoTransferencia INT,
  @Modo CHAR(2),
  @IdUsuario INT = NULL,
  @IdSesion INT = NULL,
  @IdDocumentoNuevo INT OUTPUT,
  @NumeroDocumentoNuevo VARCHAR(30) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @TipoOperacion CHAR(1),
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

  IF @Modo NOT IN ('SO', 'ET', 'ST', 'ED')
    THROW 50080, 'Modo de documento asociado no valido.', 1;

  SELECT
    @NumeroTransferencia = D.NumeroDocumento,
    @TipoMoneda = D.IdMoneda,
    @FechaDocumento = CASE
      WHEN @Modo IN ('SO', 'ET') THEN CAST(COALESCE(T.FechaSalida, D.Fecha) AS DATE)
      ELSE CAST(COALESCE(T.FechaRecepcion, T.FechaSalida, D.Fecha) AS DATE)
    END,
    @IdAlmacenDocumento = CASE
      WHEN @Modo = 'SO' THEN D.IdAlmacen
      WHEN @Modo = 'ET' THEN T.IdAlmacenTransito
      WHEN @Modo = 'ST' THEN T.IdAlmacenTransito
      ELSE T.IdAlmacenDestino
    END,
    @TipoOperacion = CASE WHEN @Modo IN ('SO', 'ST') THEN 'S' ELSE 'E' END,
    @IdDocumentoExistente = CASE
      WHEN @Modo = 'SO' THEN T.IdDocumentoSalida
      WHEN @Modo = 'ET' THEN T.IdDocumentoEntradaTransito
      WHEN @Modo = 'ST' THEN T.IdDocumentoSalidaTransito
      ELSE T.IdDocumentoEntrada
    END
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
    AND TD.TipoOperacion = @TipoOperacion
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
  SET @Observacion = CASE @Modo
    WHEN 'SO' THEN CONCAT('Documento de salida origen asociado a transferencia ', @NumeroTransferencia)
    WHEN 'ET' THEN CONCAT('Documento de entrada a transito asociado a transferencia ', @NumeroTransferencia)
    WHEN 'ST' THEN CONCAT('Documento de salida de transito asociado a transferencia ', @NumeroTransferencia)
    ELSE CONCAT('Documento de entrada destino asociado a transferencia ', @NumeroTransferencia)
  END;

  INSERT INTO dbo.InvDocumentos (
    IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento,
    Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion,
    TotalDocumento, Estado, UsuarioCreacion, IdSesionCreacion
  )
  VALUES (
    @IdTipoDocumentoAux, @TipoOperacion, @Periodo, @NuevaSecuencia, @NumeroDocumentoNuevo,
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

  UPDATE dbo.InvTransferencias
  SET
    IdDocumentoSalida = CASE WHEN @Modo = 'SO' THEN @IdDocumentoNuevo ELSE IdDocumentoSalida END,
    IdDocumentoEntradaTransito = CASE WHEN @Modo = 'ET' THEN @IdDocumentoNuevo ELSE IdDocumentoEntradaTransito END,
    IdDocumentoSalidaTransito = CASE WHEN @Modo = 'ST' THEN @IdDocumentoNuevo ELSE IdDocumentoSalidaTransito END,
    IdDocumentoEntrada = CASE WHEN @Modo = 'ED' THEN @IdDocumentoNuevo ELSE IdDocumentoEntrada END,
    FechaModificacion = GETDATE(),
    UsuarioModificacion = ISNULL(@IdUsuario, 1)
  WHERE IdDocumento = @IdDocumentoTransferencia;
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
      @IdDocumentoEntradaLink INT,
      @IdDocumentoEntradaTransitoLink INT,
      @IdDocumentoSalidaTransitoLink INT;

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
      @IdDocumentoEntradaLink = T.IdDocumentoEntrada,
      @IdDocumentoEntradaTransitoLink = T.IdDocumentoEntradaTransito,
      @IdDocumentoSalidaTransitoLink = T.IdDocumentoSalidaTransito
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

      DECLARE
        @IdDocumentoSalidaGenerado INT,
        @NumeroDocumentoSalida VARCHAR(30),
        @IdDocumentoEntradaTransitoGenerado INT,
        @NumeroDocumentoEntradaTransito VARCHAR(30);

      EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
        @IdDocumentoTransferencia = @IdDocumento,
        @Modo = 'SO',
        @IdUsuario = @IdUsuario,
        @IdSesion = @IdSesion,
        @IdDocumentoNuevo = @IdDocumentoSalidaGenerado OUTPUT,
        @NumeroDocumentoNuevo = @NumeroDocumentoSalida OUTPUT;

      EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
        @IdDocumentoTransferencia = @IdDocumento,
        @Modo = 'ET',
        @IdUsuario = @IdUsuario,
        @IdSesion = @IdSesion,
        @IdDocumentoNuevo = @IdDocumentoEntradaTransitoGenerado OUTPUT,
        @NumeroDocumentoNuevo = @NumeroDocumentoEntradaTransito OUTPUT;

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
        @IdDocumentoEntradaTransitoGenerado,
        'ENT',
        @NumeroDocumentoEntradaTransito,
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

      DECLARE
        @IdDocumentoSalidaTransitoGenerado INT,
        @NumeroDocumentoSalidaTransito VARCHAR(30),
        @IdDocumentoEntradaGenerado INT,
        @NumeroDocumentoEntrada VARCHAR(30);

      EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
        @IdDocumentoTransferencia = @IdDocumento,
        @Modo = 'ST',
        @IdUsuario = @IdUsuario,
        @IdSesion = @IdSesion,
        @IdDocumentoNuevo = @IdDocumentoSalidaTransitoGenerado OUTPUT,
        @NumeroDocumentoNuevo = @NumeroDocumentoSalidaTransito OUTPUT;

      EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
        @IdDocumentoTransferencia = @IdDocumento,
        @Modo = 'ED',
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
        @IdDocumentoSalidaTransitoGenerado,
        'SAL',
        @NumeroDocumentoSalidaTransito,
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

      UPDATE dbo.InvDocumentos
      SET Estado = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario, IdSesionModif = @IdSesion
      WHERE IdDocumento IN (@IdDocumentoSalidaLink, @IdDocumentoEntradaLink, @IdDocumentoEntradaTransitoLink, @IdDocumentoSalidaTransitoLink);

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

DECLARE @IdDocumentoTransferenciaBF INT, @EstadoBF CHAR(1), @UsuarioSalidaBF INT, @SesionSalidaBF INT, @UsuarioEntradaBF INT, @SesionEntradaBF INT, @TmpId INT, @TmpNum VARCHAR(30);

DECLARE c_transfer_docs CURSOR LOCAL FAST_FORWARD FOR
SELECT
  T.IdDocumento,
  T.EstadoTransferencia,
  COALESCE(T.UsuarioSalida, T.UsuarioCreacion, D.UsuarioCreacion, 1) AS UsuarioSalida,
  COALESCE(T.IdSesionSalida, D.IdSesionCreacion) AS SesionSalida,
  COALESCE(T.UsuarioRecepcion, T.UsuarioSalida, T.UsuarioCreacion, D.UsuarioCreacion, 1) AS UsuarioEntrada,
  COALESCE(T.IdSesionRecepcion, T.IdSesionSalida, D.IdSesionCreacion) AS SesionEntrada
FROM dbo.InvTransferencias T
INNER JOIN dbo.InvDocumentos D ON D.IdDocumento = T.IdDocumento
WHERE T.RowStatus = 1
  AND D.RowStatus = 1
  AND D.TipoOperacion = 'T';

OPEN c_transfer_docs;
FETCH NEXT FROM c_transfer_docs INTO @IdDocumentoTransferenciaBF, @EstadoBF, @UsuarioSalidaBF, @SesionSalidaBF, @UsuarioEntradaBF, @SesionEntradaBF;
WHILE @@FETCH_STATUS = 0
BEGIN
  IF @EstadoBF IN ('T', 'C')
  BEGIN
    EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
      @IdDocumentoTransferencia = @IdDocumentoTransferenciaBF,
      @Modo = 'SO',
      @IdUsuario = @UsuarioSalidaBF,
      @IdSesion = @SesionSalidaBF,
      @IdDocumentoNuevo = @TmpId OUTPUT,
      @NumeroDocumentoNuevo = @TmpNum OUTPUT;

    EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
      @IdDocumentoTransferencia = @IdDocumentoTransferenciaBF,
      @Modo = 'ET',
      @IdUsuario = @UsuarioSalidaBF,
      @IdSesion = @SesionSalidaBF,
      @IdDocumentoNuevo = @TmpId OUTPUT,
      @NumeroDocumentoNuevo = @TmpNum OUTPUT;
  END

  IF @EstadoBF = 'C'
  BEGIN
    EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
      @IdDocumentoTransferencia = @IdDocumentoTransferenciaBF,
      @Modo = 'ST',
      @IdUsuario = @UsuarioEntradaBF,
      @IdSesion = @SesionEntradaBF,
      @IdDocumentoNuevo = @TmpId OUTPUT,
      @NumeroDocumentoNuevo = @TmpNum OUTPUT;

    EXEC dbo.spInvCrearDocumentoAsociadoTransferencia
      @IdDocumentoTransferencia = @IdDocumentoTransferenciaBF,
      @Modo = 'ED',
      @IdUsuario = @UsuarioEntradaBF,
      @IdSesion = @SesionEntradaBF,
      @IdDocumentoNuevo = @TmpId OUTPUT,
      @NumeroDocumentoNuevo = @TmpNum OUTPUT;
  END

  FETCH NEXT FROM c_transfer_docs INTO @IdDocumentoTransferenciaBF, @EstadoBF, @UsuarioSalidaBF, @SesionSalidaBF, @UsuarioEntradaBF, @SesionEntradaBF;
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
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = M.IdDocumentoOrigen OR T.IdDocumentoSalida = M.IdDocumentoOrigen
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
  M.IdDocumentoOrigen = T.IdDocumentoEntradaTransito,
  M.TipoDocOrigen = 'ENT',
  M.NumeroDocumento = DETR.NumeroDocumento
FROM dbo.InvMovimientos M
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = M.IdDocumentoOrigen OR T.IdDocumentoEntradaTransito = M.IdDocumentoOrigen
INNER JOIN dbo.InvDocumentos DTR ON DTR.IdDocumento = T.IdDocumento
INNER JOIN dbo.InvDocumentos DETR ON DETR.IdDocumento = T.IdDocumentoEntradaTransito
WHERE DTR.TipoOperacion = 'T'
  AND M.RowStatus = 1
  AND M.TipoMovimiento = 'ENT'
  AND M.Signo = 1
  AND M.IdAlmacen = T.IdAlmacenTransito
  AND T.IdDocumentoEntradaTransito IS NOT NULL;
GO

UPDATE M
SET
  M.IdDocumentoOrigen = T.IdDocumentoSalidaTransito,
  M.TipoDocOrigen = 'SAL',
  M.NumeroDocumento = DSTR.NumeroDocumento
FROM dbo.InvMovimientos M
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = M.IdDocumentoOrigen OR T.IdDocumentoSalidaTransito = M.IdDocumentoOrigen
INNER JOIN dbo.InvDocumentos DTR ON DTR.IdDocumento = T.IdDocumento
INNER JOIN dbo.InvDocumentos DSTR ON DSTR.IdDocumento = T.IdDocumentoSalidaTransito
WHERE DTR.TipoOperacion = 'T'
  AND M.RowStatus = 1
  AND M.TipoMovimiento = 'SAL'
  AND M.Signo = -1
  AND M.IdAlmacen = T.IdAlmacenTransito
  AND T.IdDocumentoSalidaTransito IS NOT NULL;
GO

UPDATE M
SET
  M.IdDocumentoOrigen = T.IdDocumentoEntrada,
  M.TipoDocOrigen = 'ENT',
  M.NumeroDocumento = DE.NumeroDocumento
FROM dbo.InvMovimientos M
INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = M.IdDocumentoOrigen OR T.IdDocumentoEntrada = M.IdDocumentoOrigen
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
  DS.NumeroDocumento AS DocumentoSalidaOrigen,
  DETR.NumeroDocumento AS DocumentoEntradaTransito,
  DSTR.NumeroDocumento AS DocumentoSalidaTransito,
  DE.NumeroDocumento AS DocumentoEntradaDestino,
  T.EstadoTransferencia
FROM dbo.InvTransferencias T
INNER JOIN dbo.InvDocumentos DTR ON DTR.IdDocumento = T.IdDocumento
LEFT JOIN dbo.InvDocumentos DS ON DS.IdDocumento = T.IdDocumentoSalida
LEFT JOIN dbo.InvDocumentos DETR ON DETR.IdDocumento = T.IdDocumentoEntradaTransito
LEFT JOIN dbo.InvDocumentos DSTR ON DSTR.IdDocumento = T.IdDocumentoSalidaTransito
LEFT JOIN dbo.InvDocumentos DE ON DE.IdDocumento = T.IdDocumentoEntrada
WHERE DTR.TipoOperacion = 'T'
ORDER BY DTR.IdDocumento DESC;
GO

PRINT '=== Script 79 ejecutado correctamente ==='
GO
