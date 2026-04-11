SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spProductosCRUD
    @Accion char(1),
    @IdProducto int = null,
    @IdCategoria int = null,
    @IdTipoProducto int = null,
    @IdUnidadMedida int = null,
    @IdUnidadVenta int = null,
    @IdUnidadCompra int = null,
    @IdUnidadAlterna1 int = null,
    @IdUnidadAlterna2 int = null,
    @IdUnidadAlterna3 int = null,
    @Nombre nvarchar(150) = null,
    @Descripcion nvarchar(250) = null,
    @Precio decimal(10,2) = null,
    @Activo bit = null,
    @IdSesion bigint = 0,
    @TokenSesion nvarchar(200) = null,
    @UsuarioCreacion int = null,
    @UsuarioModificacion int = null
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT P.IdProducto,
               P.IdCategoria,
               C.Nombre AS Categoria,
               P.IdTipoProducto,
               TP.Nombre AS TipoProducto,
               P.IdUnidadMedida,
               UB.Nombre AS UnidadBase,
               UB.Abreviatura AS AbreviaturaUnidadBase,
               P.IdUnidadVenta,
               UV.Nombre AS UnidadVenta,
               UV.Abreviatura AS AbreviaturaUnidadVenta,
               P.IdUnidadCompra,
               UC.Nombre AS UnidadCompra,
               UC.Abreviatura AS AbreviaturaUnidadCompra,
               P.IdUnidadAlterna1,
               UA1.Nombre AS UnidadAlterna1,
               P.IdUnidadAlterna2,
               UA2.Nombre AS UnidadAlterna2,
               P.IdUnidadAlterna3,
               UA3.Nombre AS UnidadAlterna3,
               P.Nombre,
               P.Descripcion,
               P.Precio,
               P.Activo,
               P.FechaCreacion,
               P.RowStatus
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
        LEFT JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        WHERE P.RowStatus = 1
        ORDER BY P.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT P.IdProducto,
               P.IdCategoria,
               C.Nombre AS Categoria,
               P.IdTipoProducto,
               TP.Nombre AS TipoProducto,
               P.IdUnidadMedida,
               UB.Nombre AS UnidadBase,
               UB.Abreviatura AS AbreviaturaUnidadBase,
               P.IdUnidadVenta,
               UV.Nombre AS UnidadVenta,
               UV.Abreviatura AS AbreviaturaUnidadVenta,
               P.IdUnidadCompra,
               UC.Nombre AS UnidadCompra,
               UC.Abreviatura AS AbreviaturaUnidadCompra,
               P.IdUnidadAlterna1,
               UA1.Nombre AS UnidadAlterna1,
               P.IdUnidadAlterna2,
               UA2.Nombre AS UnidadAlterna2,
               P.IdUnidadAlterna3,
               UA3.Nombre AS UnidadAlterna3,
               P.Nombre,
               P.Descripcion,
               P.Precio,
               P.Activo,
               P.FechaCreacion,
               P.RowStatus,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
        LEFT JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        WHERE P.IdProducto = @IdProducto;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Productos
            (IdCategoria, IdTipoProducto, IdUnidadMedida, IdUnidadVenta, IdUnidadCompra, IdUnidadAlterna1, IdUnidadAlterna2, IdUnidadAlterna3, Nombre, Descripcion, Precio, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdCategoria, @IdTipoProducto, @IdUnidadMedida, ISNULL(@IdUnidadVenta, @IdUnidadMedida), ISNULL(@IdUnidadCompra, @IdUnidadMedida), @IdUnidadAlterna1, @IdUnidadAlterna2, @IdUnidadAlterna3,
             LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''), ISNULL(@Precio, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        DECLARE @IdProductoNuevo int;
        SET @IdProductoNuevo = SCOPE_IDENTITY();
        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProductoNuevo, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Productos
        SET IdCategoria = @IdCategoria,
            IdTipoProducto = @IdTipoProducto,
            IdUnidadMedida = @IdUnidadMedida,
            IdUnidadVenta = ISNULL(@IdUnidadVenta, @IdUnidadMedida),
            IdUnidadCompra = ISNULL(@IdUnidadCompra, @IdUnidadMedida),
            IdUnidadAlterna1 = @IdUnidadAlterna1,
            IdUnidadAlterna2 = @IdUnidadAlterna2,
            IdUnidadAlterna3 = @IdUnidadAlterna3,
            Nombre = LTRIM(RTRIM(@Nombre)),
            Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            Precio = ISNULL(@Precio, Precio),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdProducto = @IdProducto;

        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProducto, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Productos
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdProducto = @IdProducto;

        EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProducto, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO
