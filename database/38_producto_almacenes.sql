-- =============================================
-- TAREA: Producto Almacenes + Existencia
-- Crea tabla ProductoAlmacenes (asignacion + stock)
-- y SP spProductoAlmacenesCRUD
-- =============================================

-- 1. Tabla ProductoAlmacenes
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'ProductoAlmacenes'
)
BEGIN
  CREATE TABLE dbo.ProductoAlmacenes (
    IdProductoAlmacen   INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto          INT NOT NULL REFERENCES dbo.Productos(IdProducto),
    IdAlmacen           INT NOT NULL REFERENCES dbo.Almacenes(IdAlmacen),
    Cantidad            DECIMAL(18,4) NOT NULL DEFAULT 0,
    CantidadReservada   DECIMAL(18,4) NOT NULL DEFAULT 0,
    CantidadTransito    DECIMAL(18,4) NOT NULL DEFAULT 0,
    RowStatus           BIT NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME DEFAULT GETDATE(),
    UsuarioCreacion     INT NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT NULL,
    CONSTRAINT UQ_ProductoAlmacen UNIQUE (IdProducto, IdAlmacen)
  );
END;
GO

-- 2. SP spProductoAlmacenesCRUD
-- Acciones:
--   LA  = Listar almacenes Asignados al producto
--   LD  = Listar almacenes Disponibles (no asignados)
--   A   = Asignar almacen al producto
--   Q   = Quitar almacen del producto (soft-delete)
--   U   = Actualizar cantidad de existencia en un almacen
CREATE OR ALTER PROCEDURE dbo.spProductoAlmacenesCRUD
  @Accion         NVARCHAR(2),
  @IdProducto     INT         = NULL,
  @IdAlmacen      INT         = NULL,
  @Cantidad       DECIMAL(18,4) = NULL,
  @IdSesion       INT         = NULL,
  @TokenSesion    NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- LA: Listar almacenes asignados al producto (con existencia)
  IF @Accion = 'LA'
  BEGIN
    SELECT
      PA.IdProductoAlmacen,
      PA.IdAlmacen,
      A.Descripcion         AS NombreAlmacen,
      A.Siglas,
      A.TipoAlmacen,
      PA.Cantidad,
      PA.CantidadReservada,
      PA.CantidadTransito,
      (PA.Cantidad - PA.CantidadReservada) AS CantidadDisponible
    FROM dbo.ProductoAlmacenes PA
    INNER JOIN dbo.Almacenes A ON A.IdAlmacen = PA.IdAlmacen
    WHERE PA.IdProducto = @IdProducto
      AND PA.RowStatus = 1
      AND A.RowStatus = 1
    ORDER BY A.Descripcion;
    RETURN;
  END;

  -- LD: Listar almacenes disponibles (activos no asignados al producto)
  IF @Accion = 'LD'
  BEGIN
    SELECT
      A.IdAlmacen,
      A.Descripcion AS NombreAlmacen,
      A.Siglas,
      A.TipoAlmacen
    FROM dbo.Almacenes A
    WHERE A.RowStatus = 1
      AND A.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.ProductoAlmacenes PA
        WHERE PA.IdProducto = @IdProducto
          AND PA.IdAlmacen  = A.IdAlmacen
          AND PA.RowStatus  = 1
      )
    ORDER BY A.Descripcion;
    RETURN;
  END;

  -- A: Asignar almacen al producto (INSERT o reactivar)
  IF @Accion = 'A'
  BEGIN
    IF EXISTS (
      SELECT 1 FROM dbo.ProductoAlmacenes
      WHERE IdProducto = @IdProducto AND IdAlmacen = @IdAlmacen
    )
    BEGIN
      UPDATE dbo.ProductoAlmacenes
      SET RowStatus = 1, FechaModificacion = GETDATE(), UsuarioModificacion = @IdSesion
      WHERE IdProducto = @IdProducto AND IdAlmacen = @IdAlmacen;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus, FechaCreacion, UsuarioCreacion)
      VALUES (@IdProducto, @IdAlmacen, 0, 0, 0, 1, GETDATE(), @IdSesion);
    END;
    RETURN;
  END;

  -- Q: Quitar almacen del producto (soft-delete)
  IF @Accion = 'Q'
  BEGIN
    UPDATE dbo.ProductoAlmacenes
    SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @IdSesion
    WHERE IdProducto = @IdProducto AND IdAlmacen = @IdAlmacen AND RowStatus = 1;
    RETURN;
  END;

  -- U: Actualizar cantidad de existencia
  IF @Accion = 'U'
  BEGIN
    UPDATE dbo.ProductoAlmacenes
    SET Cantidad = @Cantidad, FechaModificacion = GETDATE(), UsuarioModificacion = @IdSesion
    WHERE IdProducto = @IdProducto AND IdAlmacen = @IdAlmacen AND RowStatus = 1;
    RETURN;
  END;
END;
GO

PRINT 'Script 38_producto_almacenes.sql aplicado correctamente.';
