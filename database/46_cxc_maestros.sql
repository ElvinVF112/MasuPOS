-- ============================================================
-- TAREA 35 - CxC Maestros
-- Tablas, Seeds, SPs y Permisos
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 1. TABLA: DocumentosIdentificacion
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DocumentosIdentificacion' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.DocumentosIdentificacion (
    IdDocumentoIdentificacion  INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_DocumentosIdentificacion PRIMARY KEY,
    Codigo                     VARCHAR(10)    NOT NULL,
    Nombre                     NVARCHAR(80)   NOT NULL,
    LongitudMin                INT            NOT NULL DEFAULT 1,
    LongitudMax                INT            NOT NULL DEFAULT 30,
    -- Control fields
    Activo                     BIT            NOT NULL DEFAULT 1,
    RowStatus                  INT            NOT NULL DEFAULT 1,
    FechaCreacion              DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion            INT            NOT NULL DEFAULT 1,
    FechaModificacion          DATETIME       NULL,
    UsuarioModificacion        INT            NULL,
    CONSTRAINT UQ_DocumentosIdentificacion_Codigo UNIQUE (Codigo)
  );
  PRINT 'Tabla DocumentosIdentificacion creada.';
END
GO

-- Seed DocumentosIdentificacion
IF NOT EXISTS (SELECT 1 FROM dbo.DocumentosIdentificacion WHERE Codigo = 'CED')
  INSERT INTO dbo.DocumentosIdentificacion (Codigo, Nombre, LongitudMin, LongitudMax) VALUES ('CED','Cedula',11,11);
IF NOT EXISTS (SELECT 1 FROM dbo.DocumentosIdentificacion WHERE Codigo = 'RNC')
  INSERT INTO dbo.DocumentosIdentificacion (Codigo, Nombre, LongitudMin, LongitudMax) VALUES ('RNC','RNC',9,9);
IF NOT EXISTS (SELECT 1 FROM dbo.DocumentosIdentificacion WHERE Codigo = 'PAS')
  INSERT INTO dbo.DocumentosIdentificacion (Codigo, Nombre, LongitudMin, LongitudMax) VALUES ('PAS','Pasaporte',6,20);
IF NOT EXISTS (SELECT 1 FROM dbo.DocumentosIdentificacion WHERE Codigo = 'OTR')
  INSERT INTO dbo.DocumentosIdentificacion (Codigo, Nombre, LongitudMin, LongitudMax) VALUES ('OTR','Otro',1,30);
GO

-- ============================================================
-- 2. TABLA: TiposCliente
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TiposCliente' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.TiposCliente (
    IdTipoCliente              INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_TiposCliente PRIMARY KEY,
    Codigo                     VARCHAR(10)    NOT NULL,
    Nombre                     NVARCHAR(80)   NOT NULL,
    -- Control fields
    Activo                     BIT            NOT NULL DEFAULT 1,
    RowStatus                  INT            NOT NULL DEFAULT 1,
    FechaCreacion              DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion            INT            NOT NULL DEFAULT 1,
    FechaModificacion          DATETIME       NULL,
    UsuarioModificacion        INT            NULL,
    CONSTRAINT UQ_TiposCliente_Codigo UNIQUE (Codigo)
  );
  PRINT 'Tabla TiposCliente creada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.TiposCliente WHERE Codigo = 'NAT')
  INSERT INTO dbo.TiposCliente (Codigo, Nombre) VALUES ('NAT','Natural');
IF NOT EXISTS (SELECT 1 FROM dbo.TiposCliente WHERE Codigo = 'EMP')
  INSERT INTO dbo.TiposCliente (Codigo, Nombre) VALUES ('EMP','Empresa');
IF NOT EXISTS (SELECT 1 FROM dbo.TiposCliente WHERE Codigo = 'GOB')
  INSERT INTO dbo.TiposCliente (Codigo, Nombre) VALUES ('GOB','Gobierno');
IF NOT EXISTS (SELECT 1 FROM dbo.TiposCliente WHERE Codigo = 'OTR')
  INSERT INTO dbo.TiposCliente (Codigo, Nombre) VALUES ('OTR','Otro');
GO

