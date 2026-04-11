-- TAREA 24: Actualizar spCategoriasCRUD con campos POS y jerarquia
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
    @Imagen NVARCHAR(500) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- L: Listar todas (jerarquia completa)
    IF @Accion = 'L'
    BEGIN
        SELECT
            C.IdCategoria,
            C.Nombre,
            C.Descripcion,
            C.Activo,
            C.FechaCreacion,
            C.RowStatus,
            C.Codigo,
            C.CodigoCorto,
            C.NombreCorto,
            C.IdCategoriaPadre,
            C.IdMoneda,
            C.ColorFondo,
            C.ColorBoton,
            C.ColorTexto,
            C.TamanoTexto,
            C.ColumnasPOS,
            C.MostrarEnPOS,
            C.Imagen,
            CP.Nombre AS CategoriaPadreNombre,
            M.Codigo AS MonedaCodigo,
            M.Simbolo AS MonedaSimbolo,
            (SELECT COUNT(*) FROM dbo.Categorias WHERE IdCategoriaPadre = C.IdCategoria AND RowStatus = 1) AS TotalSubcategorias,
            (SELECT COUNT(*) FROM dbo.Productos WHERE IdCategoria = C.IdCategoria AND RowStatus = 1) AS TotalProductos
        FROM dbo.Categorias C
        LEFT JOIN dbo.Categorias CP ON C.IdCategoriaPadre = CP.IdCategoria AND CP.RowStatus = 1
        LEFT JOIN dbo.Monedas M ON C.IdMoneda = M.IdMoneda
        WHERE C.RowStatus = 1
        ORDER BY C.IdCategoriaPadre ASC, C.Nombre ASC;
        RETURN;
    END;

    -- O: Obtener una por ID
    IF @Accion = 'O'
    BEGIN
        IF ISNULL(@IdCategoria, 0) = 0
        BEGIN
            RAISERROR('Debe enviar @IdCategoria para la accion O.', 16, 1);
            RETURN;
        END;

        SELECT
            C.IdCategoria,
            C.Nombre,
            C.Descripcion,
            C.Activo,
            C.FechaCreacion,
            C.RowStatus,
            C.UsuarioCreacion,
            C.FechaModificacion,
            C.UsuarioModificacion,
            C.Codigo,
            C.CodigoCorto,
            C.NombreCorto,
            C.IdCategoriaPadre,
            C.IdMoneda,
            C.ColorFondo,
            C.ColorBoton,
            C.ColorTexto,
            C.TamanoTexto,
            C.ColumnasPOS,
            C.MostrarEnPOS,
            C.Imagen,
            CP.Nombre AS CategoriaPadreNombre,
            M.Codigo AS MonedaCodigo,
            M.Simbolo AS MonedaSimbolo
        FROM dbo.Categorias C
        LEFT JOIN dbo.Categorias CP ON C.IdCategoriaPadre = CP.IdCategoria AND CP.RowStatus = 1
        LEFT JOIN dbo.Monedas M ON C.IdMoneda = M.IdMoneda
        WHERE C.IdCategoria = @IdCategoria;
        RETURN;
    END;

    -- I: Insertar
    IF @Accion = 'I'
    BEGIN
        IF ISNULL(LTRIM(RTRIM(@Nombre)), '') = ''
        BEGIN
            RAISERROR('Debe enviar @Nombre.', 16, 1);
            RETURN;
        END;

        -- Evitar recursion circular
        IF @IdCategoriaPadre IS NOT NULL
        BEGIN
            DECLARE @Level INT = 0;
            DECLARE @CurrentParent INT = @IdCategoriaPadre;
            WHILE @CurrentParent IS NOT NULL AND @Level < 100
            BEGIN
                IF @CurrentParent = @IdCategoria
                BEGIN
                    RAISERROR('No se puede asignar una categoria como padre de si misma o de sus ancestros.', 16, 1);
                    RETURN;
                END;
                SELECT @CurrentParent = IdCategoriaPadre FROM dbo.Categorias WHERE IdCategoria = @CurrentParent;
                SET @Level = @Level + 1;
            END;
        END;

        INSERT INTO dbo.Categorias (
            Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion,
            Codigo, CodigoCorto, NombreCorto, IdCategoriaPadre, IdMoneda,
            ColorFondo, ColorBoton, ColorTexto, TamanoTexto, ColumnasPOS, MostrarEnPOS, Imagen
        )
        VALUES (
            LTRIM(RTRIM(@Nombre)),
            NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            ISNULL(@Activo, 1),
            1,
            GETDATE(),
            @UsuarioCreacion,
            NULLIF(LTRIM(RTRIM(@Codigo)), ''),
            NULLIF(LTRIM(RTRIM(@CodigoCorto)), ''),
            NULLIF(LTRIM(RTRIM(@NombreCorto)), ''),
            @IdCategoriaPadre,
            @IdMoneda,
            ISNULL(@ColorFondo, '#1e3a5f'),
            ISNULL(@ColorBoton, '#12467e'),
            ISNULL(@ColorTexto, '#ffffff'),
            ISNULL(@TamanoTexto, 14),
            ISNULL(@ColumnasPOS, 3),
            ISNULL(@MostrarEnPOS, 1),
            NULLIF(LTRIM(RTRIM(@Imagen)), '')
        );

        SELECT @IdCategoria = SCOPE_IDENTITY();

        SELECT
            C.IdCategoria,
            C.Nombre,
            C.Descripcion,
            C.Activo,
            C.FechaCreacion,
            C.RowStatus,
            C.Codigo,
            C.CodigoCorto,
            C.NombreCorto,
            C.IdCategoriaPadre,
            C.IdMoneda,
            C.ColorFondo,
            C.ColorBoton,
            C.ColorTexto,
            C.TamanoTexto,
            C.ColumnasPOS,
            C.MostrarEnPOS,
            C.Imagen
        FROM dbo.Categorias C
        WHERE C.IdCategoria = @IdCategoria;
        RETURN;
    END;

    -- A: Actualizar
    IF @Accion = 'A'
    BEGIN
        IF ISNULL(@IdCategoria, 0) = 0
        BEGIN
            RAISERROR('Debe enviar @IdCategoria.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE IdCategoria = @IdCategoria AND RowStatus = 1)
        BEGIN
            RAISERROR('La categoria no existe.', 16, 1);
            RETURN;
        END;

        -- Evitar recursion circular
        IF @IdCategoriaPadre IS NOT NULL
        BEGIN
            DECLARE @Lvl INT = 0;
            DECLARE @CurrParent INT = @IdCategoriaPadre;
            WHILE @CurrParent IS NOT NULL AND @Lvl < 100
            BEGIN
                IF @CurrParent = @IdCategoria
                BEGIN
                    RAISERROR('No se puede asignar una categoria como padre de si misma o de sus ancestros.', 16, 1);
                    RETURN;
                END;
                SELECT @CurrParent = IdCategoriaPadre FROM dbo.Categorias WHERE IdCategoria = @CurrParent;
                SET @Lvl = @Lvl + 1;
            END;
        END;

        UPDATE dbo.Categorias SET
            Nombre = LTRIM(RTRIM(ISNULL(@Nombre, Nombre))),
            Descripcion = NULLIF(LTRIM(RTRIM(ISNULL(@Descripcion, Descripcion))), ''),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion,
            Codigo = NULLIF(LTRIM(RTRIM(ISNULL(@Codigo, Codigo))), ''),
            CodigoCorto = NULLIF(LTRIM(RTRIM(ISNULL(@CodigoCorto, CodigoCorto))), ''),
            NombreCorto = NULLIF(LTRIM(RTRIM(ISNULL(@NombreCorto, NombreCorto))), ''),
            IdCategoriaPadre = @IdCategoriaPadre,
            IdMoneda = @IdMoneda,
            ColorFondo = ISNULL(@ColorFondo, ColorFondo),
            ColorBoton = ISNULL(@ColorBoton, ColorBoton),
            ColorTexto = ISNULL(@ColorTexto, ColorTexto),
            TamanoTexto = ISNULL(@TamanoTexto, TamanoTexto),
            ColumnasPOS = ISNULL(@ColumnasPOS, ColumnasPOS),
            MostrarEnPOS = ISNULL(@MostrarEnPOS, MostrarEnPOS),
            Imagen = NULLIF(LTRIM(RTRIM(ISNULL(@Imagen, Imagen))), '')
        WHERE IdCategoria = @IdCategoria;

        SELECT
            C.IdCategoria,
            C.Nombre,
            C.Descripcion,
            C.Activo,
            C.FechaCreacion,
            C.RowStatus,
            C.Codigo,
            C.CodigoCorto,
            C.NombreCorto,
            C.IdCategoriaPadre,
            C.IdMoneda,
            C.ColorFondo,
            C.ColorBoton,
            C.ColorTexto,
            C.TamanoTexto,
            C.ColumnasPOS,
            C.MostrarEnPOS,
            C.Imagen
        FROM dbo.Categorias C
        WHERE C.IdCategoria = @IdCategoria;
        RETURN;
    END;

    -- E: Eliminar (soft delete)
    IF @Accion = 'E'
    BEGIN
        IF ISNULL(@IdCategoria, 0) = 0
        BEGIN
            RAISERROR('Debe enviar @IdCategoria.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.Categorias WHERE IdCategoriaPadre = @IdCategoria AND RowStatus = 1)
        BEGIN
            RAISERROR('No se puede eliminar una categoria que tiene subcategorias.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.Productos WHERE IdCategoria = @IdCategoria AND RowStatus = 1)
        BEGIN
            RAISERROR('No se puede eliminar una categoria que tiene productos asociados.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.Categorias SET RowStatus = 0 WHERE IdCategoria = @IdCategoria;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, I, A o E.', 16, 1);
END;
GO

PRINT 'spCategoriasCRUD actualizado correctamente.';
GO
