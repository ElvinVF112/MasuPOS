-- ============================================================
-- 155_fac_documentos_pos_sin_estado.sql
-- Elimina la columna Estado de FacDocumentosPOS
-- (y su CHECK constraint si existe)
-- Reescribe spFacDocumentosPOSCRUD con acciones I/U/L/O/X
--   I = Insertar nuevo documento
--   U = Actualizar + reemplazar lineas
--   L = Listar documentos pendientes del punto de emisión
--   O = Obtener documento con sus lineas
--   X = Anular (soft-delete via RowStatus)
-- ============================================================

-- 1. Quitar DEFAULT constraint de Estado si existe
DECLARE @df NVARCHAR(200);
SELECT @df = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE dc.parent_object_id = OBJECT_ID('dbo.FacDocumentosPOS')
  AND c.name = 'Estado';
IF @df IS NOT NULL
BEGIN
    EXEC('ALTER TABLE dbo.FacDocumentosPOS DROP CONSTRAINT [' + @df + ']');
    PRINT 'DEFAULT constraint de Estado eliminado.';
END
ELSE
    PRINT 'No se encontro DEFAULT constraint de Estado.';
GO

-- 2. Quitar CHECK constraint de Estado si existe
DECLARE @ck NVARCHAR(200);
SELECT @ck = name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dbo.FacDocumentosPOS')
  AND definition LIKE '%Estado%';
IF @ck IS NOT NULL
BEGIN
    EXEC('ALTER TABLE dbo.FacDocumentosPOS DROP CONSTRAINT [' + @ck + ']');
    PRINT 'CHECK constraint de Estado eliminado.';
END
ELSE
    PRINT 'No se encontro CHECK constraint de Estado.';
GO

-- 3. Eliminar columna Estado
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentosPOS') AND name = 'Estado'
)
BEGIN
    ALTER TABLE dbo.FacDocumentosPOS DROP COLUMN Estado;
    PRINT 'Columna FacDocumentosPOS.Estado eliminada.';
END
ELSE
    PRINT 'Columna Estado no existe (ya eliminada).';
GO

