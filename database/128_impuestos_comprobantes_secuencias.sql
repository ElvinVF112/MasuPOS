-- ============================================================
-- Script 128: Impuestos — CatalogoNCF + SecuenciasNCF
-- Tables:  dbo.CatalogoNCF
--          dbo.SecuenciasNCF
--          dbo.HistorialDistribucionNCF
--          dbo.SecuenciasNCF_PuntosEmision
-- SPs:     dbo.spCatalogoNCFCRUD   (L/O/A)
--          dbo.spSecuenciasNCFCRUD (L/O/I/A/D/DIST/FILL/SWAP/STATUS)
--          dbo.spHistorialDistribucionNCF (L)
-- Seed:    Catálogo oficial DGII RD (físicos B* + electrónicos E*)
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- TABLE: CatalogoNCF
-- Catálogo oficial DGII + configuración del negocio
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CatalogoNCF' AND type = 'U')
BEGIN
  CREATE TABLE dbo.CatalogoNCF (
    IdCatalogoNCF       INT           NOT NULL IDENTITY(1,1),
    Codigo              NVARCHAR(10)  NOT NULL,
    Nombre              NVARCHAR(150) NOT NULL,
    NombreInterno       NVARCHAR(150) NULL,         -- nombre del negocio (editable)
    Descripcion         NVARCHAR(500) NULL,
    EsElectronico       BIT           NOT NULL DEFAULT 0,
    AplicaCredito       BIT           NOT NULL DEFAULT 0,
    AplicaContado       BIT           NOT NULL DEFAULT 1,
    RequiereRNC         BIT           NOT NULL DEFAULT 0,
    AplicaImpuesto      BIT           NOT NULL DEFAULT 1,
    ExoneraImpuesto     BIT           NOT NULL DEFAULT 0,
    Activo              BIT           NOT NULL DEFAULT 1,
    RowStatus           BIT           NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME      NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT           NULL,
    FechaModificacion   DATETIME      NULL,
    UsuarioModificacion INT           NULL,
    CONSTRAINT PK_CatalogoNCF PRIMARY KEY (IdCatalogoNCF)
  )
  PRINT 'TABLE CatalogoNCF CREATED'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_CatalogoNCF_Codigo' AND object_id = OBJECT_ID('dbo.CatalogoNCF'))
  CREATE UNIQUE INDEX UQ_CatalogoNCF_Codigo ON dbo.CatalogoNCF(Codigo) WHERE RowStatus = 1
GO

-- ============================================================
-- TABLE: SecuenciasNCF
-- Secuencias con modelo Madre (Distribución) / Hija (Operación)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'SecuenciasNCF' AND type = 'U')
BEGIN
  CREATE TABLE dbo.SecuenciasNCF (
    IdSecuencia         INT           NOT NULL IDENTITY(1,1),
    IdCatalogoNCF       INT           NOT NULL,
    IdPuntoEmision      INT           NULL,         -- NULL = global/madre
    IdSecuenciaMadre    INT           NULL,         -- NULL = es madre
    UsoComprobante      CHAR(1)       NOT NULL DEFAULT 'D',  -- D=Distribución, O=Operación
    Descripcion         NVARCHAR(200) NULL,

    -- e-CF (proveedor/procesamiento se configura en Empresa al integrar e-CF)
    EsElectronico       BIT           NOT NULL DEFAULT 0,
    DigitosSecuencia    TINYINT       NOT NULL DEFAULT 8,

    -- Rango "En Uso"
    Prefijo             NVARCHAR(10)  NULL,
    RangoDesde          BIGINT        NOT NULL DEFAULT 1,
    RangoHasta          BIGINT        NOT NULL DEFAULT 1,
    SecuenciaActual     BIGINT        NOT NULL DEFAULT 0,    -- 0 = no iniciada
    FechaVencimiento    DATE          NULL,

    -- Rango "En Cola"
    ColaPrefijo         NVARCHAR(10)  NULL,
    ColaRangoDesde      BIGINT        NULL,
    ColaRangoHasta      BIGINT        NULL,
    ColaFechaVencimiento DATE         NULL,

    -- Alertas y auto-relleno
    MinimoParaAlertar   INT           NOT NULL DEFAULT 10,
    RellenoAutomatico   INT           NULL,         -- NULL = relleno manual

    -- Estado
    Agotado             BIT           NOT NULL DEFAULT 0,
    Activo              BIT           NOT NULL DEFAULT 1,
    RowStatus           BIT           NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME      NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT           NULL,
    FechaModificacion   DATETIME      NULL,
    UsuarioModificacion INT           NULL,

    CONSTRAINT PK_SecuenciasNCF PRIMARY KEY (IdSecuencia),
    CONSTRAINT FK_SecuenciasNCF_Catalogo FOREIGN KEY (IdCatalogoNCF) REFERENCES dbo.CatalogoNCF(IdCatalogoNCF),
    CONSTRAINT FK_SecuenciasNCF_Madre FOREIGN KEY (IdSecuenciaMadre) REFERENCES dbo.SecuenciasNCF(IdSecuencia),
    CONSTRAINT CHK_SecuenciasNCF_Uso CHECK (UsoComprobante IN ('D','O')),
    CONSTRAINT CHK_SecuenciasNCF_Digitos CHECK (DigitosSecuencia IN (8,10))
  )
  PRINT 'TABLE SecuenciasNCF CREATED'
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SecuenciasNCF_Catalogo' AND object_id = OBJECT_ID('dbo.SecuenciasNCF'))
  CREATE INDEX IX_SecuenciasNCF_Catalogo ON dbo.SecuenciasNCF(IdCatalogoNCF) WHERE RowStatus = 1
