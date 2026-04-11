-- ============================================================
-- Script: 002d_sps_crud_basicos.sql
-- Propósito: Crear SPs CRUD básicos de V1 que faltan
-- (spUsuariosCRUD, spPermisosCRUD, spCategoriasCRUD, etc.)
-- ============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- spUsuariosCRUD
-- ============================================================

IF OBJECT_ID('dbo.spUsuariosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spUsuariosCRUD;
GO

CREATE PROCEDURE dbo.spUsuariosCRUD
    @Accion CHAR(1) = 'L',
    @IdUsuario INT = NULL,
    @IdRol INT = NULL,
    @Nombres NVARCHAR(150) = NULL,
    @Apellidos NVARCHAR(150) = NULL,
    @NombreUsuario NVARCHAR(100) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @ClaveHash NVARCHAR(500) = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT IdUsuario, NombreUsuario, CONCAT(Nombres, ' ', Apellidos) AS NombreCompleto,
               Correo, IdRol, Activo, RowStatus
        FROM dbo.Usuarios
        WHERE RowStatus = 1
        ORDER BY NombreUsuario;
    END
    ELSE IF @Accion = 'O'
    BEGIN
        SELECT IdUsuario, NombreUsuario, Nombres, Apellidos, Correo, IdRol, Activo, RowStatus
        FROM dbo.Usuarios
        WHERE IdUsuario = @IdUsuario;
    END
    ELSE IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Usuarios (IdRol, Nombres, Apellidos, NombreUsuario, Correo, ClaveHash, Activo, RowStatus, UsuarioCreacion)
        VALUES (@IdRol, @Nombres, @Apellidos, @NombreUsuario, @Correo, @ClaveHash, ISNULL(@Activo, 1), 1, ISNULL(@IdSesion, 1));

        SELECT SCOPE_IDENTITY() AS IdUsuario;
    END
    ELSE IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Usuarios
        SET Nombres = ISNULL(@Nombres, Nombres),
            Apellidos = ISNULL(@Apellidos, Apellidos),
            Correo = ISNULL(@Correo, Correo),
            IdRol = ISNULL(@IdRol, IdRol),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = ISNULL(@IdSesion, 1)
        WHERE IdUsuario = @IdUsuario;
    END
    ELSE IF @Accion = 'D' OR @Accion = 'X'
    BEGIN
        UPDATE dbo.Usuarios
        SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = ISNULL(@IdSesion, 1)
        WHERE IdUsuario = @IdUsuario;
    END
END;
GO

PRINT 'SP spUsuariosCRUD creado';
GO

-- ============================================================
-- spPermisosCRUD
-- ============================================================

IF OBJECT_ID('dbo.spPermisosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spPermisosCRUD;
GO

CREATE PROCEDURE dbo.spPermisosCRUD
    @Accion CHAR(1) = 'L',
    @IdPermiso INT = NULL,
    @IdPantalla INT = NULL,
    @Nombre VARCHAR(300) = NULL,
    @Descripcion VARCHAR(500) = NULL,
    @Clave NVARCHAR(100) = NULL,
    @PuedeVer BIT = NULL,
    @PuedeCrear BIT = NULL,
    @PuedeEditar BIT = NULL,
    @PuedeEliminar BIT = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT IdPermiso, IdPantalla, Nombre, Descripcion, Clave, PuedeVer, PuedeCrear, PuedeEditar, PuedeEliminar, Activo
        FROM dbo.Permisos
        WHERE RowStatus = 1
        ORDER BY IdPantalla, Nombre;
    END
    ELSE IF @Accion = 'O'
    BEGIN
        SELECT IdPermiso, IdPantalla, Nombre, Descripcion, Clave, PuedeVer, PuedeCrear, PuedeEditar, PuedeEliminar, Activo
        FROM dbo.Permisos
        WHERE IdPermiso = @IdPermiso;
    END
    ELSE IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, PuedeVer, PuedeCrear, PuedeEditar, PuedeEliminar, Activo, RowStatus, UsuarioCreacion)
        VALUES (@IdPantalla, @Nombre, @Descripcion, @Clave, ISNULL(@PuedeVer, 0), ISNULL(@PuedeCrear, 0), ISNULL(@PuedeEditar, 0), ISNULL(@PuedeEliminar, 0), ISNULL(@Activo, 1), 1, ISNULL(@IdSesion, 1));

        SELECT SCOPE_IDENTITY() AS IdPermiso;
    END
    ELSE IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Permisos
        SET Nombre = ISNULL(@Nombre, Nombre),
            Descripcion = ISNULL(@Descripcion, Descripcion),
            PuedeVer = ISNULL(@PuedeVer, PuedeVer),
            PuedeCrear = ISNULL(@PuedeCrear, PuedeCrear),
            PuedeEditar = ISNULL(@PuedeEditar, PuedeEditar),
            PuedeEliminar = ISNULL(@PuedeEliminar, PuedeEliminar),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = ISNULL(@IdSesion, 1)
        WHERE IdPermiso = @IdPermiso;
    END
END;
GO

PRINT 'SP spPermisosCRUD creado';
GO

-- ============================================================
-- spCategoriasCRUD
-- ============================================================

IF OBJECT_ID('dbo.spCategoriasCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spCategoriasCRUD;
GO

CREATE PROCEDURE dbo.spCategoriasCRUD
    @Accion CHAR(1) = 'L',
    @IdCategoria INT = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT IdCategoria, Nombre, Descripcion, Activo
        FROM dbo.Categorias
        WHERE Activo = 1
        ORDER BY Nombre;
    END
    ELSE IF @Accion = 'O'
    BEGIN
        SELECT IdCategoria, Nombre, Descripcion, Activo
        FROM dbo.Categorias
        WHERE IdCategoria = @IdCategoria;
    END
    ELSE IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Categorias (Nombre, Descripcion, Activo, FechaCreacion)
        VALUES (@Nombre, @Descripcion, ISNULL(@Activo, 1), GETDATE());

        SELECT SCOPE_IDENTITY() AS IdCategoria;
    END
    ELSE IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Categorias
        SET Nombre = ISNULL(@Nombre, Nombre),
            Descripcion = ISNULL(@Descripcion, Descripcion),
            Activo = ISNULL(@Activo, Activo)
        WHERE IdCategoria = @IdCategoria;
    END
END;
GO

PRINT 'SP spCategoriasCRUD creado';
GO

-- ============================================================
-- spProductosCRUD
-- ============================================================

IF OBJECT_ID('dbo.spProductosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spProductosCRUD;
GO

CREATE PROCEDURE dbo.spProductosCRUD
    @Accion CHAR(1) = 'L',
    @IdProducto INT = NULL,
    @IdCategoria INT = NULL,
    @IdTipoProducto INT = NULL,
    @IdUnidadMedida INT = NULL,
    @Nombre NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Precio DECIMAL(10, 2) = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT IdProducto, IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio, Activo
        FROM dbo.Productos
        WHERE Activo = 1
        ORDER BY Nombre;
    END
    ELSE IF @Accion = 'O'
    BEGIN
        SELECT IdProducto, IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio, Activo
        FROM dbo.Productos
        WHERE IdProducto = @IdProducto;
    END
    ELSE IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Productos (IdCategoria, IdTipoProducto, IdUnidadMedida, Nombre, Descripcion, Precio, Activo, FechaCreacion)
        VALUES (@IdCategoria, @IdTipoProducto, @IdUnidadMedida, @Nombre, @Descripcion, ISNULL(@Precio, 0), ISNULL(@Activo, 1), GETDATE());

        SELECT SCOPE_IDENTITY() AS IdProducto;
    END
    ELSE IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Productos
        SET IdCategoria = ISNULL(@IdCategoria, IdCategoria),
            IdTipoProducto = ISNULL(@IdTipoProducto, IdTipoProducto),
            IdUnidadMedida = ISNULL(@IdUnidadMedida, IdUnidadMedida),
            Nombre = ISNULL(@Nombre, Nombre),
            Descripcion = ISNULL(@Descripcion, Descripcion),
            Precio = ISNULL(@Precio, Precio),
            Activo = ISNULL(@Activo, Activo)
        WHERE IdProducto = @IdProducto;
    END
END;
GO

PRINT 'SP spProductosCRUD creado';
GO

PRINT '============================================================';
PRINT 'SPs CRUD básicos creados exitosamente';
PRINT '============================================================';
