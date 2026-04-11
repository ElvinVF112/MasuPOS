SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InvTipoDocUsuario' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.InvTipoDocUsuario (
    IdTipoDocUsuario    INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_InvTipoDocUsuario PRIMARY KEY,
    IdTipoDocumento     INT NOT NULL,
    IdUsuario           INT NOT NULL,
    Activo              BIT NOT NULL CONSTRAINT DF_InvTipoDocUsuario_Activo DEFAULT (1),
    RowStatus           BIT NOT NULL CONSTRAINT DF_InvTipoDocUsuario_RowStatus DEFAULT (1),
    FechaCreacion       DATETIME2(0) NOT NULL CONSTRAINT DF_InvTipoDocUsuario_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT NULL,
    FechaModificacion   DATETIME2(0) NULL,
    UsuarioModificacion INT NULL,
    CONSTRAINT FK_InvTipoDocUsuario_TipoDoc FOREIGN KEY (IdTipoDocumento) REFERENCES dbo.InvTiposDocumento(IdTipoDocumento) ON DELETE CASCADE,
    CONSTRAINT FK_InvTipoDocUsuario_Usuario FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuarios(IdUsuario),
    CONSTRAINT UQ_InvTipoDocUsuario UNIQUE (IdTipoDocumento, IdUsuario)
  );
END
GO
