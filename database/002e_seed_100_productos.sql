-- ============================================================
-- Script: 002e_seed_100_productos.sql
-- Propósito: Crear 10 categorías y 100 productos (10 por categoría)
-- ============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @IdTipoProducto INT;
DECLARE @IdUnidadMedida INT;

-- Obtener referencias
SELECT TOP 1 @IdTipoProducto = IdTipoProducto FROM dbo.TiposProducto WHERE Activo = 1 ORDER BY IdTipoProducto;
SELECT TOP 1 @IdUnidadMedida = IdUnidadMedida FROM dbo.UnidadesMedida WHERE Activo = 1 ORDER BY IdUnidadMedida;

IF @IdTipoProducto IS NULL OR @IdUnidadMedida IS NULL
BEGIN
  PRINT 'ERROR: Falta TipoProducto o UnidadMedida';
  RETURN;
END;

-- ============================================================
-- Crear 10 categorías
-- ============================================================

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Bebidas Calientes', 'Categoría de Bebidas Calientes', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Bebidas Calientes');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Bebidas Frías', 'Categoría de Bebidas Frías', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Bebidas Frías');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Repostería', 'Categoría de Repostería', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Repostería');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Sándwiches', 'Categoría de Sándwiches', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Sándwiches');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Ensaladas', 'Categoría de Ensaladas', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Ensaladas');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Platos Principales', 'Categoría de Platos Principales', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Platos Principales');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Acompañamientos', 'Categoría de Acompañamientos', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Acompañamientos');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Postres', 'Categoría de Postres', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Postres');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Snacks', 'Categoría de Snacks', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Snacks');

INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
SELECT 'Accesorios', 'Categoría de Accesorios', 1, GETDATE() WHERE NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = 'Accesorios');

PRINT 'Categorías creadas/verificadas: 10';
GO

-- ============================================================
-- Crear 100 productos (10 por categoría)
-- ============================================================

DECLARE @IdTipoProducto INT;
DECLARE @IdUnidadMedida INT;
DECLARE @i INT = 1;
DECLARE @j INT;
DECLARE @CatId INT;
DECLARE @Precio DECIMAL(10, 2);

SELECT TOP 1 @IdTipoProducto = IdTipoProducto FROM dbo.TiposProducto WHERE Activo = 1 ORDER BY IdTipoProducto;
SELECT TOP 1 @IdUnidadMedida = IdUnidadMedida FROM dbo.UnidadesMedida WHERE Activo = 1 ORDER BY IdUnidadMedida;

DECLARE @Categorias_Temp TABLE (RowNum INT, IdCategoria INT, Nombre NVARCHAR(100));

INSERT INTO @Categorias_Temp (RowNum, IdCategoria, Nombre)
SELECT ROW_NUMBER() OVER (ORDER BY IdCategoria), IdCategoria, Nombre
FROM dbo.Categorias
WHERE Activo = 1;

DECLARE @MaxCat INT = (SELECT COUNT(*) FROM @Categorias_Temp);
SET @j = 1;

WHILE @j <= @MaxCat
BEGIN
  SELECT @CatId = IdCategoria FROM @Categorias_Temp WHERE RowNum = @j;

  DECLARE @k INT = 1;
  DECLARE @CatName NVARCHAR(100) = (SELECT Nombre FROM @Categorias_Temp WHERE RowNum = @j);

  WHILE @k <= 10
  BEGIN
    SET @Precio = 50.00 + (@i * 5.00);

    INSERT INTO dbo.Productos (IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio, Activo, FechaCreacion)
    VALUES (@CatId, @IdTipoProducto, @IdUnidadMedida, @CatName + ' ' + CAST(@k AS VARCHAR(2)), 'Producto ' + CAST(@i AS VARCHAR(3)), @Precio, 1, GETDATE());

    SET @k = @k + 1;
    SET @i = @i + 1;
  END;

  SET @j = @j + 1;
END;

PRINT 'Productos creados: 100';
GO

-- ============================================================
-- Verificación final
-- ============================================================

SELECT 'Categorías creadas:' AS [Resultado];
SELECT COUNT(*) AS [Total] FROM dbo.Categorias WHERE Activo = 1;

SELECT 'Productos creados:' AS [Resultado];
SELECT COUNT(*) AS [Total] FROM dbo.Productos WHERE Activo = 1;

SELECT 'Primeras 10 productos:' AS [Muestra];
SELECT TOP 10 IdProducto, Nombre, Precio FROM dbo.Productos ORDER BY IdProducto;

PRINT '============================================================';
PRINT 'Seed de 100 productos + 10 categorías completado exitosamente';
PRINT '============================================================';
