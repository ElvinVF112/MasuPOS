SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
  116_seed_catalogo_pos_100_y_compras_compat.sql
  - Restaura el catalogo demo amplio de POS
  - Inserta 10 categorias y 100 productos del seed historico bueno
  - Genera compras iniciales por categoria para probar entradas por compras
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

  SELECT TOP (1) @IdUnidad = U.IdUnidadMedida FROM dbo.UnidadesMedida U WHERE ISNULL(U.RowStatus, 1) = 1 ORDER BY CASE WHEN U.Abreviatura IN ('UND','UNI') THEN 0 ELSE 1 END, U.IdUnidadMedida;
  IF @IdUnidad IS NULL THROW 51600, 'No se encontro una unidad de medida activa.', 1;
  SELECT TOP (1) @IdTipoProducto = TP.IdTipoProducto FROM dbo.TiposProducto TP WHERE ISNULL(TP.RowStatus, 1) = 1 AND ISNULL(TP.Activo, 1) = 1 ORDER BY TP.IdTipoProducto;
  IF @IdTipoProducto IS NULL THROW 51601, 'No se encontro un tipo de producto activo.', 1;
  SELECT TOP (1) @IdMonedaDOP = M.IdMoneda FROM dbo.Monedas M WHERE ISNULL(M.RowStatus, 1) = 1 AND UPPER(LTRIM(RTRIM(M.Codigo))) = 'DOP' ORDER BY M.IdMoneda;
  IF @IdMonedaDOP IS NULL THROW 51602, 'No se encontro la moneda DOP.', 1;
  SELECT TOP (1) @IdAlmacenPrincipal = A.IdAlmacen FROM dbo.Almacenes A WHERE ISNULL(A.RowStatus, 1) = 1 AND ISNULL(A.Activo, 1) = 1 AND ISNULL(A.TipoAlmacen, '') <> 'T' ORDER BY CASE WHEN A.Siglas = 'PRI' THEN 0 ELSE 1 END, A.IdAlmacen;
  IF @IdAlmacenPrincipal IS NULL THROW 51603, 'No se encontro un almacen activo para compras.', 1;
  SELECT TOP (1) @IdProveedor = T.IdTercero FROM dbo.Terceros T WHERE ISNULL(T.RowStatus, 1) = 1 AND ISNULL(T.Activo, 1) = 1 AND ISNULL(T.EsProveedor, 0) = 1 ORDER BY T.IdTercero;
  IF @IdProveedor IS NULL THROW 51604, 'No se encontro un proveedor activo.', 1;
  SELECT TOP (1) @IdTipoDocumentoCompra = TD.IdTipoDocumento, @PrefijoCompra = ISNULL(TD.Prefijo, 'COM'), @SecuenciaBase = ISNULL(TD.SecuenciaActual, 0) FROM dbo.InvTiposDocumento TD WHERE ISNULL(TD.RowStatus, 1) = 1 AND ISNULL(TD.Activo, 1) = 1 AND TD.TipoOperacion = 'C' ORDER BY TD.IdTipoDocumento;
  IF @IdTipoDocumentoCompra IS NULL THROW 51605, 'No se encontro un tipo de documento de compras activo.', 1;

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
  INSERT INTO dbo.Categorias (IdCategoria, Nombre, Descripcion, Activo, FechaCreacion, RowStatus, UsuarioCreacion, ColorFondoItem, ColorBotonItem, ColorTextoItem)
  VALUES (0, N'Sin Categoria', N'Productos sin categoria asignada', 1, @Ahora, 1, @UsuarioSistema, N'#E5E7EB', N'#9CA3AF', N'#111827');
  SET IDENTITY_INSERT dbo.Categorias OFF;

  IF OBJECT_ID('tempdb..#CategoriasSeed') IS NOT NULL DROP TABLE #CategoriasSeed;
  CREATE TABLE #CategoriasSeed (Codigo NVARCHAR(20) NOT NULL PRIMARY KEY, Nombre NVARCHAR(100) NOT NULL, Descripcion NVARCHAR(200) NULL, ColorFondo NVARCHAR(7) NOT NULL, ColorBoton NVARCHAR(7) NOT NULL, ColorTexto NVARCHAR(7) NOT NULL);

  INSERT INTO #CategoriasSeed (Codigo, Nombre, Descripcion, ColorFondo, ColorBoton, ColorTexto) VALUES
    ('CAT-BFRIAS', 'Bebidas Frias', 'Jugos, refrescos y bebidas frias.', '#EAF6FF', '#B9E3FF', '#16324F'),
    ('CAT-BCAL', 'Bebidas Calientes', 'Cafe, te y bebidas calientes.', '#FFF3E6', '#FFD8B5', '#5A3418'),
    ('CAT-CERV', 'Cervezas', 'Cervezas nacionales e importadas.', '#FFF8D9', '#F7E7A8', '#5B4A12'),
    ('CAT-COCT', 'Cocteles', 'Cocteles clasicos y frozen.', '#FBEAFE', '#E8C4F6', '#5B2A68'),
    ('CAT-RAP', 'Comida Rapida', 'Hamburguesas, pizzas y sandwiches.', '#FFE7E2', '#FFC6BC', '#6A2E24'),
    ('CAT-PIC', 'Picaderas', 'Entradas para compartir.', '#FFEAF1', '#FFC8D8', '#6B2941'),
    ('CAT-PLT', 'Platos Fuertes', 'Platos principales del menu.', '#EAF8EF', '#BEE7C8', '#214E34'),
    ('CAT-PST', 'Postres', 'Dulces y postres frios.', '#FFF5EA', '#FFD9B8', '#6A4320'),
    ('CAT-CMB', 'Combos', 'Combos de comida y bebida.', '#EEF0FF', '#C9D2FF', '#28356B'),
    ('CAT-EXT', 'Extras y Salsas', 'Acompanantes, toppings y salsas.', '#EEF3F7', '#D2DCE5', '#334155') ;

  INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion, RowStatus, UsuarioCreacion, ColorFondoItem, ColorBotonItem, ColorTextoItem)
  SELECT Nombre, Descripcion, 1, @Ahora, 1, @UsuarioSistema, ColorFondo, ColorBoton, ColorTexto FROM #CategoriasSeed ORDER BY Codigo;

  IF OBJECT_ID('tempdb..#CategoriasMap') IS NOT NULL DROP TABLE #CategoriasMap;
  CREATE TABLE #CategoriasMap (Codigo NVARCHAR(20) NOT NULL PRIMARY KEY, IdCategoria INT NOT NULL, Nombre NVARCHAR(100) NOT NULL);
  INSERT INTO #CategoriasMap (Codigo, IdCategoria, Nombre)
  SELECT S.Codigo, C.IdCategoria, C.Nombre FROM #CategoriasSeed S INNER JOIN dbo.Categorias C ON C.Nombre = S.Nombre AND C.RowStatus = 1;

  IF OBJECT_ID('tempdb..#ProductosSeed') IS NOT NULL DROP TABLE #ProductosSeed;
  CREATE TABLE #ProductosSeed (CategoriaCodigo NVARCHAR(20) NOT NULL, Codigo NVARCHAR(20) NOT NULL PRIMARY KEY, Nombre NVARCHAR(150) NOT NULL, Descripcion NVARCHAR(250) NULL, Comentario NVARCHAR(250) NULL, Precio DECIMAL(18,2) NOT NULL, Costo DECIMAL(18,2) NOT NULL);

  INSERT INTO #ProductosSeed (CategoriaCodigo, Codigo, Nombre, Descripcion, Comentario, Precio, Costo) VALUES
    ('CAT-BFRIAS', 'POS001', 'Agua 500ml', 'Botella de agua fria de 500ml.', 'Ideal para takeaway.', 60.00, 25.00),
    ('CAT-BFRIAS', 'POS002', 'Agua con Gas', 'Botella de agua mineral con gas.', 'Servir bien fria.', 75.00, 32.00),
    ('CAT-BFRIAS', 'POS003', 'Refresco Cola', 'Refresco de cola 12 oz.', 'Presentacion individual.', 95.00, 38.00),
    ('CAT-BFRIAS', 'POS004', 'Refresco Limon', 'Refresco sabor limon 12 oz.', 'Presentacion individual.', 95.00, 38.00),
    ('CAT-BFRIAS', 'POS005', 'Jugo de Naranja', 'Jugo natural de naranja.', 'Preparacion fresca.', 145.00, 58.00),
    ('CAT-BFRIAS', 'POS006', 'Jugo de Chinola', 'Jugo natural de chinola.', 'Preparacion fresca.', 145.00, 58.00),
    ('CAT-BFRIAS', 'POS007', 'Limonada Clasica', 'Limonada natural con hielo.', 'Vaso 16 oz.', 130.00, 45.00),
    ('CAT-BFRIAS', 'POS008', 'Limonada Frozen', 'Limonada frappe.', 'Textura frozen.', 165.00, 62.00),
    ('CAT-BFRIAS', 'POS009', 'Te Frio Limon', 'Te frio sabor limon.', 'Vaso 16 oz.', 110.00, 42.00),
    ('CAT-BFRIAS', 'POS010', 'Malteada Vainilla', 'Malteada cremosa de vainilla.', 'Servir con topping.', 210.00, 85.00),
    ('CAT-BCAL', 'POS011', 'Cafe Espresso', 'Cafe espresso sencillo.', 'Taza pequena.', 95.00, 28.00),
    ('CAT-BCAL', 'POS012', 'Cafe Americano', 'Cafe americano 8 oz.', 'Intensidad media.', 105.00, 32.00),
    ('CAT-BCAL', 'POS013', 'Cafe con Leche', 'Cafe con leche espumada.', 'Vaso 10 oz.', 135.00, 48.00),
    ('CAT-BCAL', 'POS014', 'Cappuccino', 'Cappuccino clasico.', 'Con espuma cremosa.', 155.00, 55.00),
    ('CAT-BCAL', 'POS015', 'Latte Vainilla', 'Latte con toque de vainilla.', 'Vaso 12 oz.', 175.00, 66.00),
    ('CAT-BCAL', 'POS016', 'Chocolate Caliente', 'Chocolate caliente cremoso.', 'Vaso 12 oz.', 165.00, 63.00),
    ('CAT-BCAL', 'POS017', 'Te Verde', 'Te verde caliente.', 'Taza individual.', 90.00, 24.00),
    ('CAT-BCAL', 'POS018', 'Te Manzanilla', 'Infusion de manzanilla.', 'Taza individual.', 90.00, 24.00),
    ('CAT-BCAL', 'POS019', 'Mocaccino', 'Cafe moka con chocolate.', 'Vaso 12 oz.', 185.00, 72.00),
    ('CAT-BCAL', 'POS020', 'Chocolate Blanco', 'Bebida caliente de chocolate blanco.', 'Vaso 12 oz.', 190.00, 74.00),
    ('CAT-CERV', 'POS021', 'Cerveza Nacional Small', 'Cerveza nacional pequena.', 'Servir bien fria.', 140.00, 60.00),
    ('CAT-CERV', 'POS022', 'Cerveza Nacional Large', 'Cerveza nacional grande.', 'Servir bien fria.', 220.00, 96.00),
    ('CAT-CERV', 'POS023', 'Cerveza Light', 'Cerveza ligera.', 'Presentacion regular.', 150.00, 64.00),
    ('CAT-CERV', 'POS024', 'Cerveza Negra', 'Cerveza oscura.', 'Botella individual.', 170.00, 72.00),
    ('CAT-CERV', 'POS025', 'Cerveza Importada', 'Cerveza importada premium.', 'Botella individual.', 260.00, 125.00),
    ('CAT-CERV', 'POS026', 'Cubeta 4 Cervezas', 'Cubeta de 4 cervezas nacionales.', 'Incluye hielo.', 520.00, 240.00),
    ('CAT-CERV', 'POS027', 'Cubeta 6 Cervezas', 'Cubeta de 6 cervezas nacionales.', 'Incluye hielo.', 760.00, 348.00),
    ('CAT-CERV', 'POS028', 'Michelada Clasica', 'Cerveza preparada estilo michelada.', 'Vaso escarchado.', 245.00, 105.00),
    ('CAT-CERV', 'POS029', 'Radler Limon', 'Cerveza con limon ligera.', 'Muy refrescante.', 185.00, 78.00),
    ('CAT-CERV', 'POS030', 'Cerveza Artesanal', 'Cerveza artesanal rotativa.', 'Consultar disponibilidad.', 310.00, 145.00),
    ('CAT-COCT', 'POS031', 'Mojito Clasico', 'Ron, hierbabuena y limon.', 'Coctel clasico.', 295.00, 128.00),
    ('CAT-COCT', 'POS032', 'Margarita Limon', 'Tequila y limon.', 'Copa escarchada.', 320.00, 140.00),
    ('CAT-COCT', 'POS033', 'Pina Colada', 'Ron, pina y coco.', 'Version frozen.', 310.00, 136.00),
    ('CAT-COCT', 'POS034', 'Sangria Copa', 'Copa de sangria.', 'Preparacion de la casa.', 240.00, 102.00),
    ('CAT-COCT', 'POS035', 'Cuba Libre', 'Ron con cola y limon.', 'Vaso highball.', 255.00, 110.00),
    ('CAT-COCT', 'POS036', 'Daiquiri Fresa', 'Daiquiri frozen de fresa.', 'Presentacion frozen.', 330.00, 145.00),
    ('CAT-COCT', 'POS037', 'Whisky Sour', 'Whisky con mix citrico.', 'Coctel clasico.', 345.00, 150.00),
    ('CAT-COCT', 'POS038', 'Gin Tonic', 'Gin con agua tonica.', 'Copa grande.', 360.00, 158.00),
    ('CAT-COCT', 'POS039', 'Aperol Spritz', 'Aperitivo con espumante.', 'Copa de vino.', 395.00, 176.00),
    ('CAT-COCT', 'POS040', 'Moscow Mule', 'Vodka, ginger beer y limon.', 'Servido en mug.', 365.00, 160.00),
    ('CAT-RAP', 'POS041', 'Hamburguesa Clasica', 'Hamburguesa de res con queso.', 'Incluye papas.', 320.00, 145.00),
    ('CAT-RAP', 'POS042', 'Hamburguesa Bacon', 'Hamburguesa con bacon y cheddar.', 'Incluye papas.', 375.00, 170.00),
    ('CAT-RAP', 'POS043', 'Cheeseburger Doble', 'Hamburguesa doble carne.', 'Incluye papas.', 435.00, 205.00),
    ('CAT-RAP', 'POS044', 'Hot Dog Clasico', 'Pan, salchicha y toppings.', 'Presentacion individual.', 180.00, 75.00),
    ('CAT-RAP', 'POS045', 'Sandwich Club', 'Sandwich club de pollo y bacon.', 'Corte triangular.', 290.00, 130.00),
    ('CAT-RAP', 'POS046', 'Wrap de Pollo', 'Wrap de pollo a la plancha.', 'Con papas o ensalada.', 285.00, 122.00),
    ('CAT-RAP', 'POS047', 'Pizza Personal Pepperoni', 'Pizza personal de pepperoni.', '8 pulgadas.', 350.00, 155.00),
    ('CAT-RAP', 'POS048', 'Pizza Personal Queso', 'Pizza personal de queso.', '8 pulgadas.', 330.00, 145.00),
    ('CAT-RAP', 'POS049', 'Quesadilla de Pollo', 'Tortilla rellena de pollo y queso.', 'Con salsa.', 295.00, 128.00),
    ('CAT-RAP', 'POS050', 'Tacos de Res', 'Tres tacos de res sazonada.', 'Incluye pico de gallo.', 310.00, 135.00),
    ('CAT-PIC', 'POS051', 'Papas Fritas', 'Papas fritas crujientes.', 'Porcion regular.', 145.00, 52.00),
    ('CAT-PIC', 'POS052', 'Papas Gajo', 'Papas gajo sazonadas.', 'Porcion regular.', 165.00, 60.00),
    ('CAT-PIC', 'POS053', 'Aros de Cebolla', 'Aros de cebolla empanizados.', 'Porcion regular.', 185.00, 70.00),
    ('CAT-PIC', 'POS054', 'Mozzarella Sticks', 'Dedos de mozzarella.', '6 unidades.', 235.00, 96.00),
    ('CAT-PIC', 'POS055', 'Alitas BBQ 6u', 'Seis alitas en salsa BBQ.', 'Incluye dip.', 285.00, 122.00),
    ('CAT-PIC', 'POS056', 'Alitas Picantes 6u', 'Seis alitas picantes.', 'Incluye dip.', 285.00, 122.00),
    ('CAT-PIC', 'POS057', 'Nachos Supremos', 'Nachos con carne, queso y jalapenos.', 'Perfectos para compartir.', 330.00, 148.00),
    ('CAT-PIC', 'POS058', 'Croquetas de Pollo', 'Croquetas de pollo crujientes.', '8 unidades.', 215.00, 88.00),
    ('CAT-PIC', 'POS059', 'Yuca Frita', 'Yuca frita con salsa rosada.', 'Porcion regular.', 155.00, 58.00),
    ('CAT-PIC', 'POS060', 'Picadera Mixta Small', 'Picadera mixta pequena.', 'Para 2 personas.', 520.00, 245.00),
    ('CAT-PLT', 'POS061', 'Pollo a la Plancha', 'Pechuga a la plancha con guarnicion.', 'Incluye acompanante.', 360.00, 165.00),
    ('CAT-PLT', 'POS062', 'Pechurina con Papas', 'Tiras de pollo empanizadas.', 'Incluye papas fritas.', 340.00, 152.00),
    ('CAT-PLT', 'POS063', 'Churrasco 10oz', 'Churrasco a la parrilla.', 'Incluye acompanante.', 845.00, 425.00),
    ('CAT-PLT', 'POS064', 'Pasta Alfredo Pollo', 'Pasta en salsa alfredo con pollo.', 'Plato completo.', 425.00, 188.00),
    ('CAT-PLT', 'POS065', 'Pasta Bolognesa', 'Pasta con salsa de carne.', 'Plato completo.', 395.00, 176.00),
    ('CAT-PLT', 'POS066', 'Mofongo de Pollo', 'Mofongo relleno de pollo.', 'Salsa criolla.', 410.00, 182.00),
    ('CAT-PLT', 'POS067', 'Mofongo de Camaron', 'Mofongo relleno de camarones.', 'Salsa criolla.', 520.00, 245.00),
    ('CAT-PLT', 'POS068', 'Arroz con Camarones', 'Arroz cremoso con camarones.', 'Plato principal.', 495.00, 228.00),
    ('CAT-PLT', 'POS069', 'Filete de Pescado', 'Filete de pescado a la plancha.', 'Incluye acompanante.', 465.00, 215.00),
    ('CAT-PLT', 'POS070', 'Costillas BBQ', 'Costillas en salsa BBQ.', 'Incluye papas wedges.', 585.00, 278.00),
    ('CAT-PST', 'POS071', 'Brownie con Helado', 'Brownie tibio con helado.', 'Postre estrella.', 225.00, 86.00),
    ('CAT-PST', 'POS072', 'Cheesecake Fresa', 'Cheesecake con topping de fresa.', 'Porcion individual.', 215.00, 82.00),
    ('CAT-PST', 'POS073', 'Flan de Caramelo', 'Flan cremoso casero.', 'Porcion individual.', 145.00, 52.00),
    ('CAT-PST', 'POS074', 'Tres Leches', 'Bizcocho tres leches.', 'Porcion individual.', 175.00, 64.00),
    ('CAT-PST', 'POS075', 'Helado Vainilla', 'Copa de helado vainilla.', '2 bolas.', 110.00, 36.00),
    ('CAT-PST', 'POS076', 'Helado Chocolate', 'Copa de helado chocolate.', '2 bolas.', 110.00, 36.00),
    ('CAT-PST', 'POS077', 'Churros con Azucar', 'Churros recien hechos.', 'Con dip aparte.', 160.00, 58.00),
    ('CAT-PST', 'POS078', 'Tarta de Manzana', 'Tarta de manzana horneada.', 'Porcion individual.', 190.00, 74.00),
    ('CAT-PST', 'POS079', 'Volcan de Chocolate', 'Volcan tibio de chocolate.', 'Con helado.', 245.00, 95.00),
    ('CAT-PST', 'POS080', 'Banana Split', 'Helado con banana y toppings.', 'Postre grande.', 230.00, 90.00),
    ('CAT-CMB', 'POS081', 'Combo Burger + Refresco', 'Hamburguesa clasica con refresco.', 'Combo de alta rotacion.', 395.00, 178.00),
    ('CAT-CMB', 'POS082', 'Combo Bacon + Papas + Refresco', 'Burger bacon con papas y refresco.', 'Combo premium.', 485.00, 224.00),
    ('CAT-CMB', 'POS083', 'Combo Hot Dog + Refresco', 'Hot dog con refresco.', 'Combo rapido.', 245.00, 106.00),
    ('CAT-CMB', 'POS084', 'Combo Wrap + Jugo', 'Wrap de pollo con jugo natural.', 'Combo saludable.', 395.00, 176.00),
    ('CAT-CMB', 'POS085', 'Combo Pizza Personal + Refresco', 'Pizza personal con bebida.', 'Combo individual.', 430.00, 192.00),
    ('CAT-CMB', 'POS086', 'Combo Quesadilla + Refresco', 'Quesadilla con refresco.', 'Combo individual.', 385.00, 170.00),
    ('CAT-CMB', 'POS087', 'Combo Tacos + Refresco', 'Tres tacos con refresco.', 'Combo individual.', 405.00, 182.00),
    ('CAT-CMB', 'POS088', 'Combo Alitas + Cerveza', 'Alitas con cerveza nacional.', 'Ideal para sports bar.', 425.00, 188.00),
    ('CAT-CMB', 'POS089', 'Combo Cafe + Brownie', 'Cafe americano y brownie.', 'Combo merienda.', 260.00, 98.00),
    ('CAT-CMB', 'POS090', 'Combo Ninos', 'Mini burger, papas y jugo.', 'Combo infantil.', 290.00, 124.00),
    ('CAT-EXT', 'POS091', 'Salsa Ketchup', 'Porcion de ketchup.', 'Extra individual.', 25.00, 6.00),
    ('CAT-EXT', 'POS092', 'Salsa Rosada', 'Porcion de salsa rosada.', 'Extra individual.', 30.00, 8.00),
    ('CAT-EXT', 'POS093', 'Salsa BBQ', 'Porcion de salsa BBQ.', 'Extra individual.', 35.00, 10.00),
    ('CAT-EXT', 'POS094', 'Mayonesa de Ajo', 'Porcion de mayonesa de ajo.', 'Extra individual.', 35.00, 10.00),
    ('CAT-EXT', 'POS095', 'Queso Extra', 'Porcion de queso adicional.', 'Topping adicional.', 45.00, 18.00),
    ('CAT-EXT', 'POS096', 'Bacon Extra', 'Porcion de bacon adicional.', 'Topping adicional.', 65.00, 28.00),
    ('CAT-EXT', 'POS097', 'Papas Extra', 'Porcion adicional de papas.', 'Acompanante extra.', 95.00, 36.00),
    ('CAT-EXT', 'POS098', 'Hielo Extra', 'Vaso de hielo.', 'Extra de bar.', 20.00, 4.00),
    ('CAT-EXT', 'POS099', 'Limon Extra', 'Porcion de limon.', 'Extra de bar.', 20.00, 5.00),
    ('CAT-EXT', 'POS100', 'Pan Extra', 'Pan adicional.', 'Acompanante extra.', 30.00, 9.00) ;

  INSERT INTO dbo.Productos (IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  SELECT CM.IdCategoria, @IdTipoProducto, @IdUnidad, P.Nombre, P.Descripcion, P.Precio, 1, @Ahora, 1, @UsuarioSistema
  FROM #ProductosSeed P
  INNER JOIN #CategoriasMap CM ON CM.Codigo = P.CategoriaCodigo
  ORDER BY P.Codigo;

  INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdProducto, @IdAlmacenPrincipal, 0, 0, 0, 1, @Ahora, @UsuarioSistema FROM dbo.Productos P WHERE P.RowStatus = 1;

  IF OBJECT_ID('tempdb..#Compras') IS NOT NULL DROP TABLE #Compras;
  CREATE TABLE #Compras (CompraItem INT IDENTITY(1,1) PRIMARY KEY, CategoriaCodigo NVARCHAR(20) NOT NULL, Referencia NVARCHAR(50) NOT NULL, Observacion NVARCHAR(250) NOT NULL, Fecha DATE NOT NULL, NoFactura NVARCHAR(50) NOT NULL, NCF NVARCHAR(50) NOT NULL);

  INSERT INTO #Compras (CategoriaCodigo, Referencia, Observacion, Fecha, NoFactura, NCF)
  SELECT S.Codigo, CONCAT('SEED-', RIGHT(S.Codigo, 3)), CONCAT('Compra demo de ', S.Nombre, ' para pruebas POS.'), DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY S.Codigo), @Hoy), CONCAT('FC-', RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY S.Codigo) AS VARCHAR(10)), 4)), CONCAT('B010000', RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY S.Codigo) AS VARCHAR(10)), 4)) FROM #CategoriasSeed S ORDER BY S.Codigo;

  IF OBJECT_ID('tempdb..#CompraLineas') IS NOT NULL DROP TABLE #CompraLineas;
  CREATE TABLE #CompraLineas (CompraItem INT NOT NULL, NumeroLinea INT NOT NULL, NombreProducto NVARCHAR(150) NOT NULL, Cantidad DECIMAL(18,4) NOT NULL, Costo DECIMAL(18,4) NOT NULL);

  INSERT INTO #CompraLineas (CompraItem, NumeroLinea, NombreProducto, Cantidad, Costo)
  SELECT C.CompraItem, ROW_NUMBER() OVER (PARTITION BY C.CompraItem ORDER BY P.Codigo), P.Nombre,
         CAST(CASE WHEN C.CompraItem IN (1,2,3,4) THEN 24 WHEN C.CompraItem IN (5,6) THEN 18 WHEN C.CompraItem IN (7,8) THEN 14 WHEN C.CompraItem = 9 THEN 12 ELSE 30 END AS DECIMAL(18,4)) AS Cantidad,
         P.Costo
  FROM #Compras C
  INNER JOIN #ProductosSeed P ON P.CategoriaCodigo = C.CategoriaCodigo;

  DECLARE @CompraItem INT, @Fecha DATE, @Referencia NVARCHAR(50), @Observacion NVARCHAR(250), @NoFactura NVARCHAR(50), @NCF NVARCHAR(50);
  DECLARE @IdDocumento INT, @Secuencia INT, @NumeroDocumento VARCHAR(30), @Periodo VARCHAR(6);

  DECLARE c_comp CURSOR LOCAL FAST_FORWARD FOR SELECT CompraItem, Fecha, Referencia, Observacion, NoFactura, NCF FROM #Compras ORDER BY CompraItem;
  OPEN c_comp;
  FETCH NEXT FROM c_comp INTO @CompraItem, @Fecha, @Referencia, @Observacion, @NoFactura, @NCF;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @SecuenciaBase = ISNULL(@SecuenciaBase, 0) + 1;
    SET @Secuencia = @SecuenciaBase;
    SET @NumeroDocumento = CONCAT(@PrefijoCompra, '-', RIGHT('0000' + CAST(@Secuencia AS VARCHAR(10)), 4));
    SET @Periodo = CONVERT(VARCHAR(6), @Fecha, 112);
    INSERT INTO dbo.InvDocumentos (IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento, Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion, TotalDocumento, Estado, RowStatus, FechaCreacion, UsuarioCreacion, IdSesionCreacion, IdProveedor, NoFactura, NCF, FechaFactura)
    VALUES (@IdTipoDocumentoCompra, 'C', @Periodo, @Secuencia, @NumeroDocumento, @Fecha, @IdAlmacenPrincipal, @IdMonedaDOP, 1, @Referencia, @Observacion, 0, 'A', 1, @Ahora, @UsuarioSistema, NULL, @IdProveedor, @NoFactura, @NCF, @Fecha);
    SET @IdDocumento = SCOPE_IDENTITY();
    INSERT INTO dbo.InvDocumentoDetalle (IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion, IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, RowStatus, FechaCreacion, UsuarioCreacion)
    SELECT @IdDocumento, L.NumeroLinea, P.IdProducto, CONCAT('P-', RIGHT('0000' + CAST(P.IdProducto AS VARCHAR(10)), 4)), P.Nombre, P.IdUnidadMedida, U.Abreviatura, L.Cantidad, L.Costo, ROUND(L.Cantidad * L.Costo, 2), 1, @Ahora, @UsuarioSistema
    FROM #CompraLineas L
    INNER JOIN dbo.Productos P ON P.Nombre = L.NombreProducto AND P.RowStatus = 1
    INNER JOIN dbo.UnidadesMedida U ON U.IdUnidadMedida = P.IdUnidadMedida
    WHERE L.CompraItem = @CompraItem;
    UPDATE D SET TotalDocumento = X.TotalDocumento FROM dbo.InvDocumentos D CROSS APPLY (SELECT SUM(Total) AS TotalDocumento FROM dbo.InvDocumentoDetalle WHERE IdDocumento = @IdDocumento) X WHERE D.IdDocumento = @IdDocumento;
    UPDATE PA SET Cantidad = PA.Cantidad + X.Cantidad, FechaModificacion = @Ahora, UsuarioModificacion = @UsuarioSistema
    FROM dbo.ProductoAlmacenes PA
    INNER JOIN (SELECT P.IdProducto, SUM(L.Cantidad) AS Cantidad FROM #CompraLineas L INNER JOIN dbo.Productos P ON P.Nombre = L.NombreProducto AND P.RowStatus = 1 WHERE L.CompraItem = @CompraItem GROUP BY P.IdProducto) X ON X.IdProducto = PA.IdProducto AND PA.IdAlmacen = @IdAlmacenPrincipal;
    INSERT INTO dbo.InvMovimientos (IdProducto, IdAlmacen, TipoMovimiento, Signo, IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea, Cantidad, CostoUnitario, CostoTotal, SaldoAnterior, SaldoNuevo, CostoPromedioAnterior, CostoPromedioNuevo, Fecha, Periodo, Observacion, RowStatus, FechaCreacion, UsuarioCreacion)
    SELECT P.IdProducto, @IdAlmacenPrincipal, 'C', 1, @IdDocumento, 'INV', @NumeroDocumento, L.NumeroLinea, L.Cantidad, L.Costo, ROUND(L.Cantidad * L.Costo, 2), 0, L.Cantidad, 0, L.Costo, @Fecha, @Periodo, @Observacion, 1, @Ahora, @UsuarioSistema
    FROM #CompraLineas L
    INNER JOIN dbo.Productos P ON P.Nombre = L.NombreProducto AND P.RowStatus = 1
    WHERE L.CompraItem = @CompraItem;
    FETCH NEXT FROM c_comp INTO @CompraItem, @Fecha, @Referencia, @Observacion, @NoFactura, @NCF;
  END
  CLOSE c_comp;
  DEALLOCATE c_comp;

  UPDATE dbo.InvTiposDocumento SET SecuenciaActual = @SecuenciaBase, FechaModificacion = @Ahora, UsuarioModificacion = @UsuarioSistema WHERE IdTipoDocumento = @IdTipoDocumentoCompra;

  COMMIT TRANSACTION;

  SELECT
    (SELECT COUNT(*) FROM dbo.Categorias WHERE RowStatus = 1 AND IdCategoria <> 0) AS CategoriasCreadas,
    (SELECT COUNT(*) FROM dbo.Productos WHERE RowStatus = 1) AS ProductosCreados,
    (SELECT COUNT(*) FROM dbo.InvDocumentos WHERE RowStatus = 1 AND TipoOperacion = 'C') AS ComprasCreadas,
    (SELECT COUNT(*) FROM dbo.InvDocumentoDetalle WHERE RowStatus = 1) AS LineasCompraCreadas;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
GO
