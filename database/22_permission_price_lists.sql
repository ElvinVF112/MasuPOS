DECLARE @IdPantalla INT;
DECLARE @IdPermiso INT;

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/catalog/price-lists' AND RowStatus = 1)
BEGIN
    INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (5, 'Listas de Precios', '/config/catalog/price-lists', 'Catalog', 'PriceLists', 'tag', 5, 1, 1, GETDATE(), 1);
END

SELECT @IdPantalla = IdPantalla FROM dbo.Pantallas WHERE Ruta = '/config/catalog/price-lists' AND RowStatus = 1;
PRINT 'IdPantalla: ' + CAST(@IdPantalla AS NVARCHAR(10));

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla = @IdPantalla AND RowStatus = 1)
BEGIN
    INSERT INTO dbo.Permisos (IdPantalla, Nombre, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (@IdPantalla, 'Permiso Listas de Precios', 1, 1, GETDATE(), 1);
END

SELECT @IdPermiso = IdPermiso FROM dbo.Permisos WHERE IdPantalla = @IdPantalla AND RowStatus = 1;
PRINT 'IdPermiso: ' + CAST(@IdPermiso AS NVARCHAR(10));

IF NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol = 1 AND IdPermiso = @IdPermiso AND RowStatus = 1)
BEGIN
    INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (1, @IdPermiso, 1, 1, GETDATE(), 1);
END

PRINT 'Permiso asignado al rol admin (IdRol=1)';

SELECT p.Nombre AS Permiso, pa.Ruta, rp.IdRol, r.Nombre AS Rol
FROM dbo.Permisos p
JOIN dbo.Pantallas pa ON p.IdPantalla = pa.IdPantalla
JOIN dbo.RolesPermisos rp ON p.IdPermiso = rp.IdPermiso
JOIN dbo.Roles r ON rp.IdRol = r.IdRol
WHERE pa.Ruta = '/config/catalog/price-lists'
  AND p.RowStatus = 1
  AND rp.RowStatus = 1;
