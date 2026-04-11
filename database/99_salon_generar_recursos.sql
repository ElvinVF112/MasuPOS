SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.spRecursosGenerarMasivo
    @IdCategoriaRecurso INT,
    @Prefijo VARCHAR(40),
    @Cantidad INT,
    @NumeroInicial INT = 1,
    @CantidadSillas INT = 4,
    @Estado VARCHAR(20) = 'Libre',
    @UsuarioCreacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @IdCategoriaRecurso IS NULL OR @IdCategoriaRecurso <= 0
    BEGIN
        RAISERROR('Debes seleccionar una categoria valida.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.CategoriasRecurso
        WHERE IdCategoriaRecurso = @IdCategoriaRecurso
          AND RowStatus = 1
    )
    BEGIN
        RAISERROR('La categoria de recurso no existe o esta inactiva.', 16, 1);
        RETURN;
    END;

    IF @Cantidad IS NULL OR @Cantidad < 1
    BEGIN
        RAISERROR('La cantidad a generar debe ser mayor o igual a 1.', 16, 1);
        RETURN;
    END;

    IF @NumeroInicial IS NULL OR @NumeroInicial < 1
    BEGIN
        SET @NumeroInicial = 1;
    END;

    IF @CantidadSillas IS NULL OR @CantidadSillas < 1
    BEGIN
        SET @CantidadSillas = 4;
    END;

    SET @Prefijo = UPPER(LTRIM(RTRIM(ISNULL(@Prefijo, ''))));
    IF @Prefijo = ''
    BEGIN
        SET @Prefijo = 'MESA';
    END;

    DECLARE @Padding INT = LEN(CONVERT(VARCHAR(10), @NumeroInicial + @Cantidad - 1));
    IF @Padding < 2 SET @Padding = 2;

    DECLARE @Generados TABLE (
        Nombre VARCHAR(100) NOT NULL
    );

    INSERT INTO @Generados (Nombre)
    SELECT
        @Prefijo + '-' +
        RIGHT(REPLICATE('0', @Padding) + CONVERT(VARCHAR(10), @NumeroInicial + OffsetNumero), @Padding) AS Nombre
    FROM (
        SELECT TOP (@Cantidad)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS OffsetNumero
        FROM sys.all_objects
    ) N;

    IF EXISTS (
        SELECT 1
        FROM @Generados G
        INNER JOIN dbo.Recursos R
            ON R.Nombre = G.Nombre
           AND R.RowStatus = 1
    )
    BEGIN
        RAISERROR('Ya existe uno o mas recursos con ese prefijo y secuencia.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.Recursos
        (IdCategoriaRecurso, Nombre, Estado, CantidadSillas, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    SELECT
        @IdCategoriaRecurso,
        G.Nombre,
        ISNULL(NULLIF(LTRIM(RTRIM(@Estado)), ''), 'Libre'),
        @CantidadSillas,
        1,
        1,
        GETDATE(),
        @UsuarioCreacion
    FROM @Generados G;

    SELECT
        R.IdRecurso,
        R.IdCategoriaRecurso,
        R.Nombre,
        R.Estado,
        R.CantidadSillas,
        R.Activo,
        R.RowStatus,
        R.FechaCreacion
    FROM dbo.Recursos R
    WHERE R.IdCategoriaRecurso = @IdCategoriaRecurso
      AND R.Nombre LIKE @Prefijo + '-%'
      AND R.RowStatus = 1
    ORDER BY R.Nombre;
END;
GO
