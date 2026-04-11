-- ============================================================
-- Script 43: SP búsqueda de productos con prioridad
-- Prioridad:
--   1) Codigo
--   2) Nombre (Descripcion funcional)
--   3) Descripcion (Referencia funcional)
--   4) Cualquiera de los 3
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spBuscarProductos
  @Busqueda NVARCHAR(150) = NULL,
  @Top INT = 80
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Q NVARCHAR(150) = LTRIM(RTRIM(ISNULL(@Busqueda, '')));
  DECLARE @Like NVARCHAR(170) = '%' + @Q + '%';
  SET @Top = CASE WHEN ISNULL(@Top, 0) <= 0 THEN 80 WHEN @Top > 300 THEN 300 ELSE @Top END;

  IF @Q = ''
  BEGIN
    SELECT TOP (@Top)
           P.IdProducto,
           ISNULL(P.Codigo, '') AS Codigo,
           P.Nombre,
           ISNULL(P.Descripcion, '') AS Descripcion,
           C.Nombre  AS Categoria,
           TP.Nombre AS TipoProducto,
           P.Activo,
           ISNULL((SELECT TOP 1 PP.Precio
                   FROM dbo.ProductoPrecios PP
                   INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                   WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                   ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
    WHERE P.RowStatus = 1
    ORDER BY P.Nombre;
    RETURN;
  END

  -- 1) Código primero (exacto o parcial)
  IF EXISTS (
    SELECT 1
    FROM dbo.Productos P
    WHERE P.RowStatus = 1
      AND (ISNULL(P.Codigo, '') = @Q OR ISNULL(P.Codigo, '') LIKE @Like)
  )
  BEGIN
    SELECT TOP (@Top)
           P.IdProducto,
           ISNULL(P.Codigo, '') AS Codigo,
           P.Nombre,
           ISNULL(P.Descripcion, '') AS Descripcion,
           C.Nombre  AS Categoria,
           TP.Nombre AS TipoProducto,
           P.Activo,
           ISNULL((SELECT TOP 1 PP.Precio
                   FROM dbo.ProductoPrecios PP
                   INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                   WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                   ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
    WHERE P.RowStatus = 1
      AND (ISNULL(P.Codigo, '') = @Q OR ISNULL(P.Codigo, '') LIKE @Like)
    ORDER BY CASE WHEN ISNULL(P.Codigo, '') = @Q THEN 0 ELSE 1 END, P.Nombre;
    RETURN;
  END

  -- 2) Nombre (Descripción funcional)
  IF EXISTS (
    SELECT 1
    FROM dbo.Productos P
    WHERE P.RowStatus = 1
      AND P.Nombre LIKE @Like
  )
  BEGIN
    SELECT TOP (@Top)
           P.IdProducto,
           ISNULL(P.Codigo, '') AS Codigo,
           P.Nombre,
           ISNULL(P.Descripcion, '') AS Descripcion,
           C.Nombre  AS Categoria,
           TP.Nombre AS TipoProducto,
           P.Activo,
           ISNULL((SELECT TOP 1 PP.Precio
                   FROM dbo.ProductoPrecios PP
                   INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                   WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                   ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
    WHERE P.RowStatus = 1
      AND P.Nombre LIKE @Like
    ORDER BY P.Nombre;
    RETURN;
  END

  -- 3) Descripción (Referencia funcional)
  IF EXISTS (
    SELECT 1
    FROM dbo.Productos P
    WHERE P.RowStatus = 1
      AND ISNULL(P.Descripcion, '') LIKE @Like
  )
  BEGIN
    SELECT TOP (@Top)
           P.IdProducto,
           ISNULL(P.Codigo, '') AS Codigo,
           P.Nombre,
           ISNULL(P.Descripcion, '') AS Descripcion,
           C.Nombre  AS Categoria,
           TP.Nombre AS TipoProducto,
           P.Activo,
           ISNULL((SELECT TOP 1 PP.Precio
                   FROM dbo.ProductoPrecios PP
                   INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                   WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                   ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
    WHERE P.RowStatus = 1
      AND ISNULL(P.Descripcion, '') LIKE @Like
    ORDER BY P.Nombre;
    RETURN;
  END

  -- 4) Fallback cualquiera de los 3
  SELECT TOP (@Top)
         P.IdProducto,
         ISNULL(P.Codigo, '') AS Codigo,
         P.Nombre,
         ISNULL(P.Descripcion, '') AS Descripcion,
         C.Nombre  AS Categoria,
         TP.Nombre AS TipoProducto,
         P.Activo,
         ISNULL((SELECT TOP 1 PP.Precio
                 FROM dbo.ProductoPrecios PP
                 INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
                 WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
                 ORDER BY LP.IdListaPrecio ASC), 0) AS Precio
  FROM dbo.Productos P
  INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
  INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
  WHERE P.RowStatus = 1
    AND (
      ISNULL(P.Codigo, '') LIKE @Like
      OR P.Nombre LIKE @Like
      OR ISNULL(P.Descripcion, '') LIKE @Like
    )
  ORDER BY P.Nombre;
END
GO

PRINT '=== Script 43 ejecutado correctamente ===';
GO
