USE [DbMasuPOS];
GO

-- ============================================================
-- 151 - FacDocumentosPOS: documentos pausados / pendientes POS
-- ============================================================
-- Tablas:
--   FacDocumentosPOS        encabezado del documento en pausa
--   FacDocumentoPOSDetalle  lineas del documento
-- Columna nueva:
--   Terceros.PedirReferencia BIT
-- SP:
--   spFacDocumentosPOSCRUD  acciones I/U/L/O/X/E/R
-- ============================================================

-- ------------------------------------------------------------
-- 1. Columna PedirReferencia en Terceros
-- ------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.Terceros')
      AND name = 'PedirReferencia'
)
BEGIN
    ALTER TABLE dbo.Terceros
        ADD PedirReferencia BIT NOT NULL DEFAULT 0;
    PRINT 'Columna Terceros.PedirReferencia agregada.';
END
ELSE
    PRINT 'Columna Terceros.PedirReferencia ya existe.';
GO

-- ------------------------------------------------------------
-- 2. Tabla FacDocumentosPOS
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FacDocumentosPOS' AND type = 'U')
BEGIN
    CREATE TABLE dbo.FacDocumentosPOS (
        IdDocumentoPOS      INT IDENTITY(1,1)   NOT NULL,
        IdPuntoEmision      INT                 NOT NULL,
        IdUsuario           INT                 NOT NULL,
        IdCliente           INT                 NULL,
        NombreCliente       NVARCHAR(150)       NULL,   -- cliente final con nombre manual
        Referencia          NVARCHAR(100)       NULL,
        IdTipoDocumento     INT                 NULL,
        IdAlmacen           INT                 NULL,
        FechaDocumento      DATE                NOT NULL DEFAULT CAST(GETDATE() AS DATE),
        Vendedor            NVARCHAR(100)       NULL,
        Estado              NVARCHAR(20)        NOT NULL DEFAULT 'PAUSADO',
            -- PAUSADO    = en lista de pendientes, disponible para cargar
            -- EN_EDICION = cargado actualmente en un POS (bloqueado)
            -- EN_CAJA    = enviado a Caja Central
            -- RETORNADO  = devuelto desde Caja Central (equivale a PAUSADO)
            -- ANULADO    = cancelado
        Notas               NVARCHAR(500)       NULL,
        FechaCreacion       DATETIME            NOT NULL DEFAULT GETDATE(),
        FechaModificacion   DATETIME            NULL,
        IdUsuarioCreacion   INT                 NOT NULL,
        IdUsuarioModif      INT                 NULL,
        RowStatus           TINYINT             NOT NULL DEFAULT 1,

        CONSTRAINT PK_FacDocumentosPOS PRIMARY KEY (IdDocumentoPOS),
        CONSTRAINT FK_FacDocumentosPOS_PuntoEmision FOREIGN KEY (IdPuntoEmision)
            REFERENCES dbo.PuntosEmision(IdPuntoEmision),
        CONSTRAINT FK_FacDocumentosPOS_Usuario FOREIGN KEY (IdUsuario)
            REFERENCES dbo.Usuarios(IdUsuario),
        CONSTRAINT FK_FacDocumentosPOS_Cliente FOREIGN KEY (IdCliente)
            REFERENCES dbo.Terceros(IdTercero),
        CONSTRAINT CK_FacDocumentosPOS_Estado CHECK (
            Estado IN ('PAUSADO','EN_EDICION','EN_CAJA','RETORNADO','ANULADO')
        )
    );
    PRINT 'Tabla FacDocumentosPOS creada.';
END
ELSE
    PRINT 'Tabla FacDocumentosPOS ya existe.';
GO

-- ------------------------------------------------------------
-- 3. Tabla FacDocumentoPOSDetalle
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FacDocumentoPOSDetalle' AND type = 'U')
BEGIN
    CREATE TABLE dbo.FacDocumentoPOSDetalle (
        IdDetalle           INT IDENTITY(1,1)   NOT NULL,
        IdDocumentoPOS      INT                 NOT NULL,
        NumLinea            INT                 NOT NULL,
        IdProducto          INT                 NULL,
        Codigo              NVARCHAR(50)        NULL,
        Descripcion         NVARCHAR(200)       NULL,
        Cantidad            DECIMAL(18,4)       NOT NULL DEFAULT 1,
        Unidad              NVARCHAR(20)        NULL,
        PrecioBase          DECIMAL(18,4)       NOT NULL DEFAULT 0,
        PorcentajeImpuesto  DECIMAL(8,4)        NOT NULL DEFAULT 0,
        AplicaImpuesto      BIT                 NOT NULL DEFAULT 1,
        AplicaPropina       BIT                 NOT NULL DEFAULT 0,
        DescuentoLinea      DECIMAL(18,4)       NOT NULL DEFAULT 0,
        RowStatus           TINYINT             NOT NULL DEFAULT 1,

        CONSTRAINT PK_FacDocumentoPOSDetalle PRIMARY KEY (IdDetalle),
        CONSTRAINT FK_FacDocumentoPOSDetalle_Doc FOREIGN KEY (IdDocumentoPOS)
            REFERENCES dbo.FacDocumentosPOS(IdDocumentoPOS)
    );
    PRINT 'Tabla FacDocumentoPOSDetalle creada.';
