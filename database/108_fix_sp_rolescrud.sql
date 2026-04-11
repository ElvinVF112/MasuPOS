USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spRolesCRUD
    @Accion CHAR(1),
    @IdRol INT = NULL OUTPUT,
    @Nombre VARCHAR(200) = NULL,
    @Descripcion VARCHAR(500) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            R.IdRol,
            R.Nombre,
            R.Descripcion,
            R.Activo,
            R.RowStatus,
            R.FechaCreacion,
            R.UsuarioCreacion,
            R.FechaModificacion,
            R.UsuarioModificacion
        FROM dbo.Roles R
        WHERE R.RowStatus = 1
        ORDER BY R.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            R.IdRol,
            R.Nombre,
            R.Descripcion,
            R.Activo,
            R.RowStatus,
            R.FechaCreacion,
            R.UsuarioCreacion,
            R.FechaModificacion,
            R.UsuarioModificacion
        FROM dbo.Roles R
        WHERE R.IdRol = @IdRol;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Roles
            (Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
             ISNULL(@Activo, 1),
             1,
             GETDATE(),
             COALESCE(@UsuarioCreacion, @IdSesion, 1));

        SET @IdRol = SCOPE_IDENTITY();
        EXEC dbo.spRolesCRUD @Accion = 'O', @IdRol = @IdRol;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Roles
        SET Nombre = LTRIM(RTRIM(@Nombre)),
            Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioModificacion, @IdSesion, 1)
        WHERE IdRol = @IdRol;

        EXEC dbo.spRolesCRUD @Accion = 'O', @IdRol = @IdRol;
        RETURN;
    END;

    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.Roles
        SET Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioModificacion, @IdSesion, 1)
        WHERE IdRol = @IdRol;
        RETURN;
    END;

    IF @Accion IN ('D', 'X')
    BEGIN
        UPDATE dbo.Roles
        SET RowStatus = 0,
            Activo = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioModificacion, @IdSesion, 1)
        WHERE IdRol = @IdRol;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

