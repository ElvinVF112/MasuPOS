USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 43.1.a) Columna ActualizaCosto en InvTiposDocumento
-- ============================================================
IF COL_LENGTH('dbo.InvTiposDocumento', 'ActualizaCosto') IS NULL
BEGIN
  ALTER TABLE dbo.InvTiposDocumento
    ADD ActualizaCosto BIT NOT NULL
      CONSTRAINT DF_InvTiposDocumento_ActualizaCosto DEFAULT (0);
END
GO

UPDATE dbo.InvTiposDocumento
SET ActualizaCosto = 1
WHERE TipoOperacion = 'C'
  AND RowStatus = 1;
GO

-- ============================================================
-- 43.1.b/c/d/e/f/g) Fixes en spInvDocumentosCRUD
-- ============================================================
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

  IF @Accion = 'I'
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @TipoOp CHAR(1), @Prefijo VARCHAR(10), @NuevaSecuencia INT, @NumDoc VARCHAR(30);
      DECLARE @TipoMoneda INT, @ActualizaCosto BIT;

      UPDATE dbo.InvTiposDocumento
        SET SecuenciaActual = SecuenciaActual + 1
      WHERE IdTipoDocumento = @IdTipoDocumento;

      SELECT
        @TipoOp = TipoOperacion,
        @Prefijo = ISNULL(Prefijo, ''),
        @NuevaSecuencia = SecuenciaActual,
        @TipoMoneda = IdMoneda,
        @ActualizaCosto = ISNULL(ActualizaCosto, 0)
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

        IF @ActualizaCosto = 1
        BEGIN
          ;WITH DetAgg AS (
            SELECT
              det.IdProducto,
              SUM(det.Cantidad) AS Qty,
              SUM(det.Total) AS CostTotal
            FROM dbo.InvDocumentoDetalle det
            WHERE det.IdDocumento = @NewDocId
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

      IF @TipoOp = 'S'
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM dbo.InvDocumentoDetalle det
          INNER JOIN dbo.Productos p ON p.IdProducto = det.IdProducto
          LEFT JOIN dbo.ProductoAlmacenes pa
            ON pa.IdProducto = det.IdProducto
           AND pa.IdAlmacen = @IdAlmacen
           AND pa.RowStatus = 1
          WHERE det.IdDocumento = @NewDocId
            AND det.RowStatus = 1
            AND ISNULL(p.ManejaExistencia, 1) = 1
            AND ISNULL(p.VenderSinExistencia, 0) = 0
            AND ISNULL(pa.Cantidad, 0) < det.Cantidad
        )
        BEGIN
          THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
        END

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

  IF @Accion = 'N'
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @DocTipoOp CHAR(1), @DocAlmacen INT, @ActualizaCostoOrig BIT;
      SELECT
        @DocTipoOp = d.TipoOperacion,
        @DocAlmacen = d.IdAlmacen,
        @ActualizaCostoOrig = ISNULL(t.ActualizaCosto, 0)
      FROM dbo.InvDocumentos d
      INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
      WHERE d.IdDocumento = @IdDocumento
        AND d.Estado = 'A';

      IF @DocTipoOp IS NULL
        THROW 50010, 'Documento no encontrado o ya anulado.', 1;

      IF @DocTipoOp IN ('E', 'C')
      BEGIN
        IF @ActualizaCostoOrig = 1
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

        UPDATE pa SET
          pa.Cantidad = pa.Cantidad - det.Cantidad,
          pa.FechaModificacion = GETDATE(),
          pa.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
          AND pa.IdAlmacen = @DocAlmacen AND pa.RowStatus = 1;
      END

      IF @DocTipoOp = 'S'
      BEGIN
        UPDATE pa SET
          pa.Cantidad = pa.Cantidad + det.Cantidad,
          pa.FechaModificacion = GETDATE(),
          pa.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
          AND pa.IdAlmacen = @DocAlmacen AND pa.RowStatus = 1;
      END

      UPDATE dbo.InvDocumentoDetalle
      SET RowStatus = 0
      WHERE IdDocumento = @IdDocumento
        AND RowStatus = 1;

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
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
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

-- ============================================================
-- 43.3) spInvTiposDocumentoCRUD con ActualizaCosto
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion              CHAR(2)        = 'L',
  @IdTipoDocumento     INT            = NULL,
  @TipoOperacion       CHAR(1)        = NULL,
  @Codigo              VARCHAR(10)    = NULL,
  @Descripcion         NVARCHAR(250)  = NULL,
  @Prefijo             VARCHAR(10)    = NULL,
  @SecuenciaInicial    INT            = 1,
  @ActualizaCosto      BIT            = 0,
  @IdMoneda            INT            = NULL,
  @Activo              BIT            = 1,
  @UsuarioCreacion     INT            = 1,
  @UsuarioModificacion INT            = NULL,
  @IdSesion            INT            = NULL,
  @TokenSesion         NVARCHAR(128)  = NULL,
  @UsuariosAsignados   NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

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
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
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
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
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
      SecuenciaInicial, SecuenciaActual, ActualizaCosto, IdMoneda, Activo,
      UsuarioCreacion, IdSesionCreacion
    )
    VALUES (
      @TipoOperacion, @Codigo, @Descripcion, @Prefijo,
      @SecuenciaInicial, 0,
      CASE WHEN @TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      @IdMoneda, @Activo,
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

    UPDATE dbo.InvTiposDocumento SET
      Codigo              = ISNULL(@Codigo, Codigo),
      Descripcion         = @Descripcion,
      Prefijo             = @Prefijo,
      SecuenciaInicial    = ISNULL(@SecuenciaInicial, SecuenciaInicial),
      ActualizaCosto      = CASE WHEN TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      IdMoneda            = @IdMoneda,
      Activo              = ISNULL(@Activo, Activo),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif       = @IdSesion
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

PRINT 'Script 57_inv_fix_cmp_actualiza_costo.sql ejecutado correctamente.';
GO
