USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   Seguridad - CRUD alineado con la app actual
   - spRolesCRUD
   - spPermisosCRUD
   - spModulosCRUD
   - spPantallasCRUD
   ============================================================ */

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

CREATE OR ALTER PROCEDURE dbo.spPermisosCRUD
    @Accion CHAR(1),
    @IdPermiso INT = NULL OUTPUT,
    @IdPantalla INT = NULL,
    @Nombre NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            P.IdPermiso,
            P.IdPantalla,
            PA.Nombre AS Pantalla,
            M.Nombre AS Modulo,
            P.Nombre,
            P.Descripcion,
            P.Activo,
            P.RowStatus,
            P.FechaCreacion,
            P.UsuarioCreacion,
            P.FechaModificacion,
            P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
        INNER JOIN dbo.Modulos M ON M.IdModulo = PA.IdModulo
        WHERE P.RowStatus = 1
        ORDER BY M.Orden, PA.Orden, P.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            P.IdPermiso,
            P.IdPantalla,
            PA.Nombre AS Pantalla,
            M.Nombre AS Modulo,
            P.Nombre,
            P.Descripcion,
            P.Activo,
            P.RowStatus,
            P.FechaCreacion,
            P.UsuarioCreacion,
            P.FechaModificacion,
            P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
        INNER JOIN dbo.Modulos M ON M.IdModulo = PA.IdModulo
        WHERE P.IdPermiso = @IdPermiso;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Permisos
            (IdPantalla, Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdPantalla,
             LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
             ISNULL(@Activo, 1),
             1,
             GETDATE(),
             COALESCE(@UsuarioCreacion, @IdSesion, 1));

        SET @IdPermiso = SCOPE_IDENTITY();
        EXEC dbo.spPermisosCRUD @Accion = 'O', @IdPermiso = @IdPermiso;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Permisos
        SET IdPantalla = @IdPantalla,
            Nombre = LTRIM(RTRIM(@Nombre)),
            Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioModificacion, @IdSesion, 1)
        WHERE IdPermiso = @IdPermiso
          AND RowStatus = 1;

        EXEC dbo.spPermisosCRUD @Accion = 'O', @IdPermiso = @IdPermiso;
        RETURN;
    END;

    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.Permisos
        SET Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioModificacion, @IdSesion, 1)
        WHERE IdPermiso = @IdPermiso
          AND RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Permisos
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = COALESCE(@UsuarioModificacion, @IdSesion, 1)
        WHERE IdPermiso = @IdPermiso
          AND RowStatus = 1;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A, E o D.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spModulosCRUD
    @Accion CHAR(1),
    @IdModulo INT = NULL OUTPUT,
    @Nombre VARCHAR(200) = NULL,
    @Icono VARCHAR(200) = NULL,
    @Orden INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            IdModulo,
            Nombre,
            Icono,
            Orden,
            Activo,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion,
            FechaModificacion,
            UsuarioModificacion
        FROM dbo.Modulos
        WHERE RowStatus = 1
        ORDER BY Orden, Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            IdModulo,
            Nombre,
            Icono,
            Orden,
            Activo,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion,
            FechaModificacion,
            UsuarioModificacion
        FROM dbo.Modulos
        WHERE IdModulo = @IdModulo;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Modulos
            (Nombre, Icono, Orden, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(@Icono)), ''),
             ISNULL(@Orden, 0),
             ISNULL(@Activo, 1),
             1,
             GETDATE(),
             @UsuarioCreacion);

        SET @IdModulo = SCOPE_IDENTITY();
        EXEC dbo.spModulosCRUD @Accion = 'O', @IdModulo = @IdModulo;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Modulos
        SET Nombre = LTRIM(RTRIM(@Nombre)),
            Icono = NULLIF(LTRIM(RTRIM(@Icono)), ''),
            Orden = ISNULL(@Orden, Orden),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdModulo = @IdModulo;

        EXEC dbo.spModulosCRUD @Accion = 'O', @IdModulo = @IdModulo;
        RETURN;
    END;

    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.Modulos
        SET Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdModulo = @IdModulo;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Modulos
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdModulo = @IdModulo;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spPantallasCRUD
    @Accion CHAR(1),
    @IdPantalla INT = NULL OUTPUT,
    @IdModulo INT = NULL,
    @Nombre VARCHAR(200) = NULL,
    @Ruta VARCHAR(400) = NULL,
    @Controlador VARCHAR(200) = NULL,
    @AccionNombre VARCHAR(200) = NULL,
    @Icono VARCHAR(200) = NULL,
    @Orden INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            P.IdPantalla,
            P.IdModulo,
            M.Nombre AS ModuloNombre,
            P.Nombre,
            P.Ruta,
            P.Controlador,
            P.AccionVista,
            P.Icono,
            P.Orden,
            P.Activo,
            P.RowStatus,
            P.FechaCreacion,
            P.UsuarioCreacion,
            P.FechaModificacion,
            P.UsuarioModificacion
        FROM dbo.Pantallas P
        INNER JOIN dbo.Modulos M ON M.IdModulo = P.IdModulo
        WHERE P.RowStatus = 1
        ORDER BY M.Orden, P.Orden, P.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            IdPantalla,
            IdModulo,
            Nombre,
            Ruta,
            Controlador,
            AccionVista,
            Icono,
            Orden,
            Activo,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion,
            FechaModificacion,
            UsuarioModificacion
        FROM dbo.Pantallas
        WHERE IdPantalla = @IdPantalla;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Pantallas
            (IdModulo, Nombre, Ruta, Controlador, AccionVista, Icono, Orden, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdModulo,
             LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(@Ruta)), ''),
             NULLIF(LTRIM(RTRIM(@Controlador)), ''),
             NULLIF(LTRIM(RTRIM(@AccionNombre)), ''),
             NULLIF(LTRIM(RTRIM(@Icono)), ''),
             ISNULL(@Orden, 0),
             ISNULL(@Activo, 1),
             1,
             GETDATE(),
             @UsuarioCreacion);

        SET @IdPantalla = SCOPE_IDENTITY();
        EXEC dbo.spPantallasCRUD @Accion = 'O', @IdPantalla = @IdPantalla;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Pantallas
        SET IdModulo = @IdModulo,
            Nombre = LTRIM(RTRIM(@Nombre)),
            Ruta = NULLIF(LTRIM(RTRIM(@Ruta)), ''),
            Controlador = NULLIF(LTRIM(RTRIM(@Controlador)), ''),
            AccionVista = NULLIF(LTRIM(RTRIM(@AccionNombre)), ''),
            Icono = NULLIF(LTRIM(RTRIM(@Icono)), ''),
            Orden = ISNULL(@Orden, Orden),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPantalla = @IdPantalla;

        EXEC dbo.spPantallasCRUD @Accion = 'O', @IdPantalla = @IdPantalla;
        RETURN;
    END;

    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.Pantallas
        SET Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPantalla = @IdPantalla;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Pantallas
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPantalla = @IdPantalla;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

