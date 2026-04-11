-- ============================================================
-- SP: spInvDocumentosCRUD (filtros + paginacion en accion L)
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.spInvDocumentosCRUD
  @Accion              CHAR(2)         = 'L',
  @IdDocumento         INT             = NULL,
  @IdTipoDocumento     INT             = NULL,
  @TipoOperacion       CHAR(1)         = NULL,
  @Fecha               DATE            = NULL,
  @IdAlmacen           INT             = NULL,
  @IdMoneda            INT             = NULL,
  @TasaCambio          DECIMAL(18,6)   = 1.000000,
  @Referencia          NVARCHAR(250)   = NULL,
  @Observacion         NVARCHAR(500)   = NULL,
  @DetalleJSON         NVARCHAR(MAX)   = NULL,
  @IdUsuario           INT             = NULL,
  @FechaDesde          DATE            = NULL,
  @FechaHasta          DATE            = NULL,
  @SecuenciaDesde      INT             = NULL,
  @SecuenciaHasta      INT             = NULL,
  @NumeroPagina        INT             = 1,
  @TamanoPagina        INT             = 20,
  @IdSesion            INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- ── L: Listar documentos (con filtros y paginacion) ───────
  IF @Accion = 'L'
  BEGIN
    IF ISNULL(@NumeroPagina, 0) < 1 SET @NumeroPagina = 1;
    IF ISNULL(@TamanoPagina, 0) < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 200 SET @TamanoPagina = 200;

    ;WITH Base AS (
      SELECT
        d.IdDocumento,
        d.IdTipoDocumento,
        td.Descripcion   AS NombreTipoDocumento,
        d.TipoOperacion,
        d.Periodo,
        d.Secuencia,
        d.NumeroDocumento,
        d.Fecha,
        d.IdAlmacen,
        a.Descripcion    AS NombreAlmacen,
        d.IdMoneda,
        m.Nombre         AS NombreMoneda,
        m.Simbolo        AS SimboloMoneda,
        d.TasaCambio,
        d.Referencia,
        d.Observacion,
        d.TotalDocumento,
        d.Estado,
        d.FechaCreacion,
        d.UsuarioCreacion
      FROM dbo.InvDocumentos d
      INNER JOIN dbo.InvTiposDocumento td ON td.IdTipoDocumento = d.IdTipoDocumento
      INNER JOIN dbo.Almacenes a ON a.IdAlmacen = d.IdAlmacen
      LEFT JOIN dbo.Monedas m ON m.IdMoneda = d.IdMoneda
      WHERE d.RowStatus = 1
        AND (@TipoOperacion IS NULL OR d.TipoOperacion = @TipoOperacion)
        AND (@IdAlmacen IS NULL OR d.IdAlmacen = @IdAlmacen)
        AND (@IdTipoDocumento IS NULL OR d.IdTipoDocumento = @IdTipoDocumento)
        AND (@FechaDesde IS NULL OR d.Fecha >= @FechaDesde)
        AND (@FechaHasta IS NULL OR d.Fecha <= @FechaHasta)
        AND (@SecuenciaDesde IS NULL OR d.Secuencia >= @SecuenciaDesde)
        AND (@SecuenciaHasta IS NULL OR d.Secuencia <= @SecuenciaHasta)
    )
    SELECT
      b.*,
      COUNT(1) OVER() AS TotalRows
    FROM Base b
    ORDER BY b.Fecha DESC, b.IdDocumento DESC
    OFFSET (@NumeroPagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
    RETURN;
  END

  -- ── O: Obtener documento con detalle ──────────────────────
  IF @Accion = 'O'
  BEGIN
    SELECT
      d.IdDocumento,
      d.IdTipoDocumento,
      td.Descripcion   AS NombreTipoDocumento,
      d.TipoOperacion,
      d.Periodo,
      d.Secuencia,
      d.NumeroDocumento,
      d.Fecha,
      d.IdAlmacen,
      a.Descripcion    AS NombreAlmacen,
      d.IdMoneda,
      m.Nombre         AS NombreMoneda,
      m.Simbolo        AS SimboloMoneda,
      d.TasaCambio,
      d.Referencia,
      d.Observacion,
      d.TotalDocumento,
      d.Estado,
      d.FechaCreacion,
      d.UsuarioCreacion
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTiposDocumento td ON td.IdTipoDocumento = d.IdTipoDocumento
    INNER JOIN dbo.Almacenes a ON a.IdAlmacen = d.IdAlmacen
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = d.IdMoneda
    WHERE d.IdDocumento = @IdDocumento AND d.RowStatus = 1;

    SELECT
      det.IdDetalle,
      det.NumeroLinea,
      det.IdProducto,
      det.Codigo,
      det.Descripcion,
      det.IdUnidadMedida,
      det.NombreUnidad,
      det.Cantidad,
      det.Costo,
      det.Total
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;
    RETURN;
  END

  -- ── I: Insertar documento completo ────────────────────────
  IF @Accion = 'I'
  BEGIN
    BEGIN TRY
      BEGIN TRANSACTION;

      DECLARE @TipoOp CHAR(1), @Prefijo VARCHAR(10), @NuevaSecuencia INT, @NumDoc VARCHAR(30);
      DECLARE @TipoMoneda INT;

      UPDATE dbo.InvTiposDocumento
        SET SecuenciaActual = SecuenciaActual + 1
      WHERE IdTipoDocumento = @IdTipoDocumento;

      SELECT
        @TipoOp = TipoOperacion,
        @Prefijo = ISNULL(Prefijo, ''),
        @NuevaSecuencia = SecuenciaActual,
        @TipoMoneda = IdMoneda
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumento;

      SET @NumDoc = CASE
        WHEN @Prefijo <> '' THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4)
        ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4)
      END;

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
        0, 'A', @IdUsuario, @IdSesion
      );

      DECLARE @NewDocId INT = SCOPE_IDENTITY();
      DECLARE @TotalDoc DECIMAL(18,4) = 0;

      INSERT INTO dbo.InvDocumentoDetalle (
        IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
        IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
      )
      SELECT
        @NewDocId,
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
      WHERE j.idProducto IS NOT NULL AND j.cantidad > 0;

      SELECT @TotalDoc = ISNULL(SUM(Total), 0)
      FROM dbo.InvDocumentoDetalle
      WHERE IdDocumento = @NewDocId AND RowStatus = 1;

      UPDATE dbo.InvDocumentos SET TotalDocumento = @TotalDoc WHERE IdDocumento = @NewDocId;

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

        UPDATE pa SET
          pa.Cantidad = pa.Cantidad + det.Cantidad,
          pa.FechaModificacion = GETDATE(),
          pa.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
          AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1;

        UPDATE p SET
          p.CostoPromedio = CASE
            WHEN (stockActual.TotalQty + det.Cantidad) > 0
            THEN ROUND((p.CostoPromedio * stockActual.TotalQty + det.Costo * det.Cantidad) / (stockActual.TotalQty + det.Cantidad), 4)
            ELSE det.Costo
          END,
          p.FechaModificacion = GETDATE(),
          p.UsuarioModificacion = @IdUsuario
        FROM dbo.Productos p
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = p.IdProducto
        CROSS APPLY (
          SELECT ISNULL(SUM(pa2.Cantidad), 0) - det.Cantidad AS TotalQty
          FROM dbo.ProductoAlmacenes pa2
          WHERE pa2.IdProducto = p.IdProducto AND pa2.RowStatus = 1
        ) stockActual
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1;
      END

      IF @TipoOp = 'S'
      BEGIN
        UPDATE pa SET
          pa.Cantidad = pa.Cantidad - det.Cantidad,
          pa.FechaModificacion = GETDATE(),
          pa.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
          AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1;
      END

      COMMIT TRANSACTION;
      EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @NewDocId;
      RETURN;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  -- ── N: Anular documento ───────────────────────────────────
  IF @Accion = 'N'
  BEGIN
    BEGIN TRY
      BEGIN TRANSACTION;

      DECLARE @DocTipoOp CHAR(1), @DocAlmacen INT;
      SELECT @DocTipoOp = TipoOperacion, @DocAlmacen = IdAlmacen
      FROM dbo.InvDocumentos WHERE IdDocumento = @IdDocumento AND Estado = 'A';

      IF @DocTipoOp IS NULL
        THROW 50010, 'Documento no encontrado o ya anulado.', 1;

      IF @DocTipoOp IN ('E', 'C')
      BEGIN
        UPDATE pa SET
          pa.Cantidad = pa.Cantidad - det.Cantidad,
          pa.FechaModificacion = GETDATE()
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
          AND pa.IdAlmacen = @DocAlmacen AND pa.RowStatus = 1;
      END

      IF @DocTipoOp = 'S'
      BEGIN
        UPDATE pa SET
          pa.Cantidad = pa.Cantidad + det.Cantidad,
          pa.FechaModificacion = GETDATE()
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
          AND pa.IdAlmacen = @DocAlmacen AND pa.RowStatus = 1;
      END

      UPDATE dbo.InvDocumentos SET
        Estado = 'N',
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario,
        IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      COMMIT TRANSACTION;
      EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @IdDocumento;
      RETURN;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  -- ── LT: Listar tipos de documento asignados al usuario ────
  IF @Accion = 'LT'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      t.IdMoneda,
      m.Nombre  AS NombreMoneda,
      m.Simbolo AS SimboloMoneda
    FROM dbo.InvTiposDocumento t
    INNER JOIN dbo.InvTipoDocUsuario tdu
      ON tdu.IdTipoDocumento = t.IdTipoDocumento
      AND tdu.IdUsuario = @IdUsuario
      AND tdu.Activo = 1
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE t.RowStatus = 1 AND t.Activo = 1
      AND (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
    ORDER BY t.Descripcion;
    RETURN;
  END

END
GO

PRINT 'SP spInvDocumentosCRUD actualizado (filtros + paginacion) correctamente.';
GO
