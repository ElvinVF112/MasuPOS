SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Monedas' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Monedas (
        IdMoneda INT IDENTITY(1,1) PRIMARY KEY,
        Codigo NVARCHAR(5) NOT NULL UNIQUE,
        Nombre NVARCHAR(100) NOT NULL,
        Simbolo NVARCHAR(10),
        SimboloAlt NVARCHAR(10),
        EsLocal BIT NOT NULL DEFAULT 0,
        CodigoBanco NVARCHAR(20),
        FactorConversionLocal DECIMAL(18,6) DEFAULT 1,
        FactorConversionUSD DECIMAL(18,6) DEFAULT 1,
        MostrarEnPOS BIT DEFAULT 1,
        AceptaPagos BIT DEFAULT 1,
        DecimalesPOS INT DEFAULT 2,
        Activo BIT NOT NULL DEFAULT 1,
        RowStatus BIT NOT NULL DEFAULT 1,
        FechaCreacion DATETIME DEFAULT GETDATE(),
        UsuarioCreacion INT NULL,
        FechaModificacion DATETIME NULL,
        UsuarioModificacion INT NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MonedaTasas' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.MonedaTasas (
        IdTasa INT IDENTITY(1,1) PRIMARY KEY,
        IdMoneda INT NOT NULL REFERENCES dbo.Monedas(IdMoneda),
        Fecha DATE NOT NULL,
        TasaAdministrativa DECIMAL(18,6),
        TasaOperativa DECIMAL(18,6),
        TasaCompra DECIMAL(18,6),
        TasaVenta DECIMAL(18,6),
        IdUsuario INT NULL,
        FechaRegistro DATETIME DEFAULT SYSDATETIME(),
        CONSTRAINT UQ_MonedaFecha UNIQUE (IdMoneda, Fecha)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MonedaTasas_IdMoneda_Fecha')
BEGIN
    CREATE INDEX IX_MonedaTasas_IdMoneda_Fecha ON dbo.MonedaTasas(IdMoneda, Fecha DESC);
END
GO

INSERT INTO dbo.Monedas (Codigo, Nombre, Simbolo, SimboloAlt, EsLocal, FactorConversionLocal, FactorConversionUSD, MostrarEnPOS, AceptaPagos, DecimalesPOS, Activo, UsuarioCreacion)
SELECT 'DOP', 'Peso Dominicano', 'RD$', 'DOP', 1, 1, 1, 1, 1, 2, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Monedas WHERE Codigo = 'DOP' AND RowStatus = 1);

INSERT INTO dbo.Monedas (Codigo, Nombre, Simbolo, SimboloAlt, EsLocal, FactorConversionLocal, FactorConversionUSD, MostrarEnPOS, AceptaPagos, DecimalesPOS, Activo, UsuarioCreacion)
SELECT 'USD', 'Dolar Estadounidense', 'US$', 'USD', 0, 1, 1, 1, 1, 2, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Monedas WHERE Codigo = 'USD' AND RowStatus = 1);

INSERT INTO dbo.Monedas (Codigo, Nombre, Simbolo, SimboloAlt, EsLocal, FactorConversionLocal, FactorConversionUSD, MostrarEnPOS, AceptaPagos, DecimalesPOS, Activo, UsuarioCreacion)
SELECT 'EUR', 'Euro', 'EUR', 'EUR', 0, 1, 1, 0, 0, 2, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Monedas WHERE Codigo = 'EUR' AND RowStatus = 1);
GO

DECLARE @Today DATE = CAST(SYSDATETIME() AS DATE);
DECLARE @IdUSD INT = (SELECT IdMoneda FROM dbo.Monedas WHERE Codigo = 'USD' AND RowStatus = 1);
DECLARE @IdEUR INT = (SELECT IdMoneda FROM dbo.Monedas WHERE Codigo = 'EUR' AND RowStatus = 1);

IF @IdUSD IS NOT NULL
BEGIN
    INSERT INTO dbo.MonedaTasas (IdMoneda, Fecha, TasaAdministrativa, TasaOperativa, TasaCompra, TasaVenta, IdUsuario)
    SELECT @IdUSD, @Today, 59.50, 59.80, 59.20, 60.10, 1
    WHERE NOT EXISTS (SELECT 1 FROM dbo.MonedaTasas WHERE IdMoneda = @IdUSD AND Fecha = @Today);
END

IF @IdEUR IS NOT NULL
BEGIN
    INSERT INTO dbo.MonedaTasas (IdMoneda, Fecha, TasaAdministrativa, TasaOperativa, TasaCompra, TasaVenta, IdUsuario)
    SELECT @IdEUR, @Today, 64.20, 64.50, 63.90, 65.00, 1
    WHERE NOT EXISTS (SELECT 1 FROM dbo.MonedaTasas WHERE IdMoneda = @IdEUR AND Fecha = @Today);
END
GO

SELECT 'Tablas de monedas creadas correctamente' AS Result;
GO
