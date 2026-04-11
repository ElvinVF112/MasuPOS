USE DbMasuPOS;
GO

PRINT '========================================';
PRINT '=== CREANDO STORED PROCEDURES ===';
PRINT '========================================';
SET NOCOUNT ON;
GO

------------------------------------------------------------
-- SP MÓDULOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spModulosCRUD') DROP PROCEDURE dbo.spModulosCRUD;
GO

CREATE PROCEDURE spModulosCRUD
    @Accion CHAR(1),
    @IdModulo INT = NULL OUTPUT,
    @Nombre NVARCHAR(100) = NULL,
    @Icono NVARCHAR(100) = NULL,
    @Orden INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdModulo, Nombre, Icono, Orden, Activo, RowEstatus, FechaCreacion FROM dbo.Modulos WHERE RowEstatus = 1 ORDER BY Orden;
    IF @Accion = 'O' SELECT IdModulo, Nombre, Icono, Orden, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Modulos WHERE IdModulo = @IdModulo;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Icono)), ''), ISNULL(@Orden, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdModulo = SCOPE_IDENTITY(); SELECT @IdModulo; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Modulos SET Nombre = LTRIM(RTRIM(@Nombre)), Icono = NULLIF(LTRIM(RTRIM(@Icono)), ''), Orden = ISNULL(@Orden, Orden), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdModulo = @IdModulo; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Modulos SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdModulo = @IdModulo; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Modulos SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdModulo = @IdModulo; END
END;
GO

------------------------------------------------------------
-- SP PANTALLAS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spPantallasCRUD') DROP PROCEDURE dbo.spPantallasCRUD;
GO

CREATE PROCEDURE spPantallasCRUD
    @Accion CHAR(1),
    @IdPantalla INT = NULL OUTPUT,
    @IdModulo INT = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Ruta NVARCHAR(200) = NULL,
    @Controlador NVARCHAR(100) = NULL,
    @AccionNombre NVARCHAR(100) = NULL,
    @Icono NVARCHAR(100) = NULL,
    @Orden INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT P.IdPantalla, P.IdModulo, M.Nombre AS ModuloNombre, P.Nombre, P.Ruta, P.Controlador, P.Accion, P.Icono, P.Orden, P.Activo, P.RowEstatus, P.FechaCreacion FROM dbo.Pantallas P INNER JOIN dbo.Modulos M ON P.IdModulo = M.IdModulo WHERE P.RowEstatus = 1 ORDER BY M.Orden, P.Orden;
    IF @Accion = 'O' SELECT IdPantalla, IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Pantallas WHERE IdPantalla = @IdPantalla;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdModulo, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Ruta)), ''), NULLIF(LTRIM(RTRIM(@Controlador)), ''), NULLIF(LTRIM(RTRIM(@AccionNombre)), ''), NULLIF(LTRIM(RTRIM(@Icono)), ''), ISNULL(@Orden, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdPantalla = SCOPE_IDENTITY(); SELECT @IdPantalla; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Pantallas SET IdModulo = @IdModulo, Nombre = LTRIM(RTRIM(@Nombre)), Ruta = NULLIF(LTRIM(RTRIM(@Ruta)), ''), Controlador = NULLIF(LTRIM(RTRIM(@Controlador)), ''), Accion = NULLIF(LTRIM(RTRIM(@AccionNombre)), ''), Icono = NULLIF(LTRIM(RTRIM(@Icono)), ''), Orden = ISNULL(@Orden, Orden), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdPantalla = @IdPantalla; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Pantallas SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdPantalla = @IdPantalla; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Pantallas SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdPantalla = @IdPantalla; END
END;
GO

------------------------------------------------------------
-- SP ROLES
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spRolesCRUD') DROP PROCEDURE dbo.spRolesCRUD;
GO

CREATE PROCEDURE spRolesCRUD
    @Accion CHAR(1),
    @IdRol INT = NULL OUTPUT,
    @Nombre NVARCHAR(100) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdRol, Nombre, Descripcion, Activo, RowEstatus, FechaCreacion FROM dbo.Roles WHERE RowEstatus = 1 ORDER BY Nombre;
    IF @Accion = 'O' SELECT IdRol, Nombre, Descripcion, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Roles WHERE IdRol = @IdRol;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Roles (Nombre, Descripcion, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdRol = SCOPE_IDENTITY(); SELECT @IdRol; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Roles SET Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRol = @IdRol; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Roles SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRol = @IdRol; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Roles SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRol = @IdRol; END
END;
GO

------------------------------------------------------------
-- SP USUARIOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spUsuariosCRUD') DROP PROCEDURE dbo.spUsuariosCRUD;
GO

CREATE PROCEDURE spUsuariosCRUD
    @Accion CHAR(1),
    @IdUsuario INT = NULL OUTPUT,
    @Nombres NVARCHAR(150) = NULL,
    @Apellidos NVARCHAR(150) = NULL,
    @NombreUsuario NVARCHAR(100) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @ClaveHash NVARCHAR(500) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdUsuario, Nombres, Apellidos, NombreUsuario, Correo, Activo, RowEstatus, FechaCreacion FROM dbo.Usuarios WHERE RowEstatus = 1 ORDER BY NombreUsuario;
    IF @Accion = 'O' SELECT IdUsuario, Nombres, Apellidos, NombreUsuario, Correo, ClaveHash, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Usuarios WHERE IdUsuario = @IdUsuario;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Usuarios (Nombres, Apellidos, NombreUsuario, Correo, ClaveHash, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombres)), LTRIM(RTRIM(@Apellidos)), LTRIM(RTRIM(@NombreUsuario)), NULLIF(LTRIM(RTRIM(@Correo)), ''), @ClaveHash, ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdUsuario = SCOPE_IDENTITY(); SELECT @IdUsuario; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Usuarios SET Nombres = LTRIM(RTRIM(@Nombres)), Apellidos = LTRIM(RTRIM(@Apellidos)), NombreUsuario = LTRIM(RTRIM(@NombreUsuario)), Correo = NULLIF(LTRIM(RTRIM(@Correo)), ''), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUsuario = @IdUsuario; IF @ClaveHash IS NOT NULL AND LEN(@ClaveHash) > 0 BEGIN UPDATE dbo.Usuarios SET ClaveHash = @ClaveHash WHERE IdUsuario = @IdUsuario; END END
    IF @Accion = 'E' BEGIN UPDATE dbo.Usuarios SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUsuario = @IdUsuario; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Usuarios SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUsuario = @IdUsuario; END
END;
GO

------------------------------------------------------------
-- SP PERMISOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spPermisosCRUD') DROP PROCEDURE dbo.spPermisosCRUD;
GO

CREATE PROCEDURE spPermisosCRUD
    @Accion CHAR(1),
    @IdPermiso INT = NULL OUTPUT,
    @IdPantalla INT = NULL,
    @Nombre NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @pVer BIT = NULL,
    @pCrear BIT = NULL,
    @pEditar BIT = NULL,
    @pEliminar BIT = NULL,
    @pAprobar BIT = NULL,
    @pAnular BIT = NULL,
    @pImprimir BIT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS PantallaNombre, P.Nombre, P.Descripcion, P.PuedeVer, P.PuedeCrear, P.PuedeEditar, P.PuedeEliminar, P.PuedeAprobar, P.PuedeAnular, P.PuedeImprimir, P.Activo, P.RowEstatus, P.FechaCreacion FROM dbo.Permisos P INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla WHERE P.RowEstatus = 1 ORDER BY PA.Nombre, P.Nombre;
    IF @Accion = 'O' SELECT IdPermiso, IdPantalla, Nombre, Descripcion, PuedeVer, PuedeCrear, PuedeEditar, PuedeEliminar, PuedeAprobar, PuedeAnular, PuedeImprimir, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Permisos WHERE IdPermiso = @IdPermiso;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, PuedeVer, PuedeCrear, PuedeEditar, PuedeEliminar, PuedeAprobar, PuedeAnular, PuedeImprimir, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdPantalla, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@pVer, 0), ISNULL(@pCrear, 0), ISNULL(@pEditar, 0), ISNULL(@pEliminar, 0), ISNULL(@pAprobar, 0), ISNULL(@pAnular, 0), ISNULL(@pImprimir, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdPermiso = SCOPE_IDENTITY(); SELECT @IdPermiso; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Permisos SET IdPantalla = @IdPantalla, Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), PuedeVer = ISNULL(@pVer, PuedeVer), PuedeCrear = ISNULL(@pCrear, PuedeCrear), PuedeEditar = ISNULL(@pEditar, PuedeEditar), PuedeEliminar = ISNULL(@pEliminar, PuedeEliminar), PuedeAprobar = ISNULL(@pAprobar, PuedeAprobar), PuedeAnular = ISNULL(@pAnular, PuedeAnular), PuedeImprimir = ISNULL(@pImprimir, PuedeImprimir), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdPermiso = @IdPermiso; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Permisos SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdPermiso = @IdPermiso; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Permisos SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdPermiso = @IdPermiso; END
