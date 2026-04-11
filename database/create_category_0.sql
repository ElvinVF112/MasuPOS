-- Crear categoría ID 0 para productos sin categoría
SET IDENTITY_INSERT dbo.Categorias ON;

INSERT INTO dbo.Categorias (IdCategoria, Nombre, Codigo, Descripcion, IdCategoriaPadre, Color, Icono, MostrarEnMenu, MostrarEnPOS, PermiteModificadores, Orden, RowStatus)
VALUES (0, 'Sin Categoría', 'SIN-CAT', 'Productos sin categoría asignada', NULL, '#6b7280', 'Archive', 0, 0, 0, 0, 1);

SET IDENTITY_INSERT dbo.Categorias OFF;
GO

-- Verificar
SELECT * FROM dbo.Categorias WHERE IdCategoria = 0;