-- ============================================================
-- 3. TABLA: CategoriasCliente
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CategoriasCliente' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.CategoriasCliente (
    IdCategoriaCliente         INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_CategoriasCliente PRIMARY KEY,
    Codigo                     VARCHAR(10)    NOT NULL,
    Nombre                     NVARCHAR(80)   NOT NULL,
    -- Control fields
    Activo                     BIT            NOT NULL DEFAULT 1,
    RowStatus                  INT            NOT NULL DEFAULT 1,
    FechaCreacion              DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion            INT            NOT NULL DEFAULT 1,
    FechaModificacion          DATETIME       NULL,
    UsuarioModificacion        INT            NULL,
    CONSTRAINT UQ_CategoriasCliente_Codigo UNIQUE (Codigo)
  );
  PRINT 'Tabla CategoriasCliente creada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CategoriasCliente WHERE Codigo = 'VIP')
  INSERT INTO dbo.CategoriasCliente (Codigo, Nombre) VALUES ('VIP','VIP');
IF NOT EXISTS (SELECT 1 FROM dbo.CategoriasCliente WHERE Codigo = 'MAY')
  INSERT INTO dbo.CategoriasCliente (Codigo, Nombre) VALUES ('MAY','Mayorista');
IF NOT EXISTS (SELECT 1 FROM dbo.CategoriasCliente WHERE Codigo = 'MIN')
  INSERT INTO dbo.CategoriasCliente (Codigo, Nombre) VALUES ('MIN','Minorista');
IF NOT EXISTS (SELECT 1 FROM dbo.CategoriasCliente WHERE Codigo = 'GEN')
  INSERT INTO dbo.CategoriasCliente (Codigo, Nombre) VALUES ('GEN','General');
GO

-- ============================================================
-- 4. TABLA: Descuentos
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Descuentos' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.Descuentos (
    IdDescuento                INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Descuentos PRIMARY KEY,
    Codigo                     VARCHAR(10)    NOT NULL,
    Nombre                     NVARCHAR(80)   NOT NULL,
    Porcentaje                 DECIMAL(5,2)   NOT NULL DEFAULT 0,
    EsGlobal                   BIT            NOT NULL DEFAULT 1,
    FechaInicio                DATE           NULL,
    FechaFin                   DATE           NULL,
    -- Control fields
    Activo                     BIT            NOT NULL DEFAULT 1,
    RowStatus                  INT            NOT NULL DEFAULT 1,
    FechaCreacion              DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion            INT            NOT NULL DEFAULT 1,
    FechaModificacion          DATETIME       NULL,
    UsuarioModificacion        INT            NULL,
    CONSTRAINT UQ_Descuentos_Codigo UNIQUE (Codigo),
    CONSTRAINT CK_Descuentos_Porcentaje CHECK (Porcentaje >= 0 AND Porcentaje <= 100)
  );
  PRINT 'Tabla Descuentos creada.';
END
GO

-- ============================================================
-- 5. TABLA: Terceros
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Terceros' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.Terceros (
    IdTercero                  INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_Terceros PRIMARY KEY,
    Codigo                     VARCHAR(20)    NOT NULL,
    Nombre                     NVARCHAR(150)  NOT NULL,
    NombreCorto                NVARCHAR(50)   NULL,
    TipoPersona                CHAR(1)        NOT NULL DEFAULT 'J',
    -- Documento identidad
    IdTipoDocIdentificacion    INT            NULL,
    DocumentoIdentificacion    VARCHAR(30)    NULL,
    -- Cliente
    EsCliente                  BIT            NOT NULL DEFAULT 0,
    IdTipoCliente              INT            NULL,
    IdCategoriaCliente         INT            NULL,
    -- Proveedor
    EsProveedor                BIT            NOT NULL DEFAULT 0,
    IdTipoProveedor            INT            NULL,
    IdCategoriaProveedor       INT            NULL,
    -- Contacto
    Direccion                  NVARCHAR(300)  NULL,
    Ciudad                     NVARCHAR(100)  NULL,
    Telefono                   VARCHAR(30)    NULL,
    Celular                    VARCHAR(30)    NULL,
    Email                      NVARCHAR(150)  NULL,
    Web                        NVARCHAR(200)  NULL,
    Contacto                   NVARCHAR(100)  NULL,
    TelefonoContacto           VARCHAR(30)    NULL,
    EmailContacto              NVARCHAR(150)  NULL,
    -- Comercial
    IdListaPrecio              INT            NULL,
    LimiteCredito              DECIMAL(18,2)  NOT NULL DEFAULT 0,
    DiasCredito                INT            NOT NULL DEFAULT 0,
    IdDocumentoVenta           INT            NULL,
    IdTipoComprobante          INT            NULL,
    IdDescuento                INT            NULL,
    Notas                      NVARCHAR(MAX)  NULL,
    -- Control fields
    Activo                     BIT            NOT NULL DEFAULT 1,
    RowStatus                  INT            NOT NULL DEFAULT 1,
    FechaCreacion              DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion            INT            NOT NULL DEFAULT 1,
    FechaModificacion          DATETIME       NULL,
    UsuarioModificacion        INT            NULL,
    CONSTRAINT UQ_Terceros_Codigo UNIQUE (Codigo)
  );
  PRINT 'Tabla Terceros creada.';