END
ELSE
    PRINT 'Tabla FacDocumentoPOSDetalle ya existe.';
GO

-- ------------------------------------------------------------
-- 4. SP spFacDocumentosPOSCRUD
-- ------------------------------------------------------------
-- Acciones:
--   I  Insertar (pausar) documento nuevo con sus lineas
--   U  Actualizar encabezado (nombre, referencia, notas)
--   L  Listar documentos disponibles para un punto de emision
--      (Estado IN PAUSADO, RETORNADO)
--   O  Obtener un documento con sus lineas
--   X  Anular documento
--   E  Enviar a Caja Central  (PAUSADO/RETORNADO → EN_CAJA)
--   C  Cargar en POS          (PAUSADO/RETORNADO → EN_EDICION)
--   P  Pausar de nuevo        (EN_EDICION → PAUSADO)
--   R  Retornar desde caja    (EN_CAJA → RETORNADO)
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.spFacDocumentosPOSCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spFacDocumentosPOSCRUD;
GO

CREATE PROCEDURE dbo.spFacDocumentosPOSCRUD
    @Accion             CHAR(1),
    @IdDocumentoPOS     INT             = NULL,
    @IdPuntoEmision     INT             = NULL,
    @IdUsuario          INT             = NULL,
    @IdCliente          INT             = NULL,
    @NombreCliente      NVARCHAR(150)   = NULL,
    @Referencia         NVARCHAR(100)   = NULL,
    @IdTipoDocumento    INT             = NULL,
    @IdAlmacen          INT             = NULL,
    @FechaDocumento     DATE            = NULL,
    @Vendedor           NVARCHAR(100)   = NULL,
    @Notas              NVARCHAR(500)   = NULL,
    @LineasJson         NVARCHAR(MAX)   = NULL   -- JSON array de lineas para accion I/U
