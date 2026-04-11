-- ============================================================
-- Script 132: Facturación — Tipos de Documentos
-- Tablas:  dbo.FacTiposDocumento
--          dbo.FacTipoDocUsuario
-- SP:      dbo.spFacTiposDocumentoCRUD (L/O/I/A/D/LU/U)
-- Seed:    Permisos + asignación a rol Administrador
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- TABLE: FacTiposDocumento
-- TipoOperacion: F=Factura, Q=Cotización, K=Conduce, P=Orden de Pedido
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacTiposDocumento' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.FacTiposDocumento (
    IdTipoDocumento     INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_FacTiposDocumento PRIMARY KEY,
    TipoOperacion       CHAR(1)        NOT NULL CONSTRAINT CK_FacTiposDocumento_TipoOp CHECK (TipoOperacion IN ('F','Q','K','P')),
    Codigo              VARCHAR(10)    NOT NULL,
    Descripcion         NVARCHAR(250)  NULL,
    Prefijo             VARCHAR(10)    NULL,
    SecuenciaInicial    INT            NOT NULL DEFAULT 1,
    SecuenciaActual     INT            NOT NULL DEFAULT 0,
    IdMoneda            INT            NULL CONSTRAINT FK_FacTiposDocumento_Moneda FOREIGN KEY REFERENCES dbo.Monedas(IdMoneda),
    AplicaPropina       BIT            NOT NULL DEFAULT 0,
    IdCatalogoNCF       INT            NULL CONSTRAINT FK_FacTiposDocumento_NCF FOREIGN KEY REFERENCES dbo.CatalogoNCF(IdCatalogoNCF),
    Activo              BIT            NOT NULL DEFAULT 1,
    RowStatus           INT            NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT            NOT NULL DEFAULT 1,
    FechaModificacion   DATETIME       NULL,
    UsuarioModificacion INT            NULL,
    CONSTRAINT UQ_FacTiposDocumento_Codigo UNIQUE (Codigo)
  )
  PRINT 'TABLE FacTiposDocumento CREATED'
END
GO

-- ============================================================
-- TABLE: FacTipoDocUsuario
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacTipoDocUsuario' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.FacTipoDocUsuario (
    IdTipoDocUsuario    INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_FacTipoDocUsuario PRIMARY KEY,
    IdTipoDocumento     INT            NOT NULL CONSTRAINT FK_FacTipoDocUsuario_TipoDoc FOREIGN KEY REFERENCES dbo.FacTiposDocumento(IdTipoDocumento) ON DELETE CASCADE,
    IdUsuario           INT            NOT NULL CONSTRAINT FK_FacTipoDocUsuario_Usuario FOREIGN KEY REFERENCES dbo.Usuarios(IdUsuario),
    Activo              BIT            NOT NULL DEFAULT 1,
    RowStatus           INT            NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT            NOT NULL DEFAULT 1,
    FechaModificacion   DATETIME       NULL,
    UsuarioModificacion INT            NULL,
    CONSTRAINT UQ_FacTipoDocUsuario UNIQUE (IdTipoDocumento, IdUsuario)
  )
  PRINT 'TABLE FacTipoDocUsuario CREATED'
END
GO

