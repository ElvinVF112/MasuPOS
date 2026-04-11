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
  const pool = await new sql.ConnectionPool(process.env.DATABASE_URL).connect()

  const roleRow = await pool.request().query("SELECT TOP (1) IdRol FROM dbo.Roles WHERE RowStatus = 1 ORDER BY IdRol")
  const roleId = roleRow.recordset?.[0]?.IdRol
  if (!roleId) throw new Error("No role found")

  const snapshot = await pool.request().input("IdRol", roleId).execute("dbo.spRolPermisosPorModulo")
  const sets = Array.isArray(snapshot.recordsets) ? snapshot.recordsets : []
  console.log("SP_CHECK", { roleId, modules: sets[0]?.length ?? 0, screens: sets[1]?.length ?? 0, fields: sets[2]?.length ?? 0 })

  await pool
    .request()
    .input("IdRol", roleId)
    .input("Tipo", "CAMPO")
    .input("IdObjeto", null)
    .input("ClaveCampo", "precios")
    .input("Valor", true)
    .input("CampoPermiso", null)
    .execute("dbo.spRolPermisosActualizar")

  console.log("UPDATE_CAMPO_OK", true)
  await pool.close()
}

run().catch((error) => {
  console.error(error.message)
  process.exit(1)
})
