USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

PRINT '=== Script 81: core de ordenes - tablas y estados base ===';
GO

IF OBJECT_ID('dbo.EstadosDetalleOrden', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.EstadosDetalleOrden (
    IdEstadoDetalleOrden INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    Descripcion VARCHAR(250) NULL,
    PermiteEditar BIT NOT NULL CONSTRAINT DF_EstadosDetalleOrden_PermiteEditar DEFAULT (1),
    Activo BIT NOT NULL CONSTRAINT DF_EstadosDetalleOrden_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_EstadosDetalleOrden_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_EstadosDetalleOrden_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL,
    FechaModificacion DATETIME NULL,
    UsuarioModificacion INT NULL
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_EstadosDetalleOrden_Nombre' AND object_id = OBJECT_ID('dbo.EstadosDetalleOrden'))
BEGIN
  CREATE UNIQUE INDEX UX_EstadosDetalleOrden_Nombre
    ON dbo.EstadosDetalleOrden (Nombre)
    WHERE RowStatus = 1;
END
GO

IF OBJECT_ID('dbo.OrdenesMovimientos', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdenesMovimientos (
    IdOrdenMovimiento INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdOrden INT NOT NULL,
    IdOrdenDetalle INT NULL,
    TipoMovimiento VARCHAR(50) NOT NULL,
    EstadoAnterior VARCHAR(50) NULL,
    EstadoNuevo VARCHAR(50) NULL,
    Observacion VARCHAR(500) NULL,
    FechaMovimiento DATETIME NOT NULL CONSTRAINT DF_OrdenesMovimientos_FechaMovimiento DEFAULT (GETDATE()),
    UsuarioMovimiento INT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_OrdenesMovimientos_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_OrdenesMovimientos_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_OrdenesMovimientos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrdenesMovimientos_Orden')
BEGIN
  ALTER TABLE dbo.OrdenesMovimientos
    ADD CONSTRAINT FK_OrdenesMovimientos_Orden
    FOREIGN KEY (IdOrden) REFERENCES dbo.Ordenes (IdOrden);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrdenesMovimientos_Detalle')
BEGIN
  ALTER TABLE dbo.OrdenesMovimientos
    ADD CONSTRAINT FK_OrdenesMovimientos_Detalle
    FOREIGN KEY (IdOrdenDetalle) REFERENCES dbo.OrdenesDetalle (IdOrdenDetalle);
END
GO

IF COL_LENGTH('dbo.OrdenesDetalle', 'IdEstadoDetalleOrden') IS NULL
BEGIN
  ALTER TABLE dbo.OrdenesDetalle ADD IdEstadoDetalleOrden INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrdenesDetalle_EstadoDetalleOrden')
BEGIN
  ALTER TABLE dbo.OrdenesDetalle
    ADD CONSTRAINT FK_OrdenesDetalle_EstadoDetalleOrden
    FOREIGN KEY (IdEstadoDetalleOrden) REFERENCES dbo.EstadosDetalleOrden (IdEstadoDetalleOrden);
END
GO

MERGE dbo.EstadosDetalleOrden AS target
USING (
  SELECT 'Pendiente' AS Nombre, 'Linea pendiente de preparacion o servicio' AS Descripcion, CAST(1 AS BIT) AS PermiteEditar
  UNION ALL SELECT 'En preparacion', 'Linea en preparacion', CAST(1 AS BIT)
  UNION ALL SELECT 'Servido', 'Linea servida', CAST(0 AS BIT)
  UNION ALL SELECT 'Cancelado', 'Linea cancelada', CAST(0 AS BIT)
) AS source
ON target.Nombre = source.Nombre
WHEN MATCHED THEN
  UPDATE SET
    Descripcion = source.Descripcion,
    PermiteEditar = source.PermiteEditar,
    Activo = 1,
    RowStatus = 1,
    FechaModificacion = GETDATE(),
    UsuarioModificacion = 1
WHEN NOT MATCHED THEN
  INSERT (Nombre, Descripcion, PermiteEditar, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (source.Nombre, source.Descripcion, source.PermiteEditar, 1, 1, GETDATE(), 1);
GO

MERGE dbo.EstadosOrden AS target
USING (
  SELECT 'Abierta' AS Nombre, 'Orden abierta y editable' AS Descripcion, CAST(1 AS BIT) AS PermiteEditar
  UNION ALL SELECT 'En proceso', 'Orden en proceso de atencion', CAST(1 AS BIT)
  UNION ALL SELECT 'Cerrada', 'Orden cerrada comercialmente', CAST(0 AS BIT)
  UNION ALL SELECT 'Anulada', 'Orden anulada', CAST(0 AS BIT)
  UNION ALL SELECT 'Reabierta', 'Orden reabierta despues del cierre', CAST(1 AS BIT)
  UNION ALL SELECT 'Cuenta solicitada', 'Cuenta solicitada por el cliente', CAST(1 AS BIT)
  UNION ALL SELECT 'Facturada', 'Orden facturada', CAST(0 AS BIT)
) AS source
ON target.Nombre = source.Nombre
WHEN MATCHED THEN
  UPDATE SET
    Descripcion = source.Descripcion,
    PermiteEditar = source.PermiteEditar,
    Activo = 1,
    RowStatus = 1,
    FechaModificacion = GETDATE(),
    UsuarioModificacion = 1
WHEN NOT MATCHED THEN
  INSERT (Nombre, Descripcion, PermiteEditar, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (source.Nombre, source.Descripcion, source.PermiteEditar, 1, 1, GETDATE(), 1);
GO

DECLARE @IdEstadoDetallePendiente INT = (
  SELECT TOP 1 IdEstadoDetalleOrden
  FROM dbo.EstadosDetalleOrden
  WHERE Nombre = 'Pendiente' AND RowStatus = 1
);

UPDATE dbo.OrdenesDetalle
SET IdEstadoDetalleOrden = @IdEstadoDetallePendiente
WHERE IdEstadoDetalleOrden IS NULL;
GO

PRINT '81_orders_core_tables.sql ejecutado correctamente.';
GO
