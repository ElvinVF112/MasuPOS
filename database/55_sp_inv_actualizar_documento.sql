USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

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
    SELECT
      @OldTipoOp = d.TipoOperacion,
      @OldAlmacen = d.IdAlmacen,
      @OldTipoDocumento = d.IdTipoDocumento,
      @OldActualizaCosto = ISNULL(t.ActualizaCosto, 0)
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

    -- Reversa CMP del detalle actual (si aplica)
    IF @OldTipoOp IN ('E', 'C') AND @OldActualizaCosto = 1
    BEGIN
      ;WITH DetAgg AS (
        SELECT
          det.IdProducto,
          SUM(det.Cantidad) AS Qty,
          SUM(det.Total) AS CostTotal
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = @IdDocumento
          AND det.RowStatus = 1
        GROUP BY det.IdProducto
      ),
      StockAgg AS (
        SELECT
          pa.IdProducto,
          SUM(pa.Cantidad) AS StockActual
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN DetAgg d ON d.IdProducto = pa.IdProducto
        WHERE pa.RowStatus = 1
        GROUP BY pa.IdProducto
      )
      UPDATE p
      SET
        p.CostoPromedio = CASE
          WHEN (sa.StockActual - d.Qty) > 0
            THEN ROUND(((ISNULL(p.CostoPromedio, 0) * sa.StockActual) - d.CostTotal) / (sa.StockActual - d.Qty), 4)
          ELSE ISNULL(p.CostoPromedio, 0)
        END,
        p.FechaModificacion = GETDATE(),
        p.UsuarioModificacion = @IdUsuario
      FROM dbo.Productos p
      INNER JOIN DetAgg d ON d.IdProducto = p.IdProducto
      INNER JOIN StockAgg sa ON sa.IdProducto = p.IdProducto;
    END

    -- Reversa stock del detalle actual
    IF @OldTipoOp IN ('E', 'C')
    BEGIN
      UPDATE pa
      SET
        pa.Cantidad = pa.Cantidad - det.Cantidad,
        pa.FechaModificacion = GETDATE(),
        pa.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes pa
      INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
      WHERE det.IdDocumento = @IdDocumento
        AND det.RowStatus = 1
        AND pa.IdAlmacen = @OldAlmacen
        AND pa.RowStatus = 1;
    END
    ELSE IF @OldTipoOp = 'S'
    BEGIN
      UPDATE pa
      SET
        pa.Cantidad = pa.Cantidad + det.Cantidad,
        pa.FechaModificacion = GETDATE(),
        pa.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes pa
      INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
      WHERE det.IdDocumento = @IdDocumento
        AND det.RowStatus = 1
        AND pa.IdAlmacen = @OldAlmacen
        AND pa.RowStatus = 1;
    END

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

    -- Reaplica stock con nuevo detalle
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

      UPDATE pa
      SET
        pa.Cantidad = pa.Cantidad + det.Cantidad,
        pa.FechaModificacion = GETDATE(),
        pa.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes pa
      INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
      WHERE det.IdDocumento = @IdDocumento
        AND det.RowStatus = 1
        AND pa.IdAlmacen = @IdAlmacen
        AND pa.RowStatus = 1;

      IF @NewActualizaCosto = 1
      BEGIN
        ;WITH DetAgg AS (
          SELECT
            det.IdProducto,
            SUM(det.Cantidad) AS Qty,
            SUM(det.Total) AS CostTotal
          FROM dbo.InvDocumentoDetalle det
          WHERE det.IdDocumento = @IdDocumento
            AND det.RowStatus = 1
          GROUP BY det.IdProducto
        ),
        StockAgg AS (
          SELECT
            pa.IdProducto,
            SUM(pa.Cantidad) AS StockActual
          FROM dbo.ProductoAlmacenes pa
          INNER JOIN DetAgg d ON d.IdProducto = pa.IdProducto
          WHERE pa.RowStatus = 1
          GROUP BY pa.IdProducto
        )
        UPDATE p
        SET
          p.CostoPromedio = CASE
            WHEN sa.StockActual > 0
              THEN ROUND(((ISNULL(p.CostoPromedio, 0) * (sa.StockActual - d.Qty)) + d.CostTotal) / sa.StockActual, 4)
            WHEN d.Qty > 0
              THEN ROUND(d.CostTotal / d.Qty, 4)
            ELSE ISNULL(p.CostoPromedio, 0)
          END,
          p.FechaModificacion = GETDATE(),
          p.UsuarioModificacion = @IdUsuario
        FROM dbo.Productos p
        INNER JOIN DetAgg d ON d.IdProducto = p.IdProducto
        INNER JOIN StockAgg sa ON sa.IdProducto = p.IdProducto;
      END
    END
    ELSE IF @OldTipoOp = 'S'
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM dbo.InvDocumentoDetalle det
        INNER JOIN dbo.Productos p ON p.IdProducto = det.IdProducto
        LEFT JOIN dbo.ProductoAlmacenes pa
          ON pa.IdProducto = det.IdProducto
         AND pa.IdAlmacen = @IdAlmacen
         AND pa.RowStatus = 1
        WHERE det.IdDocumento = @IdDocumento
          AND det.RowStatus = 1
          AND ISNULL(p.ManejaExistencia, 1) = 1
          AND ISNULL(p.VenderSinExistencia, 0) = 0
          AND ISNULL(pa.Cantidad, 0) < det.Cantidad
      )
      BEGIN
        THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
      END

      UPDATE pa
      SET
        pa.Cantidad = pa.Cantidad - det.Cantidad,
        pa.FechaModificacion = GETDATE(),
        pa.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes pa
      INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
      WHERE det.IdDocumento = @IdDocumento
        AND det.RowStatus = 1
        AND pa.IdAlmacen = @IdAlmacen
        AND pa.RowStatus = 1;
    END

    -- Actualiza total documento
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
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
GO

PRINT 'SP spInvActualizarDocumento creado correctamente.';
GO
