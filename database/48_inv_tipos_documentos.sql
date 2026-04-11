-- ============================================================
-- TAREA 37 - Inventario: Tipos de Documentos
-- Tablas, SPs y Permisos
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 1. TABLA: InvTiposDocumento
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InvTiposDocumento' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.InvTiposDocumento (
    IdTipoDocumento     INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_InvTiposDocumento PRIMARY KEY,
    TipoOperacion       CHAR(1)        NOT NULL CONSTRAINT CK_InvTiposDocumento_TipoOp CHECK (TipoOperacion IN ('E','S','C','T')),
    -- E=Entrada Inventario, S=Salida Inventario, C=Entrada Compra, T=Transferencia
    Codigo              VARCHAR(10)    NOT NULL,
    Descripcion         NVARCHAR(250)  NULL,
    Prefijo             VARCHAR(10)    NULL,
    SecuenciaInicial    INT            NOT NULL DEFAULT 1,
    SecuenciaActual     INT            NOT NULL DEFAULT 0,
    ActualizaCosto      BIT            NOT NULL DEFAULT 0,
    IdMoneda            INT            NULL CONSTRAINT FK_InvTiposDocumento_Moneda FOREIGN KEY REFERENCES dbo.Monedas(IdMoneda),
    -- Control fields
    Activo              BIT            NOT NULL DEFAULT 1,
    RowStatus           INT            NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT            NOT NULL DEFAULT 1,
    FechaModificacion   DATETIME       NULL,
    UsuarioModificacion INT            NULL,
    IdSesionCreacion    INT            NULL,
    IdSesionModif       INT            NULL,
    CONSTRAINT UQ_InvTiposDocumento_Codigo UNIQUE (Codigo)
  );
  PRINT 'Tabla InvTiposDocumento creada.';
END
GO

-- ============================================================
-- 2. TABLA: InvTipoDocUsuario
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InvTipoDocUsuario' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.InvTipoDocUsuario (
    IdTipoDocUsuario    INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_InvTipoDocUsuario PRIMARY KEY,
    IdTipoDocumento     INT            NOT NULL CONSTRAINT FK_InvTipoDocUsuario_TipoDoc FOREIGN KEY REFERENCES dbo.InvTiposDocumento(IdTipoDocumento) ON DELETE CASCADE,
    IdUsuario           INT            NOT NULL CONSTRAINT FK_InvTipoDocUsuario_Usuario FOREIGN KEY REFERENCES dbo.Usuarios(IdUsuario),
    -- Control fields
    Activo              BIT            NOT NULL DEFAULT 1,
    RowStatus           INT            NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT            NOT NULL DEFAULT 1,
    FechaModificacion   DATETIME       NULL,
    UsuarioModificacion INT            NULL,
    CONSTRAINT UQ_InvTipoDocUsuario UNIQUE (IdTipoDocumento, IdUsuario)
  );
  PRINT 'Tabla InvTipoDocUsuario creada.';
END
GO

