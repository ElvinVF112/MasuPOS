-- =============================================
-- MASU POS - Módulo Catálogos
-- Tablas: Categorias, UnidadesMedida, TiposProducto, Productos
-- Ejecutar en orden
-- =============================================

-- =============================================
-- 1. Categorias
-- =============================================
CREATE TABLE dbo.Categorias
(
    IdCategoria   INT           NOT NULL IDENTITY(1,1),
    Nombre        NVARCHAR(100) NOT NULL,
    Descripcion   NVARCHAR(250)     NULL,
    Activo        BIT           NOT NULL CONSTRAINT DF_Categorias_Activo        DEFAULT 1,
    FechaCreacion DATETIME      NOT NULL CONSTRAINT DF_Categorias_FechaCreacion DEFAULT GETDATE(),

    CONSTRAINT PK_Categorias PRIMARY KEY (IdCategoria),
    CONSTRAINT UQ_Categorias_Nombre UNIQUE (Nombre)
);
GO

-- =============================================
-- 2. UnidadesMedida
-- =============================================
CREATE TABLE dbo.UnidadesMedida
(
    IdUnidadMedida INT           NOT NULL IDENTITY(1,1),
    Nombre         NVARCHAR(100) NOT NULL,
    Abreviatura    NVARCHAR(20)  NOT NULL,
    Activo         BIT           NOT NULL CONSTRAINT DF_UnidadesMedida_Activo        DEFAULT 1,
    FechaCreacion  DATETIME      NOT NULL CONSTRAINT DF_UnidadesMedida_FechaCreacion DEFAULT GETDATE(),

    CONSTRAINT PK_UnidadesMedida   PRIMARY KEY (IdUnidadMedida),
    CONSTRAINT UQ_UnidadesMedida_Nombre UNIQUE (Nombre)
);
GO

-- =============================================
-- 3. TiposProducto
-- =============================================
CREATE TABLE dbo.TiposProducto
(
    IdTipoProducto INT           NOT NULL IDENTITY(1,1),
    Nombre         NVARCHAR(100) NOT NULL,
    Descripcion    NVARCHAR(250)     NULL,
    Activo         BIT           NOT NULL CONSTRAINT DF_TiposProducto_Activo        DEFAULT 1,
    FechaCreacion  DATETIME      NOT NULL CONSTRAINT DF_TiposProducto_FechaCreacion DEFAULT GETDATE(),

    CONSTRAINT PK_TiposProducto PRIMARY KEY (IdTipoProducto),
    CONSTRAINT UQ_TiposProducto_Nombre UNIQUE (Nombre)
);
GO

-- =============================================
-- 4. Productos
-- =============================================
CREATE TABLE dbo.Productos
(
    IdProducto     INT            NOT NULL IDENTITY(1,1),
    IdCategoria    INT            NOT NULL,
    IdTipoProducto INT            NOT NULL,
    IdUnidadMedida INT            NOT NULL,
    Nombre         NVARCHAR(150)  NOT NULL,
    Descripcion    NVARCHAR(250)      NULL,
    Precio         DECIMAL(10, 2) NOT NULL CONSTRAINT DF_Productos_Precio DEFAULT 0,
    Activo         BIT            NOT NULL CONSTRAINT DF_Productos_Activo        DEFAULT 1,
    FechaCreacion  DATETIME       NOT NULL CONSTRAINT DF_Productos_FechaCreacion DEFAULT GETDATE(),

    CONSTRAINT PK_Productos          PRIMARY KEY (IdProducto),
    CONSTRAINT UQ_Productos_Nombre   UNIQUE (Nombre),
    CONSTRAINT FK_Productos_Categoria    FOREIGN KEY (IdCategoria)    REFERENCES dbo.Categorias    (IdCategoria),
    CONSTRAINT FK_Productos_TipoProducto FOREIGN KEY (IdTipoProducto) REFERENCES dbo.TiposProducto (IdTipoProducto),
    CONSTRAINT FK_Productos_UnidadMedida FOREIGN KEY (IdUnidadMedida) REFERENCES dbo.UnidadesMedida(IdUnidadMedida)
);
GO
