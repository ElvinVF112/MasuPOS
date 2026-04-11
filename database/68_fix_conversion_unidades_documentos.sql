SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
PRINT '=== Script 68: conversion de unidades en documentos inventario ==='
GO

CREATE   FUNCTION dbo.fnInvCantidadABase (
  @IdProducto INT,
  @IdUnidadMedida INT,
  @Cantidad DECIMAL(18,4)
)
RETURNS DECIMAL(18,4)
AS
BEGIN
  DECLARE @IdUnidadBase INT;
  DECLARE @FactorBase DECIMAL(18,6) = 1;
  DECLARE @FactorSeleccionada DECIMAL(18,6) = 1;
  SELECT @IdUnidadBase = p.IdUnidadMedida FROM dbo.Productos p WHERE p.IdProducto = @IdProducto;
  IF @IdUnidadBase IS NULL OR @Cantidad IS NULL RETURN 0;
  IF @IdUnidadMedida IS NULL SET @IdUnidadMedida = @IdUnidadBase;
  SELECT @FactorBase = CASE WHEN ISNULL(um.BaseA,0) <= 0 OR ISNULL(um.BaseB,0) <= 0 THEN 1 ELSE CAST(um.BaseB AS DECIMAL(18,6))/CAST(um.BaseA AS DECIMAL(18,6)) END FROM dbo.UnidadesMedida um WHERE um.IdUnidadMedida = @IdUnidadBase;
  SELECT @FactorSeleccionada = CASE WHEN ISNULL(um.BaseA,0) <= 0 OR ISNULL(um.BaseB,0) <= 0 THEN 1 ELSE CAST(um.BaseB AS DECIMAL(18,6))/CAST(um.BaseA AS DECIMAL(18,6)) END FROM dbo.UnidadesMedida um WHERE um.IdUnidadMedida = @IdUnidadMedida;
  RETURN ROUND(@Cantidad * (@FactorSeleccionada / NULLIF(@FactorBase, 0)), 4);
END

GO

CREATE   PROCEDURE dbo.spInvBuscarProducto
  @Modo       CHAR(1)       = 'E',
  @Busqueda   NVARCHAR(100) = NULL,
  @IdAlmacen  INT           = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Modo = 'E'
  BEGIN
    SELECT TOP 1
      p.IdProducto,
      p.Codigo,
      p.Nombre,
      p.PideUnidadInventario,
      p.IdUnidadMedida,
      um.Nombre AS NombreUnidad,
      um.Abreviatura AS AbreviaturaUnidad,
      um.BaseA AS BaseAUnidad,
      um.BaseB AS BaseBUnidad,
      um.BaseA AS BaseAUnidad,
      um.BaseB AS BaseBUnidad,
      p.IdUnidadVenta,
      um2.Nombre AS NombreUnidadVenta,
      um2.Abreviatura AS AbreviaturaUnidadVenta,
      um2.BaseA AS BaseAUnidadVenta,
      um2.BaseB AS BaseBUnidadVenta,
      um2.BaseA AS BaseAUnidadVenta,
      um2.BaseB AS BaseBUnidadVenta,
      p.IdUnidadCompra,
      um3.Nombre AS NombreUnidadCompra,
      um3.Abreviatura AS AbreviaturaUnidadCompra,
      um3.BaseA AS BaseAUnidadCompra,
      um3.BaseB AS BaseBUnidadCompra,
      um3.BaseA AS BaseAUnidadCompra,
      um3.BaseB AS BaseBUnidadCompra,
      p.IdUnidadAlterna1,
      um4.Nombre AS NombreUnidadAlterna1,
      um4.Abreviatura AS AbreviaturaUnidadAlterna1,
      um4.BaseA AS BaseAUnidadAlterna1,
      um4.BaseB AS BaseBUnidadAlterna1,
      um4.BaseA AS BaseAUnidadAlterna1,
      um4.BaseB AS BaseBUnidadAlterna1,
      p.IdUnidadAlterna2,
      um5.Nombre AS NombreUnidadAlterna2,
      um5.Abreviatura AS AbreviaturaUnidadAlterna2,
      um5.BaseA AS BaseAUnidadAlterna2,
      um5.BaseB AS BaseBUnidadAlterna2,
      um5.BaseA AS BaseAUnidadAlterna2,
      um5.BaseB AS BaseBUnidadAlterna2,
      p.IdUnidadAlterna3,
      um6.Nombre AS NombreUnidadAlterna3,
      um6.Abreviatura AS AbreviaturaUnidadAlterna3,
      um6.BaseA AS BaseAUnidadAlterna3,
      um6.BaseB AS BaseBUnidadAlterna3,
      um6.BaseA AS BaseAUnidadAlterna3,
      um6.BaseB AS BaseBUnidadAlterna3,
      p.CostoPromedio,
      p.ManejaExistencia,
      ISNULL(pa.Cantidad, 0) AS Existencia
    FROM dbo.Productos p
    LEFT JOIN dbo.UnidadesMedida um  ON um.IdUnidadMedida = p.IdUnidadMedida
    LEFT JOIN dbo.UnidadesMedida um2 ON um2.IdUnidadMedida = p.IdUnidadVenta
    LEFT JOIN dbo.UnidadesMedida um3 ON um3.IdUnidadMedida = p.IdUnidadCompra
    LEFT JOIN dbo.UnidadesMedida um4 ON um4.IdUnidadMedida = p.IdUnidadAlterna1
    LEFT JOIN dbo.UnidadesMedida um5 ON um5.IdUnidadMedida = p.IdUnidadAlterna2
    LEFT JOIN dbo.UnidadesMedida um6 ON um6.IdUnidadMedida = p.IdUnidadAlterna3
    LEFT JOIN dbo.ProductoAlmacenes pa
      ON pa.IdProducto = p.IdProducto
      AND pa.IdAlmacen = @IdAlmacen
      AND pa.RowStatus = 1
    WHERE p.RowStatus = 1
      AND p.Activo = 1
      AND p.Codigo = @Busqueda;
    RETURN;
  END

  IF @Modo = 'P'
  BEGIN
    SELECT TOP 50
      p.IdProducto,
      p.Codigo,
      p.Nombre,
      p.PideUnidadInventario,
      p.IdUnidadMedida,
      um.Nombre AS NombreUnidad,
      um.Abreviatura AS AbreviaturaUnidad,
      um.BaseA AS BaseAUnidad,
      um.BaseB AS BaseBUnidad,
      um.BaseA AS BaseAUnidad,
      um.BaseB AS BaseBUnidad,
      p.IdUnidadVenta,
      um2.Nombre AS NombreUnidadVenta,
      um2.Abreviatura AS AbreviaturaUnidadVenta,
      um2.BaseA AS BaseAUnidadVenta,
      um2.BaseB AS BaseBUnidadVenta,
      um2.BaseA AS BaseAUnidadVenta,
      um2.BaseB AS BaseBUnidadVenta,
      p.IdUnidadCompra,
      um3.Nombre AS NombreUnidadCompra,
      um3.Abreviatura AS AbreviaturaUnidadCompra,
      um3.BaseA AS BaseAUnidadCompra,
      um3.BaseB AS BaseBUnidadCompra,
      um3.BaseA AS BaseAUnidadCompra,
      um3.BaseB AS BaseBUnidadCompra,
      p.IdUnidadAlterna1,
      um4.Nombre AS NombreUnidadAlterna1,
      um4.Abreviatura AS AbreviaturaUnidadAlterna1,
      um4.BaseA AS BaseAUnidadAlterna1,
      um4.BaseB AS BaseBUnidadAlterna1,
      um4.BaseA AS BaseAUnidadAlterna1,
      um4.BaseB AS BaseBUnidadAlterna1,
      p.IdUnidadAlterna2,
      um5.Nombre AS NombreUnidadAlterna2,
      um5.Abreviatura AS AbreviaturaUnidadAlterna2,
      um5.BaseA AS BaseAUnidadAlterna2,
      um5.BaseB AS BaseBUnidadAlterna2,
      um5.BaseA AS BaseAUnidadAlterna2,
      um5.BaseB AS BaseBUnidadAlterna2,
      p.IdUnidadAlterna3,
      um6.Nombre AS NombreUnidadAlterna3,
      um6.Abreviatura AS AbreviaturaUnidadAlterna3,
      um6.BaseA AS BaseAUnidadAlterna3,
      um6.BaseB AS BaseBUnidadAlterna3,
      um6.BaseA AS BaseAUnidadAlterna3,
      um6.BaseB AS BaseBUnidadAlterna3,
      p.CostoPromedio,
      p.ManejaExistencia,
      ISNULL(pa.Cantidad, 0) AS Existencia
    FROM dbo.Productos p
    LEFT JOIN dbo.UnidadesMedida um  ON um.IdUnidadMedida = p.IdUnidadMedida
    LEFT JOIN dbo.UnidadesMedida um2 ON um2.IdUnidadMedida = p.IdUnidadVenta
    LEFT JOIN dbo.UnidadesMedida um3 ON um3.IdUnidadMedida = p.IdUnidadCompra
    LEFT JOIN dbo.UnidadesMedida um4 ON um4.IdUnidadMedida = p.IdUnidadAlterna1
    LEFT JOIN dbo.UnidadesMedida um5 ON um5.IdUnidadMedida = p.IdUnidadAlterna2
    LEFT JOIN dbo.UnidadesMedida um6 ON um6.IdUnidadMedida = p.IdUnidadAlterna3
    LEFT JOIN dbo.ProductoAlmacenes pa
      ON pa.IdProducto = p.IdProducto
      AND pa.IdAlmacen = @IdAlmacen
      AND pa.RowStatus = 1
    WHERE p.RowStatus = 1
      AND p.Activo = 1
      AND (
        p.Codigo LIKE '%' + @Busqueda + '%'
        OR p.Nombre LIKE '%' + @Busqueda + '%'
      )
    ORDER BY
      CASE WHEN p.Codigo = @Busqueda THEN 0 ELSE 1 END,
      p.Nombre;
    RETURN;
  END