-- ============================================================
-- 3. SP: spInvTiposDocumentoCRUD
-- Acciones: L=Listar, O=Obtener, I=Insertar, A=Actualizar, D=Eliminar
--           U=Sincronizar usuarios asignados, LU=Listar usuarios asignados
-- ============================================================
IF OBJECT_ID('dbo.spInvTiposDocumentoCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spInvTiposDocumentoCRUD;
GO

CREATE PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion              CHAR(2)        = 'L',
  @IdTipoDocumento     INT            = NULL,
  @TipoOperacion       CHAR(1)        = NULL,
  @Codigo              VARCHAR(10)    = NULL,
  @Descripcion         NVARCHAR(250)  = NULL,
  @Prefijo             VARCHAR(10)    = NULL,
  @SecuenciaInicial    INT            = 1,
  @ActualizaCosto      BIT            = 0,
  @IdMoneda            INT            = NULL,
  @Activo              BIT            = 1,
  @UsuarioCreacion     INT            = 1,
  @UsuarioModificacion INT            = NULL,
  @IdSesion            INT            = NULL,
  @TokenSesion         NVARCHAR(128)  = NULL,
  -- Para accion U: lista CSV de IdUsuario a asignar (NULL = sin cambios, '' = quitar todos)
  @UsuariosAsignados   NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: Listar todos (opcional filtrar por TipoOperacion)
  IF @Accion = 'L'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
      AND t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion;
    RETURN;
  END

  -- O: Obtener uno por ID
  IF @Accion = 'O'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE t.IdTipoDocumento = @IdTipoDocumento
      AND t.RowStatus = 1;
    RETURN;
  END

  -- I: Insertar
  IF @Accion = 'I'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND RowStatus = 1)
      THROW 50001, 'Ya existe un tipo de documento con ese codigo.', 1;

    INSERT INTO dbo.InvTiposDocumento (
      TipoOperacion, Codigo, Descripcion, Prefijo,
      SecuenciaInicial, SecuenciaActual, ActualizaCosto, IdMoneda, Activo,
      UsuarioCreacion, IdSesionCreacion
    )
    VALUES (
      @TipoOperacion, @Codigo, @Descripcion, @Prefijo,
      @SecuenciaInicial, 0,
      CASE WHEN @TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      @IdMoneda, @Activo,
      @UsuarioCreacion, @IdSesion
    );

    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId;
    RETURN;
  END

  -- A: Actualizar
  IF @Accion = 'A'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND IdTipoDocumento <> @IdTipoDocumento AND RowStatus = 1)
      THROW 50002, 'Ya existe otro tipo de documento con ese codigo.', 1;

    UPDATE dbo.InvTiposDocumento SET
      Codigo              = ISNULL(@Codigo, Codigo),
      Descripcion         = @Descripcion,
      Prefijo             = @Prefijo,
      SecuenciaInicial    = ISNULL(@SecuenciaInicial, SecuenciaInicial),
      ActualizaCosto      = CASE WHEN TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      IdMoneda            = @IdMoneda,
      Activo              = ISNULL(@Activo, Activo),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif       = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1;

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  -- D: Eliminar (soft delete)
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.InvTiposDocumento SET
      RowStatus           = 0,
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif       = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  -- LU: Listar usuarios asignados a un tipo de documento
  IF @Accion = 'LU'
  BEGIN
    SELECT
      u.IdUsuario,
      u.NombreUsuario,
      u.Nombres,
      u.Correo,
      CASE WHEN tdu.IdTipoDocUsuario IS NOT NULL THEN 1 ELSE 0 END AS Asignado
    FROM dbo.Usuarios u
    LEFT JOIN dbo.InvTipoDocUsuario tdu
      ON tdu.IdUsuario = u.IdUsuario
      AND tdu.IdTipoDocumento = @IdTipoDocumento
      AND tdu.Activo = 1
    WHERE u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres;
    RETURN;
  END

  -- U: Sincronizar usuarios asignados (reemplaza la lista completa)
  IF @Accion = 'U'
  BEGIN
    -- Desactivar todos los actuales
    UPDATE dbo.InvTipoDocUsuario SET
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoDocumento = @IdTipoDocumento;

    -- Insertar/reactivar los nuevos si se envio lista
    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      -- Parsear CSV de IDs
      INSERT INTO dbo.InvTipoDocUsuario (IdTipoDocumento, IdUsuario, UsuarioCreacion)
      SELECT @IdTipoDocumento, value, @UsuarioCreacion
      FROM STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE TRY_CAST(value AS INT) IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM dbo.InvTipoDocUsuario
          WHERE IdTipoDocumento = @IdTipoDocumento AND IdUsuario = TRY_CAST(value AS INT)
        );

      -- Reactivar los que ya existian
      UPDATE dbo.InvTipoDocUsuario SET
        Activo              = 1,
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
      WHERE IdTipoDocumento = @IdTipoDocumento
        AND IdUsuario IN (
          SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@UsuariosAsignados, ',')
          WHERE TRY_CAST(value AS INT) IS NOT NULL
        );
    END

    -- Retornar la lista actualizada
    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'LU', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

END
GO

-- ============================================================
-- 4. PERMISOS SEED
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'inventory.entry-types.view')
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Tipos de Entradas de Inventario', 'Acceso al CRUD de tipos de documentos de entrada de inventario', 'inventory.entry-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'inventory.exit-types.view')
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Tipos de Salidas de Inventario', 'Acceso al CRUD de tipos de documentos de salida de inventario', 'inventory.exit-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'inventory.purchase-types.view')
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Tipos Entradas por Compras', 'Acceso al CRUD de tipos de documentos de entradas por compras', 'inventory.purchase-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'inventory.transfer-types.view')
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Tipos de Transferencias', 'Acceso al CRUD de tipos de documentos de transferencias', 'inventory.transfer-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
GO

-- Asignar al rol Administrador (IdRol = 1)
INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, p.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM dbo.Permisos p
WHERE p.Clave IN (
  'inventory.entry-types.view',
  'inventory.exit-types.view',
  'inventory.purchase-types.view',
  'inventory.transfer-types.view'
)
AND NOT EXISTS (
  SELECT 1 FROM dbo.RolPantallaPermisos rp
  WHERE rp.IdRol = 1 AND rp.IdPantalla = p.IdPantalla
);
GO

PRINT 'Script 48_inv_tipos_documentos.sql ejecutado correctamente.';
GO
