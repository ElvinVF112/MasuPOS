SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ListasPrecios' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ListasPrecios (
        IdListaPrecio INT IDENTITY(1,1) PRIMARY KEY,
        Codigo NVARCHAR(20) NOT NULL,
        Descripcion NVARCHAR(200) NOT NULL,
        Abreviatura NVARCHAR(10),
        IdMoneda INT NULL,
        FechaInicio DATE,
        FechaFin DATE,
        Activo BIT NOT NULL DEFAULT 1,
        RowStatus BIT NOT NULL DEFAULT 1,
        FechaCreacion DATETIME DEFAULT GETDATE(),
        UsuarioCreacion INT NULL,
        FechaModificacion DATETIME NULL,
        UsuarioModificacion INT NULL
    );
END

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ListaPrecioUsuarios' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ListaPrecioUsuarios (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        IdListaPrecio INT NOT NULL,
        IdUsuario INT NOT NULL,
        RowStatus BIT NOT NULL DEFAULT 1,
        FechaCreacion DATETIME DEFAULT GETDATE()
    );
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ListasPrecios_Codigo')
BEGIN
    CREATE UNIQUE INDEX IX_ListasPrecios_Codigo ON dbo.ListasPrecios(Codigo) WHERE RowStatus = 1;
END

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_ListaPrecioUsuarios')
BEGIN
    ALTER TABLE dbo.ListaPrecioUsuarios ADD CONSTRAINT UQ_ListaPrecioUsuarios UNIQUE (IdListaPrecio, IdUsuario, RowStatus);
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ListaPrecioUsuarios_ListaPrecio')
BEGIN
    ALTER TABLE dbo.ListaPrecioUsuarios ADD CONSTRAINT FK_ListaPrecioUsuarios_ListaPrecio FOREIGN KEY (IdListaPrecio) REFERENCES dbo.ListasPrecios(IdListaPrecio);
END

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ListaPrecioUsuarios_Usuario')
BEGIN
    ALTER TABLE dbo.ListaPrecioUsuarios ADD CONSTRAINT FK_ListaPrecioUsuarios_Usuario FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuarios(IdUsuario);
END

INSERT INTO dbo.ListasPrecios (Codigo, Descripcion, Abreviatura, IdMoneda, FechaInicio, FechaFin, Activo, UsuarioCreacion)
SELECT '1', 'LISTA DE PRECIO GENERAL', 'GENERAL', 1, '2018-01-01', '2099-12-31', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE Codigo = '1' AND RowStatus = 1);

INSERT INTO dbo.ListasPrecios (Codigo, Descripcion, Abreviatura, IdMoneda, FechaInicio, FechaFin, Activo, UsuarioCreacion)
SELECT '2', 'LISTA DE PRECIO DETALLE', 'DETALLE', 1, '2018-08-01', '2099-12-31', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE Codigo = '2' AND RowStatus = 1);

INSERT INTO dbo.ListasPrecios (Codigo, Descripcion, Abreviatura, IdMoneda, FechaInicio, FechaFin, Activo, UsuarioCreacion)
SELECT '3', 'LISTA DE PRECIO MAYORISTA', 'MAYORISTA', 2, '2020-01-01', '2099-12-31', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE Codigo = '3' AND RowStatus = 1);

UPDATE dbo.ListasPrecios SET FechaInicio = '2018-01-01', FechaFin = '2099-12-31'
WHERE (FechaInicio IS NULL OR FechaFin IS NULL) AND RowStatus = 1;
GO

SELECT 'Tablas creadas correctamente' AS Result;