GO

-- ============================================================
-- TABLE: HistorialDistribucionNCF
-- Auditoría de distribuciones madre → hija
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'HistorialDistribucionNCF' AND type = 'U')
BEGIN
  CREATE TABLE dbo.HistorialDistribucionNCF (
    IdHistorial           INT      NOT NULL IDENTITY(1,1),
    IdSecuenciaMadre      INT      NOT NULL,
    IdSecuenciaHija       INT      NOT NULL,
    CantidadDistribuida   BIGINT   NOT NULL,
    RangoDesde            BIGINT   NOT NULL,
    RangoHasta            BIGINT   NOT NULL,
    FechaDistribucion     DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioDistribucion   INT      NULL,
    Observacion           NVARCHAR(300) NULL,
    FechaCreacion         DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion       INT      NULL,
    FechaModificacion     DATETIME NULL,
    UsuarioModificacion   INT      NULL,
    CONSTRAINT PK_HistorialDistribucionNCF PRIMARY KEY (IdHistorial),
    CONSTRAINT FK_HistNCF_Madre FOREIGN KEY (IdSecuenciaMadre) REFERENCES dbo.SecuenciasNCF(IdSecuencia),
    CONSTRAINT FK_HistNCF_Hija  FOREIGN KEY (IdSecuenciaHija)  REFERENCES dbo.SecuenciasNCF(IdSecuencia)
  )
  PRINT 'TABLE HistorialDistribucionNCF CREATED'
END
GO

-- ============================================================
-- TABLE: SecuenciasNCF_PuntosEmision
-- Permite compartir una secuencia hija entre múltiples puntos
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'SecuenciasNCF_PuntosEmision' AND type = 'U')
BEGIN
  CREATE TABLE dbo.SecuenciasNCF_PuntosEmision (
    IdSecuencia    INT NOT NULL,
    IdPuntoEmision INT NOT NULL,
    FechaCreacion  DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion INT NULL,
    CONSTRAINT PK_SecuenciasNCF_PuntosEmision PRIMARY KEY (IdSecuencia, IdPuntoEmision),
    CONSTRAINT FK_SecPE_Secuencia FOREIGN KEY (IdSecuencia) REFERENCES dbo.SecuenciasNCF(IdSecuencia),
    CONSTRAINT FK_SecPE_Punto FOREIGN KEY (IdPuntoEmision) REFERENCES dbo.PuntosEmision(IdPuntoEmision)
  )
  PRINT 'TABLE SecuenciasNCF_PuntosEmision CREATED'
END
GO

