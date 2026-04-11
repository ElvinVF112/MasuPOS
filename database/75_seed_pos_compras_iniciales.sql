SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
  Seed de compras iniciales POS
  - Crea compras reales via spInvDocumentosCRUD
  - Las compras quedan visibles en Entradas por Compras
  - Genera existencias iniciales para los 100 productos seed

  Requiere:
  - 74_seed_pos_categorias_productos.sql ya aplicado
  - Tipo documento de compras activo (TipoOperacion = 'C')
  - Un proveedor activo
*/

BEGIN TRY
  BEGIN TRANSACTION;

  DECLARE @UsuarioSistema INT = 1;
  DECLARE @IdTipoDocumentoCompra INT;
  DECLARE @IdAlmacenCompra INT;
  DECLARE @IdMoneda INT;
  DECLARE @IdProveedor INT;
  DECLARE @FechaBase DATE = CONVERT(date, GETDATE());

  SELECT TOP (1) @IdTipoDocumentoCompra = td.IdTipoDocumento
  FROM dbo.InvTiposDocumento td
  WHERE td.RowStatus = 1
    AND td.Activo = 1
    AND td.TipoOperacion = 'C'
  ORDER BY td.IdTipoDocumento;

  IF @IdTipoDocumentoCompra IS NULL
    THROW 50070, 'No existe un tipo de documento activo para compras.', 1;

  SELECT TOP (1) @IdAlmacenCompra = a.IdAlmacen
  FROM dbo.Almacenes a
  WHERE a.RowStatus = 1
    AND a.Activo = 1
    AND a.TipoAlmacen <> 'T'
  ORDER BY CASE WHEN a.Siglas = 'PRI' THEN 0 ELSE 1 END, a.IdAlmacen;

  IF @IdAlmacenCompra IS NULL
    THROW 50071, 'No existe un almacen activo para registrar compras.', 1;

  SELECT TOP (1) @IdMoneda = m.IdMoneda
  FROM dbo.Monedas m
  WHERE UPPER(LTRIM(RTRIM(m.Codigo))) = 'DOP'
  ORDER BY m.IdMoneda;

  IF @IdMoneda IS NULL
    THROW 50072, 'No existe la moneda DOP.', 1;

  SELECT TOP (1) @IdProveedor = t.IdTercero
  FROM dbo.Terceros t
  WHERE t.RowStatus = 1
    AND t.Activo = 1
    AND t.EsProveedor = 1
  ORDER BY t.IdTercero;

  IF @IdProveedor IS NULL
    THROW 50073, 'No existe un proveedor activo.', 1;

  DELETE FROM dbo.InvDocumentoDetalle
  WHERE IdDocumento IN (
    SELECT d.IdDocumento
    FROM dbo.InvDocumentos d
    WHERE d.RowStatus = 1
      AND d.TipoOperacion = 'C'
      AND d.Referencia LIKE 'SEED-COMP-%'
  );

  DELETE FROM dbo.InvMovimientos
  WHERE NumeroDocumento IN (
    SELECT d.NumeroDocumento
    FROM dbo.InvDocumentos d
    WHERE d.RowStatus = 1
      AND d.TipoOperacion = 'C'
      AND d.Referencia LIKE 'SEED-COMP-%'
  );

  DELETE FROM dbo.InvDocumentos
  WHERE RowStatus = 1
    AND TipoOperacion = 'C'
    AND Referencia LIKE 'SEED-COMP-%';

  UPDATE pa
  SET
    pa.Cantidad = 0,
    pa.CantidadReservada = 0,
    pa.CantidadTransito = 0,
    pa.FechaModificacion = GETDATE(),
    pa.UsuarioModificacion = @UsuarioSistema
  FROM dbo.ProductoAlmacenes pa
  INNER JOIN dbo.Productos p ON p.IdProducto = pa.IdProducto
  WHERE p.RowStatus = 1
    AND p.Codigo LIKE 'POS%';

  IF OBJECT_ID('tempdb..#CategoriasCompra') IS NOT NULL DROP TABLE #CategoriasCompra;
  CREATE TABLE #CategoriasCompra (
    Orden INT NOT NULL PRIMARY KEY,
    IdCategoria INT NOT NULL,
    CodigoCategoria NVARCHAR(20) NOT NULL,
    NombreCategoria NVARCHAR(100) NOT NULL
  );

  INSERT INTO #CategoriasCompra (Orden, IdCategoria, CodigoCategoria, NombreCategoria)
  SELECT
    ROW_NUMBER() OVER (ORDER BY c.Nombre) AS Orden,
    c.IdCategoria,
    ISNULL(c.Codigo, CONCAT('CAT-', c.IdCategoria)),
    c.Nombre
  FROM dbo.Categorias c
  WHERE c.RowStatus = 1
    AND c.Activo = 1
    AND c.Codigo LIKE 'CAT-%';

  DECLARE
    @Orden INT,
    @IdCategoria INT,
    @CodigoCategoria NVARCHAR(20),
    @NombreCategoria NVARCHAR(100),
    @FechaCompra DATE,
    @Referencia NVARCHAR(250),
    @Observacion NVARCHAR(500),
    @DetalleJSON NVARCHAR(MAX),
    @NoFactura NVARCHAR(50),
    @NCF NVARCHAR(50),
    @IdDocumento INT;

  DECLARE c_cat CURSOR LOCAL FAST_FORWARD FOR
  SELECT Orden, IdCategoria, CodigoCategoria, NombreCategoria
  FROM #CategoriasCompra
  ORDER BY Orden;

  OPEN c_cat;
  FETCH NEXT FROM c_cat INTO @Orden, @IdCategoria, @CodigoCategoria, @NombreCategoria;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @FechaCompra = DATEADD(DAY, -(@Orden - 1), @FechaBase);
    SET @Referencia = CONCAT('SEED-COMP-', @CodigoCategoria);
    SET @Observacion = CONCAT('Carga inicial POS por compras para categoria ', @NombreCategoria, '.');
    SET @NoFactura = CONCAT('F', RIGHT('0000' + CAST(@Orden AS VARCHAR(10)), 4), '-2026');
    SET @NCF = CONCAT('B0100000', RIGHT('00000000' + CAST(@Orden AS VARCHAR(10)), 8));

    SET @DetalleJSON = (
      SELECT
        ROW_NUMBER() OVER (ORDER BY p.IdProducto) AS linea,
        p.IdProducto AS idProducto,
        p.Codigo AS codigo,
        p.Nombre AS descripcion,
        COALESCE(p.IdUnidadCompra, p.IdUnidadVenta, p.IdUnidadMedida) AS idUnidadMedida,
        um.Abreviatura AS unidad,
        CAST((10 + (ROW_NUMBER() OVER (ORDER BY p.IdProducto) - 1) * 3) AS DECIMAL(18,4)) AS cantidad,
        CAST(
          CASE
            WHEN ISNULL(p.CostoProveedor, 0) > 0 THEN p.CostoProveedor
            WHEN ISNULL(p.CostoPromedio, 0) > 0 THEN p.CostoPromedio
            ELSE 25
          END
          AS DECIMAL(18,4)
        ) AS costo
      FROM dbo.Productos p
      INNER JOIN dbo.UnidadesMedida um
        ON um.IdUnidadMedida = COALESCE(p.IdUnidadCompra, p.IdUnidadVenta, p.IdUnidadMedida)
      WHERE p.RowStatus = 1
        AND p.Activo = 1
        AND p.IdCategoria = @IdCategoria
        AND p.Codigo LIKE 'POS%'
      ORDER BY p.IdProducto
      FOR JSON PATH
    );

    IF @DetalleJSON IS NULL OR @DetalleJSON = '[]'
      THROW 50074, 'No se encontraron productos seed para una categoria de compra.', 1;

    EXEC dbo.spInvDocumentosCRUD
      @Accion = 'I',
      @IdTipoDocumento = @IdTipoDocumentoCompra,
      @Fecha = @FechaCompra,
      @IdAlmacen = @IdAlmacenCompra,
      @IdMoneda = @IdMoneda,
      @TasaCambio = 1,
      @Referencia = @Referencia,
      @Observacion = @Observacion,
      @DetalleJSON = @DetalleJSON,
      @IdUsuario = @UsuarioSistema,
      @IdSesion = NULL;

    SELECT TOP (1) @IdDocumento = d.IdDocumento
    FROM dbo.InvDocumentos d
    WHERE d.RowStatus = 1
      AND d.TipoOperacion = 'C'
      AND d.Referencia = @Referencia
    ORDER BY d.IdDocumento DESC;

    IF @IdDocumento IS NULL
      THROW 50075, 'No se pudo recuperar el documento de compra creado.', 1;

    UPDATE dbo.InvDocumentos
    SET
      IdProveedor = @IdProveedor,
      NoFactura = @NoFactura,
      NCF = @NCF,
      FechaFactura = @FechaCompra
    WHERE IdDocumento = @IdDocumento;

    FETCH NEXT FROM c_cat INTO @Orden, @IdCategoria, @CodigoCategoria, @NombreCategoria;
  END

  CLOSE c_cat;
  DEALLOCATE c_cat;

  COMMIT TRANSACTION;

  SELECT
    (SELECT COUNT(*) FROM dbo.InvDocumentos WHERE RowStatus = 1 AND TipoOperacion = 'C' AND Referencia LIKE 'SEED-COMP-%') AS ComprasCreadas,
    (SELECT COUNT(*) FROM dbo.InvDocumentoDetalle det INNER JOIN dbo.InvDocumentos d ON d.IdDocumento = det.IdDocumento WHERE det.RowStatus = 1 AND d.RowStatus = 1 AND d.TipoOperacion = 'C' AND d.Referencia LIKE 'SEED-COMP-%') AS LineasCompras,
    (SELECT COUNT(*) FROM dbo.InvMovimientos WHERE TipoMovimiento = 'COM' AND NumeroDocumento IN (SELECT NumeroDocumento FROM dbo.InvDocumentos WHERE RowStatus = 1 AND TipoOperacion = 'C' AND Referencia LIKE 'SEED-COMP-%')) AS MovimientosCreados,
    (SELECT COUNT(*) FROM dbo.ProductoAlmacenes pa INNER JOIN dbo.Productos p ON p.IdProducto = pa.IdProducto WHERE pa.RowStatus = 1 AND p.RowStatus = 1 AND p.Codigo LIKE 'POS%' AND pa.Cantidad > 0) AS ProductosConExistencia;
END TRY
BEGIN CATCH
  IF CURSOR_STATUS('local', 'c_cat') >= -1
  BEGIN
    CLOSE c_cat;
    DEALLOCATE c_cat;
  END

  IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

  THROW;
END CATCH;
GO
