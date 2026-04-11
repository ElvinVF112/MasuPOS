-- ============================================================
-- SCRIPT 34: Tasas de Impuesto
-- Tables: dbo.TasasImpuesto
-- SP:     dbo.spTasasImpuestoCRUD (L/O/I/A/D)
-- Seeds:  Pantallas + Permisos + RolesPermisos (IdRol=1)
-- ============================================================

-- ── Table ────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'TasasImpuesto' AND type = 'U')
BEGIN
  CREATE TABLE dbo.TasasImpuesto (
    IdTasaImpuesto    INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Nombre            NVARCHAR(100) NOT NULL,
    Tasa              DECIMAL(7,4)  NOT NULL DEFAULT 0,
    Codigo            NVARCHAR(20)  NOT NULL,
    Activo            BIT           NOT NULL DEFAULT 1,
    RowStatus         CHAR(1)       NOT NULL DEFAULT 'A',
    FechaCreacion     DATETIME      NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion   INT           NOT NULL DEFAULT 1,
    FechaModificacion DATETIME      NULL,
    UsuarioModificacion INT         NULL
  )
END
GO

-- ── Stored Procedure ──────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'spTasasImpuestoCRUD' AND type = 'P')
  DROP PROCEDURE dbo.spTasasImpuestoCRUD
GO

CREATE PROCEDURE dbo.spTasasImpuestoCRUD
  @Accion              CHAR(1),
  @IdTasaImpuesto      INT           = NULL,
  @Nombre              NVARCHAR(100) = NULL,
  @Tasa                DECIMAL(7,4)  = NULL,
  @Codigo              NVARCHAR(20)  = NULL,
  @Activo              BIT           = NULL,
  @UsuarioCreacion     INT           = NULL,
  @UsuarioModificacion INT           = NULL
AS
BEGIN
  SET NOCOUNT ON

  -- L: List all active
  IF @Accion = 'L'
  BEGIN
    SELECT IdTasaImpuesto, Nombre, Tasa, Codigo, Activo
    FROM   dbo.TasasImpuesto
    WHERE  RowStatus = 'A'
    ORDER BY Nombre
    RETURN
  END

  -- O: Obtain one
  IF @Accion = 'O'
  BEGIN
    SELECT IdTasaImpuesto, Nombre, Tasa, Codigo, Activo
    FROM   dbo.TasasImpuesto
    WHERE  IdTasaImpuesto = @IdTasaImpuesto AND RowStatus = 'A'
    RETURN
  END

  -- I: Insert
  IF @Accion = 'I'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.TasasImpuesto WHERE Codigo = @Codigo AND RowStatus = 'A')
      THROW 50001, 'Ya existe una tasa de impuesto con ese codigo.', 1

    INSERT INTO dbo.TasasImpuesto (Nombre, Tasa, Codigo, Activo, UsuarioCreacion)
    VALUES (@Nombre, @Tasa, @Codigo, ISNULL(@Activo, 1), ISNULL(@UsuarioCreacion, 1))

    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spTasasImpuestoCRUD @Accion = 'O', @IdTasaImpuesto = @NewId
    RETURN
  END

  -- A: Update
  IF @Accion = 'A'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.TasasImpuesto WHERE Codigo = @Codigo AND IdTasaImpuesto <> @IdTasaImpuesto AND RowStatus = 'A')
      THROW 50002, 'Ya existe una tasa de impuesto con ese codigo.', 1

    UPDATE dbo.TasasImpuesto
    SET    Nombre = @Nombre,
           Tasa   = @Tasa,
           Codigo = @Codigo,
           Activo = @Activo,
           FechaModificacion     = GETDATE(),
           UsuarioModificacion   = @UsuarioModificacion
    WHERE  IdTasaImpuesto = @IdTasaImpuesto AND RowStatus = 'A'

    EXEC dbo.spTasasImpuestoCRUD @Accion = 'O', @IdTasaImpuesto = @IdTasaImpuesto
    RETURN
  END

  -- D: Soft delete
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.TasasImpuesto
    SET    RowStatus           = 'I',
           Activo              = 0,
           FechaModificacion   = GETDATE(),
           UsuarioModificacion = @UsuarioModificacion
    WHERE  IdTasaImpuesto = @IdTasaImpuesto
    RETURN
  END
END
GO

-- ── Seeds ─────────────────────────────────────────────────────

-- Default tax rates
IF NOT EXISTS (SELECT 1 FROM dbo.TasasImpuesto WHERE Codigo = 'EXENTO')
  INSERT INTO dbo.TasasImpuesto (Nombre, Tasa, Codigo) VALUES ('Exento', 0, 'EXENTO')

IF NOT EXISTS (SELECT 1 FROM dbo.TasasImpuesto WHERE Codigo = 'ITBIS18')
  INSERT INTO dbo.TasasImpuesto (Nombre, Tasa, Codigo) VALUES ('ITBIS 18%', 18, 'ITBIS18')

IF NOT EXISTS (SELECT 1 FROM dbo.TasasImpuesto WHERE Codigo = 'ITBIS16')
  INSERT INTO dbo.TasasImpuesto (Nombre, Tasa, Codigo) VALUES ('ITBIS 16%', 16, 'ITBIS16')

-- Pantalla
IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/company/tax-rates')
  INSERT INTO dbo.Pantallas (Nombre, Ruta, Activo, IdModulo)
  VALUES ('Tasas de Impuesto', '/config/company/tax-rates', 1, 7)

-- Permiso
IF NOT EXISTS (
  SELECT 1 FROM dbo.Permisos P
  JOIN   dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
  WHERE  PA.Ruta = '/config/company/tax-rates'
)
BEGIN
  INSERT INTO dbo.Permisos (Nombre, Descripcion, IdPantalla, Activo)
  SELECT 'Ver Tasas de Impuesto', 'Acceder a la pantalla de tasas de impuesto', IdPantalla, 1
  FROM   dbo.Pantallas
  WHERE  Ruta = '/config/company/tax-rates'
END

-- Asignar al rol admin (IdRol=1)
IF NOT EXISTS (
  SELECT 1 FROM dbo.RolesPermisos RP
  JOIN   dbo.Permisos P ON RP.IdPermiso = P.IdPermiso
  JOIN   dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
  WHERE  PA.Ruta = '/config/company/tax-rates' AND RP.IdRol = 1
)
BEGIN
  INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso)
  SELECT 1, P.IdPermiso
  FROM   dbo.Permisos P
  JOIN   dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
  WHERE  PA.Ruta = '/config/company/tax-rates'
END

PRINT 'Script 34 completado.'
GO
