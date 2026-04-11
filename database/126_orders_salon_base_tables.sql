-- ============================================================
-- Script: 126_orders_salon_base_tables.sql
-- Propósito: Crear las tablas base del módulo de Órdenes y Salón
--            que venían de V1 y nunca se crearon en V2.
--
--  Tablas (en orden de dependencias):
--   1. Areas
--   2. TiposRecurso
--   3. CategoriasRecurso   (dep: Areas, TiposRecurso)
--   4. Recursos            (dep: CategoriasRecurso)
--   5. EstadosOrden
--   6. Ordenes             (dep: Recursos, EstadosOrden)
--   7. OrdenesDetalle      (dep: Ordenes)
-- ============================================================

USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. Areas
-- ============================================================
IF OBJECT_ID('dbo.Areas', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Areas (
    IdArea              INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre              NVARCHAR(100) NOT NULL,
    Descripcion         NVARCHAR(250) NULL,
    Orden               INT           NOT NULL CONSTRAINT DF_Areas_Orden DEFAULT (0),
    Activo              BIT           NOT NULL CONSTRAINT DF_Areas_Activo DEFAULT (1),
    RowStatus           BIT           NOT NULL CONSTRAINT DF_Areas_RowStatus DEFAULT (1),
    FechaCreacion       DATETIME      NOT NULL CONSTRAINT DF_Areas_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT           NULL,
    FechaModificacion   DATETIME      NULL,
    UsuarioModificacion INT           NULL
  );
  PRINT 'Tabla Areas creada.';
END
ELSE
  PRINT 'Tabla Areas ya existe.';
GO

-- ============================================================
-- 2. TiposRecurso
-- ============================================================
IF OBJECT_ID('dbo.TiposRecurso', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.TiposRecurso (
    IdTipoRecurso       INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre              NVARCHAR(100) NOT NULL,
    Descripcion         NVARCHAR(250) NULL,
    Activo              BIT           NOT NULL CONSTRAINT DF_TiposRecurso_Activo DEFAULT (1),
    RowStatus           BIT           NOT NULL CONSTRAINT DF_TiposRecurso_RowStatus DEFAULT (1),
    FechaCreacion       DATETIME      NOT NULL CONSTRAINT DF_TiposRecurso_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT           NULL,
    FechaModificacion   DATETIME      NULL,
    UsuarioModificacion INT           NULL
  );
  PRINT 'Tabla TiposRecurso creada.';
END
ELSE
  PRINT 'Tabla TiposRecurso ya existe.';
GO

-- ============================================================
-- 3. CategoriasRecurso
-- ============================================================
IF OBJECT_ID('dbo.CategoriasRecurso', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.CategoriasRecurso (
    IdCategoriaRecurso  INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdTipoRecurso       INT           NULL,
    IdArea              INT           NULL,
    Nombre              NVARCHAR(100) NOT NULL,
    Descripcion         NVARCHAR(250) NULL,
    ColorTema           NVARCHAR(7)   NOT NULL CONSTRAINT DF_CategoriasRecurso_ColorTema DEFAULT ('#3b82f6'),
    FormaVisual         VARCHAR(20)   NOT NULL CONSTRAINT DF_CategoriasRecurso_FormaVisual DEFAULT ('square'),
    Activo              BIT           NOT NULL CONSTRAINT DF_CategoriasRecurso_Activo DEFAULT (1),
    RowStatus           BIT           NOT NULL CONSTRAINT DF_CategoriasRecurso_RowStatus DEFAULT (1),
    FechaCreacion       DATETIME      NOT NULL CONSTRAINT DF_CategoriasRecurso_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT           NULL,
    FechaModificacion   DATETIME      NULL,
    UsuarioModificacion INT           NULL,
    CONSTRAINT FK_CategoriasRecurso_Area       FOREIGN KEY (IdArea)         REFERENCES dbo.Areas(IdArea),
    CONSTRAINT FK_CategoriasRecurso_TipoRecurso FOREIGN KEY (IdTipoRecurso) REFERENCES dbo.TiposRecurso(IdTipoRecurso)
  );
  PRINT 'Tabla CategoriasRecurso creada.';
END
ELSE
  PRINT 'Tabla CategoriasRecurso ya existe.';
GO

-- ============================================================
-- 4. Recursos
-- ============================================================
IF OBJECT_ID('dbo.Recursos', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Recursos (
    IdRecurso               INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdCategoriaRecurso      INT           NOT NULL,
    Nombre                  NVARCHAR(100) NOT NULL,
    Estado                  VARCHAR(20)   NOT NULL CONSTRAINT DF_Recursos_Estado DEFAULT ('Libre'),
    CantidadSillas          INT           NOT NULL CONSTRAINT DF_Recursos_CantidadSillas DEFAULT (4),
    Activo                  BIT           NOT NULL CONSTRAINT DF_Recursos_Activo DEFAULT (1),
    IdUsuarioBloqueoOrdenes INT           NULL,
    FechaBloqueoOrdenes     DATETIME      NULL,
    RowStatus               BIT           NOT NULL CONSTRAINT DF_Recursos_RowStatus DEFAULT (1),
    FechaCreacion           DATETIME      NOT NULL CONSTRAINT DF_Recursos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion         INT           NULL,
    FechaModificacion       DATETIME      NULL,
    UsuarioModificacion     INT           NULL,
    CONSTRAINT FK_Recursos_CategoriaRecurso FOREIGN KEY (IdCategoriaRecurso) REFERENCES dbo.CategoriasRecurso(IdCategoriaRecurso)
  );
  PRINT 'Tabla Recursos creada.';
END
ELSE
  PRINT 'Tabla Recursos ya existe.';
GO

-- ============================================================
-- 5. EstadosOrden
-- ============================================================
IF OBJECT_ID('dbo.EstadosOrden', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.EstadosOrden (
    IdEstadoOrden       INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre              VARCHAR(50)   NOT NULL,
    Descripcion         VARCHAR(250)  NULL,
    PermiteEditar       BIT           NOT NULL CONSTRAINT DF_EstadosOrden_PermiteEditar DEFAULT (1),
    Activo              BIT           NOT NULL CONSTRAINT DF_EstadosOrden_Activo DEFAULT (1),
    RowStatus           BIT           NOT NULL CONSTRAINT DF_EstadosOrden_RowStatus DEFAULT (1),
    FechaCreacion       DATETIME      NOT NULL CONSTRAINT DF_EstadosOrden_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT           NULL,
    FechaModificacion   DATETIME      NULL,
    UsuarioModificacion INT           NULL
  );
  PRINT 'Tabla EstadosOrden creada.';
END
ELSE
  PRINT 'Tabla EstadosOrden ya existe.';
GO

-- Seed estados de orden
MERGE dbo.EstadosOrden AS target
USING (
  SELECT 'Abierta'           AS Nombre, 'Orden abierta y editable'             AS Descripcion, CAST(1 AS BIT) AS PermiteEditar
  UNION ALL SELECT 'En proceso',         'Orden en proceso de atencion',                       CAST(1 AS BIT)
  UNION ALL SELECT 'Cerrada',            'Orden cerrada comercialmente',                        CAST(0 AS BIT)
  UNION ALL SELECT 'Anulada',            'Orden anulada',                                       CAST(0 AS BIT)
  UNION ALL SELECT 'Reabierta',          'Orden reabierta despues del cierre',                  CAST(1 AS BIT)
  UNION ALL SELECT 'Cuenta solicitada',  'Cuenta solicitada por el cliente',                    CAST(1 AS BIT)
  UNION ALL SELECT 'Facturada',          'Orden facturada',                                     CAST(0 AS BIT)
) AS source ON target.Nombre = source.Nombre
WHEN MATCHED THEN UPDATE SET
  Descripcion   = source.Descripcion,
  PermiteEditar = source.PermiteEditar,
  Activo = 1, RowStatus = 1,
  FechaModificacion = GETDATE(), UsuarioModificacion = 1
WHEN NOT MATCHED THEN INSERT (Nombre, Descripcion, PermiteEditar, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (source.Nombre, source.Descripcion, source.PermiteEditar, 1, 1, GETDATE(), 1);
GO

-- ============================================================
-- 6. Ordenes
-- ============================================================
IF OBJECT_ID('dbo.Ordenes', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Ordenes (
    IdOrden             INT            IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NumeroOrden         VARCHAR(50)    NOT NULL,
    IdRecurso           INT            NOT NULL,
    IdEstadoOrden       INT            NOT NULL,
    IdUsuario           INT            NOT NULL,
    FechaOrden          DATETIME       NOT NULL CONSTRAINT DF_Ordenes_FechaOrden DEFAULT (GETDATE()),
    ReferenciaCliente   NVARCHAR(200)  NULL,
    Observaciones       NVARCHAR(500)  NULL,
    CantidadPersonas    INT            NOT NULL CONSTRAINT DF_Ordenes_CantidadPersonas DEFAULT (1),
    Subtotal            DECIMAL(18,4)  NOT NULL CONSTRAINT DF_Ordenes_Subtotal DEFAULT (0),
    Impuesto            DECIMAL(18,4)  NOT NULL CONSTRAINT DF_Ordenes_Impuesto DEFAULT (0),
    Total               DECIMAL(18,4)  NOT NULL CONSTRAINT DF_Ordenes_Total DEFAULT (0),
    FechaCierre         DATETIME       NULL,
    Activo              BIT            NOT NULL CONSTRAINT DF_Ordenes_Activo DEFAULT (1),
    RowStatus           BIT            NOT NULL CONSTRAINT DF_Ordenes_RowStatus DEFAULT (1),
    FechaCreacion       DATETIME       NOT NULL CONSTRAINT DF_Ordenes_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT            NULL,
    FechaModificacion   DATETIME       NULL,
    UsuarioModificacion INT            NULL,
    IdSesionCreacion    INT            NULL,
    IdSesionModif       INT            NULL,
    CONSTRAINT FK_Ordenes_Recurso     FOREIGN KEY (IdRecurso)    REFERENCES dbo.Recursos(IdRecurso),
    CONSTRAINT FK_Ordenes_EstadoOrden FOREIGN KEY (IdEstadoOrden) REFERENCES dbo.EstadosOrden(IdEstadoOrden)
  );
  PRINT 'Tabla Ordenes creada.';
END
ELSE
  PRINT 'Tabla Ordenes ya existe.';
GO

-- ============================================================
-- 7. OrdenesDetalle
-- ============================================================
IF OBJECT_ID('dbo.OrdenesDetalle', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdenesDetalle (
    IdOrdenDetalle          INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdOrden                 INT           NOT NULL,
    IdProducto              INT           NULL,
    IdUnidadMedida          INT           NULL,
    IdEstadoDetalleOrden    INT           NULL,
    Cantidad                DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenesDetalle_Cantidad DEFAULT (0),
    Unidades                INT           NOT NULL CONSTRAINT DF_OrdenesDetalle_Unidades DEFAULT (1),
    PrecioUnitario          DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenesDetalle_PrecioUnitario DEFAULT (0),
    PorcentajeImpuesto      DECIMAL(5,2)  NOT NULL CONSTRAINT DF_OrdenesDetalle_PctImpuesto DEFAULT (0),
    SubtotalLinea           DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenesDetalle_SubtotalLinea DEFAULT (0),
    MontoImpuesto           DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenesDetalle_MontoImpuesto DEFAULT (0),
    TotalLinea              DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenesDetalle_TotalLinea DEFAULT (0),
    ObservacionLinea        NVARCHAR(250) NULL,
    Activo                  BIT           NOT NULL CONSTRAINT DF_OrdenesDetalle_Activo DEFAULT (1),
    RowStatus               BIT           NOT NULL CONSTRAINT DF_OrdenesDetalle_RowStatus DEFAULT (1),
    FechaCreacion           DATETIME      NOT NULL CONSTRAINT DF_OrdenesDetalle_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion         INT           NULL,
    FechaModificacion       DATETIME      NULL,
    UsuarioModificacion     INT           NULL,
    CONSTRAINT FK_OrdenesDetalle_Orden FOREIGN KEY (IdOrden) REFERENCES dbo.Ordenes(IdOrden)
  );
  PRINT 'Tabla OrdenesDetalle creada.';
END
ELSE
  PRINT 'Tabla OrdenesDetalle ya existe.';
GO

-- ============================================================
-- Seed mínimo: 1 Área, 1 TipoRecurso, 1 CategoriaRecurso, 1 Recurso
-- Solo si las tablas están vacías
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Areas WHERE RowStatus = 1)
BEGIN
  INSERT INTO dbo.Areas (Nombre, Descripcion, Orden, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES ('Salon Principal', 'Area principal del salon', 1, 1, GETDATE(), 1);
  PRINT 'Seed: Area ''Salon Principal'' insertada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.TiposRecurso WHERE RowStatus = 1)
BEGIN
  INSERT INTO dbo.TiposRecurso (Nombre, Descripcion, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES ('Mesa', 'Mesa de salon', 1, GETDATE(), 1);
  PRINT 'Seed: TipoRecurso ''Mesa'' insertado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CategoriasRecurso WHERE RowStatus = 1)
BEGIN
  DECLARE @IdArea INT = (SELECT TOP 1 IdArea FROM dbo.Areas WHERE RowStatus = 1 ORDER BY IdArea);
  DECLARE @IdTipo INT = (SELECT TOP 1 IdTipoRecurso FROM dbo.TiposRecurso WHERE RowStatus = 1 ORDER BY IdTipoRecurso);
  INSERT INTO dbo.CategoriasRecurso (IdTipoRecurso, IdArea, Nombre, Descripcion, ColorTema, FormaVisual, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (@IdTipo, @IdArea, 'Mesas Salon', 'Mesas del salon principal', '#3b82f6', 'square', 1, GETDATE(), 1);
  PRINT 'Seed: CategoriaRecurso ''Mesas Salon'' insertada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Recursos WHERE RowStatus = 1)
BEGIN
  DECLARE @IdCat INT = (SELECT TOP 1 IdCategoriaRecurso FROM dbo.CategoriasRecurso WHERE RowStatus = 1 ORDER BY IdCategoriaRecurso);
  INSERT INTO dbo.Recursos (IdCategoriaRecurso, Nombre, Estado, CantidadSillas, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES (@IdCat, 'Mesa 1', 'Libre', 4, 1, GETDATE(), 1),
         (@IdCat, 'Mesa 2', 'Libre', 4, 1, GETDATE(), 1),
         (@IdCat, 'Mesa 3', 'Libre', 4, 1, GETDATE(), 1);
  PRINT 'Seed: 3 recursos (mesas) insertados.';
END
GO

PRINT 'Script 126_orders_salon_base_tables.sql ejecutado correctamente.';
GO
