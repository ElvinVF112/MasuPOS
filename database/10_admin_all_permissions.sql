SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @IdRolAdmin INT;
DECLARE @UsuarioSistema INT = TRY_CONVERT(INT, ISNULL(NULLIF(LTRIM(RTRIM('1')), ''), '1'));

SELECT TOP (1) @IdRolAdmin = R.IdRol
FROM dbo.Roles R
WHERE R.RowStatus = 1
  AND R.Activo = 1
  AND UPPER(LTRIM(RTRIM(R.Nombre))) IN (N'ADMIN', N'ADMINISTRADOR', N'ADMINISTRADOR GENERAL')
ORDER BY CASE WHEN UPPER(LTRIM(RTRIM(R.Nombre))) = N'ADMINISTRADOR' THEN 0 ELSE 1 END, R.IdRol;

IF @IdRolAdmin IS NULL
BEGIN
  RAISERROR('No se encontro un rol administrador activo (ADMIN/ADMINISTRADOR).', 16, 1);
  RETURN;
END;

DECLARE @IdPantalla INT;
DECLARE @NombrePantalla NVARCHAR(100);
DECLARE @NombrePermiso NVARCHAR(200);

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
  SET @NombrePermiso = N'Acceso Total - ' + ISNULL(@NombrePantalla, N'');

  EXEC dbo.spPermisosCRUD
    @Accion = 'I',
    @IdPantalla = @IdPantalla,
    @Nombre = @NombrePermiso,
    @Descripcion = N'Permiso autogenerado para cobertura completa del rol administrador.',
    @pVer = 1,
    @pCrear = 1,
    @pEditar = 1,
    @pEliminar = 1,
    @pAprobar = 1,
    @pAnular = 1,
    @pImprimir = 1,
    @Activo = 1,
    @UsuarioCreacion = @UsuarioSistema;

  FETCH NEXT FROM curPantallas INTO @IdPantalla, @NombrePantalla;
END;

CLOSE curPantallas;
DEALLOCATE curPantallas;

DECLARE @IdPermiso INT;

DECLARE curRolePerm CURSOR LOCAL FAST_FORWARD FOR
SELECT PE.IdPermiso
FROM dbo.Permisos PE
WHERE PE.RowStatus = 1
  AND PE.Activo = 1
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = @IdRolAdmin
      AND RP.IdPermiso = PE.IdPermiso
      AND RP.RowStatus = 1
  )
ORDER BY PE.IdPermiso;

OPEN curRolePerm;
FETCH NEXT FROM curRolePerm INTO @IdPermiso;

WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC dbo.spRolesPermisosCRUD
    @Accion = 'I',
    @IdRol = @IdRolAdmin,
    @IdPermiso = @IdPermiso,
    @Activo = 1,
    @UsuarioCreacion = @UsuarioSistema;

  FETCH NEXT FROM curRolePerm INTO @IdPermiso;
END;

CLOSE curRolePerm;
DEALLOCATE curRolePerm;

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
  (SELECT COUNT(1) FROM dbo.Pantallas WHERE RowStatus = 1 AND Activo = 1) AS PantallasActivas,
  (SELECT COUNT(1) FROM dbo.Permisos WHERE RowStatus = 1 AND Activo = 1) AS PermisosActivos,
  (SELECT COUNT(1) FROM dbo.RolesPermisos WHERE IdRol = @IdRolAdmin AND RowStatus = 1 AND Activo = 1) AS PermisosAsignadosAdmin;
GO
