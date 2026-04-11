SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Ordenes', 'ReferenciaCliente') IS NULL
BEGIN
    ALTER TABLE dbo.Ordenes ADD ReferenciaCliente VARCHAR(200) NULL;
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenesCRUD
    @Accion CHAR(1),
    @IdOrden INT = NULL,
    @IdRecurso INT = NULL,
    @IdEstadoOrden INT = NULL,
    @IdUsuario INT = NULL,
    @ReferenciaCliente VARCHAR(200) = NULL,
    @Observaciones VARCHAR(500) = NULL,
    @Activo BIT = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            O.IdOrden,
            O.NumeroOrden,
            O.IdRecurso,
            R.Nombre AS Recurso,
            O.IdEstadoOrden,
            E.Nombre AS EstadoOrden,
            O.IdUsuario,
            U.NombreUsuario,
            O.FechaOrden,
            O.ReferenciaCliente,
            O.Observaciones,
            O.Subtotal,
            O.Impuesto,
            O.Total,
            O.FechaCierre,
            O.Activo,
            O.RowStatus,
            O.FechaCreacion
        FROM dbo.Ordenes O
        INNER JOIN dbo.Recursos R ON R.IdRecurso = O.IdRecurso
        INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
        INNER JOIN dbo.Usuarios U ON U.IdUsuario = O.IdUsuario
        WHERE O.RowStatus = 1
        ORDER BY O.IdOrden DESC;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            O.IdOrden,
            O.NumeroOrden,
            O.IdRecurso,
            R.Nombre AS Recurso,
            O.IdEstadoOrden,
            E.Nombre AS EstadoOrden,
            O.IdUsuario,
            U.NombreUsuario,
            O.FechaOrden,
            O.ReferenciaCliente,
            O.Observaciones,
            O.Subtotal,
            O.Impuesto,
            O.Total,
            O.FechaCierre,
            O.Activo,
            O.RowStatus,
            O.FechaCreacion
        FROM dbo.Ordenes O
        INNER JOIN dbo.Recursos R ON R.IdRecurso = O.IdRecurso
        INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
        INNER JOIN dbo.Usuarios U ON U.IdUsuario = O.IdUsuario
        WHERE O.IdOrden = @IdOrden;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        DECLARE @IdEstadoAbierta INT;
        SELECT @IdEstadoAbierta = IdEstadoOrden FROM dbo.EstadosOrden WHERE Nombre = 'Abierta' AND RowStatus = 1;

        INSERT INTO dbo.Ordenes
            (NumeroOrden, IdRecurso, IdEstadoOrden, IdUsuario, FechaOrden, ReferenciaCliente, Observaciones, Subtotal, Impuesto, Total, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (
                'ORD-' + RIGHT('00000000' + CAST(ISNULL((SELECT MAX(IdOrden) + 1 FROM dbo.Ordenes), 1) AS VARCHAR(20)), 8),
                @IdRecurso,
                ISNULL(@IdEstadoOrden, @IdEstadoAbierta),
                @IdUsuario,
                GETDATE(),
                NULLIF(LTRIM(RTRIM(@ReferenciaCliente)), ''),
                NULLIF(LTRIM(RTRIM(@Observaciones)), ''),
                0,
                0,
                0,
                ISNULL(@Activo, 1),
                1,
                GETDATE(),
                @UsuarioCreacion
            );

        DECLARE @IdOrdenNueva INT;
        SET @IdOrdenNueva = SCOPE_IDENTITY();
        EXEC dbo.spOrdenesCRUD @Accion='O', @IdOrden=@IdOrdenNueva, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.Ordenes O
            INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
            WHERE O.IdOrden = @IdOrden AND E.PermiteEditar = 0
        )
        BEGIN
            RAISERROR('La orden no permite edicion.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.Ordenes
        SET
            IdRecurso = ISNULL(@IdRecurso, IdRecurso),
            IdEstadoOrden = ISNULL(@IdEstadoOrden, IdEstadoOrden),
            ReferenciaCliente = CASE WHEN @ReferenciaCliente IS NULL THEN ReferenciaCliente ELSE NULLIF(LTRIM(RTRIM(@ReferenciaCliente)), '') END,
            Observaciones = CASE WHEN @Observaciones IS NULL THEN Observaciones ELSE NULLIF(LTRIM(RTRIM(@Observaciones)), '') END,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdOrden = @IdOrden;

        EXEC dbo.spOrdenesCRUD @Accion='O', @IdOrden=@IdOrden, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Ordenes
        SET
            RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdOrden = @IdOrden;

        EXEC dbo.spOrdenesCRUD @Accion='O', @IdOrden=@IdOrden, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;
END;
GO
