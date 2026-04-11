-- ============================================================
-- SP: spInvDocumentosCRUD
-- Acciones: L (listar), O (obtener), I (insertar), N (anular)
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.spInvDocumentosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spInvDocumentosCRUD;
GO

CREATE PROCEDURE dbo.spInvDocumentosCRUD
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
  @IdSesion            INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- ── L: Listar documentos ──────────────────────────────────
  IF @Accion = 'L'
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
    ORDER BY d.Fecha DESC, d.IdDocumento DESC;
    RETURN;
  END

  -- ── O: Obtener documento con detalle ──────────────────────
  IF @Accion = 'O'
  BEGIN
    -- Recordset 1: Cabecera
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

    -- Recordset 2: Detalle
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

      -- 1. Obtener info del tipo de documento y generar secuencia
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

      -- Construir numero de documento: PRE-0001
      SET @NumDoc = CASE
        WHEN @Prefijo <> '' THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4)
        ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4)
      END;

      -- Periodo desde la fecha
      DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112); -- YYYYMM

      -- Moneda: usar la del tipo si no se envio
      IF @IdMoneda IS NULL SET @IdMoneda = @TipoMoneda;

      -- 2. Insertar cabecera
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

      -- 3. Insertar detalle desde JSON
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

      -- 4. Calcular total del documento
      SELECT @TotalDoc = ISNULL(SUM(Total), 0)
      FROM dbo.InvDocumentoDetalle
      WHERE IdDocumento = @NewDocId AND RowStatus = 1;

      UPDATE dbo.InvDocumentos SET TotalDocumento = @TotalDoc WHERE IdDocumento = @NewDocId;

      -- 5. Actualizar stock en ProductoAlmacenes
      -- Para Entradas (E, C): sumar cantidad
      -- Para Salidas (S): restar cantidad
      IF @TipoOp IN ('E', 'C')
      BEGIN
        -- Insertar registros en ProductoAlmacenes si no existen
        INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
        SELECT DISTINCT det.IdProducto, @IdAlmacen, 0, @IdUsuario
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
          AND NOT EXISTS (
            SELECT 1 FROM dbo.ProductoAlmacenes pa
            WHERE pa.IdProducto = det.IdProducto AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1
          );

        -- Sumar cantidades
        UPDATE pa SET
          pa.Cantidad = pa.Cantidad + det.Cantidad,
          pa.FechaModificacion = GETDATE(),
          pa.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
          AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1;

        -- Actualizar costo promedio en Productos (promedio ponderado)
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
        -- Restar cantidades
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

      -- Retornar documento creado
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

      -- Reversar stock
      IF @DocTipoOp IN ('E', 'C')
      BEGIN
        -- Reversar entrada: restar
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
        -- Reversar salida: sumar
        UPDATE pa SET
          pa.Cantidad = pa.Cantidad + det.Cantidad,
          pa.FechaModificacion = GETDATE()
        FROM dbo.ProductoAlmacenes pa
        INNER JOIN dbo.InvDocumentoDetalle det ON det.IdProducto = pa.IdProducto
        WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
          AND pa.IdAlmacen = @DocAlmacen AND pa.RowStatus = 1;
      END

      -- Marcar como anulado
      UPDATE dbo.InvDocumentos SET
        Estado = 'N',
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario,
        IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      COMMIT TRANSACTION;

      -- Retornar documento actualizado
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

PRINT 'SP spInvDocumentosCRUD creado correctamente.';
GO

-- ============================================================
-- SP: spInvBuscarProducto
-- Busca producto por codigo exacto o por texto parcial
-- ============================================================

IF OBJECT_ID('dbo.spInvBuscarProducto', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spInvBuscarProducto;
GO

CREATE PROCEDURE dbo.spInvBuscarProducto
  @Modo       CHAR(1)       = 'E',  -- E=Exacto, P=Parcial
  @Busqueda   NVARCHAR(100) = NULL,
  @IdAlmacen  INT           = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- E: Busqueda exacta por codigo (escaner / Enter)
  IF @Modo = 'E'
  BEGIN
    SELECT TOP 1
      p.IdProducto,
      p.Codigo,
      p.Nombre,
      p.IdUnidadMedida,
      um.Nombre       AS NombreUnidad,
      um.Abreviatura   AS AbreviaturaUnidad,
      p.CostoPromedio,
      p.ManejaExistencia,
      ISNULL(pa.Cantidad, 0) AS Existencia
    FROM dbo.Productos p
    LEFT JOIN dbo.UnidadesMedida um ON um.IdUnidadMedida = p.IdUnidadMedida
    LEFT JOIN dbo.ProductoAlmacenes pa
      ON pa.IdProducto = p.IdProducto
      AND pa.IdAlmacen = @IdAlmacen
      AND pa.RowStatus = 1
    WHERE p.RowStatus = 1 AND p.Activo = 1
      AND p.Codigo = @Busqueda;
    RETURN;
  END

  -- P: Busqueda parcial (modal de busqueda)
  IF @Modo = 'P'
  BEGIN
    SELECT TOP 50
      p.IdProducto,
      p.Codigo,
      p.Nombre,
      p.IdUnidadMedida,
      um.Nombre       AS NombreUnidad,
      um.Abreviatura   AS AbreviaturaUnidad,
      p.CostoPromedio,
      p.ManejaExistencia,
      ISNULL(pa.Cantidad, 0) AS Existencia
    FROM dbo.Productos p
    LEFT JOIN dbo.UnidadesMedida um ON um.IdUnidadMedida = p.IdUnidadMedida
    LEFT JOIN dbo.ProductoAlmacenes pa
      ON pa.IdProducto = p.IdProducto
      AND pa.IdAlmacen = @IdAlmacen
      AND pa.RowStatus = 1
    WHERE p.RowStatus = 1 AND p.Activo = 1
      AND (
        p.Codigo LIKE '%' + @Busqueda + '%'
        OR p.Nombre LIKE '%' + @Busqueda + '%'
      )
    ORDER BY
      CASE WHEN p.Codigo = @Busqueda THEN 0 ELSE 1 END,
      p.Nombre;
    RETURN;
  END

END
GO

PRINT 'SP spInvBuscarProducto creado correctamente.';
GO

PRINT 'Script 53_sp_inv_documentos.sql ejecutado correctamente.';
GO
