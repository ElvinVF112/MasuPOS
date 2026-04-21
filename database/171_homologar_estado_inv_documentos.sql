-- ============================================================
-- Script 171: Homologar Estado en InvDocumentos
--
-- Estándar del sistema:
--   I = Pendiente de Postear
--   P = Posteado
--   N = Anulado
--
-- InvDocumentos usaba:
--   A = Activo/Posteado  → P
--   N = Anulado          → N (sin cambio)
-- ============================================================

-- 1. Quitar CHECK constraint viejo
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_InvDocumentos_Estado'
           AND parent_object_id = OBJECT_ID('dbo.InvDocumentos'))
    ALTER TABLE dbo.InvDocumentos DROP CONSTRAINT CK_InvDocumentos_Estado;
GO

-- 2. Migrar datos
UPDATE dbo.InvDocumentos SET Estado = 'P' WHERE Estado = 'A';
GO

-- 3. Crear nuevo CHECK constraint
ALTER TABLE dbo.InvDocumentos
    ADD CONSTRAINT CK_InvDocumentos_Estado
    CHECK (Estado IN ('I','P','N'));
GO

-- 4. Recrear spInvDocumentosCRUD con Estado 'P' en INSERT y 'P' en validación anulación
IF OBJECT_ID('dbo.spInvDocumentosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spInvDocumentosCRUD;
GO

CREATE PROCEDURE dbo.spInvDocumentosCRUD
  @Accion             CHAR(2)         = 'L',
  @IdDocumento        INT             = NULL,
  @IdTipoDocumento    INT             = NULL,
  @TipoOperacion      CHAR(1)         = NULL,
  @Fecha              DATE            = NULL,
  @IdAlmacen          INT             = NULL,
  @IdMoneda           INT             = NULL,
  @TasaCambio         DECIMAL(18,6)   = 1.000000,
  @Referencia         NVARCHAR(250)   = NULL,
  @Observacion        NVARCHAR(500)   = NULL,
  @DetalleJSON        NVARCHAR(MAX)   = NULL,
  @IdUsuario          INT             = NULL,
  @FechaDesde         DATE            = NULL,
  @FechaHasta         DATE            = NULL,
  @SecuenciaDesde     INT             = NULL,
  @SecuenciaHasta     INT             = NULL,
  @NumeroPagina       INT             = 1,
  @TamanoPagina       INT             = 20,
  @IdSesion           INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    IF ISNULL(@NumeroPagina, 0) < 1 SET @NumeroPagina = 1;
    IF ISNULL(@TamanoPagina, 0) < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 200 SET @TamanoPagina = 200;

    ;WITH Base AS (
      SELECT
        d.IdDocumento, d.IdTipoDocumento,
        td.Descripcion AS NombreTipoDocumento,
        d.TipoOperacion, d.Periodo, d.Secuencia, d.NumeroDocumento,
        d.Fecha, d.IdAlmacen,
        a.Descripcion  AS NombreAlmacen,
        d.IdMoneda,
        m.Nombre       AS NombreMoneda,
        m.Simbolo      AS SimboloMoneda,
        d.TasaCambio, d.Referencia, d.Observacion,
        d.TotalDocumento, d.Estado,
        d.FechaCreacion, d.UsuarioCreacion
      FROM dbo.InvDocumentos d
      INNER JOIN dbo.InvTiposDocumento td ON td.IdTipoDocumento = d.IdTipoDocumento
      INNER JOIN dbo.Almacenes a          ON a.IdAlmacen = d.IdAlmacen
      LEFT  JOIN dbo.Monedas m            ON m.IdMoneda = d.IdMoneda
      WHERE d.RowStatus = 1
        AND (@TipoOperacion    IS NULL OR d.TipoOperacion    = @TipoOperacion)
        AND (@IdAlmacen        IS NULL OR d.IdAlmacen        = @IdAlmacen)
        AND (@IdTipoDocumento  IS NULL OR d.IdTipoDocumento  = @IdTipoDocumento)
        AND (@FechaDesde       IS NULL OR d.Fecha            >= @FechaDesde)
        AND (@FechaHasta       IS NULL OR d.Fecha            <= @FechaHasta)
        AND (@SecuenciaDesde   IS NULL OR d.Secuencia        >= @SecuenciaDesde)
        AND (@SecuenciaHasta   IS NULL OR d.Secuencia        <= @SecuenciaHasta)
    )
    SELECT b.*, COUNT(1) OVER() AS TotalRows
    FROM Base b
    ORDER BY b.Fecha DESC, b.IdDocumento DESC
    OFFSET (@NumeroPagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      d.IdDocumento, d.IdTipoDocumento,
      td.Descripcion AS NombreTipoDocumento,
      d.TipoOperacion, d.Periodo, d.Secuencia, d.NumeroDocumento,
      d.Fecha, d.IdAlmacen,
      a.Descripcion  AS NombreAlmacen,
      d.IdMoneda,
      m.Nombre       AS NombreMoneda,
      m.Simbolo      AS SimboloMoneda,
      d.TasaCambio, d.Referencia, d.Observacion,
      d.TotalDocumento, d.Estado,
      d.FechaCreacion, d.UsuarioCreacion
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTiposDocumento td ON td.IdTipoDocumento = d.IdTipoDocumento
    INNER JOIN dbo.Almacenes a          ON a.IdAlmacen = d.IdAlmacen
    LEFT  JOIN dbo.Monedas m            ON m.IdMoneda = d.IdMoneda
    WHERE d.IdDocumento = @IdDocumento AND d.RowStatus = 1;

    SELECT
      det.IdDetalle, det.NumeroLinea, det.IdProducto, det.Codigo, det.Descripcion,
      det.IdUnidadMedida, det.NombreUnidad, det.Cantidad, det.Costo, det.Total
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @TipoOp CHAR(1), @Prefijo VARCHAR(10), @NuevaSecuencia INT, @NumDoc VARCHAR(30);
      DECLARE @TipoMoneda INT, @ActualizaCosto BIT;

      UPDATE dbo.InvTiposDocumento SET SecuenciaActual = SecuenciaActual + 1 WHERE IdTipoDocumento = @IdTipoDocumento;

      SELECT
        @TipoOp          = TipoOperacion,
        @Prefijo         = ISNULL(Prefijo, ''),
        @NuevaSecuencia  = SecuenciaActual,
        @TipoMoneda      = IdMoneda,
        @ActualizaCosto  = ISNULL(ActualizaCosto, 0)
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumento;

      SET @NumDoc = CASE WHEN @Prefijo <> ''
                         THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4)
                         ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4) END;

      DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);
      IF @IdMoneda IS NULL SET @IdMoneda = @TipoMoneda;

      INSERT INTO dbo.InvDocumentos (
        IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento,
        Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion,
        TotalDocumento, Estado, UsuarioCreacion, IdSesionCreacion
      )
      VALUES (
        @IdTipoDocumento, @TipoOp, @Periodo, @NuevaSecuencia, @NumDoc,
        @Fecha, @IdAlmacen, @IdMoneda, @TasaCambio, @Referencia, @Observacion,
        0, 'P', @IdUsuario, @IdSesion
      );

      DECLARE @NewDocId INT = SCOPE_IDENTITY();

      INSERT INTO dbo.InvDocumentoDetalle (
        IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
        IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
      )
      SELECT
        @NewDocId, j.linea, j.idProducto, j.codigo, j.descripcion,
        j.idUnidadMedida, j.unidad, j.cantidad, j.costo,
        ROUND(j.cantidad * j.costo, 4), @IdUsuario
      FROM OPENJSON(@DetalleJSON) WITH (
        linea          INT            '$.linea',
        idProducto     INT            '$.idProducto',
        codigo         NVARCHAR(60)   '$.codigo',
        descripcion    NVARCHAR(200)  '$.descripcion',
        idUnidadMedida INT            '$.idUnidadMedida',
        unidad         NVARCHAR(50)   '$.unidad',
        cantidad       DECIMAL(18,4)  '$.cantidad',
        costo          DECIMAL(18,4)  '$.costo'
      ) j
      WHERE j.idProducto IS NOT NULL AND j.cantidad > 0;

      UPDATE d
      SET d.TotalDocumento = x.TotalDoc
      FROM dbo.InvDocumentos d
      CROSS APPLY (
        SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
      ) x
      WHERE d.IdDocumento = @NewDocId;

      IF @TipoOp IN ('E', 'C')
      BEGIN
        INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
        SELECT DISTINCT det.IdProducto, @IdAlmacen, 0, @IdUsuario
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
          AND NOT EXISTS (
            SELECT 1 FROM dbo.ProductoAlmacenes pa
            WHERE pa.IdProducto = det.IdProducto AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1
          );
      END

      DECLARE @Linea INT, @ProdId INT, @Cant DECIMAL(18,4), @Costo DECIMAL(18,4), @Total DECIMAL(18,4);
      DECLARE @StockAntes DECIMAL(18,4), @StockNuevo DECIMAL(18,4), @Signo SMALLINT;
      DECLARE @CostoPromAntes DECIMAL(10,4), @CostoPromNuevo DECIMAL(10,4);
      DECLARE @ManejaExistencia BIT, @VenderSinExistencia BIT;

      DECLARE c_det CURSOR LOCAL FAST_FORWARD FOR
      SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
      ORDER BY det.NumeroLinea;

      OPEN c_det;
      FETCH NEXT FROM c_det INTO @Linea, @ProdId, @Cant, @Costo, @Total;
      WHILE @@FETCH_STATUS = 0
      BEGIN
        SELECT
          @ManejaExistencia    = ISNULL(p.ManejaExistencia, 1),
          @VenderSinExistencia = ISNULL(p.VenderSinExistencia, 0),
          @CostoPromAntes      = ISNULL(p.CostoPromedio, 0)
        FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
        WHERE p.IdProducto = @ProdId;

        IF NOT EXISTS (
          SELECT 1 FROM dbo.ProductoAlmacenes pa
          WHERE pa.IdProducto = @ProdId AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1
        )
        BEGIN
          INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
          VALUES (@ProdId, @IdAlmacen, 0, @IdUsuario);
        END

        SELECT @StockAntes = ISNULL(pa.Cantidad, 0)
        FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
        WHERE pa.IdProducto = @ProdId AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1;

        SET @Signo = CASE WHEN @TipoOp IN ('E', 'C') THEN 1 ELSE -1 END;

        IF @TipoOp = 'S' AND @ManejaExistencia = 1 AND @VenderSinExistencia = 0 AND @StockAntes < @Cant
        BEGIN
          CLOSE c_det; DEALLOCATE c_det;
          THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
        END

        SET @StockNuevo = @StockAntes + (@Signo * @Cant);

        UPDATE dbo.ProductoAlmacenes
        SET Cantidad = @StockNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdId AND IdAlmacen = @IdAlmacen AND RowStatus = 1;

        SET @CostoPromNuevo = @CostoPromAntes;
        IF @TipoOp IN ('E', 'C') AND @ActualizaCosto = 1
        BEGIN
          SET @CostoPromNuevo = CASE
            WHEN @StockNuevo > 0 THEN ROUND(((@CostoPromAntes * @StockAntes) + (@Costo * @Cant)) / @StockNuevo, 4)
            ELSE @Costo END;
          UPDATE dbo.Productos
          SET CostoPromedio = @CostoPromNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @ProdId;
        END

        INSERT INTO dbo.InvMovimientos (
          IdProducto, IdAlmacen, TipoMovimiento, Signo,
          IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
          Cantidad, CostoUnitario, CostoTotal,
          SaldoAnterior, SaldoNuevo,
          CostoPromedioAnterior, CostoPromedioNuevo,
          Fecha, Periodo, UsuarioCreacion
        ) VALUES (
          @ProdId, @IdAlmacen,
          CASE @TipoOp WHEN 'E' THEN 'ENT' WHEN 'S' THEN 'SAL' WHEN 'C' THEN 'COM' ELSE 'TRF' END,
          @Signo, @NewDocId, 'InvDocumento', @NumDoc, @Linea,
          @Cant, @Costo, @Total,
          @StockAntes, @StockNuevo, @CostoPromAntes, @CostoPromNuevo,
          @Fecha, @Periodo, @IdUsuario
        );

        FETCH NEXT FROM c_det INTO @Linea, @ProdId, @Cant, @Costo, @Total;
      END
      CLOSE c_det; DEALLOCATE c_det;

      COMMIT TRANSACTION;
      EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @NewDocId;
      RETURN;
    END TRY
    BEGIN CATCH
      IF CURSOR_STATUS('local', 'c_det') >= -1 BEGIN TRY CLOSE c_det; END TRY BEGIN CATCH END CATCH;
      IF CURSOR_STATUS('local', 'c_det') >= -1 BEGIN TRY DEALLOCATE c_det; END TRY BEGIN CATCH END CATCH;
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  IF @Accion = 'N'
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @DocTipoOp CHAR(1), @DocAlmacen INT, @ActualizaCostoOrig BIT, @DocNum VARCHAR(30), @DocFecha DATE, @DocPeriodo VARCHAR(6);
      SELECT
        @DocTipoOp          = d.TipoOperacion,
        @DocAlmacen         = d.IdAlmacen,
        @ActualizaCostoOrig = ISNULL(t.ActualizaCosto, 0),
        @DocNum             = d.NumeroDocumento,
        @DocFecha           = d.Fecha,
        @DocPeriodo         = d.Periodo
      FROM dbo.InvDocumentos d
      INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
      WHERE d.IdDocumento = @IdDocumento AND d.Estado = 'P';

      IF @DocTipoOp IS NULL
        THROW 50010, 'Documento no encontrado o ya anulado.', 1;

      DECLARE @NLinea INT, @NProdId INT, @NCant DECIMAL(18,4), @NCosto DECIMAL(18,4), @NTotal DECIMAL(18,4);
      DECLARE @NStockAntes DECIMAL(18,4), @NStockNuevo DECIMAL(18,4), @NSigno SMALLINT;
      DECLARE @NCostoPromAntes DECIMAL(10,4), @NCostoPromNuevo DECIMAL(10,4);

      DECLARE c_anu CURSOR LOCAL FAST_FORWARD FOR
      SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
      ORDER BY det.NumeroLinea;

      OPEN c_anu;
      FETCH NEXT FROM c_anu INTO @NLinea, @NProdId, @NCant, @NCosto, @NTotal;
      WHILE @@FETCH_STATUS = 0
      BEGIN
        SELECT @NCostoPromAntes = ISNULL(p.CostoPromedio, 0)
        FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
        WHERE p.IdProducto = @NProdId;

        SELECT @NStockAntes = ISNULL(pa.Cantidad, 0)
        FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
        WHERE pa.IdProducto = @NProdId AND pa.IdAlmacen = @DocAlmacen AND pa.RowStatus = 1;

        IF @DocTipoOp IN ('E', 'C')
        BEGIN
          SET @NSigno = -1;
          SET @NStockNuevo = @NStockAntes - @NCant;
          SET @NCostoPromNuevo = @NCostoPromAntes;
          IF @ActualizaCostoOrig = 1
          BEGIN
            SET @NCostoPromNuevo = CASE
              WHEN (@NStockAntes - @NCant) > 0 THEN ROUND(((@NCostoPromAntes * @NStockAntes) - (@NCosto * @NCant)) / (@NStockAntes - @NCant), 4)
              ELSE @NCostoPromAntes END;
            UPDATE dbo.Productos
            SET CostoPromedio = @NCostoPromNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
            WHERE IdProducto = @NProdId;
          END
          UPDATE dbo.ProductoAlmacenes
          SET Cantidad = @NStockNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @NProdId AND IdAlmacen = @DocAlmacen AND RowStatus = 1;
        END
        ELSE
        BEGIN
          SET @NSigno = 1;
          SET @NStockNuevo = @NStockAntes + @NCant;
          SET @NCostoPromNuevo = @NCostoPromAntes;
          UPDATE dbo.ProductoAlmacenes
          SET Cantidad = @NStockNuevo, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @NProdId AND IdAlmacen = @DocAlmacen AND RowStatus = 1;
        END

        INSERT INTO dbo.InvMovimientos (
          IdProducto, IdAlmacen, TipoMovimiento, Signo,
          IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
          Cantidad, CostoUnitario, CostoTotal,
          SaldoAnterior, SaldoNuevo,
          CostoPromedioAnterior, CostoPromedioNuevo,
          Fecha, Periodo, UsuarioCreacion, Observacion
        ) VALUES (
          @NProdId, @DocAlmacen, 'ANU', @NSigno,
          @IdDocumento, 'InvDocumento', @DocNum, @NLinea,
          @NCant, @NCosto, @NTotal,
          @NStockAntes, @NStockNuevo, @NCostoPromAntes, @NCostoPromNuevo,
          @DocFecha, @DocPeriodo, @IdUsuario, N'Anulacion de documento'
        );

        FETCH NEXT FROM c_anu INTO @NLinea, @NProdId, @NCant, @NCosto, @NTotal;
      END
      CLOSE c_anu; DEALLOCATE c_anu;

      UPDATE dbo.InvDocumentoDetalle SET RowStatus = 0 WHERE IdDocumento = @IdDocumento AND RowStatus = 1;

      UPDATE dbo.InvDocumentos
      SET Estado = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario, IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      COMMIT TRANSACTION;
      EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @IdDocumento;
      RETURN;
    END TRY
    BEGIN CATCH
      IF CURSOR_STATUS('local', 'c_anu') >= -1 BEGIN TRY CLOSE c_anu; END TRY BEGIN CATCH END CATCH;
      IF CURSOR_STATUS('local', 'c_anu') >= -1 BEGIN TRY DEALLOCATE c_anu; END TRY BEGIN CATCH END CATCH;
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  IF @Accion = 'LT'
  BEGIN
    SELECT
      t.IdTipoDocumento, t.TipoOperacion, t.Codigo, t.Descripcion, t.Prefijo,
      t.SecuenciaInicial, t.SecuenciaActual,
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre  AS NombreMoneda,
      m.Simbolo AS SimboloMoneda
    FROM dbo.InvTiposDocumento t
    INNER JOIN dbo.InvTipoDocUsuario tdu ON tdu.IdTipoDocumento = t.IdTipoDocumento
                                        AND tdu.IdUsuario = @IdUsuario AND tdu.Activo = 1
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE t.RowStatus = 1 AND t.Activo = 1
      AND (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
    ORDER BY t.Descripcion;
    RETURN;
  END
END
GO

-- 5. Recrear spInvActualizarDocumento con Estado 'P'
IF OBJECT_ID('dbo.spInvActualizarDocumento', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spInvActualizarDocumento;
GO

CREATE PROCEDURE dbo.spInvActualizarDocumento
  @IdDocumento     INT,
  @IdTipoDocumento INT             = NULL,
  @Fecha           DATE,
  @IdAlmacen       INT,
  @IdMoneda        INT             = NULL,
  @TasaCambio      DECIMAL(18,6)   = 1.000000,
  @Referencia      NVARCHAR(250)   = NULL,
  @Observacion     NVARCHAR(500)   = NULL,
  @DetalleJSON     NVARCHAR(MAX),
  @IdUsuario       INT             = NULL,
  @IdSesion        INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    DECLARE @OldTipoOp CHAR(1), @OldAlmacen INT, @OldTipoDocumento INT, @OldActualizaCosto BIT;
    DECLARE @DocNum VARCHAR(30), @DocPeriodo VARCHAR(6);

    SELECT
      @OldTipoOp         = d.TipoOperacion,
      @OldAlmacen        = d.IdAlmacen,
      @OldTipoDocumento  = d.IdTipoDocumento,
      @OldActualizaCosto = ISNULL(t.ActualizaCosto, 0),
      @DocNum            = d.NumeroDocumento,
      @DocPeriodo        = d.Periodo
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
    WHERE d.IdDocumento = @IdDocumento AND d.RowStatus = 1 AND d.Estado = 'P';

    IF @OldTipoOp IS NULL
      THROW 50020, 'Documento no encontrado o no editable (anulado).', 1;

    IF @IdTipoDocumento IS NULL SET @IdTipoDocumento = @OldTipoDocumento;

    DECLARE @NewTipoOp CHAR(1), @TipoMoneda INT, @NewActualizaCosto BIT;
    SELECT
      @NewTipoOp        = t.TipoOperacion,
      @TipoMoneda       = t.IdMoneda,
      @NewActualizaCosto = ISNULL(t.ActualizaCosto, 0)
    FROM dbo.InvTiposDocumento t
    WHERE t.IdTipoDocumento = @IdTipoDocumento AND t.RowStatus = 1;

    IF @NewTipoOp IS NULL THROW 50021, 'Tipo de documento no valido.', 1;
    IF @NewTipoOp <> @OldTipoOp THROW 50022, 'No se permite cambiar tipo de operacion en edicion.', 1;

    IF @IdMoneda IS NULL SET @IdMoneda = @TipoMoneda;

    DECLARE @LineaOld INT, @ProdOld INT, @CantOld DECIMAL(18,4), @CostoOld DECIMAL(18,4), @TotalOld DECIMAL(18,4), @CantBaseOld DECIMAL(18,4);
    DECLARE @StockAntesOld DECIMAL(18,4), @StockNuevoOld DECIMAL(18,4), @SignoOld SMALLINT;
    DECLARE @CostoPromAntesOld DECIMAL(10,4), @CostoPromNuevoOld DECIMAL(10,4), @CostoBaseOld DECIMAL(18,4);

    DECLARE c_old CURSOR LOCAL FAST_FORWARD FOR
    SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
           dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;

    OPEN c_old;
    FETCH NEXT FROM c_old INTO @LineaOld, @ProdOld, @CantOld, @CostoOld, @TotalOld, @CantBaseOld;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @CostoBaseOld = CASE WHEN ISNULL(@CantBaseOld, 0) > 0 THEN ROUND(@TotalOld / @CantBaseOld, 4) ELSE @CostoOld END;

      SELECT @CostoPromAntesOld = ISNULL(p.CostoPromedio, 0)
      FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK) WHERE p.IdProducto = @ProdOld;

      SELECT @StockAntesOld = ISNULL(pa.Cantidad, 0)
      FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
      WHERE pa.IdProducto = @ProdOld AND pa.IdAlmacen = @OldAlmacen AND pa.RowStatus = 1;

      IF @OldTipoOp IN ('E', 'C')
      BEGIN
        SET @SignoOld = -1;
        SET @StockNuevoOld = @StockAntesOld - @CantBaseOld;
        SET @CostoPromNuevoOld = @CostoPromAntesOld;
        IF @OldActualizaCosto = 1
        BEGIN
          SET @CostoPromNuevoOld = CASE
            WHEN (@StockAntesOld - @CantBaseOld) > 0 THEN ROUND(((@CostoPromAntesOld * @StockAntesOld) - (@CostoOld * @CantOld)) / (@StockAntesOld - @CantBaseOld), 4)
            ELSE @CostoPromAntesOld END;
          UPDATE dbo.Productos SET CostoPromedio = @CostoPromNuevoOld, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario WHERE IdProducto = @ProdOld;
        END
        UPDATE dbo.ProductoAlmacenes SET Cantidad = @StockNuevoOld, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdOld AND IdAlmacen = @OldAlmacen AND RowStatus = 1;
      END
      ELSE
      BEGIN
        SET @SignoOld = 1;
        SET @StockNuevoOld = @StockAntesOld + @CantBaseOld;
        SET @CostoPromNuevoOld = @CostoPromAntesOld;
        UPDATE dbo.ProductoAlmacenes SET Cantidad = @StockNuevoOld, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdOld AND IdAlmacen = @OldAlmacen AND RowStatus = 1;
      END

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo,
        IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
        Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, UsuarioCreacion, Observacion
      ) VALUES (
        @ProdOld, @OldAlmacen, 'ANU', @SignoOld, @IdDocumento, 'InvDocumento', @DocNum, @LineaOld,
        @CantBaseOld, @CostoBaseOld, @TotalOld, @StockAntesOld, @StockNuevoOld,
        @CostoPromAntesOld, @CostoPromNuevoOld, @Fecha, CONVERT(VARCHAR(6), @Fecha, 112), @IdUsuario, N'Reversion por edicion'
      );

      FETCH NEXT FROM c_old INTO @LineaOld, @ProdOld, @CantOld, @CostoOld, @TotalOld, @CantBaseOld;
    END
    CLOSE c_old; DEALLOCATE c_old;

    UPDATE dbo.InvDocumentoDetalle SET RowStatus = 0 WHERE IdDocumento = @IdDocumento AND RowStatus = 1;

    DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);

    UPDATE dbo.InvDocumentos SET
      IdTipoDocumento = @IdTipoDocumento, Fecha = @Fecha, Periodo = @Periodo,
      IdAlmacen = @IdAlmacen, IdMoneda = @IdMoneda, TasaCambio = @TasaCambio,
      Referencia = @Referencia, Observacion = @Observacion,
      FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario, IdSesionModif = @IdSesion
    WHERE IdDocumento = @IdDocumento;

    INSERT INTO dbo.InvDocumentoDetalle (
      IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
      IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
    )
    SELECT @IdDocumento, j.linea, j.idProducto, j.codigo, j.descripcion,
           j.idUnidadMedida, j.unidad, j.cantidad, j.costo, ROUND(j.cantidad * j.costo, 4), @IdUsuario
    FROM OPENJSON(@DetalleJSON) WITH (
      linea          INT            '$.linea',
      idProducto     INT            '$.idProducto',
      codigo         NVARCHAR(60)   '$.codigo',
      descripcion    NVARCHAR(200)  '$.descripcion',
      idUnidadMedida INT            '$.idUnidadMedida',
      unidad         NVARCHAR(50)   '$.unidad',
      cantidad       DECIMAL(18,4)  '$.cantidad',
      costo          DECIMAL(18,4)  '$.costo'
    ) j
    WHERE j.idProducto IS NOT NULL AND j.cantidad > 0;

    IF @OldTipoOp IN ('E', 'C')
    BEGIN
      INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
      SELECT DISTINCT det.IdProducto, @IdAlmacen, 0, @IdUsuario
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
        AND NOT EXISTS (SELECT 1 FROM dbo.ProductoAlmacenes pa WHERE pa.IdProducto = det.IdProducto AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1);
    END

    DECLARE @LineaNew INT, @ProdNew INT, @CantNew DECIMAL(18,4), @CostoNew DECIMAL(18,4), @TotalNew DECIMAL(18,4), @CantBaseNew DECIMAL(18,4);
    DECLARE @StockAntesNew DECIMAL(18,4), @StockNuevoNew DECIMAL(18,4), @SignoNew SMALLINT;
    DECLARE @CostoPromAntesNew DECIMAL(10,4), @CostoPromNuevoNew DECIMAL(10,4), @CostoBaseNew DECIMAL(18,4);
    DECLARE @ManejaNew BIT, @VendeSinNew BIT;

    DECLARE c_new CURSOR LOCAL FAST_FORWARD FOR
    SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
           dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;

    OPEN c_new;
    FETCH NEXT FROM c_new INTO @LineaNew, @ProdNew, @CantNew, @CostoNew, @TotalNew, @CantBaseNew;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @CostoBaseNew = CASE WHEN ISNULL(@CantBaseNew, 0) > 0 THEN ROUND(@TotalNew / @CantBaseNew, 4) ELSE @CostoNew END;

      SELECT @CostoPromAntesNew = ISNULL(p.CostoPromedio, 0), @ManejaNew = ISNULL(p.ManejaExistencia, 1), @VendeSinNew = ISNULL(p.VenderSinExistencia, 0)
      FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK) WHERE p.IdProducto = @ProdNew;

      SELECT @StockAntesNew = ISNULL(pa.Cantidad, 0)
      FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
      WHERE pa.IdProducto = @ProdNew AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1;

      SET @SignoNew = CASE WHEN @OldTipoOp IN ('E', 'C') THEN 1 ELSE -1 END;

      IF @OldTipoOp = 'S' AND @ManejaNew = 1 AND @VendeSinNew = 0 AND @StockAntesNew < @CantBaseNew
      BEGIN
        CLOSE c_new; DEALLOCATE c_new;
        THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
      END

      SET @StockNuevoNew = @StockAntesNew + (@SignoNew * @CantBaseNew);

      UPDATE dbo.ProductoAlmacenes SET Cantidad = @StockNuevoNew, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
      WHERE IdProducto = @ProdNew AND IdAlmacen = @IdAlmacen AND RowStatus = 1;

      SET @CostoPromNuevoNew = @CostoPromAntesNew;
      IF @OldTipoOp IN ('E', 'C') AND @NewActualizaCosto = 1
      BEGIN
        SET @CostoPromNuevoNew = CASE
          WHEN @StockNuevoNew > 0 THEN ROUND(((@CostoPromAntesNew * @StockAntesNew) + @TotalNew) / @StockNuevoNew, 4)
          ELSE @CostoBaseNew END;
        UPDATE dbo.Productos SET CostoPromedio = @CostoPromNuevoNew, FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario WHERE IdProducto = @ProdNew;
      END

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo,
        IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
        Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, UsuarioCreacion, Observacion
      ) VALUES (
        @ProdNew, @IdAlmacen,
        CASE @OldTipoOp WHEN 'E' THEN 'ENT' WHEN 'S' THEN 'SAL' WHEN 'C' THEN 'COM' ELSE 'TRF' END,
        @SignoNew, @IdDocumento, 'InvDocumento', @DocNum, @LineaNew,
        @CantBaseNew, @CostoBaseNew, @TotalNew, @StockAntesNew, @StockNuevoNew,
        @CostoPromAntesNew, @CostoPromNuevoNew, @Fecha, @Periodo, @IdUsuario, N'Reaplicacion por edicion'
      );

      FETCH NEXT FROM c_new INTO @LineaNew, @ProdNew, @CantNew, @CostoNew, @TotalNew, @CantBaseNew;
    END
    CLOSE c_new; DEALLOCATE c_new;

    UPDATE d SET d.TotalDocumento = x.TotalDoc
    FROM dbo.InvDocumentos d
    CROSS APPLY (SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc FROM dbo.InvDocumentoDetalle det WHERE det.IdDocumento = d.IdDocumento AND det.RowStatus = 1) x
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

-- Verificación
SELECT Estado, COUNT(*) AS Qty FROM dbo.InvDocumentos GROUP BY Estado ORDER BY Estado;
PRINT 'Script 171 aplicado correctamente.';
GO
