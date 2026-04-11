USE DbMasuPOS;
GO
SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Productos', 'Codigo') IS NULL
  ALTER TABLE dbo.Productos ADD Codigo NVARCHAR(60) NULL;
GO
IF COL_LENGTH('dbo.Productos', 'Comentario') IS NULL
  ALTER TABLE dbo.Productos ADD Comentario NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.Productos', 'Imagen') IS NULL
  ALTER TABLE dbo.Productos ADD Imagen NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.Productos', 'IdUnidadVenta') IS NULL
  ALTER TABLE dbo.Productos ADD IdUnidadVenta INT NULL;
GO
IF COL_LENGTH('dbo.Productos', 'IdUnidadCompra') IS NULL
  ALTER TABLE dbo.Productos ADD IdUnidadCompra INT NULL;
GO
IF COL_LENGTH('dbo.Productos', 'IdUnidadAlterna1') IS NULL
  ALTER TABLE dbo.Productos ADD IdUnidadAlterna1 INT NULL;
GO
IF COL_LENGTH('dbo.Productos', 'IdUnidadAlterna2') IS NULL
  ALTER TABLE dbo.Productos ADD IdUnidadAlterna2 INT NULL;
GO
IF COL_LENGTH('dbo.Productos', 'IdUnidadAlterna3') IS NULL
  ALTER TABLE dbo.Productos ADD IdUnidadAlterna3 INT NULL;
GO
IF COL_LENGTH('dbo.Productos', 'AplicaImpuesto') IS NULL
  ALTER TABLE dbo.Productos ADD AplicaImpuesto BIT NOT NULL CONSTRAINT DF_Productos_AplicaImpuesto DEFAULT(0);
GO
IF COL_LENGTH('dbo.Productos', 'IdTasaImpuesto') IS NULL
  ALTER TABLE dbo.Productos ADD IdTasaImpuesto INT NULL;
GO
IF COL_LENGTH('dbo.Productos', 'UnidadBaseExistencia') IS NULL
  ALTER TABLE dbo.Productos ADD UnidadBaseExistencia NVARCHAR(20) NOT NULL CONSTRAINT DF_Productos_UnidadBaseExistencia DEFAULT('measure');
GO
IF COL_LENGTH('dbo.Productos', 'SeVendeEnFactura') IS NULL
  ALTER TABLE dbo.Productos ADD SeVendeEnFactura BIT NOT NULL CONSTRAINT DF_Productos_SeVendeEnFactura DEFAULT(1);
GO
IF COL_LENGTH('dbo.Productos', 'PermiteDescuento') IS NULL
  ALTER TABLE dbo.Productos ADD PermiteDescuento BIT NOT NULL CONSTRAINT DF_Productos_PermiteDescuento DEFAULT(1);
GO
IF COL_LENGTH('dbo.Productos', 'PermiteCambioPrecio') IS NULL
  ALTER TABLE dbo.Productos ADD PermiteCambioPrecio BIT NOT NULL CONSTRAINT DF_Productos_PermiteCambioPrecio DEFAULT(1);
GO
IF COL_LENGTH('dbo.Productos', 'PermitePrecioManual') IS NULL
  ALTER TABLE dbo.Productos ADD PermitePrecioManual BIT NOT NULL CONSTRAINT DF_Productos_PermitePrecioManual DEFAULT(1);
GO
IF COL_LENGTH('dbo.Productos', 'PideUnidad') IS NULL
  ALTER TABLE dbo.Productos ADD PideUnidad BIT NOT NULL CONSTRAINT DF_Productos_PideUnidad DEFAULT(0);
GO
IF COL_LENGTH('dbo.Productos', 'PideUnidadInventario') IS NULL
  ALTER TABLE dbo.Productos ADD PideUnidadInventario BIT NOT NULL CONSTRAINT DF_Productos_PideUnidadInventario DEFAULT(0);
GO
IF COL_LENGTH('dbo.Productos', 'PermiteFraccionesDecimales') IS NULL
  ALTER TABLE dbo.Productos ADD PermiteFraccionesDecimales BIT NOT NULL CONSTRAINT DF_Productos_PermiteFracciones DEFAULT(0);