-- ============================================================
-- SP: spCatalogoNCFCRUD  (L/O/A — el catálogo es oficial, no se crea/borra)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spCatalogoNCFCRUD
  @Accion             CHAR(1)       = 'L',
  @IdCatalogoNCF      INT           = NULL,
  @NombreInterno      NVARCHAR(150) = NULL,
  @Activo             BIT           = NULL,
  @UsuarioAccion      INT           = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: Listar todos
  IF @Accion = 'L'
  BEGIN
    SELECT IdCatalogoNCF, Codigo, Nombre, NombreInterno,
           Descripcion, EsElectronico, AplicaCredito, AplicaContado,
           RequiereRNC, AplicaImpuesto, ExoneraImpuesto, Activo,
           FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM   dbo.CatalogoNCF
    WHERE  RowStatus = 1
    ORDER  BY Codigo
    RETURN
  END

  -- O: Uno por ID
  IF @Accion = 'O'
  BEGIN
    SELECT IdCatalogoNCF, Codigo, Nombre, NombreInterno,
           Descripcion, EsElectronico, AplicaCredito, AplicaContado,
           RequiereRNC, AplicaImpuesto, ExoneraImpuesto, Activo,
           FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM   dbo.CatalogoNCF
    WHERE  IdCatalogoNCF = @IdCatalogoNCF AND RowStatus = 1
    RETURN
  END

  -- A: Actualizar nombre interno y activo (lo demás es catálogo oficial)
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.CatalogoNCF
    SET    NombreInterno      = ISNULL(@NombreInterno, NombreInterno),
           Activo             = ISNULL(@Activo, Activo),
           FechaModificacion  = GETDATE(),
           UsuarioModificacion= @UsuarioAccion
    WHERE  IdCatalogoNCF = @IdCatalogoNCF AND RowStatus = 1

    EXEC dbo.spCatalogoNCFCRUD @Accion = 'O', @IdCatalogoNCF = @IdCatalogoNCF
    RETURN
  END
END
GO