-- ============================================================
-- SP: spFacTiposDocumentoCRUD
-- Acciones: L, O, I, A, D, LU, U
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spFacTiposDocumentoCRUD
  @Accion              CHAR(2)        = 'L',
  @IdTipoDocumento     INT            = NULL,
  @TipoOperacion       CHAR(1)        = NULL,
  @Codigo              VARCHAR(10)    = NULL,
  @Descripcion         NVARCHAR(250)  = NULL,
  @Prefijo             VARCHAR(10)    = NULL,
  @SecuenciaInicial    INT            = 1,
  @IdMoneda            INT            = NULL,
  @AplicaPropina       BIT            = 0,
  @IdCatalogoNCF       INT            = NULL,
  @Activo              BIT            = 1,
  @UsuarioAccion       INT            = NULL,
  @UsuariosAsignados   NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: Listar (filtro opcional por TipoOperacion)
  IF @Accion = 'L'
  BEGIN
    SELECT t.IdTipoDocumento, t.TipoOperacion, t.Codigo, t.Descripcion,
           t.Prefijo, t.SecuenciaInicial, t.SecuenciaActual,
           t.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           t.AplicaPropina,
           t.IdCatalogoNCF, c.Codigo AS CodigoNCF, ISNULL(c.NombreInterno, c.Nombre) AS NombreNCF,
           t.Activo,
           t.FechaCreacion, t.UsuarioCreacion, t.FechaModificacion, t.UsuarioModificacion
    FROM   dbo.FacTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.CatalogoNCF c ON c.IdCatalogoNCF = t.IdCatalogoNCF
    WHERE  (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
      AND  t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion
    RETURN
  END

  -- O: Obtener uno
  IF @Accion = 'O'
  BEGIN
    SELECT t.IdTipoDocumento, t.TipoOperacion, t.Codigo, t.Descripcion,
           t.Prefijo, t.SecuenciaInicial, t.SecuenciaActual,
           t.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           t.AplicaPropina,
           t.IdCatalogoNCF, c.Codigo AS CodigoNCF, ISNULL(c.NombreInterno, c.Nombre) AS NombreNCF,
           t.Activo,
           t.FechaCreacion, t.UsuarioCreacion, t.FechaModificacion, t.UsuarioModificacion
    FROM   dbo.FacTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.CatalogoNCF c ON c.IdCatalogoNCF = t.IdCatalogoNCF
    WHERE  t.IdTipoDocumento = @IdTipoDocumento AND t.RowStatus = 1
    RETURN
  END

  -- I: Insertar
  IF @Accion = 'I'
  BEGIN
    -- Auto-generar código si no se envía
    IF @Codigo IS NULL OR LEN(LTRIM(RTRIM(@Codigo))) = 0
    BEGIN
      DECLARE @MaxCode INT
      SELECT @MaxCode = ISNULL(MAX(TRY_CAST(REPLACE(Codigo, @Prefijo + '-', '') AS INT)), 0)
      FROM dbo.FacTiposDocumento WHERE TipoOperacion = @TipoOperacion AND RowStatus = 1
      SET @Codigo = ISNULL(@Prefijo, '') + '-' + RIGHT('0000' + CAST(@MaxCode + 1 AS VARCHAR), 4)
    END

    IF EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE Codigo = @Codigo AND RowStatus = 1)
      THROW 50030, 'Ya existe un tipo de documento con ese código.', 1

    INSERT INTO dbo.FacTiposDocumento (
      TipoOperacion, Codigo, Descripcion, Prefijo, SecuenciaInicial, SecuenciaActual,
      IdMoneda, AplicaPropina, IdCatalogoNCF, Activo, UsuarioCreacion
    ) VALUES (
      @TipoOperacion, @Codigo, @Descripcion, @Prefijo, @SecuenciaInicial, 0,
      @IdMoneda, ISNULL(@AplicaPropina, 0), @IdCatalogoNCF, ISNULL(@Activo, 1), @UsuarioAccion
    )

    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId
    RETURN
  END

  -- A: Actualizar
  IF @Accion = 'A'
  BEGIN
    IF @Codigo IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE Codigo = @Codigo AND IdTipoDocumento <> @IdTipoDocumento AND RowStatus = 1)
      THROW 50031, 'Ya existe otro tipo de documento con ese código.', 1

    UPDATE dbo.FacTiposDocumento
    SET    Descripcion         = ISNULL(@Descripcion, Descripcion),
           Prefijo             = ISNULL(@Prefijo, Prefijo),
           SecuenciaInicial    = ISNULL(@SecuenciaInicial, SecuenciaInicial),
           IdMoneda            = @IdMoneda,
           AplicaPropina       = ISNULL(@AplicaPropina, AplicaPropina),
           IdCatalogoNCF       = @IdCatalogoNCF,
           Activo              = ISNULL(@Activo, Activo),
           FechaModificacion   = GETDATE(),
           UsuarioModificacion = @UsuarioAccion
    WHERE  IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1

    EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento
    RETURN
  END

  -- D: Soft-delete
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacTiposDocumento
    SET    RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE  IdTipoDocumento = @IdTipoDocumento
    RETURN
  END

  -- LU: Listar usuarios (asignados + disponibles)
  IF @Accion = 'LU'
  BEGIN
    SELECT u.IdUsuario, u.NombreUsuario, u.Nombres, u.Correo,
           CASE WHEN tdu.IdTipoDocUsuario IS NOT NULL THEN 1 ELSE 0 END AS Asignado
    FROM   dbo.Usuarios u
    LEFT JOIN dbo.FacTipoDocUsuario tdu
      ON tdu.IdUsuario = u.IdUsuario AND tdu.IdTipoDocumento = @IdTipoDocumento AND tdu.Activo = 1
    WHERE  u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres
    RETURN
  END

  -- U: Sincronizar usuarios
  IF @Accion = 'U'
  BEGIN
    UPDATE dbo.FacTipoDocUsuario
    SET    Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE  IdTipoDocumento = @IdTipoDocumento

    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      INSERT INTO dbo.FacTipoDocUsuario (IdTipoDocumento, IdUsuario, UsuarioCreacion)
      SELECT @IdTipoDocumento, TRY_CAST(value AS INT), ISNULL(@UsuarioAccion, 1)
      FROM   STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE  TRY_CAST(value AS INT) IS NOT NULL
        AND  NOT EXISTS (SELECT 1 FROM dbo.FacTipoDocUsuario WHERE IdTipoDocumento = @IdTipoDocumento AND IdUsuario = TRY_CAST(value AS INT))

      UPDATE dbo.FacTipoDocUsuario
      SET    Activo = 1, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
      WHERE  IdTipoDocumento = @IdTipoDocumento
        AND  IdUsuario IN (SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@UsuariosAsignados, ',') WHERE TRY_CAST(value AS INT) IS NOT NULL)
    END

    EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'LU', @IdTipoDocumento = @IdTipoDocumento
    RETURN
  END
