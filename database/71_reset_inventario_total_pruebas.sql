USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  -- Existencias por producto/almacen.
  UPDATE dbo.ProductoAlmacenes
  SET
    Cantidad = 0,
    CantidadReservada = 0,
    CantidadTransito = 0,
    FechaModificacion = GETDATE();

  -- Historial y saldos.
  DELETE FROM dbo.InvSaldosMensuales;
  DELETE FROM dbo.InvMovimientos;

  -- Documentos y estructuras derivadas.
  DELETE FROM dbo.InvTransferencias;
  DELETE FROM dbo.InvDocumentoDetalle;
  DELETE FROM dbo.InvDocumentos;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

DBCC CHECKIDENT ('dbo.InvDocumentos', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.InvDocumentoDetalle', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.InvMovimientos', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.InvSaldosMensuales', RESEED, 0) WITH NO_INFOMSGS;
GO

SELECT
  (SELECT COUNT(*) FROM dbo.InvDocumentos) AS InvDocumentos,
  (SELECT COUNT(*) FROM dbo.InvDocumentoDetalle) AS InvDocumentoDetalle,
  (SELECT COUNT(*) FROM dbo.InvTransferencias) AS InvTransferencias,
  (SELECT COUNT(*) FROM dbo.InvMovimientos) AS InvMovimientos,
  (SELECT COUNT(*) FROM dbo.InvSaldosMensuales) AS InvSaldosMensuales,
  (SELECT COUNT(*) FROM dbo.ProductoAlmacenes WHERE ISNULL(Cantidad, 0) <> 0 OR ISNULL(CantidadReservada, 0) <> 0 OR ISNULL(CantidadTransito, 0) <> 0) AS ProductosConExistenciaNoCero;
GO
