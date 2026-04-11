SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.spCategoriasCRUD
    @Accion CHAR(1),
    @IdCategoria INT = NULL OUTPUT,
    @Nombre NVARCHAR(100) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @Codigo NVARCHAR(20) = NULL,
    @CodigoCorto NVARCHAR(10) = NULL,
    @NombreCorto NVARCHAR(30) = NULL,
    @IdCategoriaPadre INT = NULL,
    @IdMoneda INT = NULL,
    @ColorFondo NVARCHAR(7) = NULL,
    @ColorBoton NVARCHAR(7) = NULL,
    @ColorTexto NVARCHAR(7) = NULL,
    @TamanoTexto INT = NULL,
    @ColumnasPOS INT = NULL,
    @MostrarEnPOS BIT = NULL,
    @Imagen NVARCHAR(MAX) = NULL,
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
            C.IdCategoria,
            C.Nombre,
            C.Descripcion,
            C.Activo,
            C.FechaCreacion,
            C.RowStatus,
            CAST(NULL AS NVARCHAR(20)) AS Codigo,
            CAST(NULL AS NVARCHAR(10)) AS CodigoCorto,
            CAST(NULL AS NVARCHAR(30)) AS NombreCorto,
            CAST(NULL AS INT) AS IdCategoriaPadre,
            CAST(NULL AS INT) AS IdMoneda,
            C.ColorFondo,
            C.ColorBoton,
            C.ColorTexto,
            CAST(NULL AS INT) AS TamanoTexto,
            CAST(NULL AS INT) AS ColumnasPOS,
            CAST(1 AS BIT) AS MostrarEnPOS,
            CAST(NULL AS NVARCHAR(MAX)) AS Imagen,
            CAST(NULL AS NVARCHAR(100)) AS CategoriaPadreNombre,
            CAST(NULL AS NVARCHAR(10)) AS MonedaCodigo,
            CAST(NULL AS NVARCHAR(10)) AS MonedaSimbolo,
            0 AS TotalSubcategorias,
            (SELECT COUNT(*) FROM dbo.Productos P WHERE P.IdCategoria = C.IdCategoria AND ISNULL(P.RowStatus,1)=1) AS TotalProductos
        FROM dbo.Categorias C
        WHERE ISNULL(C.RowStatus,1)=1
        ORDER BY C.Nombre ASC;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            C.IdCategoria,
            C.Nombre,
            C.Descripcion,
            C.Activo,
            C.FechaCreacion,
            C.RowStatus,
            CAST(NULL AS NVARCHAR(20)) AS Codigo,
            CAST(NULL AS NVARCHAR(10)) AS CodigoCorto,
            CAST(NULL AS NVARCHAR(30)) AS NombreCorto,
            CAST(NULL AS INT) AS IdCategoriaPadre,
            CAST(NULL AS INT) AS IdMoneda,
            C.ColorFondo,
            C.ColorBoton,
            C.ColorTexto,
            CAST(NULL AS INT) AS TamanoTexto,
            CAST(NULL AS INT) AS ColumnasPOS,
            CAST(1 AS BIT) AS MostrarEnPOS,
            CAST(NULL AS NVARCHAR(MAX)) AS Imagen,
            CAST(NULL AS NVARCHAR(100)) AS CategoriaPadreNombre,
            CAST(NULL AS NVARCHAR(10)) AS MonedaCodigo,
            CAST(NULL AS NVARCHAR(10)) AS MonedaSimbolo,
            0 AS TotalSubcategorias,
            (SELECT COUNT(*) FROM dbo.Productos P WHERE P.IdCategoria = C.IdCategoria AND ISNULL(P.RowStatus,1)=1) AS TotalProductos
        FROM dbo.Categorias C
        WHERE C.IdCategoria = @IdCategoria AND ISNULL(C.RowStatus,1)=1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Categorias
        (
            Nombre, Descripcion, Activo, FechaCreacion, RowStatus, UsuarioCreacion,
            FechaModificacion, UsuarioModificacion, ColorFondo, ColorBoton, ColorTexto
        )
        VALUES
        (
            @Nombre, @Descripcion, ISNULL(@Activo,1), GETDATE(), 1, @UsuarioCreacion,
            GETDATE(), @UsuarioModificacion, @ColorFondo, @ColorBoton, @ColorTexto
        );

        SET @IdCategoria = SCOPE_IDENTITY();
    END;
    ELSE IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Categorias
        SET Nombre = ISNULL(@Nombre, Nombre),
            Descripcion = @Descripcion,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion,
            ColorFondo = COALESCE(@ColorFondo, ColorFondo),
            ColorBoton = COALESCE(@ColorBoton, ColorBoton),
            ColorTexto = COALESCE(@ColorTexto, ColorTexto)
        WHERE IdCategoria = @IdCategoria;
    END;
    ELSE IF @Accion = 'E'
    BEGIN
        UPDATE dbo.Categorias
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdCategoria = @IdCategoria;
        RETURN;
    END;

    SELECT
        C.IdCategoria,
        C.Nombre,
        C.Descripcion,
        C.Activo,
        C.FechaCreacion,
        C.RowStatus,
        CAST(NULL AS NVARCHAR(20)) AS Codigo,
        CAST(NULL AS NVARCHAR(10)) AS CodigoCorto,
        CAST(NULL AS NVARCHAR(30)) AS NombreCorto,
        CAST(NULL AS INT) AS IdCategoriaPadre,
        CAST(NULL AS INT) AS IdMoneda,
        C.ColorFondo,
        C.ColorBoton,
        C.ColorTexto,
        CAST(NULL AS INT) AS TamanoTexto,
        CAST(NULL AS INT) AS ColumnasPOS,
        CAST(1 AS BIT) AS MostrarEnPOS,
        CAST(NULL AS NVARCHAR(MAX)) AS Imagen,
        CAST(NULL AS NVARCHAR(100)) AS CategoriaPadreNombre,
        CAST(NULL AS NVARCHAR(10)) AS MonedaCodigo,
        CAST(NULL AS NVARCHAR(10)) AS MonedaSimbolo,
        0 AS TotalSubcategorias,
        (SELECT COUNT(*) FROM dbo.Productos P WHERE P.IdCategoria = C.IdCategoria AND ISNULL(P.RowStatus,1)=1) AS TotalProductos
    FROM dbo.Categorias C
    WHERE C.IdCategoria = @IdCategoria;
END
GO
