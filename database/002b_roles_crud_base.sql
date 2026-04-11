-- ============================================================
-- Script: 002b_roles_crud_base.sql
-- Propósito: Crear SP básico spRolesCRUD si no existe
-- (compatibilidad con scripts V2 que lo asumen)
-- ============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.spRolesCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spRolesCRUD;
GO

CREATE PROCEDURE dbo.spRolesCRUD
    @Accion CHAR(1) = 'L',        -- L=List, O=One, I=Insert, A=Update, D=Delete, X=Anulate
    @IdRol INT = NULL,
    @Nombre VARCHAR(200) = NULL,
    @Descripcion VARCHAR(500) = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        -- Listar roles activos
        SELECT IdRol, Nombre, Descripcion, Activo, RowStatus
        FROM dbo.Roles
        WHERE RowStatus = 1
        ORDER BY Nombre;
    END

    ELSE IF @Accion = 'O'
    BEGIN
        -- Obtener rol específico
        SELECT IdRol, Nombre, Descripcion, Activo, RowStatus
        FROM dbo.Roles
        WHERE IdRol = @IdRol;
    END

    ELSE IF @Accion = 'I'
    BEGIN
        -- Insertar rol
        INSERT INTO dbo.Roles (Nombre, Descripcion, Activo, RowStatus, UsuarioCreacion, FechaCreacion)
        VALUES (@Nombre, @Descripcion, ISNULL(@Activo, 1), 1, ISNULL(@IdSesion, 1), GETDATE());

        SELECT SCOPE_IDENTITY() AS IdRol;
    END

    ELSE IF @Accion = 'A'
    BEGIN
        -- Actualizar rol
        UPDATE dbo.Roles
        SET Nombre = ISNULL(@Nombre, Nombre),
            Descripcion = ISNULL(@Descripcion, Descripcion),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = ISNULL(@IdSesion, 1)
        WHERE IdRol = @IdRol;
    END

    ELSE IF @Accion = 'D' OR @Accion = 'X'
    BEGIN
        -- Marcar como inactivo (soft delete)
        UPDATE dbo.Roles
        SET RowStatus = 0,
            Activo = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = ISNULL(@IdSesion, 1)
        WHERE IdRol = @IdRol;
    END
END;
GO

PRINT 'SP spRolesCRUD creado correctamente';
GO
