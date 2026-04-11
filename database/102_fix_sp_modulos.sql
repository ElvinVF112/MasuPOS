USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
            FechaCreacion
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
            (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Icono)), ''), ISNULL(@Orden, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

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
