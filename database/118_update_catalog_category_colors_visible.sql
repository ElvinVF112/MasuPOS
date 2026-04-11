SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Categorias', 'ColorFondo') IS NULL
  ALTER TABLE dbo.Categorias ADD ColorFondo NVARCHAR(7) NULL;
GO
IF COL_LENGTH('dbo.Categorias', 'ColorBoton') IS NULL
  ALTER TABLE dbo.Categorias ADD ColorBoton NVARCHAR(7) NULL;
GO
IF COL_LENGTH('dbo.Categorias', 'ColorTexto') IS NULL
  ALTER TABLE dbo.Categorias ADD ColorTexto NVARCHAR(7) NULL;
GO

BEGIN TRY
  BEGIN TRANSACTION;

  UPDATE dbo.Categorias
  SET
    ColorFondo = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#DFF4FF'
      WHEN N'Bebidas Calientes' THEN N'#FFF1DC'
      WHEN N'Cervezas' THEN N'#FFF6C9'
      WHEN N'Cocteles' THEN N'#F8E4FF'
      WHEN N'Comida Rapida' THEN N'#FFE2D8'
      WHEN N'Picaderas' THEN N'#FFE4EE'
      WHEN N'Platos Fuertes' THEN N'#E2F5E8'
      WHEN N'Postres' THEN N'#FFF0E2'
      WHEN N'Combos' THEN N'#E6E9FF'
      WHEN N'Extras y Salsas' THEN N'#E7EEF5'
      ELSE ISNULL(ColorFondo, N'#EFF6FF')
    END,
    ColorBoton = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#8ED8FF'
      WHEN N'Bebidas Calientes' THEN N'#FFC78C'
      WHEN N'Cervezas' THEN N'#F0D96B'
      WHEN N'Cocteles' THEN N'#D9A7F5'
      WHEN N'Comida Rapida' THEN N'#FFB39F'
      WHEN N'Picaderas' THEN N'#FFB7CF'
      WHEN N'Platos Fuertes' THEN N'#9ED9AF'
      WHEN N'Postres' THEN N'#FFC89A'
      WHEN N'Combos' THEN N'#B9C3FF'
      WHEN N'Extras y Salsas' THEN N'#BED0E0'
      ELSE ISNULL(ColorBoton, N'#BFDBFE')
    END,
    ColorTexto = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#11405C'
      WHEN N'Bebidas Calientes' THEN N'#6A3814'
      WHEN N'Cervezas' THEN N'#675200'
      WHEN N'Cocteles' THEN N'#5F2674'
      WHEN N'Comida Rapida' THEN N'#7A261C'
      WHEN N'Picaderas' THEN N'#7A2145'
      WHEN N'Platos Fuertes' THEN N'#1E5931'
      WHEN N'Postres' THEN N'#7A4216'
      WHEN N'Combos' THEN N'#2D3F8C'
      WHEN N'Extras y Salsas' THEN N'#304355'
      ELSE ISNULL(ColorTexto, N'#0F172A')
    END,
    ColorFondoItem = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#DFF4FF'
      WHEN N'Bebidas Calientes' THEN N'#FFF1DC'
      WHEN N'Cervezas' THEN N'#FFF6C9'
      WHEN N'Cocteles' THEN N'#F8E4FF'
      WHEN N'Comida Rapida' THEN N'#FFE2D8'
      WHEN N'Picaderas' THEN N'#FFE4EE'
      WHEN N'Platos Fuertes' THEN N'#E2F5E8'
      WHEN N'Postres' THEN N'#FFF0E2'
      WHEN N'Combos' THEN N'#E6E9FF'
      WHEN N'Extras y Salsas' THEN N'#E7EEF5'
      ELSE ISNULL(ColorFondoItem, N'#EFF6FF')
    END,
    ColorBotonItem = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#8ED8FF'
      WHEN N'Bebidas Calientes' THEN N'#FFC78C'
      WHEN N'Cervezas' THEN N'#F0D96B'
      WHEN N'Cocteles' THEN N'#D9A7F5'
      WHEN N'Comida Rapida' THEN N'#FFB39F'
      WHEN N'Picaderas' THEN N'#FFB7CF'
      WHEN N'Platos Fuertes' THEN N'#9ED9AF'
      WHEN N'Postres' THEN N'#FFC89A'
      WHEN N'Combos' THEN N'#B9C3FF'
      WHEN N'Extras y Salsas' THEN N'#BED0E0'
      ELSE ISNULL(ColorBotonItem, N'#BFDBFE')
    END,
    ColorTextoItem = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#11405C'
      WHEN N'Bebidas Calientes' THEN N'#6A3814'
      WHEN N'Cervezas' THEN N'#675200'
      WHEN N'Cocteles' THEN N'#5F2674'
      WHEN N'Comida Rapida' THEN N'#7A261C'
      WHEN N'Picaderas' THEN N'#7A2145'
      WHEN N'Platos Fuertes' THEN N'#1E5931'
      WHEN N'Postres' THEN N'#7A4216'
      WHEN N'Combos' THEN N'#2D3F8C'
      WHEN N'Extras y Salsas' THEN N'#304355'
      ELSE ISNULL(ColorTextoItem, N'#0F172A')
    END,
    FechaModificacion = GETDATE(),
    UsuarioModificacion = 1
  WHERE RowStatus = 1
    AND Nombre IN (
      N'Bebidas Frias', N'Bebidas Calientes', N'Cervezas', N'Cocteles', N'Comida Rapida',
      N'Picaderas', N'Platos Fuertes', N'Postres', N'Combos', N'Extras y Salsas'
    );

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
  THROW;
END CATCH;
GO