GO
IF COL_LENGTH('dbo.Productos', 'VenderSinExistencia') IS NULL
  ALTER TABLE dbo.Productos ADD VenderSinExistencia BIT NOT NULL CONSTRAINT DF_Productos_VenderSinExistencia DEFAULT(1);
GO
IF COL_LENGTH('dbo.Productos', 'AplicaPropina') IS NULL
  ALTER TABLE dbo.Productos ADD AplicaPropina BIT NOT NULL CONSTRAINT DF_Productos_AplicaPropina DEFAULT(0);
GO
IF COL_LENGTH('dbo.Productos', 'ManejaExistencia') IS NULL
  ALTER TABLE dbo.Productos ADD ManejaExistencia BIT NOT NULL CONSTRAINT DF_Productos_ManejaExistencia DEFAULT(1);
GO
IF COL_LENGTH('dbo.Productos', 'IdMoneda') IS NULL
BEGIN
  ALTER TABLE dbo.Productos ADD IdMoneda INT NULL, DescuentoProveedor DECIMAL(10,4) NOT NULL CONSTRAINT DF_Productos_DescuentoProveedor DEFAULT(0), CostoProveedor DECIMAL(10,4) NOT NULL CONSTRAINT DF_Productos_CostoProveedor DEFAULT(0), CostoConImpuesto DECIMAL(10,4) NOT NULL CONSTRAINT DF_Productos_CostoConImpuesto DEFAULT(0), CostoPromedio DECIMAL(10,4) NOT NULL CONSTRAINT DF_Productos_CostoPromedio DEFAULT(0), PermitirCostoManual BIT NOT NULL CONSTRAINT DF_Productos_PermitirCostoManual DEFAULT(0);
END
GO

UPDATE dbo.Productos
SET IdUnidadVenta = ISNULL(IdUnidadVenta, IdUnidadMedida),
    IdUnidadCompra = ISNULL(IdUnidadCompra, IdUnidadMedida),
    UnidadBaseExistencia = ISNULL(NULLIF(UnidadBaseExistencia, ''), 'measure');
GO