-- ============================================================
-- SP: spSecuenciasNCFCRUD
-- Acciones: L / O / I / A / D / DIST / FILL / SWAP / STATUS
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spSecuenciasNCFCRUD
  @Accion              NVARCHAR(10)  = 'L',
  @IdSecuencia         INT           = NULL,
  @IdCatalogoNCF       INT           = NULL,
  @IdPuntoEmision      INT           = NULL,
  @IdSecuenciaMadre    INT           = NULL,
  @UsoComprobante      CHAR(1)       = NULL,
  @Descripcion         NVARCHAR(200) = NULL,
  @EsElectronico       BIT           = NULL,
  @DigitosSecuencia    TINYINT       = NULL,
  @Prefijo             NVARCHAR(10)  = NULL,
  @RangoDesde          BIGINT        = NULL,
  @RangoHasta          BIGINT        = NULL,
  @SecuenciaActual     BIGINT        = NULL,
  @FechaVencimiento    DATE          = NULL,
  @ColaPrefijo         NVARCHAR(10)  = NULL,
  @ColaRangoDesde      BIGINT        = NULL,
  @ColaRangoHasta      BIGINT        = NULL,
  @ColaFechaVencimiento DATE         = NULL,
  @MinimoParaAlertar   INT           = NULL,
  @RellenoAutomatico   INT           = NULL,
  @Activo              BIT           = NULL,
  -- Para DIST: cantidad a distribuir a la hija
  @CantidadDistribuir  BIGINT        = NULL,
  @Observacion         NVARCHAR(300) = NULL,
  @UsuarioAccion       INT           = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET QUOTED_IDENTIFIER ON;

  -- ===========================================================
  -- L: Listar secuencias con info del catálogo y punto de emisión
  -- ===========================================================
  IF @Accion = 'L'
  BEGIN
    SELECT S.IdSecuencia, S.IdCatalogoNCF,
           C.Codigo AS CodigoNCF,
           ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
           C.EsElectronico AS CatEsElectronico,
           S.IdPuntoEmision,
           PE.Nombre AS NombrePuntoEmision,
           S.IdSecuenciaMadre,
           SM.Descripcion AS DescripcionMadre,
           S.UsoComprobante, S.Descripcion,
           S.EsElectronico, S.DigitosSecuencia,
           S.Prefijo, S.RangoDesde, S.RangoHasta, S.SecuenciaActual, S.FechaVencimiento,
           S.ColaPrefijo, S.ColaRangoDesde, S.ColaRangoHasta, S.ColaFechaVencimiento,
           S.MinimoParaAlertar, S.RellenoAutomatico,
           S.Agotado, S.Activo,
           -- Calculados
           CASE WHEN S.SecuenciaActual = 0 THEN S.RangoHasta - S.RangoDesde + 1
                ELSE S.RangoHasta - S.SecuenciaActual END AS CantidadRestante,
           S.RangoHasta - S.RangoDesde + 1 AS CantidadRegistrada,
           S.FechaCreacion, S.UsuarioCreacion, S.FechaModificacion, S.UsuarioModificacion
    FROM   dbo.SecuenciasNCF S
    JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
    LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = S.IdPuntoEmision
    LEFT JOIN dbo.SecuenciasNCF SM ON SM.IdSecuencia = S.IdSecuenciaMadre
    WHERE  S.RowStatus = 1
    ORDER  BY C.Codigo, S.UsoComprobante, S.IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- O: Una secuencia por ID
  -- ===========================================================
  IF @Accion = 'O'
  BEGIN
    SELECT S.IdSecuencia, S.IdCatalogoNCF,
           C.Codigo AS CodigoNCF,
           ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
           C.EsElectronico AS CatEsElectronico,
           S.IdPuntoEmision,
           PE.Nombre AS NombrePuntoEmision,
           S.IdSecuenciaMadre,
           SM.Descripcion AS DescripcionMadre,
           S.UsoComprobante, S.Descripcion,
           S.EsElectronico, S.DigitosSecuencia,
           S.Prefijo, S.RangoDesde, S.RangoHasta, S.SecuenciaActual, S.FechaVencimiento,
           S.ColaPrefijo, S.ColaRangoDesde, S.ColaRangoHasta, S.ColaFechaVencimiento,
           S.MinimoParaAlertar, S.RellenoAutomatico,
           S.Agotado, S.Activo,
           CASE WHEN S.SecuenciaActual = 0 THEN S.RangoHasta - S.RangoDesde + 1
                ELSE S.RangoHasta - S.SecuenciaActual END AS CantidadRestante,
           S.RangoHasta - S.RangoDesde + 1 AS CantidadRegistrada,
           S.FechaCreacion, S.UsuarioCreacion, S.FechaModificacion, S.UsuarioModificacion
    FROM   dbo.SecuenciasNCF S
    JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
    LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = S.IdPuntoEmision
    LEFT JOIN dbo.SecuenciasNCF SM ON SM.IdSecuencia = S.IdSecuenciaMadre
    WHERE  S.IdSecuencia = @IdSecuencia AND S.RowStatus = 1
    RETURN
  END

  -- ===========================================================
  -- I: Insertar nueva secuencia
  -- ===========================================================
  IF @Accion = 'I'
  BEGIN
    -- Validaciones
    IF @IdCatalogoNCF IS NULL
      THROW 50001, 'El tipo de comprobante (CatalogoNCF) es obligatorio.', 1

    IF @UsoComprobante = 'O' AND @IdSecuenciaMadre IS NULL
      THROW 50002, 'Una secuencia de Operación debe tener una secuencia madre.', 1

    IF @RangoDesde IS NULL OR @RangoHasta IS NULL OR @RangoDesde > @RangoHasta
      THROW 50003, 'El rango es inválido. RangoDesde debe ser <= RangoHasta.', 1

    DECLARE @NewId INT

    INSERT INTO dbo.SecuenciasNCF (
      IdCatalogoNCF, IdPuntoEmision, IdSecuenciaMadre, UsoComprobante, Descripcion,
      EsElectronico, DigitosSecuencia,
      Prefijo, RangoDesde, RangoHasta, SecuenciaActual, FechaVencimiento,
      ColaPrefijo, ColaRangoDesde, ColaRangoHasta, ColaFechaVencimiento,
      MinimoParaAlertar, RellenoAutomatico,
      Activo, UsuarioCreacion
    ) VALUES (
      @IdCatalogoNCF, @IdPuntoEmision, @IdSecuenciaMadre,
      ISNULL(@UsoComprobante, 'D'), @Descripcion,
      ISNULL(@EsElectronico, 0), ISNULL(@DigitosSecuencia, 8),
      @Prefijo, @RangoDesde, @RangoHasta, ISNULL(@SecuenciaActual, 0), @FechaVencimiento,
      @ColaPrefijo, @ColaRangoDesde, @ColaRangoHasta, @ColaFechaVencimiento,
      ISNULL(@MinimoParaAlertar, 10), @RellenoAutomatico,
      ISNULL(@Activo, 1), @UsuarioAccion
    )

    SET @NewId = SCOPE_IDENTITY()
    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @NewId
    RETURN
  END

  -- ===========================================================
  -- A: Actualizar secuencia
  -- ===========================================================
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.SecuenciasNCF
    SET    IdCatalogoNCF       = ISNULL(@IdCatalogoNCF, IdCatalogoNCF),
           IdPuntoEmision      = @IdPuntoEmision,         -- permite NULL explícito
           IdSecuenciaMadre    = @IdSecuenciaMadre,
           UsoComprobante      = ISNULL(@UsoComprobante, UsoComprobante),
           Descripcion         = ISNULL(@Descripcion, Descripcion),
           EsElectronico       = ISNULL(@EsElectronico, EsElectronico),
           DigitosSecuencia    = ISNULL(@DigitosSecuencia, DigitosSecuencia),
           Prefijo             = ISNULL(@Prefijo, Prefijo),
           RangoDesde          = ISNULL(@RangoDesde, RangoDesde),
           RangoHasta          = ISNULL(@RangoHasta, RangoHasta),
           SecuenciaActual     = ISNULL(@SecuenciaActual, SecuenciaActual),
           FechaVencimiento    = @FechaVencimiento,
           ColaPrefijo         = @ColaPrefijo,
           ColaRangoDesde      = @ColaRangoDesde,
           ColaRangoHasta      = @ColaRangoHasta,
           ColaFechaVencimiento= @ColaFechaVencimiento,
           MinimoParaAlertar   = ISNULL(@MinimoParaAlertar, MinimoParaAlertar),
           RellenoAutomatico   = @RellenoAutomatico,
           Activo              = ISNULL(@Activo, Activo),
           FechaModificacion   = GETDATE(),
           UsuarioModificacion = @UsuarioAccion
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- D: Soft-delete
  -- ===========================================================
  IF @Accion = 'D'
  BEGIN
    -- No eliminar si tiene hijas activas
    IF EXISTS (SELECT 1 FROM dbo.SecuenciasNCF WHERE IdSecuenciaMadre = @IdSecuencia AND RowStatus = 1)
      THROW 50004, 'No se puede eliminar: tiene secuencias hijas asociadas.', 1

    UPDATE dbo.SecuenciasNCF
    SET    RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE  IdSecuencia = @IdSecuencia

    -- Eliminar también sus asociaciones con puntos de emisión
    DELETE FROM dbo.SecuenciasNCF_PuntosEmision WHERE IdSecuencia = @IdSecuencia

    SELECT 'OK' AS Resultado
    RETURN
  END

  -- ===========================================================
  -- DIST: Distribución manual madre → hija
  -- Resta @CantidadDistribuir de la madre y la asigna a la hija
  -- (al rango "En Uso" si está vacío, sino al "En Cola")
  -- ===========================================================
  IF @Accion = 'DIST'
  BEGIN
    IF @IdSecuencia IS NULL OR @IdSecuenciaMadre IS NULL
      THROW 50005, 'Se requiere IdSecuencia (hija) e IdSecuenciaMadre.', 1

    IF @CantidadDistribuir IS NULL OR @CantidadDistribuir <= 0
      THROW 50006, 'La cantidad a distribuir debe ser mayor a cero.', 1

    -- Verificar disponibilidad en la madre
    DECLARE @MadreHasta BIGINT, @MadreActual BIGINT, @MadreDisponible BIGINT
    SELECT @MadreHasta   = RangoHasta,
           @MadreActual  = SecuenciaActual
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuenciaMadre AND RowStatus = 1

    IF @MadreHasta IS NULL
      THROW 50007, 'La secuencia madre no existe o está inactiva.', 1

    SET @MadreDisponible = @MadreHasta - CASE WHEN @MadreActual = 0 THEN @MadreHasta - @MadreHasta ELSE @MadreActual END

    -- Calcular desde dónde se distribuye (después de SecuenciaActual de la madre)
    DECLARE @DistDesde BIGINT, @DistHasta BIGINT
    DECLARE @MadreRangoDesde BIGINT
    SELECT @MadreRangoDesde = RangoDesde FROM dbo.SecuenciasNCF WHERE IdSecuencia = @IdSecuenciaMadre

    -- El bloque que se distribuye es el siguiente disponible en la madre
    IF @MadreActual = 0
      SET @DistDesde = @MadreRangoDesde
    ELSE
      SET @DistDesde = @MadreActual + 1

    SET @DistHasta = @DistDesde + @CantidadDistribuir - 1

    IF @DistHasta > @MadreHasta
      THROW 50008, 'La cantidad solicitada supera el rango disponible en la madre.', 1

    -- Determinar si va a "En Uso" o a "En Cola" de la hija
    DECLARE @HijaRangoDesde BIGINT, @HijaRangoHasta BIGINT, @HijaColaDesde BIGINT
    SELECT @HijaRangoDesde = RangoDesde,
           @HijaRangoHasta = RangoHasta,
           @HijaColaDesde  = ColaRangoDesde
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    IF @HijaRangoHasta IS NULL
      THROW 50009, 'La secuencia hija no existe.', 1

    BEGIN TRANSACTION

    BEGIN TRY
      -- Actualizar la madre: avanzar SecuenciaActual
      UPDATE dbo.SecuenciasNCF
      SET    SecuenciaActual   = @DistHasta,
             FechaModificacion = GETDATE(),
             UsuarioModificacion = @UsuarioAccion
      WHERE  IdSecuencia = @IdSecuenciaMadre

      -- Actualizar la hija: asignar a En Cola si En Uso ya tiene rango, sino a En Uso
      IF @HijaColaDesde IS NULL
      BEGIN
        -- Cargar en En Cola
        UPDATE dbo.SecuenciasNCF
        SET    ColaRangoDesde      = @DistDesde,
               ColaRangoHasta      = @DistHasta,
               FechaModificacion   = GETDATE(),
               UsuarioModificacion = @UsuarioAccion
        WHERE  IdSecuencia = @IdSecuencia
      END
      ELSE
      BEGIN
        -- Ya tiene cola — actualizar la cola existente extendiendo el rango
        UPDATE dbo.SecuenciasNCF
        SET    ColaRangoHasta      = @DistHasta,
               FechaModificacion   = GETDATE(),
               UsuarioModificacion = @UsuarioAccion
        WHERE  IdSecuencia = @IdSecuencia
      END

      -- Registrar en historial
      INSERT INTO dbo.HistorialDistribucionNCF
        (IdSecuenciaMadre, IdSecuenciaHija, CantidadDistribuida, RangoDesde, RangoHasta, UsuarioDistribucion, Observacion, UsuarioCreacion)
      VALUES
        (@IdSecuenciaMadre, @IdSecuencia, @CantidadDistribuir, @DistDesde, @DistHasta, @UsuarioAccion, @Observacion, @UsuarioAccion)

      COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
      ROLLBACK TRANSACTION
      THROW
    END CATCH

    -- Retornar la hija actualizada
    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- FILL: Auto-relleno — llama DIST con RellenoAutomatico configurado
  -- ===========================================================
  IF @Accion = 'FILL'
  BEGIN
    DECLARE @AutoCantidad INT, @AutoMadre INT

    SELECT @AutoCantidad = RellenoAutomatico,
           @AutoMadre    = IdSecuenciaMadre
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    IF @AutoCantidad IS NULL
      THROW 50010, 'Esta secuencia no tiene relleno automático configurado.', 1

    IF @AutoMadre IS NULL
      THROW 50011, 'Esta secuencia no tiene madre asignada para el relleno.', 1

    EXEC dbo.spSecuenciasNCFCRUD
      @Accion           = 'DIST',
      @IdSecuencia      = @IdSecuencia,
      @IdSecuenciaMadre = @AutoMadre,
      @CantidadDistribuir = @AutoCantidad,
      @Observacion      = 'Relleno automático',
      @UsuarioAccion    = @UsuarioAccion
    RETURN
  END

  -- ===========================================================
  -- SWAP: Promover Cola → En Uso cuando el rango activo se agota
  -- ===========================================================
  IF @Accion = 'SWAP'
  BEGIN
    DECLARE @ColaDesde BIGINT, @ColaHasta BIGINT, @ColaPref NVARCHAR(10), @ColaFecha DATE

    SELECT @ColaPref  = ColaPrefijo,
           @ColaDesde = ColaRangoDesde,
           @ColaHasta = ColaRangoHasta,
           @ColaFecha = ColaFechaVencimiento
    FROM   dbo.SecuenciasNCF
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    IF @ColaDesde IS NULL
      THROW 50012, 'No hay rango En Cola disponible para promover.', 1

    UPDATE dbo.SecuenciasNCF
    SET    Prefijo             = ISNULL(@ColaPref, Prefijo),
           RangoDesde         = @ColaDesde,
           RangoHasta         = @ColaHasta,
           SecuenciaActual    = 0,
           FechaVencimiento   = @ColaFecha,
           ColaPrefijo        = NULL,
           ColaRangoDesde     = NULL,
           ColaRangoHasta     = NULL,
           ColaFechaVencimiento = NULL,
           Agotado            = 0,
           FechaModificacion  = GETDATE(),
           UsuarioModificacion= @UsuarioAccion
    WHERE  IdSecuencia = @IdSecuencia AND RowStatus = 1

    EXEC dbo.spSecuenciasNCFCRUD @Accion = 'O', @IdSecuencia = @IdSecuencia
    RETURN
  END

  -- ===========================================================
  -- STATUS: Estadísticas de consumo (para alertas / dashboard)
  -- ===========================================================
  IF @Accion = 'STATUS'
  BEGIN
    SELECT S.IdSecuencia,
           S.Descripcion,
           ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
           C.Codigo AS CodigoNCF,
           S.RangoDesde, S.RangoHasta, S.SecuenciaActual,
           S.RangoHasta - S.RangoDesde + 1 AS CantidadRegistrada,
           CASE WHEN S.SecuenciaActual = 0 THEN S.RangoHasta - S.RangoDesde + 1
                ELSE S.RangoHasta - S.SecuenciaActual END AS CantidadRestante,
           S.MinimoParaAlertar,
           CASE WHEN (CASE WHEN S.SecuenciaActual = 0 THEN S.RangoHasta - S.RangoDesde + 1
                           ELSE S.RangoHasta - S.SecuenciaActual END) <= S.MinimoParaAlertar
                THEN 1 ELSE 0 END AS EnAlerta,
           S.Agotado,
           S.ColaRangoDesde, S.ColaRangoHasta,
           CASE WHEN S.ColaRangoDesde IS NOT NULL THEN S.ColaRangoHasta - S.ColaRangoDesde + 1 ELSE 0 END AS CantidadEnCola
    FROM   dbo.SecuenciasNCF S
    JOIN   dbo.CatalogoNCF C ON C.IdCatalogoNCF = S.IdCatalogoNCF
    WHERE  S.RowStatus = 1 AND S.Activo = 1
      AND  (@IdSecuencia IS NULL OR S.IdSecuencia = @IdSecuencia)
    ORDER  BY EnAlerta DESC, CantidadRestante ASC
    RETURN
  END
