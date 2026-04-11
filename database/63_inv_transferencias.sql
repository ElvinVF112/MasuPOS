USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Almacenes', 'IdAlmacenTransito') IS NULL
BEGIN
  ALTER TABLE dbo.Almacenes ADD IdAlmacenTransito INT NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.foreign_keys
  WHERE name = 'FK_Almacenes_AlmacenTransito'
)
BEGIN
  ALTER TABLE dbo.Almacenes
    ADD CONSTRAINT FK_Almacenes_AlmacenTransito
    FOREIGN KEY (IdAlmacenTransito) REFERENCES dbo.Almacenes(IdAlmacen);
END
GO

DECLARE @IdTransitoGeneral INT;

SELECT @IdTransitoGeneral = IdAlmacen
FROM dbo.Almacenes
WHERE RowStatus = 1
  AND LOWER(LTRIM(RTRIM(Descripcion))) = 'transito general';

IF @IdTransitoGeneral IS NULL
BEGIN
  INSERT INTO dbo.Almacenes (
    Descripcion, Siglas, TipoAlmacen, Activo, RowStatus, FechaCreacion, UsuarioCreacion
  )
  VALUES (
    N'Transito General', N'TRN', 'T', 1, 1, GETDATE(), 1
  );

  SET @IdTransitoGeneral = SCOPE_IDENTITY();
END

UPDATE dbo.Almacenes
SET IdAlmacenTransito = @IdTransitoGeneral
WHERE RowStatus = 1
  AND TipoAlmacen <> 'T'
  AND IdAlmacenTransito IS NULL;
GO

