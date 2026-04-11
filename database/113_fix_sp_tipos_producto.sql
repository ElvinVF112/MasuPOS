CREATE OR ALTER PROCEDURE dbo.spTiposProductoCRUD
    @Accion CHAR(1),
    @IdTipoProducto INT = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            TP.IdTipoProducto,
            TP.Nombre,
            TP.Descripcion,
            ISNULL(TP.Activo, 1) AS Activo,
            TP.FechaCreacion
        FROM dbo.TiposProducto TP
        WHERE ISNULL(TP.RowStatus, 1) = 1
        ORDER BY TP.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            TP.IdTipoProducto,
            TP.Nombre,
            TP.Descripcion,
            ISNULL(TP.Activo, 1) AS Activo,
            TP.FechaCreacion
        FROM dbo.TiposProducto TP
        WHERE TP.IdTipoProducto = @IdTipoProducto
          AND ISNULL(TP.RowStatus, 1) = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.TiposProducto
            WHERE Nombre = LTRIM(RTRIM(@Nombre))
              AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe un tipo de producto con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.TiposProducto (
            Nombre,
            Descripcion,
            Activo,
            FechaCreacion,
            UsuarioCreacion,
            RowStatus
        )
        VALUES (
            LTRIM(RTRIM(@Nombre)),
            LTRIM(RTRIM(ISNULL(@Descripcion, @Nombre))),
            ISNULL(@Activo, 1),
            GETDATE(),
            @UsuarioCreacion,
            1
        );

        DECLARE @NuevoId INT = SCOPE_IDENTITY();
        EXEC dbo.spTiposProductoCRUD @Accion = 'O', @IdTipoProducto = @NuevoId;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.TiposProducto
        SET Nombre = LTRIM(RTRIM(@Nombre)),
            Descripcion = LTRIM(RTRIM(ISNULL(@Descripcion, @Nombre))),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdTipoProducto = @IdTipoProducto
          AND ISNULL(RowStatus, 1) = 1;

        EXEC dbo.spTiposProductoCRUD @Accion = 'O', @IdTipoProducto = @IdTipoProducto;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.TiposProducto
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdTipoProducto = @IdTipoProducto;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, I, A o D.', 16, 1);
END;
