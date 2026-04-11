const fs = require("fs")
const path = require("path")
const sql = require("mssql")

function loadEnvFile(fileName) {
  const filePath = path.resolve(process.cwd(), fileName)
  if (!fs.existsSync(filePath)) return

  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/)
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    const eq = trimmed.indexOf("=")
    if (eq <= 0) continue

    const key = trimmed.slice(0, eq).trim()
    let value = trimmed.slice(eq + 1).trim()
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1)
    }

    if (!(key in process.env)) {
      process.env[key] = value
    }
  }
}

async function run() {
  loadEnvFile(".env.local")
  loadEnvFile(".env")

  const connectionString = process.env.DATABASE_URL
  if (!connectionString) {
    throw new Error("DATABASE_URL no esta definido.")
  }

  const pool = await new sql.ConnectionPool(connectionString).connect()
  try {
    const result = await pool.request().query(`
      DECLARE @IdRolAdmin INT;

      SELECT TOP (1) @IdRolAdmin = R.IdRol
      FROM dbo.Roles R
      WHERE R.RowStatus = 1
        AND R.Activo = 1
        AND UPPER(LTRIM(RTRIM(R.Nombre))) IN (N'ADMIN', N'ADMINISTRADOR', N'ADMINISTRADOR GENERAL')
      ORDER BY CASE WHEN UPPER(LTRIM(RTRIM(R.Nombre))) = N'ADMINISTRADOR' THEN 0 ELSE 1 END, R.IdRol;

      SELECT
        @IdRolAdmin AS IdRolAdmin,
        (SELECT COUNT(1) FROM dbo.Pantallas WHERE RowStatus = 1 AND Activo = 1) AS PantallasActivas,
        (SELECT COUNT(1) FROM dbo.Permisos WHERE RowStatus = 1 AND Activo = 1) AS PermisosActivos,
        (SELECT COUNT(1) FROM dbo.RolesPermisos WHERE IdRol = @IdRolAdmin AND RowStatus = 1 AND Activo = 1) AS PermisosAsignadosAdmin;
    `)

    console.log(result.recordset?.[0])
  } finally {
    await pool.close()
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