END
GO

-- FKs Terceros
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_DocIdent')
  ALTER TABLE dbo.Terceros ADD CONSTRAINT FK_Terceros_DocIdent
    FOREIGN KEY (IdTipoDocIdentificacion) REFERENCES dbo.DocumentosIdentificacion(IdDocumentoIdentificacion);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_TipoCliente')
  ALTER TABLE dbo.Terceros ADD CONSTRAINT FK_Terceros_TipoCliente
    FOREIGN KEY (IdTipoCliente) REFERENCES dbo.TiposCliente(IdTipoCliente);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_CategoriaCliente')
  ALTER TABLE dbo.Terceros ADD CONSTRAINT FK_Terceros_CategoriaCliente
    FOREIGN KEY (IdCategoriaCliente) REFERENCES dbo.CategoriasCliente(IdCategoriaCliente);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_ListaPrecio')
  ALTER TABLE dbo.Terceros ADD CONSTRAINT FK_Terceros_ListaPrecio
    FOREIGN KEY (IdListaPrecio) REFERENCES dbo.ListasPrecios(IdListaPrecio);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_Descuento')
  ALTER TABLE dbo.Terceros ADD CONSTRAINT FK_Terceros_Descuento
    FOREIGN KEY (IdDescuento) REFERENCES dbo.Descuentos(IdDescuento);
GO

