SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '=== Script 80: tipos de transferencia con doc entrada/salida configurables ==='
GO

IF COL_LENGTH('dbo.InvTiposDocumento', 'IdTipoDocumentoEntrada') IS NULL
BEGIN
  ALTER TABLE dbo.InvTiposDocumento ADD IdTipoDocumentoEntrada INT NULL;
END
GO

IF COL_LENGTH('dbo.InvTiposDocumento', 'IdTipoDocumentoSalida') IS NULL
BEGIN
  ALTER TABLE dbo.InvTiposDocumento ADD IdTipoDocumentoSalida INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InvTiposDocumento_TipoEntrada')
BEGIN
  ALTER TABLE dbo.InvTiposDocumento
    ADD CONSTRAINT FK_InvTiposDocumento_TipoEntrada
    FOREIGN KEY (IdTipoDocumentoEntrada) REFERENCES dbo.InvTiposDocumento(IdTipoDocumento);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InvTiposDocumento_TipoSalida')
BEGIN
  ALTER TABLE dbo.InvTiposDocumento
    ADD CONSTRAINT FK_InvTiposDocumento_TipoSalida
    FOREIGN KEY (IdTipoDocumentoSalida) REFERENCES dbo.InvTiposDocumento(IdTipoDocumento);
END
GO