END;
GO

------------------------------------------------------------
-- SP USUARIOS ROLES
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spUsuariosRolesCRUD') DROP PROCEDURE dbo.spUsuariosRolesCRUD;
GO

CREATE PROCEDURE spUsuariosRolesCRUD
    @Accion CHAR(1),
    @IdUsuarioRol INT = NULL OUTPUT,
    @IdUsuario INT = NULL,
    @IdRol INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT UR.IdUsuarioRol, UR.IdUsuario, U.NombreUsuario, UR.IdRol, R.Nombre AS RolNombre, UR.Activo, UR.RowEstatus, UR.FechaCreacion FROM dbo.UsuariosRoles UR INNER JOIN dbo.Usuarios U ON UR.IdUsuario = U.IdUsuario INNER JOIN dbo.Roles R ON UR.IdRol = R.IdRol WHERE UR.RowEstatus = 1 ORDER BY U.NombreUsuario, R.Nombre;
    IF @Accion = 'LU' SELECT UR.IdUsuarioRol, UR.IdUsuario, UR.IdRol, UR.Activo, UR.RowEstatus, UR.FechaCreacion FROM dbo.UsuariosRoles UR WHERE UR.IdUsuario = @IdUsuario AND UR.RowEstatus = 1;
    IF @Accion = 'O' SELECT IdUsuarioRol, IdUsuario, IdRol, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.UsuariosRoles WHERE IdUsuarioRol = @IdUsuarioRol;
    IF @Accion = 'I' BEGIN IF EXISTS (SELECT 1 FROM dbo.UsuariosRoles WHERE IdUsuario = @IdUsuario AND IdRol = @IdRol AND RowEstatus = 1) BEGIN RAISERROR('El usuario ya tiene este rol asignado.', 16, 1); RETURN; END INSERT INTO dbo.UsuariosRoles (IdUsuario, IdRol, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdUsuario, @IdRol, ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdUsuarioRol = SCOPE_IDENTITY(); SELECT @IdUsuarioRol; END
    IF @Accion = 'A' BEGIN UPDATE dbo.UsuariosRoles SET IdUsuario = @IdUsuario, IdRol = @IdRol, Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUsuarioRol = @IdUsuarioRol; END
    IF @Accion = 'E' BEGIN UPDATE dbo.UsuariosRoles SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUsuarioRol = @IdUsuarioRol; END
    IF @Accion = 'D' BEGIN UPDATE dbo.UsuariosRoles SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUsuarioRol = @IdUsuarioRol; END
END;
GO

------------------------------------------------------------
-- SP ROLES PERMISOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spRolesPermisosCRUD') DROP PROCEDURE dbo.spRolesPermisosCRUD;
GO

CREATE PROCEDURE spRolesPermisosCRUD
    @Accion CHAR(1),
    @IdRolPermiso INT = NULL OUTPUT,
    @IdRol INT = NULL,
    @IdPermiso INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS RolNombre, RP.IdPermiso, P.Nombre AS PermisoNombre, RP.Activo, RP.RowEstatus, RP.FechaCreacion FROM dbo.RolesPermisos RP INNER JOIN dbo.Roles R ON RP.IdRol = R.IdRol INNER JOIN dbo.Permisos P ON RP.IdPermiso = P.IdPermiso WHERE RP.RowEstatus = 1 ORDER BY R.Nombre, P.Nombre;
    IF @Accion = 'LR' SELECT RP.IdRolPermiso, RP.IdRol, RP.IdPermiso, RP.Activo, RP.RowEstatus, RP.FechaCreacion FROM dbo.RolesPermisos RP WHERE RP.IdRol = @IdRol AND RP.RowEstatus = 1;
    IF @Accion = 'O' SELECT IdRolPermiso, IdRol, IdPermiso, Activo, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.RolesPermisos WHERE IdRolPermiso = @IdRolPermiso;
    IF @Accion = 'I' BEGIN IF EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso AND RowEstatus = 1) BEGIN RAISERROR('El rol ya tiene este permiso asignado.', 16, 1); RETURN; END INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdRol, @IdPermiso, ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdRolPermiso = SCOPE_IDENTITY(); SELECT @IdRolPermiso; END
    IF @Accion = 'A' BEGIN UPDATE dbo.RolesPermisos SET IdRol = @IdRol, IdPermiso = @IdPermiso, Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRolPermiso = @IdRolPermiso; END
    IF @Accion = 'E' BEGIN UPDATE dbo.RolesPermisos SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRolPermiso = @IdRolPermiso; END
    IF @Accion = 'D' BEGIN UPDATE dbo.RolesPermisos SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRolPermiso = @IdRolPermiso; END
