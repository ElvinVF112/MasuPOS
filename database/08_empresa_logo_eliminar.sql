SET NOCOUNT ON;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spEmpresaLogoEliminar
    @IdEmpresa INT,
    @UsuarioModificacion INT = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @IdEmpresa IS NULL OR @IdEmpresa <= 0
    BEGIN
        RAISERROR('Debe enviar @IdEmpresa.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.Empresa
    SET
        LogoData = NULL,
        LogoMimeType = NULL,
        LogoFileName = NULL,
        LogoActualizacion = SYSDATETIME(),
        FechaModificacion = SYSDATETIME(),
        UsuarioModificacion = @UsuarioModificacion
    WHERE IdEmpresa = @IdEmpresa
      AND RowStatus = 1;

    SELECT
        IdEmpresa,
        CASE WHEN LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo
    FROM dbo.Empresa
    WHERE IdEmpresa = @IdEmpresa;
END;
GO
