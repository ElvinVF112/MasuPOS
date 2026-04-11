-- ============================================================
-- Script 44: TAREA 33 - Existencias por Almacen
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 33.1 Tabla de limites por producto/almacen
IF OBJECT_ID('dbo.ProductoAlmacenesLimites', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ProductoAlmacenesLimites (
    IdProductoAlmacenLimite INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto              INT NOT NULL,
    IdAlmacen               INT NOT NULL,
    Minimo                  DECIMAL(18,4) NOT NULL DEFAULT 0,
    Maximo                  DECIMAL(18,4) NOT NULL DEFAULT 0,
    PuntoReorden            DECIMAL(18,4) NOT NULL DEFAULT 0,
    RowStatus               BIT NOT NULL DEFAULT 1,
    FechaCreacion           DATETIME DEFAULT GETDATE(),
    UsuarioCreacion         INT NULL,
    FechaModificacion       DATETIME NULL,
    UsuarioModificacion     INT NULL,
    CONSTRAINT UQ_ProductoAlmacenLimites UNIQUE (IdProducto, IdAlmacen),
    CONSTRAINT FK_PAL_Producto FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
    CONSTRAINT FK_PAL_Almacen  FOREIGN KEY (IdAlmacen)  REFERENCES dbo.Almacenes(IdAlmacen)
  );
END
GO

-- 33.2 SP CRUD limites
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

  IF @Accion = 'U'
  BEGIN
    IF EXISTS (
      SELECT 1 FROM dbo.ProductoAlmacenesLimites
      WHERE IdProducto = @IdProducto AND IdAlmacen = @IdAlmacen
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
      PuntoReorden
    FROM dbo.ProductoAlmacenesLimites
    WHERE IdProducto = @IdProducto
      AND IdAlmacen = @IdAlmacen;
    RETURN;
  END
END
GO

-- 33.3 SP existencias por almacen
CREATE OR ALTER PROCEDURE dbo.spProductoExistencias
  @IdProducto INT,
  @IdSesion INT = NULL,
  @TokenSesion NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    al.IdAlmacen,
    al.Descripcion AS NombreAlmacen,

    pal.Minimo,
    pal.Maximo,
    pal.PuntoReorden,

    CAST(ISNULL(pa.Cantidad, 0) AS DECIMAL(18,4)) AS Existencia,
    CAST(0 AS DECIMAL(18,4)) AS PendienteRecibir,
    CAST(0 AS DECIMAL(18,4)) AS PendienteEntregar,
    CAST(ISNULL(pa.Cantidad, 0) + ISNULL(pa.CantidadTransito, 0) AS DECIMAL(18,4)) AS ExistenciaReal,
    CAST(ISNULL(pa.CantidadReservada, 0) AS DECIMAL(18,4)) AS Reservado,
    CAST(ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0) AS DECIMAL(18,4)) AS DisponibleBase,

    p.IdUnidadVenta,
    uv.Nombre AS NombreUnidadVenta,
    uv.Abreviatura AS AbreviaturaUnidadVenta,

    p.IdUnidadAlterna1,
    ua1.Nombre AS NombreAlterna1,
    ua1.Abreviatura AS AbreviaturaAlterna1,
    ua1.BaseA AS BaseA1,
    ua1.BaseB AS BaseB1,
    CASE
      WHEN p.IdUnidadAlterna1 IS NULL THEN NULL
      WHEN ISNULL(ua1.BaseA, 0) <= 0 OR ISNULL(ua1.BaseB, 0) <= 0 THEN NULL
      ELSE FLOOR((ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0)) / (CAST(ua1.BaseA AS DECIMAL(18,6)) / NULLIF(CAST(ua1.BaseB AS DECIMAL(18,6)), 0)))
    END AS DisponibleAlterna1,

    p.IdUnidadAlterna2,
    ua2.Nombre AS NombreAlterna2,
    ua2.Abreviatura AS AbreviaturaAlterna2,
    ua2.BaseA AS BaseA2,
    ua2.BaseB AS BaseB2,
    CASE
      WHEN p.IdUnidadAlterna2 IS NULL THEN NULL
      WHEN ISNULL(ua2.BaseA, 0) <= 0 OR ISNULL(ua2.BaseB, 0) <= 0 THEN NULL
      ELSE FLOOR((ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0)) / (CAST(ua2.BaseA AS DECIMAL(18,6)) / NULLIF(CAST(ua2.BaseB AS DECIMAL(18,6)), 0)))
    END AS DisponibleAlterna2,

    p.IdUnidadAlterna3,
    ua3.Nombre AS NombreAlterna3,
    ua3.Abreviatura AS AbreviaturaAlterna3,
    ua3.BaseA AS BaseA3,
    ua3.BaseB AS BaseB3,
    CASE
      WHEN p.IdUnidadAlterna3 IS NULL THEN NULL
      WHEN ISNULL(ua3.BaseA, 0) <= 0 OR ISNULL(ua3.BaseB, 0) <= 0 THEN NULL
      ELSE FLOOR((ISNULL(pa.Cantidad, 0) - ISNULL(pa.CantidadReservada, 0)) / (CAST(ua3.BaseA AS DECIMAL(18,6)) / NULLIF(CAST(ua3.BaseB AS DECIMAL(18,6)), 0)))
    END AS DisponibleAlterna3
  FROM dbo.ProductoAlmacenes pa
  INNER JOIN dbo.Almacenes al ON al.IdAlmacen = pa.IdAlmacen
  INNER JOIN dbo.Productos p ON p.IdProducto = pa.IdProducto
  LEFT JOIN dbo.ProductoAlmacenesLimites pal
    ON pal.IdProducto = pa.IdProducto
   AND pal.IdAlmacen = pa.IdAlmacen
   AND pal.RowStatus = 1
  LEFT JOIN dbo.UnidadesMedida uv ON uv.IdUnidadMedida = p.IdUnidadVenta
  LEFT JOIN dbo.UnidadesMedida ua1 ON ua1.IdUnidadMedida = p.IdUnidadAlterna1
  LEFT JOIN dbo.UnidadesMedida ua2 ON ua2.IdUnidadMedida = p.IdUnidadAlterna2
  LEFT JOIN dbo.UnidadesMedida ua3 ON ua3.IdUnidadMedida = p.IdUnidadAlterna3
  WHERE pa.IdProducto = @IdProducto
    AND pa.RowStatus = 1
    AND ISNULL(al.RowStatus, 1) = 1
  ORDER BY al.Descripcion ASC;
END
GO

PRINT '=== Script 44 ejecutado correctamente ===';
GO
