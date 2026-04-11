SET NOCOUNT ON;

DECLARE @IdUsuarioDemo INT = TRY_CONVERT(INT, 1);
DECLARE @IdProductoDemo INT;
DECLARE @IdUnidadDemo INT;
DECLARE @IdEstadoAbierta INT;
DECLARE @IdEstadoProceso INT;

SELECT TOP (1) @IdProductoDemo = IdProducto, @IdUnidadDemo = IdUnidadMedida
FROM dbo.Productos
WHERE RowStatus = 1 AND Activo = 1
ORDER BY IdProducto;

SELECT @IdEstadoAbierta = IdEstadoOrden
FROM dbo.EstadosOrden
WHERE Nombre = 'Abierta' AND RowStatus = 1;

SELECT @IdEstadoProceso = IdEstadoOrden
FROM dbo.EstadosOrden
WHERE Nombre = 'En proceso' AND RowStatus = 1;

IF @IdUsuarioDemo IS NULL OR @IdProductoDemo IS NULL OR @IdUnidadDemo IS NULL OR @IdEstadoAbierta IS NULL OR @IdEstadoProceso IS NULL
BEGIN
    RAISERROR('No existen datos base suficientes para crear ordenes demo.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (
    SELECT 1
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.RowStatus = 1 AND E.Nombre IN ('Abierta', 'En proceso')
)
BEGIN
    DECLARE @OrdenNueva TABLE (
        IdOrden INT,
        NumeroOrden VARCHAR(20),
        IdRecurso INT,
        Recurso VARCHAR(100),
        IdEstadoOrden INT,
        EstadoOrden VARCHAR(50),
        IdUsuario INT,
        NombreUsuario NVARCHAR(150),
        FechaOrden DATETIME,
        Observaciones VARCHAR(500),
        Subtotal DECIMAL(18, 2),
        Impuesto DECIMAL(18, 2),
        Total DECIMAL(18, 2),
        FechaCierre DATETIME,
        Activo BIT,
        RowStatus BIT,
        FechaCreacion DATETIME
    );

    DECLARE @IdOrdenUno INT;
    DECLARE @IdOrdenDos INT;

    INSERT INTO @OrdenNueva
    EXEC dbo.spOrdenesCRUD
        @Accion = 'I',
        @IdRecurso = 1,
        @IdUsuario = @IdUsuarioDemo,
        @Observaciones = 'Orden demo generada para pruebas V2',
        @UsuarioCreacion = @IdUsuarioDemo;

    SELECT TOP (1) @IdOrdenUno = IdOrden FROM @OrdenNueva ORDER BY IdOrden DESC;

    IF @IdOrdenUno IS NOT NULL
    BEGIN
        EXEC dbo.spOrdenesDetalleCRUD
            @Accion = 'I',
            @IdOrden = @IdOrdenUno,
            @IdProducto = @IdProductoDemo,
            @IdUnidadMedida = @IdUnidadDemo,
            @Cantidad = 2,
            @Unidades = 1,
            @PrecioUnitario = 100,
            @PorcentajeImpuesto = 18,
            @ObservacionLinea = 'Demo V2 - recurso ocupado',
            @UsuarioCreacion = @IdUsuarioDemo;
    END;

    DELETE FROM @OrdenNueva;

    INSERT INTO @OrdenNueva
    EXEC dbo.spOrdenesCRUD
        @Accion = 'I',
        @IdRecurso = 2,
        @IdUsuario = @IdUsuarioDemo,
        @Observaciones = 'Orden demo en proceso para pruebas V2',
        @UsuarioCreacion = @IdUsuarioDemo;

    SELECT TOP (1) @IdOrdenDos = IdOrden FROM @OrdenNueva ORDER BY IdOrden DESC;

    IF @IdOrdenDos IS NOT NULL
    BEGIN
        EXEC dbo.spOrdenesDetalleCRUD
            @Accion = 'I',
            @IdOrden = @IdOrdenDos,
            @IdProducto = @IdProductoDemo,
            @IdUnidadMedida = @IdUnidadDemo,
            @Cantidad = 3,
            @Unidades = 1,
            @PrecioUnitario = 100,
            @PorcentajeImpuesto = 18,
            @ObservacionLinea = 'Demo V2 - orden en proceso',
            @UsuarioCreacion = @IdUsuarioDemo;

        EXEC dbo.spOrdenesCRUD
            @Accion = 'A',
            @IdOrden = @IdOrdenDos,
            @IdEstadoOrden = @IdEstadoProceso,
            @UsuarioModificacion = @IdUsuarioDemo;
    END;
END;
