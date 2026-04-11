import "../src/lib/db"
import sql from "mssql"

const connectionString = process.env.DATABASE_URL
if (!connectionString) {
  console.error("Missing DATABASE_URL")
  process.exit(1)
}

async function main() {
  const pool = await new sql.ConnectionPool(connectionString).connect()
  
  const result = await pool.request().query(`
    SELECT 
      IdEmpresa, 
      RazonSocial, 
      NombreComercial,
      LogoUrl,
      CASE WHEN LogoData IS NULL THEN 0 ELSE 1 END AS TieneLogo,
      LogoMimeType,
      LogoFileName
    FROM dbo.Empresa 
    WHERE RowStatus = 1
  `)
  
  console.log("=== Empresa data ===")
  console.log(JSON.stringify(result.recordset, null, 2))
  
  if (result.recordset[0]?.TieneLogo) {
    console.log("\n=== Logo exists ===")
    const logoResult = await pool.request().query(`
      SELECT TOP 1 LEN(LogoData) as LogoSize, LogoMimeType
      FROM dbo.Empresa 
      WHERE LogoData IS NOT NULL
    `)
    console.log(JSON.stringify(logoResult.recordset, null, 2))
  }
  
  await pool.close()
}

main().catch(console.error)