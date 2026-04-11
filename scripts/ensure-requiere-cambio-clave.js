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
    await pool.request().query(`
      IF COL_LENGTH('dbo.Usuarios', 'RequiereCambioClave') IS NULL
      BEGIN
        ALTER TABLE dbo.Usuarios
        ADD RequiereCambioClave BIT NOT NULL
            CONSTRAINT DF_Usuarios_RequiereCambioClave DEFAULT (0);
      END;
    `)

    const result = await pool.request().query(`
      SELECT CASE WHEN COL_LENGTH('dbo.Usuarios', 'RequiereCambioClave') IS NULL THEN 0 ELSE 1 END AS ColumnExists;
    `)

    const exists = result.recordset?.[0]?.ColumnExists
    console.log(`RequiereCambioClave column exists: ${exists === 1 ? "YES" : "NO"}`)
  } finally {
    await pool.close()
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