END
GO

-- ============================================================
-- SP: spHistorialDistribucionNCF  (L con filtros)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spHistorialDistribucionNCF
  @Accion           CHAR(1) = 'L',
  @IdSecuenciaMadre INT     = NULL,
  @IdSecuenciaHija  INT     = NULL,
  @FechaDesde       DATE    = NULL,
  @FechaHasta       DATE    = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT H.IdHistorial,
         H.IdSecuenciaMadre, SM.Descripcion AS DescripcionMadre,
         H.IdSecuenciaHija,  SH.Descripcion AS DescripcionHija,
         PE.Nombre AS NombrePuntoEmision,
         ISNULL(C.NombreInterno, C.Nombre) AS NombreNCF,
         H.CantidadDistribuida,
         H.RangoDesde, H.RangoHasta,
         H.FechaDistribucion,
         H.UsuarioDistribucion,
         H.Observacion
  FROM   dbo.HistorialDistribucionNCF H
  JOIN   dbo.SecuenciasNCF SM ON SM.IdSecuencia = H.IdSecuenciaMadre
  JOIN   dbo.SecuenciasNCF SH ON SH.IdSecuencia = H.IdSecuenciaHija
  JOIN   dbo.CatalogoNCF   C  ON C.IdCatalogoNCF = SM.IdCatalogoNCF
  LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = SH.IdPuntoEmision
  WHERE  (@IdSecuenciaMadre IS NULL OR H.IdSecuenciaMadre = @IdSecuenciaMadre)
    AND  (@IdSecuenciaHija  IS NULL OR H.IdSecuenciaHija  = @IdSecuenciaHija)
    AND  (@FechaDesde IS NULL OR CAST(H.FechaDistribucion AS DATE) >= @FechaDesde)
    AND  (@FechaHasta IS NULL OR CAST(H.FechaDistribucion AS DATE) <= @FechaHasta)
  ORDER  BY H.FechaDistribucion DESC
END
GO

-- ============================================================
-- SEED: Catálogo oficial DGII República Dominicana
-- Físicos: B01, B02, B11, B14, B15, B16, B17
-- Electrónicos: E31, E32, E33, E34, E41, E43, E44, E45, E46, E47
-- ============================================================

-- Físicos
IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B01')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B01', 'Facturas de Crédito Fiscal', 'Para personas jurídicas y contribuyentes con RNC. Genera crédito fiscal deducible de ITBIS.', 0, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B02')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B02', 'Facturas de Consumo', 'Para consumidores finales. No genera crédito fiscal.', 0, 0, 1, 0, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B11')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B11', 'Notas de Débito', 'Para aumentar el valor de facturas ya emitidas.', 0, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B14')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B14', 'Regímenes Especiales de Tributación', 'Para contribuyentes bajo regímenes especiales.', 0, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B15')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B15', 'Gubernamental', 'Para operaciones con el gobierno y entidades públicas.', 0, 0, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B16')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B16', 'Exportaciones', 'Para comprobantes de exportación. Tasa de ITBIS 0%.', 0, 0, 1, 1, 0, 1)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'B17')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('B17', 'Pagos al Exterior', 'Para pagos a proveedores o servicios del exterior.', 0, 0, 1, 1, 0, 0)