END;

GO

CREATE   PROCEDURE dbo.spInvDocumentosCRUD
  @Accion              CHAR(2)         = 'L',
  @IdDocumento         INT             = NULL,
  @IdTipoDocumento     INT             = NULL,
  @TipoOperacion       CHAR(1)         = NULL,
  @Fecha               DATE            = NULL,
  @IdAlmacen           INT             = NULL,
  @IdMoneda            INT             = NULL,
  @TasaCambio          DECIMAL(18,6)   = 1.000000,
  @Referencia          NVARCHAR(250)   = NULL,
  @Observacion         NVARCHAR(500)   = NULL,
  @DetalleJSON         NVARCHAR(MAX)   = NULL,
  @IdUsuario           INT             = NULL,
  @FechaDesde          DATE            = NULL,
  @FechaHasta          DATE            = NULL,
  @SecuenciaDesde      INT             = NULL,
  @SecuenciaHasta      INT             = NULL,
  @NumeroPagina        INT             = 1,
  @TamanoPagina        INT             = 20,
  @IdSesion            INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    IF ISNULL(@NumeroPagina, 0) < 1 SET @NumeroPagina = 1;
    IF ISNULL(@TamanoPagina, 0) < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 200 SET @TamanoPagina = 200;

    ;WITH Base AS (
      SELECT
        d.IdDocumento,
        d.IdTipoDocumento,
        td.Descripcion   AS NombreTipoDocumento,
        d.TipoOperacion,
        d.Periodo,
        d.Secuencia,
        d.NumeroDocumento,
        d.Fecha,
        d.IdAlmacen,
        a.Descripcion    AS NombreAlmacen,
        d.IdMoneda,
        m.Nombre         AS NombreMoneda,
        m.Simbolo        AS SimboloMoneda,
        d.TasaCambio,
        d.Referencia,
        d.Observacion,
        d.TotalDocumento,
        d.Estado,
        d.FechaCreacion,
        d.UsuarioCreacion
      FROM dbo.InvDocumentos d
      INNER JOIN dbo.InvTiposDocumento td ON td.IdTipoDocumento = d.IdTipoDocumento
      INNER JOIN dbo.Almacenes a ON a.IdAlmacen = d.IdAlmacen
      LEFT JOIN dbo.Monedas m ON m.IdMoneda = d.IdMoneda
      WHERE d.RowStatus = 1
        AND (@TipoOperacion IS NULL OR d.TipoOperacion = @TipoOperacion)
        AND (@IdAlmacen IS NULL OR d.IdAlmacen = @IdAlmacen)
        AND (@IdTipoDocumento IS NULL OR d.IdTipoDocumento = @IdTipoDocumento)
        AND (@FechaDesde IS NULL OR d.Fecha >= @FechaDesde)
        AND (@FechaHasta IS NULL OR d.Fecha <= @FechaHasta)
        AND (@SecuenciaDesde IS NULL OR d.Secuencia >= @SecuenciaDesde)
        AND (@SecuenciaHasta IS NULL OR d.Secuencia <= @SecuenciaHasta)
    )
    SELECT b.*, COUNT(1) OVER() AS TotalRows
    FROM Base b
    ORDER BY b.Fecha DESC, b.IdDocumento DESC
    OFFSET (@NumeroPagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      d.IdDocumento,
      d.IdTipoDocumento,
      td.Descripcion   AS NombreTipoDocumento,
      d.TipoOperacion,
      d.Periodo,
      d.Secuencia,
      d.NumeroDocumento,
      d.Fecha,
      d.IdAlmacen,
      a.Descripcion    AS NombreAlmacen,
      d.IdMoneda,
      m.Nombre         AS NombreMoneda,
      m.Simbolo        AS SimboloMoneda,
      d.TasaCambio,
      d.Referencia,
      d.Observacion,
      d.TotalDocumento,
      d.Estado,
      d.FechaCreacion,
      d.UsuarioCreacion
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTiposDocumento td ON td.IdTipoDocumento = d.IdTipoDocumento
    INNER JOIN dbo.Almacenes a ON a.IdAlmacen = d.IdAlmacen
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = d.IdMoneda
    WHERE d.IdDocumento = @IdDocumento AND d.RowStatus = 1;

    SELECT
      det.IdDetalle,
      det.NumeroLinea,
      det.IdProducto,
      det.Codigo,
      det.Descripcion,
      det.IdUnidadMedida,
      det.NombreUnidad,
      det.Cantidad,
      det.Costo,
      det.Total
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @TipoOp CHAR(1), @Prefijo VARCHAR(10), @NuevaSecuencia INT, @NumDoc VARCHAR(30);
      DECLARE @TipoMoneda INT, @ActualizaCosto BIT;

      UPDATE dbo.InvTiposDocumento SET SecuenciaActual = SecuenciaActual + 1 WHERE IdTipoDocumento = @IdTipoDocumento;

      SELECT
        @TipoOp = TipoOperacion,
        @Prefijo = ISNULL(Prefijo, ''),
        @NuevaSecuencia = SecuenciaActual,
        @TipoMoneda = IdMoneda,
        @ActualizaCosto = ISNULL(ActualizaCosto, 0)
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumento;

      IF @TipoOp = 'T'
        THROW 50030, 'Las transferencias deben manejarse via spInvTransferenciasCRUD.', 1;

      SET @NumDoc = CASE WHEN @Prefijo <> '' THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4) ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR), 4) END;

      DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);
      IF @IdMoneda IS NULL SET @IdMoneda = @TipoMoneda;

      INSERT INTO dbo.InvDocumentos (
        IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento,
        Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion,
        TotalDocumento, Estado, UsuarioCreacion, IdSesionCreacion
      )
      VALUES (
        @IdTipoDocumento, @TipoOp, @Periodo, @NuevaSecuencia, @NumDoc,
        @Fecha, @IdAlmacen, @IdMoneda, @TasaCambio, @Referencia, @Observacion,
        0, 'A', @IdUsuario, @IdSesion
      );

      DECLARE @NewDocId INT = SCOPE_IDENTITY();

      INSERT INTO dbo.InvDocumentoDetalle (
        IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
        IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
      )
      SELECT
        @NewDocId,
        j.linea,
        j.idProducto,
        j.codigo,
        j.descripcion,
        j.idUnidadMedida,
        j.unidad,
        j.cantidad,
        j.costo,
        ROUND(j.cantidad * j.costo, 4),
        @IdUsuario
      FROM OPENJSON(@DetalleJSON)
      WITH (
        linea          INT            '$.linea',
        idProducto     INT            '$.idProducto',
        codigo         NVARCHAR(60)   '$.codigo',
        descripcion    NVARCHAR(200)  '$.descripcion',
        idUnidadMedida INT            '$.idUnidadMedida',
        unidad         NVARCHAR(50)   '$.unidad',
        cantidad       DECIMAL(18,4)  '$.cantidad',
        costo          DECIMAL(18,4)  '$.costo'
      ) j
      WHERE j.idProducto IS NOT NULL AND j.cantidad > 0;

      UPDATE d
      SET d.TotalDocumento = x.TotalDoc
      FROM dbo.InvDocumentos d
      CROSS APPLY (
        SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = @NewDocId
          AND det.RowStatus = 1
      ) x
      WHERE d.IdDocumento = @NewDocId;

      IF @TipoOp IN ('E', 'C')
      BEGIN
        INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
        SELECT DISTINCT det.IdProducto, @IdAlmacen, 0, @IdUsuario
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = @NewDocId
          AND det.RowStatus = 1
          AND NOT EXISTS (
            SELECT 1 FROM dbo.ProductoAlmacenes pa
            WHERE pa.IdProducto = det.IdProducto AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1
          );
      END

      DECLARE @Linea INT, @ProdId INT, @Cant DECIMAL(18,4), @Costo DECIMAL(18,4), @Total DECIMAL(18,4), @CantBase DECIMAL(18,4);
      DECLARE @StockAntes DECIMAL(18,4), @StockNuevo DECIMAL(18,4), @Signo SMALLINT;
      DECLARE @CostoPromAntes DECIMAL(10,4), @CostoPromNuevo DECIMAL(10,4), @CostoBase DECIMAL(18,4);
      DECLARE @ManejaExistencia BIT, @VenderSinExistencia BIT;

      DECLARE c_det CURSOR LOCAL FAST_FORWARD FOR
      SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
             dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
      ORDER BY det.NumeroLinea;

      OPEN c_det;
      FETCH NEXT FROM c_det INTO @Linea, @ProdId, @Cant, @Costo, @Total, @CantBase;
      WHILE @@FETCH_STATUS = 0
      BEGIN
        SET @CostoBase = CASE WHEN ISNULL(@CantBase, 0) > 0 THEN ROUND(@Total / @CantBase, 4) ELSE @Costo END;

        SELECT
          @ManejaExistencia = ISNULL(p.ManejaExistencia, 1),
          @VenderSinExistencia = ISNULL(p.VenderSinExistencia, 0),
          @CostoPromAntes = ISNULL(p.CostoPromedio, 0)
        FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
        WHERE p.IdProducto = @ProdId;

        IF NOT EXISTS (
          SELECT 1 FROM dbo.ProductoAlmacenes pa
          WHERE pa.IdProducto = @ProdId AND pa.IdAlmacen = @IdAlmacen AND pa.RowStatus = 1
        )
        BEGIN
          INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
          VALUES (@ProdId, @IdAlmacen, 0, @IdUsuario);
        END

        SELECT @StockAntes = ISNULL(pa.Cantidad, 0)
        FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
        WHERE pa.IdProducto = @ProdId
          AND pa.IdAlmacen = @IdAlmacen
          AND pa.RowStatus = 1;

        SET @Signo = CASE WHEN @TipoOp IN ('E', 'C') THEN 1 ELSE -1 END;

        IF @TipoOp = 'S' AND @ManejaExistencia = 1 AND @VenderSinExistencia = 0 AND @StockAntes < @CantBase
        BEGIN
          CLOSE c_det;
          DEALLOCATE c_det;
          THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
        END

        SET @StockNuevo = @StockAntes + (@Signo * @CantBase);

        UPDATE dbo.ProductoAlmacenes
        SET
          Cantidad = @StockNuevo,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdId
          AND IdAlmacen = @IdAlmacen
          AND RowStatus = 1;

        SET @CostoPromNuevo = @CostoPromAntes;
        IF @TipoOp IN ('E', 'C') AND @ActualizaCosto = 1
        BEGIN
          SET @CostoPromNuevo = CASE
            WHEN @StockNuevo > 0 THEN ROUND(((@CostoPromAntes * @StockAntes) + @Total) / @StockNuevo, 4)
            ELSE @CostoBase
          END;

          UPDATE dbo.Productos
          SET
            CostoPromedio = @CostoPromNuevo,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @ProdId;
        END

        INSERT INTO dbo.InvMovimientos (
          IdProducto, IdAlmacen, TipoMovimiento, Signo,
          IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
          Cantidad, CostoUnitario, CostoTotal,
          SaldoAnterior, SaldoNuevo,
          CostoPromedioAnterior, CostoPromedioNuevo,
          Fecha, Periodo, UsuarioCreacion
        )
        VALUES (
          @ProdId,
          @IdAlmacen,
          CASE @TipoOp WHEN 'E' THEN 'ENT' WHEN 'S' THEN 'SAL' WHEN 'C' THEN 'COM' ELSE 'TRF' END,
          @Signo,
          @NewDocId,
          'InvDocumento',
          @NumDoc,
          @Linea,
          @CantBase,
          @CostoBase,
          @Total,
          @StockAntes,
          @StockNuevo,
          @CostoPromAntes,
          @CostoPromNuevo,
          @Fecha,
          @Periodo,
          @IdUsuario
        );

        FETCH NEXT FROM c_det INTO @Linea, @ProdId, @Cant, @Costo, @Total, @CantBase;
      END

      CLOSE c_det;
      DEALLOCATE c_det;

      COMMIT TRANSACTION;
      EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @NewDocId;
      RETURN;
    END TRY
    BEGIN CATCH
      IF CURSOR_STATUS('local', 'c_det') >= -1 BEGIN TRY CLOSE c_det; END TRY BEGIN CATCH END CATCH;
      IF CURSOR_STATUS('local', 'c_det') >= -1 BEGIN TRY DEALLOCATE c_det; END TRY BEGIN CATCH END CATCH;
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  IF @Accion = 'N'
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @DocTipoOp CHAR(1), @DocAlmacen INT, @ActualizaCostoOrig BIT, @DocNum VARCHAR(30), @DocFecha DATE, @DocPeriodo VARCHAR(6);
      SELECT
        @DocTipoOp = d.TipoOperacion,
        @DocAlmacen = d.IdAlmacen,
        @ActualizaCostoOrig = ISNULL(t.ActualizaCosto, 0),
        @DocNum = d.NumeroDocumento,
        @DocFecha = d.Fecha,
        @DocPeriodo = d.Periodo
      FROM dbo.InvDocumentos d
      INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
      WHERE d.IdDocumento = @IdDocumento
        AND d.Estado = 'A';

      IF @DocTipoOp IS NULL
        THROW 50010, 'Documento no encontrado o ya anulado.', 1;

      IF @DocTipoOp = 'T'
        THROW 50030, 'Las transferencias deben manejarse via spInvTransferenciasCRUD.', 1;

      DECLARE @NLinea INT, @NProdId INT, @NCant DECIMAL(18,4), @NCosto DECIMAL(18,4), @NTotal DECIMAL(18,4), @NCantBase DECIMAL(18,4);
      DECLARE @NStockAntes DECIMAL(18,4), @NStockNuevo DECIMAL(18,4), @NSigno SMALLINT;
      DECLARE @NCostoPromAntes DECIMAL(10,4), @NCostoPromNuevo DECIMAL(10,4), @NCostoBase DECIMAL(18,4);

      DECLARE c_anu CURSOR LOCAL FAST_FORWARD FOR
      SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
             dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @IdDocumento AND det.RowStatus = 1
      ORDER BY det.NumeroLinea;

      OPEN c_anu;
      FETCH NEXT FROM c_anu INTO @NLinea, @NProdId, @NCant, @NCosto, @NTotal, @NCantBase;
      WHILE @@FETCH_STATUS = 0
      BEGIN
        SET @NCostoBase = CASE WHEN ISNULL(@NCantBase, 0) > 0 THEN ROUND(@NTotal / @NCantBase, 4) ELSE @NCosto END;

        SELECT @NCostoPromAntes = ISNULL(p.CostoPromedio, 0)
        FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
        WHERE p.IdProducto = @NProdId;

        SELECT @NStockAntes = ISNULL(pa.Cantidad, 0)
        FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
        WHERE pa.IdProducto = @NProdId
          AND pa.IdAlmacen = @DocAlmacen
          AND pa.RowStatus = 1;

        IF @DocTipoOp IN ('E', 'C')
        BEGIN
          SET @NSigno = -1;
          SET @NStockNuevo = @NStockAntes - @NCantBase;

          SET @NCostoPromNuevo = @NCostoPromAntes;
          IF @ActualizaCostoOrig = 1
          BEGIN
            SET @NCostoPromNuevo = CASE
              WHEN (@NStockAntes - @NCantBase) > 0 THEN ROUND(((@NCostoPromAntes * @NStockAntes) - (@NCosto * @NCant)) / (@NStockAntes - @NCantBase), 4)
              ELSE @NCostoPromAntes
            END;

            UPDATE dbo.Productos
            SET
              CostoPromedio = @NCostoPromNuevo,
              FechaModificacion = GETDATE(),
              UsuarioModificacion = @IdUsuario
            WHERE IdProducto = @NProdId;
          END

          UPDATE dbo.ProductoAlmacenes
          SET
            Cantidad = @NStockNuevo,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @NProdId
            AND IdAlmacen = @DocAlmacen
            AND RowStatus = 1;
        END
        ELSE
        BEGIN
          SET @NSigno = 1;
          SET @NStockNuevo = @NStockAntes + @NCantBase;
          SET @NCostoPromNuevo = @NCostoPromAntes;

          UPDATE dbo.ProductoAlmacenes
          SET
            Cantidad = @NStockNuevo,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @NProdId
            AND IdAlmacen = @DocAlmacen
            AND RowStatus = 1;
        END

        INSERT INTO dbo.InvMovimientos (
          IdProducto, IdAlmacen, TipoMovimiento, Signo,
          IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
          Cantidad, CostoUnitario, CostoTotal,
          SaldoAnterior, SaldoNuevo,
          CostoPromedioAnterior, CostoPromedioNuevo,
          Fecha, Periodo, UsuarioCreacion,
          Observacion
        )
        VALUES (
          @NProdId,
          @DocAlmacen,
          'ANU',
          @NSigno,
          @IdDocumento,
          'InvDocumento',
          @DocNum,
          @NLinea,
          @NCantBase,
          @NCostoBase,
          @NTotal,
          @NStockAntes,
          @NStockNuevo,
          @NCostoPromAntes,
          @NCostoPromNuevo,
          @DocFecha,
          @DocPeriodo,
          @IdUsuario,
          N'Anulacion de documento'
        );

        FETCH NEXT FROM c_anu INTO @NLinea, @NProdId, @NCant, @NCosto, @NTotal, @NCantBase;
      END

      CLOSE c_anu;
      DEALLOCATE c_anu;

      UPDATE dbo.InvDocumentoDetalle
      SET RowStatus = 0
      WHERE IdDocumento = @IdDocumento
        AND RowStatus = 1;

      UPDATE dbo.InvDocumentos
      SET
        Estado = 'N',
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario,
        IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      COMMIT TRANSACTION;
      EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @IdDocumento;
      RETURN;
    END TRY
    BEGIN CATCH
      IF CURSOR_STATUS('local', 'c_anu') >= -1 BEGIN TRY CLOSE c_anu; END TRY BEGIN CATCH END CATCH;
      IF CURSOR_STATUS('local', 'c_anu') >= -1 BEGIN TRY DEALLOCATE c_anu; END TRY BEGIN CATCH END CATCH;
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  IF @Accion = 'LT'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre  AS NombreMoneda,
      m.Simbolo AS SimboloMoneda
    FROM dbo.InvTiposDocumento t
    INNER JOIN dbo.InvTipoDocUsuario tdu
      ON tdu.IdTipoDocumento = t.IdTipoDocumento
      AND tdu.IdUsuario = @IdUsuario
      AND tdu.Activo = 1
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE t.RowStatus = 1 AND t.Activo = 1
      AND (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
    ORDER BY t.Descripcion;
    RETURN;
  END
END

GO

-- ============================================================
-- 44.4) spInvActualizarDocumento con movimientos de reversa+nuevos
-- ============================================================
CREATE   PROCEDURE dbo.spInvActualizarDocumento
  @IdDocumento         INT,
  @IdTipoDocumento     INT             = NULL,
  @Fecha               DATE,
  @IdAlmacen           INT,
  @IdMoneda            INT             = NULL,
  @TasaCambio          DECIMAL(18,6)   = 1.000000,
  @Referencia          NVARCHAR(250)   = NULL,
  @Observacion         NVARCHAR(500)   = NULL,
  @DetalleJSON         NVARCHAR(MAX),
  @IdUsuario           INT             = NULL,
  @IdSesion            INT             = NULL
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    DECLARE @OldTipoOp CHAR(1), @OldAlmacen INT, @OldTipoDocumento INT, @OldActualizaCosto BIT;
    DECLARE @DocNum VARCHAR(30), @DocPeriodo VARCHAR(6);
    SELECT
      @OldTipoOp = d.TipoOperacion,
      @OldAlmacen = d.IdAlmacen,
      @OldTipoDocumento = d.IdTipoDocumento,
      @OldActualizaCosto = ISNULL(t.ActualizaCosto, 0),
      @DocNum = d.NumeroDocumento,
      @DocPeriodo = d.Periodo
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
    WHERE d.IdDocumento = @IdDocumento
      AND d.RowStatus = 1
      AND d.Estado = 'A';

    IF @OldTipoOp IS NULL
      THROW 50020, 'Documento no encontrado o no editable (anulado).', 1;

    IF @IdTipoDocumento IS NULL SET @IdTipoDocumento = @OldTipoDocumento;

    DECLARE @NewTipoOp CHAR(1), @TipoMoneda INT, @NewActualizaCosto BIT;
    SELECT
      @NewTipoOp = t.TipoOperacion,
      @TipoMoneda = t.IdMoneda,
      @NewActualizaCosto = ISNULL(t.ActualizaCosto, 0)
    FROM dbo.InvTiposDocumento t
    WHERE t.IdTipoDocumento = @IdTipoDocumento
      AND t.RowStatus = 1;

    IF @NewTipoOp IS NULL
      THROW 50021, 'Tipo de documento no valido.', 1;

    IF @NewTipoOp <> @OldTipoOp
      THROW 50022, 'No se permite cambiar tipo de operacion en edicion.', 1;

    IF @IdMoneda IS NULL SET @IdMoneda = @TipoMoneda;

    -- Reversa del detalle previo con movimiento ANU
    DECLARE @LineaOld INT, @ProdOld INT, @CantOld DECIMAL(18,4), @CostoOld DECIMAL(18,4), @TotalOld DECIMAL(18,4), @CantBaseOld DECIMAL(18,4);
    DECLARE @StockAntesOld DECIMAL(18,4), @StockNuevoOld DECIMAL(18,4), @SignoOld SMALLINT;
    DECLARE @CostoPromAntesOld DECIMAL(10,4), @CostoPromNuevoOld DECIMAL(10,4), @CostoBaseOld DECIMAL(18,4);

    DECLARE c_old CURSOR LOCAL FAST_FORWARD FOR
    SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
           dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento
      AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;

    OPEN c_old;
    FETCH NEXT FROM c_old INTO @LineaOld, @ProdOld, @CantOld, @CostoOld, @TotalOld, @CantBaseOld;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @CostoBaseOld = CASE WHEN ISNULL(@CantBaseOld, 0) > 0 THEN ROUND(@TotalOld / @CantBaseOld, 4) ELSE @CostoOld END;

      SELECT @CostoPromAntesOld = ISNULL(p.CostoPromedio, 0)
      FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
      WHERE p.IdProducto = @ProdOld;

      SELECT @StockAntesOld = ISNULL(pa.Cantidad, 0)
      FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
      WHERE pa.IdProducto = @ProdOld
        AND pa.IdAlmacen = @OldAlmacen
        AND pa.RowStatus = 1;

      IF @OldTipoOp IN ('E', 'C')
      BEGIN
        SET @SignoOld = -1;
        SET @StockNuevoOld = @StockAntesOld - @CantBaseOld;

        SET @CostoPromNuevoOld = @CostoPromAntesOld;
        IF @OldActualizaCosto = 1
        BEGIN
          SET @CostoPromNuevoOld = CASE
            WHEN (@StockAntesOld - @CantBaseOld) > 0 THEN ROUND(((@CostoPromAntesOld * @StockAntesOld) - (@CostoOld * @CantOld)) / (@StockAntesOld - @CantBaseOld), 4)
            ELSE @CostoPromAntesOld
          END;

          UPDATE dbo.Productos
          SET
            CostoPromedio = @CostoPromNuevoOld,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @IdUsuario
          WHERE IdProducto = @ProdOld;
        END

        UPDATE dbo.ProductoAlmacenes
        SET
          Cantidad = @StockNuevoOld,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdOld
          AND IdAlmacen = @OldAlmacen
          AND RowStatus = 1;
      END
      ELSE
      BEGIN
        SET @SignoOld = 1;
        SET @StockNuevoOld = @StockAntesOld + @CantBaseOld;
        SET @CostoPromNuevoOld = @CostoPromAntesOld;

        UPDATE dbo.ProductoAlmacenes
        SET
          Cantidad = @StockNuevoOld,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdOld
          AND IdAlmacen = @OldAlmacen
          AND RowStatus = 1;
      END

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo,
        IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
        Cantidad, CostoUnitario, CostoTotal,
        SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo,
        Fecha, Periodo, UsuarioCreacion,
        Observacion
      )
      VALUES (
        @ProdOld,
        @OldAlmacen,
        'ANU',
        @SignoOld,
        @IdDocumento,
        'InvDocumento',
        @DocNum,
        @LineaOld,
        @CantBaseOld,
        @CostoBaseOld,
        @TotalOld,
        @StockAntesOld,
        @StockNuevoOld,
        @CostoPromAntesOld,
        @CostoPromNuevoOld,
        @Fecha,
        CONVERT(VARCHAR(6), @Fecha, 112),
        @IdUsuario,
        N'Reversion por edicion'
      );

      FETCH NEXT FROM c_old INTO @LineaOld, @ProdOld, @CantOld, @CostoOld, @TotalOld, @CantBaseOld;
    END

    CLOSE c_old;
    DEALLOCATE c_old;

    -- Soft delete detalle actual (historico)
    UPDATE dbo.InvDocumentoDetalle
    SET RowStatus = 0
    WHERE IdDocumento = @IdDocumento
      AND RowStatus = 1;

    DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);

    UPDATE dbo.InvDocumentos
    SET
      IdTipoDocumento = @IdTipoDocumento,
      Fecha = @Fecha,
      Periodo = @Periodo,
      IdAlmacen = @IdAlmacen,
      IdMoneda = @IdMoneda,
      TasaCambio = @TasaCambio,
      Referencia = @Referencia,
      Observacion = @Observacion,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario,
      IdSesionModif = @IdSesion
    WHERE IdDocumento = @IdDocumento;

    -- Inserta nuevo detalle
    INSERT INTO dbo.InvDocumentoDetalle (
      IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
      IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
    )
    SELECT
      @IdDocumento,
      j.linea,
      j.idProducto,
      j.codigo,
      j.descripcion,
      j.idUnidadMedida,
      j.unidad,
      j.cantidad,
      j.costo,
      ROUND(j.cantidad * j.costo, 4),
      @IdUsuario
    FROM OPENJSON(@DetalleJSON)
    WITH (
      linea          INT            '$.linea',
      idProducto     INT            '$.idProducto',
      codigo         NVARCHAR(60)   '$.codigo',
      descripcion    NVARCHAR(200)  '$.descripcion',
      idUnidadMedida INT            '$.idUnidadMedida',
      unidad         NVARCHAR(50)   '$.unidad',
      cantidad       DECIMAL(18,4)  '$.cantidad',
      costo          DECIMAL(18,4)  '$.costo'
    ) j
    WHERE j.idProducto IS NOT NULL
      AND j.cantidad > 0;

    IF @OldTipoOp IN ('E', 'C')
    BEGIN
      INSERT INTO dbo.ProductoAlmacenes (IdProducto, IdAlmacen, Cantidad, UsuarioCreacion)
      SELECT DISTINCT det.IdProducto, @IdAlmacen, 0, @IdUsuario
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = @IdDocumento
        AND det.RowStatus = 1
        AND NOT EXISTS (
          SELECT 1
          FROM dbo.ProductoAlmacenes pa
          WHERE pa.IdProducto = det.IdProducto
            AND pa.IdAlmacen = @IdAlmacen
            AND pa.RowStatus = 1
        );
    END

    DECLARE @LineaNew INT, @ProdNew INT, @CantNew DECIMAL(18,4), @CostoNew DECIMAL(18,4), @TotalNew DECIMAL(18,4), @CantBaseNew DECIMAL(18,4);
    DECLARE @StockAntesNew DECIMAL(18,4), @StockNuevoNew DECIMAL(18,4), @SignoNew SMALLINT;
    DECLARE @CostoPromAntesNew DECIMAL(10,4), @CostoPromNuevoNew DECIMAL(10,4), @CostoBaseNew DECIMAL(18,4);
    DECLARE @ManejaNew BIT, @VendeSinNew BIT;

    DECLARE c_new CURSOR LOCAL FAST_FORWARD FOR
    SELECT det.NumeroLinea, det.IdProducto, det.Cantidad, det.Costo, det.Total,
           dbo.fnInvCantidadABase(det.IdProducto, det.IdUnidadMedida, det.Cantidad) AS CantidadBase
    FROM dbo.InvDocumentoDetalle det
    WHERE det.IdDocumento = @IdDocumento
      AND det.RowStatus = 1
    ORDER BY det.NumeroLinea;

    OPEN c_new;
    FETCH NEXT FROM c_new INTO @LineaNew, @ProdNew, @CantNew, @CostoNew, @TotalNew, @CantBaseNew;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @CostoBaseNew = CASE WHEN ISNULL(@CantBaseNew, 0) > 0 THEN ROUND(@TotalNew / @CantBaseNew, 4) ELSE @CostoNew END;

      SELECT
        @CostoPromAntesNew = ISNULL(p.CostoPromedio, 0),
        @ManejaNew = ISNULL(p.ManejaExistencia, 1),
        @VendeSinNew = ISNULL(p.VenderSinExistencia, 0)
      FROM dbo.Productos p WITH (UPDLOCK, HOLDLOCK)
      WHERE p.IdProducto = @ProdNew;

      SELECT @StockAntesNew = ISNULL(pa.Cantidad, 0)
      FROM dbo.ProductoAlmacenes pa WITH (UPDLOCK, HOLDLOCK)
      WHERE pa.IdProducto = @ProdNew
        AND pa.IdAlmacen = @IdAlmacen
        AND pa.RowStatus = 1;

      SET @SignoNew = CASE WHEN @OldTipoOp IN ('E', 'C') THEN 1 ELSE -1 END;

      IF @OldTipoOp = 'S' AND @ManejaNew = 1 AND @VendeSinNew = 0 AND @StockAntesNew < @CantBaseNew
      BEGIN
        CLOSE c_new;
        DEALLOCATE c_new;
        THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
      END

      SET @StockNuevoNew = @StockAntesNew + (@SignoNew * @CantBaseNew);

      UPDATE dbo.ProductoAlmacenes
      SET
        Cantidad = @StockNuevoNew,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdProducto = @ProdNew
        AND IdAlmacen = @IdAlmacen
        AND RowStatus = 1;

      SET @CostoPromNuevoNew = @CostoPromAntesNew;
      IF @OldTipoOp IN ('E', 'C') AND @NewActualizaCosto = 1
      BEGIN
        SET @CostoPromNuevoNew = CASE
          WHEN @StockNuevoNew > 0 THEN ROUND(((@CostoPromAntesNew * @StockAntesNew) + @TotalNew) / @StockNuevoNew, 4)
          ELSE @CostoBaseNew
        END;

        UPDATE dbo.Productos
        SET
          CostoPromedio = @CostoPromNuevoNew,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdProducto = @ProdNew;
      END

      INSERT INTO dbo.InvMovimientos (
        IdProducto, IdAlmacen, TipoMovimiento, Signo,
        IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
        Cantidad, CostoUnitario, CostoTotal,
        SaldoAnterior, SaldoNuevo,
        CostoPromedioAnterior, CostoPromedioNuevo,
        Fecha, Periodo, UsuarioCreacion,
        Observacion
      )
      VALUES (
        @ProdNew,
        @IdAlmacen,
        CASE @OldTipoOp WHEN 'E' THEN 'ENT' WHEN 'S' THEN 'SAL' WHEN 'C' THEN 'COM' ELSE 'TRF' END,
        @SignoNew,
        @IdDocumento,
        'InvDocumento',
        @DocNum,
        @LineaNew,
        @CantBaseNew,
        @CostoBaseNew,
        @TotalNew,
        @StockAntesNew,
        @StockNuevoNew,
        @CostoPromAntesNew,
        @CostoPromNuevoNew,
        @Fecha,
        @Periodo,
        @IdUsuario,
        N'Reaplicacion por edicion'
      );

      FETCH NEXT FROM c_new INTO @LineaNew, @ProdNew, @CantNew, @CostoNew, @TotalNew, @CantBaseNew;
    END

    CLOSE c_new;
    DEALLOCATE c_new;

    UPDATE d
    SET d.TotalDocumento = x.TotalDoc
    FROM dbo.InvDocumentos d
    CROSS APPLY (
      SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
      FROM dbo.InvDocumentoDetalle det
      WHERE det.IdDocumento = d.IdDocumento
        AND det.RowStatus = 1
    ) x
    WHERE d.IdDocumento = @IdDocumento;

    COMMIT TRANSACTION;
    EXEC dbo.spInvDocumentosCRUD @Accion = 'O', @IdDocumento = @IdDocumento;
  END TRY
  BEGIN CATCH
    IF CURSOR_STATUS('local', 'c_old') >= -1 BEGIN TRY CLOSE c_old; END TRY BEGIN CATCH END CATCH;
    IF CURSOR_STATUS('local', 'c_old') >= -1 BEGIN TRY DEALLOCATE c_old; END TRY BEGIN CATCH END CATCH;
    IF CURSOR_STATUS('local', 'c_new') >= -1 BEGIN TRY CLOSE c_new; END TRY BEGIN CATCH END CATCH;
    IF CURSOR_STATUS('local', 'c_new') >= -1 BEGIN TRY DEALLOCATE c_new; END TRY BEGIN CATCH END CATCH;
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END

