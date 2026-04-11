-- ============================================================
-- Script 133: Facturacion - Formas de Pago
-- Tablas:  dbo.FacFormasPago
--          dbo.FacFormaPagoPuntoEmision
-- SP:      dbo.spFacFormasPagoCRUD (L/O/I/A/D/LP/SP)
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- TABLE: FacFormasPago
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacFormasPago' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.FacFormasPago (
    IdFormaPago           INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_FacFormasPago PRIMARY KEY,
    Descripcion           NVARCHAR(150)  NOT NULL,
    Comentario            NVARCHAR(500)  NULL,

    -- Tipo de Valor (clasificacion operativa)
    -- EF=Efectivo, TC=Tarjetas Db/Cr, NC=Nota de Credito, AN=Anticipos, PM=Pagos Mixtos,
    -- CH=Cheques, DV=Divisas, AB=Abonos, VC=Ventas a Credito, OV=Otros Valores
    TipoValor             VARCHAR(2)     NOT NULL DEFAULT 'EF',

    -- Tipo de Valor para Informe Fiscal 607
    -- EF=Efectivo, TA=Tarjetas, PE=Permutas, BO=Bonos, CH=Cheques, CR=Credito, OT=Otros
    TipoValor607          VARCHAR(2)     NULL,

    -- Monedas
    IdMonedaBase          INT            NULL CONSTRAINT FK_FacFormasPago_MonBase FOREIGN KEY REFERENCES dbo.Monedas(IdMoneda),
    IdMonedaOrigen        INT            NULL CONSTRAINT FK_FacFormasPago_MonOrigen FOREIGN KEY REFERENCES dbo.Monedas(IdMoneda),

    -- Factor de conversion
    TasaCambioOrigen      DECIMAL(18,6)  NOT NULL DEFAULT 1.000000,
    TasaCambioBase        DECIMAL(18,6)  NOT NULL DEFAULT 1.000000,
    Factor                DECIMAL(18,6)  NOT NULL DEFAULT 1.000000,

    -- Opciones de cobro
    MostrarEnPantallaCobro BIT           NOT NULL DEFAULT 1,
    AutoConsumo            BIT           NOT NULL DEFAULT 0,
    MostrarEnCobrosMixtos  BIT           NOT NULL DEFAULT 0,
    AfectaCuadreCaja       BIT           NOT NULL DEFAULT 1,

    -- Posicion y grupo
    Posicion              INT            NOT NULL DEFAULT 1,
    GrupoCierre           NVARCHAR(50)   NULL,

    -- Personalizacion visual
    CantidadImpresiones   INT            NOT NULL DEFAULT 1,
    ColorFondo            VARCHAR(7)     NULL,   -- hex #000000
    ColorTexto            VARCHAR(7)     NULL,   -- hex #FFFFFF

    -- Control
    Activo                BIT            NOT NULL DEFAULT 1,
    RowStatus             INT            NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion       INT            NULL,
    FechaModificacion     DATETIME       NULL,
    UsuarioModificacion   INT            NULL
  )
  PRINT 'TABLE FacFormasPago CREATED'
END
GO

-- ============================================================
-- TABLE: FacFormaPagoPuntoEmision
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacFormaPagoPuntoEmision' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.FacFormaPagoPuntoEmision (
    IdFormaPago    INT NOT NULL,
    IdPuntoEmision INT NOT NULL,
    FechaCreacion  DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion INT NULL,
    CONSTRAINT PK_FacFormaPagoPE PRIMARY KEY (IdFormaPago, IdPuntoEmision),
    CONSTRAINT FK_FacFormaPagoPE_FP FOREIGN KEY (IdFormaPago) REFERENCES dbo.FacFormasPago(IdFormaPago),
    CONSTRAINT FK_FacFormaPagoPE_PE FOREIGN KEY (IdPuntoEmision) REFERENCES dbo.PuntosEmision(IdPuntoEmision)
  )
  PRINT 'TABLE FacFormaPagoPuntoEmision CREATED'
END
GO

-- ============================================================
-- SP: spFacFormasPagoCRUD
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spFacFormasPagoCRUD
  @Accion               NVARCHAR(10)   = 'L',
  @IdFormaPago           INT            = NULL,
  @Descripcion           NVARCHAR(150)  = NULL,
  @Comentario            NVARCHAR(500)  = NULL,
  @TipoValor             VARCHAR(2)     = NULL,
  @TipoValor607          VARCHAR(2)     = NULL,
  @IdMonedaBase          INT            = NULL,
  @IdMonedaOrigen        INT            = NULL,
  @TasaCambioOrigen      DECIMAL(18,6)  = NULL,
  @TasaCambioBase        DECIMAL(18,6)  = NULL,
  @Factor                DECIMAL(18,6)  = NULL,
  @MostrarEnPantallaCobro BIT           = NULL,
  @AutoConsumo           BIT            = NULL,
  @MostrarEnCobrosMixtos BIT            = NULL,
  @AfectaCuadreCaja      BIT            = NULL,
  @Posicion              INT            = NULL,
  @GrupoCierre           NVARCHAR(50)   = NULL,
  @CantidadImpresiones   INT            = NULL,
  @ColorFondo            VARCHAR(7)     = NULL,
  @ColorTexto            VARCHAR(7)     = NULL,
  @Activo                BIT            = NULL,
  @UsuarioAccion         INT            = NULL,
  @PuntosEmision         NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: Listar
  IF @Accion = 'L'
  BEGIN
    SELECT f.IdFormaPago, f.Descripcion, f.Comentario,
           f.TipoValor, f.TipoValor607,
           f.IdMonedaBase, mb.Nombre AS NombreMonedaBase, mb.Simbolo AS SimboloMonedaBase,
           f.IdMonedaOrigen, mo.Nombre AS NombreMonedaOrigen, mo.Simbolo AS SimboloMonedaOrigen,
           f.TasaCambioOrigen, f.TasaCambioBase, f.Factor,
           f.MostrarEnPantallaCobro, f.AutoConsumo, f.MostrarEnCobrosMixtos, f.AfectaCuadreCaja,
           f.Posicion, f.GrupoCierre,
           f.CantidadImpresiones, f.ColorFondo, f.ColorTexto,
           f.Activo,
           f.FechaCreacion, f.UsuarioCreacion, f.FechaModificacion, f.UsuarioModificacion
    FROM   dbo.FacFormasPago f
    LEFT JOIN dbo.Monedas mb ON mb.IdMoneda = f.IdMonedaBase
    LEFT JOIN dbo.Monedas mo ON mo.IdMoneda = f.IdMonedaOrigen
    WHERE  f.RowStatus = 1
    ORDER BY f.Posicion, f.Descripcion
    RETURN
  END

  -- O: Obtener uno
  IF @Accion = 'O'
  BEGIN
    SELECT f.IdFormaPago, f.Descripcion, f.Comentario,
           f.TipoValor, f.TipoValor607,
           f.IdMonedaBase, mb.Nombre AS NombreMonedaBase, mb.Simbolo AS SimboloMonedaBase,
           f.IdMonedaOrigen, mo.Nombre AS NombreMonedaOrigen, mo.Simbolo AS SimboloMonedaOrigen,
           f.TasaCambioOrigen, f.TasaCambioBase, f.Factor,
           f.MostrarEnPantallaCobro, f.AutoConsumo, f.MostrarEnCobrosMixtos, f.AfectaCuadreCaja,
           f.Posicion, f.GrupoCierre,
           f.CantidadImpresiones, f.ColorFondo, f.ColorTexto,
           f.Activo,
           f.FechaCreacion, f.UsuarioCreacion, f.FechaModificacion, f.UsuarioModificacion
    FROM   dbo.FacFormasPago f
    LEFT JOIN dbo.Monedas mb ON mb.IdMoneda = f.IdMonedaBase
    LEFT JOIN dbo.Monedas mo ON mo.IdMoneda = f.IdMonedaOrigen
    WHERE  f.IdFormaPago = @IdFormaPago AND f.RowStatus = 1
    RETURN
  END

  -- I: Insertar
  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.FacFormasPago (
      Descripcion, Comentario, TipoValor, TipoValor607,
      IdMonedaBase, IdMonedaOrigen, TasaCambioOrigen, TasaCambioBase, Factor,
      MostrarEnPantallaCobro, AutoConsumo, MostrarEnCobrosMixtos, AfectaCuadreCaja,
      Posicion, GrupoCierre, CantidadImpresiones, ColorFondo, ColorTexto,
      Activo, UsuarioCreacion
    ) VALUES (
      @Descripcion, @Comentario, ISNULL(@TipoValor, 'EF'), @TipoValor607,
      @IdMonedaBase, @IdMonedaOrigen,
      ISNULL(@TasaCambioOrigen, 1), ISNULL(@TasaCambioBase, 1), ISNULL(@Factor, 1),
      ISNULL(@MostrarEnPantallaCobro, 1), ISNULL(@AutoConsumo, 0),
      ISNULL(@MostrarEnCobrosMixtos, 0), ISNULL(@AfectaCuadreCaja, 1),
      ISNULL(@Posicion, 1), @GrupoCierre,
      ISNULL(@CantidadImpresiones, 1), @ColorFondo, @ColorTexto,
      ISNULL(@Activo, 1), @UsuarioAccion
    )

    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spFacFormasPagoCRUD @Accion = 'O', @IdFormaPago = @NewId
    RETURN
  END

  -- A: Actualizar
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.FacFormasPago
    SET    Descripcion           = ISNULL(@Descripcion, Descripcion),
           Comentario            = @Comentario,
           TipoValor             = ISNULL(@TipoValor, TipoValor),
           TipoValor607          = @TipoValor607,
           IdMonedaBase          = @IdMonedaBase,
           IdMonedaOrigen        = @IdMonedaOrigen,
           TasaCambioOrigen      = ISNULL(@TasaCambioOrigen, TasaCambioOrigen),
           TasaCambioBase        = ISNULL(@TasaCambioBase, TasaCambioBase),
           Factor                = ISNULL(@Factor, Factor),
           MostrarEnPantallaCobro = ISNULL(@MostrarEnPantallaCobro, MostrarEnPantallaCobro),
           AutoConsumo           = ISNULL(@AutoConsumo, AutoConsumo),
           MostrarEnCobrosMixtos = ISNULL(@MostrarEnCobrosMixtos, MostrarEnCobrosMixtos),
           AfectaCuadreCaja      = ISNULL(@AfectaCuadreCaja, AfectaCuadreCaja),
           Posicion              = ISNULL(@Posicion, Posicion),
           GrupoCierre           = @GrupoCierre,
           CantidadImpresiones   = ISNULL(@CantidadImpresiones, CantidadImpresiones),
           ColorFondo            = @ColorFondo,
           ColorTexto            = @ColorTexto,
           Activo                = ISNULL(@Activo, Activo),
           FechaModificacion     = GETDATE(),
           UsuarioModificacion   = @UsuarioAccion
    WHERE  IdFormaPago = @IdFormaPago AND RowStatus = 1

    EXEC dbo.spFacFormasPagoCRUD @Accion = 'O', @IdFormaPago = @IdFormaPago
    RETURN
  END

  -- D: Soft-delete
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacFormasPago
    SET    RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE  IdFormaPago = @IdFormaPago

    DELETE FROM dbo.FacFormaPagoPuntoEmision WHERE IdFormaPago = @IdFormaPago
    SELECT 'OK' AS Resultado
    RETURN
  END

  -- LP: Listar puntos de emision asociados
  IF @Accion = 'LP'
  BEGIN
    SELECT fp.IdFormaPago, fp.IdPuntoEmision, pe.Nombre AS NombrePuntoEmision
    FROM   dbo.FacFormaPagoPuntoEmision fp
    JOIN   dbo.PuntosEmision pe ON pe.IdPuntoEmision = fp.IdPuntoEmision
    WHERE  fp.IdFormaPago = @IdFormaPago
    ORDER  BY pe.Nombre
    RETURN
  END

  -- SP: Sincronizar puntos de emision
  IF @Accion = 'SP'
  BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
      DELETE FROM dbo.FacFormaPagoPuntoEmision WHERE IdFormaPago = @IdFormaPago

      IF @PuntosEmision IS NOT NULL AND LEN(LTRIM(RTRIM(@PuntosEmision))) > 0
      BEGIN
        INSERT INTO dbo.FacFormaPagoPuntoEmision (IdFormaPago, IdPuntoEmision, UsuarioCreacion)
        SELECT @IdFormaPago, CAST(value AS INT), @UsuarioAccion
        FROM   STRING_SPLIT(@PuntosEmision, ',')
        WHERE  LTRIM(RTRIM(value)) <> ''
          AND  EXISTS (SELECT 1 FROM dbo.PuntosEmision WHERE IdPuntoEmision = CAST(value AS INT))
      END

      COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
      ROLLBACK TRANSACTION
      THROW
    END CATCH

    EXEC dbo.spFacFormasPagoCRUD @Accion = 'LP', @IdFormaPago = @IdFormaPago
    RETURN
  END
END
GO

-- ============================================================
-- SEED: Formas de pago iniciales
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.FacFormasPago WHERE RowStatus = 1)
BEGIN
  INSERT INTO dbo.FacFormasPago (Descripcion, TipoValor, TipoValor607, Posicion, UsuarioCreacion) VALUES
    (N'EFECTIVO',        'EF', 'EF', 1, 1),
    (N'TARJETAS',        'TC', 'TA', 2, 1),
    (N'CHEQUES',         'CH', 'CH', 3, 1),
    (N'TRANSFERENCIAS',  'OV', 'OT', 4, 1),
    (N'CREDITO',         'VC', 'CR', 5, 1),
    (N'NOTA DE CREDITO', 'NC', 'OT', 6, 1)
  PRINT 'SEED: Formas de pago insertadas'
END
GO

-- ============================================================
-- PERMISOS
-- ============================================================
DECLARE @IdMod INT = (SELECT TOP 1 IdModulo FROM dbo.Modulos WHERE Nombre LIKE '%Factur%' AND RowStatus = 1)
IF @IdMod IS NULL SET @IdMod = 1

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/facturacion/formas-pago')
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, UsuarioCreacion) VALUES (@IdMod, N'Formas de Pago', '/config/facturacion/formas-pago', 1)
GO

SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.facturacion.formas-pago.view')
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Clave, Activo, UsuarioCreacion)
  SELECT p.IdPantalla, N'Formas de Pago', 'config.facturacion.formas-pago.view', 1, 1
  FROM dbo.Pantallas p WHERE p.Ruta = '/config/facturacion/formas-pago' AND p.RowStatus = 1
GO

INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, p.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM dbo.Pantallas p WHERE p.Ruta = '/config/facturacion/formas-pago' AND p.RowStatus = 1
  AND NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos rp WHERE rp.IdRol = 1 AND rp.IdPantalla = p.IdPantalla)
GO

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, UsuarioCreacion)
SELECT 1, pe.IdPermiso, 1, 1
FROM dbo.Permisos pe WHERE pe.Clave = 'config.facturacion.formas-pago.view'
  AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos rp WHERE rp.IdRol = 1 AND rp.IdPermiso = pe.IdPermiso)
GO

PRINT '=== Script 133 completado ==='
GO