AS
BEGIN
    SET NOCOUNT ON;

    -- ── I: Insertar nuevo documento pausado ──────────────────
    IF @Accion = 'I'
    BEGIN
        DECLARE @NewId INT;

        INSERT INTO dbo.FacDocumentosPOS (
            IdPuntoEmision, IdUsuario, IdCliente, NombreCliente, Referencia,
            IdTipoDocumento, IdAlmacen, FechaDocumento, Vendedor,
            Estado, Notas, IdUsuarioCreacion
        ) VALUES (
            @IdPuntoEmision, @IdUsuario, @IdCliente, @NombreCliente, @Referencia,
            @IdTipoDocumento, @IdAlmacen,
            ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
            @Vendedor, 'PAUSADO', @Notas, @IdUsuario
        );
        SET @NewId = SCOPE_IDENTITY();

        -- Insertar lineas desde JSON
        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea
            )
            SELECT
                @NewId,
                CAST(j.NumLinea        AS INT),
                NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo,
                j.Descripcion,
                CAST(j.Cantidad        AS DECIMAL(18,4)),
                j.Unidad,
                CAST(j.PrecioBase      AS DECIMAL(18,4)),
                CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto  AS BIT),
                CAST(j.AplicaPropina   AS BIT),
                CAST(j.DescuentoLinea  AS DECIMAL(18,4))
            FROM OPENJSON(@LineasJson) WITH (
                NumLinea            INT             '$.numLinea',
                IdProducto          INT             '$.productId',
                Codigo              NVARCHAR(50)    '$.code',
                Descripcion         NVARCHAR(200)   '$.description',
                Cantidad            DECIMAL(18,4)   '$.quantity',
                Unidad              NVARCHAR(20)    '$.unit',
                PrecioBase          DECIMAL(18,4)   '$.basePrice',
                PorcentajeImpuesto  DECIMAL(8,4)    '$.taxRate',
                AplicaImpuesto      BIT             '$.applyTax',
                AplicaPropina       BIT             '$.applyTip',
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END

        SELECT @NewId AS IdDocumentoPOS;
        RETURN;
    END

    -- ── U: Actualizar encabezado + reemplazar lineas ─────────
    IF @Accion = 'U'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            IdCliente           = ISNULL(@IdCliente,        IdCliente),
            NombreCliente       = ISNULL(@NombreCliente,    NombreCliente),
            Referencia          = ISNULL(@Referencia,       Referencia),
            IdTipoDocumento     = ISNULL(@IdTipoDocumento,  IdTipoDocumento),
            IdAlmacen           = ISNULL(@IdAlmacen,        IdAlmacen),
            FechaDocumento      = ISNULL(@FechaDocumento,   FechaDocumento),
            Vendedor            = ISNULL(@Vendedor,         Vendedor),
            Notas               = ISNULL(@Notas,            Notas),
            FechaModificacion   = GETDATE(),
            IdUsuarioModif      = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS AND RowStatus = 1;

        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            -- Borrar lineas anteriores y reinsertar
            DELETE FROM dbo.FacDocumentoPOSDetalle
            WHERE IdDocumentoPOS = @IdDocumentoPOS;

            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea
            )
            SELECT
                @IdDocumentoPOS,
                CAST(j.NumLinea        AS INT),
                NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo,
                j.Descripcion,
                CAST(j.Cantidad        AS DECIMAL(18,4)),
                j.Unidad,
                CAST(j.PrecioBase      AS DECIMAL(18,4)),
                CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto  AS BIT),
                CAST(j.AplicaPropina   AS BIT),
                CAST(j.DescuentoLinea  AS DECIMAL(18,4))
            FROM OPENJSON(@LineasJson) WITH (
                NumLinea            INT             '$.numLinea',
                IdProducto          INT             '$.productId',
                Codigo              NVARCHAR(50)    '$.code',
                Descripcion         NVARCHAR(200)   '$.description',
                Cantidad            DECIMAL(18,4)   '$.quantity',
                Unidad              NVARCHAR(20)    '$.unit',
                PrecioBase          DECIMAL(18,4)   '$.basePrice',
                PorcentajeImpuesto  DECIMAL(8,4)    '$.taxRate',
                AplicaImpuesto      BIT             '$.applyTax',
                AplicaPropina       BIT             '$.applyTip',
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END

        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    -- ── L: Listar pendientes de un punto de emision ──────────
    IF @Accion = 'L'
    BEGIN
        SELECT
            D.IdDocumentoPOS,
            D.IdPuntoEmision,
            D.IdCliente,
            ISNULL(D.NombreCliente, T.Nombre)   AS NombreCliente,
            D.Referencia,
            D.IdTipoDocumento,
            TD.Descripcion                       AS NombreTipoDocumento,
            D.FechaDocumento,
            D.Vendedor,
            D.Estado,
            D.Notas,
            D.FechaCreacion,
            D.FechaModificacion,
            U.NombreCompleto                     AS NombreUsuario,
            -- Conteo de lineas con producto
            (SELECT COUNT(*) FROM dbo.FacDocumentoPOSDetalle DL
             WHERE DL.IdDocumentoPOS = D.IdDocumentoPOS
               AND DL.RowStatus = 1
               AND DL.IdProducto IS NOT NULL) AS CantidadLineas,
            -- Total estimado
            (SELECT SUM(
                (DL.Cantidad * DL.PrecioBase)
                + CASE WHEN DL.AplicaImpuesto = 1
                       THEN DL.Cantidad * DL.PrecioBase * (DL.PorcentajeImpuesto / 100)
                       ELSE 0 END
                - DL.DescuentoLinea
             ) FROM dbo.FacDocumentoPOSDetalle DL
             WHERE DL.IdDocumentoPOS = D.IdDocumentoPOS
               AND DL.RowStatus = 1) AS TotalEstimado
        FROM dbo.FacDocumentosPOS D
        LEFT JOIN dbo.Terceros T       ON T.IdTercero = D.IdCliente
        LEFT JOIN dbo.FacTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
        LEFT JOIN dbo.Usuarios U       ON U.IdUsuario = D.IdUsuario
        WHERE D.IdPuntoEmision = @IdPuntoEmision
          AND D.Estado IN ('PAUSADO', 'RETORNADO', 'EN_EDICION')
          AND D.RowStatus = 1
        ORDER BY D.FechaModificacion DESC, D.FechaCreacion DESC;
        RETURN;
    END

    -- ── O: Obtener un documento con sus lineas ───────────────
    IF @Accion = 'O'
    BEGIN
        -- Encabezado
        SELECT
            D.IdDocumentoPOS,
            D.IdPuntoEmision,
            D.IdCliente,
            ISNULL(D.NombreCliente, T.Nombre) AS NombreCliente,
            D.Referencia,
            D.IdTipoDocumento,
            D.IdAlmacen,
            D.FechaDocumento,
            D.Vendedor,
            D.Estado,
            D.Notas,
            D.FechaCreacion,
            D.IdUsuario,
            D.IdUsuarioCreacion
        FROM dbo.FacDocumentosPOS D
        LEFT JOIN dbo.Terceros T ON T.IdTercero = D.IdCliente
        WHERE D.IdDocumentoPOS = @IdDocumentoPOS AND D.RowStatus = 1;

        -- Lineas
        SELECT
            DL.IdDetalle,
            DL.NumLinea,
            DL.IdProducto,
            DL.Codigo,
            DL.Descripcion,
            DL.Cantidad,
            DL.Unidad,
            DL.PrecioBase,
            DL.PorcentajeImpuesto,
            DL.AplicaImpuesto,
            DL.AplicaPropina,
            DL.DescuentoLinea
        FROM dbo.FacDocumentoPOSDetalle DL
        WHERE DL.IdDocumentoPOS = @IdDocumentoPOS AND DL.RowStatus = 1
        ORDER BY DL.NumLinea;
        RETURN;
    END

    -- ── X: Anular ────────────────────────────────────────────
    IF @Accion = 'X'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            Estado              = 'ANULADO',
            FechaModificacion   = GETDATE(),
            IdUsuarioModif      = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado NOT IN ('ANULADO', 'EN_CAJA')
          AND RowStatus = 1;
        RETURN;
    END

    -- ── E: Enviar a Caja Central ─────────────────────────────
    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            NombreCliente       = ISNULL(@NombreCliente,    NombreCliente),
            Referencia          = ISNULL(@Referencia,       Referencia),
            Estado              = 'EN_CAJA',
            FechaModificacion   = GETDATE(),
            IdUsuarioModif      = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado IN ('PAUSADO', 'RETORNADO', 'EN_EDICION')
          AND RowStatus = 1;

        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    -- ── C: Cargar en POS (bloquear para edicion) ─────────────
    IF @Accion = 'C'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            Estado              = 'EN_EDICION',
            FechaModificacion   = GETDATE(),
            IdUsuarioModif      = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado IN ('PAUSADO', 'RETORNADO')
          AND RowStatus = 1;

        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    -- ── P: Pausar de nuevo (EN_EDICION → PAUSADO) ────────────
    IF @Accion = 'P'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            IdCliente           = ISNULL(@IdCliente,        IdCliente),
            NombreCliente       = ISNULL(@NombreCliente,    NombreCliente),
            Referencia          = ISNULL(@Referencia,       Referencia),
            IdTipoDocumento     = ISNULL(@IdTipoDocumento,  IdTipoDocumento),
            IdAlmacen           = ISNULL(@IdAlmacen,        IdAlmacen),
            FechaDocumento      = ISNULL(@FechaDocumento,   FechaDocumento),
            Vendedor            = ISNULL(@Vendedor,         Vendedor),
            Notas               = ISNULL(@Notas,            Notas),
            Estado              = 'PAUSADO',
            FechaModificacion   = GETDATE(),
            IdUsuarioModif      = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado = 'EN_EDICION'
          AND RowStatus = 1;

        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            DELETE FROM dbo.FacDocumentoPOSDetalle
            WHERE IdDocumentoPOS = @IdDocumentoPOS;

            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea
            )
            SELECT
                @IdDocumentoPOS,
                CAST(j.NumLinea        AS INT),
                NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo,
                j.Descripcion,
                CAST(j.Cantidad        AS DECIMAL(18,4)),
                j.Unidad,
                CAST(j.PrecioBase      AS DECIMAL(18,4)),
                CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto  AS BIT),
                CAST(j.AplicaPropina   AS BIT),
                CAST(j.DescuentoLinea  AS DECIMAL(18,4))
            FROM OPENJSON(@LineasJson) WITH (
                NumLinea            INT             '$.numLinea',
                IdProducto          INT             '$.productId',
                Codigo              NVARCHAR(50)    '$.code',
                Descripcion         NVARCHAR(200)   '$.description',
                Cantidad            DECIMAL(18,4)   '$.quantity',
                Unidad              NVARCHAR(20)    '$.unit',
                PrecioBase          DECIMAL(18,4)   '$.basePrice',
                PorcentajeImpuesto  DECIMAL(8,4)    '$.taxRate',
                AplicaImpuesto      BIT             '$.applyTax',
                AplicaPropina       BIT             '$.applyTip',
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END

        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    -- ── R: Retornar desde Caja Central ───────────────────────
    IF @Accion = 'R'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            Estado              = 'RETORNADO',
            FechaModificacion   = GETDATE(),
            IdUsuarioModif      = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado = 'EN_CAJA'
          AND RowStatus = 1;
        RETURN;
    END

END
GO

PRINT 'Script 151 aplicado correctamente.';
GO