-- ============================================================
-- 6. SP: spDocumentosIdentificacionCRUD
-- ============================================================
IF OBJECT_ID('dbo.spDocumentosIdentificacionCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spDocumentosIdentificacionCRUD;
GO

CREATE PROCEDURE dbo.spDocumentosIdentificacionCRUD
  @Accion                    CHAR(1)        = 'L',
  @IdDocumentoIdentificacion INT            = NULL,
  @Codigo                    VARCHAR(10)    = NULL,
  @Nombre                    NVARCHAR(80)   = NULL,
  @LongitudMin               INT            = NULL,
  @LongitudMax               INT            = NULL,
  @Activo                    BIT            = NULL,
  @UsuarioCreacion           INT            = 1,
  @UsuarioModificacion       INT            = 1,
  @IdSesion                  INT            = NULL,
  @TokenSesion               NVARCHAR(128)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT
      IdDocumentoIdentificacion,
      Codigo,
      Nombre,
      LongitudMin,
      LongitudMax,
      Activo,
      FechaCreacion,
      FechaModificacion
    FROM dbo.DocumentosIdentificacion
    WHERE RowStatus = 1
    ORDER BY Nombre;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      IdDocumentoIdentificacion,
      Codigo,
      Nombre,
      LongitudMin,
      LongitudMax,
      Activo,
      FechaCreacion,
      FechaModificacion
    FROM dbo.DocumentosIdentificacion
    WHERE IdDocumentoIdentificacion = @IdDocumentoIdentificacion
      AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.DocumentosIdentificacion (Codigo, Nombre, LongitudMin, LongitudMax, Activo, UsuarioCreacion)
    VALUES (
      UPPER(LTRIM(RTRIM(@Codigo))),
      LTRIM(RTRIM(@Nombre)),
      ISNULL(@LongitudMin, 1),
      ISNULL(@LongitudMax, 30),
      ISNULL(@Activo, 1),
      @UsuarioCreacion
    );
    SELECT
      IdDocumentoIdentificacion,
      Codigo,
      Nombre,
      LongitudMin,
      LongitudMax,
      Activo,
      FechaCreacion,
      FechaModificacion
    FROM dbo.DocumentosIdentificacion
    WHERE IdDocumentoIdentificacion = SCOPE_IDENTITY();
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.DocumentosIdentificacion
    SET
      Codigo              = UPPER(LTRIM(RTRIM(@Codigo))),
      Nombre              = LTRIM(RTRIM(@Nombre)),
      LongitudMin         = ISNULL(@LongitudMin, LongitudMin),
      LongitudMax         = ISNULL(@LongitudMax, LongitudMax),
      Activo              = ISNULL(@Activo, Activo),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdDocumentoIdentificacion = @IdDocumentoIdentificacion
      AND RowStatus = 1;
    SELECT
      IdDocumentoIdentificacion,
      Codigo,
      Nombre,
      LongitudMin,
      LongitudMax,
      Activo,
      FechaCreacion,
      FechaModificacion
    FROM dbo.DocumentosIdentificacion
    WHERE IdDocumentoIdentificacion = @IdDocumentoIdentificacion;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.DocumentosIdentificacion
    SET
      RowStatus           = 0,
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdDocumentoIdentificacion = @IdDocumentoIdentificacion;
    RETURN;
  END
END
GO

-- ============================================================
-- 7. SP: spTiposClienteCRUD
-- ============================================================
IF OBJECT_ID('dbo.spTiposClienteCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spTiposClienteCRUD;
GO

CREATE PROCEDURE dbo.spTiposClienteCRUD
  @Accion              CHAR(1)       = 'L',
  @IdTipoCliente       INT           = NULL,
  @Codigo              VARCHAR(10)   = NULL,
  @Nombre              NVARCHAR(80)  = NULL,
  @Activo              BIT           = NULL,
  @UsuarioCreacion     INT           = 1,
  @UsuarioModificacion INT           = 1,
  @IdSesion            INT           = NULL,
  @TokenSesion         NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT IdTipoCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.TiposCliente
    WHERE RowStatus = 1
    ORDER BY Nombre;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT IdTipoCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.TiposCliente
    WHERE IdTipoCliente = @IdTipoCliente AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.TiposCliente (Codigo, Nombre, Activo, UsuarioCreacion)
    VALUES (UPPER(LTRIM(RTRIM(@Codigo))), LTRIM(RTRIM(@Nombre)), ISNULL(@Activo, 1), @UsuarioCreacion);
    SELECT IdTipoCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.TiposCliente WHERE IdTipoCliente = SCOPE_IDENTITY();
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.TiposCliente
    SET Codigo = UPPER(LTRIM(RTRIM(@Codigo))), Nombre = LTRIM(RTRIM(@Nombre)),
        Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoCliente = @IdTipoCliente AND RowStatus = 1;
    SELECT IdTipoCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.TiposCliente WHERE IdTipoCliente = @IdTipoCliente;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.TiposCliente
    SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoCliente = @IdTipoCliente;
    RETURN;
  END
END
GO

-- ============================================================
-- 8. SP: spCategoriasClienteCRUD
-- ============================================================
IF OBJECT_ID('dbo.spCategoriasClienteCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spCategoriasClienteCRUD;
GO

CREATE PROCEDURE dbo.spCategoriasClienteCRUD
  @Accion                CHAR(1)       = 'L',
  @IdCategoriaCliente    INT           = NULL,
  @Codigo                VARCHAR(10)   = NULL,
  @Nombre                NVARCHAR(80)  = NULL,
  @Activo                BIT           = NULL,
  @UsuarioCreacion       INT           = 1,
  @UsuarioModificacion   INT           = 1,
  @IdSesion              INT           = NULL,
  @TokenSesion           NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT IdCategoriaCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.CategoriasCliente
    WHERE RowStatus = 1
    ORDER BY Nombre;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT IdCategoriaCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.CategoriasCliente
    WHERE IdCategoriaCliente = @IdCategoriaCliente AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.CategoriasCliente (Codigo, Nombre, Activo, UsuarioCreacion)
    VALUES (UPPER(LTRIM(RTRIM(@Codigo))), LTRIM(RTRIM(@Nombre)), ISNULL(@Activo, 1), @UsuarioCreacion);
    SELECT IdCategoriaCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.CategoriasCliente WHERE IdCategoriaCliente = SCOPE_IDENTITY();
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.CategoriasCliente
    SET Codigo = UPPER(LTRIM(RTRIM(@Codigo))), Nombre = LTRIM(RTRIM(@Nombre)),
        Activo = ISNULL(@Activo, Activo), FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdCategoriaCliente = @IdCategoriaCliente AND RowStatus = 1;
    SELECT IdCategoriaCliente, Codigo, Nombre, Activo, FechaCreacion, FechaModificacion
    FROM dbo.CategoriasCliente WHERE IdCategoriaCliente = @IdCategoriaCliente;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.CategoriasCliente
    SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdCategoriaCliente = @IdCategoriaCliente;
    RETURN;
  END
END
GO

-- ============================================================
-- 9. SP: spDescuentosCRUD
-- ============================================================
IF OBJECT_ID('dbo.spDescuentosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spDescuentosCRUD;
GO

CREATE PROCEDURE dbo.spDescuentosCRUD
  @Accion              CHAR(1)        = 'L',
  @IdDescuento         INT            = NULL,
  @Codigo              VARCHAR(10)    = NULL,
  @Nombre              NVARCHAR(80)   = NULL,
  @Porcentaje          DECIMAL(5,2)   = NULL,
  @EsGlobal            BIT            = NULL,
  @FechaInicio         DATE           = NULL,
  @FechaFin            DATE           = NULL,
  @Activo              BIT            = NULL,
  @UsuarioCreacion     INT            = 1,
  @UsuarioModificacion INT            = 1,
  @IdSesion            INT            = NULL,
  @TokenSesion         NVARCHAR(128)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin,
           Activo, FechaCreacion, FechaModificacion
    FROM dbo.Descuentos
    WHERE RowStatus = 1
    ORDER BY Nombre;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin,
           Activo, FechaCreacion, FechaModificacion
    FROM dbo.Descuentos
    WHERE IdDescuento = @IdDescuento AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.Descuentos (Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin, Activo, UsuarioCreacion)
    VALUES (
      UPPER(LTRIM(RTRIM(@Codigo))),
      LTRIM(RTRIM(@Nombre)),
      ISNULL(@Porcentaje, 0),
      ISNULL(@EsGlobal, 1),
      @FechaInicio,
      @FechaFin,
      ISNULL(@Activo, 1),
      @UsuarioCreacion
    );
    SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin,
           Activo, FechaCreacion, FechaModificacion
    FROM dbo.Descuentos WHERE IdDescuento = SCOPE_IDENTITY();
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Descuentos
    SET
      Codigo              = UPPER(LTRIM(RTRIM(@Codigo))),
      Nombre              = LTRIM(RTRIM(@Nombre)),
      Porcentaje          = ISNULL(@Porcentaje, Porcentaje),
      EsGlobal            = ISNULL(@EsGlobal, EsGlobal),
      FechaInicio         = @FechaInicio,
      FechaFin            = @FechaFin,
      Activo              = ISNULL(@Activo, Activo),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdDescuento = @IdDescuento AND RowStatus = 1;
    SELECT IdDescuento, Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin,
           Activo, FechaCreacion, FechaModificacion
    FROM dbo.Descuentos WHERE IdDescuento = @IdDescuento;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Descuentos
    SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdDescuento = @IdDescuento;
    RETURN;
  END
END
GO

-- ============================================================
-- 10. SP: spTercerosCRUD
-- ============================================================
IF OBJECT_ID('dbo.spTercerosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spTercerosCRUD;
GO

CREATE PROCEDURE dbo.spTercerosCRUD
  @Accion                    CHAR(1)         = 'L',
  @IdTercero                 INT             = NULL,
  @Codigo                    VARCHAR(20)     = NULL,
  @Nombre                    NVARCHAR(150)   = NULL,
  @NombreCorto               NVARCHAR(50)    = NULL,
  @TipoPersona               CHAR(1)         = NULL,
  @IdTipoDocIdentificacion   INT             = NULL,
  @DocumentoIdentificacion   VARCHAR(30)     = NULL,
  @EsCliente                 BIT             = NULL,
  @IdTipoCliente             INT             = NULL,
  @IdCategoriaCliente        INT             = NULL,
  @EsProveedor               BIT             = NULL,
  @IdTipoProveedor           INT             = NULL,
  @IdCategoriaProveedor      INT             = NULL,
  @Direccion                 NVARCHAR(300)   = NULL,
  @Ciudad                    NVARCHAR(100)   = NULL,
  @Telefono                  VARCHAR(30)     = NULL,
  @Celular                   VARCHAR(30)     = NULL,
  @Email                     NVARCHAR(150)   = NULL,
  @Web                       NVARCHAR(200)   = NULL,
  @Contacto                  NVARCHAR(100)   = NULL,
  @TelefonoContacto          VARCHAR(30)     = NULL,
  @EmailContacto             NVARCHAR(150)   = NULL,
  @IdListaPrecio             INT             = NULL,
  @LimiteCredito             DECIMAL(18,2)   = NULL,
  @DiasCredito               INT             = NULL,
  @IdDocumentoVenta          INT             = NULL,
  @IdTipoComprobante         INT             = NULL,
  @IdDescuento               INT             = NULL,
  @Notas                     NVARCHAR(MAX)   = NULL,
  @Activo                    BIT             = NULL,
  @UsuarioCreacion           INT             = 1,
  @UsuarioModificacion       INT             = 1,
  @IdSesion                  INT             = NULL,
  @TokenSesion               NVARCHAR(128)   = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT
      t.IdTercero,
      t.Codigo,
      t.Nombre,
      t.NombreCorto,
      t.TipoPersona,
      t.IdTipoDocIdentificacion,
      di.Codigo       AS CodigoDocIdent,
      di.Nombre       AS NombreDocIdent,
      di.LongitudMin  AS DocLongitudMin,
      di.LongitudMax  AS DocLongitudMax,
      t.DocumentoIdentificacion,
      t.EsCliente,
      t.IdTipoCliente,
      tc.Codigo       AS CodigoTipoCliente,
      tc.Nombre       AS NombreTipoCliente,
      t.IdCategoriaCliente,
      cc.Codigo       AS CodigoCategoriaCliente,
      cc.Nombre       AS NombreCategoriaCliente,
      t.EsProveedor,
      t.IdTipoProveedor,
      t.IdCategoriaProveedor,
      t.Direccion,
      t.Ciudad,
      t.Telefono,
      t.Celular,
      t.Email,
      t.Web,
      t.Contacto,
      t.TelefonoContacto,
      t.EmailContacto,
      t.IdListaPrecio,
      lp.Descripcion  AS NombreListaPrecio,
      t.LimiteCredito,
      t.DiasCredito,
      t.IdDocumentoVenta,
      t.IdTipoComprobante,
      t.IdDescuento,
      t.Notas,
      t.Activo,
      t.FechaCreacion,
      t.FechaModificacion
    FROM dbo.Terceros t
    LEFT JOIN dbo.DocumentosIdentificacion di ON di.IdDocumentoIdentificacion = t.IdTipoDocIdentificacion
    LEFT JOIN dbo.TiposCliente tc ON tc.IdTipoCliente = t.IdTipoCliente
    LEFT JOIN dbo.CategoriasCliente cc ON cc.IdCategoriaCliente = t.IdCategoriaCliente
    LEFT JOIN dbo.ListasPrecios lp ON lp.IdListaPrecio = t.IdListaPrecio
    WHERE t.RowStatus = 1
      AND (@EsCliente IS NULL OR t.EsCliente = @EsCliente)
      AND (@EsProveedor IS NULL OR t.EsProveedor = @EsProveedor)
    ORDER BY t.Nombre;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      t.IdTercero,
      t.Codigo,
      t.Nombre,
      t.NombreCorto,
      t.TipoPersona,
      t.IdTipoDocIdentificacion,
      di.Codigo       AS CodigoDocIdent,
      di.Nombre       AS NombreDocIdent,
      di.LongitudMin  AS DocLongitudMin,
      di.LongitudMax  AS DocLongitudMax,
      t.DocumentoIdentificacion,
      t.EsCliente,
      t.IdTipoCliente,
      tc.Codigo       AS CodigoTipoCliente,
      tc.Nombre       AS NombreTipoCliente,
      t.IdCategoriaCliente,
      cc.Codigo       AS CodigoCategoriaCliente,
      cc.Nombre       AS NombreCategoriaCliente,
      t.EsProveedor,
      t.IdTipoProveedor,
      t.IdCategoriaProveedor,
      t.Direccion,
      t.Ciudad,
      t.Telefono,
      t.Celular,
      t.Email,
      t.Web,
      t.Contacto,
      t.TelefonoContacto,
      t.EmailContacto,
      t.IdListaPrecio,
      lp.Descripcion  AS NombreListaPrecio,
      t.LimiteCredito,
      t.DiasCredito,
      t.IdDocumentoVenta,
      t.IdTipoComprobante,
      t.IdDescuento,
      t.Notas,
      t.Activo,
      t.FechaCreacion,
      t.FechaModificacion
    FROM dbo.Terceros t
    LEFT JOIN dbo.DocumentosIdentificacion di ON di.IdDocumentoIdentificacion = t.IdTipoDocIdentificacion
    LEFT JOIN dbo.TiposCliente tc ON tc.IdTipoCliente = t.IdTipoCliente
    LEFT JOIN dbo.CategoriasCliente cc ON cc.IdCategoriaCliente = t.IdCategoriaCliente
    LEFT JOIN dbo.ListasPrecios lp ON lp.IdListaPrecio = t.IdListaPrecio
    WHERE t.IdTercero = @IdTercero AND t.RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.Terceros (
      Codigo, Nombre, NombreCorto, TipoPersona,
      IdTipoDocIdentificacion, DocumentoIdentificacion,
      EsCliente, IdTipoCliente, IdCategoriaCliente,
      EsProveedor, IdTipoProveedor, IdCategoriaProveedor,
      Direccion, Ciudad, Telefono, Celular, Email, Web,
      Contacto, TelefonoContacto, EmailContacto,
      IdListaPrecio, LimiteCredito, DiasCredito,
      IdDocumentoVenta, IdTipoComprobante, IdDescuento, Notas,
      Activo, UsuarioCreacion
    )
    VALUES (
      UPPER(LTRIM(RTRIM(@Codigo))),
      LTRIM(RTRIM(@Nombre)),
      NULLIF(LTRIM(RTRIM(@NombreCorto)), ''),
      ISNULL(@TipoPersona, 'J'),
      @IdTipoDocIdentificacion,
      NULLIF(LTRIM(RTRIM(@DocumentoIdentificacion)), ''),
      ISNULL(@EsCliente, 0),
      @IdTipoCliente,
      @IdCategoriaCliente,
      ISNULL(@EsProveedor, 0),
      @IdTipoProveedor,
      @IdCategoriaProveedor,
      NULLIF(LTRIM(RTRIM(@Direccion)), ''),
      NULLIF(LTRIM(RTRIM(@Ciudad)), ''),
      NULLIF(LTRIM(RTRIM(@Telefono)), ''),
      NULLIF(LTRIM(RTRIM(@Celular)), ''),
      NULLIF(LTRIM(RTRIM(@Email)), ''),
      NULLIF(LTRIM(RTRIM(@Web)), ''),
      NULLIF(LTRIM(RTRIM(@Contacto)), ''),
      NULLIF(LTRIM(RTRIM(@TelefonoContacto)), ''),
      NULLIF(LTRIM(RTRIM(@EmailContacto)), ''),
      @IdListaPrecio,
      ISNULL(@LimiteCredito, 0),
      ISNULL(@DiasCredito, 0),
      @IdDocumentoVenta,
      @IdTipoComprobante,
      @IdDescuento,
      @Notas,
      ISNULL(@Activo, 1),
      @UsuarioCreacion
    );
    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.spTercerosCRUD @Accion = 'O', @IdTercero = @NewId;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Terceros
    SET
      Codigo                   = UPPER(LTRIM(RTRIM(@Codigo))),
      Nombre                   = LTRIM(RTRIM(@Nombre)),
      NombreCorto              = NULLIF(LTRIM(RTRIM(@NombreCorto)), ''),
      TipoPersona              = ISNULL(@TipoPersona, TipoPersona),
      IdTipoDocIdentificacion  = @IdTipoDocIdentificacion,
      DocumentoIdentificacion  = NULLIF(LTRIM(RTRIM(@DocumentoIdentificacion)), ''),
      EsCliente                = ISNULL(@EsCliente, EsCliente),
      IdTipoCliente            = @IdTipoCliente,
      IdCategoriaCliente       = @IdCategoriaCliente,
      EsProveedor              = ISNULL(@EsProveedor, EsProveedor),
      IdTipoProveedor          = @IdTipoProveedor,
      IdCategoriaProveedor     = @IdCategoriaProveedor,
      Direccion                = NULLIF(LTRIM(RTRIM(@Direccion)), ''),
      Ciudad                   = NULLIF(LTRIM(RTRIM(@Ciudad)), ''),
      Telefono                 = NULLIF(LTRIM(RTRIM(@Telefono)), ''),
      Celular                  = NULLIF(LTRIM(RTRIM(@Celular)), ''),
      Email                    = NULLIF(LTRIM(RTRIM(@Email)), ''),
      Web                      = NULLIF(LTRIM(RTRIM(@Web)), ''),
      Contacto                 = NULLIF(LTRIM(RTRIM(@Contacto)), ''),
      TelefonoContacto         = NULLIF(LTRIM(RTRIM(@TelefonoContacto)), ''),
      EmailContacto            = NULLIF(LTRIM(RTRIM(@EmailContacto)), ''),
      IdListaPrecio            = @IdListaPrecio,
      LimiteCredito            = ISNULL(@LimiteCredito, LimiteCredito),
      DiasCredito              = ISNULL(@DiasCredito, DiasCredito),
      IdDocumentoVenta         = @IdDocumentoVenta,
      IdTipoComprobante        = @IdTipoComprobante,
      IdDescuento              = @IdDescuento,
      Notas                    = @Notas,
      Activo                   = ISNULL(@Activo, Activo),
      FechaModificacion        = GETDATE(),
      UsuarioModificacion      = @UsuarioModificacion
    WHERE IdTercero = @IdTercero AND RowStatus = 1;
    EXEC dbo.spTercerosCRUD @Accion = 'O', @IdTercero = @IdTercero;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Terceros
    SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdTercero = @IdTercero;
    RETURN;
  END
END
GO

-- ============================================================
-- 11. PERMISOS
-- ============================================================

-- config.cxc.customers.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxc.customers.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Clientes', 'Acceso a la pantalla de Clientes', 'config.cxc.customers.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END

-- config.cxc.customer-types.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxc.customer-types.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Tipos de Clientes', 'Acceso a la pantalla de Tipos de Clientes', 'config.cxc.customer-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END

-- config.cxc.customer-categories.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxc.customer-categories.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Categorias de Clientes', 'Acceso a la pantalla de Categorias de Clientes', 'config.cxc.customer-categories.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END

-- config.cxc.discounts.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxc.discounts.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Descuentos', 'Acceso a la pantalla de Descuentos', 'config.cxc.discounts.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END

-- config.company.doc-types.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.company.doc-types.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Documentos Identidad', 'Acceso a la pantalla de Documentos de Identidad', 'config.company.doc-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END
GO

-- Asignar permisos al rol 1
INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, p.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM dbo.Permisos p
WHERE p.Clave IN (
  'config.cxc.customers.view',
  'config.cxc.customer-types.view',
  'config.cxc.customer-categories.view',
  'config.cxc.discounts.view',
  'config.company.doc-types.view'
)
AND NOT EXISTS (
  SELECT 1 FROM dbo.RolPantallaPermisos rp
  WHERE rp.IdRol = 1 AND rp.IdPantalla = p.IdPantalla
);
GO

PRINT 'Script 46_cxc_maestros.sql completado.';
GO
