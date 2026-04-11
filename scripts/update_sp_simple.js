const sql = require('mssql');

const config = { 
  server: 'localhost', 
  database: 'DbMasuPOS', 
  user: 'Masu', 
  password: 'M@$uM@$t3rP@s$', 
  options: { trustServerCertificate: true } 
};

// Version simplificada del SP solo con los campos necesarios
const spDefinition = `ALTER PROCEDURE dbo.spEmpresaCRUD
    @Accion CHAR(1),
    @IdEmpresa INT = NULL OUTPUT,
    @IdentificacionFiscal NVARCHAR(30) = NULL,
    @RazonSocial NVARCHAR(200) = NULL,
    @NombreComercial NVARCHAR(200) = NULL,
    @Direccion NVARCHAR(300) = NULL,
    @Ciudad NVARCHAR(100) = NULL,
    @ProvinciaEstado NVARCHAR(100) = NULL,
    @CodigoPostal NVARCHAR(20) = NULL,
    @Pais NVARCHAR(100) = NULL,
    @Telefono1 NVARCHAR(30) = NULL,
    @Telefono2 NVARCHAR(30) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @SitioWeb NVARCHAR(200) = NULL,
    @Instagram NVARCHAR(150) = NULL,
    @Facebook NVARCHAR(150) = NULL,
    @XTwitter NVARCHAR(150) = NULL,
    @LogoUrl NVARCHAR(300) = NULL,
    @Moneda NVARCHAR(10) = NULL,
    @Activo BIT = NULL,
    @FormatoDecimal NVARCHAR(10) = NULL,
    @DigitosDecimales INT = NULL,
    @SeparadorMiles NVARCHAR(10) = NULL,
    @SimboloNegativo NVARCHAR(5) = NULL,
    @FormatoFechaCorta NVARCHAR(20) = NULL,
    @FormatoFechaLarga NVARCHAR(80) = NULL,
    @FormatoHoraCorta NVARCHAR(20) = NULL,
    @FormatoHoraLarga NVARCHAR(20) = NULL,
    @SimboloAM NVARCHAR(5) = NULL,
    @SimboloPM NVARCHAR(5) = NULL,
    @PrimerDiaSemana INT = NULL,
    @SistemaMedida NVARCHAR(20) = NULL,
    @Eslogan NVARCHAR(500) = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion = 'L'
    BEGIN
        SELECT E.IdEmpresa, E.IdentificacionFiscal, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida, E.Eslogan
        FROM dbo.Empresa E WHERE E.RowStatus = 1 ORDER BY E.IdEmpresa;
        RETURN;
    END
    IF @Accion = 'O'
    BEGIN
        SELECT E.IdEmpresa, E.IdentificacionFiscal, E.RazonSocial, E.NombreComercial,
            E.Direccion, E.Ciudad, E.ProvinciaEstado, E.CodigoPostal, E.Pais,
            E.Telefono1, E.Telefono2, E.Correo, E.SitioWeb, E.Instagram, E.Facebook, E.XTwitter,
            E.LogoUrl, E.LogoMimeType, E.LogoFileName, E.LogoActualizacion,
            CASE WHEN E.LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
            E.Moneda, E.Activo, E.RowStatus, E.FechaCreacion, E.UsuarioCreacion, E.FechaModificacion, E.UsuarioModificacion,
            E.FormatoDecimal, E.DigitosDecimales, E.SeparadorMiles, E.SimboloNegativo,
            E.FormatoFechaCorta, E.FormatoFechaLarga, E.FormatoHoraCorta, E.FormatoHoraLarga,
            E.SimboloAM, E.SimboloPM, E.PrimerDiaSemana, E.SistemaMedida, E.Eslogan
        FROM dbo.Empresa E WHERE E.IdEmpresa = @IdEmpresa AND E.RowStatus = 1;
        RETURN;
    END
    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Empresa SET
            Eslogan = NULLIF(LTRIM(RTRIM(@Eslogan)),
            FechaModificacion = SYSDATETIME(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdEmpresa = @IdEmpresa AND RowStatus = 1;
        EXEC dbo.spEmpresaCRUD @Accion='O', @IdEmpresa=@IdEmpresa;
        RETURN;
    END
END`;

(async () => {
  const pool = await sql.connect(config);
  try {
    await pool.request().query(spDefinition);
    console.log('SP actualizado correctamente');
  } catch(e) {
    console.log('Error:', e.message);
  }
  await sql.close();
})();