END;
GO

------------------------------------------------------------
-- SP CATEGORÍAS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spCategoriasCRUD') DROP PROCEDURE dbo.spCategoriasCRUD;
GO

CREATE PROCEDURE spCategoriasCRUD
    @Accion CHAR(1),
    @IdCategoria INT = NULL OUTPUT,
    @Nombre NVARCHAR(100) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdCategoria, Nombre, Descripcion, Activo, FechaCreacion, RowEstatus FROM dbo.Categorias WHERE RowEstatus = 1 ORDER BY Nombre;
    IF @Accion = 'O' SELECT IdCategoria, Nombre, Descripcion, Activo, FechaCreacion, RowEstatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Categorias WHERE IdCategoria = @IdCategoria;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdCategoria = SCOPE_IDENTITY(); SELECT @IdCategoria; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Categorias SET Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdCategoria = @IdCategoria; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Categorias SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdCategoria = @IdCategoria; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Categorias SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdCategoria = @IdCategoria; END
END;
GO

------------------------------------------------------------
-- SP TIPOS PRODUCTO
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spTiposProductoCRUD') DROP PROCEDURE dbo.spTiposProductoCRUD;
GO

CREATE PROCEDURE spTiposProductoCRUD
    @Accion CHAR(1),
    @IdTipoProducto INT = NULL OUTPUT,
    @Nombre NVARCHAR(100) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdTipoProducto, Nombre, Descripcion, Activo, FechaCreacion, RowEstatus FROM dbo.TiposProducto WHERE RowEstatus = 1 ORDER BY Nombre;
    IF @Accion = 'O' SELECT IdTipoProducto, Nombre, Descripcion, Activo, FechaCreacion, RowEstatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.TiposProducto WHERE IdTipoProducto = @IdTipoProducto;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.TiposProducto (Nombre, Descripcion, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdTipoProducto = SCOPE_IDENTITY(); SELECT @IdTipoProducto; END
    IF @Accion = 'A' BEGIN UPDATE dbo.TiposProducto SET Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdTipoProducto = @IdTipoProducto; END
    IF @Accion = 'E' BEGIN UPDATE dbo.TiposProducto SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdTipoProducto = @IdTipoProducto; END
    IF @Accion = 'D' BEGIN UPDATE dbo.TiposProducto SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdTipoProducto = @IdTipoProducto; END
END;
GO

------------------------------------------------------------
-- SP UNIDADES MEDIDA
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spUnidadesMedidaCRUD') DROP PROCEDURE dbo.spUnidadesMedidaCRUD;
GO

CREATE PROCEDURE spUnidadesMedidaCRUD
    @Accion CHAR(1),
    @IdUnidadMedida INT = NULL OUTPUT,
    @Nombre NVARCHAR(100) = NULL,
    @Abreviatura NVARCHAR(20) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdUnidadMedida, Nombre, Abreviatura, Activo, FechaCreacion, RowEstatus FROM dbo.UnidadesMedida WHERE RowEstatus = 1 ORDER BY Nombre;
    IF @Accion = 'O' SELECT IdUnidadMedida, Nombre, Abreviatura, Activo, FechaCreacion, RowEstatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.UnidadesMedida WHERE IdUnidadMedida = @IdUnidadMedida;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.UnidadesMedida (Nombre, Abreviatura, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), LTRIM(RTRIM(@Abreviatura)), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdUnidadMedida = SCOPE_IDENTITY(); SELECT @IdUnidadMedida; END
    IF @Accion = 'A' BEGIN UPDATE dbo.UnidadesMedida SET Nombre = LTRIM(RTRIM(@Nombre)), Abreviatura = LTRIM(RTRIM(@Abreviatura)), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUnidadMedida = @IdUnidadMedida; END
    IF @Accion = 'E' BEGIN UPDATE dbo.UnidadesMedida SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUnidadMedida = @IdUnidadMedida; END
    IF @Accion = 'D' BEGIN UPDATE dbo.UnidadesMedida SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdUnidadMedida = @IdUnidadMedida; END
END;
GO

------------------------------------------------------------
-- SP PRODUCTOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spProductosCRUD') DROP PROCEDURE dbo.spProductosCRUD;
GO

CREATE PROCEDURE spProductosCRUD
    @Accion CHAR(1),
    @IdProducto INT = NULL OUTPUT,
    @IdCategoria INT = NULL,
    @IdTipoProducto INT = NULL,
    @IdUnidadMedida INT = NULL,
    @Nombre NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Precio DECIMAL(10,2) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT P.IdProducto, P.IdCategoria, C.Nombre AS Categoria, P.IdTipoProducto, TP.Nombre AS TipoProducto, P.IdUnidadMedida, UM.Nombre AS UnidadMedida, UM.Abreviatura, P.Nombre, P.Descripcion, P.Precio, P.Activo, P.FechaCreacion, P.RowEstatus FROM dbo.Productos P INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto INNER JOIN dbo.UnidadesMedida UM ON UM.IdUnidadMedida = P.IdUnidadMedida WHERE P.RowEstatus = 1 ORDER BY P.Nombre;
    IF @Accion = 'O' SELECT P.IdProducto, P.IdCategoria, C.Nombre AS Categoria, P.IdTipoProducto, TP.Nombre AS TipoProducto, P.IdUnidadMedida, UM.Nombre AS UnidadMedida, UM.Abreviatura, P.Nombre, P.Descripcion, P.Precio, P.Activo, P.FechaCreacion, P.RowEstatus, P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion FROM dbo.Productos P INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto INNER JOIN dbo.UnidadesMedida UM ON UM.IdUnidadMedida = P.IdUnidadMedida WHERE P.IdProducto = @IdProducto;
    IF @Accion = 'I' BEGIN INSERT INTO dbo.Productos (IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio, Activo, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdCategoria, @IdTipoProducto, @IdUnidadMedida, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@Precio, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion); SET @IdProducto = SCOPE_IDENTITY(); SELECT @IdProducto; END
    IF @Accion = 'A' BEGIN UPDATE dbo.Productos SET IdCategoria = @IdCategoria, IdTipoProducto = @IdTipoProducto, IdUnidadMedida = @IdUnidadMedida, Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), Precio = ISNULL(@Precio, Precio), Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdProducto = @IdProducto; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Productos SET Activo = @Activo, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdProducto = @IdProducto; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Productos SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdProducto = @IdProducto; END
