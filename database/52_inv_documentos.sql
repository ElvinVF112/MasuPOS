-- ============================================================
-- Tablas para Documentos de Inventario (Cabecera + Detalle)
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- 1. TABLA: InvDocumentos (Cabecera)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InvDocumentos' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.InvDocumentos (
    IdDocumento         INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_InvDocumentos PRIMARY KEY,
    IdTipoDocumento     INT            NOT NULL CONSTRAINT FK_InvDocumentos_TipoDoc FOREIGN KEY REFERENCES dbo.InvTiposDocumento(IdTipoDocumento),
    TipoOperacion       CHAR(1)        NOT NULL CONSTRAINT CK_InvDocumentos_TipoOp CHECK (TipoOperacion IN ('E','S','C','T')),
    Periodo             VARCHAR(6)     NOT NULL,
    Secuencia           INT            NOT NULL,
    NumeroDocumento     VARCHAR(30)    NOT NULL,
    Fecha               DATE           NOT NULL DEFAULT GETDATE(),
    IdAlmacen           INT            NOT NULL CONSTRAINT FK_InvDocumentos_Almacen FOREIGN KEY REFERENCES dbo.Almacenes(IdAlmacen),
    IdMoneda            INT            NULL CONSTRAINT FK_InvDocumentos_Moneda FOREIGN KEY REFERENCES dbo.Monedas(IdMoneda),
    TasaCambio          DECIMAL(18,6)  NOT NULL DEFAULT 1.000000,
    Referencia          NVARCHAR(250)  NULL,
    Observacion         NVARCHAR(500)  NULL,
    TotalDocumento      DECIMAL(18,4)  NOT NULL DEFAULT 0,
    Estado              CHAR(1)        NOT NULL DEFAULT 'A' CONSTRAINT CK_InvDocumentos_Estado CHECK (Estado IN ('A','N')),
    RowStatus           INT            NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT            NOT NULL,
    FechaModificacion   DATETIME       NULL,
    UsuarioModificacion INT            NULL,
    IdSesionCreacion    INT            NULL,
    IdSesionModif       INT            NULL,
    CONSTRAINT UQ_InvDocumentos_TipoSecuencia UNIQUE (IdTipoDocumento, Secuencia)
  );
  PRINT 'Tabla InvDocumentos creada.';
END
GO

-- 2. TABLA: InvDocumentoDetalle (Lineas)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InvDocumentoDetalle' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.InvDocumentoDetalle (
    IdDetalle           INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_InvDocumentoDetalle PRIMARY KEY,
    IdDocumento         INT            NOT NULL CONSTRAINT FK_InvDocDetalle_Doc FOREIGN KEY REFERENCES dbo.InvDocumentos(IdDocumento),
    NumeroLinea         INT            NOT NULL,
    IdProducto          INT            NOT NULL CONSTRAINT FK_InvDocDetalle_Prod FOREIGN KEY REFERENCES dbo.Productos(IdProducto),
    Codigo              NVARCHAR(60)   NULL,
    Descripcion         NVARCHAR(200)  NOT NULL,
    IdUnidadMedida      INT            NULL,
    NombreUnidad        NVARCHAR(50)   NULL,
    Cantidad            DECIMAL(18,4)  NOT NULL DEFAULT 0,
    Costo               DECIMAL(18,4)  NOT NULL DEFAULT 0,
    Total               DECIMAL(18,4)  NOT NULL DEFAULT 0,
    RowStatus           INT            NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT            NOT NULL DEFAULT 1,
    CONSTRAINT UQ_InvDocDetalle_Linea UNIQUE (IdDocumento, NumeroLinea)
  );
  PRINT 'Tabla InvDocumentoDetalle creada.';
END
GO

-- 3. Indices utiles
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InvDocumentos_TipoOp_Fecha' AND object_id = OBJECT_ID('dbo.InvDocumentos'))
BEGIN
  CREATE NONCLUSTERED INDEX IX_InvDocumentos_TipoOp_Fecha
    ON dbo.InvDocumentos (TipoOperacion, Fecha DESC)
    INCLUDE (IdTipoDocumento, NumeroDocumento, IdAlmacen, TotalDocumento, Estado);
  PRINT 'Indice IX_InvDocumentos_TipoOp_Fecha creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InvDocDetalle_Doc' AND object_id = OBJECT_ID('dbo.InvDocumentoDetalle'))
BEGIN
  CREATE NONCLUSTERED INDEX IX_InvDocDetalle_Doc
    ON dbo.InvDocumentoDetalle (IdDocumento)
    INCLUDE (IdProducto, Cantidad, Costo, Total);
  PRINT 'Indice IX_InvDocDetalle_Doc creado.';
END
GO

PRINT 'Script 52_inv_documentos.sql ejecutado correctamente.';
GO
