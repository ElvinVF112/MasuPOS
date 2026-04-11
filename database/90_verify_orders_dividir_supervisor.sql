DECLARE @AuthVerify INT = OBJECT_ID('dbo.spAuthVerificarSupervisor');
DECLARE @SplitSp INT = OBJECT_ID('dbo.spOrdenesDividir');
DECLARE @DeletePerm INT = (SELECT COUNT(*) FROM dbo.Permisos WHERE Clave = 'orders.delete' AND RowStatus = 1);
DECLARE @WrappersLeft INT = (SELECT COUNT(*) FROM sys.objects WHERE type = 'P' AND name IN ('spOrdenesCerrar','spOrdenesAnular','spOrdenesReabrir'));
PRINT CONCAT('AuthVerify=', ISNULL(CAST(@AuthVerify AS VARCHAR(20)), 'NULL'));
PRINT CONCAT('SplitSp=', ISNULL(CAST(@SplitSp AS VARCHAR(20)), 'NULL'));
PRINT CONCAT('DeletePerm=', CAST(@DeletePerm AS VARCHAR(20)));
PRINT CONCAT('WrappersLeft=', CAST(@WrappersLeft AS VARCHAR(20)));
IF @AuthVerify IS NULL OR @SplitSp IS NULL OR @DeletePerm <> 1 OR @WrappersLeft <> 0
  THROW 51000, 'Verificacion TAREA 55 fallida.', 1;