END;
GO

------------------------------------------------------------
-- SP ÁREAS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spAreasCRUD') DROP PROCEDURE dbo.spAreasCRUD;
GO

CREATE PROCEDURE spAreasCRUD
    @Accion CHAR(1),
    @IdArea INT = NULL OUTPUT,
    @Nombre VARCHAR(100) = NULL,
    @Descripcion VARCHAR(250) = NULL,
    @Orden INT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdArea, Nombre, Descripcion, Orden, RowEstatus, FechaCreacion FROM dbo.Areas WHERE RowEstatus = 1 ORDER BY Orden;
    IF @Accion = 'O' SELECT IdArea, Nombre, Descripcion, Orden, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Areas WHERE IdArea = @IdArea;
    IF @Accion = 'C' BEGIN INSERT INTO dbo.Areas (Nombre, Descripcion, Orden, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@Orden, 0), 1, GETDATE(), @UsuarioCreacion); SET @IdArea = SCOPE_IDENTITY(); SELECT @IdArea; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Areas SET Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), Orden = ISNULL(@Orden, Orden), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdArea = @IdArea; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Areas SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdArea = @IdArea; END
END;
GO

------------------------------------------------------------
-- SP TIPOS RECURSO
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spTiposRecursoCRUD') DROP PROCEDURE dbo.spTiposRecursoCRUD;
GO

