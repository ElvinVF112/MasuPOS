-- ============================================================
-- Script 36: Productos - Modelo Expandido (Tablas)
-- Tarea 25 - Paso 1
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ── 1. Eliminar columna Precio de Productos ──────────────────

-- Buscar y eliminar constraint DEFAULT si existe
DECLARE @constraint_name NVARCHAR(200);
SELECT @constraint_name = dc.name
FROM sys.default_constraints dc
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE OBJECT_NAME(dc.parent_object_id) = 'Productos' AND c.name = 'Precio';
IF @constraint_name IS NOT NULL
    EXEC('ALTER TABLE dbo.Productos DROP CONSTRAINT [' + @constraint_name + ']');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE OBJECT_NAME(object_id) = 'Productos' AND name = 'Precio')
BEGIN
    ALTER TABLE dbo.Productos DROP COLUMN Precio;
    PRINT 'Columna Precio eliminada de dbo.Productos';
END
ELSE
    PRINT 'Columna Precio no existe, omitido';
GO

-- ── 2. Agregar nuevas columnas a Productos ────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE OBJECT_NAME(object_id) = 'Productos' AND name = 'AplicaImpuesto')
BEGIN
    ALTER TABLE dbo.Productos
        ADD AplicaImpuesto              BIT          NOT NULL DEFAULT 0,
            IdTasaImpuesto              INT          NULL,
            UnidadBaseExistencia        NVARCHAR(20) NOT NULL DEFAULT 'measure',
            SeVendeEnFactura            BIT          NOT NULL DEFAULT 1,
            PermiteDescuento            BIT          NOT NULL DEFAULT 1,
            PermiteCambioPrecio         BIT          NOT NULL DEFAULT 1,
            PermitePrecioManual         BIT          NOT NULL DEFAULT 1,
            PideUnidad                  BIT          NOT NULL DEFAULT 0,
            PermiteFraccionesDecimales  BIT          NOT NULL DEFAULT 0,
            VenderSinExistencia         BIT          NOT NULL DEFAULT 1,
            AplicaPropina               BIT          NOT NULL DEFAULT 0,
            ManejaExistencia            BIT          NOT NULL DEFAULT 1;
    PRINT 'Columnas nuevas agregadas a dbo.Productos';
END
ELSE
    PRINT 'Columnas nuevas ya existen en dbo.Productos, omitido';
GO

-- FK IdTasaImpuesto → TasasImpuesto
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Productos_TasasImpuesto')
BEGIN
    ALTER TABLE dbo.Productos
        ADD CONSTRAINT FK_Productos_TasasImpuesto
            FOREIGN KEY (IdTasaImpuesto) REFERENCES dbo.TasasImpuesto(IdTasaImpuesto);
    PRINT 'FK FK_Productos_TasasImpuesto creado';
END
GO

-- ── 3. ProductoPrecios ─────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProductoPrecios' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ProductoPrecios (
        IdProductoPrecio    INT          IDENTITY(1,1) NOT NULL,
        IdProducto          INT          NOT NULL,
        IdListaPrecio       INT          NOT NULL,
        PorcentajeGanancia  DECIMAL(10,4) NOT NULL DEFAULT 0,
        Precio              DECIMAL(10,4) NOT NULL DEFAULT 0,
        Impuesto            DECIMAL(10,4) NOT NULL DEFAULT 0,
        PrecioConImpuesto   DECIMAL(10,4) NOT NULL DEFAULT 0,
        RowStatus           BIT          NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME     NOT NULL DEFAULT GETDATE(),
        UsuarioCreacion     INT          NULL,
        FechaModificacion   DATETIME     NULL,
        UsuarioModificacion INT          NULL,
        CONSTRAINT PK_ProductoPrecios PRIMARY KEY (IdProductoPrecio),
        CONSTRAINT FK_ProductoPrecios_Productos
            FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
        CONSTRAINT FK_ProductoPrecios_ListasPrecios
            FOREIGN KEY (IdListaPrecio) REFERENCES dbo.ListasPrecios(IdListaPrecio),
        CONSTRAINT UQ_ProductoPrecios
            UNIQUE (IdProducto, IdListaPrecio)
    );
    PRINT 'Tabla dbo.ProductoPrecios creada';
END
ELSE
    PRINT 'Tabla dbo.ProductoPrecios ya existe, omitido';
GO

-- ── 4. ProductoCostos ──────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProductoCostos' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ProductoCostos (
        IdProductoCosto     INT          IDENTITY(1,1) NOT NULL,
        IdProducto          INT          NOT NULL,
        IdMoneda            INT          NULL,
        DescuentoProveedor  DECIMAL(10,4) NOT NULL DEFAULT 0,
        CostoProveedor      DECIMAL(10,4) NOT NULL DEFAULT 0,
        CostoConImpuesto    DECIMAL(10,4) NOT NULL DEFAULT 0,
        CostoPromedio       DECIMAL(10,4) NOT NULL DEFAULT 0,
        PermitirCostoManual BIT          NOT NULL DEFAULT 0,
        RowStatus           BIT          NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME     NOT NULL DEFAULT GETDATE(),
        UsuarioCreacion     INT          NULL,
        FechaModificacion   DATETIME     NULL,
        UsuarioModificacion INT          NULL,
        CONSTRAINT PK_ProductoCostos PRIMARY KEY (IdProductoCosto),
        CONSTRAINT UQ_ProductoCostos_Producto UNIQUE (IdProducto),
        CONSTRAINT FK_ProductoCostos_Productos
            FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
        CONSTRAINT FK_ProductoCostos_Monedas
            FOREIGN KEY (IdMoneda) REFERENCES dbo.Monedas(IdMoneda)
    );
    PRINT 'Tabla dbo.ProductoCostos creada';
END
ELSE
    PRINT 'Tabla dbo.ProductoCostos ya existe, omitido';
GO

-- ── 5. ProductoOfertas ─────────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProductoOfertas' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ProductoOfertas (
        IdProductoOferta    INT          IDENTITY(1,1) NOT NULL,
        IdProducto          INT          NOT NULL,
        Activo              BIT          NOT NULL DEFAULT 0,
        PrecioOferta        DECIMAL(10,4) NOT NULL DEFAULT 0,
        FechaInicio         DATE         NULL,
        FechaFin            DATE         NULL,
        RowStatus           BIT          NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME     NOT NULL DEFAULT GETDATE(),
        UsuarioCreacion     INT          NULL,
        FechaModificacion   DATETIME     NULL,
        UsuarioModificacion INT          NULL,
        CONSTRAINT PK_ProductoOfertas PRIMARY KEY (IdProductoOferta),
        CONSTRAINT UQ_ProductoOfertas_Producto UNIQUE (IdProducto),
        CONSTRAINT FK_ProductoOfertas_Productos
            FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto)
    );
    PRINT 'Tabla dbo.ProductoOfertas creada';
END
ELSE
    PRINT 'Tabla dbo.ProductoOfertas ya existe, omitido';
GO

PRINT '=== Script 36 ejecutado correctamente ===';
GO
