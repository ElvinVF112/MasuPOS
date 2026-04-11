SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
  Seed POS demo
  - Limpia categorias y productos actuales con sus dependencias operativas.
  - Crea 10 categorias orientadas a POS.
  - Crea 100 productos (10 por categoria).
  - Configura colores POS para categorias.
  - Asigna precios en listas DOP activas.
  - Inicializa ProductoAlmacenes en 0 para todos los almacenes activos.

  Nota:
  Este script es agresivo y esta pensado para ambientes de demo / pruebas.
*/

BEGIN TRY
  BEGIN TRANSACTION;

  DECLARE @UsuarioSistema INT = 1;
  DECLARE @FechaAhora DATETIME = GETDATE();

  DECLARE @IdMonedaDOP INT;
  DECLARE @IdTipoProducto INT;
  DECLARE @IdUnidadUND INT;
  DECLARE @IdTasaITBIS INT;

  SELECT TOP (1) @IdMonedaDOP = M.IdMoneda
  FROM dbo.Monedas AS M
  WHERE UPPER(LTRIM(RTRIM(M.Codigo))) = 'DOP'
  ORDER BY M.IdMoneda;

  IF @IdMonedaDOP IS NULL
    THROW 50001, 'No se encontro la moneda DOP.', 1;

  SELECT TOP (1) @IdUnidadUND = U.IdUnidadMedida
  FROM dbo.UnidadesMedida AS U
  WHERE U.RowStatus = 1
    AND (
      UPPER(LTRIM(RTRIM(U.Abreviatura))) = 'UND'
      OR UPPER(LTRIM(RTRIM(U.Nombre))) = 'UNIDAD'
    )
  ORDER BY U.IdUnidadMedida;

  IF @IdUnidadUND IS NULL
    THROW 50002, 'No se encontro la unidad UND/Unidad.', 1;

  SELECT TOP (1) @IdTipoProducto = TP.IdTipoProducto
  FROM dbo.TiposProducto AS TP
  WHERE TP.Activo = 1
    AND ISNULL(TP.RowStatus, 1) = 1
  ORDER BY TP.IdTipoProducto;

  IF @IdTipoProducto IS NULL
    THROW 50003, 'No se encontro un TipoProducto activo.', 1;

  SELECT TOP (1) @IdTasaITBIS = TI.IdTasaImpuesto
  FROM dbo.TasasImpuesto AS TI
  WHERE TI.RowStatus = 'A'
    AND TRY_CONVERT(DECIMAL(10, 4), TI.Tasa) = 18
  ORDER BY TI.IdTasaImpuesto;

  IF @IdTasaITBIS IS NULL
  BEGIN
    SELECT TOP (1) @IdTasaITBIS = TI.IdTasaImpuesto
    FROM dbo.TasasImpuesto AS TI
    WHERE TI.RowStatus = 'A'
    ORDER BY TI.IdTasaImpuesto;
  END;

  IF OBJECT_ID('tempdb..#ListasDOP') IS NOT NULL DROP TABLE #ListasDOP;
  CREATE TABLE #ListasDOP (
    IdListaPrecio INT NOT NULL PRIMARY KEY,
    Codigo NVARCHAR(20) NOT NULL,
    Descripcion NVARCHAR(200) NOT NULL,
    EsGeneral BIT NOT NULL,
    EsDetalle BIT NOT NULL
  );

  INSERT INTO #ListasDOP (IdListaPrecio, Codigo, Descripcion, EsGeneral, EsDetalle)
  SELECT
    LP.IdListaPrecio,
    LP.Codigo,
    LP.Descripcion,
    CASE
      WHEN UPPER(ISNULL(LP.Abreviatura, '')) LIKE '%GENERAL%'
        OR UPPER(ISNULL(LP.Descripcion, '')) LIKE '%GENERAL%'
        OR LP.Codigo = '1'
      THEN 1 ELSE 0
    END,
    CASE
      WHEN UPPER(ISNULL(LP.Abreviatura, '')) LIKE '%DETALLE%'
        OR UPPER(ISNULL(LP.Descripcion, '')) LIKE '%DETALLE%'
        OR LP.Codigo = '2'
      THEN 1 ELSE 0
    END
  FROM dbo.ListasPrecios AS LP
  WHERE LP.Activo = 1
    AND LP.RowStatus = 1
    AND LP.IdMoneda = @IdMonedaDOP;

  IF NOT EXISTS (SELECT 1 FROM #ListasDOP)
    THROW 50004, 'No hay listas de precios activas en DOP.', 1;

  /*
    Limpieza previa
  */
  IF OBJECT_ID('dbo.OrdenesDetalle', 'U') IS NOT NULL
    DELETE FROM dbo.OrdenesDetalle;

  IF OBJECT_ID('dbo.Ordenes', 'U') IS NOT NULL
    DELETE FROM dbo.Ordenes;

  IF OBJECT_ID('dbo.InvDocumentoDetalle', 'U') IS NOT NULL
    DELETE FROM dbo.InvDocumentoDetalle;

  IF OBJECT_ID('dbo.InvTransferencias', 'U') IS NOT NULL
    DELETE FROM dbo.InvTransferencias;

  IF OBJECT_ID('dbo.InvMovimientos', 'U') IS NOT NULL
    DELETE FROM dbo.InvMovimientos;

  IF OBJECT_ID('dbo.InvSaldosMensuales', 'U') IS NOT NULL
    DELETE FROM dbo.InvSaldosMensuales;

  IF OBJECT_ID('dbo.InvDocumentos', 'U') IS NOT NULL
    DELETE FROM dbo.InvDocumentos;

  IF OBJECT_ID('dbo.ProductoAlmacenesLimites', 'U') IS NOT NULL
    DELETE FROM dbo.ProductoAlmacenesLimites;

  IF OBJECT_ID('dbo.ProductoAlmacenes', 'U') IS NOT NULL
    DELETE FROM dbo.ProductoAlmacenes;

  IF OBJECT_ID('dbo.ProductoOfertas', 'U') IS NOT NULL
    DELETE FROM dbo.ProductoOfertas;

  IF OBJECT_ID('dbo.ProductoPrecios', 'U') IS NOT NULL
    DELETE FROM dbo.ProductoPrecios;

  IF OBJECT_ID('dbo.Productos', 'U') IS NOT NULL
    DELETE FROM dbo.Productos;

  IF OBJECT_ID('dbo.Categorias', 'U') IS NOT NULL
    DELETE FROM dbo.Categorias;

  DBCC CHECKIDENT ('dbo.Categorias', RESEED, 0) WITH NO_INFOMSGS;
  DBCC CHECKIDENT ('dbo.Productos', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('dbo.ProductoPrecios', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.ProductoPrecios', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('dbo.ProductoOfertas', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.ProductoOfertas', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('dbo.Ordenes', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.Ordenes', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('dbo.OrdenesDetalle', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.OrdenesDetalle', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('dbo.InvDocumentos', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.InvDocumentos', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('dbo.InvDocumentoDetalle', 'U') IS NOT NULL
    DBCC CHECKIDENT ('dbo.InvDocumentoDetalle', RESEED, 0) WITH NO_INFOMSGS;

  IF OBJECT_ID('tempdb..#CategoriasSeed') IS NOT NULL DROP TABLE #CategoriasSeed;
  CREATE TABLE #CategoriasSeed (
    Codigo NVARCHAR(20) NOT NULL PRIMARY KEY,
    CodigoCorto NVARCHAR(10) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    NombreCorto NVARCHAR(30) NOT NULL,
    Descripcion NVARCHAR(200) NULL,
    ColorFondo NVARCHAR(7) NOT NULL,
    ColorBoton NVARCHAR(7) NOT NULL,
    ColorTexto NVARCHAR(7) NOT NULL,
    TamanoTexto INT NOT NULL,
    ColumnasPOS INT NOT NULL
  );

  INSERT INTO #CategoriasSeed (Codigo, CodigoCorto, Nombre, NombreCorto, Descripcion, ColorFondo, ColorBoton, ColorTexto, TamanoTexto, ColumnasPOS)
  VALUES
    ('CAT-BFRIAS', 'BFR', 'Bebidas Frias', 'Frias', 'Jugos, refrescos y bebidas frias.', '#EAF4FF', '#0F62FE', '#FFFFFF', 14, 3),
    ('CAT-BCAL', 'BCA', 'Bebidas Calientes', 'Calientes', 'Cafe, te y bebidas calientes.', '#FFF3E8', '#C2410C', '#FFFFFF', 14, 3),
    ('CAT-CERV', 'CRV', 'Cervezas', 'Cervezas', 'Cervezas nacionales e importadas.', '#FFF7CC', '#D97706', '#2B1E00', 14, 3),
    ('CAT-COCT', 'CKT', 'Cocteles', 'Cocteles', 'Cocteles clasicos y frozen.', '#FDF2FF', '#BE185D', '#FFFFFF', 14, 3),
    ('CAT-RAP', 'RAP', 'Comida Rapida', 'Rapida', 'Hamburguesas, pizzas y sandwiches.', '#FEE2E2', '#DC2626', '#FFFFFF', 14, 3),
    ('CAT-PIC', 'PIC', 'Picaderas', 'Picaderas', 'Entradas para compartir.', '#FFF1F2', '#E11D48', '#FFFFFF', 14, 3),
    ('CAT-PLT', 'PLT', 'Platos Fuertes', 'Platos', 'Platos principales del menu.', '#ECFDF3', '#15803D', '#FFFFFF', 14, 3),
    ('CAT-PST', 'PST', 'Postres', 'Postres', 'Dulces y postres frios.', '#FFF7ED', '#EA580C', '#FFFFFF', 14, 3),
    ('CAT-CMB', 'CMB', 'Combos', 'Combos', 'Combos de comida y bebida.', '#EEF2FF', '#4338CA', '#FFFFFF', 14, 3),
    ('CAT-EXT', 'EXT', 'Extras y Salsas', 'Extras', 'Acompanantes, toppings y salsas.', '#F1F5F9', '#475569', '#FFFFFF', 14, 3);

  INSERT INTO dbo.Categorias (
    Nombre,
    Descripcion,
    Activo,
    FechaCreacion,
    RowStatus,
    UsuarioCreacion,
    Codigo,
    CodigoCorto,
    NombreCorto,
    IdMoneda,
    ColorFondo,
    ColorBoton,
    ColorTexto,
    TamanoTexto,
    ColumnasPOS,
    MostrarEnPOS
  )
  SELECT
    C.Nombre,
    C.Descripcion,
    1,
    @FechaAhora,
    1,
    @UsuarioSistema,
    C.Codigo,
    C.CodigoCorto,
    C.NombreCorto,
    @IdMonedaDOP,
    C.ColorFondo,
    C.ColorBoton,
    C.ColorTexto,
    C.TamanoTexto,
    C.ColumnasPOS,
    1
  FROM #CategoriasSeed AS C
  ORDER BY C.Codigo;

  IF OBJECT_ID('tempdb..#CategoriasMap') IS NOT NULL DROP TABLE #CategoriasMap;
  CREATE TABLE #CategoriasMap (
    Codigo NVARCHAR(20) NOT NULL PRIMARY KEY,
    IdCategoria INT NOT NULL
  );

  INSERT INTO #CategoriasMap (Codigo, IdCategoria)
  SELECT S.Codigo, C.IdCategoria
  FROM #CategoriasSeed AS S
  INNER JOIN dbo.Categorias AS C
    ON C.Codigo = S.Codigo
   AND C.RowStatus = 1;

  IF OBJECT_ID('tempdb..#ProductosSeed') IS NOT NULL DROP TABLE #ProductosSeed;
  CREATE TABLE #ProductosSeed (
    CategoriaCodigo NVARCHAR(20) NOT NULL,
    Codigo NVARCHAR(20) NOT NULL PRIMARY KEY,
    Nombre NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(250) NULL,
    Comentario NVARCHAR(250) NULL,
    Precio DECIMAL(18,4) NOT NULL,
    Costo DECIMAL(18,4) NOT NULL,
    AplicaImpuesto BIT NOT NULL DEFAULT 1
  );

  INSERT INTO #ProductosSeed (CategoriaCodigo, Codigo, Nombre, Descripcion, Comentario, Precio, Costo, AplicaImpuesto)
  VALUES
    ('CAT-BFRIAS', 'POS001', 'Agua 500ml', 'Botella de agua fria de 500ml.', 'Ideal para takeaway.', 60.00, 25.00, 1),
    ('CAT-BFRIAS', 'POS002', 'Agua con Gas', 'Botella de agua mineral con gas.', 'Servir bien fria.', 75.00, 32.00, 1),
    ('CAT-BFRIAS', 'POS003', 'Refresco Cola', 'Refresco de cola 12 oz.', 'Presentacion individual.', 95.00, 38.00, 1),
    ('CAT-BFRIAS', 'POS004', 'Refresco Limon', 'Refresco sabor limon 12 oz.', 'Presentacion individual.', 95.00, 38.00, 1),
    ('CAT-BFRIAS', 'POS005', 'Jugo de Naranja', 'Jugo natural de naranja.', 'Preparacion fresca.', 145.00, 58.00, 1),
    ('CAT-BFRIAS', 'POS006', 'Jugo de Chinola', 'Jugo natural de chinola.', 'Preparacion fresca.', 145.00, 58.00, 1),
    ('CAT-BFRIAS', 'POS007', 'Limonada Clasica', 'Limonada natural con hielo.', 'Vaso 16 oz.', 130.00, 45.00, 1),
    ('CAT-BFRIAS', 'POS008', 'Limonada Frozen', 'Limonada frappe.', 'Textura frozen.', 165.00, 62.00, 1),
    ('CAT-BFRIAS', 'POS009', 'Te Frio Limon', 'Te frio sabor limon.', 'Vaso 16 oz.', 110.00, 42.00, 1),
    ('CAT-BFRIAS', 'POS010', 'Malteada Vainilla', 'Malteada cremosa de vainilla.', 'Servir con topping.', 210.00, 85.00, 1),

    ('CAT-BCAL', 'POS011', 'Cafe Espresso', 'Cafe espresso sencillo.', 'Taza pequena.', 95.00, 28.00, 1),
    ('CAT-BCAL', 'POS012', 'Cafe Americano', 'Cafe americano 8 oz.', 'Intensidad media.', 105.00, 32.00, 1),
    ('CAT-BCAL', 'POS013', 'Cafe con Leche', 'Cafe con leche espumada.', 'Vaso 10 oz.', 135.00, 48.00, 1),
    ('CAT-BCAL', 'POS014', 'Cappuccino', 'Cappuccino clasico.', 'Con espuma cremosa.', 155.00, 55.00, 1),
    ('CAT-BCAL', 'POS015', 'Latte Vainilla', 'Latte con toque de vainilla.', 'Vaso 12 oz.', 175.00, 66.00, 1),
    ('CAT-BCAL', 'POS016', 'Chocolate Caliente', 'Chocolate caliente cremoso.', 'Vaso 12 oz.', 165.00, 63.00, 1),
    ('CAT-BCAL', 'POS017', 'Te Verde', 'Te verde caliente.', 'Taza individual.', 90.00, 24.00, 1),
    ('CAT-BCAL', 'POS018', 'Te Manzanilla', 'Infusion de manzanilla.', 'Taza individual.', 90.00, 24.00, 1),
    ('CAT-BCAL', 'POS019', 'Mocaccino', 'Cafe moka con chocolate.', 'Vaso 12 oz.', 185.00, 72.00, 1),
    ('CAT-BCAL', 'POS020', 'Chocolate Blanco', 'Bebida caliente de chocolate blanco.', 'Vaso 12 oz.', 190.00, 74.00, 1),

    ('CAT-CERV', 'POS021', 'Cerveza Nacional Small', 'Cerveza nacional pequena.', 'Servir bien fria.', 140.00, 60.00, 1),
    ('CAT-CERV', 'POS022', 'Cerveza Nacional Large', 'Cerveza nacional grande.', 'Servir bien fria.', 220.00, 96.00, 1),
    ('CAT-CERV', 'POS023', 'Cerveza Light', 'Cerveza ligera.', 'Presentacion regular.', 150.00, 64.00, 1),
    ('CAT-CERV', 'POS024', 'Cerveza Negra', 'Cerveza oscura.', 'Botella individual.', 170.00, 72.00, 1),
    ('CAT-CERV', 'POS025', 'Cerveza Importada', 'Cerveza importada premium.', 'Botella individual.', 260.00, 125.00, 1),
    ('CAT-CERV', 'POS026', 'Cubeta 4 Cervezas', 'Cubeta de 4 cervezas nacionales.', 'Incluye hielo.', 520.00, 240.00, 1),
    ('CAT-CERV', 'POS027', 'Cubeta 6 Cervezas', 'Cubeta de 6 cervezas nacionales.', 'Incluye hielo.', 760.00, 348.00, 1),
    ('CAT-CERV', 'POS028', 'Michelada Clasica', 'Cerveza preparada estilo michelada.', 'Vaso escarchado.', 245.00, 105.00, 1),
    ('CAT-CERV', 'POS029', 'Radler Limon', 'Cerveza con limon ligera.', 'Muy refrescante.', 185.00, 78.00, 1),
    ('CAT-CERV', 'POS030', 'Cerveza Artesanal', 'Cerveza artesanal rotativa.', 'Consultar disponibilidad.', 310.00, 145.00, 1),

    ('CAT-COCT', 'POS031', 'Mojito Clasico', 'Ron, hierbabuena y limon.', 'Coctel clasico.', 295.00, 128.00, 1),
    ('CAT-COCT', 'POS032', 'Margarita Limon', 'Tequila y limon.', 'Copa escarchada.', 320.00, 140.00, 1),
    ('CAT-COCT', 'POS033', 'Pina Colada', 'Ron, pina y coco.', 'Version frozen.', 310.00, 136.00, 1),
    ('CAT-COCT', 'POS034', 'Sangria Copa', 'Copa de sangria.', 'Preparacion de la casa.', 240.00, 102.00, 1),
    ('CAT-COCT', 'POS035', 'Cuba Libre', 'Ron con cola y limon.', 'Vaso highball.', 255.00, 110.00, 1),
    ('CAT-COCT', 'POS036', 'Daiquiri Fresa', 'Daiquiri frozen de fresa.', 'Presentacion frozen.', 330.00, 145.00, 1),
    ('CAT-COCT', 'POS037', 'Whisky Sour', 'Whisky con mix citrico.', 'Coctel clasico.', 345.00, 150.00, 1),
    ('CAT-COCT', 'POS038', 'Gin Tonic', 'Gin con agua tonica.', 'Copa grande.', 360.00, 158.00, 1),
    ('CAT-COCT', 'POS039', 'Aperol Spritz', 'Aperitivo con espumante.', 'Copa de vino.', 395.00, 176.00, 1),
    ('CAT-COCT', 'POS040', 'Moscow Mule', 'Vodka, ginger beer y limon.', 'Servido en mug.', 365.00, 160.00, 1),

    ('CAT-RAP', 'POS041', 'Hamburguesa Clasica', 'Hamburguesa de res con queso.', 'Incluye papas.', 320.00, 145.00, 1),
    ('CAT-RAP', 'POS042', 'Hamburguesa Bacon', 'Hamburguesa con bacon y cheddar.', 'Incluye papas.', 375.00, 170.00, 1),
    ('CAT-RAP', 'POS043', 'Cheeseburger Doble', 'Hamburguesa doble carne.', 'Incluye papas.', 435.00, 205.00, 1),
    ('CAT-RAP', 'POS044', 'Hot Dog Clasico', 'Pan, salchicha y toppings.', 'Presentacion individual.', 180.00, 75.00, 1),
    ('CAT-RAP', 'POS045', 'Sandwich Club', 'Sandwich club de pollo y bacon.', 'Corte triangular.', 290.00, 130.00, 1),
    ('CAT-RAP', 'POS046', 'Wrap de Pollo', 'Wrap de pollo a la plancha.', 'Con papas o ensalada.', 285.00, 122.00, 1),
    ('CAT-RAP', 'POS047', 'Pizza Personal Pepperoni', 'Pizza personal de pepperoni.', '8 pulgadas.', 350.00, 155.00, 1),
    ('CAT-RAP', 'POS048', 'Pizza Personal Queso', 'Pizza personal de queso.', '8 pulgadas.', 330.00, 145.00, 1),
    ('CAT-RAP', 'POS049', 'Quesadilla de Pollo', 'Tortilla rellena de pollo y queso.', 'Con salsa.', 295.00, 128.00, 1),
    ('CAT-RAP', 'POS050', 'Tacos de Res', 'Tres tacos de res sazonada.', 'Incluye pico de gallo.', 310.00, 135.00, 1),

    ('CAT-PIC', 'POS051', 'Papas Fritas', 'Papas fritas crujientes.', 'Porcion regular.', 145.00, 52.00, 1),
    ('CAT-PIC', 'POS052', 'Papas Gajo', 'Papas gajo sazonadas.', 'Porcion regular.', 165.00, 60.00, 1),
    ('CAT-PIC', 'POS053', 'Aros de Cebolla', 'Aros de cebolla empanizados.', 'Porcion regular.', 185.00, 70.00, 1),
    ('CAT-PIC', 'POS054', 'Mozzarella Sticks', 'Dedos de mozzarella.', '6 unidades.', 235.00, 96.00, 1),
    ('CAT-PIC', 'POS055', 'Alitas BBQ 6u', 'Seis alitas en salsa BBQ.', 'Incluye dip.', 285.00, 122.00, 1),
    ('CAT-PIC', 'POS056', 'Alitas Picantes 6u', 'Seis alitas picantes.', 'Incluye dip.', 285.00, 122.00, 1),
    ('CAT-PIC', 'POS057', 'Nachos Supremos', 'Nachos con carne, queso y jalapenos.', 'Perfectos para compartir.', 330.00, 148.00, 1),
    ('CAT-PIC', 'POS058', 'Croquetas de Pollo', 'Croquetas de pollo crujientes.', '8 unidades.', 215.00, 88.00, 1),
    ('CAT-PIC', 'POS059', 'Yuca Frita', 'Yuca frita con salsa rosada.', 'Porcion regular.', 155.00, 58.00, 1),
    ('CAT-PIC', 'POS060', 'Picadera Mixta Small', 'Picadera mixta pequena.', 'Para 2 personas.', 520.00, 245.00, 1),

    ('CAT-PLT', 'POS061', 'Pollo a la Plancha', 'Pechuga a la plancha con guarnicion.', 'Incluye acompanante.', 360.00, 165.00, 1),
    ('CAT-PLT', 'POS062', 'Pechurina con Papas', 'Tiras de pollo empanizadas.', 'Incluye papas fritas.', 340.00, 152.00, 1),
    ('CAT-PLT', 'POS063', 'Churrasco 10oz', 'Churrasco a la parrilla.', 'Incluye acompanante.', 845.00, 425.00, 1),
    ('CAT-PLT', 'POS064', 'Pasta Alfredo Pollo', 'Pasta en salsa alfredo con pollo.', 'Plato completo.', 425.00, 188.00, 1),
    ('CAT-PLT', 'POS065', 'Pasta Bolognesa', 'Pasta con salsa de carne.', 'Plato completo.', 395.00, 176.00, 1),
    ('CAT-PLT', 'POS066', 'Mofongo de Pollo', 'Mofongo relleno de pollo.', 'Salsa criolla.', 410.00, 182.00, 1),
    ('CAT-PLT', 'POS067', 'Mofongo de Camaron', 'Mofongo relleno de camarones.', 'Salsa criolla.', 520.00, 245.00, 1),
    ('CAT-PLT', 'POS068', 'Arroz con Camarones', 'Arroz cremoso con camarones.', 'Plato principal.', 495.00, 228.00, 1),
    ('CAT-PLT', 'POS069', 'Filete de Pescado', 'Filete de pescado a la plancha.', 'Incluye acompanante.', 465.00, 215.00, 1),
    ('CAT-PLT', 'POS070', 'Costillas BBQ', 'Costillas en salsa BBQ.', 'Incluye papas wedges.', 585.00, 278.00, 1),

    ('CAT-PST', 'POS071', 'Brownie con Helado', 'Brownie tibio con helado.', 'Postre estrella.', 225.00, 86.00, 1),
    ('CAT-PST', 'POS072', 'Cheesecake Fresa', 'Cheesecake con topping de fresa.', 'Porcion individual.', 215.00, 82.00, 1),
    ('CAT-PST', 'POS073', 'Flan de Caramelo', 'Flan cremoso casero.', 'Porcion individual.', 145.00, 52.00, 1),
    ('CAT-PST', 'POS074', 'Tres Leches', 'Bizcocho tres leches.', 'Porcion individual.', 175.00, 64.00, 1),
    ('CAT-PST', 'POS075', 'Helado Vainilla', 'Copa de helado vainilla.', '2 bolas.', 110.00, 36.00, 1),
    ('CAT-PST', 'POS076', 'Helado Chocolate', 'Copa de helado chocolate.', '2 bolas.', 110.00, 36.00, 1),
    ('CAT-PST', 'POS077', 'Churros con Azucar', 'Churros recien hechos.', 'Con dip aparte.', 160.00, 58.00, 1),
    ('CAT-PST', 'POS078', 'Tarta de Manzana', 'Tarta de manzana horneada.', 'Porcion individual.', 190.00, 74.00, 1),
    ('CAT-PST', 'POS079', 'Volcan de Chocolate', 'Volcan tibio de chocolate.', 'Con helado.', 245.00, 95.00, 1),
    ('CAT-PST', 'POS080', 'Banana Split', 'Helado con banana y toppings.', 'Postre grande.', 230.00, 90.00, 1),

    ('CAT-CMB', 'POS081', 'Combo Burger + Refresco', 'Hamburguesa clasica con refresco.', 'Combo de alta rotacion.', 395.00, 178.00, 1),
    ('CAT-CMB', 'POS082', 'Combo Bacon + Papas + Refresco', 'Burger bacon con papas y refresco.', 'Combo premium.', 485.00, 224.00, 1),
    ('CAT-CMB', 'POS083', 'Combo Hot Dog + Refresco', 'Hot dog con refresco.', 'Combo rapido.', 245.00, 106.00, 1),
    ('CAT-CMB', 'POS084', 'Combo Wrap + Jugo', 'Wrap de pollo con jugo natural.', 'Combo saludable.', 395.00, 176.00, 1),
    ('CAT-CMB', 'POS085', 'Combo Pizza Personal + Refresco', 'Pizza personal con bebida.', 'Combo individual.', 430.00, 192.00, 1),
    ('CAT-CMB', 'POS086', 'Combo Quesadilla + Refresco', 'Quesadilla con refresco.', 'Combo individual.', 385.00, 170.00, 1),
    ('CAT-CMB', 'POS087', 'Combo Tacos + Refresco', 'Tres tacos con refresco.', 'Combo individual.', 405.00, 182.00, 1),
    ('CAT-CMB', 'POS088', 'Combo Alitas + Cerveza', 'Alitas con cerveza nacional.', 'Ideal para sports bar.', 425.00, 188.00, 1),
    ('CAT-CMB', 'POS089', 'Combo Cafe + Brownie', 'Cafe americano y brownie.', 'Combo merienda.', 260.00, 98.00, 1),
    ('CAT-CMB', 'POS090', 'Combo Ninos', 'Mini burger, papas y jugo.', 'Combo infantil.', 290.00, 124.00, 1),

    ('CAT-EXT', 'POS091', 'Salsa Ketchup', 'Porcion de ketchup.', 'Extra individual.', 25.00, 6.00, 1),
    ('CAT-EXT', 'POS092', 'Salsa Rosada', 'Porcion de salsa rosada.', 'Extra individual.', 30.00, 8.00, 1),
    ('CAT-EXT', 'POS093', 'Salsa BBQ', 'Porcion de salsa BBQ.', 'Extra individual.', 35.00, 10.00, 1),
    ('CAT-EXT', 'POS094', 'Mayonesa de Ajo', 'Porcion de mayonesa de ajo.', 'Extra individual.', 35.00, 10.00, 1),
    ('CAT-EXT', 'POS095', 'Queso Extra', 'Porcion de queso adicional.', 'Topping adicional.', 45.00, 18.00, 1),
    ('CAT-EXT', 'POS096', 'Bacon Extra', 'Porcion de bacon adicional.', 'Topping adicional.', 65.00, 28.00, 1),
    ('CAT-EXT', 'POS097', 'Papas Extra', 'Porcion adicional de papas.', 'Acompanante extra.', 95.00, 36.00, 1),
    ('CAT-EXT', 'POS098', 'Hielo Extra', 'Vaso de hielo.', 'Extra de bar.', 20.00, 4.00, 1),
    ('CAT-EXT', 'POS099', 'Limon Extra', 'Porcion de limon.', 'Extra de bar.', 20.00, 5.00, 1),
    ('CAT-EXT', 'POS100', 'Pan Extra', 'Pan adicional.', 'Acompanante extra.', 30.00, 9.00, 1);

  INSERT INTO dbo.Productos (
    IdCategoria,
    IdTipoProducto,
    IdUnidadMedida,
    Nombre,
    Descripcion,
    Activo,
    FechaCreacion,
    RowStatus,
    UsuarioCreacion,
    IdUnidadVenta,
    IdUnidadCompra,
    AplicaImpuesto,
    IdTasaImpuesto,
    UnidadBaseExistencia,
    SeVendeEnFactura,
    PermiteDescuento,
    PermiteCambioPrecio,
    PermitePrecioManual,
    PideUnidad,
    PermiteFraccionesDecimales,
    VenderSinExistencia,
    AplicaPropina,
    ManejaExistencia,
    IdMoneda,
    DescuentoProveedor,
    CostoProveedor,
    CostoConImpuesto,
    CostoPromedio,
    PermitirCostoManual,
    Codigo,
    Comentario,
    PideUnidadInventario
  )
  SELECT
    CM.IdCategoria,
    @IdTipoProducto,
    @IdUnidadUND,
    P.Nombre,
    P.Descripcion,
    1,
    @FechaAhora,
    1,
    @UsuarioSistema,
    @IdUnidadUND,
    @IdUnidadUND,
    P.AplicaImpuesto,
    CASE WHEN P.AplicaImpuesto = 1 THEN @IdTasaITBIS ELSE NULL END,
    'measure',
    1,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    1,
    @IdMonedaDOP,
    0,
    P.Costo,
    CASE
      WHEN P.AplicaImpuesto = 1 AND @IdTasaITBIS IS NOT NULL
      THEN ROUND(P.Costo * 1.18, 4)
      ELSE P.Costo
    END,
    P.Costo,
    0,
    P.Codigo,
    P.Comentario,
    0
  FROM #ProductosSeed AS P
  INNER JOIN #CategoriasMap AS CM
    ON CM.Codigo = P.CategoriaCodigo
  ORDER BY P.Codigo;

  INSERT INTO dbo.ProductoPrecios (
    IdProducto,
    IdListaPrecio,
    PorcentajeGanancia,
    Precio,
    Impuesto,
    PrecioConImpuesto,
    RowStatus,
    FechaCreacion,
    UsuarioCreacion
  )
  SELECT
    PR.IdProducto,
    LP.IdListaPrecio,
    CASE
      WHEN PS.Costo <= 0 THEN 0
      ELSE ROUND(((PrecioBase - PS.Costo) / PS.Costo) * 100.0, 4)
    END AS PorcentajeGanancia,
    PrecioBase,
    CASE
      WHEN PS.AplicaImpuesto = 1 AND @IdTasaITBIS IS NOT NULL THEN 18
      ELSE 0
    END AS Impuesto,
    CASE
      WHEN PS.AplicaImpuesto = 1 AND @IdTasaITBIS IS NOT NULL THEN ROUND(PrecioBase * 1.18, 4)
      ELSE PrecioBase
    END AS PrecioConImpuesto,
    1,
    @FechaAhora,
    @UsuarioSistema
  FROM #ProductosSeed AS PS
  INNER JOIN dbo.Productos AS PR
    ON PR.Codigo = PS.Codigo
   AND PR.RowStatus = 1
  INNER JOIN #ListasDOP AS LP
    ON 1 = 1
  CROSS APPLY (
    SELECT CASE
      WHEN LP.EsDetalle = 1 THEN ROUND(PS.Precio * 1.08, 4)
      WHEN LP.EsGeneral = 1 THEN ROUND(PS.Precio, 4)
      ELSE ROUND(PS.Precio, 4)
    END AS PrecioBase
  ) AS Calc;

  IF OBJECT_ID('dbo.ProductoAlmacenes', 'U') IS NOT NULL
  BEGIN
    INSERT INTO dbo.ProductoAlmacenes (
      IdProducto,
      IdAlmacen,
      Cantidad,
      CantidadReservada,
      CantidadTransito,
      RowStatus,
      FechaCreacion,
      UsuarioCreacion
    )
    SELECT
      P.IdProducto,
      A.IdAlmacen,
      0,
      0,
      0,
      1,
      @FechaAhora,
      @UsuarioSistema
    FROM dbo.Productos AS P
    CROSS JOIN dbo.Almacenes AS A
    WHERE P.RowStatus = 1
      AND A.RowStatus = 1
      AND A.Activo = 1;
  END;

  COMMIT TRANSACTION;

  SELECT
    (SELECT COUNT(*) FROM dbo.Categorias WHERE RowStatus = 1) AS CategoriasCreadas,
    (SELECT COUNT(*) FROM dbo.Productos WHERE RowStatus = 1) AS ProductosCreados,
    (SELECT COUNT(*) FROM dbo.ProductoPrecios WHERE RowStatus = 1) AS PreciosCreados;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

  THROW;
END CATCH;
GO