CREATE PROCEDURE spTiposRecursoCRUD
    @Accion CHAR(1),
    @IdTipoRecurso INT = NULL OUTPUT,
    @Nombre VARCHAR(100) = NULL,
    @Descripcion VARCHAR(250) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT IdTipoRecurso, Nombre, Descripcion, RowEstatus, FechaCreacion FROM dbo.TiposRecurso WHERE RowEstatus = 1 ORDER BY Nombre;
    IF @Accion = 'O' SELECT IdTipoRecurso, Nombre, Descripcion, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.TiposRecurso WHERE IdTipoRecurso = @IdTipoRecurso;
    IF @Accion = 'C' BEGIN INSERT INTO dbo.TiposRecurso (Nombre, Descripcion, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), 1, GETDATE(), @UsuarioCreacion); SET @IdTipoRecurso = SCOPE_IDENTITY(); SELECT @IdTipoRecurso; END
    IF @Accion = 'E' BEGIN UPDATE dbo.TiposRecurso SET Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdTipoRecurso = @IdTipoRecurso; END
    IF @Accion = 'D' BEGIN UPDATE dbo.TiposRecurso SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdTipoRecurso = @IdTipoRecurso; END
END;
GO

------------------------------------------------------------
-- SP CATEGORÍAS RECURSO
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spCategoriasRecursoCRUD') DROP PROCEDURE dbo.spCategoriasRecursoCRUD;
GO

