const fs = require("fs")
const path = require("path")
const sql = require("mssql")

function loadEnv(fileName) {
  const filePath = path.resolve(process.cwd(), fileName)
  if (!fs.existsSync(filePath)) return
  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    const i = trimmed.indexOf("=")
    if (i < 1) continue
    const key = trimmed.slice(0, i).trim()
    const value = trimmed.slice(i + 1).trim().replace(/^['"]|['"]$/g, "")
    if (!(key in process.env)) process.env[key] = value
  }
}

async function run() {
  loadEnv(".env.local")
  const cs = process.env.DATABASE_URL
  const pool = await new sql.ConnectionPool(cs).connect()
  const result = await pool.request().query(`
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Permisos'
    ORDER BY ORDINAL_POSITION
  `)
  console.log(result.recordset.map((r) => r.COLUMN_NAME).join(", "))
  await pool.close()
}

run().catch((error) => {
  console.error(error.message)
  process.exit(1)
})