GO

CREATE   PROCEDURE dbo.spInvTransferenciasCRUD
  @Accion              CHAR(2)        = 'L',
  @IdDocumento         INT            = NULL,
  @IdTipoDocumento     INT            = NULL,
  @Fecha               DATE           = NULL,
  @IdAlmacen           INT            = NULL,
  @IdAlmacenDestino    INT            = NULL,
  @EstadoTransferencia CHAR(1)        = NULL,
  @Referencia          NVARCHAR(250)  = NULL,
  @Observacion         NVARCHAR(500)  = NULL,
  @DetalleJSON         NVARCHAR(MAX)  = NULL,
  @IdUsuario           INT            = NULL,
  @NumeroPagina        INT            = 1,
  @TamanoPagina        INT            = 20,
  @FechaDesde          DATE           = NULL,
  @FechaHasta          DATE           = NULL,
  @IdSesion            INT            = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    ;WITH Base AS (
      SELECT
        D.IdDocumento, D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento, D.TipoOperacion, D.Periodo, D.Secuencia,
        D.NumeroDocumento, D.Fecha, D.IdAlmacen, AO.Descripcion AS NombreAlmacen, D.IdMoneda, M.Nombre AS NombreMoneda,
        M.Simbolo AS SimboloMoneda, D.TasaCambio, D.Referencia, D.Observacion, D.TotalDocumento, D.Estado,
        T.IdAlmacenDestino, AD.Descripcion AS NombreAlmacenDestino, T.IdAlmacenTransito, ATN.Descripcion AS NombreAlmacenTransito,
        T.EstadoTransferencia, T.FechaSalida, T.FechaRecepcion
      FROM dbo.InvDocumentos D
      INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento AND T.RowStatus = 1
      INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
      INNER JOIN dbo.Almacenes AO ON AO.IdAlmacen = D.IdAlmacen
      INNER JOIN dbo.Almacenes AD ON AD.IdAlmacen = T.IdAlmacenDestino
      INNER JOIN dbo.Almacenes ATN ON ATN.IdAlmacen = T.IdAlmacenTransito
      LEFT JOIN dbo.Monedas M ON M.IdMoneda = D.IdMoneda
      WHERE D.RowStatus = 1
        AND D.TipoOperacion = 'T'
        AND (@IdAlmacen IS NULL OR D.IdAlmacen = @IdAlmacen)
        AND (@IdAlmacenDestino IS NULL OR T.IdAlmacenDestino = @IdAlmacenDestino)
        AND (@IdTipoDocumento IS NULL OR D.IdTipoDocumento = @IdTipoDocumento)
        AND (@EstadoTransferencia IS NULL OR T.EstadoTransferencia = @EstadoTransferencia)
        AND (@FechaDesde IS NULL OR D.Fecha >= @FechaDesde)
        AND (@FechaHasta IS NULL OR D.Fecha <= @FechaHasta)
    )
    SELECT *, COUNT(1) OVER() AS TotalRows
    FROM Base
    ORDER BY Fecha DESC, IdDocumento DESC
    OFFSET (@NumeroPagina - 1) * @TamanoPagina ROWS FETCH NEXT @TamanoPagina ROWS ONLY;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      D.IdDocumento, D.IdTipoDocumento, TD.Descripcion AS NombreTipoDocumento, D.TipoOperacion, D.Periodo, D.Secuencia,
      D.NumeroDocumento, D.Fecha, D.IdAlmacen, AO.Descripcion AS NombreAlmacen, D.IdMoneda, M.Nombre AS NombreMoneda,
      M.Simbolo AS SimboloMoneda, D.TasaCambio, D.Referencia, D.Observacion, D.TotalDocumento, D.Estado,
      T.IdAlmacenDestino, AD.Descripcion AS NombreAlmacenDestino, T.IdAlmacenTransito, ATN.Descripcion AS NombreAlmacenTransito,
      T.EstadoTransferencia, T.FechaSalida, T.FechaRecepcion
    FROM dbo.InvDocumentos D
    INNER JOIN dbo.InvTransferencias T ON T.IdDocumento = D.IdDocumento AND T.RowStatus = 1
    INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = D.IdTipoDocumento
    INNER JOIN dbo.Almacenes AO ON AO.IdAlmacen = D.IdAlmacen
    INNER JOIN dbo.Almacenes AD ON AD.IdAlmacen = T.IdAlmacenDestino
    INNER JOIN dbo.Almacenes ATN ON ATN.IdAlmacen = T.IdAlmacenTransito
    LEFT JOIN dbo.Monedas M ON M.IdMoneda = D.IdMoneda
    WHERE D.IdDocumento = @IdDocumento AND D.RowStatus = 1;

    SELECT IdDetalle, NumeroLinea, IdProducto, Codigo, Descripcion, IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total
    FROM dbo.InvDocumentoDetalle
    WHERE IdDocumento = @IdDocumento AND RowStatus = 1
    ORDER BY NumeroLinea;
    RETURN;
  END

  IF @Accion IN ('I', 'U')
  BEGIN
    BEGIN TRY
      SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
      BEGIN TRANSACTION;

      DECLARE @TransitoOrigen INT;
      SELECT @TransitoOrigen = IdAlmacenTransito
      FROM dbo.Almacenes
      WHERE IdAlmacen = @IdAlmacen
        AND RowStatus = 1;

      IF @TransitoOrigen IS NULL
        THROW 50045, 'El almacen origen no tiene almacen de transito configurado.', 1;

      IF @Accion = 'I'
      BEGIN
        DECLARE @TipoOp CHAR(1), @Prefijo VARCHAR(10), @NuevaSecuencia INT, @NumDoc VARCHAR(30), @TipoMoneda INT;
        DECLARE @Periodo VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);

        UPDATE dbo.InvTiposDocumento
        SET SecuenciaActual = SecuenciaActual + 1
        WHERE IdTipoDocumento = @IdTipoDocumento;

        SELECT
          @TipoOp = TipoOperacion,
          @Prefijo = ISNULL(Prefijo, ''),
          @NuevaSecuencia = SecuenciaActual,
          @TipoMoneda = IdMoneda
        FROM dbo.InvTiposDocumento
        WHERE IdTipoDocumento = @IdTipoDocumento
          AND RowStatus = 1;

        IF @TipoOp IS NULL
          THROW 50052, 'Tipo de documento no valido.', 1;

        IF @TipoOp <> 'T'
          THROW 50053, 'El tipo de documento no corresponde a transferencias.', 1;

        SET @NumDoc = CASE
          WHEN @Prefijo <> '' THEN @Prefijo + '-' + RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR(10)), 4)
          ELSE RIGHT('0000' + CAST(@NuevaSecuencia AS VARCHAR(10)), 4)
        END;

        INSERT INTO dbo.InvDocumentos (
          IdTipoDocumento, TipoOperacion, Periodo, Secuencia, NumeroDocumento,
          Fecha, IdAlmacen, IdMoneda, TasaCambio, Referencia, Observacion,
          TotalDocumento, Estado, UsuarioCreacion, IdSesionCreacion
        )
        VALUES (
          @IdTipoDocumento, 'T', @Periodo, @NuevaSecuencia, @NumDoc,
          @Fecha, @IdAlmacen, @TipoMoneda, 1.000000, @Referencia, @Observacion,
          0, 'A', @IdUsuario, @IdSesion
        );

        SET @IdDocumento = SCOPE_IDENTITY();

        INSERT INTO dbo.InvDocumentoDetalle (
          IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
          IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
        )
        SELECT
          @IdDocumento,
          j.linea,
          j.idProducto,
          j.codigo,
          j.descripcion,
          j.idUnidadMedida,
          j.unidad,
          j.cantidad,
          j.costo,
          ROUND(j.cantidad * j.costo, 4),
          @IdUsuario
        FROM OPENJSON(@DetalleJSON)
        WITH (
          linea          INT            '$.linea',
          idProducto     INT            '$.idProducto',
          codigo         NVARCHAR(60)   '$.codigo',
          descripcion    NVARCHAR(200)  '$.descripcion',
          idUnidadMedida INT            '$.idUnidadMedida',
          unidad         NVARCHAR(50)   '$.unidad',
          cantidad       DECIMAL(18,4)  '$.cantidad',
          costo          DECIMAL(18,4)  '$.costo'
        ) j
        WHERE j.idProducto IS NOT NULL
          AND j.cantidad > 0;

        UPDATE d
        SET d.TotalDocumento = x.TotalDoc
        FROM dbo.InvDocumentos d
        CROSS APPLY (
          SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
          FROM dbo.InvDocumentoDetalle det
          WHERE det.IdDocumento = @IdDocumento
            AND det.RowStatus = 1
        ) x
        WHERE d.IdDocumento = @IdDocumento;

        INSERT INTO dbo.InvTransferencias (IdDocumento, IdAlmacenDestino, IdAlmacenTransito, EstadoTransferencia, UsuarioCreacion)
        VALUES (@IdDocumento, @IdAlmacenDestino, @TransitoOrigen, 'B', @IdUsuario);

        COMMIT TRANSACTION;
        EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
        RETURN;
      END

      IF NOT EXISTS (
        SELECT 1
        FROM dbo.InvTransferencias
        WHERE IdDocumento = @IdDocumento
          AND EstadoTransferencia = 'B'
          AND RowStatus = 1
      )
        THROW 50046, 'Solo se pueden editar transferencias en borrador.', 1;

      DECLARE @DocTipoOp CHAR(1), @TipoMonedaEdit INT, @PeriodoEdit VARCHAR(6) = CONVERT(VARCHAR(6), @Fecha, 112);
      SELECT
        @DocTipoOp = D.TipoOperacion,
        @TipoMonedaEdit = TD.IdMoneda
      FROM dbo.InvDocumentos D
      INNER JOIN dbo.InvTiposDocumento TD ON TD.IdTipoDocumento = @IdTipoDocumento
      WHERE D.IdDocumento = @IdDocumento
        AND D.RowStatus = 1
        AND D.Estado = 'A';

      IF @DocTipoOp IS NULL
        THROW 50054, 'Transferencia no encontrada o no editable.', 1;

      IF @DocTipoOp <> 'T'
        THROW 50055, 'El documento indicado no es una transferencia.', 1;

      UPDATE dbo.InvDocumentoDetalle
      SET RowStatus = 0
      WHERE IdDocumento = @IdDocumento
        AND RowStatus = 1;

      UPDATE dbo.InvDocumentos
      SET
        IdTipoDocumento = @IdTipoDocumento,
        Fecha = @Fecha,
        Periodo = @PeriodoEdit,
        IdAlmacen = @IdAlmacen,
        IdMoneda = @TipoMonedaEdit,
        TasaCambio = 1.000000,
        Referencia = @Referencia,
        Observacion = @Observacion,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario,
        IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      INSERT INTO dbo.InvDocumentoDetalle (
        IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
        IdUnidadMedida, NombreUnidad, Cantidad, Costo, Total, UsuarioCreacion
      )
      SELECT
        @IdDocumento,
        j.linea,
        j.idProducto,
        j.codigo,
        j.descripcion,
        j.idUnidadMedida,
        j.unidad,
        j.cantidad,
        j.costo,
        ROUND(j.cantidad * j.costo, 4),
        @IdUsuario
      FROM OPENJSON(@DetalleJSON)
      WITH (
        linea          INT            '$.linea',
        idProducto     INT            '$.idProducto',
        codigo         NVARCHAR(60)   '$.codigo',
        descripcion    NVARCHAR(200)  '$.descripcion',
        idUnidadMedida INT            '$.idUnidadMedida',
        unidad         NVARCHAR(50)   '$.unidad',
        cantidad       DECIMAL(18,4)  '$.cantidad',
        costo          DECIMAL(18,4)  '$.costo'
      ) j
      WHERE j.idProducto IS NOT NULL
        AND j.cantidad > 0;

      UPDATE d
      SET d.TotalDocumento = x.TotalDoc
      FROM dbo.InvDocumentos d
      CROSS APPLY (
        SELECT ISNULL(SUM(det.Total), 0) AS TotalDoc
        FROM dbo.InvDocumentoDetalle det
        WHERE det.IdDocumento = d.IdDocumento
          AND det.RowStatus = 1
      ) x
      WHERE d.IdDocumento = @IdDocumento;

      UPDATE dbo.InvTransferencias
      SET
        IdAlmacenDestino = @IdAlmacenDestino,
        IdAlmacenTransito = @TransitoOrigen,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      COMMIT TRANSACTION;
      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  END

  IF @Accion IN ('GS', 'CR', 'N')
  BEGIN
    DECLARE @EstadoActual CHAR(1), @OrigenDoc INT, @DestinoDoc INT, @TransitoDoc INT;

    SELECT
      @EstadoActual = T.EstadoTransferencia,
      @OrigenDoc = D.IdAlmacen,
      @DestinoDoc = T.IdAlmacenDestino,
      @TransitoDoc = T.IdAlmacenTransito
    FROM dbo.InvTransferencias T
    INNER JOIN dbo.InvDocumentos D ON D.IdDocumento = T.IdDocumento
    WHERE T.IdDocumento = @IdDocumento
      AND T.RowStatus = 1
      AND D.RowStatus = 1;

    IF @EstadoActual IS NULL
      THROW 50047, 'Transferencia no encontrada.', 1;

    IF OBJECT_ID('tempdb..#TransferDetalle') IS NOT NULL DROP TABLE #TransferDetalle;
    SELECT
      IdProducto,
      SUM(dbo.fnInvCantidadABase(IdProducto, IdUnidadMedida, Cantidad)) AS Cantidad,
      MAX(Costo) AS Costo
    INTO #TransferDetalle
    FROM dbo.InvDocumentoDetalle
    WHERE IdDocumento = @IdDocumento
      AND RowStatus = 1
    GROUP BY IdProducto;

    IF @Accion = 'GS'
    BEGIN
      IF @EstadoActual <> 'B'
        THROW 50048, 'Solo se puede generar salida desde borrador.', 1;

      IF EXISTS (
        SELECT 1
        FROM #TransferDetalle D
        OUTER APPLY (
          SELECT TOP 1 ISNULL(PA.Cantidad, 0) AS Existencia
          FROM dbo.ProductoAlmacenes PA
          WHERE PA.IdProducto = D.IdProducto
            AND PA.IdAlmacen = @OrigenDoc
            AND PA.RowStatus = 1
        ) S
        WHERE ISNULL(S.Existencia, 0) < D.Cantidad
      )
        THROW 50049, 'Stock insuficiente para generar la salida.', 1;

      MERGE dbo.ProductoAlmacenes AS T
      USING (SELECT IdProducto, @TransitoDoc AS IdAlmacen FROM #TransferDetalle) AS S
      ON T.IdProducto = S.IdProducto AND T.IdAlmacen = S.IdAlmacen
      WHEN NOT MATCHED THEN
        INSERT (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (S.IdProducto, S.IdAlmacen, 0, 0, 0, 1, GETDATE(), @IdUsuario);

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad - D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @OrigenDoc
        AND PA.RowStatus = 1;

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad + D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @TransitoDoc
        AND PA.RowStatus = 1;

      UPDATE dbo.InvTransferencias
      SET
        EstadoTransferencia = 'T',
        FechaSalida = GETDATE(),
        UsuarioSalida = @IdUsuario,
        IdSesionSalida = @IdSesion,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    IF @Accion = 'CR'
    BEGIN
      IF @EstadoActual <> 'T'
        THROW 50050, 'Solo se puede confirmar recepcion desde En Transito.', 1;

      MERGE dbo.ProductoAlmacenes AS T
      USING (SELECT IdProducto, @DestinoDoc AS IdAlmacen FROM #TransferDetalle) AS S
      ON T.IdProducto = S.IdProducto AND T.IdAlmacen = S.IdAlmacen
      WHEN NOT MATCHED THEN
        INSERT (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (S.IdProducto, S.IdAlmacen, 0, 0, 0, 1, GETDATE(), @IdUsuario);

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad - D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @TransitoDoc
        AND PA.RowStatus = 1;

      UPDATE PA
      SET
        PA.Cantidad = PA.Cantidad + D.Cantidad,
        PA.FechaModificacion = GETDATE(),
        PA.UsuarioModificacion = @IdUsuario
      FROM dbo.ProductoAlmacenes PA
      INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
      WHERE PA.IdAlmacen = @DestinoDoc
        AND PA.RowStatus = 1;

      UPDATE dbo.InvTransferencias
      SET
        EstadoTransferencia = 'C',
        FechaRecepcion = GETDATE(),
        UsuarioRecepcion = @IdUsuario,
        IdSesionRecepcion = @IdSesion,
        FechaModificacion = GETDATE(),
        UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    IF @Accion = 'N'
    BEGIN
      IF @EstadoActual = 'C'
        THROW 50051, 'Transferencias completadas no pueden anularse.', 1;

      IF @EstadoActual = 'T'
      BEGIN
        UPDATE PA
        SET
          PA.Cantidad = PA.Cantidad + D.Cantidad,
          PA.FechaModificacion = GETDATE(),
          PA.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes PA
        INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
        WHERE PA.IdAlmacen = @OrigenDoc
          AND PA.RowStatus = 1;

        UPDATE PA
        SET
          PA.Cantidad = PA.Cantidad - D.Cantidad,
          PA.FechaModificacion = GETDATE(),
          PA.UsuarioModificacion = @IdUsuario
        FROM dbo.ProductoAlmacenes PA
        INNER JOIN #TransferDetalle D ON D.IdProducto = PA.IdProducto
        WHERE PA.IdAlmacen = @TransitoDoc
          AND PA.RowStatus = 1;
      END

      UPDATE dbo.InvTransferencias
      SET EstadoTransferencia = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario
      WHERE IdDocumento = @IdDocumento;

      UPDATE dbo.InvDocumentos
      SET Estado = 'N', FechaModificacion = GETDATE(), UsuarioModificacion = @IdUsuario, IdSesionModif = @IdSesion
      WHERE IdDocumento = @IdDocumento;

      EXEC dbo.spInvTransferenciasCRUD @Accion='O', @IdDocumento=@IdDocumento;
      RETURN;
    END

    RETURN;
  END
END;

GO

PRINT '=== Script 68 ejecutado correctamente ==='
GO