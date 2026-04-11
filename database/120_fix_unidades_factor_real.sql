IF COL_LENGTH('dbo.UnidadesMedida', 'BaseA') IS NULL
BEGIN
  ALTER TABLE dbo.UnidadesMedida
    ADD BaseA INT NOT NULL CONSTRAINT DF_UnidadesMedida_BaseA_120 DEFAULT (1);
END;
GO

IF COL_LENGTH('dbo.UnidadesMedida', 'BaseB') IS NULL
BEGIN
  ALTER TABLE dbo.UnidadesMedida
    ADD BaseB INT NOT NULL CONSTRAINT DF_UnidadesMedida_BaseB_120 DEFAULT (1);
END;
GO

IF COL_LENGTH('dbo.UnidadesMedida', 'Factor') IS NULL
BEGIN
  ALTER TABLE dbo.UnidadesMedida
    ADD Factor DECIMAL(18, 6) NOT NULL CONSTRAINT DF_UnidadesMedida_Factor_120 DEFAULT (1);
END;
GO

UPDATE UM
SET UM.Factor =
  CASE
    WHEN ISNULL(UM.BaseB, 0) = 0 THEN 1
    ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18, 6)) / NULLIF(CAST(UM.BaseB AS DECIMAL(18, 6)), 0)
  END
FROM dbo.UnidadesMedida UM;
GO

CREATE OR ALTER PROCEDURE dbo.spUnidadesMedidaCRUD
    @Accion CHAR(2),
    @IdUnidadMedida INT = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Abreviatura NVARCHAR(20) = NULL,
    @BaseA INT = NULL,
    @BaseB INT = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            UM.IdUnidadMedida,
            UM.Nombre,
            UM.Abreviatura,
            ISNULL(UM.BaseA, 1) AS BaseA,
            ISNULL(UM.BaseB, 1) AS BaseB,
            ISNULL(UM.Factor,
              CASE WHEN ISNULL(UM.BaseB, 0) = 0 THEN 1
                   ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,6)) / NULLIF(CAST(UM.BaseB AS DECIMAL(18,6)), 0)
              END
            ) AS Factor,
            ISNULL(UM.Factor,
              CASE WHEN ISNULL(UM.BaseB, 0) = 0 THEN 1
                   ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,6)) / NULLIF(CAST(UM.BaseB AS DECIMAL(18,6)), 0)
              END
            ) AS UnidadesCalculadas,
            ISNULL(UM.Activo, 1) AS Activo
        FROM dbo.UnidadesMedida UM
        WHERE ISNULL(UM.RowStatus, 1) = 1
        ORDER BY UM.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            UM.IdUnidadMedida,
            UM.Nombre,
            UM.Abreviatura,
            ISNULL(UM.BaseA, 1) AS BaseA,
            ISNULL(UM.BaseB, 1) AS BaseB,
            ISNULL(UM.Factor,
              CASE WHEN ISNULL(UM.BaseB, 0) = 0 THEN 1
                   ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,6)) / NULLIF(CAST(UM.BaseB AS DECIMAL(18,6)), 0)
              END
            ) AS Factor,
            ISNULL(UM.Factor,
              CASE WHEN ISNULL(UM.BaseB, 0) = 0 THEN 1
                   ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,6)) / NULLIF(CAST(UM.BaseB AS DECIMAL(18,6)), 0)
              END
            ) AS UnidadesCalculadas,
            ISNULL(UM.Activo, 1) AS Activo
        FROM dbo.UnidadesMedida UM
        WHERE UM.IdUnidadMedida = @IdUnidadMedida
          AND ISNULL(UM.RowStatus, 1) = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.UnidadesMedida
            WHERE Nombre = LTRIM(RTRIM(@Nombre))
              AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe una unidad de medida con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.UnidadesMedida (
            Nombre,
            Abreviatura,
            BaseA,
            BaseB,
            Factor,
            Activo,
            FechaCreacion,
            UsuarioCreacion,
            RowStatus
        )
        VALUES (
            LTRIM(RTRIM(@Nombre)),
            LTRIM(RTRIM(@Abreviatura)),
            ISNULL(@BaseA, 1),
            ISNULL(@BaseB, 1),
            CASE
              WHEN ISNULL(@BaseB, 0) = 0 THEN 1
              ELSE CAST(ISNULL(@BaseA, 1) AS DECIMAL(18,6)) / NULLIF(CAST(@BaseB AS DECIMAL(18,6)), 0)
            END,
            ISNULL(@Activo, 1),
            GETDATE(),
            @UsuarioCreacion,
            1
        );

        DECLARE @NuevoId INT = SCOPE_IDENTITY();
        EXEC dbo.spUnidadesMedidaCRUD @Accion = 'O', @IdUnidadMedida = @NuevoId;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.UnidadesMedida
        SET Nombre = LTRIM(RTRIM(@Nombre)),
            Abreviatura = LTRIM(RTRIM(@Abreviatura)),
            BaseA = ISNULL(@BaseA, BaseA),
            BaseB = ISNULL(@BaseB, BaseB),
            Factor = CASE
              WHEN ISNULL(ISNULL(@BaseB, BaseB), 0) = 0 THEN 1
              ELSE CAST(ISNULL(ISNULL(@BaseA, BaseA), 1) AS DECIMAL(18,6))
                   / NULLIF(CAST(ISNULL(ISNULL(@BaseB, BaseB), 1) AS DECIMAL(18,6)), 0)
            END,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUnidadMedida = @IdUnidadMedida
          AND ISNULL(RowStatus, 1) = 1;

        EXEC dbo.spUnidadesMedidaCRUD @Accion = 'O', @IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.UnidadesMedida
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, I, A o D.', 16, 1);
END;
GO
