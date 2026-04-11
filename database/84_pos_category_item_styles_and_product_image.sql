SET NOCOUNT ON;

IF COL_LENGTH('dbo.Categorias', 'ColorFondoItem') IS NULL
BEGIN
  ALTER TABLE dbo.Categorias ADD ColorFondoItem NVARCHAR(7) NULL;
END

IF COL_LENGTH('dbo.Categorias', 'ColorBotonItem') IS NULL
BEGIN
  ALTER TABLE dbo.Categorias ADD ColorBotonItem NVARCHAR(7) NULL;
END

IF COL_LENGTH('dbo.Categorias', 'ColorTextoItem') IS NULL
BEGIN
  ALTER TABLE dbo.Categorias ADD ColorTextoItem NVARCHAR(7) NULL;
END

UPDATE dbo.Categorias
SET
  ColorFondoItem = ISNULL(ColorFondoItem, ColorFondo),
  ColorBotonItem = ISNULL(ColorBotonItem, ColorBoton),
  ColorTextoItem = ISNULL(ColorTextoItem, ColorTexto)
WHERE
  ColorFondoItem IS NULL
  OR ColorBotonItem IS NULL
  OR ColorTextoItem IS NULL;

IF COL_LENGTH('dbo.Productos', 'Imagen') IS NULL
BEGIN
  ALTER TABLE dbo.Productos ADD Imagen NVARCHAR(500) NULL;
END
