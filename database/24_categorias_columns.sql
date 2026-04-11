-- TAREA 24: Agregar columnas faltantes a Categorias
-- Requiere: spCategoriasCRUD actualizado para manejar campos nuevos

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Agregar columnas faltantes si no existen
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'IdCategoriaPadre')
  ALTER TABLE dbo.Categorias ADD IdCategoriaPadre INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'Codigo')
  ALTER TABLE dbo.Categorias ADD Codigo NVARCHAR(20) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'CodigoCorto')
  ALTER TABLE dbo.Categorias ADD CodigoCorto NVARCHAR(10) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'NombreCorto')
  ALTER TABLE dbo.Categorias ADD NombreCorto NVARCHAR(30) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'IdMoneda')
  ALTER TABLE dbo.Categorias ADD IdMoneda INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'ColorFondo')
  ALTER TABLE dbo.Categorias ADD ColorFondo NVARCHAR(7) DEFAULT '#1e3a5f';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'ColorBoton')
  ALTER TABLE dbo.Categorias ADD ColorBoton NVARCHAR(7) DEFAULT '#12467e';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'ColorTexto')
  ALTER TABLE dbo.Categorias ADD ColorTexto NVARCHAR(7) DEFAULT '#ffffff';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'TamanoTexto')
  ALTER TABLE dbo.Categorias ADD TamanoTexto INT DEFAULT 14;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'ColumnasPOS')
  ALTER TABLE dbo.Categorias ADD ColumnasPOS INT DEFAULT 3;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'MostrarEnPOS')
  ALTER TABLE dbo.Categorias ADD MostrarEnPOS BIT DEFAULT 1;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Categorias') AND name = 'Imagen')
  ALTER TABLE dbo.Categorias ADD Imagen NVARCHAR(500) NULL;
GO

-- Agregar FK a si misma (jerarquia)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Categorias_Categorias')
BEGIN
  ALTER TABLE dbo.Categorias ADD CONSTRAINT FK_Categorias_Categorias
    FOREIGN KEY (IdCategoriaPadre) REFERENCES dbo.Categorias(IdCategoria);
END
GO

-- Agregar FK a Monedas
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Categorias_Monedas')
BEGIN
  ALTER TABLE dbo.Categorias ADD CONSTRAINT FK_Categorias_Monedas
    FOREIGN KEY (IdMoneda) REFERENCES dbo.Monedas(IdMoneda);
END
GO

PRINT 'Columnas de Categorias agregadas correctamente.';
GO
