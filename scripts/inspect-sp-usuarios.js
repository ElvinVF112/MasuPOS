const fs = require('fs')
const path = require('path')
const sql = require('mssql')
function loadEnvFile(fileName) {
  const filePath = path.resolve(process.cwd(), fileName)
  if (!fs.existsSync(filePath)) return
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/)
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith('#')) continue
    const eq = trimmed.indexOf('=')
    if (eq <= 0) continue
    const key = trimmed.slice(0, eq).trim()
    let value = trimmed.slice(eq + 1).trim()
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1)
    if (!(key in process.env)) process.env[key] = value
  }
}
async function run() {
  loadEnvFile('.env.local'); loadEnvFile('.env')
  const cs = process.env.DATABASE_URL
  if (!cs) throw new Error('DATABASE_URL no esta definido.')
  const pool = await new sql.ConnectionPool(cs).connect()
  try {
    const result = await pool.request().input('proc', 'spUsuariosCRUD').query(`
      SELECT PR.parameter_id AS ParamOrder, PR.name AS ParamName, T.name AS TypeName, PR.max_length AS MaxLength
      FROM sys.procedures P
      LEFT JOIN sys.parameters PR ON PR.object_id = P.object_id
      LEFT JOIN sys.types T ON T.user_type_id = PR.user_type_id
      WHERE P.name = @proc
      ORDER BY PR.parameter_id;
    `)
    console.log(JSON.stringify(result.recordset, null, 2))
  } finally {
    await pool.close()
  }
}
run().catch((error) => { console.error(error instanceof Error ? error.message : String(error)); process.exit(1) })