CREATE PROCEDURE spCategoriasRecursoCRUD
    @Accion CHAR(1),
    @IdCategoriaRecurso INT = NULL OUTPUT,
    @IdTipoRecurso INT = NULL,
    @IdArea INT = NULL,
    @Nombre VARCHAR(100) = NULL,
    @Descripcion VARCHAR(250) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT CR.IdCategoriaRecurso, CR.IdTipoRecurso, CR.IdArea, CR.Nombre, CR.Descripcion, CR.RowEstatus, CR.FechaCreacion FROM dbo.CategoriasRecurso CR WHERE CR.RowEstatus = 1 ORDER BY CR.Nombre;
    IF @Accion = 'O' SELECT IdCategoriaRecurso, IdTipoRecurso, IdArea, Nombre, Descripcion, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.CategoriasRecurso WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    IF @Accion = 'C' BEGIN INSERT INTO dbo.CategoriasRecurso (IdTipoRecurso, IdArea, Nombre, Descripcion, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdTipoRecurso, @IdArea, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), 1, GETDATE(), @UsuarioCreacion); SET @IdCategoriaRecurso = SCOPE_IDENTITY(); SELECT @IdCategoriaRecurso; END
    IF @Accion = 'E' BEGIN UPDATE dbo.CategoriasRecurso SET IdTipoRecurso = @IdTipoRecurso, IdArea = @IdArea, Nombre = LTRIM(RTRIM(@Nombre)), Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdCategoriaRecurso = @IdCategoriaRecurso; END
    IF @Accion = 'D' BEGIN UPDATE dbo.CategoriasRecurso SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdCategoriaRecurso = @IdCategoriaRecurso; END
