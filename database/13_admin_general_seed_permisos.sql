SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @IdRolAdmin INT;
DECLARE @UsuarioSistema INT = 1;

SELECT TOP (1) @IdRolAdmin = R.IdRol
FROM dbo.Roles R
WHERE R.RowStatus = 1
  AND (
    R.IdRol = 1
    OR UPPER(LTRIM(RTRIM(R.Nombre))) IN (N'ADMIN', N'ADMINISTRADOR', N'ADMINISTRADOR GENERAL')
  )
ORDER BY CASE WHEN R.IdRol = 1 THEN 0 ELSE 1 END, R.IdRol;

IF @IdRolAdmin IS NULL
BEGIN
  RAISERROR('No se encontro Rol Administrador General.', 16, 1);
  RETURN;
END;

DECLARE @IdPantalla INT;
DECLARE @NombrePantalla NVARCHAR(120);
DECLARE @NombrePermiso NVARCHAR(220);

DECLARE curPantallas CURSOR LOCAL FAST_FORWARD FOR
SELECT P.IdPantalla, P.Nombre
FROM dbo.Pantallas P
WHERE P.RowStatus = 1
  AND P.Activo = 1
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.Permisos PE
    WHERE PE.IdPantalla = P.IdPantalla
      AND PE.RowStatus = 1
  )
ORDER BY P.IdPantalla;

OPEN curPantallas;
FETCH NEXT FROM curPantallas INTO @IdPantalla, @NombrePantalla;

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @NombrePermiso = N'Acceso Total - ' + ISNULL(@NombrePantalla, N'Pantalla');

  EXEC dbo.spPermisosCRUD
    @Accion = 'I',
    @IdPantalla = @IdPantalla,
    @Nombre = @NombrePermiso,
    @Descripcion = N'Permiso semilla para administrador general.',
    @pVer = 1,
    @pCrear = 1,
    @pEditar = 1,
    @pEliminar = 1,
    @pAprobar = 1,
    @pAnular = 1,
    @pImprimir = 1,
    @Activo = 1,
    @UsuarioCreacion = @UsuarioSistema,
    @IdSesion = NULL,
    @TokenSesion = NULL;

  FETCH NEXT FROM curPantallas INTO @IdPantalla, @NombrePantalla;
END;

CLOSE curPantallas;
DEALLOCATE curPantallas;

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
SELECT
  @IdRolAdmin,
  PE.IdPermiso,
  1,
  1,
  GETDATE(),
  @UsuarioSistema
FROM dbo.Permisos PE
WHERE PE.RowStatus = 1
  AND PE.Activo = 1
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = @IdRolAdmin
      AND RP.IdPermiso = PE.IdPermiso
      AND RP.RowStatus = 1
  );

UPDATE RP
SET
  RP.Activo = 1,
  RP.FechaModificacion = GETDATE(),
  RP.UsuarioModificacion = @UsuarioSistema
FROM dbo.RolesPermisos RP
WHERE RP.IdRol = @IdRolAdmin
  AND RP.RowStatus = 1
  AND ISNULL(RP.Activo, 0) = 0;

SELECT
  @IdRolAdmin AS IdRolAdmin,
  (SELECT COUNT(1) FROM dbo.Permisos WHERE RowStatus = 1 AND Activo = 1) AS PermisosActivos,
  (SELECT COUNT(1) FROM dbo.RolesPermisos WHERE IdRol = @IdRolAdmin AND RowStatus = 1 AND Activo = 1) AS PermisosAdminActivos;
GO