IF OBJECT_ID('dbo.ProductoPrecios', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ProductoPrecios (
    IdProductoPrecio INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL,
    IdListaPrecio INT NOT NULL,
    PorcentajeGanancia DECIMAL(10,4) NOT NULL DEFAULT 0,
    Precio DECIMAL(10,4) NOT NULL DEFAULT 0,
    Impuesto DECIMAL(10,4) NOT NULL DEFAULT 0,
    PrecioConImpuesto DECIMAL(10,4) NOT NULL DEFAULT 0,
    RowStatus BIT NOT NULL DEFAULT 1,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion INT NULL,
    FechaModificacion DATETIME NULL,
    UsuarioModificacion INT NULL,
    CONSTRAINT UQ_ProductoPrecios UNIQUE (IdProducto, IdListaPrecio)
  );
END
GO

IF OBJECT_ID('dbo.ProductoOfertas', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.ProductoOfertas (
    IdProductoOferta INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL,
    Activo BIT NOT NULL DEFAULT 0,
    PrecioOferta DECIMAL(10,4) NOT NULL DEFAULT 0,
    FechaInicio DATE NULL,
    FechaFin DATE NULL,
    RowStatus BIT NOT NULL DEFAULT 1,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion INT NULL,
    FechaModificacion DATETIME NULL,
    UsuarioModificacion INT NULL,
    CONSTRAINT UQ_ProductoOfertas UNIQUE (IdProducto)
  );
END
GO

DECLARE @IdListaPrecioBase INT = (SELECT TOP 1 IdListaPrecio FROM dbo.ListasPrecios WHERE ISNULL(RowStatus,1)=1 ORDER BY IdListaPrecio);
IF @IdListaPrecioBase IS NOT NULL
BEGIN
  INSERT INTO dbo.ProductoPrecios (IdProducto, IdListaPrecio, Precio, Impuesto, PrecioConImpuesto, PorcentajeGanancia, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdProducto, @IdListaPrecioBase, ISNULL(P.Precio,0), 0, ISNULL(P.Precio,0), 0, 1, GETDATE(), ISNULL(P.UsuarioCreacion,1)
  FROM dbo.Productos P
  WHERE ISNULL(P.RowStatus,1)=1
    AND NOT EXISTS (
      SELECT 1 FROM dbo.ProductoPrecios PP WHERE PP.IdProducto=P.IdProducto AND PP.IdListaPrecio=@IdListaPrecioBase
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.spProductosCRUD
    @Accion                     CHAR(1),
    @IdProducto                 INT           = NULL,
    @IdCategoria                INT           = NULL,
    @IdTipoProducto             INT           = NULL,
    @IdUnidadMedida             INT           = NULL,
    @IdUnidadVenta              INT           = NULL,
    @IdUnidadCompra             INT           = NULL,
    @IdUnidadAlterna1           INT           = NULL,
    @IdUnidadAlterna2           INT           = NULL,
    @IdUnidadAlterna3           INT           = NULL,
    @Nombre                     NVARCHAR(150) = NULL,
    @Descripcion                NVARCHAR(250) = NULL,
    @Activo                     BIT           = NULL,
    @AplicaImpuesto             BIT           = NULL,
    @IdTasaImpuesto             INT           = NULL,
    @UnidadBaseExistencia       NVARCHAR(20)  = NULL,
    @SeVendeEnFactura           BIT           = NULL,
    @PermiteDescuento           BIT           = NULL,
    @PermiteCambioPrecio        BIT           = NULL,
    @PermitePrecioManual        BIT           = NULL,
    @PideUnidad                 BIT           = NULL,
    @PideUnidadInventario       BIT           = NULL,
    @PermiteFraccionesDecimales BIT           = NULL,
    @VenderSinExistencia        BIT           = NULL,
    @AplicaPropina              BIT           = NULL,
    @ManejaExistencia           BIT           = NULL,
    @IdMoneda                   INT           = NULL,
    @DescuentoProveedor         DECIMAL(10,4) = NULL,
    @CostoProveedor             DECIMAL(10,4) = NULL,
    @CostoConImpuesto           DECIMAL(10,4) = NULL,
    @CostoPromedio              DECIMAL(10,4) = NULL,
    @PermitirCostoManual        BIT           = NULL,
    @IdSesion                   BIGINT        = 0,
    @TokenSesion                NVARCHAR(200) = NULL,
    @UsuarioCreacion            INT           = NULL,
    @UsuarioModificacion        INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT P.IdProducto, P.IdCategoria, C.Nombre AS Categoria, P.IdTipoProducto, TP.Nombre AS TipoProducto,
               P.IdUnidadMedida, UB.Nombre AS UnidadBase, UB.Abreviatura AS AbreviaturaUnidadBase,
               P.IdUnidadVenta, UV.Nombre AS UnidadVenta, UV.Abreviatura AS AbreviaturaUnidadVenta,
               P.IdUnidadCompra, UC.Nombre AS UnidadCompra, UC.Abreviatura AS AbreviaturaUnidadCompra,
               P.IdUnidadAlterna1, UA1.Nombre AS UnidadAlterna1,
               P.IdUnidadAlterna2, UA2.Nombre AS UnidadAlterna2,
               P.IdUnidadAlterna3, UA3.Nombre AS UnidadAlterna3,
               P.Nombre, P.Descripcion, P.AplicaImpuesto, P.IdTasaImpuesto,
               TI.Nombre AS NombreTasa, TI.Tasa AS TasaImpuesto,
               P.UnidadBaseExistencia, P.SeVendeEnFactura, P.PermiteDescuento, P.PermiteCambioPrecio,
               P.PermitePrecioManual, P.PideUnidad, P.PideUnidadInventario, P.PermiteFraccionesDecimales,
               P.VenderSinExistencia, P.AplicaPropina, P.ManejaExistencia, P.Activo, P.FechaCreacion,
               P.RowStatus, P.IdMoneda, P.DescuentoProveedor, P.CostoProveedor, P.CostoConImpuesto,
               P.CostoPromedio, P.PermitirCostoManual,
               ISNULL((SELECT TOP 1 PP.Precio FROM dbo.ProductoPrecios PP WHERE PP.IdProducto=P.IdProducto AND PP.RowStatus=1 ORDER BY PP.IdListaPrecio), ISNULL(P.Precio,0)) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = ISNULL(P.IdUnidadVenta, P.IdUnidadMedida)
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = ISNULL(P.IdUnidadCompra, P.IdUnidadMedida)
        LEFT JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
        WHERE ISNULL(P.RowStatus,1)=1
        ORDER BY P.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT P.IdProducto, P.IdCategoria, C.Nombre AS Categoria, P.IdTipoProducto, TP.Nombre AS TipoProducto,
               P.IdUnidadMedida, UB.Nombre AS UnidadBase, UB.Abreviatura AS AbreviaturaUnidadBase,
               P.IdUnidadVenta, UV.Nombre AS UnidadVenta, UV.Abreviatura AS AbreviaturaUnidadVenta,
               P.IdUnidadCompra, UC.Nombre AS UnidadCompra, UC.Abreviatura AS AbreviaturaUnidadCompra,
               P.IdUnidadAlterna1, UA1.Nombre AS UnidadAlterna1,
               P.IdUnidadAlterna2, UA2.Nombre AS UnidadAlterna2,
               P.IdUnidadAlterna3, UA3.Nombre AS UnidadAlterna3,
               P.Nombre, P.Descripcion, P.AplicaImpuesto, P.IdTasaImpuesto,
               TI.Nombre AS NombreTasa, TI.Tasa AS TasaImpuesto,
               P.UnidadBaseExistencia, P.SeVendeEnFactura, P.PermiteDescuento, P.PermiteCambioPrecio,
               P.PermitePrecioManual, P.PideUnidad, P.PideUnidadInventario, P.PermiteFraccionesDecimales,
               P.VenderSinExistencia, P.AplicaPropina, P.ManejaExistencia, P.Activo, P.FechaCreacion,
               P.RowStatus, P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion,
               P.IdMoneda, P.DescuentoProveedor, P.CostoProveedor, P.CostoConImpuesto,
               P.CostoPromedio, P.PermitirCostoManual,
               ISNULL((SELECT TOP 1 PP.Precio FROM dbo.ProductoPrecios PP WHERE PP.IdProducto=P.IdProducto AND PP.RowStatus=1 ORDER BY PP.IdListaPrecio), ISNULL(P.Precio,0)) AS Precio
        FROM dbo.Productos P
        INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
        INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
        INNER JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
        INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = ISNULL(P.IdUnidadVenta, P.IdUnidadMedida)
        INNER JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = ISNULL(P.IdUnidadCompra, P.IdUnidadMedida)
        LEFT JOIN dbo.UnidadesMedida UA1 ON UA1.IdUnidadMedida = P.IdUnidadAlterna1
        LEFT JOIN dbo.UnidadesMedida UA2 ON UA2.IdUnidadMedida = P.IdUnidadAlterna2
        LEFT JOIN dbo.UnidadesMedida UA3 ON UA3.IdUnidadMedida = P.IdUnidadAlterna3
        LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
        WHERE P.IdProducto=@IdProducto;
        RETURN;
    END;

    IF @Accion='I'
    BEGIN
      INSERT INTO dbo.Productos (IdCategoria,IdTipoProducto,IdUnidadMedida,IdUnidadVenta,IdUnidadCompra,IdUnidadAlterna1,IdUnidadAlterna2,IdUnidadAlterna3,Nombre,Descripcion,AplicaImpuesto,IdTasaImpuesto,UnidadBaseExistencia,SeVendeEnFactura,PermiteDescuento,PermiteCambioPrecio,PermitePrecioManual,PideUnidad,PideUnidadInventario,PermiteFraccionesDecimales,VenderSinExistencia,AplicaPropina,ManejaExistencia,IdMoneda,DescuentoProveedor,CostoProveedor,CostoConImpuesto,CostoPromedio,PermitirCostoManual,Activo,RowStatus,FechaCreacion,UsuarioCreacion)
      VALUES (@IdCategoria,@IdTipoProducto,@IdUnidadMedida,ISNULL(@IdUnidadVenta,@IdUnidadMedida),ISNULL(@IdUnidadCompra,@IdUnidadMedida),@IdUnidadAlterna1,@IdUnidadAlterna2,@IdUnidadAlterna3,LTRIM(RTRIM(@Nombre)),NULLIF(LTRIM(RTRIM(@Descripcion)),''),ISNULL(@AplicaImpuesto,0),@IdTasaImpuesto,ISNULL(@UnidadBaseExistencia,'measure'),ISNULL(@SeVendeEnFactura,1),ISNULL(@PermiteDescuento,1),ISNULL(@PermiteCambioPrecio,1),ISNULL(@PermitePrecioManual,1),ISNULL(@PideUnidad,0),ISNULL(@PideUnidadInventario,0),ISNULL(@PermiteFraccionesDecimales,0),ISNULL(@VenderSinExistencia,1),ISNULL(@AplicaPropina,0),ISNULL(@ManejaExistencia,1),@IdMoneda,ISNULL(@DescuentoProveedor,0),ISNULL(@CostoProveedor,0),ISNULL(@CostoConImpuesto,0),ISNULL(@CostoPromedio,0),ISNULL(@PermitirCostoManual,0),ISNULL(@Activo,1),1,GETDATE(),@UsuarioCreacion);
      DECLARE @Nuevo INT=SCOPE_IDENTITY();
      EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@Nuevo, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
      RETURN;
    END;

    IF @Accion='A'
    BEGIN
      UPDATE dbo.Productos
      SET IdCategoria=@IdCategoria, IdTipoProducto=@IdTipoProducto, IdUnidadMedida=@IdUnidadMedida,
          IdUnidadVenta=ISNULL(@IdUnidadVenta,@IdUnidadMedida), IdUnidadCompra=ISNULL(@IdUnidadCompra,@IdUnidadMedida),
          IdUnidadAlterna1=@IdUnidadAlterna1, IdUnidadAlterna2=@IdUnidadAlterna2, IdUnidadAlterna3=@IdUnidadAlterna3,
          Nombre=LTRIM(RTRIM(@Nombre)), Descripcion=NULLIF(LTRIM(RTRIM(@Descripcion)),''),
          AplicaImpuesto=ISNULL(@AplicaImpuesto,AplicaImpuesto), IdTasaImpuesto=@IdTasaImpuesto,
          UnidadBaseExistencia=ISNULL(@UnidadBaseExistencia,UnidadBaseExistencia), SeVendeEnFactura=ISNULL(@SeVendeEnFactura,SeVendeEnFactura),
          PermiteDescuento=ISNULL(@PermiteDescuento,PermiteDescuento), PermiteCambioPrecio=ISNULL(@PermiteCambioPrecio,PermiteCambioPrecio),
          PermitePrecioManual=ISNULL(@PermitePrecioManual,PermitePrecioManual), PideUnidad=ISNULL(@PideUnidad,PideUnidad),
          PideUnidadInventario=ISNULL(@PideUnidadInventario,PideUnidadInventario), PermiteFraccionesDecimales=ISNULL(@PermiteFraccionesDecimales,PermiteFraccionesDecimales),
          VenderSinExistencia=ISNULL(@VenderSinExistencia,VenderSinExistencia), AplicaPropina=ISNULL(@AplicaPropina,AplicaPropina),
          ManejaExistencia=ISNULL(@ManejaExistencia,ManejaExistencia), IdMoneda=@IdMoneda,
          DescuentoProveedor=ISNULL(@DescuentoProveedor,DescuentoProveedor), CostoProveedor=ISNULL(@CostoProveedor,CostoProveedor),
          CostoConImpuesto=ISNULL(@CostoConImpuesto,CostoConImpuesto), CostoPromedio=ISNULL(@CostoPromedio,CostoPromedio),
          PermitirCostoManual=ISNULL(@PermitirCostoManual,PermitirCostoManual), Activo=ISNULL(@Activo,Activo),
          FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion
      WHERE IdProducto=@IdProducto;
      EXEC dbo.spProductosCRUD @Accion='O', @IdProducto=@IdProducto, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
      RETURN;
    END;

    IF @Accion='D'
    BEGIN
      UPDATE dbo.Productos SET RowStatus=0, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion WHERE IdProducto=@IdProducto;
      RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.',16,1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spProductosPreciosCRUD
    @Accion CHAR(1),
    @IdProducto INT = NULL,
    @IdListaPrecio INT = NULL,
    @PorcentajeGanancia DECIMAL(10,4) = NULL,
    @Precio DECIMAL(10,4) = NULL,
    @Impuesto DECIMAL(10,4) = NULL,
    @PrecioConImpuesto DECIMAL(10,4) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @Accion='G'
  BEGIN
    SELECT PP.IdProductoPrecio, PP.IdProducto, PP.IdListaPrecio,
           LP.Codigo AS CodigoLista, LP.Descripcion AS DescripcionLista, LP.IdMoneda,
           M.Simbolo AS SimboloMoneda,
           PP.PorcentajeGanancia, PP.Precio, PP.Impuesto, PP.PrecioConImpuesto,
           PP.RowStatus, PP.FechaCreacion, PP.FechaModificacion
    FROM dbo.ProductoPrecios PP
    INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio=PP.IdListaPrecio
    LEFT JOIN dbo.Monedas M ON M.IdMoneda=LP.IdMoneda
    WHERE PP.IdProducto=@IdProducto AND PP.RowStatus=1
    ORDER BY LP.IdListaPrecio ASC;
    RETURN;
  END;
  IF @Accion='U'
  BEGIN
    IF EXISTS(SELECT 1 FROM dbo.ProductoPrecios WHERE IdProducto=@IdProducto AND IdListaPrecio=@IdListaPrecio)
      UPDATE dbo.ProductoPrecios SET PorcentajeGanancia=ISNULL(@PorcentajeGanancia,PorcentajeGanancia), Precio=ISNULL(@Precio,Precio), Impuesto=ISNULL(@Impuesto,Impuesto), PrecioConImpuesto=ISNULL(@PrecioConImpuesto,PrecioConImpuesto), RowStatus=1, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion WHERE IdProducto=@IdProducto AND IdListaPrecio=@IdListaPrecio;
    ELSE
      INSERT INTO dbo.ProductoPrecios (IdProducto,IdListaPrecio,PorcentajeGanancia,Precio,Impuesto,PrecioConImpuesto,RowStatus,FechaCreacion,UsuarioCreacion)
      VALUES (@IdProducto,@IdListaPrecio,ISNULL(@PorcentajeGanancia,0),ISNULL(@Precio,0),ISNULL(@Impuesto,0),ISNULL(@PrecioConImpuesto,0),1,GETDATE(),@UsuarioCreacion);

    SELECT PP.IdProductoPrecio, PP.IdProducto, PP.IdListaPrecio,
           LP.Codigo AS CodigoLista, LP.Descripcion AS DescripcionLista, LP.IdMoneda,
           M.Simbolo AS SimboloMoneda,
           PP.PorcentajeGanancia, PP.Precio, PP.Impuesto, PP.PrecioConImpuesto,
           PP.RowStatus, PP.FechaCreacion, PP.FechaModificacion
    FROM dbo.ProductoPrecios PP
    INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio=PP.IdListaPrecio
    LEFT JOIN dbo.Monedas M ON M.IdMoneda=LP.IdMoneda
    WHERE PP.IdProducto=@IdProducto AND PP.IdListaPrecio=@IdListaPrecio;
    RETURN;
  END;
  RAISERROR('La accion enviada no es valida para spProductosPreciosCRUD. Use G o U.',16,1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spProductosOfertasCRUD
    @Accion CHAR(1),
    @IdProducto INT = NULL,
    @Activo BIT = NULL,
    @PrecioOferta DECIMAL(10,4) = NULL,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @Accion='G'
  BEGIN
    SELECT IdProductoOferta, IdProducto, Activo, PrecioOferta, FechaInicio, FechaFin, FechaCreacion, FechaModificacion
    FROM dbo.ProductoOfertas WHERE IdProducto=@IdProducto AND RowStatus=1;
    RETURN;
  END;
  IF @Accion='U'
  BEGIN
    IF EXISTS(SELECT 1 FROM dbo.ProductoOfertas WHERE IdProducto=@IdProducto)
      UPDATE dbo.ProductoOfertas SET Activo=ISNULL(@Activo,Activo), PrecioOferta=ISNULL(@PrecioOferta,PrecioOferta), FechaInicio=@FechaInicio, FechaFin=@FechaFin, RowStatus=1, FechaModificacion=GETDATE(), UsuarioModificacion=@UsuarioModificacion WHERE IdProducto=@IdProducto;
    ELSE
      INSERT INTO dbo.ProductoOfertas (IdProducto,Activo,PrecioOferta,FechaInicio,FechaFin,RowStatus,FechaCreacion,UsuarioCreacion)
      VALUES (@IdProducto,ISNULL(@Activo,0),ISNULL(@PrecioOferta,0),@FechaInicio,@FechaFin,1,GETDATE(),@UsuarioCreacion);
    SELECT IdProductoOferta, IdProducto, Activo, PrecioOferta, FechaInicio, FechaFin, FechaCreacion, FechaModificacion
    FROM dbo.ProductoOfertas WHERE IdProducto=@IdProducto AND RowStatus=1;
    RETURN;
  END;
  RAISERROR('La accion enviada no es valida para spProductosOfertasCRUD. Use G o U.',16,1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spBuscarProductos
  @Busqueda NVARCHAR(150) = NULL,
  @Top INT = 80
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Q NVARCHAR(150) = LTRIM(RTRIM(ISNULL(@Busqueda, '')));
  DECLARE @Like NVARCHAR(170) = '%' + @Q + '%';
  SET @Top = CASE WHEN ISNULL(@Top, 0) <= 0 THEN 80 WHEN @Top > 300 THEN 300 ELSE @Top END;
  IF @Q = ''
  BEGIN
    SELECT TOP (@Top) P.IdProducto, ISNULL(P.Codigo, '') AS Codigo, P.Nombre, ISNULL(P.Descripcion, '') AS Descripcion,
           C.Nombre AS Categoria, TP.Nombre AS TipoProducto, P.Activo,
           ISNULL((SELECT TOP 1 PP.Precio FROM dbo.ProductoPrecios PP WHERE PP.IdProducto=P.IdProducto AND PP.RowStatus=1 ORDER BY PP.IdListaPrecio), ISNULL(P.Precio,0)) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria=P.IdCategoria
    INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto=P.IdTipoProducto
    WHERE ISNULL(P.RowStatus,1)=1
    ORDER BY P.Nombre;
    RETURN;
  END
  SELECT TOP (@Top) P.IdProducto, ISNULL(P.Codigo, '') AS Codigo, P.Nombre, ISNULL(P.Descripcion, '') AS Descripcion,
         C.Nombre AS Categoria, TP.Nombre AS TipoProducto, P.Activo,
         ISNULL((SELECT TOP 1 PP.Precio FROM dbo.ProductoPrecios PP WHERE PP.IdProducto=P.IdProducto AND PP.RowStatus=1 ORDER BY PP.IdListaPrecio), ISNULL(P.Precio,0)) AS Precio
  FROM dbo.Productos P
  INNER JOIN dbo.Categorias C ON C.IdCategoria=P.IdCategoria
  INNER JOIN dbo.TiposProducto TP ON TP.IdTipoProducto=P.IdTipoProducto
  WHERE ISNULL(P.RowStatus,1)=1
    AND (ISNULL(P.Codigo,'') LIKE @Like OR P.Nombre LIKE @Like OR ISNULL(P.Descripcion,'') LIKE @Like)
  ORDER BY CASE WHEN ISNULL(P.Codigo,'')=@Q THEN 0 ELSE 1 END, P.Nombre;
END;
GO