CREATE OR ALTER PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion                CHAR(2)        = 'L',
  @IdTipoDocumento       INT            = NULL,
  @TipoOperacion         CHAR(1)        = NULL,
  @Codigo                VARCHAR(10)    = NULL,
  @Descripcion           NVARCHAR(250)  = NULL,
  @Prefijo               VARCHAR(10)    = NULL,
  @SecuenciaInicial      INT            = 1,
  @ActualizaCosto        BIT            = 0,
  @IdMoneda              INT            = NULL,
  @IdTipoDocumentoEntrada INT           = NULL,
  @IdTipoDocumentoSalida INT            = NULL,
  @Activo                BIT            = 1,
  @UsuarioCreacion       INT            = 1,
  @UsuarioModificacion   INT            = NULL,
  @IdSesion              INT            = NULL,
  @TokenSesion           NVARCHAR(128)  = NULL,
  @UsuariosAsignados     NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion IN ('I', 'A') AND @TipoOperacion = 'T'
  BEGIN
    IF @IdTipoDocumentoEntrada IS NULL
      THROW 50083, 'El tipo de documento de entrada es obligatorio para transferencias.', 1;

    IF @IdTipoDocumentoSalida IS NULL
      THROW 50084, 'El tipo de documento de salida es obligatorio para transferencias.', 1;

    IF NOT EXISTS (
      SELECT 1
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumentoEntrada
        AND TipoOperacion = 'E'
        AND Activo = 1
        AND RowStatus = 1
    )
      THROW 50085, 'El tipo de documento de entrada configurado no es valido.', 1;

    IF NOT EXISTS (
      SELECT 1
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumentoSalida
        AND TipoOperacion = 'S'
        AND Activo = 1
        AND RowStatus = 1
    )
      THROW 50086, 'El tipo de documento de salida configurado no es valido.', 1;
  END

  IF @Accion = 'L'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.IdTipoDocumentoEntrada,
      te.Descripcion  AS DescripcionTipoDocumentoEntrada,
      t.IdTipoDocumentoSalida,
      ts.Descripcion  AS DescripcionTipoDocumentoSalida,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.InvTiposDocumento te ON te.IdTipoDocumento = t.IdTipoDocumentoEntrada
    LEFT JOIN dbo.InvTiposDocumento ts ON ts.IdTipoDocumento = t.IdTipoDocumentoSalida
    WHERE (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
      AND t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.IdTipoDocumentoEntrada,
      te.Descripcion  AS DescripcionTipoDocumentoEntrada,
      t.IdTipoDocumentoSalida,
      ts.Descripcion  AS DescripcionTipoDocumentoSalida,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.InvTiposDocumento te ON te.IdTipoDocumento = t.IdTipoDocumentoEntrada
    LEFT JOIN dbo.InvTiposDocumento ts ON ts.IdTipoDocumento = t.IdTipoDocumentoSalida
    WHERE t.IdTipoDocumento = @IdTipoDocumento
      AND t.RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND RowStatus = 1)
      THROW 50001, 'Ya existe un tipo de documento con ese codigo.', 1;

    INSERT INTO dbo.InvTiposDocumento (
      TipoOperacion, Codigo, Descripcion, Prefijo,
      SecuenciaInicial, SecuenciaActual, ActualizaCosto, IdMoneda,
      IdTipoDocumentoEntrada, IdTipoDocumentoSalida, Activo,
      UsuarioCreacion, IdSesionCreacion
    )
    VALUES (
      @TipoOperacion, @Codigo, @Descripcion, @Prefijo,
      @SecuenciaInicial, 0,
      CASE WHEN @TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      @IdMoneda,
      CASE WHEN @TipoOperacion = 'T' THEN @IdTipoDocumentoEntrada ELSE NULL END,
      CASE WHEN @TipoOperacion = 'T' THEN @IdTipoDocumentoSalida ELSE NULL END,
      @Activo,
      @UsuarioCreacion, @IdSesion
    );

    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND IdTipoDocumento <> @IdTipoDocumento AND RowStatus = 1)
      THROW 50002, 'Ya existe otro tipo de documento con ese codigo.', 1;

    UPDATE dbo.InvTiposDocumento
    SET
      Codigo                = ISNULL(@Codigo, Codigo),
      Descripcion           = @Descripcion,
      Prefijo               = @Prefijo,
      SecuenciaInicial      = ISNULL(@SecuenciaInicial, SecuenciaInicial),
      ActualizaCosto        = CASE WHEN TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      IdMoneda              = @IdMoneda,
      IdTipoDocumentoEntrada = CASE WHEN TipoOperacion = 'T' THEN @IdTipoDocumentoEntrada ELSE NULL END,
      IdTipoDocumentoSalida = CASE WHEN TipoOperacion = 'T' THEN @IdTipoDocumentoSalida ELSE NULL END,
      Activo                = ISNULL(@Activo, Activo),
      FechaModificacion     = GETDATE(),
      UsuarioModificacion   = @UsuarioModificacion,
      IdSesionModif         = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento
      AND RowStatus = 1;

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.InvTiposDocumento SET
      RowStatus           = 0,
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif       = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  IF @Accion = 'LU'
  BEGIN
    SELECT
      u.IdUsuario,
      u.NombreUsuario,
      u.Nombres,
      u.Correo,
      CASE WHEN tdu.IdTipoDocUsuario IS NOT NULL THEN 1 ELSE 0 END AS Asignado
    FROM dbo.Usuarios u
    LEFT JOIN dbo.InvTipoDocUsuario tdu
      ON tdu.IdUsuario = u.IdUsuario
      AND tdu.IdTipoDocumento = @IdTipoDocumento
      AND tdu.Activo = 1
    WHERE u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres;
    RETURN;
  END

  IF @Accion = 'U'
  BEGIN
    UPDATE dbo.InvTipoDocUsuario SET
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoDocumento = @IdTipoDocumento;

    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      INSERT INTO dbo.InvTipoDocUsuario (IdTipoDocumento, IdUsuario, UsuarioCreacion)
      SELECT @IdTipoDocumento, value, @UsuarioCreacion
      FROM STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE TRY_CAST(value AS INT) IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM dbo.InvTipoDocUsuario
          WHERE IdTipoDocumento = @IdTipoDocumento AND IdUsuario = TRY_CAST(value AS INT)
        );

      UPDATE dbo.InvTipoDocUsuario SET
        Activo              = 1,
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
      WHERE IdTipoDocumento = @IdTipoDocumento
        AND IdUsuario IN (
          SELECT TRY_CAST(value AS INT)
          FROM STRING_SPLIT(@UsuariosAsignados, ',')
          WHERE TRY_CAST(value AS INT) IS NOT NULL
        );
    END

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'LU', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END
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
    END,
    @IdTipoDocumentoAux = CASE
      WHEN @Modo IN ('SO', 'ST') THEN TD.IdTipoDocumentoSalida
      ELSE TD.IdTipoDocumentoEntrada
    END
  FROM dbo.InvDocumentos D
  INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento
  INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
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

  IF @IdTipoDocumentoAux IS NULL
    THROW 50087, 'El tipo de transferencia no tiene configurados los tipos de entrada/salida.', 1;

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.InvTiposDocumento
    WHERE IdTipoDocumento = @IdTipoDocumentoAux
      AND TipoOperacion = @TipoOperacion
      AND Activo = 1
      AND RowStatus = 1
  )
    THROW 50088, 'El tipo documental configurado para la transferencia no es valido.', 1;

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

DECLARE @DefaultEntrada INT = (
  SELECT TOP (1) IdTipoDocumento
  FROM dbo.InvTiposDocumento
  WHERE TipoOperacion = 'E' AND Activo = 1 AND RowStatus = 1
  ORDER BY IdTipoDocumento
);
DECLARE @DefaultSalida INT = (
  SELECT TOP (1) IdTipoDocumento
  FROM dbo.InvTiposDocumento
  WHERE TipoOperacion = 'S' AND Activo = 1 AND RowStatus = 1
  ORDER BY IdTipoDocumento
);

UPDATE dbo.InvTiposDocumento
SET
  IdTipoDocumentoEntrada = COALESCE(IdTipoDocumentoEntrada, @DefaultEntrada),
  IdTipoDocumentoSalida = COALESCE(IdTipoDocumentoSalida, @DefaultSalida)
WHERE TipoOperacion = 'T'
  AND RowStatus = 1;
GO

PRINT '=== Script 80 ejecutado correctamente ==='
GO
