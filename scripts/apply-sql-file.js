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
  const relativePath = process.argv[2]
  if (!relativePath) {
    throw new Error("Uso: node scripts/apply-sql-file.js <ruta.sql>")
  }

  const sqlPath = path.resolve(process.cwd(), relativePath)
  if (!fs.existsSync(sqlPath)) {
    throw new Error(`No existe el archivo SQL: ${sqlPath}`)
  }

  loadEnvFile(".env.local")
  loadEnvFile(".env")

  const connectionString = process.env.DATABASE_URL
  if (!connectionString) {
    throw new Error("DATABASE_URL no esta definido.")
  }

  const script = fs.readFileSync(sqlPath, "utf8")
  const batches = script
    .split(/\r?\nGO\r?\n/gi)
    .map((item) => item.trim())
    .filter(Boolean)

  const pool = await new sql.ConnectionPool(connectionString).connect()
  try {
    for (const batch of batches) {
      await pool.request().batch(batch)
    }
    console.log(`Script aplicado correctamente: ${relativePath}`)
  } finally {
    await pool.close()
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
