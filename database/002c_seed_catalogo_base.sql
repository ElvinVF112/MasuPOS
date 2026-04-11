-- ============================================================
-- Script: 002c_seed_catalogo_base.sql
-- Propósito: Seed de UnidadesMedida, TiposProducto, ListasPrecios
-- (requerido para que 74_seed_pos_categorias_productos.sql funcione)
-- ============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- UnidadesMedida - Unidades básicas
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM dbo.UnidadesMedida WHERE UPPER(Abreviatura) = 'UND')
  INSERT INTO dbo.UnidadesMedida (Nombre, Abreviatura, Activo)
  VALUES ('Unidad', 'UND', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.UnidadesMedida WHERE UPPER(Abreviatura) = 'KG')
  INSERT INTO dbo.UnidadesMedida (Nombre, Abreviatura, Activo)
  VALUES ('Kilogramo', 'KG', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.UnidadesMedida WHERE UPPER(Abreviatura) = 'LT')
  INSERT INTO dbo.UnidadesMedida (Nombre, Abreviatura, Activo)
  VALUES ('Litro', 'LT', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.UnidadesMedida WHERE UPPER(Abreviatura) = 'ML')
  INSERT INTO dbo.UnidadesMedida (Nombre, Abreviatura, Activo)
  VALUES ('Mililitro', 'ML', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.UnidadesMedida WHERE UPPER(Abreviatura) = 'GR')
  INSERT INTO dbo.UnidadesMedida (Nombre, Abreviatura, Activo)
  VALUES ('Gramo', 'GR', 1);

PRINT 'UnidadesMedida insertadas: 5 registros';
GO

-- ============================================================
-- TiposProducto - Tipos básicos
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM dbo.TiposProducto WHERE UPPER(Nombre) = 'PRODUCTO')
  INSERT INTO dbo.TiposProducto (Nombre, Descripcion, Activo)
  VALUES ('Producto', 'Producto físico estándar', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.TiposProducto WHERE UPPER(Nombre) = 'SERVICIO')
  INSERT INTO dbo.TiposProducto (Nombre, Descripcion, Activo)
  VALUES ('Servicio', 'Servicio o labor', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.TiposProducto WHERE UPPER(Nombre) = 'BEBIDA')
  INSERT INTO dbo.TiposProducto (Nombre, Descripcion, Activo)
  VALUES ('Bebida', 'Bebida para venta POS', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.TiposProducto WHERE UPPER(Nombre) = 'COMIDA')
  INSERT INTO dbo.TiposProducto (Nombre, Descripcion, Activo)
  VALUES ('Comida', 'Comida para venta POS', 1);

PRINT 'TiposProducto insertados: 4 registros';
GO

-- ============================================================
-- ListasPrecios - Listas base
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE UPPER(Codigo) = 'GENERAL_DOP')
  INSERT INTO dbo.ListasPrecios (
    Codigo, Descripcion, Abreviatura, IdMoneda, Activo, RowStatus
  )
  SELECT 'GENERAL_DOP', 'Lista General - Pesos Dominicanos', 'GEN', IdMoneda, 1, 1
  FROM dbo.Monedas
  WHERE Codigo = 'DOP'
    AND NOT EXISTS (
      SELECT 1 FROM dbo.ListasPrecios
      WHERE Codigo = 'GENERAL_DOP'
    );

IF NOT EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE UPPER(Codigo) = 'MAYOR_DOP')
  INSERT INTO dbo.ListasPrecios (
    Codigo, Descripcion, Abreviatura, IdMoneda, Activo, RowStatus
  )
  SELECT 'MAYOR_DOP', 'Lista Mayor - Pesos Dominicanos', 'MAY', IdMoneda, 1, 1
  FROM dbo.Monedas
  WHERE Codigo = 'DOP'
    AND NOT EXISTS (
      SELECT 1 FROM dbo.ListasPrecios
      WHERE Codigo = 'MAYOR_DOP'
    );

IF NOT EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE UPPER(Codigo) = 'DETALLE_DOP')
  INSERT INTO dbo.ListasPrecios (
    Codigo, Descripcion, Abreviatura, IdMoneda, Activo, RowStatus
  )
  SELECT 'DETALLE_DOP', 'Lista Detalle - Pesos Dominicanos', 'DET', IdMoneda, 1, 1
  FROM dbo.Monedas
  WHERE Codigo = 'DOP'
    AND NOT EXISTS (
      SELECT 1 FROM dbo.ListasPrecios
      WHERE Codigo = 'DETALLE_DOP'
    );

PRINT 'ListasPrecios insertadas: 3 registros';
GO

-- ============================================================
-- Verificación
-- ============================================================

SELECT 'UnidadesMedida:' AS [Tabla];
SELECT COUNT(*) AS [Total] FROM dbo.UnidadesMedida;

SELECT 'TiposProducto:' AS [Tabla];
SELECT COUNT(*) AS [Total] FROM dbo.TiposProducto;

SELECT 'ListasPrecios:' AS [Tabla];
SELECT COUNT(*) AS [Total] FROM dbo.ListasPrecios;

PRINT '============================================================';
PRINT 'Seed de catálogo base completado';
PRINT '============================================================';