END
GO

-- ============================================================
-- SEED: Tipos iniciales
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE TipoOperacion = 'F' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.FacTiposDocumento (TipoOperacion, Codigo, Descripcion, Prefijo, SecuenciaInicial)
  VALUES ('F', 'FAC-0001', N'Facturas de Crédito Fiscal', 'FAC', 1)
  PRINT 'SEED: Tipo Factura insertado'
END

IF NOT EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE TipoOperacion = 'Q' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.FacTiposDocumento (TipoOperacion, Codigo, Descripcion, Prefijo, SecuenciaInicial)
  VALUES ('Q', 'COT-0001', N'Cotizaciones', 'COT', 1)
  PRINT 'SEED: Tipo Cotización insertado'
END

IF NOT EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE TipoOperacion = 'K' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.FacTiposDocumento (TipoOperacion, Codigo, Descripcion, Prefijo, SecuenciaInicial)
  VALUES ('K', 'CON-0001', N'Conduces de Entrega', 'CON', 1)
  PRINT 'SEED: Tipo Conduce insertado'
END

IF NOT EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE TipoOperacion = 'P' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.FacTiposDocumento (TipoOperacion, Codigo, Descripcion, Prefijo, SecuenciaInicial)
  VALUES ('P', 'PED-0001', N'Ordenes de Pedido', 'PED', 1)
  PRINT 'SEED: Tipo Orden de Pedido insertado'
END
GO

-- ============================================================
-- PERMISOS
-- ============================================================
DECLARE @IdMod INT = (SELECT TOP 1 IdModulo FROM dbo.Modulos WHERE Nombre LIKE '%Factur%' AND RowStatus = 1)
IF @IdMod IS NULL SET @IdMod = 1

-- Pantallas
IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/facturacion/tipos-facturas')
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Descripcion, UsuarioCreacion) VALUES (@IdMod, N'Tipos de Facturas', '/config/facturacion/tipos-facturas', N'CRUD de tipos de facturas', 1)

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/facturacion/tipos-cotizaciones')
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Descripcion, UsuarioCreacion) VALUES (@IdMod, N'Tipos de Cotización', '/config/facturacion/tipos-cotizaciones', N'CRUD de tipos de cotizaciones', 1)

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/facturacion/tipos-conduces')
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Descripcion, UsuarioCreacion) VALUES (@IdMod, N'Tipos de Conduce', '/config/facturacion/tipos-conduces', N'CRUD de tipos de conduces', 1)

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/facturacion/tipos-ordenes-pedido')
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Descripcion, UsuarioCreacion) VALUES (@IdMod, N'Tipos de Ordenes de Pedido', '/config/facturacion/tipos-ordenes-pedido', N'CRUD de tipos de ordenes de pedido', 1)
GO

-- Permisos
DECLARE @perms TABLE (Ruta NVARCHAR(200), Clave NVARCHAR(100), Nombre NVARCHAR(200))
INSERT INTO @perms VALUES
  ('/config/facturacion/tipos-facturas',        'config.facturacion.tipos-facturas.view',        N'Tipos de Facturas'),
  ('/config/facturacion/tipos-cotizaciones',     'config.facturacion.tipos-cotizaciones.view',    N'Tipos de Cotización'),
  ('/config/facturacion/tipos-conduces',         'config.facturacion.tipos-conduces.view',        N'Tipos de Conduce'),
  ('/config/facturacion/tipos-ordenes-pedido',   'config.facturacion.tipos-ordenes-pedido.view',  N'Tipos de Ordenes de Pedido')

INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
SELECT p.IdPantalla, pe.Nombre, N'Acceso a ' + pe.Nombre, pe.Clave, 1, 1
FROM   @perms pe
JOIN   dbo.Pantallas p ON p.Ruta = pe.Ruta AND p.RowStatus = 1
WHERE  NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = pe.Clave)
GO

-- Asignar a rol Administrador
INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, p.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM   dbo.Permisos pe
JOIN   dbo.Pantallas p ON p.IdPantalla = pe.IdPantalla
WHERE  pe.Clave IN ('config.facturacion.tipos-facturas.view','config.facturacion.tipos-cotizaciones.view','config.facturacion.tipos-conduces.view','config.facturacion.tipos-ordenes-pedido.view')
  AND  NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos rp WHERE rp.IdRol = 1 AND rp.IdPantalla = p.IdPantalla)
GO

-- RolesPermisos
INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Permitido)
SELECT 1, pe.IdPermiso, 1
FROM   dbo.Permisos pe
WHERE  pe.Clave IN ('config.facturacion.tipos-facturas.view','config.facturacion.tipos-cotizaciones.view','config.facturacion.tipos-conduces.view','config.facturacion.tipos-ordenes-pedido.view')
  AND  NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos rp WHERE rp.IdRol = 1 AND rp.IdPermiso = pe.IdPermiso)
GO

PRINT '=== Script 132 completado ==='
GO
