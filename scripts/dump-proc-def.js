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
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1)
    if (!(key in process.env)) process.env[key] = value
  }
}

async function run() {
  const procName = process.argv[2]
  if (!procName) throw new Error("Uso: node scripts/dump-proc-def.js <nombreProc>")

  loadEnvFile(".env.local")
  loadEnvFile(".env")
  const cs = process.env.DATABASE_URL
  if (!cs) throw new Error("DATABASE_URL no esta definido.")

  const pool = await new sql.ConnectionPool(cs).connect()
  try {
    const result = await pool.request().input("name", procName).query(`
      SELECT OBJECT_DEFINITION(OBJECT_ID(CONCAT('dbo.', @name))) AS DefinitionText;
    `)
    const text = result.recordset?.[0]?.DefinitionText
    if (!text) throw new Error(`No se encontro definicion para ${procName}`)
    console.log(text)
  } finally {
    await pool.close()
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
