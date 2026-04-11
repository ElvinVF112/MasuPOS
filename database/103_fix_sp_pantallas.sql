USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
            P.FechaCreacion
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
            (@IdModulo, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Ruta)), ''), NULLIF(LTRIM(RTRIM(@Controlador)), ''), NULLIF(LTRIM(RTRIM(@AccionNombre)), ''), NULLIF(LTRIM(RTRIM(@Icono)), ''), ISNULL(@Orden, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

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
