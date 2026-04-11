USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

DECLARE @IdPantalla INT;

SELECT TOP 1 @IdPantalla = IdPantalla
FROM dbo.Pantallas
WHERE RowStatus = 1
  AND Activo = 1
  AND Ruta IN ('/inventory/entries', '/inventory/exits')
ORDER BY CASE WHEN Ruta = '/inventory/entries' THEN 0 ELSE 1 END;

IF @IdPantalla IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'inventory.documents.history.view' AND RowStatus = 1)
  BEGIN
    INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (@IdPantalla, 'Ver historial de cambios', 'Permite visualizar historial de cambios del detalle de documentos de inventario.', 'inventory.documents.history.view', 1, 1, GETDATE(), 1);
    PRINT 'Permiso inventory.documents.history.view creado.';
  END

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
    WHERE RP.IdRol = 1
      AND P.Clave = 'inventory.documents.history.view'
      AND RP.RowStatus = 1
  )
  BEGIN
    INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    SELECT 1, P.IdPermiso, 1, 1, GETDATE(), 1
    FROM dbo.Permisos P
    WHERE P.Clave = 'inventory.documents.history.view' AND P.RowStatus = 1;
    PRINT 'Permiso inventory.documents.history.view asignado al rol administrador.';
  END
END
ELSE
BEGIN
  PRINT 'No se encontro pantalla de Inventario para asociar el permiso.';
END
GO
