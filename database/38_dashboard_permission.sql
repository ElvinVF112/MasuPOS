-- ============================================================
-- Script 38: Dashboard permission seed
-- TAREA 32.2 - dashboard.view + asignacion admin
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @IdRolAdmin INT = 1;
DECLARE @IdPantallaDashboard INT;
DECLARE @IdPermisoDashboard INT;

SELECT TOP 1 @IdPantallaDashboard = P.IdPantalla
FROM dbo.Pantallas P
WHERE ISNULL(P.RowStatus, 1) = 1
  AND LOWER(LTRIM(RTRIM(P.Ruta))) IN ('/dashboard', '/');

IF @IdPantallaDashboard IS NULL
BEGIN
  SELECT TOP 1 @IdPantallaDashboard = P.IdPantalla
  FROM dbo.Pantallas P
  WHERE ISNULL(P.RowStatus, 1) = 1
    AND ISNULL(P.Activo, 1) = 1
  ORDER BY P.IdPantalla;
END

SELECT TOP 1 @IdPermisoDashboard = PE.IdPermiso
FROM dbo.Permisos PE
WHERE ISNULL(PE.RowStatus, 1) = 1
  AND LTRIM(RTRIM(ISNULL(PE.Clave, ''))) = 'dashboard.view';

IF @IdPermisoDashboard IS NULL
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (@IdPantallaDashboard, 'Dashboard', 'Ver dashboard principal', 'dashboard.view', 1, 1, GETDATE(), 1);

  SET @IdPermisoDashboard = SCOPE_IDENTITY();
END

IF @IdPermisoDashboard IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM dbo.RolesPermisos RP
     WHERE RP.IdRol = @IdRolAdmin
       AND RP.IdPermiso = @IdPermisoDashboard
       AND ISNULL(RP.RowStatus, 1) = 1
   )
BEGIN
  INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (@IdRolAdmin, @IdPermisoDashboard, 1, 1, GETDATE(), 1);
END
GO

PRINT '=== Script 38 ejecutado correctamente ===';
GO
