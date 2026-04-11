SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE IdCategoria = 0)
BEGIN
  SET IDENTITY_INSERT dbo.Categorias ON;

  INSERT INTO dbo.Categorias (
    IdCategoria,
    Nombre,
    Descripcion,
    Activo,
    FechaCreacion,
    RowStatus,
    UsuarioCreacion,
    FechaModificacion,
    UsuarioModificacion,
    ColorFondoItem,
    ColorBotonItem,
    ColorTextoItem
  )
  VALUES (
    0,
    N'Sin Categoria',
    N'Productos sin categoria asignada',
    1,
    GETDATE(),
    1,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  );

  SET IDENTITY_INSERT dbo.Categorias OFF;
END
GO

CREATE OR ALTER PROCEDURE dbo.spCategoriaProductos
  @Accion NVARCHAR(2),
  @IdCategoria INT = NULL,
  @IdProducto INT = NULL,
  @IdSesion INT = NULL,
  @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'LA'
  BEGIN
    SELECT
      P.IdProducto,
      P.Nombre,
      P.Activo,
      TP.Nombre AS TipoProducto
    FROM dbo.Productos P
    LEFT JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
    WHERE P.RowStatus = 1
      AND P.IdCategoria = @IdCategoria
    ORDER BY P.Nombre;
    RETURN;
  END

  IF @Accion = 'LD'
  BEGIN
    SELECT
      P.IdProducto,
      P.Nombre,
      P.Activo,
      TP.Nombre AS TipoProducto
    FROM dbo.Productos P
    LEFT JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
    WHERE P.RowStatus = 1
      AND ISNULL(P.IdCategoria, 0) <> @IdCategoria
    ORDER BY P.Nombre;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Productos
    SET
      IdCategoria = @IdCategoria,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = COALESCE(@TokenSesion, UsuarioModificacion)
    WHERE IdProducto = @IdProducto
      AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'Q'
  BEGIN
    UPDATE dbo.Productos
    SET
      IdCategoria = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = COALESCE(@TokenSesion, UsuarioModificacion)
    WHERE IdProducto = @IdProducto
      AND RowStatus = 1;
    RETURN;
  END
END
GO
