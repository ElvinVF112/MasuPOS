SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
  115_seed_catalogo_pos_y_compras_compat.sql
  - Limpia el demo actual de categorias/productos/compras inventario
  - Inserta categorias y productos legibles para POS
  - Crea compras iniciales para probar Entradas por Compras
  - Compatible con el esquema actual de DbMasuPOS
*/

BEGIN TRY
  BEGIN TRANSACTION;

  DECLARE @UsuarioSistema INT = 1;
  DECLARE @Ahora DATETIME = GETDATE();
  DECLARE @Hoy DATE = CONVERT(date, GETDATE());
  DECLARE @IdUnidad INT;
  DECLARE @IdTipoProducto INT;
  DECLARE @IdMonedaDOP INT;
  DECLARE @IdAlmacenPrincipal INT;
  DECLARE @IdProveedor INT;
  DECLARE @IdTipoDocumentoCompra INT;
  DECLARE @PrefijoCompra VARCHAR(10);
  DECLARE @SecuenciaBase INT;

  SELECT TOP (1) @IdUnidad = U.IdUnidadMedida
  FROM dbo.UnidadesMedida U
  WHERE ISNULL(U.RowStatus, 1) = 1
  ORDER BY CASE WHEN U.Abreviatura IN ('UND','UNI') THEN 0 ELSE 1 END, U.IdUnidadMedida;

  IF @IdUnidad IS NULL
    THROW 51150, 'No se encontro una unidad de medida activa.', 1;

  SELECT TOP (1) @IdTipoProducto = TP.IdTipoProducto
  FROM dbo.TiposProducto TP
  WHERE ISNULL(TP.RowStatus, 1) = 1 AND ISNULL(TP.Activo, 1) = 1
  ORDER BY TP.IdTipoProducto;

  IF @IdTipoProducto IS NULL
    THROW 51151, 'No se encontro un tipo de producto activo.', 1;

  SELECT TOP (1) @IdMonedaDOP = M.IdMoneda
  FROM dbo.Monedas M
  WHERE ISNULL(M.RowStatus, 1) = 1 AND UPPER(LTRIM(RTRIM(M.Codigo))) = 'DOP'
  ORDER BY M.IdMoneda;

  IF @IdMonedaDOP IS NULL
    THROW 51152, 'No se encontro la moneda DOP.', 1;

  SELECT TOP (1) @IdAlmacenPrincipal = A.IdAlmacen
  FROM dbo.Almacenes A
  WHERE ISNULL(A.RowStatus, 1) = 1 AND ISNULL(A.Activo, 1) = 1 AND ISNULL(A.TipoAlmacen, '') <> 'T'
  ORDER BY CASE WHEN A.Siglas = 'PRI' THEN 0 ELSE 1 END, A.IdAlmacen;

  IF @IdAlmacenPrincipal IS NULL
    THROW 51153, 'No se encontro un almacen activo para compras.', 1;

  SELECT TOP (1) @IdProveedor = T.IdTercero
  FROM dbo.Terceros T
  WHERE ISNULL(T.RowStatus, 1) = 1 AND ISNULL(T.Activo, 1) = 1 AND ISNULL(T.EsProveedor, 0) = 1
  ORDER BY T.IdTercero;

  IF @IdProveedor IS NULL
    THROW 51154, 'No se encontro un proveedor activo.', 1;

  SELECT TOP (1)
    @IdTipoDocumentoCompra = TD.IdTipoDocumento,
    @PrefijoCompra = ISNULL(TD.Prefijo, 'COM'),
    @SecuenciaBase = ISNULL(TD.SecuenciaActual, 0)
  FROM dbo.InvTiposDocumento TD
  WHERE ISNULL(TD.RowStatus, 1) = 1 AND ISNULL(TD.Activo, 1) = 1 AND TD.TipoOperacion = 'C'
  ORDER BY TD.IdTipoDocumento;

  IF @IdTipoDocumentoCompra IS NULL
    THROW 51155, 'No se encontro un tipo de documento de compras activo.', 1;

  IF OBJECT_ID('dbo.InvDocumentoDetalle', 'U') IS NOT NULL DELETE FROM dbo.InvDocumentoDetalle;
  IF OBJECT_ID('dbo.InvMovimientos', 'U') IS NOT NULL DELETE FROM dbo.InvMovimientos;
  IF OBJECT_ID('dbo.InvDocumentos', 'U') IS NOT NULL DELETE FROM dbo.InvDocumentos;
  IF OBJECT_ID('dbo.ProductoAlmacenes', 'U') IS NOT NULL DELETE FROM dbo.ProductoAlmacenes;
  IF OBJECT_ID('dbo.Productos', 'U') IS NOT NULL DELETE FROM dbo.Productos;
  IF OBJECT_ID('dbo.Categorias', 'U') IS NOT NULL DELETE FROM dbo.Categorias;

  IF OBJECT_ID('dbo.InvDocumentoDetalle', 'U') IS NOT NULL DBCC CHECKIDENT ('dbo.InvDocumentoDetalle', RESEED, 0) WITH NO_INFOMSGS;
  IF OBJECT_ID('dbo.InvDocumentos', 'U') IS NOT NULL DBCC CHECKIDENT ('dbo.InvDocumentos', RESEED, 0) WITH NO_INFOMSGS;
  IF OBJECT_ID('dbo.ProductoAlmacenes', 'U') IS NOT NULL DBCC CHECKIDENT ('dbo.ProductoAlmacenes', RESEED, 0) WITH NO_INFOMSGS;
  IF OBJECT_ID('dbo.Productos', 'U') IS NOT NULL DBCC CHECKIDENT ('dbo.Productos', RESEED, 0) WITH NO_INFOMSGS;
  IF OBJECT_ID('dbo.Categorias', 'U') IS NOT NULL DBCC CHECKIDENT ('dbo.Categorias', RESEED, 0) WITH NO_INFOMSGS;

  SET IDENTITY_INSERT dbo.Categorias ON;
  INSERT INTO dbo.Categorias (
    IdCategoria, Nombre, Descripcion, Activo, FechaCreacion, RowStatus, UsuarioCreacion,
    ColorFondoItem, ColorBotonItem, ColorTextoItem
  ) VALUES
    (0, N'Sin Categoria', N'Productos sin categoria asignada', 1, @Ahora, 1, @UsuarioSistema, N'#E5E7EB', N'#9CA3AF', N'#111827');
  SET IDENTITY_INSERT dbo.Categorias OFF;

  INSERT INTO dbo.Categorias (
    Nombre, Descripcion, Activo, FechaCreacion, RowStatus, UsuarioCreacion,
    ColorFondoItem, ColorBotonItem, ColorTextoItem
  ) VALUES
    (N'Bebidas Frias', N'Agua, jugos y limonadas.', 1, @Ahora, 1, @UsuarioSistema, N'#DBEAFE', N'#0EA5E9', N'#0F172A'),
    (N'Bebidas Calientes', N'Cafe, te y chocolate.', 1, @Ahora, 1, @UsuarioSistema, N'#FFEDD5', N'#C2410C', N'#FFFFFF'),
    (N'Comida Rapida', N'Hamburguesas, wraps y sandwiches.', 1, @Ahora, 1, @UsuarioSistema, N'#FEE2E2', N'#DC2626', N'#FFFFFF'),
    (N'Postres', N'Dulces y reposteria.', 1, @Ahora, 1, @UsuarioSistema, N'#FCE7F3', N'#DB2777', N'#FFFFFF'),
    (N'Extras y Salsas', N'Complementos y extras.', 1, @Ahora, 1, @UsuarioSistema, N'#E2E8F0', N'#64748B', N'#0F172A');

  IF OBJECT_ID('tempdb..#CategoriasMap') IS NOT NULL DROP TABLE #CategoriasMap;
  CREATE TABLE #CategoriasMap (Nombre NVARCHAR(100) NOT NULL PRIMARY KEY, IdCategoria INT NOT NULL);
  INSERT INTO #CategoriasMap (Nombre, IdCategoria)
  SELECT Nombre, IdCategoria FROM dbo.Categorias WHERE RowStatus = 1;

  IF OBJECT_ID('tempdb..#ProductosSeed') IS NOT NULL DROP TABLE #ProductosSeed;
  CREATE TABLE #ProductosSeed (
    Categoria NVARCHAR(100) NOT NULL,
    Nombre NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(250) NULL,
    Precio DECIMAL(18,2) NOT NULL,
    Costo DECIMAL(18,2) NOT NULL
  );

  INSERT INTO #ProductosSeed (Categoria, Nombre, Descripcion, Precio, Costo) VALUES
    (N'Bebidas Frias', N'Agua 500ml', N'Botella de agua fria 500ml.', 60.00, 24.00),
    (N'Bebidas Frias', N'Agua con Gas', N'Botella de agua mineral con gas.', 75.00, 30.00),
    (N'Bebidas Frias', N'Refresco Cola', N'Refresco de cola 12 oz.', 95.00, 38.00),
    (N'Bebidas Frias', N'Limonada Clasica', N'Limonada natural con hielo.', 130.00, 46.00),
    (N'Bebidas Frias', N'Limonada Frozen', N'Limonada frappe.', 165.00, 62.00),
    (N'Bebidas Calientes', N'Cafe Espresso', N'Cafe espresso sencillo.', 95.00, 28.00),
    (N'Bebidas Calientes', N'Cafe Americano', N'Cafe americano 8 oz.', 105.00, 32.00),
    (N'Bebidas Calientes', N'Cafe con Leche', N'Cafe con leche espumada.', 135.00, 48.00),
    (N'Bebidas Calientes', N'Cappuccino', N'Cappuccino clasico.', 155.00, 55.00),
    (N'Bebidas Calientes', N'Te Verde', N'Te verde caliente.', 90.00, 24.00),
    (N'Bebidas Calientes', N'Chocolate Blanco', N'Bebida caliente de chocolate blanco.', 190.00, 74.00),
    (N'Comida Rapida', N'Hamburguesa Clasica', N'Hamburguesa de res con queso.', 320.00, 145.00),
    (N'Comida Rapida', N'Hamburguesa Bacon', N'Hamburguesa con bacon y cheddar.', 375.00, 170.00),
    (N'Comida Rapida', N'Sandwich Club', N'Sandwich club de pollo y bacon.', 290.00, 130.00),
    (N'Comida Rapida', N'Wrap de Pollo', N'Wrap de pollo a la plancha.', 285.00, 122.00),
    (N'Postres', N'Brownie con Helado', N'Brownie tibio con helado.', 225.00, 86.00),
    (N'Postres', N'Cheesecake Fresa', N'Cheesecake con topping de fresa.', 215.00, 82.00),
    (N'Postres', N'Flan de Caramelo', N'Flan cremoso casero.', 145.00, 52.00),
    (N'Extras y Salsas', N'Salsa Ketchup', N'Porcion de ketchup.', 25.00, 6.00),
    (N'Extras y Salsas', N'Queso Extra', N'Porcion de queso adicional.', 45.00, 18.00),
    (N'Extras y Salsas', N'Bacon Extra', N'Porcion de bacon adicional.', 65.00, 28.00);

  INSERT INTO dbo.Productos (
    IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio,
    Activo, FechaCreacion, RowStatus, UsuarioCreacion
  )
  SELECT
    CM.IdCategoria,
    @IdTipoProducto,
    @IdUnidad,
    P.Nombre,
    P.Descripcion,
    P.Precio,
    1,
    @Ahora,
    1,
    @UsuarioSistema
  FROM #ProductosSeed P
  INNER JOIN #CategoriasMap CM ON CM.Nombre = P.Categoria
  ORDER BY P.Categoria, P.Nombre;

  INSERT INTO dbo.ProductoAlmacenes (
    IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito,
    RowStatus, FechaCreacion, UsuarioCreacion
  )
  SELECT P.IdProducto, @IdAlmacenPrincipal, 0, 0, 0, 1, @Ahora, @UsuarioSistema
  FROM dbo.Productos P
  WHERE P.RowStatus = 1;

  IF OBJECT_ID('tempdb..#Compras') IS NOT NULL DROP TABLE #Compras;
  CREATE TABLE #Compras (
    Item INT IDENTITY(1,1) PRIMARY KEY,
    Referencia NVARCHAR(50) NOT NULL,
    Observacion NVARCHAR(250) NOT NULL,
    Fecha DATE NOT NULL,
    NoFactura NVARCHAR(50) NOT NULL,
    NCF NVARCHAR(50) NOT NULL
  );

  INSERT INTO #Compras (Referencia, Observacion, Fecha, NoFactura, NCF) VALUES
    (N'SEED-COMP-BEBIDAS', N'Compra demo de bebidas para pruebas POS.', DATEADD(DAY,-2,@Hoy), N'FC-0001', N'B0100000001'),
    (N'SEED-COMP-CALIENTES', N'Compra demo de cafe y bebidas calientes.', DATEADD(DAY,-1,@Hoy), N'FC-0002', N'B0100000002'),
    (N'SEED-COMP-COCINA', N'Compra demo de comida rapida, postres y extras.', @Hoy, N'FC-0003', N'B0100000003');

  IF OBJECT_ID('tempdb..#CompraLineas') IS NOT NULL DROP TABLE #CompraLineas;
  CREATE TABLE #CompraLineas (
    CompraItem INT NOT NULL,
    NumeroLinea INT NOT NULL,
    NombreProducto NVARCHAR(150) NOT NULL,
    Cantidad DECIMAL(18,4) NOT NULL,
    Costo DECIMAL(18,4) NOT NULL
  );

  INSERT INTO #CompraLineas (CompraItem, NumeroLinea, NombreProducto, Cantidad, Costo) VALUES
    (1, 1, N'Agua 500ml', 36, 24.00),
    (1, 2, N'Agua con Gas', 24, 30.00),
    (1, 3, N'Refresco Cola', 30, 38.00),
    (1, 4, N'Limonada Clasica', 18, 46.00),
    (1, 5, N'Limonada Frozen', 12, 62.00),
    (2, 1, N'Cafe Espresso', 40, 28.00),
    (2, 2, N'Cafe Americano', 32, 32.00),
    (2, 3, N'Cafe con Leche', 22, 48.00),
    (2, 4, N'Cappuccino', 20, 55.00),
    (2, 5, N'Te Verde', 18, 24.00),
    (2, 6, N'Chocolate Blanco', 12, 74.00),
    (3, 1, N'Hamburguesa Clasica', 10, 145.00),
    (3, 2, N'Wrap de Pollo', 12, 122.00),
    (3, 3, N'Brownie con Helado', 14, 86.00),
    (3, 4, N'Cheesecake Fresa', 10, 82.00),
    (3, 5, N'Salsa Ketchup', 40, 6.00),
    (3, 6, N'Queso Extra', 22, 18.00),
    (3, 7, N'Bacon Extra', 16, 28.00);

  DECLARE @CompraItem INT, @Fecha DATE, @Referencia NVARCHAR(50), @Observacion NVARCHAR(250), @NoFactura NVARCHAR(50), @NCF NVARCHAR(50);
  DECLARE @IdDocumento INT, @Secuencia INT, @NumeroDocumento VARCHAR(30), @Periodo VARCHAR(6);

  DECLARE c_comp CURSOR LOCAL FAST_FORWARD FOR
    SELECT Item, Fecha, Referencia, Observacion, NoFactura, NCF FROM #Compras ORDER BY Item;

  OPEN c_comp;
  FETCH NEXT FROM c_comp INTO @CompraItem, @Fecha, @Referencia, @Observacion, @NoFactura, @NCF;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @SecuenciaBase = ISNULL(@SecuenciaBase, 0) + 1;
    SET @Secuencia = @SecuenciaBase;
    SET @NumeroDocumento = CONCAT(@PrefijoCompra, '-', RIGHT('0000' + CAST(@Secuencia AS VARCHAR(10)), 4));
    SET @Periodo = CONVERT(VARCHAR(6), @Fecha, 112);

    INSERT INTO dbo.InvDocumentos (
      IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento, Fecha,
      IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion, TotalDocumento,
      Estado, RowStatus, FechaCreacion, UsuarioCreacion, IdSesionCreacion,
      IdProveedor, NoFactura, NCF, FechaFactura
    ) VALUES (
      @IdTipoDocumentoCompra, 'C', @Periodo, @Secuencia, @NumeroDocumento, @Fecha,
      @IdAlmacenPrincipal, @IdMonedaDOP, 1, @Referencia, @Observacion, 0,
      'A', 1, @Ahora, @UsuarioSistema, NULL,
      @IdProveedor, @NoFactura, @NCF, @Fecha
    );

    SET @IdDocumento = SCOPE_IDENTITY();

    INSERT INTO dbo.InvDocumentoDetalle (
      IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion, IdUnidadMedida,
      NombreUnidad, Cantidad, Costo, Total, RowStatus, FechaCreacion, UsuarioCreacion
    )
    SELECT
      @IdDocumento,
      L.NumeroLinea,
      P.IdProducto,
      CONCAT('P-', RIGHT('0000' + CAST(P.IdProducto AS VARCHAR(10)), 4)),
      P.Nombre,
      P.IdUnidadMedida,
      U.Abreviatura,
      L.Cantidad,
      L.Costo,
      ROUND(L.Cantidad * L.Costo, 4),
      1,
      @Ahora,
      @UsuarioSistema
    FROM #CompraLineas L
    INNER JOIN dbo.Productos P ON P.Nombre = L.NombreProducto AND P.RowStatus = 1
    INNER JOIN dbo.UnidadesMedida U ON U.IdUnidadMedida = P.IdUnidadMedida
    WHERE L.CompraItem = @CompraItem;

    UPDATE D
    SET D.TotalDocumento = X.TotalDoc
    FROM dbo.InvDocumentos D
    CROSS APPLY (
      SELECT ISNULL(SUM(DD.Total), 0) AS TotalDoc
      FROM dbo.InvDocumentoDetalle DD
      WHERE DD.IdDocumento = @IdDocumento AND DD.RowStatus = 1
    ) X
    WHERE D.IdDocumento = @IdDocumento;

    UPDATE PA
    SET
      PA.Cantidad = PA.Cantidad + L.Cantidad,
      PA.FechaModificacion = @Ahora,
      PA.UsuarioModificacion = @UsuarioSistema
    FROM dbo.ProductoAlmacenes PA
    INNER JOIN dbo.Productos P ON P.IdProducto = PA.IdProducto AND PA.IdAlmacen = @IdAlmacenPrincipal AND PA.RowStatus = 1
    INNER JOIN #CompraLineas L ON L.NombreProducto = P.Nombre AND L.CompraItem = @CompraItem;

    INSERT INTO dbo.InvMovimientos (
      IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen,
      NumeroDocumento, NumeroLinea, Cantidad, CostoUnitario, CostoTotal,
      SaldoAnterior, SaldoNuevo, CostoPromedioAnterior, CostoPromedioNuevo,
      Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion
    )
    SELECT
      P.IdProducto,
      @IdAlmacenPrincipal,
      'COM',
      1,
      @IdDocumento,
      'InvDocumento',
      @NumeroDocumento,
      L.NumeroLinea,
      L.Cantidad,
      L.Costo,
      ROUND(L.Cantidad * L.Costo, 4),
      0,
      L.Cantidad,
      L.Costo,
      L.Costo,
      @Fecha,
      @Periodo,
      CONCAT(N'Compra demo: ', @Referencia),
      1,
      @Ahora,
      @UsuarioSistema
    FROM #CompraLineas L
    INNER JOIN dbo.Productos P ON P.Nombre = L.NombreProducto AND P.RowStatus = 1
    WHERE L.CompraItem = @CompraItem;

    FETCH NEXT FROM c_comp INTO @CompraItem, @Fecha, @Referencia, @Observacion, @NoFactura, @NCF;
  END

  CLOSE c_comp;
  DEALLOCATE c_comp;

  UPDATE dbo.InvTiposDocumento
  SET SecuenciaActual = CASE WHEN ISNULL(SecuenciaActual, 0) < @SecuenciaBase THEN @SecuenciaBase ELSE SecuenciaActual END,
      FechaModificacion = @Ahora,
      UsuarioModificacion = @UsuarioSistema
  WHERE IdTipoDocumento = @IdTipoDocumentoCompra;

  COMMIT TRANSACTION;

  SELECT
    (SELECT COUNT(*) FROM dbo.Categorias WHERE RowStatus = 1 AND IdCategoria > 0) AS CategoriasCreadas,
    (SELECT COUNT(*) FROM dbo.Productos WHERE RowStatus = 1) AS ProductosCreados,
    (SELECT COUNT(*) FROM dbo.InvDocumentos WHERE RowStatus = 1 AND TipoOperacion = 'C') AS ComprasCreadas,
    (SELECT COUNT(*) FROM dbo.InvDocumentoDetalle WHERE RowStatus = 1) AS LineasCompra,
    (SELECT COUNT(*) FROM dbo.ProductoAlmacenes WHERE RowStatus = 1 AND Cantidad > 0) AS ProductosConExistencia;
END TRY
BEGIN CATCH
  IF CURSOR_STATUS('local', 'c_comp') >= -1
  BEGIN
    CLOSE c_comp;
    DEALLOCATE c_comp;
  END
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
GO