END;
GO

------------------------------------------------------------
-- SP RECURSOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spRecursosCRUD') DROP PROCEDURE dbo.spRecursosCRUD;
GO

CREATE PROCEDURE spRecursosCRUD
    @Accion CHAR(1),
    @IdRecurso INT = NULL OUTPUT,
    @IdCategoriaRecurso INT = NULL,
    @Nombre VARCHAR(100) = NULL,
    @Estado VARCHAR(20) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L' SELECT R.IdRecurso, R.IdCategoriaRecurso, R.Nombre, R.Estado, R.RowEstatus, R.FechaCreacion FROM dbo.Recursos R WHERE R.RowEstatus = 1 ORDER BY R.Nombre;
    IF @Accion = 'LC' SELECT R.IdRecurso, R.IdCategoriaRecurso, R.Nombre, R.Estado, R.RowEstatus, R.FechaCreacion FROM dbo.Recursos R WHERE R.IdCategoriaRecurso = @IdCategoriaRecurso AND R.RowEstatus = 1 ORDER BY R.Nombre;
    IF @Accion = 'O' SELECT IdRecurso, IdCategoriaRecurso, Nombre, Estado, RowEstatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion FROM dbo.Recursos WHERE IdRecurso = @IdRecurso;
    IF @Accion = 'C' BEGIN INSERT INTO dbo.Recursos (IdCategoriaRecurso, Nombre, Estado, RowEstatus, FechaCreacion, UsuarioCreacion) VALUES (@IdCategoriaRecurso, LTRIM(RTRIM(@Nombre)), ISNULL(@Estado, 'Libre'), 1, GETDATE(), @UsuarioCreacion); SET @IdRecurso = SCOPE_IDENTITY(); SELECT @IdRecurso; END
    IF @Accion = 'E' BEGIN UPDATE dbo.Recursos SET IdCategoriaRecurso = @IdCategoriaRecurso, Nombre = LTRIM(RTRIM(@Nombre)), Estado = ISNULL(@Estado, Estado), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRecurso = @IdRecurso; END
    IF @Accion = 'CE' BEGIN UPDATE dbo.Recursos SET Estado = @Estado, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRecurso = @IdRecurso; END
    IF @Accion = 'D' BEGIN UPDATE dbo.Recursos SET RowEstatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion WHERE IdRecurso = @IdRecurso; END
END;
GO

------------------------------------------------------------
-- SP GENERAR RECURSOS
------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'spGenerarRecursos') DROP PROCEDURE dbo.spGenerarRecursos;
GO

CREATE PROCEDURE spGenerarRecursos
    @IdCategoriaRecurso INT,
    @Cantidad INT,
    @Prefijo VARCHAR(20),
    @UsuarioCreacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    WHILE @i <= @Cantidad
    BEGIN
        INSERT INTO dbo.Recursos (IdCategoriaRecurso, Nombre, Estado, RowEstatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdCategoriaRecurso, @Prefijo + RIGHT('00' + CAST(@i AS VARCHAR(10)), 2), 'Libre', 1, GETDATE(), @UsuarioCreacion);
        SET @i = @i + 1;
    END
END;
GO

PRINT '';
PRINT '========================================';
PRINT '=== TODOS LOS SP CREADOS ===';
PRINT '========================================';