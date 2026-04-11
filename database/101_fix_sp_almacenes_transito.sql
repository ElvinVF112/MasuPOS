USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spAlmacenesCRUD
    @Accion              CHAR(1),
    @IdAlmacen           INT            = NULL,
    @Descripcion         NVARCHAR(100)  = NULL,
    @Siglas              NVARCHAR(20)   = NULL,
    @TipoAlmacen         CHAR(1)        = NULL,
    @IdAlmacenTransito   INT            = NULL,
    @Activo              BIT            = NULL,
    @UsuarioCreacion     INT            = NULL,
    @UsuarioModificacion INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion IN ('I', 'A') AND ISNULL(@TipoAlmacen, 'O') <> 'T'
    BEGIN
        IF @IdAlmacenTransito IS NULL
            THROW 50041, 'El almacen de transito es obligatorio.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Almacenes
            WHERE IdAlmacen = @IdAlmacenTransito
              AND ISNULL(RowStatus, 1) = 1
              AND Activo = 1
              AND TipoAlmacen = 'T'
        )
            THROW 50042, 'El almacen de transito debe ser un almacen tipo T activo.', 1;
    END;

    IF @Accion = 'L'
    BEGIN
        SELECT
            A.IdAlmacen,
            A.Descripcion,
            A.Siglas,
            A.TipoAlmacen,
            A.IdAlmacenTransito,
            A.Activo,
            T.Descripcion AS NombreAlmacenTransito
        FROM dbo.Almacenes A
        LEFT JOIN dbo.Almacenes T ON T.IdAlmacen = A.IdAlmacenTransito
        WHERE ISNULL(A.RowStatus, 1) = 1
        ORDER BY A.Descripcion;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            A.IdAlmacen,
            A.Descripcion,
            A.Siglas,
            A.TipoAlmacen,
            A.IdAlmacenTransito,
            A.Activo,
            T.Descripcion AS NombreAlmacenTransito
        FROM dbo.Almacenes A
        LEFT JOIN dbo.Almacenes T ON T.IdAlmacen = A.IdAlmacenTransito
        WHERE A.IdAlmacen = @IdAlmacen;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.Almacenes
            WHERE Siglas = LTRIM(RTRIM(@Siglas))
              AND ISNULL(RowStatus, 1) = 1
        )
            THROW 50043, 'Ya existe un almacen con esas siglas.', 1;

        INSERT INTO dbo.Almacenes
            (Descripcion, Siglas, TipoAlmacen, IdAlmacenTransito, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (LTRIM(RTRIM(@Descripcion)), LTRIM(RTRIM(@Siglas)), ISNULL(@TipoAlmacen, 'O'), @IdAlmacenTransito, ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        EXEC dbo.spAlmacenesCRUD @Accion = 'O', @IdAlmacen = SCOPE_IDENTITY();
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Almacenes
        SET Descripcion = LTRIM(RTRIM(@Descripcion)),
            Siglas = LTRIM(RTRIM(@Siglas)),
            TipoAlmacen = ISNULL(@TipoAlmacen, TipoAlmacen),
            IdAlmacenTransito = CASE WHEN ISNULL(@TipoAlmacen, TipoAlmacen) = 'T' THEN NULL ELSE @IdAlmacenTransito END,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdAlmacen = @IdAlmacen
          AND ISNULL(RowStatus, 1) = 1;

        EXEC dbo.spAlmacenesCRUD @Accion = 'O', @IdAlmacen = @IdAlmacen;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Almacenes
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdAlmacen = @IdAlmacen;
        RETURN;
    END;

    THROW 50044, 'Accion no valida.', 1;
END;
GO
