SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRY
  BEGIN TRANSACTION;

  UPDATE dbo.Categorias
  SET
    ColorFondoItem = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#EAF6FF'
      WHEN N'Bebidas Calientes' THEN N'#FFF3E6'
      WHEN N'Cervezas' THEN N'#FFF8D9'
      WHEN N'Cocteles' THEN N'#FBEAFE'
      WHEN N'Comida Rapida' THEN N'#FFE7E2'
      WHEN N'Picaderas' THEN N'#FFEAF1'
      WHEN N'Platos Fuertes' THEN N'#EAF8EF'
      WHEN N'Postres' THEN N'#FFF5EA'
      WHEN N'Combos' THEN N'#EEF0FF'
      WHEN N'Extras y Salsas' THEN N'#EEF3F7'
      ELSE ColorFondoItem
    END,
    ColorBotonItem = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#B9E3FF'
      WHEN N'Bebidas Calientes' THEN N'#FFD8B5'
      WHEN N'Cervezas' THEN N'#F7E7A8'
      WHEN N'Cocteles' THEN N'#E8C4F6'
      WHEN N'Comida Rapida' THEN N'#FFC6BC'
      WHEN N'Picaderas' THEN N'#FFC8D8'
      WHEN N'Platos Fuertes' THEN N'#BEE7C8'
      WHEN N'Postres' THEN N'#FFD9B8'
      WHEN N'Combos' THEN N'#C9D2FF'
      WHEN N'Extras y Salsas' THEN N'#D2DCE5'
      ELSE ColorBotonItem
    END,
    ColorTextoItem = CASE Nombre
      WHEN N'Bebidas Frias' THEN N'#16324F'
      WHEN N'Bebidas Calientes' THEN N'#5A3418'
      WHEN N'Cervezas' THEN N'#5B4A12'
      WHEN N'Cocteles' THEN N'#5B2A68'
      WHEN N'Comida Rapida' THEN N'#6A2E24'
      WHEN N'Picaderas' THEN N'#6B2941'
      WHEN N'Platos Fuertes' THEN N'#214E34'
      WHEN N'Postres' THEN N'#6A4320'
      WHEN N'Combos' THEN N'#28356B'
      WHEN N'Extras y Salsas' THEN N'#334155'
      ELSE ColorTextoItem
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
