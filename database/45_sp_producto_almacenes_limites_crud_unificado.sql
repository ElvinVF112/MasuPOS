-- ============================================================
-- Script 45: Unificar spProductoAlmacenesLimitesCRUD (L/O/I/A/D/U)
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spProductoAlmacenesLimitesCRUD
  @Accion NVARCHAR(1),
  @IdProducto INT = NULL,
  @IdAlmacen INT = NULL,
  @Minimo DECIMAL(18,4) = NULL,
  @Maximo DECIMAL(18,4) = NULL,
  @PuntoReorden DECIMAL(18,4) = NULL,
  @IdSesion INT = NULL,
  @TokenSesion NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: listado por producto (todos los almacenes asignados)
  IF @Accion = 'L'
  BEGIN
    SELECT
      al.IdAlmacen,
      al.Descripcion AS NombreAlmacen,
      pal.Minimo,
      pal.Maximo,
      pal.PuntoReorden
    FROM dbo.ProductoAlmacenes pa
    INNER JOIN dbo.Almacenes al ON al.IdAlmacen = pa.IdAlmacen
    LEFT JOIN dbo.ProductoAlmacenesLimites pal
      ON pal.IdProducto = pa.IdProducto
     AND pal.IdAlmacen = pa.IdAlmacen
     AND pal.RowStatus = 1
    WHERE pa.IdProducto = @IdProducto
      AND pa.RowStatus = 1
      AND ISNULL(al.RowStatus, 1) = 1
    ORDER BY al.Descripcion ASC;
    RETURN;
  END

  -- O: obtener una fila por IdProducto+IdAlmacen
  IF @Accion = 'O'
  BEGIN
    SELECT TOP 1
      pal.IdProducto,
      pal.IdAlmacen,
      pal.Minimo,
      pal.Maximo,
      pal.PuntoReorden,
      pal.RowStatus
    FROM dbo.ProductoAlmacenesLimites pal
    WHERE pal.IdProducto = @IdProducto
      AND pal.IdAlmacen = @IdAlmacen;
    RETURN;
  END

  -- I: insert
  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.ProductoAlmacenesLimites
    (
      IdProducto, IdAlmacen, Minimo, Maximo, PuntoReorden,
      RowStatus, FechaCreacion, UsuarioCreacion
    )
    VALUES
    (
      @IdProducto, @IdAlmacen, ISNULL(@Minimo, 0), ISNULL(@Maximo, 0), ISNULL(@PuntoReorden, 0),
      1, GETDATE(), @IdSesion
    );

    SELECT TOP 1
      IdProducto,
      IdAlmacen,
      Minimo,
      Maximo,
      PuntoReorden,
      RowStatus
    FROM dbo.ProductoAlmacenesLimites
    WHERE IdProducto = @IdProducto
      AND IdAlmacen = @IdAlmacen;
    RETURN;
  END

  -- A: update
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.ProductoAlmacenesLimites
    SET Minimo = ISNULL(@Minimo, 0),
        Maximo = ISNULL(@Maximo, 0),
        PuntoReorden = ISNULL(@PuntoReorden, 0),
        RowStatus = 1,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdSesion
    WHERE IdProducto = @IdProducto
      AND IdAlmacen = @IdAlmacen;

    SELECT TOP 1
      IdProducto,
      IdAlmacen,
      Minimo,
      Maximo,
      PuntoReorden,
      RowStatus
    FROM dbo.ProductoAlmacenesLimites
    WHERE IdProducto = @IdProducto
      AND IdAlmacen = @IdAlmacen;
    RETURN;
  END

  -- D: delete lógico
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.ProductoAlmacenesLimites
    SET RowStatus = 0,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdSesion
    WHERE IdProducto = @IdProducto
      AND IdAlmacen = @IdAlmacen;
    RETURN;
  END

  -- U: upsert (compatibilidad)
  IF @Accion = 'U'
  BEGIN
    IF EXISTS (
      SELECT 1
      FROM dbo.ProductoAlmacenesLimites
      WHERE IdProducto = @IdProducto
        AND IdAlmacen = @IdAlmacen
    )
    BEGIN
      UPDATE dbo.ProductoAlmacenesLimites
      SET Minimo = ISNULL(@Minimo, 0),
          Maximo = ISNULL(@Maximo, 0),
          PuntoReorden = ISNULL(@PuntoReorden, 0),
          RowStatus = 1,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdSesion
      WHERE IdProducto = @IdProducto
        AND IdAlmacen = @IdAlmacen;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.ProductoAlmacenesLimites
      (
        IdProducto, IdAlmacen, Minimo, Maximo, PuntoReorden,
        RowStatus, FechaCreacion, UsuarioCreacion
      )
      VALUES
      (
        @IdProducto, @IdAlmacen, ISNULL(@Minimo, 0), ISNULL(@Maximo, 0), ISNULL(@PuntoReorden, 0),
        1, GETDATE(), @IdSesion
      );
    END

    SELECT TOP 1
      IdProducto,
      IdAlmacen,
      Minimo,
      Maximo,
      PuntoReorden,
      RowStatus
    FROM dbo.ProductoAlmacenesLimites
    WHERE IdProducto = @IdProducto
      AND IdAlmacen = @IdAlmacen;
    RETURN;
  END
END
GO

PRINT '=== Script 45 ejecutado correctamente ===';
GO