-- Electrónicos (e-CF)
IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E31')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E31', 'Facturas de Crédito Fiscal Electrónicas', 'e-CF para crédito fiscal. Requiere RNC del receptor.', 1, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E32')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E32', 'Facturas de Consumo Electrónicas', 'e-CF para consumidores finales.', 1, 0, 1, 0, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E33')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E33', 'Notas de Débito Electrónicas', 'e-CF para notas de débito.', 1, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E34')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E34', 'Notas de Crédito Electrónicas', 'e-CF para notas de crédito.', 1, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E41')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E41', 'Compras Electrónicas', 'e-CF para compras a proveedores.', 1, 0, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E43')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E43', 'Gastos Menores Electrónicos', 'e-CF para gastos menores que no excedan el límite DGII.', 1, 0, 1, 0, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E44')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E44', 'Regímenes Especiales Electrónicos', 'e-CF para regímenes especiales de tributación.', 1, 1, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E45')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E45', 'Gubernamental Electrónico', 'e-CF para operaciones con el gobierno.', 1, 0, 1, 1, 1, 0)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E46')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E46', 'Exportaciones Electrónicas', 'e-CF para exportaciones. ITBIS 0%.', 1, 0, 1, 1, 0, 1)

IF NOT EXISTS (SELECT 1 FROM dbo.CatalogoNCF WHERE Codigo = 'E47')
  INSERT INTO dbo.CatalogoNCF (Codigo, Nombre, Descripcion, EsElectronico, AplicaCredito, AplicaContado, RequiereRNC, AplicaImpuesto, ExoneraImpuesto)
  VALUES ('E47', 'Pagos al Exterior Electrónicos', 'e-CF para pagos a proveedores o servicios del exterior.', 1, 0, 1, 1, 0, 0)

PRINT 'SEED CatalogoNCF OK — 15 tipos (7 físicos + 8 electrónicos)'
GO

PRINT '=== Script 128 completado ==='
GO
