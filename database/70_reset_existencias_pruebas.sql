USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  -- Reinicia existencias materializadas por almacen.
  UPDATE dbo.ProductoAlmacenes
  SET
    Cantidad = 0,
    CantidadReservada = 0,
    CantidadTransito = 0,
    FechaModificacion = GETDATE();

  -- Limpia historial de movimientos para recalcular desde cero en pruebas.
  DELETE FROM dbo.InvSaldosMensuales;
  DELETE FROM dbo.InvMovimientos;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;
GO

SELECT
  (SELECT COUNT(*) FROM dbo.InvMovimientos) AS MovimientosRestantes,
  (SELECT COUNT(*) FROM dbo.InvSaldosMensuales) AS SaldosMensualesRestantes,
  (SELECT COUNT(*) FROM dbo.ProductoAlmacenes WHERE ISNULL(Cantidad, 0) <> 0 OR ISNULL(CantidadReservada, 0) <> 0 OR ISNULL(CantidadTransito, 0) <> 0) AS ProductosConExistenciaNoCero;
GO