-- 3. Reescribir SP
IF OBJECT_ID('dbo.spFacDocumentosPOSCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spFacDocumentosPOSCRUD;
GO

CREATE PROCEDURE dbo.spFacDocumentosPOSCRUD
    @Accion             CHAR(1),
    @IdDocumentoPOS     INT             = NULL,
    @IdPuntoEmision     INT             = NULL,
    @IdUsuario          INT             = NULL,
    @IdCliente          INT             = NULL,
    @ReferenciaCliente  NVARCHAR(150)   = NULL,
    @Referencia         NVARCHAR(100)   = NULL,
    @ComentarioGeneral  NVARCHAR(500)   = NULL,
    @IdTipoDocumento    INT             = NULL,
    @IdAlmacen          INT             = NULL,
    @FechaDocumento     DATE            = NULL,
    @Vendedor           NVARCHAR(100)   = NULL,
    @Notas              NVARCHAR(500)   = NULL,
    @LineasJson         NVARCHAR(MAX)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- I: Insertar nuevo documento con sus lineas
    IF @Accion = 'I'
    BEGIN
        DECLARE @NewId INT;
        INSERT INTO dbo.FacDocumentosPOS (
            IdPuntoEmision, IdUsuario, IdCliente, ReferenciaCliente, Referencia,
            ComentarioGeneral, IdTipoDocumento, IdAlmacen, FechaDocumento, Vendedor,
            Notas, IdUsuarioCreacion
        ) VALUES (
            @IdPuntoEmision, @IdUsuario, @IdCliente, @ReferenciaCliente, @Referencia,
            @ComentarioGeneral, @IdTipoDocumento, @IdAlmacen,
            ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
            @Vendedor, @Notas, @IdUsuario
        );
        SET @NewId = SCOPE_IDENTITY();
        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea, ComentarioLinea
            )
            SELECT @NewId, CAST(j.NumLinea AS INT), NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo, j.Descripcion, CAST(j.Cantidad AS DECIMAL(18,4)), j.Unidad,
                CAST(j.PrecioBase AS DECIMAL(18,4)), CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto AS BIT), CAST(j.AplicaPropina AS BIT),
                CAST(j.DescuentoLinea AS DECIMAL(18,4)), j.ComentarioLinea
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
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount',
                ComentarioLinea     NVARCHAR(300)   '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @NewId AS IdDocumentoPOS;
        RETURN;
    END

    -- U: Actualizar cabecera y reemplazar lineas
    IF @Accion = 'U'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            IdCliente         = ISNULL(@IdCliente,         IdCliente),
            ReferenciaCliente = ISNULL(@ReferenciaCliente, ReferenciaCliente),
            Referencia        = ISNULL(@Referencia,        Referencia),
            ComentarioGeneral = @ComentarioGeneral,
            IdTipoDocumento   = ISNULL(@IdTipoDocumento,   IdTipoDocumento),
            IdAlmacen         = ISNULL(@IdAlmacen,         IdAlmacen),
            FechaDocumento    = ISNULL(@FechaDocumento,    FechaDocumento),
            Vendedor          = ISNULL(@Vendedor,          Vendedor),
            Notas             = ISNULL(@Notas,             Notas),
            FechaModificacion = GETDATE(),
            IdUsuarioModif    = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS AND RowStatus = 1;

        IF @LineasJson IS NOT NULL AND LEN(@LineasJson) > 2
        BEGIN
            DELETE FROM dbo.FacDocumentoPOSDetalle WHERE IdDocumentoPOS = @IdDocumentoPOS;
            INSERT INTO dbo.FacDocumentoPOSDetalle (
                IdDocumentoPOS, NumLinea, IdProducto, Codigo, Descripcion,
                Cantidad, Unidad, PrecioBase, PorcentajeImpuesto,
                AplicaImpuesto, AplicaPropina, DescuentoLinea, ComentarioLinea
            )
            SELECT @IdDocumentoPOS, CAST(j.NumLinea AS INT), NULLIF(CAST(j.IdProducto AS INT), 0),
                j.Codigo, j.Descripcion, CAST(j.Cantidad AS DECIMAL(18,4)), j.Unidad,
                CAST(j.PrecioBase AS DECIMAL(18,4)), CAST(j.PorcentajeImpuesto AS DECIMAL(8,4)),
                CAST(j.AplicaImpuesto AS BIT), CAST(j.AplicaPropina AS BIT),
                CAST(j.DescuentoLinea AS DECIMAL(18,4)), j.ComentarioLinea
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
                DescuentoLinea      DECIMAL(18,4)   '$.lineDiscount',
                ComentarioLinea     NVARCHAR(300)   '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    -- L: Listar documentos pendientes del punto de emisión
    IF @Accion = 'L'
    BEGIN
        SELECT
            D.IdDocumentoPOS, D.IdPuntoEmision, D.IdCliente,
            D.ReferenciaCliente, D.Referencia, D.ComentarioGeneral,
            D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento,
            D.FechaDocumento, D.Vendedor, D.Notas,
            D.FechaCreacion, D.FechaModificacion,
            LTRIM(RTRIM(ISNULL(U.Nombres,'') + ' ' + ISNULL(U.Apellidos,''))) AS NombreUsuario,
            (SELECT COUNT(*) FROM dbo.FacDocumentoPOSDetalle DL
             WHERE DL.IdDocumentoPOS = D.IdDocumentoPOS AND DL.RowStatus = 1
               AND DL.IdProducto IS NOT NULL) AS CantidadLineas,
            (SELECT SUM(
                (DL.Cantidad * DL.PrecioBase)
                + CASE WHEN DL.AplicaImpuesto = 1
                       THEN DL.Cantidad * DL.PrecioBase * (DL.PorcentajeImpuesto / 100)
                       ELSE 0 END
                - DL.DescuentoLinea
             ) FROM dbo.FacDocumentoPOSDetalle DL
             WHERE DL.IdDocumentoPOS = D.IdDocumentoPOS AND DL.RowStatus = 1) AS TotalEstimado
        FROM dbo.FacDocumentosPOS D
        LEFT JOIN dbo.FacTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
        LEFT JOIN dbo.Usuarios U           ON U.IdUsuario = D.IdUsuario
        WHERE D.IdPuntoEmision = @IdPuntoEmision
          AND D.RowStatus = 1
        ORDER BY D.FechaModificacion DESC, D.FechaCreacion DESC;
        RETURN;
    END

    -- O: Obtener documento con sus lineas
    IF @Accion = 'O'
    BEGIN
        SELECT
            D.IdDocumentoPOS, D.IdPuntoEmision, D.IdCliente,
            D.ReferenciaCliente, D.Referencia, D.ComentarioGeneral,
            D.IdTipoDocumento, D.IdAlmacen, D.FechaDocumento, D.Vendedor,
            D.Notas, D.FechaCreacion, D.IdUsuario, D.IdUsuarioCreacion
        FROM dbo.FacDocumentosPOS D
        WHERE D.IdDocumentoPOS = @IdDocumentoPOS AND D.RowStatus = 1;

        SELECT
            DL.IdDetalle, DL.NumLinea, DL.IdProducto, DL.Codigo, DL.Descripcion,
            DL.Cantidad, DL.Unidad, DL.PrecioBase, DL.PorcentajeImpuesto,
            DL.AplicaImpuesto, DL.AplicaPropina, DL.DescuentoLinea, DL.ComentarioLinea
        FROM dbo.FacDocumentoPOSDetalle DL
        WHERE DL.IdDocumentoPOS = @IdDocumentoPOS AND DL.RowStatus = 1
        ORDER BY DL.NumLinea;
        RETURN;
    END

    -- X: Anular (soft-delete)
    IF @Accion = 'X'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            RowStatus         = 0,
            FechaModificacion = GETDATE(),
            IdUsuarioModif    = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS AND RowStatus = 1;
        RETURN;
    END
END
GO

PRINT 'Script 155 aplicado correctamente.';
GO
