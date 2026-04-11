SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spSysAgregarContextoSesionEnSP
  @ProcName SYSNAME
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @ObjectId INT = OBJECT_ID(CONCAT('dbo.', @ProcName));
  IF @ObjectId IS NULL
    RETURN;

  DECLARE @HasIdSesion BIT = CASE WHEN EXISTS (
    SELECT 1
    FROM sys.parameters
    WHERE object_id = @ObjectId
      AND name = '@IdSesion'
  ) THEN 1 ELSE 0 END;

  DECLARE @HasTokenSesion BIT = CASE WHEN EXISTS (
    SELECT 1
    FROM sys.parameters
    WHERE object_id = @ObjectId
      AND name = '@TokenSesion'
  ) THEN 1 ELSE 0 END;

  IF @HasIdSesion = 1 AND @HasTokenSesion = 1
    RETURN;

  DECLARE @Definition NVARCHAR(MAX) = OBJECT_DEFINITION(@ObjectId);
  IF @Definition IS NULL OR LTRIM(RTRIM(@Definition)) = ''
    RETURN;

  DECLARE @UpperDef NVARCHAR(MAX) = UPPER(@Definition);
  DECLARE @PosProc INT;

  SET @PosProc = CHARINDEX('CREATE OR ALTER PROCEDURE', @UpperDef);
  IF @PosProc > 0
  BEGIN
    SET @Definition = STUFF(@Definition, @PosProc, LEN('CREATE OR ALTER PROCEDURE'), 'ALTER PROCEDURE');
    SET @UpperDef = UPPER(@Definition);
  END;

  SET @PosProc = CHARINDEX('CREATE OR ALTER PROC', @UpperDef);
  IF @PosProc > 0
  BEGIN
    SET @Definition = STUFF(@Definition, @PosProc, LEN('CREATE OR ALTER PROC'), 'ALTER PROCEDURE');
    SET @UpperDef = UPPER(@Definition);
  END;

  SET @PosProc = CHARINDEX('CREATE PROCEDURE', @UpperDef);
  IF @PosProc > 0
  BEGIN
    SET @Definition = STUFF(@Definition, @PosProc, LEN('CREATE PROCEDURE'), 'ALTER PROCEDURE');
    SET @UpperDef = UPPER(@Definition);
  END;

  SET @PosProc = CHARINDEX('CREATE PROC', @UpperDef);
  IF @PosProc > 0
  BEGIN
    SET @Definition = STUFF(@Definition, @PosProc, LEN('CREATE PROC'), 'ALTER PROCEDURE');
    SET @UpperDef = UPPER(@Definition);
  END;

  DECLARE @PosAs INT = CHARINDEX(CHAR(10) + 'AS', @UpperDef);
  IF @PosAs = 0 SET @PosAs = CHARINDEX(CHAR(13) + CHAR(10) + 'AS', @UpperDef);
  IF @PosAs = 0 SET @PosAs = CHARINDEX(' AS', @UpperDef);
  IF @PosAs = 0
    RETURN;

  DECLARE @ExtraParams NVARCHAR(MAX) = '';
  IF @HasIdSesion = 0
    SET @ExtraParams = @ExtraParams + ',' + CHAR(13) + CHAR(10) + '  @IdSesion INT = NULL';

  IF @HasTokenSesion = 0
    SET @ExtraParams = @ExtraParams + ',' + CHAR(13) + CHAR(10) + '  @TokenSesion NVARCHAR(128) = NULL';

  IF @ExtraParams = ''
    RETURN;

  SET @Definition = STUFF(@Definition, @PosAs, 0, @ExtraParams + CHAR(13) + CHAR(10));

  EXEC sp_executesql @Definition;
END;
GO

EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spRolesCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spPermisosCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spMesasCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spCategoriasCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spAreasCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spRecursosCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spTiposRecursoCRUD';
EXEC dbo.spSysAgregarContextoSesionEnSP @ProcName = 'spCategoriasRecursoCRUD';
GO

DROP PROCEDURE dbo.spSysAgregarContextoSesionEnSP;
GO