CREATE OR ALTER PROCEDURE dbo.spAlmacenesCRUD
    @Accion              CHAR(1),
    @IdAlmacen           INT           = NULL,
    @Descripcion         NVARCHAR(100) = NULL,
    @Siglas              NVARCHAR(20)  = NULL,
    @TipoAlmacen         CHAR(1)       = NULL,
    @IdAlmacenTransito   INT           = NULL,
    @Activo              BIT           = NULL,
    @UsuarioCreacion     INT           = NULL,
    @UsuarioModificacion INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion IN ('I', 'A') AND ISNULL(@TipoAlmacen, 'O') <> 'T'
    BEGIN
        IF @IdAlmacenTransito IS NULL
            THROW 50041, 'El almacen de transito es obligatorio.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Almacenes
            WHERE IdAlmacen = @IdAlmacenTransito
              AND RowStatus = 1
              AND Activo = 1
              AND TipoAlmacen = 'T'
        )
            THROW 50042, 'El almacen de transito debe ser un almacen tipo T activo.', 1;
    END

    IF @Accion = 'L'
    BEGIN
        SELECT
          A.IdAlmacen, A.Descripcion, A.Siglas, A.TipoAlmacen, A.IdAlmacenTransito, A.Activo,
          T.Descripcion AS NombreAlmacenTransito
        FROM dbo.Almacenes A
        LEFT JOIN dbo.Almacenes T ON T.IdAlmacen = A.IdAlmacenTransito
        WHERE ISNULL(A.RowStatus,1)=1
        ORDER BY A.Descripcion;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
          A.IdAlmacen, A.Descripcion, A.Siglas, A.TipoAlmacen, A.IdAlmacenTransito, A.Activo,
          T.Descripcion AS NombreAlmacenTransito
        FROM dbo.Almacenes A
        LEFT JOIN dbo.Almacenes T ON T.IdAlmacen = A.IdAlmacenTransito
        WHERE A.IdAlmacen=@IdAlmacen;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.Almacenes WHERE Siglas=LTRIM(RTRIM(@Siglas)) AND ISNULL(RowStatus,1)=1)
            THROW 50043, 'Ya existe un almacen con esas siglas.', 1;

        INSERT INTO dbo.Almacenes (Descripcion, Siglas, TipoAlmacen, IdAlmacenTransito, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (LTRIM(RTRIM(@Descripcion)), LTRIM(RTRIM(@Siglas)), ISNULL(@TipoAlmacen,'O'), @IdAlmacenTransito, ISNULL(@Activo,1), 1, GETDATE(), @UsuarioCreacion);

        EXEC dbo.spAlmacenesCRUD @Accion='O', @IdAlmacen=SCOPE_IDENTITY();
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Almacenes
        SET Descripcion=LTRIM(RTRIM(@Descripcion)),
            Siglas=LTRIM(RTRIM(@Siglas)),
            TipoAlmacen=ISNULL(@TipoAlmacen,TipoAlmacen),
            IdAlmacenTransito=CASE WHEN ISNULL(@TipoAlmacen, TipoAlmacen) = 'T' THEN NULL ELSE @IdAlmacenTransito END,
            Activo=ISNULL(@Activo,Activo),
            FechaModificacion=GETDATE(),
            UsuarioModificacion=@UsuarioModificacion
        WHERE IdAlmacen=@IdAlmacen AND ISNULL(RowStatus,1)=1;

        EXEC dbo.spAlmacenesCRUD @Accion='O', @IdAlmacen=@IdAlmacen;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Almacenes
        SET RowStatus=0, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion
        WHERE IdAlmacen=@IdAlmacen;
        RETURN;
    END;

    THROW 50044, 'Accion no valida.', 1;
END;
GO

IF OBJECT_ID('dbo.InvTransferencias', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.InvTransferencias (
    IdDocumento           INT NOT NULL PRIMARY KEY CONSTRAINT FK_InvTransf_Doc FOREIGN KEY REFERENCES dbo.InvDocumentos(IdDocumento),
    IdAlmacenDestino      INT NOT NULL CONSTRAINT FK_InvTransf_AlmDest FOREIGN KEY REFERENCES dbo.Almacenes(IdAlmacen),
    IdAlmacenTransito     INT NOT NULL CONSTRAINT FK_InvTransf_AlmTran FOREIGN KEY REFERENCES dbo.Almacenes(IdAlmacen),
    EstadoTransferencia   CHAR(1) NOT NULL DEFAULT 'B' CONSTRAINT CK_InvTransf_Estado CHECK (EstadoTransferencia IN ('B','T','C','N')),
    FechaSalida           DATETIME NULL,
    FechaRecepcion        DATETIME NULL,
    UsuarioSalida         INT NULL,
    UsuarioRecepcion      INT NULL,
    IdSesionSalida        INT NULL,
    IdSesionRecepcion     INT NULL,
    RowStatus             INT NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion       INT NOT NULL,
    FechaModificacion     DATETIME NULL,
    UsuarioModificacion   INT NULL
  );
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
    DECLARE @TransitoOrigen INT;
    SELECT @TransitoOrigen = IdAlmacenTransito FROM dbo.Almacenes WHERE IdAlmacen = @IdAlmacen AND RowStatus = 1;
    IF @TransitoOrigen IS NULL THROW 50045, 'El almacen origen no tiene almacen de transito configurado.', 1;

    IF @Accion = 'I'
    BEGIN
      EXEC dbo.spInvDocumentosCRUD
        @Accion='I', @IdTipoDocumento=@IdTipoDocumento, @TipoOperacion='T', @Fecha=@Fecha, @IdAlmacen=@IdAlmacen,
        @Referencia=@Referencia, @Observacion=@Observacion, @DetalleJSON=@DetalleJSON, @IdUsuario=@IdUsuario, @IdSesion=@IdSesion;

      SET @IdDocumento = (SELECT TOP 1 IdDocumento FROM dbo.InvDocumentos WHERE TipoOperacion = 'T' AND UsuarioCreacion = @IdUsuario ORDER BY IdDocumento DESC);

      INSERT INTO dbo.InvTransferencias (IdDocumento, IdAlmacenDestino, IdAlmacenTransito, EstadoTransferencia, UsuarioCreacion)
      VALUES (@IdDocumento, @IdAlmacenDestino, @TransitoOrigen, 'B', @IdUsuario);

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.InvTransferencias WHERE IdDocumento=@IdDocumento AND EstadoTransferencia='B' AND RowStatus=1)
      THROW 50046, 'Solo se pueden editar transferencias en borrador.', 1;

    EXEC dbo.spInvActualizarDocumento
      @IdDocumento=@IdDocumento, @IdTipoDocumento=@IdTipoDocumento, @Fecha=@Fecha, @IdAlmacen=@IdAlmacen,
      @Referencia=@Referencia, @Observacion=@Observacion, @DetalleJSON=@DetalleJSON, @IdUsuario=@IdUsuario, @IdSesion=@IdSesion;

    UPDATE dbo.InvTransferencias
    SET IdAlmacenDestino=@IdAlmacenDestino, IdAlmacenTransito=@TransitoOrigen, FechaModificacion=GETDATE(), UsuarioModificacion=@IdUsuario
    WHERE IdDocumento=@IdDocumento;

    EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
    RETURN;
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
      SUM(Cantidad) AS Cantidad,
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

PRINT 'IMPORTANTE: integrar manualmente la guardia THROW 50030 en spInvDocumentosCRUD para TipoOperacion = ''T'' en acciones I/N antes de ejecutar en produccion.';
GO

PRINT '63_inv_transferencias.sql generado.';
GO
