-- ============================================================
-- 154_fac_documentos_pos_comentarios.sql
-- Agrega ComentarioGeneral a FacDocumentosPOS
-- Agrega ComentarioLinea a FacDocumentoPOSDetalle
-- Actualiza spFacDocumentosPOSCRUD
-- ============================================================

-- 1. ComentarioGeneral en FacDocumentosPOS
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentosPOS') AND name = 'ComentarioGeneral'
)
BEGIN
    ALTER TABLE dbo.FacDocumentosPOS ADD ComentarioGeneral NVARCHAR(500) NULL;
    PRINT 'Columna FacDocumentosPOS.ComentarioGeneral agregada.';
END
ELSE
    PRINT 'FacDocumentosPOS.ComentarioGeneral ya existe.';
GO

-- 2. ComentarioLinea en FacDocumentoPOSDetalle
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentoPOSDetalle') AND name = 'ComentarioLinea'
)
BEGIN
    ALTER TABLE dbo.FacDocumentoPOSDetalle ADD ComentarioLinea NVARCHAR(300) NULL;
    PRINT 'Columna FacDocumentoPOSDetalle.ComentarioLinea agregada.';
END
ELSE
    PRINT 'FacDocumentoPOSDetalle.ComentarioLinea ya existe.';
GO

-- 3. Actualizar SP
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

    IF @Accion = 'I'
    BEGIN
        DECLARE @NewId INT;
        INSERT INTO dbo.FacDocumentosPOS (
            IdPuntoEmision, IdUsuario, IdCliente, ReferenciaCliente, Referencia,
            ComentarioGeneral, IdTipoDocumento, IdAlmacen, FechaDocumento, Vendedor,
            Estado, Notas, IdUsuarioCreacion
        ) VALUES (
            @IdPuntoEmision, @IdUsuario, @IdCliente, @ReferenciaCliente, @Referencia,
            @ComentarioGeneral, @IdTipoDocumento, @IdAlmacen,
            ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
            @Vendedor, 'PAUSADO', @Notas, @IdUsuario
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
                NumLinea INT '$.numLinea', IdProducto INT '$.productId',
                Codigo NVARCHAR(50) '$.code', Descripcion NVARCHAR(200) '$.description',
                Cantidad DECIMAL(18,4) '$.quantity', Unidad NVARCHAR(20) '$.unit',
                PrecioBase DECIMAL(18,4) '$.basePrice', PorcentajeImpuesto DECIMAL(8,4) '$.taxRate',
                AplicaImpuesto BIT '$.applyTax', AplicaPropina BIT '$.applyTip',
                DescuentoLinea DECIMAL(18,4) '$.lineDiscount',
                ComentarioLinea NVARCHAR(300) '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @NewId AS IdDocumentoPOS;
        RETURN;
    END

    IF @Accion = 'U'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            IdCliente          = ISNULL(@IdCliente,          IdCliente),
            ReferenciaCliente  = ISNULL(@ReferenciaCliente,  ReferenciaCliente),
            Referencia         = ISNULL(@Referencia,         Referencia),
            ComentarioGeneral  = @ComentarioGeneral,
            IdTipoDocumento    = ISNULL(@IdTipoDocumento,    IdTipoDocumento),
            IdAlmacen          = ISNULL(@IdAlmacen,          IdAlmacen),
            FechaDocumento     = ISNULL(@FechaDocumento,     FechaDocumento),
            Vendedor           = ISNULL(@Vendedor,           Vendedor),
            Notas              = ISNULL(@Notas,              Notas),
            FechaModificacion  = GETDATE(),
            IdUsuarioModif     = @IdUsuario
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
                NumLinea INT '$.numLinea', IdProducto INT '$.productId',
                Codigo NVARCHAR(50) '$.code', Descripcion NVARCHAR(200) '$.description',
                Cantidad DECIMAL(18,4) '$.quantity', Unidad NVARCHAR(20) '$.unit',
                PrecioBase DECIMAL(18,4) '$.basePrice', PorcentajeImpuesto DECIMAL(8,4) '$.taxRate',
                AplicaImpuesto BIT '$.applyTax', AplicaPropina BIT '$.applyTip',
                DescuentoLinea DECIMAL(18,4) '$.lineDiscount',
                ComentarioLinea NVARCHAR(300) '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    IF @Accion = 'L'
    BEGIN
        SELECT
            D.IdDocumentoPOS, D.IdPuntoEmision, D.IdCliente,
            D.ReferenciaCliente, D.Referencia, D.ComentarioGeneral,
            D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento,
            D.FechaDocumento, D.Vendedor, D.Estado, D.Notas,
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
          AND D.Estado IN ('PAUSADO', 'RETORNADO', 'EN_EDICION')
          AND D.RowStatus = 1
        ORDER BY D.FechaModificacion DESC, D.FechaCreacion DESC;
        RETURN;
    END

    IF @Accion = 'O'
    BEGIN
        SELECT D.IdDocumentoPOS, D.IdPuntoEmision, D.IdCliente,
            D.ReferenciaCliente, D.Referencia, D.ComentarioGeneral,
            D.IdTipoDocumento, D.IdAlmacen, D.FechaDocumento, D.Vendedor,
            D.Estado, D.Notas, D.FechaCreacion, D.IdUsuario, D.IdUsuarioCreacion
        FROM dbo.FacDocumentosPOS D
        WHERE D.IdDocumentoPOS = @IdDocumentoPOS AND D.RowStatus = 1;

        SELECT DL.IdDetalle, DL.NumLinea, DL.IdProducto, DL.Codigo, DL.Descripcion,
            DL.Cantidad, DL.Unidad, DL.PrecioBase, DL.PorcentajeImpuesto,
            DL.AplicaImpuesto, DL.AplicaPropina, DL.DescuentoLinea, DL.ComentarioLinea
        FROM dbo.FacDocumentoPOSDetalle DL
        WHERE DL.IdDocumentoPOS = @IdDocumentoPOS AND DL.RowStatus = 1
        ORDER BY DL.NumLinea;
        RETURN;
    END

    IF @Accion = 'X'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            Estado = 'ANULADO', FechaModificacion = GETDATE(), IdUsuarioModif = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado NOT IN ('ANULADO', 'EN_CAJA') AND RowStatus = 1;
        RETURN;
    END

    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            ReferenciaCliente  = ISNULL(@ReferenciaCliente, ReferenciaCliente),
            Referencia         = ISNULL(@Referencia,        Referencia),
            ComentarioGeneral  = ISNULL(@ComentarioGeneral, ComentarioGeneral),
            Estado             = 'EN_CAJA',
            FechaModificacion  = GETDATE(),
            IdUsuarioModif     = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado IN ('PAUSADO', 'RETORNADO', 'EN_EDICION') AND RowStatus = 1;
        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    IF @Accion = 'C'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            Estado = 'EN_EDICION', FechaModificacion = GETDATE(), IdUsuarioModif = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado IN ('PAUSADO', 'RETORNADO') AND RowStatus = 1;
        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    IF @Accion = 'P'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            IdCliente          = ISNULL(@IdCliente,          IdCliente),
            ReferenciaCliente  = ISNULL(@ReferenciaCliente,  ReferenciaCliente),
            Referencia         = ISNULL(@Referencia,         Referencia),
            ComentarioGeneral  = @ComentarioGeneral,
            IdTipoDocumento    = ISNULL(@IdTipoDocumento,    IdTipoDocumento),
            IdAlmacen          = ISNULL(@IdAlmacen,          IdAlmacen),
            FechaDocumento     = ISNULL(@FechaDocumento,     FechaDocumento),
            Vendedor           = ISNULL(@Vendedor,           Vendedor),
            Notas              = ISNULL(@Notas,              Notas),
            Estado             = 'PAUSADO',
            FechaModificacion  = GETDATE(),
            IdUsuarioModif     = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado = 'EN_EDICION' AND RowStatus = 1;
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
                NumLinea INT '$.numLinea', IdProducto INT '$.productId',
                Codigo NVARCHAR(50) '$.code', Descripcion NVARCHAR(200) '$.description',
                Cantidad DECIMAL(18,4) '$.quantity', Unidad NVARCHAR(20) '$.unit',
                PrecioBase DECIMAL(18,4) '$.basePrice', PorcentajeImpuesto DECIMAL(8,4) '$.taxRate',
                AplicaImpuesto BIT '$.applyTax', AplicaPropina BIT '$.applyTip',
                DescuentoLinea DECIMAL(18,4) '$.lineDiscount',
                ComentarioLinea NVARCHAR(300) '$.lineComment'
            ) j
            WHERE NULLIF(j.Descripcion, '') IS NOT NULL OR j.IdProducto > 0;
        END
        SELECT @IdDocumentoPOS AS IdDocumentoPOS;
        RETURN;
    END

    IF @Accion = 'R'
    BEGIN
        UPDATE dbo.FacDocumentosPOS SET
            Estado = 'RETORNADO', FechaModificacion = GETDATE(), IdUsuarioModif = @IdUsuario
        WHERE IdDocumentoPOS = @IdDocumentoPOS
          AND Estado = 'EN_CAJA' AND RowStatus = 1;
        RETURN;
    END
END
GO

PRINT 'Script 154 aplicado correctamente.';
GO
